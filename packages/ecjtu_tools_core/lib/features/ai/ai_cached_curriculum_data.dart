// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import '../arrangement/curriculum_models.dart';

class AiCachedCurriculumData {
  static Map<String, Object?> read({
    required CurriculumSnapshot snapshot,
    required Map<String, Object?> args,
    DateTime? updatedAt,
  }) {
    final query = (args['query'] as String? ?? '').trim().toLowerCase();
    final platform = args['platform'] as String?;
    final module = args['module'] as String?;
    final semester = args['semesterIndex'] as int?;
    final status = args['status'] as String?;
    final offset = args['offset'] as int? ?? 0;
    final limit = args['limit'] as int? ?? 20;
    final filtered = snapshot.records
        .where(
          (r) =>
              (query.isEmpty ||
                  '${r.courseName} ${r.courseCode} ${r.englishName} ${r.platform} ${r.module}'
                      .toLowerCase()
                      .contains(query)) &&
              (platform == null || platform == r.platformLabel) &&
              (module == null || module == r.module) &&
              (semester == null || r.semesterIndexes.contains(semester)) &&
              (status == null ||
                  (status == '未通过' ? !r.isPassed : r.status == status)),
        )
        .toList();
    return {
      'title': '培养方案',
      'available': updatedAt != null || snapshot.records.isNotEmpty,
      'updatedAt': updatedAt?.toIso8601String(),
      'cachedCount': snapshot.records.length,
      'total': filtered.length,
      'offset': offset,
      'limit': limit,
      'nextOffset': offset + limit < filtered.length ? offset + limit : null,
      'summary': _summary(filtered),
      'allSummary': _summary(snapshot.records),
      'filters': {
        'platforms': snapshot.platforms,
        'modules': snapshot.records
            .map((r) => r.module)
            .where((m) => m.isNotEmpty)
            .toSet()
            .toList(),
        'statuses': snapshot.records
            .map((r) => r.status)
            .where((s) => s.isNotEmpty)
            .toSet()
            .toList(),
        'semesters': [
          for (final s in snapshot.semesters)
            {'value': s, 'label': CurriculumRecord.labelForSemester(s)},
        ],
      },
      'records': [
        for (final r in filtered.skip(offset).take(limit))
          {
            'course': r.courseName,
            'courseCode': r.courseCode,
            'credit': r.credit,
            'semesterIndexes': r.semesterIndexes,
            'status': r.status,
            'fields': [
              {'label': '课程平台', 'value': r.platformLabel},
              {'label': '课程模块', 'value': r.module},
              {'label': '课程编号', 'value': r.courseCode},
              {'label': '课程名称', 'value': r.courseName},
              {'label': '英文名称', 'value': r.englishName},
              {'label': '课程类型', 'value': r.courseType},
              {'label': '状态', 'value': r.status},
              {'label': '考核类型', 'value': r.examType},
              {'label': '学分', 'value': r.credit},
              {'label': '总学时', 'value': r.totalHours},
              {'label': '课内学时', 'value': r.inClassHours},
              {'label': '实验学时', 'value': r.experimentHours},
              {'label': '上机学时', 'value': r.computerHours},
              {'label': '其他学时', 'value': r.otherHours},
              {'label': '修读学期', 'value': r.semesterLabel},
            ],
          },
      ],
      'discoverActions': {
        'tool': 'ecjtu_list_actions',
        'arguments': {'category': 'curriculum'},
      },
    };
  }

  static Map<String, Object?> _summary(List<CurriculumRecord> records) => {
    'courseCount': records.length,
    'courseCredits': records.fold<double>(
      0,
      (total, r) => total + (r.credit.isFinite ? r.credit : 0),
    ),
    'passedCount': records.where((r) => r.isPassed).length,
    'notPassedCount': records.where((r) => !r.isPassed).length,
    'statusCounts': {
      for (final status in records.map((r) => r.status).toSet())
        status: records.where((r) => r.status == status).length,
    },
    'creditMeaning': '所列培养方案课程的学分合计，非毕业要求学分；汇总覆盖全部匹配课程，不仅当前分页。',
  };
}
