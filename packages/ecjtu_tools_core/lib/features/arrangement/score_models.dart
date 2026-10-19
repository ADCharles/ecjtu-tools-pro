// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

class CreditRequirement {
  const CreditRequirement({
    required this.name,
    required this.required,
    required this.completed,
    required this.missing,
  });
  final String name, required, completed, missing;
  Map<String, String> toJson() => {
    'name': name,
    'required': required,
    'completed': completed,
    'missing': missing,
  };
  factory CreditRequirement.fromJson(Map value) => CreditRequirement(
    name: '${value['name'] ?? ''}',
    required: '${value['required'] ?? ''}',
    completed: '${value['completed'] ?? ''}',
    missing: '${value['missing'] ?? ''}',
  );
}

class ScoreValue {
  const ScoreValue({required this.type, required this.raw});

  final String type;
  final String raw;
}

class ScoreRecord {
  const ScoreRecord({
    required this.term,
    required this.courseName,
    required this.credit,
    this.courseCode = '',
    this.courseType = '',
    this.examType = '',
    this.examScore = '',
    this.retestScore = '',
    this.retakeScore = '',
    this.finalScore = '',
    this.finalScoreType = '',
    this.autoIncluded = true,
    this.includeOverride,
  });

  final String term;
  final String courseCode;
  final String courseName;
  final String courseType;
  final String examType;
  final double credit;
  final String examScore;
  final String retestScore;
  final String retakeScore;
  final String finalScore;
  final String finalScoreType;
  final bool autoIncluded;
  final bool? includeOverride;

  bool get isIncluded => includeOverride ?? autoIncluded;

  bool get hasFinalScore => ScoreCalculations.scoreToNumber(finalScore) != null;

  ScoreRecord copyWith({bool? includeOverride}) {
    return ScoreRecord(
      term: term,
      courseCode: courseCode,
      courseName: courseName,
      courseType: courseType,
      examType: examType,
      credit: credit,
      examScore: examScore,
      retestScore: retestScore,
      retakeScore: retakeScore,
      finalScore: finalScore,
      finalScoreType: finalScoreType,
      autoIncluded: autoIncluded,
      includeOverride: includeOverride ?? this.includeOverride,
    );
  }
}

class ScoreDetailRecord {
  const ScoreDetailRecord({
    required this.term,
    required this.courseName,
    this.courseCode = '',
    this.selectionType = '',
    this.courseType = '',
    this.examType = '',
    this.credit = '',
    this.usualScore = '',
    this.usualWeight = '',
    this.finalExamScore = '',
    this.finalScore = '',
    this.remark = '',
  });

  final String term;
  final String courseCode;
  final String courseName;
  final String selectionType;
  final String courseType;
  final String examType;
  final String credit;
  final String usualScore;
  final String usualWeight;
  final String finalExamScore;
  final String finalScore;
  final String remark;
}

class ScoreSnapshot {
  const ScoreSnapshot({
    this.records = const <ScoreRecord>[],
    this.details = const <String, List<ScoreDetailRecord>>{},
    this.studentId = '',
    this.studentName = '',
    this.enrollmentStatus = '',
    this.className = '',
    this.creditRequirements = const [],
    this.pageGpa = '',
  });

  final List<ScoreRecord> records;
  final Map<String, List<ScoreDetailRecord>> details;
  final String studentId;
  final String studentName;
  final String enrollmentStatus;
  final String className;
  final List<CreditRequirement> creditRequirements;
  final String pageGpa;

  List<String> get terms {
    final values = <String>{
      ...records.map((record) => record.term),
      ...details.keys,
    }.where((term) => term.isNotEmpty).toList();
    values.sort((left, right) => right.compareTo(left));
    return values;
  }

  List<ScoreRecord> recordsFor(String? term) {
    if (term == null || term == 'all' || term.isEmpty) return records;
    return records.where((record) => record.term == term).toList();
  }

  List<ScoreDetailRecord> detailsFor(String? term) {
    if (term == null || term == 'all' || term.isEmpty) {
      return details.values.expand((records) => records).toList();
    }
    return details[term] ?? const <ScoreDetailRecord>[];
  }

  ScoreDetailRecord? detailFor(ScoreRecord record) {
    final records = details[record.term] ?? const <ScoreDetailRecord>[];
    for (final detail in records) {
      if (record.courseCode.isNotEmpty && detail.courseCode.isNotEmpty) {
        if (record.courseCode == detail.courseCode) return detail;
      } else if (ScoreCalculations.courseNamesMatch(
        record.courseName,
        detail.courseName,
      )) {
        return detail;
      }
    }
    return null;
  }
}

class ScoreSummary {
  const ScoreSummary({
    required this.term,
    required this.gpa,
    required this.credits,
    required this.points,
    required this.count,
    this.label,
  });

  final String term;
  final double gpa;
  final double credits;
  final double points;
  final int count;
  final String? label;

  String get displayLabel => label ?? (term == 'all' ? '累计' : term);
}

class PlannedCourse {
  const PlannedCourse({
    required this.key,
    required this.term,
    required this.courseName,
    required this.credit,
    this.gradeMode = PlannedGradeMode.numeric,
    this.maxScore = 100,
    this.maxLevel = '优秀',
    this.plannedScore = '',
    this.manual = false,
  });

  final String key;
  final String term;
  final String courseName;
  final double credit;
  final PlannedGradeMode gradeMode;
  final double maxScore;
  final String maxLevel;
  final String plannedScore;
  final bool manual;

  PlannedCourse copyWith({
    PlannedGradeMode? gradeMode,
    double? maxScore,
    String? maxLevel,
    String? plannedScore,
    bool? manual,
  }) {
    return PlannedCourse(
      key: key,
      term: term,
      courseName: courseName,
      credit: credit,
      gradeMode: gradeMode ?? this.gradeMode,
      maxScore: maxScore ?? this.maxScore,
      maxLevel: maxLevel ?? this.maxLevel,
      plannedScore: plannedScore ?? this.plannedScore,
      manual: manual ?? this.manual,
    );
  }
}

enum PlannedGradeMode { numeric, level }

class GoalPlanResult {
  const GoalPlanResult({
    required this.status,
    required this.targetGpa,
    required this.futureCredits,
    required this.requiredTermGpa,
    required this.predictedGpa,
    required this.maxCumulativeGpa,
    required this.termGpa,
    required this.gapGpa,
    required this.suggestions,
  });

  final GoalPlanStatus status;
  final double targetGpa;
  final double futureCredits;
  final double requiredTermGpa;
  final double predictedGpa;
  final double maxCumulativeGpa;
  final double termGpa;
  final double gapGpa;
  final List<GoalSuggestion> suggestions;
}

enum GoalPlanStatus { missing, met, possible, impossible }

class RecoveryPaceResult {
  const RecoveryPaceResult({
    required this.status,
    required this.targetGpa,
    required this.currentGpa,
    required this.futureCredits,
    required this.remainingSemesters,
    this.requiredAverageGpa = 0,
    this.recommendedGpa = 0,
    this.maxFinalGpa = 0,
  });

  final RecoveryPaceStatus status;
  final double targetGpa;
  final double currentGpa;
  final double futureCredits;
  final int remainingSemesters;
  final double requiredAverageGpa;
  final double recommendedGpa;
  final double maxFinalGpa;
}

enum RecoveryPaceStatus { missing, possible, impossible }

class GoalSuggestion {
  const GoalSuggestion({
    required this.course,
    required this.target,
    required this.targetGp,
    required this.manual,
  });

  final PlannedCourse course;
  final String target;
  final double targetGp;
  final bool manual;
}

class ScoreCalculations {
  const ScoreCalculations._();

  static const gradeMap = <String, double>{
    '优秀': 95,
    '良好': 85,
    '中等': 75,
    '及格': 65,
    '不及格': 55,
    '合格': 85,
    '不合格': 55,
  };

  static const levelOptions = <String>['及格', '中等', '良好', '优秀'];

  static double? scoreToNumber(String? raw) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty) return null;
    final mapped = gradeMap[value];
    if (mapped != null) return mapped;
    final number = double.tryParse(value);
    if (number == null || number < 0 || number > 100) return null;
    return number;
  }

  static double? gradePoint(String? raw) {
    final score = scoreToNumber(raw);
    if (score == null) return null;
    final rounded = score.round();
    return rounded < 60 ? 0 : 1 + (rounded - 60) * 0.1;
  }

  static ScoreValue? bestScore(Iterable<ScoreValue> values) {
    ScoreValue? best;
    var bestNumber = double.negativeInfinity;
    for (final value in values) {
      final number = scoreToNumber(value.raw);
      if (number == null || number < bestNumber) continue;
      best = value;
      bestNumber = number;
    }
    return best;
  }

  static ScoreSummary summary(
    Iterable<ScoreRecord> records, [
    String term = 'all',
  ]) {
    var credits = 0.0;
    var points = 0.0;
    var count = 0;
    for (final record in records) {
      if (term != 'all' && record.term != term) continue;
      if (!record.isIncluded) continue;
      final gp = gradePoint(record.finalScore);
      if (gp == null || record.credit.isNaN || record.credit.isInfinite) {
        continue;
      }
      credits += record.credit;
      points += record.credit * gp;
      count += 1;
    }
    return ScoreSummary(
      term: term,
      gpa: credits == 0 ? 0 : points / credits,
      credits: credits,
      points: points,
      count: count,
    );
  }

  static RecoveryPaceResult calculateRecoveryPace({
    required ScoreSummary history,
    required double futureCredits,
    required int remainingSemesters,
    double targetGpa = 2.5,
  }) {
    final historyCredits = history.credits.clamp(0, 1000).toDouble();
    final historyPoints = history.points.clamp(0, 5000).toDouble();
    final credits = futureCredits.clamp(0, 1000).toDouble();
    final semesters = remainingSemesters.clamp(0, 20);
    final target = targetGpa.clamp(0, 5).toDouble();
    final currentGpa = historyCredits == 0
        ? 0.0
        : historyPoints / historyCredits;
    if (credits == 0 || semesters == 0) {
      return RecoveryPaceResult(
        status: RecoveryPaceStatus.missing,
        targetGpa: target,
        currentGpa: currentGpa,
        futureCredits: credits,
        remainingSemesters: semesters,
      );
    }
    final requiredFuturePoints =
        target * (historyCredits + credits) - historyPoints;
    final requiredAverageGpa = (requiredFuturePoints / credits)
        .clamp(0, double.infinity)
        .toDouble();
    final recommendedGpa = requiredAverageGpa.clamp(0, 5).toDouble();
    final maxFinalGpa =
        (historyPoints + credits * 5) / (historyCredits + credits);
    return RecoveryPaceResult(
      status: requiredAverageGpa <= 5 + 1e-9
          ? RecoveryPaceStatus.possible
          : RecoveryPaceStatus.impossible,
      targetGpa: target,
      currentGpa: currentGpa,
      futureCredits: credits,
      remainingSemesters: semesters,
      requiredAverageGpa: requiredAverageGpa,
      recommendedGpa: recommendedGpa,
      maxFinalGpa: maxFinalGpa,
    );
  }

  static List<ScoreSummary> summaries(Iterable<ScoreRecord> records) {
    final terms = records.map((record) => record.term).toSet().toList()..sort();
    return [for (final term in terms) summary(records, term), summary(records)];
  }

  static bool courseNamesMatch(String left, String right) {
    final normalizedLeft = _normalizeCourseName(left);
    final normalizedRight = _normalizeCourseName(right);
    if (normalizedLeft.isEmpty || normalizedRight.isEmpty) return false;
    return normalizedLeft == normalizedRight ||
        (normalizedLeft.length >= 3 &&
            normalizedRight.length >= 3 &&
            (normalizedLeft.startsWith(normalizedRight) ||
                normalizedRight.startsWith(normalizedLeft)));
  }

  static String _normalizeCourseName(String value) {
    return value.trim().toLowerCase().replaceAll(
      RegExp(r'[\s·•—_()（）\[\]【】]'),
      '',
    );
  }

  static GoalPlanResult calculateGoalPlan({
    required ScoreSummary history,
    required Iterable<PlannedCourse> plannedCourses,
    required double targetGpa,
  }) {
    final target = targetGpa.clamp(0, 5).toDouble();
    final courses = plannedCourses
        .where((course) => course.courseName.isNotEmpty && course.credit > 0)
        .toList();
    final futureCredits = courses.fold<double>(
      0,
      (sum, course) => sum + course.credit,
    );
    if (futureCredits == 0) {
      return GoalPlanResult(
        status: GoalPlanStatus.missing,
        targetGpa: target,
        futureCredits: 0,
        requiredTermGpa: 0,
        predictedGpa: history.gpa,
        maxCumulativeGpa: history.gpa,
        termGpa: 0,
        gapGpa: 0,
        suggestions: const <GoalSuggestion>[],
      );
    }

    final requiredPoints =
        target * (history.credits + futureCredits) - history.points;
    final requiredTermGpa = requiredPoints / futureCredits;
    final manualSuggestions = courses.where((course) => course.manual).map((
      course,
    ) {
      final planned = course.gradeMode == PlannedGradeMode.level
          ? (levelOptions.contains(course.plannedScore)
                ? course.plannedScore
                : course.maxLevel)
          : _numericPlannedScore(course.plannedScore);
      return GoalSuggestion(
        course: course,
        target: planned,
        targetGp: gradePoint(planned) ?? 0,
        manual: true,
      );
    }).toList();
    final manualPoints = manualSuggestions.fold<double>(
      0,
      (sum, item) => sum + item.course.credit * item.targetGp,
    );
    final automaticCourses = courses.where((course) => !course.manual).toList();
    final maxAutomaticPoints = automaticCourses.fold<double>(0, (sum, course) {
      final gp = course.gradeMode == PlannedGradeMode.level
          ? _levelGp(course.maxLevel)
          : gradePoint(course.maxScore.toString()) ?? 0;
      return sum + course.credit * gp;
    });
    final maxFuturePoints = manualPoints + maxAutomaticPoints;
    final maxCumulativeGpa =
        (history.points + maxFuturePoints) / (history.credits + futureCredits);
    final possible = requiredPoints <= maxFuturePoints + 1e-9;
    final automaticCredits = automaticCourses.fold<double>(
      0,
      (sum, course) => sum + course.credit,
    );
    var remainingRequiredPoints = (requiredPoints - manualPoints)
        .clamp(0, double.infinity)
        .toDouble();

    final levelSuggestions = <GoalSuggestion>[];
    for (final course in automaticCourses.where(
      (course) => course.gradeMode == PlannedGradeMode.level,
    )) {
      final cap = _levelGp(course.maxLevel);
      final desired = automaticCredits == 0
          ? 0
          : remainingRequiredPoints / automaticCredits;
      final available = levelOptions
          .where((label) => _levelGp(label) <= cap)
          .toList();
      final chosen = available.firstWhere(
        (label) => _levelGp(label) >= desired,
        orElse: () => available.isEmpty ? '及格' : available.last,
      );
      levelSuggestions.add(
        GoalSuggestion(
          course: course,
          target: chosen,
          targetGp: _levelGp(chosen),
          manual: false,
        ),
      );
    }
    final levelPoints = levelSuggestions.fold<double>(
      0,
      (sum, item) => sum + item.course.credit * item.targetGp,
    );
    remainingRequiredPoints = (remainingRequiredPoints - levelPoints)
        .clamp(0, double.infinity)
        .toDouble();

    final numericCourses = automaticCourses
        .where((course) => course.gradeMode == PlannedGradeMode.numeric)
        .toList();
    final assigned = <GoalSuggestion>[];
    final unresolved = numericCourses
        .map(
          (course) =>
              MapEntry(course, gradePoint(course.maxScore.toString()) ?? 0),
        )
        .toList();
    while (unresolved.isNotEmpty) {
      final credits = unresolved.fold<double>(
        0,
        (sum, item) => sum + item.key.credit,
      );
      final equalGp = credits == 0 ? 0.0 : remainingRequiredPoints / credits;
      final capped = unresolved
          .where((item) => item.value < equalGp - 1e-9)
          .toList();
      if (capped.isEmpty) {
        assigned.addAll(
          unresolved.map((item) => _numericSuggestion(item.key, equalGp)),
        );
        break;
      }
      for (final item in capped) {
        assigned.add(_numericSuggestion(item.key, item.value));
        remainingRequiredPoints =
            (remainingRequiredPoints - item.key.credit * item.value)
                .clamp(0, double.infinity)
                .toDouble();
        unresolved.remove(item);
      }
    }

    final automatic = [...levelSuggestions, ...assigned];
    final suggestions = courses.map((course) {
      final manual = manualSuggestions.cast<GoalSuggestion?>().firstWhere(
        (item) => item?.course.key == course.key,
        orElse: () => null,
      );
      if (manual != null) return manual;
      return automatic.firstWhere(
        (item) => item.course.key == course.key,
        orElse: () => GoalSuggestion(
          course: course,
          target: course.plannedScore,
          targetGp: gradePoint(course.plannedScore) ?? 0,
          manual: false,
        ),
      );
    }).toList();
    final suggestedPoints = suggestions.fold<double>(
      0,
      (sum, item) => sum + item.course.credit * item.targetGp,
    );
    final predictedGpa =
        (history.points + suggestedPoints) / (history.credits + futureCredits);
    final currentGpa = history.credits == 0 ? 0 : history.gpa;
    final status = target <= currentGpa && requiredPoints <= 0
        ? GoalPlanStatus.met
        : possible
        ? GoalPlanStatus.possible
        : GoalPlanStatus.impossible;
    return GoalPlanResult(
      status: status,
      targetGpa: target,
      futureCredits: futureCredits,
      requiredTermGpa: requiredTermGpa,
      predictedGpa: predictedGpa,
      maxCumulativeGpa: maxCumulativeGpa,
      termGpa: futureCredits == 0 ? 0 : suggestedPoints / futureCredits,
      gapGpa: (target - predictedGpa).clamp(0, double.infinity).toDouble(),
      suggestions: suggestions,
    );
  }

  static String _numericPlannedScore(String value) {
    final parsed = double.tryParse(value);
    if (parsed == null) return '';
    return parsed.clamp(30, 100).round().toString();
  }

  static double _levelGp(String label) {
    const values = {'及格': 1.5, '中等': 2.5, '良好': 3.5, '优秀': 4.5};
    return values[label] ?? 4.5;
  }

  static GoalSuggestion _numericSuggestion(PlannedCourse course, double gp) {
    final rawScore = gp <= 0 ? 30 : 60 + (gp < 1 ? 1 : gp - 1) * 10;
    final target = rawScore.ceil().clamp(30, course.maxScore.round());
    return GoalSuggestion(
      course: course,
      target: target.toString(),
      targetGp: gradePoint(target.toString()) ?? 0,
      manual: false,
    );
  }
}
