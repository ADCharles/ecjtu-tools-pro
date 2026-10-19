// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:async';

import '../arrangement/score_models.dart';
import 'chat_execution_mode.dart';

class AiAccountSnapshot {
  const AiAccountSnapshot({
    required this.accountId,
    required this.displayName,
    required this.scores,
    this.updatedAt,
    this.demoMode = false,
    this.scoresReady = true,
    this.authSystem,
    this.className = '',
  });

  final String accountId;
  final String displayName;
  final ScoreSnapshot scores;
  final DateTime? updatedAt;
  final bool demoMode;
  final bool scoresReady;
  final String? authSystem;
  final String className;

  bool get matchesAccount =>
      scoresReady &&
      (scores.studentId.isEmpty || scores.studentId == accountId);
}

enum AiActionKind { openFeature, button }

enum AiArgumentType { string, integer, number, boolean }

class AiActionArgument {
  AiActionArgument({
    required this.name,
    required this.title,
    this.description = '',
    this.type = AiArgumentType.string,
    this.required = false,
    List<Object>? choices,
    this.minimum,
    this.maximum,
    this.maxLength = 1024,
  }) : choices = choices == null ? null : List.unmodifiable(choices) {
    if (!RegExp(r'^[a-zA-Z][a-zA-Z0-9_]*$').hasMatch(name) ||
        maxLength < 1 ||
        (minimum != null && maximum != null && minimum! > maximum!)) {
      throw ArgumentError('Invalid action argument definition');
    }
    if (this.choices case final values?) {
      if (values.isEmpty || values.any((value) => !_matchesType(value))) {
        throw ArgumentError('Invalid action argument choices');
      }
    }
  }

  final String name;
  final String title;
  final String description;
  final AiArgumentType type;
  final bool required;
  final List<Object>? choices;
  final num? minimum;
  final num? maximum;
  final int maxLength;

  Map<String, Object?> toSchema() => {
    'type': type.name,
    'title': title,
    'description': description,
    if (choices != null) 'enum': choices,
    if (minimum != null) 'minimum': minimum,
    if (maximum != null) 'maximum': maximum,
    if (type == AiArgumentType.string) 'maxLength': maxLength,
  };

  bool _matchesType(Object? value) => switch (type) {
    AiArgumentType.string => value is String,
    AiArgumentType.integer => value is int,
    AiArgumentType.number => value is num && value.isFinite,
    AiArgumentType.boolean => value is bool,
  };

  String? validate(Object? value) {
    if (!_matchesType(value)) return '$title 的类型不正确';
    if (choices != null && !choices!.contains(value)) return '$title 的选项无效';
    if (value is String && value.length > maxLength) return '$title 过长';
    if (value is num &&
        ((minimum != null && value < minimum!) ||
            (maximum != null && value > maximum!))) {
      return '$title 超出范围';
    }
    return null;
  }

  Object? parseText(String value) => switch (type) {
    AiArgumentType.string => value,
    AiArgumentType.integer => int.tryParse(value),
    AiArgumentType.number => num.tryParse(value),
    AiArgumentType.boolean => switch (value) {
      'true' => true,
      'false' => false,
      _ => null,
    },
  };
}

class AiSemanticAction {
  AiSemanticAction({
    required this.id,
    required this.title,
    required this.description,
    required this.kind,
    required this.invoke,
    this.readResult,
    String? featureId,
    this.isAvailable,
    this.requiresAgent = false,
    List<AiActionArgument> arguments = const [],
  }) : arguments = List.unmodifiable(arguments),
       featureId = featureId ?? id.split('.').first {
    if (!RegExp(r'^[a-z][a-z0-9_.-]{0,95}$').hasMatch(id) ||
        arguments.map((arg) => arg.name).toSet().length != arguments.length ||
        !RegExp(r'^[a-z][a-z0-9_.-]{0,95}$').hasMatch(this.featureId)) {
      throw ArgumentError('Invalid semantic action definition');
    }
  }

  final String id;
  final String title;
  final String description;
  final AiActionKind kind;
  final String featureId;
  final FutureOr<void> Function(Map<String, Object?> arguments) invoke;
  final Map<String, Object?> Function(Map<String, Object?> arguments)?
  readResult;
  final bool Function()? isAvailable;
  final bool requiresAgent;
  final List<AiActionArgument> arguments;

  bool get available {
    try {
      if (requiresAgent && AiAgentScope.current?.mode != AiChatMode.agent)
        return false;
      return isAvailable?.call() ?? true;
    } catch (_) {
      return false;
    }
  }

  Map<String, Object?> get inputSchema => {
    'type': 'object',
    'properties': {for (final arg in arguments) arg.name: arg.toSchema()},
    'required': [
      for (final arg in arguments)
        if (arg.required) arg.name,
    ],
    'additionalProperties': false,
  };

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'kind': kind.name,
    'featureId': featureId,
    'category': id.split('.').first,
    'available': available,
    'inputSchema': inputSchema,
  };

  String? validateArguments(Map<String, Object?> values) {
    if (values.keys.any((name) => !arguments.any((arg) => arg.name == name))) {
      return '包含未定义的参数';
    }
    for (final arg in arguments) {
      if (!values.containsKey(arg.name)) {
        if (arg.required) return '请填写${arg.title}';
        continue;
      }
      final error = arg.validate(values[arg.name]);
      if (error != null) return error;
    }
    return null;
  }
}

class AiToolException implements Exception {
  const AiToolException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => message;
}
