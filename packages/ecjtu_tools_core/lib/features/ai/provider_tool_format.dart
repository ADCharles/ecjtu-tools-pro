// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:convert';

import 'provider_models.dart';

String visibleAiReplyText(String text) {
  final marker = RegExp(
    r'<\s*[｜|]\s*(?:DSML)?',
    caseSensitive: false,
  ).firstMatch(text);
  return marker == null ? text : text.substring(0, marker.start).trimRight();
}

AiProviderReply normalizeAiToolReply(
  AiProviderReply reply,
  List<Map<String, Object?>> tools,
) {
  final text = reply.text.replaceAllMapped(
    RegExp(
      r'<(/?)\s*[｜|]\s*DSML\s*[｜|]\s*(.*?)>',
      dotAll: true,
      caseSensitive: false,
    ),
    (match) => '<${match[1]}|DSML|${match[2]}>',
  );
  final opening = RegExp(
    r'<\|DSML\|(?:function_calls|calls)>',
    caseSensitive: false,
  ).firstMatch(text);
  if (opening == null) {
    if (visibleAiReplyText(reply.text) != reply.text) throw _formatError;
    return reply;
  }
  if (reply.toolCalls.isNotEmpty) throw _formatError;
  final prefix = text.substring(0, opening.start);
  if ((prefix.split('```').length - 1).isOdd ||
      (prefix.split('`').length - 1).isOdd)
    throw _formatError;
  final closing = RegExp(
    r'</\|DSML\|(?:function_calls|calls)>',
    caseSensitive: false,
  ).firstMatch(text.substring(opening.end));
  if (closing == null) throw _formatError;
  final end = opening.end + closing.end;
  final block = text.substring(opening.end, opening.end + closing.start);
  final calls = <AiProviderToolCall>[];
  var consumed = 0;
  final invocations = RegExp(
    r'<\|DSML\|invoke\b([^>]*)>(.*?)</\|DSML\|invoke>',
    dotAll: true,
    caseSensitive: false,
  );
  for (final invocation in invocations.allMatches(block)) {
    if (block.substring(consumed, invocation.start).trim().isNotEmpty ||
        calls.length >= 16)
      throw _formatError;
    consumed = invocation.end;
    final name = _attribute(invocation[1]!, 'name');
    if (name == null || !tools.any((tool) => tool['name'] == name))
      throw _formatError;
    final args = <String, Object?>{};
    final content = invocation[2]!;
    var parameterEnd = 0;
    for (final parameter in RegExp(
      r'<\|DSML\|parameter\b([^>]*)>(.*?)</\|DSML\|parameter>',
      dotAll: true,
      caseSensitive: false,
    ).allMatches(content)) {
      if (content.substring(parameterEnd, parameter.start).trim().isNotEmpty)
        throw _formatError;
      parameterEnd = parameter.end;
      final key = _attribute(parameter[1]!, 'name');
      final string = _attribute(parameter[1]!, 'string');
      if (key == null ||
          args.containsKey(key) ||
          (string != 'true' && string != 'false'))
        throw _formatError;
      final value = _entities(parameter[2]!);
      try {
        args[key] = string == 'true' ? value : jsonDecode(value);
      } on FormatException {
        throw _formatError;
      }
    }
    if (content.substring(parameterEnd).trim().isNotEmpty) throw _formatError;
    calls.add(
      AiProviderToolCall(
        id: 'dsml_${DateTime.now().microsecondsSinceEpoch}_${calls.length}',
        name: name,
        arguments: jsonEncode(args),
      ),
    );
  }
  if (calls.isEmpty ||
      block.substring(consumed).trim().isNotEmpty ||
      text.substring(end).contains('<|DSML|'))
    throw _formatError;
  return AiProviderReply(
    text:
        '${prefix.trimRight()}${text.substring(end).isEmpty ? '' : '\n${text.substring(end).trimLeft()}'}'
            .trim(),
    toolCalls: calls,
    responsesOutput: reply.responsesOutput,
    usage: reply.usage,
    reasoning: reply.reasoning,
    anthropicThinking: reply.anthropicThinking,
  );
}

String? _attribute(String attributes, String name) =>
    RegExp('$name\\s*=\\s*"([^"]*)"').firstMatch(attributes)?[1];

String _entities(String value) => value
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&quot;', '"')
    .replaceAll('&apos;', "'")
    .replaceAll('&amp;', '&');

const _formatError = AiProviderException(
  'tool_format',
  'AI 服务返回的工具格式无法识别，请检查接口兼容性',
);
