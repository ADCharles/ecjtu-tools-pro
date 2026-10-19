// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:convert';

import '../arrangement/score_models.dart';
import 'ai_models.dart';

class AiScoreEntry {
  const AiScoreEntry(this.id, this.record);
  final String id;
  final ScoreRecord record;
  double? get numericScore => AiScoreAnalysis.numericScore(record);

  Map<String, Object?> toJson() => {
    'id': id,
    'term': record.term,
    'courseCode': record.courseCode,
    'courseName': record.courseName,
    'course': record.courseName,
    'credit': record.credit.isFinite ? record.credit : null,
    'finalScore': record.finalScore,
    'score': record.finalScore,
    'numericScore': numericScore,
    'includedInGpa': record.isIncluded,
  };
}

class AiScoreAnalysis {
  static const definitions = {
    'gpa':
        '按应用成绩规则计算：有效且已纳入绩点的课程，以学分加权，等于 weightedPoints / credits；学分合计为 0 时返回 0',
    'credits': '纳入本次 GPA 计算的学分合计',
    'weightedPoints': '各课程学分乘绩点的总和',
    'count': '纳入本次 GPA 计算的课程记录数',
    'pageGpa': '学校成绩页给出的整体 GPA，不随本地筛选或排除改变',
    'score': '课程的原始最终成绩；numericScore 为应用成绩规则解析的数值，等级成绩采用应用已有换算，无法解析时为 null',
    'ranking':
        '排除后按 numericScore 排名，同分保持快照顺序；无法解析的成绩不参与排名，GPA 摘要仍计算全部保留课程而非仅 TopN',
    'gradeConversion':
        '等级成绩按应用规则换算：优秀95、良好85；绩点对应的加权等效平均分 = GPA × 10 + 50，例如4.05对应90.5分。',
    'gpaEvaluation': '本校4.0以上绩点属于前列水平；仅据绩点不能推断确切名次或百分位。',
  };

  static double? numericScore(ScoreRecord record) {
    final value = ScoreCalculations.scoreToNumber(record.finalScore);
    return value != null && value.isFinite ? value : null;
  }

  static Map<String, Object?> summary(Iterable<ScoreRecord> records) {
    final result = ScoreCalculations.summary(
      records.where((record) => numericScore(record) != null),
    );
    return {
      'gpa': result.gpa,
      'credits': result.credits,
      'weightedPoints': result.points,
      'count': result.count,
      'source': 'local',
    };
  }

  static List<AiScoreEntry> select(
    ScoreSnapshot snapshot,
    Map<String, Object?> args,
  ) {
    final term = args['term'] as String?;
    final year = args['year'] as int?;
    final query = (args['course'] as String? ?? '').trim().toLowerCase();
    String identity(ScoreRecord record) => base64Url
        .encode(
          utf8.encode(
            jsonEncode([
              record.term,
              record.courseCode,
              record.courseName,
              record.courseType,
              record.examType,
              record.credit.isFinite ? record.credit : null,
            ]),
          ),
        )
        .replaceAll('=', '');
    final identities = snapshot.records.map(identity).toList();
    final counts = <String, int>{};
    for (final id in identities) {
      counts[id] = (counts[id] ?? 0) + 1;
    }
    final seen = <String, int>{};
    final result = <AiScoreEntry>[];
    for (var index = 0; index < snapshot.records.length; index++) {
      final record = snapshot.records[index];
      final base = identities[index];
      seen[base] = (seen[base] ?? 0) + 1;
      // Duplicate identities use snapshot order; filtering/paging never renumbers.
      final id = 'score:$base${counts[base]! > 1 ? ':${seen[base]}' : ''}';
      if (term != null &&
          term.isNotEmpty &&
          term != 'all' &&
          record.term != term) {
        continue;
      }
      if (year != null &&
          !RegExp(
            r'(?<!\d)\d{4}(?!\d)',
          ).allMatches(record.term).any((match) => match.group(0) == '$year')) {
        continue;
      }
      if (query.isNotEmpty &&
          !record.courseName.toLowerCase().contains(query) &&
          !record.courseCode.toLowerCase().contains(query)) {
        continue;
      }
      result.add(AiScoreEntry(id, record));
    }
    return result;
  }

  static Map<String, Object?> analyze(
    AiAccountSnapshot account,
    Map<String, Object?> args,
  ) {
    Never invalid() =>
        throw const AiToolException('invalid_arguments', '成绩分析参数不正确');
    const aliases = {
      'exclude_scores': 'excludeScores',
      'sort_order': 'sortOrder',
      'top_n': 'topN',
      'future_credits': 'futureCredits',
      'remaining_semesters': 'remainingSemesters',
      'target_gpa': 'targetGpa',
    };
    final normalized = <String, Object?>{};
    for (final entry in args.entries) {
      final key = aliases[entry.key] ?? entry.key;
      if (normalized.containsKey(key)) invalid();
      normalized[key] = entry.value;
    }
    args = normalized;
    const allowed = {
      'term',
      'year',
      'exclude',
      'excludeScores',
      'sortOrder',
      'topN',
      'futureCredits',
      'remainingSemesters',
      'targetGpa',
    };
    if (args.keys.any((key) => !allowed.contains(key))) invalid();
    if (args.containsKey('term') &&
        (args['term'] is! String || (args['term'] as String).length > 128)) {
      invalid();
    }
    if (args.containsKey('year') &&
        (args['year'] is! int ||
            (args['year'] as int) < 1900 ||
            (args['year'] as int) > 9999)) {
      invalid();
    }
    final sortOrder = args.containsKey('sortOrder')
        ? args['sortOrder']
        : 'desc';
    final topN = args.containsKey('topN') ? args['topN'] : 10;
    if (sortOrder is! String ||
        !const ['asc', 'desc'].contains(sortOrder) ||
        topN is! int ||
        topN < 1 ||
        topN > 200) {
      invalid();
    }
    final scoreExclusions = args.containsKey('excludeScores')
        ? args['excludeScores']
        : const <num>[];
    if (scoreExclusions is! List ||
        scoreExclusions.length > 200 ||
        scoreExclusions.any(
          (score) =>
              score is! num || !score.isFinite || score < 0 || score > 100,
        )) {
      invalid();
    }
    final entries = select(account.scores, args);
    final raw = args.containsKey('exclude') ? args['exclude'] : [];
    if (raw is! List || raw.length > 200) invalid();
    final excluded = <String>{};
    final unmatched = <Map<String, Object?>>[];
    for (final value in raw) {
      if (value is! Map<String, Object?> ||
          value.isEmpty ||
          value.keys.any(
            (key) =>
                !const {'id', 'term', 'courseCode', 'courseName'}.contains(key),
          ) ||
          value.values.any(
            (field) => field is! String || field.isEmpty || field.length > 2048,
          )) {
        invalid();
      }
      final selector = value;
      if (selector.containsKey('id')) {
        if (selector.length != 1) invalid();
      } else if (!selector.containsKey('term') ||
          (!selector.containsKey('courseCode') &&
              !selector.containsKey('courseName'))) {
        invalid();
      }
      final matches = entries.where((entry) {
        if (selector.containsKey('id')) return entry.id == selector['id'];
        return entry.record.term == selector['term'] &&
            (!selector.containsKey('courseCode') ||
                entry.record.courseCode == selector['courseCode']) &&
            (!selector.containsKey('courseName') ||
                entry.record.courseName == selector['courseName']);
      }).toList();
      if (matches.length > 1) {
        throw const AiToolException(
          'ambiguous_course_selection',
          '此选择匹配多条成绩，请使用记录 ID 进一步限定',
        );
      }
      if (matches.isEmpty) {
        unmatched.add(selector);
      } else {
        excluded.add(matches.single.id);
      }
    }
    for (final entry in entries) {
      if (entry.numericScore != null &&
          scoreExclusions.contains(entry.numericScore)) {
        excluded.add(entry.id);
      }
    }
    final remaining = entries
        .where((entry) => !excluded.contains(entry.id))
        .toList();
    final baseline = summary(entries.map((entry) => entry.record));
    final after = summary(remaining.map((entry) => entry.record));
    final result = <String, Object?>{
      'accountLabel': account.displayName,
      'updatedAt': account.updatedAt?.toUtc().toIso8601String(),
      'demoMode': account.demoMode,
      'matchedCount': entries.length,
      'retainedCount': remaining.length,
      'excludedCount': excluded.length,
      'baseline': baseline,
      'result': after,
      'pageGpa': account.scores.pageGpa,
      'excludedCourses': [
        for (final entry in entries)
          if (excluded.contains(entry.id)) entry.toJson(),
      ],
      'unmatchedExclusions': unmatched,
      'definitions': definitions,
    };
    if (args.containsKey('sortOrder') || args.containsKey('topN')) {
      final rankable = remaining
          .where((entry) => entry.numericScore != null)
          .toList();
      final sourceOrder = {
        for (var index = 0; index < remaining.length; index++)
          remaining[index].id: index,
      };
      rankable.sort((left, right) {
        final comparison = left.numericScore!.compareTo(right.numericScore!);
        return comparison == 0
            ? sourceOrder[left.id]!.compareTo(sourceOrder[right.id]!)
            : sortOrder == 'asc'
            ? comparison
            : -comparison;
      });
      result.addAll({
        'sortOrder': sortOrder,
        'topN': topN,
        'rankableCount': rankable.length,
        'unrankableCount': remaining.length - rankable.length,
        'ranking': [
          for (var index = 0; index < rankable.length && index < topN; index++)
            {'rank': index + 1, ...rankable[index].toJson()},
        ],
      });
    }
    if (args.keys.any(
      (key) => const {
        'futureCredits',
        'remainingSemesters',
        'targetGpa',
      }.contains(key),
    )) {
      final credits = args['futureCredits'];
      final semesters = args['remainingSemesters'];
      final target = args.containsKey('targetGpa') ? args['targetGpa'] : 2.5;
      if (target is! num || !target.isFinite || target < 0 || target > 5) {
        invalid();
      }
      if (args.containsKey('targetGpa') &&
          (credits == null || semesters == null)) {
        result['planning'] = {
          'status': 'needs_input',
          'targetGpa': target,
          'missing': [
            if (credits == null) 'futureCredits',
            if (semesters == null) 'remainingSemesters',
          ],
          'message': '还需要未来学分和剩余学期数，才能计算达到目标绩点所需的成绩。',
        };
        return result;
      }
      if (credits is! num ||
          !credits.isFinite ||
          credits < 0 ||
          credits > 1000 ||
          semesters is! int ||
          semesters < 0 ||
          semesters > 20) {
        invalid();
      }
      final plan = ScoreCalculations.calculateRecoveryPace(
        history: ScoreCalculations.summary(
          remaining
              .where((entry) => entry.numericScore != null)
              .map((entry) => entry.record),
        ),
        futureCredits: credits.toDouble(),
        remainingSemesters: semesters,
        targetGpa: target.toDouble(),
      );
      result['planning'] = {
        'status': plan.status.name,
        'targetGpa': plan.targetGpa,
        'currentGpa': plan.currentGpa,
        'futureCredits': plan.futureCredits,
        'remainingSemesters': plan.remainingSemesters,
        'requiredAverageGpa': plan.requiredAverageGpa,
        'recommendedGpa': plan.recommendedGpa,
        'maxFinalGpa': plan.maxFinalGpa,
      };
    }
    return result;
  }
}
