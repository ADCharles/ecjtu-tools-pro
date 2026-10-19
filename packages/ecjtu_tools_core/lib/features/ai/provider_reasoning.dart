// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:math';

import 'provider_models.dart';

Map<String, Object?> aiReasoningParameters(
  AiProviderConfig config, {
  int? maxOutputTokens,
}) {
  final model = config.model.toLowerCase();
  final enabled = config.reasoningEffort != AiReasoningEffort.off;
  final deepseek = model.contains('deepseek');
  final effort = deepseek
      ? switch (config.reasoningEffort) {
          AiReasoningEffort.off => 'none',
          AiReasoningEffort.low => 'low',
          AiReasoningEffort.max => 'max',
          _ => 'high',
        }
      : config.reasoningEffort == AiReasoningEffort.off
      ? 'none'
      : config.reasoningEffort.name;
  switch (config.protocol) {
    case AiProviderProtocol.chatCompletions:
      if (deepseek) {
        return {
          'thinking': {'type': enabled ? 'enabled' : 'disabled'},
          if (enabled) 'reasoning_effort': effort,
        };
      }
      return {if (enabled || _supportsOff(model)) 'reasoning_effort': effort};
    case AiProviderProtocol.responses:
      return {
        if (enabled || deepseek || _supportsOff(model))
          'reasoning': {'effort': effort, if (!deepseek) 'summary': 'auto'},
      };
    case AiProviderProtocol.anthropicMessages:
      if (deepseek) {
        return {
          'thinking': {'type': enabled ? 'enabled' : 'disabled'},
          if (enabled) 'output_config': {'effort': effort},
        };
      }
      if (!enabled)
        return {
          'thinking': {'type': 'disabled'},
        };
      if (_supportsAdaptive(model)) {
        return {
          'thinking': {'type': 'adaptive'},
          'output_config': {
            'effort': switch (config.reasoningEffort) {
              AiReasoningEffort.xhigh => 'high',
              AiReasoningEffort.max => model.contains('opus') ? 'max' : 'high',
              _ => config.reasoningEffort.name,
            },
          },
        };
      }
      final requestedBudget = switch (config.reasoningEffort) {
        AiReasoningEffort.low => 1024,
        AiReasoningEffort.medium => 4096,
        AiReasoningEffort.high => 8192,
        AiReasoningEffort.xhigh => 16384,
        AiReasoningEffort.max => 32768,
        AiReasoningEffort.off => 0,
      };
      final outputLimit = maxOutputTokens ?? requestedBudget + 4096;
      if (outputLimit < 2048) {
        throw const AiProviderException(
          'configuration',
          '当前输出上限不足以完成思考和回答，请提高输出上限或关闭思考',
        );
      }
      return {
        'max_tokens': outputLimit,
        'thinking': {
          'type': 'enabled',
          'budget_tokens': min(requestedBudget, outputLimit - 1024),
        },
      };
  }
}

bool _supportsOff(String model) =>
    RegExp(r'(^|/)gpt-(5\.[1-9]|6)').hasMatch(model);

bool _supportsAdaptive(String model) =>
    RegExp(r'claude-(opus|sonnet)-4[.-][6-9]').hasMatch(model);
