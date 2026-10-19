// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecjtu_tools_core/app/remote_notice_audience.dart';

void main() {
  const android = RemoteNoticeContext(
    version: '4.1.0',
    build: 7,
    platform: 'android',
    channel: 'dev',
    locale: 'zh_CN.UTF-8',
    features: {'schedule', 'smallClassQuery', 'ai', 'mobileLayout'},
  );
  const windows = RemoteNoticeContext(
    version: '4.10.0',
    build: 12,
    platform: 'windows',
    channel: 'stable',
    locale: 'en_US',
    features: {'schedule', 'ai', 'detachedBrowser', 'updates'},
  );
  Map<String, dynamic> notice(String id) => {
    'id': id,
    'title': 'Title',
    'content': 'Content',
    'frequency': 'once',
    'closeAfterSeconds': 0,
  };
  test('numeric version and inclusive build bounds', () {
    expect(
      RemoteNoticeAudience.compareVersions('4.10.0', '4.9.0'),
      greaterThan(0),
    );
    expect(
      RemoteNoticeAudience.matches({
        'minVersion': '4.1.0',
        'maxVersion': '4.1.0',
        'minBuild': 7,
        'maxBuild': 7,
      }, android),
      isTrue,
    );
    expect(
      RemoteNoticeAudience.matches({'maxVersion': '4.9.0'}, windows),
      isFalse,
    );
    expect(
      RemoteNoticeAudience.matches({
        'excludeVersions': ['4.1.0'],
      }, android),
      isFalse,
    );
    expect(
      RemoteNoticeAudience.matches({
        'excludeBuilds': [7],
      }, android),
      isFalse,
    );
    expect(
      RemoteNoticeAudience.matches({
        'builds': [7, 8],
      }, android),
      isTrue,
    );
  });
  test('platform channel capability locale and boolean conditions', () {
    final rule = {
      'all': [
        {
          'platforms': ['android', 'ios'],
          'excludePlatforms': ['windows'],
        },
        {
          'channels': ['dev'],
          'excludeChannels': ['stable'],
        },
        {
          'featuresAll': ['schedule', 'ai'],
          'featuresAny': ['smallClassQuery', 'detachedBrowser'],
          'featuresNone': ['updates'],
        },
        {
          'locales': ['zh'],
        },
        {
          'any': [
            {
              'builds': [7],
            },
            {
              'versions': ['4.0.3'],
            },
          ],
        },
        {
          'not': {
            'platforms': ['windows'],
          },
        },
      ],
    };
    expect(RemoteNoticeAudience.matches(rule, android), isTrue);
    expect(RemoteNoticeAudience.matches(rule, windows), isFalse);
    expect(
      RemoteNoticeAudience.matches(
        {
          'platforms': ['ios'],
        },
        const RemoteNoticeContext(
          version: '4.1.0',
          build: 7,
          platform: 'ios',
          channel: 'stable',
        ),
      ),
      isTrue,
    );
    expect(
      RemoteNoticeAudience.matches(
        {'minTestRevision': 2, 'maxTestRevision': 4},
        const RemoteNoticeContext(
          version: '4.1.0',
          build: 7,
          platform: 'windows',
          channel: 'test',
          testRevision: 3,
        ),
      ),
      isTrue,
    );
  });
  test('unknown operators fail closed including inside negation', () {
    for (final rule in [
      {'futureRule': true},
      {
        'not': {'futureRule': true},
      },
      {
        'any': [
          {
            'platforms': ['android'],
          },
          {'futureRule': true},
        ],
      },
      {'minBuild': '7'},
      {'featuresAny': 'ai'},
      {'any': []},
      {},
      {'minVersion': '4.2.0', 'maxVersion': '4.1.0'},
      {'minBuild': 8, 'maxBuild': 7},
    ]) {
      expect(
        RemoteNoticeAudience.matches(rule, android),
        isFalse,
        reason: '$rule',
      );
    }
    Object nested = {
      'platforms': ['android'],
    };
    for (var i = 0; i < 9; i++) {
      nested = {'not': nested};
    }
    expect(RemoteNoticeAudience.matches(nested, android), isFalse);
  });
  test('enabled settings are distinct from supported capabilities', () {
    const enabled = RemoteNoticeContext(
      version: '4.1.0',
      build: 7,
      platform: 'android',
      channel: 'stable',
      features: {'communications'},
      enabledFeatures: {'communications', 'scheduleSmallClass'},
    );
    expect(
      RemoteNoticeAudience.matches({
        'enabledFeaturesAll': ['communications'],
        'enabledFeaturesAny': ['scheduleSmallClass', 'noticePreview'],
        'enabledFeaturesNone': ['offlineMode'],
      }, enabled),
      isTrue,
    );
    expect(
      RemoteNoticeAudience.matches({
        'enabledFeaturesAll': ['ai'],
      }, android),
      isFalse,
    );
    expect(
      RemoteNoticeAudience.matches({
        'featuresAll': ['ai'],
      }, android),
      isTrue,
    );
  });
  test('old schema and legacy list survive targeted list addition', () {
    final config =
        jsonDecode(
              jsonEncode({
                'schema': 1,
                'notices': [notice('old')],
                'targetedNotices': [
                  {
                    ...notice('new'),
                    'audience': {
                      'featuresAll': ['ai'],
                      'minVersion': '4.1.0',
                    },
                  },
                ],
              }),
            )
            as Map<String, dynamic>;
    validateRemoteNoticeConfig(config);
    expect(config['schema'], 1);
    expect((config['notices'] as List).single['id'], 'old');
    expect((config['notices'] as List).any((n) => n['id'] == 'new'), isFalse);
    validateRemoteNoticeConfig({
      'schema': 1,
      'notices': [notice('legacy')],
    });
    validateRemoteNoticeConfig({'schema': 1, 'notices': []});
  });
  test('publisher rejects conditions in legacy list and duplicate ids', () {
    for (final config in [
      {
        'schema': 1,
        'notices': [
          {
            ...notice('bad'),
            'audience': {
              'platforms': ['android'],
            },
          },
        ],
      },
      {
        'schema': 1,
        'notices': [],
        'targetedNotices': [notice('bad')],
      },
      {
        'schema': 1,
        'notices': [notice('same')],
        'targetedNotices': [
          {
            ...notice('same'),
            'audience': {
              'platforms': ['android'],
            },
          },
        ],
      },
      {
        'schema': 1,
        'notices': [],
        'targetedNotices': [
          {
            ...notice('bad'),
            'audience': {'futureRule': true},
          },
        ],
      },
    ]) {
      expect(() => validateRemoteNoticeConfig(config), throwsFormatException);
    }
  });
}
