// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import '../workbench/notices_content_cache.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalCacheManager {
  static const _cachePrefixes = <String>[
    'ecjtu.physics.',
    'ecjtu.smart_work.personal.',
    'ecjtu.electricity.',
    'ecjtu.workbench.notices.',
    'ecjtu.workbench.mobileMessages.',
    'ecjtu.workbench.schoolCalendar',
    'ecjtu.mobileApplications.',
    'ecjtu.academic.snapshot.',
    'ecjtu.academic.registrations.',
    'ecjtu.cache.academic_archive.',
  ];

  Future<int> clearCache() async {
    await NoticesContentCache.instance.clear();
    final preferences = await SharedPreferences.getInstance();
    final keys = preferences.getKeys().where(_isCacheKey).toList();
    for (final key in keys) {
      await preferences.remove(key);
    }
    return keys.length;
  }

  bool _isCacheKey(String key) =>
      _cachePrefixes.any((prefix) => key.startsWith(prefix));
}
