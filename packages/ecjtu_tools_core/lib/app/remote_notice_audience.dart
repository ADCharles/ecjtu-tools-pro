// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

class RemoteNoticeContext {
  const RemoteNoticeContext({
    required this.version,
    required this.build,
    required this.platform,
    required this.channel,
    this.features = const {},
    this.enabledFeatures = const {},
    this.locale = '',
    this.testRevision = 0,
  });
  final String version, platform, channel, locale;
  final int build, testRevision;
  final Set<String> features, enabledFeatures;
}

class RemoteNoticeAudience {
  static const _lists = {
    'versions',
    'excludeVersions',
    'platforms',
    'excludePlatforms',
    'channels',
    'excludeChannels',
    'featuresAll',
    'featuresAny',
    'featuresNone',
    'enabledFeaturesAll',
    'enabledFeaturesAny',
    'enabledFeaturesNone',
    'locales',
  };
  static const _integers = {
    'minBuild',
    'maxBuild',
    'minTestRevision',
    'maxTestRevision',
  };
  static const _versions = {'minVersion', 'maxVersion'};
  static const _numbers = {'builds', 'excludeBuilds'};

  static List<int> _version(String value) {
    final match = RegExp(r'^(\d+)\.(\d+)\.(\d+)$').firstMatch(value);
    if (match == null) throw const FormatException('Notice version');
    return [for (var i = 1; i <= 3; i++) int.parse(match[i]!)];
  }

  static int compareVersions(String left, String right) {
    final a = _version(left), b = _version(right);
    for (var i = 0; i < 3; i++) {
      final result = a[i].compareTo(b[i]);
      if (result != 0) return result;
    }
    return 0;
  }

  static void validate(Object? rule) {
    var count = 0;
    void visit(Object? node, int depth) {
      if (++count > 64 || depth > 6 || node is! Map || node.isEmpty) {
        throw const FormatException('Notice audience structure');
      }
      for (final entry in node.entries) {
        final key = entry.key, value = entry.value;
        if (key == 'all' || key == 'any') {
          if (value is! List || value.isEmpty || value.length > 20) {
            throw const FormatException('Notice audience group');
          }
          for (final child in value) {
            visit(child, depth + 1);
          }
        } else if (key == 'not') {
          visit(value, depth + 1);
        } else if (_lists.contains(key) || _numbers.contains(key)) {
          if (value is! List ||
              value.isEmpty ||
              value.length > 100 ||
              value.any(
                (v) => _numbers.contains(key)
                    ? v is! int || v < 0
                    : v is! String || v.trim().isEmpty,
              )) {
            throw const FormatException('Notice audience list');
          }
          if (key == 'versions' || key == 'excludeVersions') {
            for (final v in value) {
              _version(v as String);
            }
          }
        } else if (_integers.contains(key)) {
          if (value is! int || value < 0) {
            throw const FormatException('Notice audience number');
          }
        } else if (_versions.contains(key)) {
          if (value is! String) {
            throw const FormatException('Notice audience version');
          }
          _version(value);
        } else {
          // New operators must not broaden an older client's audience, even in NOT.
          throw const FormatException('Unknown notice audience field');
        }
      }
      for (final pair in const [
        ('minBuild', 'maxBuild'),
        ('minTestRevision', 'maxTestRevision'),
      ]) {
        if (node[pair.$1] != null &&
            node[pair.$2] != null &&
            (node[pair.$1] as int) > (node[pair.$2] as int)) {
          throw const FormatException('Notice audience range');
        }
      }
      if (node['minVersion'] != null &&
          node['maxVersion'] != null &&
          compareVersions(
                node['minVersion'] as String,
                node['maxVersion'] as String,
              ) >
              0) {
        throw const FormatException('Notice audience version range');
      }
    }

    visit(rule, 0);
  }

  static bool matches(Object? rule, RemoteNoticeContext context) {
    try {
      validate(rule);
      bool evaluate(Map node) {
        for (final entry in node.entries) {
          final value = entry.value;
          final ok = switch (entry.key) {
            'all' => (value as List).every((r) => evaluate(r as Map)),
            'any' => (value as List).any((r) => evaluate(r as Map)),
            'not' => !evaluate(value as Map),
            'versions' => (value as List).contains(context.version),
            'excludeVersions' => !(value as List).contains(context.version),
            'minVersion' =>
              compareVersions(context.version, value as String) >= 0,
            'maxVersion' =>
              compareVersions(context.version, value as String) <= 0,
            'minBuild' => context.build >= (value as int),
            'maxBuild' => context.build <= (value as int),
            'builds' => (value as List).contains(context.build),
            'excludeBuilds' => !(value as List).contains(context.build),
            'platforms' => (value as List).contains(context.platform),
            'excludePlatforms' => !(value as List).contains(context.platform),
            'channels' => (value as List).contains(context.channel),
            'excludeChannels' => !(value as List).contains(context.channel),
            'enabledFeaturesAll' => (value as List).every(
              context.enabledFeatures.contains,
            ),
            'enabledFeaturesAny' => (value as List).any(
              context.enabledFeatures.contains,
            ),
            'enabledFeaturesNone' => !(value as List).any(
              context.enabledFeatures.contains,
            ),
            'featuresAll' => (value as List).every(context.features.contains),
            'featuresAny' => (value as List).any(context.features.contains),
            'featuresNone' => !(value as List).any(context.features.contains),
            'locales' => (value as List).any((v) {
              final locale = context.locale
                  .replaceAll('_', '-')
                  .toLowerCase()
                  .split('.')
                  .first;
              final target = (v as String).replaceAll('_', '-').toLowerCase();
              return locale == target || locale.startsWith('$target-');
            }),
            'minTestRevision' => context.testRevision >= (value as int),
            'maxTestRevision' => context.testRevision <= (value as int),
            _ => false,
          };
          if (!ok) return false;
        }
        return true;
      }

      return evaluate(rule as Map);
    } on FormatException {
      return false;
    }
  }
}

void validateRemoteNoticeConfig(Map<String, dynamic> config) {
  if (config['schema'] != 1 ||
      config['notices'] is! List ||
      (config['notices'] as List).length > 20 ||
      (config.containsKey('targetedNotices') &&
          (config['targetedNotices'] is! List ||
              (config['targetedNotices'] as List).length > 20))) {
    throw const FormatException('Notice schema');
  }
  final ids = <String>{};
  for (final targeted in [false, true]) {
    for (final value
        in (config[targeted ? 'targetedNotices' : 'notices'] as List? ??
            const [])) {
      if (value is! Map<String, dynamic>) {
        throw const FormatException('Notice object');
      }
      const fields = {
        'id',
        'enabled',
        'title',
        'content',
        'frequency',
        'closeAfterSeconds',
        'startsAt',
        'endsAt',
        'channels',
        'platforms',
        'versions',
        'audience',
      };
      if (value.keys.any((key) => !fields.contains(key))) {
        throw const FormatException('Unknown notice field');
      }
      if (value['id'] is! String ||
          !RegExp(r'^[a-zA-Z0-9_.-]{1,80}$').hasMatch(value['id']) ||
          value['title'] is! String ||
          value['content'] is! String ||
          (value['content'] as String).length > 100000 ||
          !['once', 'everyLaunch'].contains(value['frequency']) ||
          !value.containsKey('closeAfterSeconds') ||
          (value.containsKey('enabled') && value['enabled'] is! bool)) {
        throw const FormatException('Notice fields');
      }
      if (!ids.add(value['id'] as String)) {
        throw const FormatException('Duplicate notice id');
      }
      final seconds = value['closeAfterSeconds'];
      if (seconds != null &&
          (seconds is! int || seconds < 0 || seconds > 86400)) {
        throw const FormatException('Notice duration');
      }
      for (final key in ['startsAt', 'endsAt']) {
        if (value[key] != null &&
            (value[key] is! String || DateTime.tryParse(value[key]) == null)) {
          throw const FormatException('Notice date');
        }
      }
      if (value['startsAt'] != null &&
          value['endsAt'] != null &&
          !DateTime.parse(
            value['endsAt'],
          ).isAfter(DateTime.parse(value['startsAt']))) {
        throw const FormatException('Notice date range');
      }
      for (final key in ['channels', 'platforms', 'versions']) {
        if (value[key] != null &&
            (value[key] is! List ||
                (value[key] as List).any((v) => v is! String))) {
          throw const FormatException('Notice target');
        }
      }
      if (targeted) {
        RemoteNoticeAudience.validate(value['audience']);
      } else if (value.containsKey('audience')) {
        throw const FormatException('Audience requires targetedNotices');
      }
    }
  }
}
