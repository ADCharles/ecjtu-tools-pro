// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import '../../data/app_models.dart';

class MobileApplicationOrdering {
  const MobileApplicationOrdering._();

  static const categoryOrder = <String>[
    'study',
    'office',
    'research',
    'life',
    'social',
    'business',
    'other',
  ];

  static const categoryLabels = <String, String>{
    'study': '教学',
    'office': '办公',
    'research': '科研',
    'life': '生活',
    'social': '校园服务',
    'business': '业务系统',
    'other': '其他应用',
  };

  static List<MobileApplication> sort(Iterable<MobileApplication> values) {
    final result = values.toList(growable: true);
    result.sort(compare);
    return result;
  }

  static int compare(MobileApplication left, MobileApplication right) {
    final rank = _specialRank(left.name) - _specialRank(right.name);
    if (rank != 0) return rank;
    final sort = right.sort.compareTo(left.sort);
    if (sort != 0) return sort;
    final name = left.name.compareTo(right.name);
    return name != 0 ? name : left.id.compareTo(right.id);
  }

  static Map<String, List<MobileApplication>> groups(
    Iterable<MobileApplication> values,
  ) {
    final grouped = <String, List<MobileApplication>>{};
    for (final application in values) {
      final category = categoryLabels.containsKey(application.category)
          ? application.category
          : 'other';
      grouped
          .putIfAbsent(category, () => <MobileApplication>[])
          .add(application);
    }
    final result = <String, List<MobileApplication>>{};
    for (final category in categoryOrder) {
      final items = grouped[category];
      if (items == null || items.isEmpty) continue;
      result[category] = sort(items);
    }
    return result;
  }

  static int _specialRank(String name) {
    if (name == '选课系统1') return 0;
    if (name == '选课系统2') return 1;
    return 2;
  }
}
