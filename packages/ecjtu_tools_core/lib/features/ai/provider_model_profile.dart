// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'attachment_models.dart';
import 'provider_models.dart';

class AiModelProfile {
  const AiModelProfile({
    this.contextTokenLimit = 16384,
    this.reasoningEffort = AiReasoningEffort.off,
    this.supportedReasoningEfforts = AiReasoningEffort.values,
    this.modelCapabilities = const AiModelCapabilities(),
  });

  final int contextTokenLimit;
  final AiReasoningEffort reasoningEffort;
  final List<AiReasoningEffort> supportedReasoningEfforts;
  final AiModelCapabilities modelCapabilities;
  bool get visionEnabled => modelCapabilities.visionEnabled;
  bool get pdfEnabled => modelCapabilities.pdfEnabled;

  AiModelProfile copyWith({
    int? contextTokenLimit,
    AiReasoningEffort? reasoningEffort,
    List<AiReasoningEffort>? supportedReasoningEfforts,
    AiModelCapabilities? modelCapabilities,
  }) => AiModelProfile(
    contextTokenLimit: contextTokenLimit ?? this.contextTokenLimit,
    reasoningEffort: reasoningEffort ?? this.reasoningEffort,
    supportedReasoningEfforts:
        supportedReasoningEfforts ?? this.supportedReasoningEfforts,
    modelCapabilities: modelCapabilities ?? this.modelCapabilities,
  );

  factory AiModelProfile.fromConfiguration(AiProviderConfig config) =>
      AiModelProfile(
        contextTokenLimit: config.contextTokenLimit,
        reasoningEffort: config.reasoningEffort,
        supportedReasoningEfforts: config.supportedReasoningEfforts,
        modelCapabilities: config.modelCapabilities,
      );

  AiProviderConfig applyTo(AiProviderConfig config) => config.copyWith(
    contextTokenLimit: contextTokenLimit,
    reasoningEffort: reasoningEffort,
    supportedReasoningEfforts: supportedReasoningEfforts,
    modelCapabilities: modelCapabilities,
  );

  void validate() {
    if (contextTokenLimit < AiProviderConfig.minContextTokenLimit ||
        contextTokenLimit > AiProviderConfig.maxContextTokenLimit) {
      throw const AiProviderException(
        'configuration',
        '上下文上限请设为 ${AiProviderConfig.minContextTokenLimit} 至 ${AiProviderConfig.maxContextTokenLimit}',
      );
    }
  }

  Map<String, Object?> toJson() => {
    'contextTokenLimit': contextTokenLimit,
    'reasoningEffort': reasoningEffort.name,
    'supportedReasoningEfforts': [
      for (final effort in supportedReasoningEfforts) effort.name,
    ],
    ...modelCapabilities.toJson(),
  };

  factory AiModelProfile.fromJson(
    Map value, {
    AiModelProfile fallback = const AiModelProfile(),
  }) {
    final context = value['contextTokenLimit'];
    final effort = value['reasoningEffort'];
    final levels = aiReasoningLevelsFromJson(
      value['supportedReasoningEfforts'],
      fallback: fallback.supportedReasoningEfforts,
    );
    final selected = AiReasoningEffort.values.firstWhere(
      (item) => item.name == (effort == 'xigh' ? 'xhigh' : effort),
      orElse: () => fallback.reasoningEffort,
    );
    return AiModelProfile(
      contextTokenLimit: context is int
          ? context.clamp(
              AiProviderConfig.minContextTokenLimit,
              AiProviderConfig.maxContextTokenLimit,
            )
          : fallback.contextTokenLimit,
      reasoningEffort: levels.contains(selected) ? selected : levels.first,
      supportedReasoningEfforts: levels,
      modelCapabilities: AiModelCapabilities.fromJson({
        ...fallback.modelCapabilities.toJson(),
        ...value,
      }),
    );
  }

  @override
  String toString() =>
      'AiModelProfile(context: $contextTokenLimit, reasoning: ${reasoningEffort.name})';
}
