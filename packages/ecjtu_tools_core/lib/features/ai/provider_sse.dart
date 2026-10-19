// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:convert';

import 'provider_models.dart';
import 'provider_errors.dart';

Stream<String> aiSseData(Stream<List<int>> bytes) async* {
  final data = <String>[];
  await for (var line
      in bytes.transform(utf8.decoder).transform(const LineSplitter())) {
    line = line.replaceFirst(RegExp(r'^\uFEFF'), '');
    if (line.isEmpty) {
      if (data.isNotEmpty) {
        yield data.join('\n');
        data.clear();
      }
    } else if (line.startsWith('data:')) {
      var value = line.substring(5);
      if (value.startsWith(' ')) value = value.substring(1);
      data.add(value);
    }
  }
  if (data.isNotEmpty) yield data.join('\n');
}

class AiSseAccumulator {
  AiSseAccumulator(this.protocol);
  final AiProviderProtocol protocol;
  final _calls = <int, Map<String, Object?>>{};
  final _thinking = <int, Map<String, Object?>>{};
  final _text = StringBuffer();
  final _reasoning = StringBuffer();
  String? _textSnapshot;
  String? _reasoningSnapshot;
  String get text => _textSnapshot ??= _text.toString();
  String get reasoning => _reasoningSnapshot ??= _reasoning.toString();
  bool get hasContent =>
      _text.isNotEmpty || _reasoning.isNotEmpty || toolProgress.isNotEmpty;
  List<AiProviderToolProgress> get toolProgress => [
    for (final call in _calls.values)
      if (call['id'] is String &&
          call['name'] is String &&
          (call['name'] as String).isNotEmpty)
        AiProviderToolProgress(
          id: call['id'] as String,
          name: call['name'] as String,
        ),
    for (final item in _responseItems.values)
      if (item['type'] == 'function_call' &&
          item['call_id'] is String &&
          item['name'] is String &&
          (item['name'] as String).isNotEmpty)
        AiProviderToolProgress(
          id: item['call_id'] as String,
          name: item['name'] as String,
        ),
  ];

  void _appendText(String fragment) {
    if (fragment.isEmpty) return;
    _text.write(fragment);
    _textSnapshot = null;
  }

  void _appendReasoning(String fragment) {
    if (fragment.isEmpty) return;
    _reasoning.write(fragment);
    _reasoningSnapshot = null;
  }

  String? _finish;
  bool done = false;
  Map<String, Object?>? _response;
  Map<String, Object?> _usage = {};
  final _responseItems = <int, Map<String, Object?>>{};
  final _responseItemIds = <String, int>{};

  void add(String event) {
    if (done) return;
    if (event == '[DONE]') {
      if (protocol == AiProviderProtocol.chatCompletions) done = true;
      return;
    }
    final value = jsonDecode(event);
    if (value is! Map<String, Object?>) throw const FormatException();
    if (value['error'] != null || value['type'] == 'error') {
      throw aiProviderFailure(event);
    }
    if (protocol != AiProviderProtocol.anthropicMessages &&
        value['usage'] is Map) {
      _usage = _mergeUsage(_usage, value['usage'] as Map);
    }
    switch (protocol) {
      case AiProviderProtocol.chatCompletions:
        final choices = value['choices'];
        if (choices is! List) throw const FormatException();
        if (choices.isEmpty) return;
        final choice = choices.first as Map;
        if (choice['finish_reason'] != null) {
          _finish = choice['finish_reason'] as String;
        }
        final delta = choice['delta'] as Map? ?? const {};
        _appendText(
          delta['content'] as String? ?? delta['refusal'] as String? ?? '',
        );
        _appendReasoning(delta['reasoning_content'] as String? ?? '');
        for (final call in delta['tool_calls'] as List? ?? const []) {
          final index = _index(call['index']);
          final accumulated = _calls.putIfAbsent(
            index,
            () => {'id': '', 'name': '', 'arguments': ''},
          );
          if (call['id'] != null) accumulated['id'] = call['id'];
          final function = call['function'] as Map? ?? const {};
          accumulated['name'] =
              '${accumulated['name']}${function['name'] ?? ''}';
          accumulated['arguments'] =
              '${accumulated['arguments']}${function['arguments'] ?? ''}';
        }
      case AiProviderProtocol.responses:
        switch (value['type']) {
          case 'response.output_text.delta':
          case 'response.refusal.delta':
            _appendText(value['delta'] as String? ?? '');
          case 'response.reasoning_summary_text.delta':
            _appendReasoning(value['delta'] as String? ?? '');
          case 'response.output_item.added':
            final index = _index(value['output_index']);
            final item = value['item'];
            if (item is! Map) throw const FormatException();
            final normalized = Map<String, Object?>.from(item);
            if (normalized['id'] case final String id when id.isNotEmpty) {
              _responseItemIds[id] = index;
            }
            _responseItems[index] = _mergeOutputItem(
              _responseItems[index],
              normalized,
            );
          case 'response.function_call_arguments.delta':
            final index = _responseIndex(value);
            final item = _responseItems.putIfAbsent(index, () => {});
            item['arguments'] =
                '${item['arguments'] ?? ''}${value['delta'] ?? ''}';
          case 'response.function_call_arguments.done':
            final index = _responseIndex(value);
            final item = _responseItems.putIfAbsent(index, () => {});
            final arguments = value['arguments'];
            if (arguments is String || arguments is Map) {
              item['arguments'] = arguments;
            }
          case 'response.output_item.done':
            final index = _responseIndex(value);
            final item = value['item'];
            if (item is! Map) throw const FormatException();
            final normalized = Map<String, Object?>.from(item);
            if (normalized['id'] case final String id when id.isNotEmpty) {
              _responseItemIds[id] = index;
            }
            _responseItems[index] = _mergeOutputItem(
              _responseItems[index],
              normalized,
            );
          case 'response.completed':
            final response = value['response'];
            if (response is! Map<String, Object?>) {
              throw const FormatException();
            }
            _response = Map<String, Object?>.from(response);
            final responseOutput = _response!['output'];
            if (responseOutput is List && responseOutput.isNotEmpty) {
              _response!['output'] = [
                for (var index = 0; index < responseOutput.length; index++)
                  responseOutput[index] is Map
                      ? _mergeOutputItem(
                          _responseItems[index],
                          Map<String, Object?>.from(
                            responseOutput[index] as Map,
                          ),
                        )
                      : responseOutput[index],
              ];
            } else if (_responseItems.isNotEmpty) {
              _response!['output'] = [
                for (final index in _responseItems.keys.toList()..sort())
                  _responseItems[index],
              ];
            }
            done = true;
          case 'response.failed':
          case 'response.incomplete':
            final response = value['response'];
            if (response is Map) {
              _response = Map<String, Object?>.from(response);
              final output = _response!['output'];
              if (output is List && output.isNotEmpty) {
                _response!['output'] = [
                  for (var index = 0; index < output.length; index++)
                    output[index] is Map
                        ? _mergeOutputItem(
                            _responseItems[index],
                            Map<String, Object?>.from(output[index] as Map),
                          )
                        : output[index],
                ];
              } else if (_responseItems.isNotEmpty) {
                _response!['output'] = [
                  for (final index in _responseItems.keys.toList()..sort())
                    _responseItems[index],
                ];
              }
            }
            // A provider can mark a response incomplete after emitting a
            // usable message or a complete function call. Let the normal
            // reply parser decide whether anything executable remains.
            done = true;
        }
      case AiProviderProtocol.anthropicMessages:
        switch (value['type']) {
          case 'message_start':
            _usage = Map<String, Object?>.from(
              (value['message'] as Map?)?['usage'] as Map? ?? const {},
            );
          case 'content_block_start':
            final block = value['content_block'] as Map;
            if (block['type'] == 'text')
              _appendText(block['text'] as String? ?? '');
            if (block['type'] == 'thinking' ||
                block['type'] == 'redacted_thinking') {
              _thinking[_index(value['index'])] = Map<String, Object?>.from(
                block,
              );
              _appendReasoning(block['thinking'] as String? ?? '');
            }
            if (block['type'] == 'tool_use') {
              _calls[_index(value['index'])] = {
                'id': block['id'],
                'name': block['name'],
                'arguments': '',
                'input': block['input'] ?? <String, Object?>{},
              };
            }
          case 'content_block_delta':
            final delta = value['delta'] as Map;
            if (delta['type'] == 'text_delta') {
              _appendText(delta['text'] as String? ?? '');
            }
            if (delta['type'] == 'thinking_delta' ||
                delta['type'] == 'signature_delta') {
              final block = _thinking[_index(value['index'])];
              if (block == null) throw const FormatException();
              final key = delta['type'] == 'thinking_delta'
                  ? 'thinking'
                  : 'signature';
              final fragment = delta[key] as String? ?? '';
              block[key] = '${block[key] ?? ''}$fragment';
              if (key == 'thinking') _appendReasoning(fragment);
            }
            if (delta['type'] == 'input_json_delta') {
              final call = _calls[_index(value['index'])];
              if (call == null) throw const FormatException();
              call['arguments'] =
                  '${call['arguments']}${delta['partial_json'] ?? ''}';
            }
          case 'message_delta':
            if (value['usage'] is Map) {
              _usage = {
                ..._usage,
                ...Map<String, Object?>.from(value['usage'] as Map),
              };
            }
            _finish = (value['delta'] as Map?)?['stop_reason'] as String?;
          case 'message_stop':
            done = true;
        }
    }
  }

  Map<String, Object?> _mergeUsage(Map previous, Map next) => {
    for (final entry in previous.entries) entry.key.toString(): entry.value,
    for (final entry in next.entries)
      if (entry.value != null)
        entry.key.toString(): entry.value is Map && previous[entry.key] is Map
            ? _mergeUsage(previous[entry.key] as Map, entry.value as Map)
            : entry.value,
  };

  Map<String, Object?> _mergeOutputItem(
    Map<String, Object?>? previous,
    Map<String, Object?> current,
  ) {
    final merged = <String, Object?>{...?previous, ...current};
    for (final key in ['id', 'call_id', 'name', 'type']) {
      if ((merged[key] == null || merged[key] == '') &&
          previous?[key] != null) {
        merged[key] = previous![key];
      }
    }
    final previousArguments = previous?['arguments'];
    final currentArguments = current['arguments'];
    if ((currentArguments == null || currentArguments == '') &&
        previousArguments != null) {
      merged['arguments'] = previousArguments;
    }
    return merged;
  }

  int _responseIndex(Map<String, Object?> value) {
    final outputIndex = value['output_index'];
    if (outputIndex is int) return _index(outputIndex);
    final itemId = value['item_id'];
    final index = itemId is String ? _responseItemIds[itemId] : null;
    if (index != null) return index;
    throw const FormatException();
  }

  int _index(Object? value) {
    if (value is! int || value < 0 || value > 63 || _calls.length > 16) {
      throw const FormatException();
    }
    return value;
  }

  Map<String, Object?> finish() {
    if (!done &&
        !(protocol == AiProviderProtocol.chatCompletions && _finish != null)) {
      throw const AiProviderException('incomplete', '连接已中断，请根据已收内容继续');
    }
    switch (protocol) {
      case AiProviderProtocol.chatCompletions:
        return {
          'usage': _usage,
          'choices': [
            {
              'finish_reason': _finish,
              'message': {
                'content': text,
                if (reasoning.isNotEmpty) 'reasoning_content': reasoning,
                'tool_calls': [
                  for (final call in _calls.values)
                    {
                      'id': call['id'],
                      'type': 'function',
                      'function': {
                        'name': call['name'],
                        'arguments': call['arguments'],
                      },
                    },
                ],
              },
            },
          ],
        };
      case AiProviderProtocol.responses:
        if (_response == null) throw const FormatException();
        return _response!;
      case AiProviderProtocol.anthropicMessages:
        return {
          'usage': _usage,
          'type': 'message',
          'stop_reason': _finish,
          'content': [
            ..._thinking.values,
            if (text.isNotEmpty) {'type': 'text', 'text': text},
            for (final call in _calls.values)
              {
                'type': 'tool_use',
                'id': call['id'],
                'name': call['name'],
                'input': (call['arguments'] as String).isEmpty
                    ? call['input']
                    : jsonDecode(call['arguments'] as String),
              },
          ],
        };
    }
  }
}
