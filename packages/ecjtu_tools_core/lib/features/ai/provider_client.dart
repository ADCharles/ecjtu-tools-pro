// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show compute;
import 'package:http/http.dart' as http;

import 'attachment_models.dart';
import 'attachment_reader.dart' show AiAttachmentReader;
import 'chat_tools.dart' show AiChatTools;
import 'provider_models.dart';
import 'provider_errors.dart';
import 'provider_reasoning.dart';
import 'tool_names.dart';
import 'provider_sse.dart';
import 'provider_tool_format.dart';

class AiProviderClient {
  AiProviderClient({
    http.Client Function()? clientFactory,
    this.timeout = const Duration(seconds: 60),
    this.maxRetries = 5,
    Future<void> Function(Duration)? retryWait,
  }) : _clientFactory = clientFactory ?? http.Client.new,
       _retryWait = retryWait ?? Future<void>.delayed;

  final http.Client Function() _clientFactory;
  final Duration timeout;
  final int maxRetries;
  final Future<void> Function(Duration) _retryWait;

  Future<T> _retry<T>(
    AiChatCancellation cancellation,
    Future<T> Function(int) action,
  ) async {
    for (var attempt = 0; ; attempt++) {
      cancellation.check();
      try {
        return await action(attempt);
      } on AiProviderException catch (error) {
        if (attempt >= maxRetries ||
            !const {
              'rate_limit',
              'server',
              'network',
              'timeout',
            }.contains(error.code))
          rethrow;
        cancellation.check();
        final delay =
            error.retryAfter ?? Duration(seconds: 1 << attempt.clamp(0, 5));
        await Future.any<void>([
          _retryWait(delay),
          cancellation.signal.then((_) => cancellation.check()),
        ]);
      }
    }
  }

  Future<AiProviderException> _httpFailure(
    http.StreamedResponse response,
    AiProviderConfig config,
    AiChatCancellation cancellation,
  ) async {
    var original = '';
    final bytes = <int>[];
    try {
      Future<void> read() async {
        await for (final chunk in response.stream) {
          bytes.addAll(chunk.take(65536 - bytes.length));
          if (bytes.length >= 65536) break;
        }
      }

      await cancellation.race(read(), timeout: const Duration(seconds: 3));
    } catch (_) {
      cancellation.check();
    }
    original = config.redact(utf8.decode(bytes, allowMalformed: true));
    final seconds = int.tryParse(response.headers['retry-after'] ?? '');
    final delay = seconds != null && seconds >= 0
        ? Duration(seconds: seconds)
        : null;
    return aiProviderFailure(
      original,
      statusCode: response.statusCode,
      retryAfter: delay,
    );
  }

  Future<AiConnectionTestResult> testConnection({
    required AiProviderConfig config,
    required AiChatCancellation cancellation,
  }) => _retry(
    cancellation,
    (_) => _testConnectionOnce(config: config, cancellation: cancellation),
  );

  Future<AiConnectionTestResult> _testConnectionOnce({
    required AiProviderConfig config,
    required AiChatCancellation cancellation,
  }) async {
    final timer = Stopwatch()..start();
    config.validate();
    cancellation.check();
    final endpoint = config.endpoint;
    final uri = endpoint.replace(
      path:
          '${endpoint.path.substring(0, endpoint.path.length - config.protocol.path.length)}/models',
    );
    final abort = Completer<void>();
    unawaited(
      cancellation.signal.then((_) {
        if (!abort.isCompleted) abort.complete();
      }),
    );
    final client = _clientFactory();
    try {
      final request = http.AbortableRequest(
        'GET',
        uri,
        abortTrigger: abort.future,
      )..followRedirects = false;
      request.headers.addAll({
        'Accept': 'application/json',
        if (config.protocol == AiProviderProtocol.anthropicMessages) ...{
          'x-api-key': config.apiKey,
          'anthropic-version': '2023-06-01',
        } else
          'Authorization': 'Bearer ${config.apiKey}',
      });
      final response = await cancellation.race(
        client.send(request),
        timeout: timeout,
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw await _httpFailure(response, config, cancellation);
      }
      final latency = timer.elapsed;
      await response.stream.listen(null).cancel();
      cancellation.check();
      return AiConnectionTestResult(
        model: config.model.trim(),
        latency: latency,
      );
    } on AiProviderException catch (error) {
      throw AiProviderException(
        error.code,
        config.redact(error.message),
        retryAfter: error.retryAfter,
      );
    } on TimeoutException catch (error) {
      throw AiProviderException('timeout', config.redact(error.toString()));
    } catch (error) {
      cancellation.check();
      throw AiProviderException('network', config.redact(error.toString()));
    } finally {
      if (!abort.isCompleted) abort.complete();
      client.close();
    }
  }

  Future<AiConversationTestResult> testConversation({
    required AiProviderConfig config,
    required AiChatCancellation cancellation,
  }) async {
    final timer = Stopwatch()..start();
    final reply = await complete(
      config: config,
      system: '只需简短确认对话测试成功。',
      messages: const [
        AiProviderMessage(role: AiProviderRole.user, text: '请回复：对话测试成功。'),
      ],
      tools: const [],
      cancellation: cancellation,
      maxOutputTokens: 48,
    );
    if (reply.text.trim().isEmpty) {
      throw const AiProviderException('response', '服务已连接，但没有收到有效的对话回复');
    }
    return AiConversationTestResult(text: reply.text, latency: timer.elapsed);
  }

  Future<AiProviderReply> complete({
    required AiProviderConfig config,
    required String system,
    required List<AiProviderMessage> messages,
    required List<Map<String, Object?>> tools,
    required AiChatCancellation cancellation,
    void Function(String text)? onText,
    void Function(String text)? onReasoning,
    void Function(AiProviderToolProgress)? onToolProgress,
    int? maxOutputTokens,
    bool stableContext = false,
    bool allowToolCalls = true,
  }) async {
    var received = '', reasoning = '';
    return _retry(cancellation, (attempt) async {
      final prefix = received, reasoningPrefix = reasoning;
      final reply = await _completeOnce(
        config: config,
        system: system,
        messages: [
          ...messages,
          if (prefix.isNotEmpty) ...[
            AiProviderMessage(role: AiProviderRole.assistant, text: prefix),
            const AiProviderMessage(
              role: AiProviderRole.user,
              text: '回复中断，请从已收到的内容继续，不重复前文。',
            ),
          ],
        ],
        tools: tools,
        cancellation: cancellation,
        onText: (text) {
          received = '$prefix$text';
          onText?.call(received);
        },
        onReasoning: (text) {
          reasoning = '$reasoningPrefix$text';
          onReasoning?.call(reasoning);
        },
        onToolProgress: onToolProgress,
        maxOutputTokens: maxOutputTokens,
        stableContext: stableContext,
        allowToolCalls: allowToolCalls,
      );
      return AiProviderReply(
        text: '$prefix${reply.text}',
        reasoning: '$reasoningPrefix${reply.reasoning}',
        toolCalls: reply.toolCalls,
        responsesOutput: reply.responsesOutput,
        usage: reply.usage,
        anthropicThinking: reply.anthropicThinking,
      );
    });
  }

  Future<AiProviderReply> _completeOnce({
    required AiProviderConfig config,
    required String system,
    required List<AiProviderMessage> messages,
    required List<Map<String, Object?>> tools,
    required AiChatCancellation cancellation,
    void Function(String text)? onText,
    void Function(String text)? onReasoning,
    void Function(AiProviderToolProgress)? onToolProgress,
    int? maxOutputTokens,
    bool stableContext = false,
    bool allowToolCalls = true,
  }) async {
    config.validate();
    cancellation.check();
    _validateAttachments(config, messages);
    final toolNames = _ProviderToolNames(tools);
    void Function()? flushStream;
    final abort = Completer<void>();
    void abortRequest() {
      if (!abort.isCompleted) abort.complete();
    }

    unawaited(
      cancellation.signal.then((_) {
        flushStream?.call();
        abortRequest();
      }),
    );
    final client = _clientFactory();
    try {
      final request = http.AbortableRequest(
        'POST',
        config.endpoint,
        abortTrigger: abort.future,
      );
      request.headers.addAll({
        'Content-Type': 'application/json',
        'Accept': config.streaming ? 'text/event-stream' : 'application/json',
        if (config.protocol == AiProviderProtocol.anthropicMessages) ...{
          'x-api-key': config.apiKey,
          'anthropic-version': '2023-06-01',
        } else
          'Authorization': 'Bearer ${config.apiKey}',
      });
      request.followRedirects = false;
      final body = _body(
        config,
        stableContext
            ? _shortToolReferences(system)
            : _providerSystem(system, messages, tools),
        messages,
        tools,
        maxOutputTokens,
        stableContext,
        allowToolCalls,
      );
      final textSize =
          system.length +
          messages.fold<int>(
            0,
            (total, message) =>
                total +
                message.text.length +
                message.reasoning.length +
                message.attachments.fold<int>(
                  0,
                  (size, a) =>
                      size + a.encodedData.length + a.extractedText.length,
                ),
          );
      request.body = textSize < 65536
          ? _encodeProviderBody((body: body, config: config))
          : await cancellation.race(
              compute(_encodeProviderBody, (
                body: body,
                config: config,
              ), debugLabel: 'ai-request-encode'),
              timeout: timeout,
            );
      cancellation.check();
      Future<AiProviderReply> receive() async {
        final response = await cancellation.race(
          client.send(request),
          timeout: timeout,
        );
        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw await _httpFailure(response, config, cancellation);
        }
        Object? data;
        if (config.streaming) {
          final accumulated = AiSseAccumulator(config.protocol);
          var visible = '';
          var visibleReasoning = '';
          final visibleTools = <String, String>{};
          Timer? updateTimer;
          var firstUpdate = true;
          void publish({bool retainReceived = false}) {
            updateTimer?.cancel();
            updateTimer = null;
            if (cancellation.isCancelled && !retainReceived) return;
            final text = visibleAiReplyText(config.redact(accumulated.text));
            if (text != visible) {
              visible = text;
              onText?.call(text);
            }
            final reasoning = config.redact(accumulated.reasoning);
            if (reasoning != visibleReasoning) {
              visibleReasoning = reasoning;
              onReasoning?.call(reasoning);
            }
            for (final tool in accumulated.toolProgress) {
              if (cancellation.isCancelled) break;
              if (tool.id.isEmpty || visibleTools[tool.id] == tool.name)
                continue;
              visibleTools[tool.id] = tool.name;
              onToolProgress?.call(
                AiProviderToolProgress(
                  id: tool.id,
                  name: toolNames
                      .toInternalReply(
                        AiProviderReply(
                          toolCalls: [
                            AiProviderToolCall(
                              id: tool.id,
                              name: tool.name,
                              arguments: '{}',
                            ),
                          ],
                        ),
                      )
                      .toolCalls
                      .single
                      .name,
                ),
              );
            }
          }

          flushStream = () => publish(retainReceived: true);

          try {
            await for (final event in aiSseData(
              response.stream.timeout(timeout),
            )) {
              cancellation.check();
              accumulated.add(event);
              if (firstUpdate && accumulated.hasContent) {
                firstUpdate = false;
                publish();
              } else if (!firstUpdate) {
                updateTimer ??= Timer(
                  const Duration(milliseconds: 32),
                  publish,
                );
              }
              if (accumulated.done) break;
            }
          } finally {
            publish();
          }
          data = _redact(accumulated.finish(), config);
        } else {
          final body = await cancellation.race(
            response.stream.toBytes(),
            timeout: timeout,
          );
          data = _redact(jsonDecode(utf8.decode(body)), config);
        }
        cancellation.check();
        if (data is! Map<String, Object?>) throw const FormatException();
        try {
          return toolNames.toInternalReply(
            normalizeAiToolReply(
              _reply(config.protocol, data),
              toolNames.acceptedTools,
            ),
          );
        } on AiProviderException {
          rethrow;
        } catch (_) {
          throw const FormatException();
        }
      }

      return await Future.any<AiProviderReply>([
        receive(),
        cancellation.signal.then(
          (_) => throw const AiProviderException('cancelled', '已停止生成'),
        ),
      ]);
    } on AiProviderException catch (error) {
      throw AiProviderException(
        error.code,
        config.redact(error.message),
        retryAfter: error.retryAfter,
      );
    } on FormatException {
      throw const AiProviderException('response', 'AI 服务返回的数据无法读取，请检查所选协议');
    } on TimeoutException catch (error) {
      throw AiProviderException('timeout', config.redact(error.toString()));
    } catch (error) {
      cancellation.check();
      throw AiProviderException('network', config.redact(error.toString()));
    } finally {
      flushStream = null;
      abortRequest();
      client.close();
    }
  }

  Object? _redact(Object? value, AiProviderConfig config) =>
      _redactProviderValue(value, config);

  Map<String, Object?> _body(
    AiProviderConfig config,
    String system,
    List<AiProviderMessage> messages,
    List<Map<String, Object?>> tools,
    int? maxOutputTokens,
    bool promptCache,
    bool allowToolCalls,
  ) {
    final common = <String, Object?>{
      'model': config.model.trim(),
      'stream': config.streaming,
    };
    switch (config.protocol) {
      case AiProviderProtocol.chatCompletions:
        return {
          ...common,
          if (!allowToolCalls && tools.isNotEmpty) 'tool_choice': 'none',
          'max_tokens': ?maxOutputTokens,
          ...aiReasoningParameters(config, maxOutputTokens: maxOutputTokens),
          'messages': [
            {'role': 'system', 'content': system},
            for (final message in messages)
              {
                'role': message.role == AiProviderRole.context
                    ? 'system'
                    : message.role.name,
                'content': message.attachments.isNotEmpty
                    ? _attachmentContent(config, message)
                    : message.text.isEmpty && message.toolCalls.isNotEmpty
                    ? null
                    : message.text,
                if (message.role == AiProviderRole.tool)
                  'tool_call_id': message.toolCallId,
                if (message.role == AiProviderRole.assistant &&
                    message.reasoning.isNotEmpty)
                  'reasoning_content': message.reasoning,
                if (message.toolCalls.isNotEmpty)
                  'tool_calls': [
                    for (final call in message.toolCalls)
                      {
                        'id': call.id,
                        'type': 'function',
                        'function': {
                          'name': _shortToolName(call.name),
                          'arguments': call.arguments,
                        },
                      },
                  ],
              },
          ],
          if (tools.isNotEmpty)
            'tools': [
              for (final tool in tools)
                {
                  'type': 'function',
                  'function': {
                    'name': _shortToolName(tool['name'] as String),
                    'description': _toolDescription(tool),
                    'parameters': tool['inputSchema'],
                  },
                },
            ],
        };
      case AiProviderProtocol.responses:
        return {
          ...common,
          if (!allowToolCalls && tools.isNotEmpty) 'tool_choice': 'none',
          'max_output_tokens': ?maxOutputTokens,
          'store': false,
          'include': ['reasoning.encrypted_content'],
          ...aiReasoningParameters(config, maxOutputTokens: maxOutputTokens),
          'instructions': system,
          'input': [
            for (final message in messages)
              if (message.role == AiProviderRole.tool)
                {
                  'type': 'function_call_output',
                  'call_id': message.toolCallId,
                  'output': message.text,
                }
              else if (message.responsesOutput.isNotEmpty)
                for (final item in message.responsesOutput)
                  _projectResponseToolName(item, _shortToolName)
              else ...[
                if (message.text.isNotEmpty || message.attachments.isNotEmpty)
                  {
                    'role': message.role == AiProviderRole.context
                        ? 'developer'
                        : message.role.name,
                    'content': message.attachments.isEmpty
                        ? message.text
                        : _attachmentContent(config, message),
                  },
                for (final call in message.toolCalls)
                  {
                    'type': 'function_call',
                    'call_id': call.id,
                    'name': _shortToolName(call.name),
                    'arguments': call.arguments,
                  },
              ],
          ],
          if (tools.isNotEmpty)
            'tools': [
              for (final tool in tools)
                {
                  'type': 'function',
                  'name': _shortToolName(tool['name'] as String),
                  'description': _toolDescription(tool),
                  'parameters': tool['inputSchema'],
                  'strict': false,
                },
            ],
        };
      case AiProviderProtocol.anthropicMessages:
        final turns = <Map<String, Object?>>[];
        for (final message in messages) {
          final role = message.role == AiProviderRole.assistant
              ? 'assistant'
              : 'user';
          final content = <Map<String, Object?>>[
            if (message.role == AiProviderRole.tool)
              {
                'type': 'tool_result',
                'tool_use_id': message.toolCallId,
                'content': message.text,
                'is_error': message.isError,
              }
            else ...[
              ...message.anthropicThinking,
              if (message.text.isNotEmpty)
                {'type': 'text', 'text': message.text},
              if (message.attachments.isNotEmpty)
                ..._attachmentContent(
                  config,
                  message,
                  includeMessageText: false,
                ),
              for (final call in message.toolCalls)
                {
                  'type': 'tool_use',
                  'id': call.id,
                  'name': _shortToolName(call.name),
                  'input': jsonDecode(call.arguments),
                },
            ],
          ];
          if (turns.isNotEmpty && turns.last['role'] == role) {
            (turns.last['content'] as List).addAll(content);
          } else {
            turns.add({'role': role, 'content': content});
          }
        }
        if (promptCache && turns.isNotEmpty) {
          final blocks = turns.last['content'] as List;
          if (blocks.isNotEmpty &&
              !{
                'thinking',
                'redacted_thinking',
              }.contains((blocks.last as Map)['type'])) {
            (blocks.last as Map)['cache_control'] = {'type': 'ephemeral'};
          }
        }
        return {
          ...common,
          'max_tokens': maxOutputTokens ?? 4096,
          ...aiReasoningParameters(config, maxOutputTokens: maxOutputTokens),
          'system': promptCache
              ? [
                  {
                    'type': 'text',
                    'text': system,
                    'cache_control': {'type': 'ephemeral'},
                  },
                ]
              : system,
          'messages': turns,
          if (!allowToolCalls && tools.isNotEmpty)
            'tool_choice': {'type': 'none'},
          if (tools.isNotEmpty)
            'tools': [
              for (var i = 0; i < tools.length; i++)
                {
                  'name': _shortToolName(tools[i]['name'] as String),
                  'description': _toolDescription(tools[i]),
                  'input_schema': tools[i]['inputSchema'],
                  if (promptCache && i == tools.length - 1)
                    'cache_control': {'type': 'ephemeral'},
                },
            ],
        };
    }
  }

  AiProviderReply _reply(
    AiProviderProtocol protocol,
    Map<String, Object?> data,
  ) {
    if (data['error'] != null || data['type'] == 'error') {
      throw aiProviderFailure(jsonEncode(data));
    }
    final calls = <AiProviderToolCall>[];
    final texts = <String>[];
    final output = <Map<String, Object?>>[];
    final reasoning = <String>[];
    final anthropicThinking = <Map<String, Object?>>[];
    String? normalizeArguments(Object? value) {
      if (value is String) return value;
      if (value is Map) return jsonEncode(value);
      return null;
    }

    void addCall(Object? id, Object? name, Object? arguments) {
      final normalizedArguments = normalizeArguments(arguments);
      if (id is! String ||
          id.isEmpty ||
          name is! String ||
          name.isEmpty ||
          normalizedArguments == null ||
          calls.any((call) => call.id == id) ||
          calls.length >= 16) {
        throw const FormatException();
      }
      calls.add(
        AiProviderToolCall(id: id, name: name, arguments: normalizedArguments),
      );
    }

    switch (protocol) {
      case AiProviderProtocol.chatCompletions:
        final choices = data['choices'];
        if (choices is! List || choices.isEmpty || choices.first is! Map) {
          throw const FormatException();
        }
        final choice = choices.first as Map;
        final message = choice['message'];
        if (message is! Map) throw const FormatException();
        if (message['content'] case final String text) texts.add(text);
        if (message['refusal'] case final String text) texts.add(text);
        if (message['reasoning_content'] case final String text)
          reasoning.add(text);
        for (final call in message['tool_calls'] as List? ?? const []) {
          addCall(
            call['id'],
            call['function']['name'],
            call['function']['arguments'],
          );
        }
      case AiProviderProtocol.responses:
        if (data['error'] != null) {
          throw const AiProviderException(
            'incomplete',
            'AI 回答未完整生成，请调整问题或模型后继续',
          );
        }
        final items = data['output'];
        if (items is! List) throw const FormatException();
        for (final item in items) {
          if (item is! Map<String, Object?>) throw const FormatException();
          output.add(item);
          if (item['type'] == 'function_call') {
            addCall(
              item['call_id'] ?? item['id'],
              item['name'],
              item['arguments'],
            );
          } else if (item['type'] == 'message') {
            for (final block in item['content'] as List? ?? const []) {
              if (block['type'] == 'output_text' && block['text'] is String) {
                texts.add(block['text']);
              }
              if (block['type'] == 'refusal' && block['refusal'] is String) {
                texts.add(block['refusal']);
              }
            }
          } else if (item['type'] == 'reasoning') {
            for (final block in item['summary'] as List? ?? const []) {
              if (block['type'] == 'summary_text' && block['text'] is String) {
                reasoning.add(block['text'] as String);
              }
            }
          }
        }
      case AiProviderProtocol.anthropicMessages:
        if (data['type'] == 'error' || data['stop_reason'] == 'max_tokens') {
          throw const AiProviderException(
            'incomplete',
            'AI 回答未完整生成，请调整问题或模型后继续',
          );
        }
        final content = data['content'];
        if (content is! List) throw const FormatException();
        for (final block in content) {
          if (block['type'] == 'thinking' ||
              block['type'] == 'redacted_thinking') {
            anthropicThinking.add(Map<String, Object?>.from(block as Map));
            if (block['thinking'] case final String text) reasoning.add(text);
          }
          if (block['type'] == 'text' && block['text'] is String) {
            texts.add(block['text']);
          }
          if (block['type'] == 'tool_use') {
            if (block['input'] is! Map) throw const FormatException();
            addCall(block['id'], block['name'], jsonEncode(block['input']));
          }
        }
    }
    if (texts.join().trim().isEmpty &&
        calls.isEmpty &&
        reasoning.join().trim().isEmpty) {
      if (data['status'] == 'failed' || data['status'] == 'incomplete') {
        throw const AiProviderException('incomplete', 'AI 回答未完整生成，请调整问题或模型后继续');
      }
      throw const AiProviderException('empty_response', '模型未返回可用答复');
    }
    return AiProviderReply(
      text: texts.join('\n'),
      toolCalls: List.unmodifiable(calls),
      responsesOutput: output,
      reasoning: reasoning.join('\n'),
      anthropicThinking: anthropicThinking,
      usage: AiProviderUsage(
        inputTokens:
            protocol == AiProviderProtocol.anthropicMessages &&
                (data['usage'] as Map?)?['input_tokens'] is int
            ? ((data['usage'] as Map)['input_tokens'] as int) +
                  ((data['usage'] as Map)['cache_read_input_tokens'] as int? ??
                      0) +
                  ((data['usage'] as Map)['cache_creation_input_tokens']
                          as int? ??
                      0)
            : (data['usage'] as Map?)?['input_tokens'] as int? ??
                  (data['usage'] as Map?)?['prompt_tokens'] as int?,
        outputTokens:
            (data['usage'] as Map?)?['output_tokens'] as int? ??
            (data['usage'] as Map?)?['completion_tokens'] as int?,
        cachedInputTokens:
            (data['usage'] as Map?)?['prompt_cache_hit_tokens'] as int? ??
            (data['usage'] as Map?)?['cache_read_input_tokens'] as int? ??
            ((data['usage'] as Map?)?['prompt_tokens_details']
                    as Map?)?['cached_tokens']
                as int? ??
            ((data['usage'] as Map?)?['input_tokens_details']
                    as Map?)?['cached_tokens']
                as int?,
      ),
    );
  }

  Future<List<String>> listModels({
    required AiProviderConfig config,
    required AiChatCancellation cancellation,
  }) => _retry(
    cancellation,
    (_) => _listModelsOnce(config: config, cancellation: cancellation),
  );

  Future<List<String>> _listModelsOnce({
    required AiProviderConfig config,
    required AiChatCancellation cancellation,
  }) async {
    config.validate(requireModel: false);
    cancellation.check();
    final client = _clientFactory();
    final abort = Completer<void>();
    void abortRequest() {
      if (!abort.isCompleted) abort.complete();
    }

    unawaited(cancellation.signal.then((_) => abortRequest()));
    try {
      final endpoint = config.endpoint;
      final uri = endpoint.replace(
        path:
            '${endpoint.path.substring(0, endpoint.path.length - config.protocol.path.length)}/models',
      );
      final ids = <String>{};
      final pages = <String>{};
      String? after;
      for (var page = 0; page < 8; page++) {
        final pageUri = config.protocol == AiProviderProtocol.anthropicMessages
            ? uri.replace(queryParameters: {'limit': '100', 'after_id': ?after})
            : uri;
        final request = http.AbortableRequest(
          'GET',
          pageUri,
          abortTrigger: abort.future,
        )..followRedirects = false;
        request.headers.addAll({
          'Accept': 'application/json',
          if (config.protocol == AiProviderProtocol.anthropicMessages) ...{
            'x-api-key': config.apiKey,
            'anthropic-version': '2023-06-01',
          } else
            'Authorization': 'Bearer ${config.apiKey}',
        });
        final streamed = await cancellation.race(
          client.send(request),
          timeout: timeout,
        );
        if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
          throw await _httpFailure(streamed, config, cancellation);
        }
        final response = await cancellation.race(
          http.Response.fromStream(streamed),
          timeout: timeout,
        );
        cancellation.check();
        final value = jsonDecode(utf8.decode(response.bodyBytes));
        if (value is! Map || value['data'] is! List) {
          throw const FormatException();
        }
        ids.addAll(
          (value['data'] as List)
              .whereType<Map>()
              .map((model) => model['id'])
              .whereType<String>()
              .map(config.redact)
              .where((model) => model.isNotEmpty),
        );
        if (config.protocol != AiProviderProtocol.anthropicMessages ||
            value['has_more'] != true) {
          break;
        }
        after = value['last_id'] as String?;
        if (after == null || !pages.add(after)) break;
      }
      return ids.toList()..sort();
    } on AiProviderException {
      rethrow;
    } catch (_) {
      cancellation.check();
      throw const AiProviderException('models', '模型列表暂时无法读取，可以手动填写模型名称');
    } finally {
      abortRequest();
      client.close();
    }
  }
}

String _shortToolName(String name) => aiCanonicalToolName(name);

final _legacyToolReference = RegExp(r'\becjtu_([a-z][a-z0-9_]*)\b');

String _shortToolReferences(String text) =>
    text.replaceAllMapped(_legacyToolReference, (match) => match[1]!);

String _providerSystem(
  String system,
  List<AiProviderMessage> messages,
  List<Map<String, Object?>> tools,
) {
  final canonical = _shortToolReferences(system);
  if (!tools.any(
    (tool) => const {
      'get_data',
      'list_actions',
    }.contains(_shortToolName(tool['name'] as String)),
  )) {
    return canonical;
  }
  for (var i = messages.length - 1; i >= 0; i--) {
    if (messages[i].role != AiProviderRole.user) continue;
    final guidance = AiChatTools.providerTaskGuidance(messages[i].text);
    return guidance.isEmpty ? canonical : '$canonical\n$guidance';
  }
  return canonical;
}

Object? _toolDescription(Map<String, Object?> tool) {
  final description = tool['description'];
  return description is String
      ? _shortToolReferences(description)
      : description;
}

Map<String, Object?> _projectResponseToolName(
  Map<String, Object?> item,
  String Function(String) project,
) {
  if (item['type'] != 'function_call' || item['name'] is! String) {
    return item;
  }
  final original = item['name'] as String;
  final name = project(original);
  return name == original ? item : {...item, 'name': name};
}

class _ProviderToolNames {
  _ProviderToolNames(List<Map<String, Object?>> tools) {
    final canonicalNames = <String>{};
    for (final tool in tools) {
      final internal = tool['name'];
      if (internal is! String || internal.isEmpty) throw _toolNameError;
      final canonical = _shortToolName(internal);
      if (canonical.isEmpty || !canonicalNames.add(canonical)) {
        throw _toolNameError;
      }
      for (final alias in {
        canonical,
        internal,
        ...aiLegacyToolNames(canonical),
      }) {
        final previous = _internalNames[alias];
        if (previous != null && previous != internal) throw _toolNameError;
        _internalNames[alias] = internal;
      }
    }
    acceptedTools = [
      for (final name in _internalNames.keys) {'name': name},
    ];
  }

  final _internalNames = <String, String>{};
  late final List<Map<String, Object?>> acceptedTools;

  String _internalName(String name) =>
      _internalNames[name] ?? (throw _toolNameError);

  AiProviderReply toInternalReply(AiProviderReply reply) {
    if (reply.toolCalls.isEmpty) return reply;
    final calls = [
      for (final call in reply.toolCalls)
        AiProviderToolCall(
          id: call.id,
          name: _internalName(call.name),
          arguments: call.arguments,
        ),
    ];
    return AiProviderReply(
      text: reply.text,
      toolCalls: List.unmodifiable(calls),
      responsesOutput: [
        for (final item in reply.responsesOutput)
          _projectResponseToolName(item, _internalName),
      ],
      usage: reply.usage,
      reasoning: reply.reasoning,
      anthropicThinking: reply.anthropicThinking,
    );
  }
}

const _toolNameError = AiProviderException(
  'tool_format',
  'AI 服务返回的工具格式无法识别，请检查接口兼容性',
);

void _validateAttachments(
  AiProviderConfig config,
  List<AiProviderMessage> messages,
) {
  var totalBytes = 0;
  for (final message in messages) {
    if (message.attachments.isEmpty) continue;
    if (message.role != AiProviderRole.user ||
        message.attachments.length > AiAttachmentReader.maxAttachments) {
      throw const AiProviderException('attachment_type', '附件仅可添加到用户消息');
    }
    for (final a in message.attachments) {
      final image = a.summary.kind == AiAttachmentKind.image;
      if (!a.supportedBy(config.modelCapabilities)) {
        throw AiProviderException(
          'attachment_unsupported',
          image ? '当前模型未开启图片识别，请选择支持图片的模型' : '当前模型未开启 PDF 支持，请选择支持文件的模型',
        );
      }
      if (a.summary.byteLength <= 0 ||
          a.summary.byteLength >
              (image
                  ? AiAttachmentReader.maxImageBytes
                  : AiAttachmentReader.maxFileBytes) ||
          a.extractedText.length > AiAttachmentReader.maxTextCharacters) {
        throw const AiProviderException('attachment_size', '附件过大，请缩小或拆分后重试');
      }
      if ((a.extractedText.isEmpty ||
              a.usesNativePdf(config.modelCapabilities)) &&
          (a.encodedData.isEmpty ||
              a.encodedData.length > (a.summary.byteLength + 2) ~/ 3 * 4 ||
              (image
                  ? !{
                      'image/png',
                      'image/jpeg',
                      'image/gif',
                      'image/webp',
                    }.contains(a.summary.mimeType)
                  : a.summary.mimeType != 'application/pdf'))) {
        throw const AiProviderException('attachment_type', '附件内容无法使用，请重新选择');
      }
      if (a.extractedText.isEmpty || a.usesNativePdf(config.modelCapabilities))
        totalBytes += a.summary.byteLength;
    }
  }
  if (totalBytes > AiAttachmentReader.maxTotalBytes) {
    throw const AiProviderException(
      'attachment_size',
      '本次请求附件超过 32 MB，请新建对话或减少附件',
    );
  }
}

List<Map<String, Object?>> _attachmentContent(
  AiProviderConfig config,
  AiProviderMessage message, {
  bool includeMessageText = true,
}) {
  final protocol = config.protocol;
  String textType = protocol == AiProviderProtocol.responses
      ? 'input_text'
      : 'text';
  final blocks = <Map<String, Object?>>[
    if (includeMessageText && message.text.isNotEmpty)
      {'type': textType, 'text': message.text},
  ];
  for (final a in message.attachments) {
    if (a.extractedText.isNotEmpty &&
        !a.usesNativePdf(config.modelCapabilities)) {
      blocks.add({'type': textType, 'text': a.textForModel});
      continue;
    }
    final dataUri = 'data:${a.summary.mimeType};base64,${a.encodedData}';
    final image = a.summary.kind == AiAttachmentKind.image;
    blocks.add({
      'type': textType,
      'text': image ? a.textForModel : '附件：${a.summary.name}',
    });
    blocks.add(switch (protocol) {
      AiProviderProtocol.chatCompletions when image => {
        'type': 'image_url',
        'image_url': {'url': dataUri},
      },
      AiProviderProtocol.chatCompletions => {
        'type': 'file',
        'file': {'filename': a.summary.name, 'file_data': dataUri},
      },
      AiProviderProtocol.responses when image => {
        'type': 'input_image',
        'image_url': dataUri,
      },
      AiProviderProtocol.responses => {
        'type': 'input_file',
        'filename': a.summary.name,
        'file_data': dataUri,
      },
      AiProviderProtocol.anthropicMessages => {
        'type': image ? 'image' : 'document',
        if (!image) 'title': a.summary.name,
        'source': {
          'type': 'base64',
          'media_type': a.summary.mimeType,
          'data': a.encodedData,
        },
      },
    });
  }
  return blocks;
}

String _encodeProviderBody(
  ({Map<String, Object?> body, AiProviderConfig config}) request,
) => jsonEncode(_redactProviderValue(request.body, request.config));

Object? _redactProviderValue(Object? value, AiProviderConfig config) =>
    switch (value) {
      String() => config.redact(value),
      List() =>
        value.map((item) => _redactProviderValue(item, config)).toList(),
      Map() => <String, Object?>{
        for (final entry in value.entries)
          config.redact(entry.key.toString()): _redactProviderValue(
            entry.value,
            config,
          ),
      },
      _ => value,
    };
