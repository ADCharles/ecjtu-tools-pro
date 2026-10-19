// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'package:ecjtu_tools_core/widgets/ecjtu_text_context_menu.dart';
import 'dart:math' as math;

import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show mapEquals;

import '../../theme/ecjtu_theme.dart';
import '../../theme/ecjtu_control_palette.dart';
import '../../theme/ecjtu_glass.dart';
import '../../widgets/ecjtu_widgets.dart';
import 'curriculum_models.dart';
import 'arrangement_models.dart';
import 'score_details_page.dart';
import 'score_models.dart';
import 'score_planner_storage.dart';
import '../workbench/smart_work_widgets.dart';

const _scoreFontFamily = 'SourceHanSansCN';

class ScoresPage extends StatefulWidget {
  const ScoresPage({
    super.key,
    required this.snapshot,
    this.showPageTitle = true,
    this.loading = false,
    this.synced = true,
    this.error,
    this.planningError,
    this.onRequestSync,
    this.curriculumSnapshot = const CurriculumSnapshot(),
    this.registrations = const <RegistrationRecord>[],
    this.studentId = '',
    this.selectedTerm = 'all',
    this.onSelectedTermChanged,
    this.onBack,
  });

  final ScoreSnapshot snapshot;
  final bool showPageTitle;
  final bool loading;
  final bool synced;
  final String? error;
  final String? planningError;
  final VoidCallback? onRequestSync;
  final CurriculumSnapshot curriculumSnapshot;
  final List<RegistrationRecord> registrations;
  final String studentId;
  final String selectedTerm;
  final ValueChanged<String>? onSelectedTermChanged;
  final VoidCallback? onBack;

  @override
  State<ScoresPage> createState() => _ScoresPageState();
}

class _ScoresPageState extends State<ScoresPage> {
  final _courseSectionKey = GlobalKey();
  final _targetGpaController = TextEditingController(text: '4.00');
  final _plannedScoreControllers = <String, TextEditingController>{};
  final _includeOverrides = <String, bool>{};
  final _plannedCourses = <String, PlannedCourse>{};
  String _selectedTerm = 'all';
  String _selectedPlannerTerm = '';
  double _targetGpa = 4;
  bool _courseDetailsOpen = true;
  bool _courseSearchOpen = false;
  String _courseQuery = '';
  bool _showScoreDetails = false;
  final _plannerStorage = ScorePlannerStorage();
  String _plannerStudentId = '';
  bool _plannerLoaded = false;
  int _plannerLoadGeneration = 0;
  List<ScoreRecord>? _recordsSource;
  List<ScoreRecord>? _recordsCache;
  Map<String, bool> _recordOverridesCache = {};
  final _summariesCache = <String, ScoreSummary>{};

  ScoreSummary _summaryFor(List<ScoreRecord> records, [String term = 'all']) =>
      _summariesCache.putIfAbsent(
        term,
        () => ScoreCalculations.summary(records, term),
      );

  @override
  void initState() {
    super.initState();
    _selectedTerm = widget.selectedTerm;
    _loadPlanner(widget.studentId);
  }

  @override
  void didUpdateWidget(covariant ScoresPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.studentId != widget.studentId) {
      _loadPlanner(widget.studentId);
    }
    if (oldWidget.selectedTerm != widget.selectedTerm &&
        _selectedTerm != widget.selectedTerm) {
      _selectedTerm = widget.selectedTerm;
    }
  }

  @override
  void dispose() {
    _targetGpaController.dispose();
    for (final controller in _plannedScoreControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadPlanner(String studentId) async {
    final target = studentId.trim();
    _plannerStudentId = target;
    _plannerLoaded = false;
    final generation = ++_plannerLoadGeneration;
    final loaded = _plannerStorage.readLoaded(target);
    final saved = loaded ?? await _plannerStorage.read(target);
    if (!mounted || generation != _plannerLoadGeneration) return;
    _targetGpaController.text = saved.targetGpa.toStringAsFixed(2);
    _targetGpa = saved.targetGpa;
    _selectedPlannerTerm = saved.term;
    for (final controller in _plannedScoreControllers.values) {
      controller.dispose();
    }
    _plannedScoreControllers.clear();
    _plannedCourses
      ..clear()
      ..addAll(saved.courses);
    _plannerLoaded = true;
    setState(() {});
  }

  void _persistPlanner() {
    if (!_plannerLoaded || _plannerStudentId.isEmpty) return;
    final snapshot = ScorePlannerSnapshot(
      targetGpa: _targetGpa,
      term: _selectedPlannerTerm,
      courses: Map<String, PlannedCourse>.from(_plannedCourses),
    );
    _plannerStorage.write(_plannerStudentId, snapshot);
  }

  void _setSelectedTerm(String value) {
    final searching = _courseQuery.trim().isNotEmpty;
    EcjtuPageScrollAnchor(
      searching,
      contentEndKey: searching ? _courseSectionKey : null,
    ).dispatch(context);
    setState(() {
      _selectedTerm = value;
      _courseDetailsOpen = true;
    });
    widget.onSelectedTermChanged?.call(value);
    if (searching) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final courseContext = _courseSectionKey.currentContext;
      if (courseContext == null) return;
      Scrollable.ensureVisible(
        courseContext,
        alignment: 0.04,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _updateCourseQuery(String value) {
    final query = value.trim().toLowerCase();
    EcjtuPageScrollAnchor(
      query.isNotEmpty,
      contentEndKey: _courseSectionKey,
    ).dispatch(context);
    setState(() => _courseQuery = value);
  }

  @override
  Widget build(BuildContext context) {
    if (_showScoreDetails) {
      return ScoreDetailsPage(
        snapshot: widget.snapshot,
        onBack: () {
          const EcjtuPageScrollScope(false).dispatch(context);
          setState(() => _showScoreDetails = false);
        },
      );
    }
    if (widget.snapshot.records.isEmpty &&
        (widget.loading || !widget.synced || widget.error != null)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showPageTitle)
            SizedBox(
              height: EcjtuMetrics.pageHeaderHeightFor(context),
              child: EcjtuSectionTitle(
                '成绩',
                lineHeight: 1.15,
                action: widget.onBack == null
                    ? null
                    : EcjtuBackAction(label: '返回教务', onPressed: widget.onBack!),
              ),
            ),
          if (widget.showPageTitle)
            SizedBox(height: EcjtuMetrics.pageHeaderGapFor(context)),
          if (widget.loading || widget.error == null)
            const SmartWorkLoading(message: '正在读取成绩')
          else ...[
            SmartWorkInlineMessage(message: widget.error!, error: true),
            if (widget.onRequestSync != null)
              EcjtuDialogAction(label: '重新读取', onPressed: widget.onRequestSync),
          ],
        ],
      );
    }
    final records = _effectiveRecords;
    final terms = widget.snapshot.terms;
    final filtered = _filterRecords(records);
    final history = _summaryFor(records);
    final pending = _plannedEntries(
      records,
      widget.curriculumSnapshot,
      widget.registrations,
    );
    final plannerTerms = _plannerTerms(pending);
    if (plannerTerms.isEmpty) {
      _selectedPlannerTerm = '';
    } else if (!plannerTerms.contains(_selectedPlannerTerm)) {
      _selectedPlannerTerm = plannerTerms.first;
    }
    final planned = pending
        .where((course) => course.term == _selectedPlannerTerm)
        .toList();
    final goal = ScoreCalculations.calculateGoalPlan(
      history: history,
      plannedCourses: pending,
      targetGpa: _targetGpa,
    );

    final termSuggestions = goal.suggestions
        .where((item) => item.course.term == _selectedPlannerTerm)
        .toList();
    final termCredits = termSuggestions.fold<double>(
      0,
      (sum, item) => sum + item.course.credit,
    );
    final termPoints = termSuggestions.fold<double>(
      0,
      (sum, item) => sum + item.course.credit * item.targetGp,
    );
    final displayedGoal = GoalPlanResult(
      status: goal.status,
      targetGpa: goal.targetGpa,
      futureCredits: goal.futureCredits,
      requiredTermGpa: goal.requiredTermGpa,
      predictedGpa: goal.predictedGpa,
      maxCumulativeGpa: goal.maxCumulativeGpa,
      termGpa: termCredits == 0 ? 0 : termPoints / termCredits,
      gapGpa: goal.gapGpa,
      suggestions: termSuggestions,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showPageTitle)
          SizedBox(
            height: EcjtuMetrics.pageHeaderHeightFor(context),
            child: EcjtuSectionTitle(
              '成绩',
              lineHeight: 1.15,
              action: widget.onBack == null
                  ? null
                  : EcjtuBackAction(label: '返回教务', onPressed: widget.onBack!),
            ),
          ),
        if (widget.showPageTitle)
          SizedBox(height: EcjtuMetrics.pageHeaderGapFor(context)),
        _buildSummaryGrid(context, records),
        _buildAcademicWarning(
          context,
          history: history,
          pending: pending,
          curriculum: widget.curriculumSnapshot,
        ),
        if (pending.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildPlanner(context, pending, planned, plannerTerms, displayedGoal),
        ],
        if (widget.planningError != null)
          SmartWorkInlineMessage(message: widget.planningError!, error: true),
        KeyedSubtree(
          key: _courseSectionKey,
          child: _buildCourseSection(context, terms, filtered),
        ),
      ],
    );
  }

  Widget _buildAcademicWarning(
    BuildContext context, {
    required ScoreSummary history,
    required List<PlannedCourse> pending,
    required CurriculumSnapshot curriculum,
  }) {
    if (history.credits <= 0 || history.gpa >= 2.5) {
      return const SizedBox.shrink();
    }
    final horizon = _warningHorizon(
      records: _effectiveRecords,
      pending: pending,
      curriculum: curriculum,
    );
    final recovery = ScoreCalculations.calculateRecoveryPace(
      history: history,
      futureCredits: horizon.futureCredits,
      remainingSemesters: horizon.remainingSemesters,
      targetGpa: 2.5,
    );
    final size = MediaQuery.sizeOf(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final critical = history.gpa < 2.2;
    final border = dark
        ? (critical ? const Color(0xFF70403D) : const Color(0xFF665629))
        : (critical ? const Color(0xFFFECDCA) : const Color(0xFFFEDF89));
    final surface = dark
        ? (critical ? const Color(0xFF251718) : const Color(0xFF211D13))
        : (critical ? const Color(0xFFFEF3F2) : const Color(0xFFFFFAEB));
    final accent = dark
        ? (critical ? const Color(0xFFFF9B91) : const Color(0xFFFFBD70))
        : (critical ? const Color(0xFFB42318) : const Color(0xFFB54708));
    final muted = EcjtuColors.mutedFrom(
      context,
      dark ? const Color(0xFF9EACC3) : const Color(0xFF667085),
    );
    final label = recovery.status == RecoveryPaceStatus.impossible
        ? '每学期尽量'
        : '每学期建议';
    final pace = recovery.status == RecoveryPaceStatus.impossible
        ? '最终最高 ${recovery.maxFinalGpa.toStringAsFixed(2)}'
        : '数字课约 ${_scoreForAverageGpa(recovery.recommendedGpa)} 分';
    Widget metric(String title, String value) {
      return Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              softWrap: true,
              style: TextStyle(
                color: muted,
                fontSize: EcjtuMetrics.fontMicroFor(size),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              value,
              style: TextStyle(
                color: accent,
                fontSize: EcjtuMetrics.isCompact(size) ? 20 : 22,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: BoxDecoration(
        color: surface,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '个人学业预警',
                style: TextStyle(
                  color: dark
                      ? const Color(0xFFE9D7A7)
                      : const Color(0xFF344054),
                  fontSize: EcjtuMetrics.fontBodyFor(size),
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                critical ? '重点关注' : '提前提醒',
                style: TextStyle(
                  color: accent,
                  fontSize: EcjtuMetrics.fontCaptionFor(size),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              metric('当前累计', history.gpa.toStringAsFixed(2)),
              const SizedBox(width: 8),
              metric('剩余', '${horizon.remainingSemesters} 学期'),
              const SizedBox(width: 8),
              metric(
                label,
                recovery.status == RecoveryPaceStatus.missing
                    ? '—'
                    : recovery.recommendedGpa.toStringAsFixed(2),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.only(top: 11),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: dark
                      ? const Color(0xFF5D4F2D)
                      : const Color(0x29B54708),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '目标 2.50 · ${horizon.source} · ${horizon.futureCredits.toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '')} 学分',
                    softWrap: true,
                    style: TextStyle(
                      color: muted,
                      fontSize: EcjtuMetrics.fontMicroFor(size),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  pace,
                  style: TextStyle(
                    color: accent,
                    fontSize: EcjtuMetrics.fontCaptionFor(size),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<String> _plannerTerms(List<PlannedCourse> entries) {
    final terms = entries
        .map((course) => course.term)
        .where(_isTerm)
        .toSet()
        .toList();
    terms.sort((left, right) => right.compareTo(left));
    return terms;
  }

  String _plannerTermLabel(String term, List<PlannedCourse> entries) {
    final completed = _effectiveRecords
        .where((record) => record.term == term && record.hasFinalScore)
        .length;
    final pendingCount = entries.where((course) => course.term == term).length;
    return '$term · $completed/${completed + pendingCount}';
  }

  _WarningHorizon _warningHorizon({
    required List<ScoreRecord> records,
    required List<PlannedCourse> pending,
    required CurriculumSnapshot curriculum,
  }) {
    final term = _warningTerm(records, pending);
    final firstTerm = _curriculumStartTerm(records, curriculum);
    var currentIndex = _semesterIndexForTerm(firstTerm, term);
    if (currentIndex == 0) currentIndex = 1;
    if (!pending.any((course) => course.term == term) && currentIndex < 20) {
      currentIndex += 1;
    }
    var schemeEnd = 0;
    for (final semester in curriculum.semesters) {
      if (semester > schemeEnd) schemeEnd = semester;
    }
    final totalSemesters = math.max(8, math.max(schemeEnd, currentIndex));
    final remainingSemesters = math.max(1, totalSemesters - currentIndex + 1);
    final reliableScheme = curriculum.records.length >= 10;
    final observedCredits = <double>[];
    for (final value in _termSummaries(records)) {
      if (value.credits > 0) observedCredits.add(value.credits);
    }
    final typicalCredits = math
        .max(12, math.min(24, _median(observedCredits) ?? 20))
        .toDouble();
    final completed = records
        .where((record) => record.hasFinalScore && record.isIncluded)
        .toList();
    final loads = <double>[];
    for (var index = currentIndex; index <= totalSemesters; index += 1) {
      final mappedTerm = _termFromSemester(firstTerm, index);
      var credits = mappedTerm.isEmpty
          ? 0.0
          : pending
                .where((course) => course.term == mappedTerm)
                .fold<double>(0, (sum, course) => sum + course.credit);
      if (credits == 0) {
        credits = curriculum.records
            .where(
              (course) =>
                  course.semesterIndexes.contains(index) &&
                  course.status != '已过' &&
                  course.credit > 0 &&
                  _isDefiniteCurriculumCourse(course) &&
                  !completed.any((record) => _coursesMatch(record, course)),
            )
            .fold<double>(0, (sum, course) => sum + course.credit);
      }
      if (!reliableScheme && credits == 0) credits = typicalCredits;
      loads.add(credits);
    }
    var futureCredits = loads.fold<double>(0, (sum, value) => sum + value);
    if (futureCredits == 0) futureCredits = typicalCredits * remainingSemesters;
    return _WarningHorizon(
      remainingSemesters: remainingSemesters,
      futureCredits: futureCredits,
      source: reliableScheme ? '培养方案' : '四年制估算',
    );
  }

  String _warningTerm(List<ScoreRecord> records, List<PlannedCourse> pending) {
    if (_selectedPlannerTerm.isNotEmpty &&
        pending.any((course) => course.term == _selectedPlannerTerm)) {
      return _selectedPlannerTerm;
    }
    final pendingTerms = _plannerTerms(pending);
    if (pendingTerms.isNotEmpty) return pendingTerms.first;
    final terms = records.map((record) => record.term).where(_isTerm).toList()
      ..sort((left, right) => right.compareTo(left));
    return terms.isEmpty ? '' : terms.first;
  }

  bool _isDefiniteCurriculumCourse(CurriculumRecord course) {
    if (course.courseType.contains('限选')) return true;
    return !RegExp(r'任选|选修').hasMatch(course.courseType);
  }

  int _semesterIndexForTerm(String firstTerm, String term) {
    final first = RegExp(r'^(20\d{2})\.([12])$').firstMatch(firstTerm);
    final current = RegExp(r'^(20\d{2})\.([12])$').firstMatch(term);
    if (first == null || current == null) return 0;
    final firstHalf =
        int.parse(first.group(1)!) * 2 + int.parse(first.group(2)!) - 1;
    final currentHalf =
        int.parse(current.group(1)!) * 2 + int.parse(current.group(2)!) - 1;
    final index = currentHalf - firstHalf + 1;
    return index > 0 && index <= 20 ? index : 0;
  }

  double? _median(List<double> values) {
    final sorted = values.where((value) => value > 0).toList()..sort();
    if (sorted.isEmpty) return null;
    final middle = sorted.length ~/ 2;
    return sorted.length.isOdd
        ? sorted[middle]
        : (sorted[middle - 1] + sorted[middle]) / 2;
  }

  int _scoreForAverageGpa(double gpa) {
    if (gpa <= 0) return 60;
    return math.max(
      60,
      math.min(100, (60 + (math.max(1, gpa) - 1) * 10 - 1e-9).ceil()),
    );
  }

  List<ScoreRecord> get _effectiveRecords {
    if (identical(_recordsSource, widget.snapshot.records) &&
        mapEquals(_recordOverridesCache, _includeOverrides))
      return _recordsCache!;
    _recordsSource = widget.snapshot.records;
    _recordOverridesCache = Map.of(_includeOverrides);
    _summariesCache.clear();
    return _recordsCache = widget.snapshot.records.map((record) {
      final key = _courseKey(record);
      final override = _includeOverrides[key];
      return override == null
          ? record
          : record.copyWith(includeOverride: override);
    }).toList();
  }

  Widget _buildSummaryGrid(BuildContext context, List<ScoreRecord> records) {
    final values = <ScoreSummary>[
      _summaryFor(records),
      ..._termSummaries(records),
      ..._yearSummaries(records),
    ];
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        dragDevices: const {
          PointerDeviceKind.mouse,
          PointerDeviceKind.touch,
          PointerDeviceKind.stylus,
          PointerDeviceKind.trackpad,
        },
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var index = 0; index < values.length; index++)
              Padding(
                padding: EdgeInsets.only(
                  right: index == values.length - 1 ? 0 : 10,
                ),
                child: SizedBox(
                  width: 172,
                  child: _SummaryCard(
                    summary: values[index],
                    selected: _selectedTerm == values[index].term,
                    onPressed: () => _setSelectedTerm(values[index].term),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<ScoreSummary> _termSummaries(List<ScoreRecord> records) {
    final terms = records.map((record) => record.term).toSet().toList()
      ..sort((left, right) => right.compareTo(left));
    return [
      for (final term in terms)
        ScoreSummary(
          term: term,
          label: term,
          gpa: _summaryFor(records, term).gpa,
          credits: _summaryFor(records, term).credits,
          points: _summaryFor(records, term).points,
          count: _summaryFor(records, term).count,
        ),
    ];
  }

  List<ScoreSummary> _yearSummaries(List<ScoreRecord> records) {
    final years =
        records
            .map((record) => _yearOf(record.term))
            .where((year) => year.isNotEmpty)
            .toSet()
            .toList()
          ..sort((left, right) => right.compareTo(left));
    return [for (final year in years) _summaryForYear(records, year)];
  }

  ScoreSummary _summaryForYear(List<ScoreRecord> records, String year) {
    final summary = ScoreCalculations.summary(
      records.where((record) => _yearOf(record.term) == year),
    );
    return ScoreSummary(
      term: 'year:$year',
      label: '$year 学年',
      gpa: summary.gpa,
      credits: summary.credits,
      points: summary.points,
      count: summary.count,
    );
  }

  Widget _buildPlanner(
    BuildContext context,
    List<PlannedCourse> allEntries,
    List<PlannedCourse> entries,
    List<String> terms,
    GoalPlanResult result,
  ) {
    final size = MediaQuery.sizeOf(context);
    final compact = EcjtuMetrics.isCompact(size);
    final plannerTitleSize = EcjtuMetrics.fontLabelFor(size);
    final plannerCaptionSize = EcjtuMetrics.fontCaptionFor(size);
    final plannerMicroSize = EcjtuMetrics.fontMicroFor(size);
    final plannerSmallSize = EcjtuMetrics.fontSmallFor(size);
    final targetFieldWidth = plannerMicroSize * 6 + 84;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final controls = Row(
      children: [
        Expanded(
          child: EcjtuSelectBox<String>(
            value: _selectedPlannerTerm,
            items: terms,
            labelBuilder: (term) => _plannerTermLabel(term, allEntries),
            fontSize: plannerCaptionSize,
            onChanged: (value) => setState(() {
              _selectedPlannerTerm = value;
              _persistPlanner();
            }),
          ),
        ),
        SizedBox(width: compact ? 7 : 6),
        _targetGpaField(
          context,
          width: targetFieldWidth,
          labelSize: plannerMicroSize,
          inputSize: plannerSmallSize,
        ),
      ],
    );
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.only(top: 18),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: EcjtuColors.borderFrom(
              context,
              dark ? const Color(0xFF293851) : const Color(0xFFE4E7EC),
            ),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (compact) ...[
            Text(
              '绩点规划',
              style: TextStyle(
                color: EcjtuColors.textFrom(
                  context,
                  dark ? const Color(0xFFF4F7FF) : const Color(0xFF1F2937),
                ),
                fontSize: plannerTitleSize,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 9),
            controls,
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    '绩点规划',
                    style: TextStyle(
                      color: dark
                          ? const Color(0xFFF4F7FF)
                          : const Color(0xFF1F2937),
                      fontSize: plannerTitleSize,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(width: 150 + 6 + targetFieldWidth, child: controls),
              ],
            ),
          const SizedBox(height: 12),
          _PlannerResult(result: result),
          const SizedBox(height: 10),
          Text(
            '${_effectiveRecords.where((record) => record.term == _selectedPlannerTerm && record.hasFinalScore).length} 门已出 · ${entries.length} 门待估 · ${_plannerStatusLabel(result.status)}',
            style: TextStyle(
              color: EcjtuColors.mutedFrom(
                context,
                dark ? const Color(0xFF9EACC3) : const Color(0xFF667085),
              ),
              fontSize: plannerCaptionSize,
            ),
          ),
          const SizedBox(height: 3),
          for (final suggestion in result.suggestions)
            _buildPlanRow(context, suggestion),
        ],
      ),
    );
  }

  String _plannerStatusLabel(GoalPlanStatus status) => switch (status) {
    GoalPlanStatus.met => '已达目标',
    GoalPlanStatus.possible => '可达目标',
    GoalPlanStatus.impossible => '暂不可达',
    GoalPlanStatus.missing => '等待成绩',
  };

  Widget _targetGpaField(
    BuildContext context, {
    required double width,
    required double labelSize,
    required double inputSize,
  }) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: width,
      height: 30,
      child: Container(
        padding: const EdgeInsets.only(left: 8),
        decoration: BoxDecoration(
          color: EcjtuColors.surfaceFrom(
            context,
            dark ? const Color(0xFF131E32) : Colors.white,
          ),
          border: Border.all(
            color: EcjtuColors.borderFrom(
              context,
              dark ? const Color(0xFF34445F) : const Color(0xFFD0D5DD),
            ),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Text(
              '大学目标绩点',
              style: TextStyle(
                color: EcjtuColors.mutedFrom(
                  context,
                  dark ? const Color(0xFF9EACC3) : const Color(0xFF667085),
                ),
                fontSize: labelSize,
              ),
            ),
            Expanded(
              child: TextField(
                controller: _targetGpaController,
                textAlign: TextAlign.center,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: _onTargetGpaChanged,
                style: TextStyle(
                  color: EcjtuColors.textFrom(
                    context,
                    dark ? const Color(0xFFEAF1FF) : const Color(0xFF1D2939),
                  ),
                  fontSize: inputSize,
                  fontWeight: FontWeight.w700,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 2),
                ),

                contextMenuBuilder: buildEcjtuPlatformTextContextMenu,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanRow(BuildContext context, GoalSuggestion suggestion) {
    final course = suggestion.course;
    final size = MediaQuery.sizeOf(context);
    final suggestionTitleSize = EcjtuMetrics.fontSmallFor(size);
    final suggestionCaptionSize = EcjtuMetrics.fontMicroFor(size);
    final suggestionControlSize = EcjtuMetrics.fontCaptionFor(size);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final controlBorder = EcjtuColors.borderFrom(
      context,
      dark ? const Color(0xFF34445F) : const Color(0xFFD0D5DD),
    );
    final controlSurface = EcjtuColors.surfaceFrom(
      context,
      dark ? const Color(0xFF131E32) : Colors.white,
    );
    final controlFocus = Theme.of(context).colorScheme.primary;
    final scoreEnabled = course.credit > 0;
    final controller = course.gradeMode == PlannedGradeMode.numeric
        ? _plannedScoreControllerFor(suggestion)
        : null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: EcjtuColors.borderFrom(
              context,
              dark ? const Color(0xFF293851) : const Color(0xFFE4E7EC),
            ),
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.courseName,
                  softWrap: true,
                  style: TextStyle(
                    color: dark
                        ? const Color(0xFFF5F8FF)
                        : const Color(0xFF344054),
                    fontSize: suggestionTitleSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  course.credit > 0
                      ? '${_formatCredit(course.credit)} 学分'
                      : '学分未同步',
                  style: TextStyle(
                    color: dark
                        ? const Color(0xFFBDCBE0)
                        : const Color(0xFF667085),
                    fontSize: suggestionCaptionSize,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 58,
            height: EcjtuMetrics.pickerHeight,
            child: EcjtuSelectBox<PlannedGradeMode>(
              value: course.gradeMode,
              items: PlannedGradeMode.values,
              labelBuilder: (value) =>
                  value == PlannedGradeMode.level ? '等级' : '分数',
              textAlign: TextAlign.center,
              fontSize: suggestionControlSize,
              onChanged: (value) => setState(() {
                _plannedCourses[_plannedKey(course)] = course.copyWith(
                  gradeMode: value,
                  plannedScore: '',
                  manual: false,
                );
                _persistPlanner();
              }),
            ),
          ),
          const SizedBox(width: 5),
          SizedBox(
            width: 62,
            height: EcjtuMetrics.pickerHeight,
            child: course.gradeMode == PlannedGradeMode.level
                ? EcjtuSelectBox<String>(
                    value:
                        ScoreCalculations.levelOptions.contains(
                          course.plannedScore,
                        )
                        ? course.plannedScore
                        : suggestion.target,
                    items: ScoreCalculations.levelOptions,
                    labelBuilder: (value) => value,
                    textAlign: TextAlign.center,
                    fontSize: suggestionControlSize,
                    enabled: scoreEnabled,
                    onChanged: (value) => setState(() {
                      _plannedCourses[_plannedKey(course)] = course.copyWith(
                        plannedScore: value,
                        manual: true,
                      );
                      _persistPlanner();
                    }),
                  )
                : TextField(
                    enabled: scoreEnabled,
                    controller: controller,
                    textAlign: TextAlign.center,
                    textAlignVertical: TextAlignVertical.center,
                    onChanged: (value) => _onPlannedScoreChanged(course, value),
                    style: TextStyle(
                      color: EcjtuColors.textFrom(
                        context,
                        dark
                            ? const Color(0xFFEAF1FF)
                            : const Color(0xFF17202F),
                      ),
                      fontSize: suggestionControlSize,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: controlSurface,
                      isDense: false,
                      constraints: const BoxConstraints.tightFor(
                        height: EcjtuMetrics.pickerHeight,
                      ),
                      hintText: suggestion.target,
                      hintStyle: TextStyle(
                        color: EcjtuColors.mutedFrom(
                          context,
                          dark
                              ? const Color(0xFF9EACC3)
                              : const Color(0xFF7B8492),
                        ),
                        fontSize: suggestionControlSize,
                        fontWeight: FontWeight.w700,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(color: controlBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(color: controlBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(color: controlFocus),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(color: controlBorder),
                      ),
                    ),

                    contextMenuBuilder: buildEcjtuPlatformTextContextMenu,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseSection(
    BuildContext context,
    List<String> terms,
    List<ScoreRecord> records,
  ) {
    final options = <String>['all', ..._yearFilterValues(terms), ...terms];
    if (!options.contains(_selectedTerm) &&
        RegExp(r'^\d{4}\.[12]$').hasMatch(_selectedTerm)) {
      options.add(_selectedTerm);
    }
    final query = _courseQuery.trim().toLowerCase();
    final visibleRecords = query.isEmpty
        ? records
        : records
              .where(
                (record) => record.courseName.toLowerCase().contains(query),
              )
              .toList();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _courseHeading(context, visibleRecords.length, options),
          if (_courseDetailsOpen) ...[
            const SizedBox(height: 12),
            _buildCourseList(context, visibleRecords),
          ],
        ],
      ),
    );
  }

  Widget _courseHeading(BuildContext context, int count, List<String> options) {
    final size = MediaQuery.sizeOf(context);
    final compact = EcjtuMetrics.isCompact(size);
    final detailCountSize = EcjtuMetrics.fontCaptionFor(size);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final title = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() {
        _courseDetailsOpen = !_courseDetailsOpen;
      }),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '课程明细',
              style: TextStyle(
                color: dark ? const Color(0xFFF3F6FB) : const Color(0xFF1D2939),
                fontFamily: _scoreFontFamily,
                fontSize: compact ? 14 : 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 7),
            AnimatedRotation(
              turns: _courseDetailsOpen ? 0.5 : 0,
              duration: EcjtuAnimation.navigation,
              curve: EcjtuAnimation.curve,
              child: EcjtuChevronGlyph(
                size: 8,
                color: dark ? const Color(0xFFBDC9DA) : const Color(0xFF667085),
              ),
            ),
          ],
        ),
      ),
    );
    final searchButton = _CourseSearchButton(
      active: _courseSearchOpen,
      onPressed: () {
        if (_courseSearchOpen) {
          const EcjtuPageScrollAnchor(false).dispatch(context);
        }
        setState(() {
          _courseDetailsOpen = true;
          _courseSearchOpen = !_courseSearchOpen;
          if (!_courseSearchOpen) {
            _courseQuery = '';
          }
        });
      },
    );
    final detailsButton = SizedBox(
      height: 34,
      child: EcjtuDialogAction(
        label: '成绩详情',
        onPressed: () {
          const EcjtuPageScrollAnchor(false).dispatch(context);
          const EcjtuPageScrollScope(true).dispatch(context);
          setState(() => _showScoreDetails = true);
        },
      ),
    );
    final countLabel = Text(
      '$count 门',
      style: TextStyle(
        color: EcjtuColors.mutedFrom(
          context,
          dark ? const Color(0xFF9EACC3) : const Color(0xFF667085),
        ),
        fontSize: detailCountSize,
        fontWeight: FontWeight.w500,
        fontFamily: _scoreFontFamily,
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final inline = _courseSearchOpen && constraints.maxWidth >= 760;
        final field = _CourseSearchField(
          value: _courseQuery,
          onChanged: _updateCourseQuery,
        );
        final gap = constraints.maxWidth < 455 ? 4.0 : 8.0;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                title,
                SizedBox(width: gap),
                searchButton,
                if (inline) ...[
                  const SizedBox(width: 8),
                  Expanded(child: field),
                  const SizedBox(width: 12),
                ] else
                  SizedBox(width: gap),
                detailsButton,
                SizedBox(width: gap),
                countLabel,
                SizedBox(width: gap),
                if (inline)
                  _termSelect(options, width: 150)
                else
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 150),
                        child: _termSelect(options),
                      ),
                    ),
                  ),
              ],
            ),
            if (_courseSearchOpen && !inline) ...[
              const SizedBox(height: 10),
              field,
            ],
          ],
        );
      },
    );
  }

  Widget _termSelect(List<String> options, {double width = 150}) {
    return SizedBox(
      width: width,
      child: EcjtuSelectBox<String>(
        value: _selectedTerm,
        items: options,
        labelBuilder: _termLabel,
        fontSize: EcjtuMetrics.fontSmallFor(MediaQuery.sizeOf(context)),
        onChanged: _setSelectedTerm,
      ),
    );
  }

  Widget _buildCourseRow(BuildContext context, ScoreRecord record) {
    final compact = EcjtuMetrics.isCompact(MediaQuery.sizeOf(context));
    final dark = Theme.of(context).brightness == Brightness.dark;
    final key = _courseKey(record);
    final score = record.finalScore.isEmpty ? '—' : record.finalScore;
    final gp = ScoreCalculations.gradePoint(record.finalScore);
    final row = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: EcjtuColors.surfaceFrom(
          context,
          dark ? EcjtuColors.surfaceFor(context) : Colors.white,
        ),
        border: compact
            ? null
            : Border.all(
                color: EcjtuColors.borderFrom(
                  context,
                  EcjtuColors.borderFrom(
                    context,
                    dark ? const Color(0xFF293851) : const Color(0xFFE4E7EC),
                  ),
                ),
              ),
        borderRadius: compact ? BorderRadius.zero : BorderRadius.circular(8),
        boxShadow: compact || dark
            ? const []
            : const [
                BoxShadow(
                  color: Color.fromRGBO(16, 24, 40, 0.025),
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.courseName,
                  softWrap: true,
                  style: TextStyle(
                    color: dark
                        ? const Color(0xFFF3F6FB)
                        : const Color(0xFF1D2939),
                    fontFamily: _scoreFontFamily,
                    fontSize: EcjtuMetrics.fontSmallFor(
                      MediaQuery.sizeOf(context),
                    ),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '$score · ${_formatCredit(record.credit)} 学分',
                  softWrap: true,
                  style: TextStyle(
                    color: dark
                        ? const Color(0xFFBDCBE0)
                        : const Color(0xFF667085),
                    fontFamily: _scoreFontFamily,
                    fontSize: EcjtuMetrics.fontCaptionFor(
                      MediaQuery.sizeOf(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 42,
            child: Text(
              gp?.toStringAsFixed(2) ?? '—',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: dark ? const Color(0xFFE0E8F4) : const Color(0xFF344054),
                fontSize: 15,
                fontWeight: FontWeight.w700,
                fontFamily: _scoreFontFamily,
                height: 1,
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 20,
            height: 20,
            child: Center(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () =>
                    setState(() => _includeOverrides[key] = !record.isIncluded),
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: record.isIncluded
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                    border: Border.all(
                      color: record.isIncluded
                          ? Theme.of(context).colorScheme.primary
                          : (EcjtuColors.mutedFor(context)),
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: record.isIncluded
                      ? Icon(
                          Icons.check,
                          size: 11,
                          color: Theme.of(context).colorScheme.onPrimary,
                        )
                      : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
    return Opacity(opacity: record.isIncluded ? 1 : 0.42, child: row);
  }

  Widget _buildCourseList(BuildContext context, List<ScoreRecord> records) {
    final compact = EcjtuMetrics.isCompact(MediaQuery.sizeOf(context));
    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = compact ? 1.0 : 10.0;
        final width = compact
            ? constraints.maxWidth
            : (constraints.maxWidth - gap) / 2;
        return Container(
          width: double.infinity,
          color: compact ? (EcjtuColors.pageFor(context)) : Colors.transparent,
          child: Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final record in records)
                SizedBox(width: width, child: _buildCourseRow(context, record)),
            ],
          ),
        );
      },
    );
  }

  String _formatCredit(double value) {
    return value.toStringAsFixed(2).replaceFirst(RegExp(r'\.00$'), '');
  }

  List<ScoreRecord> _filterRecords(List<ScoreRecord> records) {
    final filtered = _selectedTerm == 'all'
        ? List<ScoreRecord>.of(records)
        : _selectedTerm.startsWith('year:')
        ? () {
            final year = _selectedTerm.substring(5);
            return records
                .where((record) => _yearOf(record.term) == year)
                .toList();
          }()
        : records.where((record) => record.term == _selectedTerm).toList();
    filtered.sort((left, right) {
      final termOrder = right.term.compareTo(left.term);
      if (termOrder != 0) return termOrder;
      return right.credit.compareTo(left.credit);
    });
    return filtered;
  }

  List<PlannedCourse> _plannedEntries(
    List<ScoreRecord> records,
    CurriculumSnapshot curriculum,
    List<RegistrationRecord> registrations,
  ) {
    final result = <String, PlannedCourse>{};
    for (final record in records) {
      if (record.hasFinalScore || !record.isIncluded || record.credit <= 0) {
        continue;
      }
      final key = _courseKey(record);
      result[key] =
          _plannedCourses[key] ??
          PlannedCourse(
            key: key,
            term: record.term,
            courseName: record.courseName,
            credit: record.credit,
          );
    }

    final registrationTerms = registrations
        .map((record) => record.term)
        .where(_isTerm)
        .toSet();
    if (registrationTerms.isNotEmpty) {
      result.removeWhere(
        (_, course) => registrationTerms.contains(course.term),
      );
      final completed = records
          .where((record) => record.hasFinalScore)
          .toList();
      final allCurriculum = curriculum.records;
      for (final registration in registrations) {
        if (completed.any(
          (record) => _coursesMatchRegistration(record, registration),
        )) {
          continue;
        }
        final scheme = allCurriculum.cast<CurriculumRecord?>().firstWhere(
          (item) => item != null && _coursesMatchStrict(item, registration),
          orElse: () => null,
        );
        final identity = scheme?.courseCode.isNotEmpty == true
            ? scheme!.courseCode
            : registration.courseCode.isNotEmpty
            ? registration.courseCode
            : registration.courseName;
        final key = '${registration.term}|$identity';
        result[key] =
            _plannedCourses[key] ??
            PlannedCourse(
              key: key,
              term: registration.term,
              courseName: registration.courseName,
              credit: scheme?.credit ?? registration.credit,
            );
      }
      return result.values.toList();
    }

    final firstTerm = _curriculumStartTerm(records, curriculum);
    if (firstTerm.isNotEmpty) {
      for (final scheme in curriculum.records) {
        if (scheme.isPassed || scheme.credit <= 0) continue;
        final hasCompletedScore = records.any(
          (record) => record.hasFinalScore && _coursesMatch(record, scheme),
        );
        if (hasCompletedScore) continue;
        final term = _termFromSemester(firstTerm, scheme.semesterIndex);
        if (term.isEmpty) continue;
        final key = '$term|${scheme.identity}';
        result.putIfAbsent(
          key,
          () =>
              _plannedCourses[key] ??
              PlannedCourse(
                key: key,
                term: term,
                courseName: scheme.courseName,
                credit: scheme.credit,
              ),
        );
      }
    }
    return result.values.toList();
  }

  TextEditingController _plannedScoreControllerFor(GoalSuggestion suggestion) {
    final key = suggestion.course.key;
    final initial = suggestion.manual
        ? suggestion.course.plannedScore
        : suggestion.target;
    final controller = _plannedScoreControllers.putIfAbsent(
      key,
      () => TextEditingController(text: initial),
    );
    if (!suggestion.manual && controller.text != suggestion.target) {
      controller.value = TextEditingValue(
        text: suggestion.target,
        selection: TextSelection.collapsed(offset: suggestion.target.length),
      );
    }
    return controller;
  }

  void _onTargetGpaChanged(String value) {
    final parsed = double.tryParse(value);
    if (parsed == null) return;
    setState(() => _targetGpa = parsed.clamp(0, 5).toDouble());
    _persistPlanner();
  }

  void _onPlannedScoreChanged(PlannedCourse course, String value) {
    _plannedCourses[course.key] = course.copyWith(
      plannedScore: value,
      manual: true,
    );
    setState(() {});
    _persistPlanner();
  }

  String _courseKey(ScoreRecord record) =>
      '${record.term}|${record.courseCode.isEmpty ? record.courseName : record.courseCode}';

  String _plannedKey(PlannedCourse course) => course.key;

  bool _coursesMatch(ScoreRecord score, CurriculumRecord scheme) {
    if (score.courseCode.isNotEmpty && scheme.courseCode.isNotEmpty) {
      return score.courseCode == scheme.courseCode;
    }
    return _normalizeCourseName(score.courseName) ==
        _normalizeCourseName(scheme.courseName);
  }

  bool _coursesMatchRegistration(
    ScoreRecord score,
    RegistrationRecord registration,
  ) {
    if (score.term != registration.term) return false;
    if (score.courseCode.isNotEmpty && registration.courseCode.isNotEmpty) {
      return score.courseCode == registration.courseCode;
    }
    return ScoreCalculations.courseNamesMatch(
      score.courseName,
      registration.courseName,
    );
  }

  bool _coursesMatchStrict(
    CurriculumRecord scheme,
    RegistrationRecord registration,
  ) {
    if (scheme.courseCode.isNotEmpty && registration.courseCode.isNotEmpty) {
      return scheme.courseCode == registration.courseCode;
    }
    return _normalizeCourseName(scheme.courseName) ==
        _normalizeCourseName(registration.courseName);
  }

  String _curriculumStartTerm(
    List<ScoreRecord> records,
    CurriculumSnapshot curriculum,
  ) {
    final scoreTerms =
        records.map((record) => record.term).where(_isTerm).toSet().toList()
          ..sort();
    if (curriculum.records.isEmpty) {
      return scoreTerms.isEmpty ? '' : scoreTerms.first;
    }

    final votes = <String, int>{};
    for (final record in records) {
      final scheme = curriculum.records.cast<CurriculumRecord?>().firstWhere(
        (item) => item != null && _coursesMatch(record, item),
        orElse: () => null,
      );
      if (scheme == null) continue;
      final inferred = _firstTermFromObserved(
        record.term,
        scheme.semesterIndex,
      );
      if (inferred.isEmpty) continue;
      final weight =
          record.courseCode.isNotEmpty && scheme.courseCode == record.courseCode
          ? 4
          : 1;
      votes[inferred] = (votes[inferred] ?? 0) + weight;
    }
    if (votes.isEmpty) return scoreTerms.isEmpty ? '' : scoreTerms.first;
    final entries = votes.entries.toList()
      ..sort(
        (left, right) => right.value.compareTo(left.value) != 0
            ? right.value.compareTo(left.value)
            : left.key.compareTo(right.key),
      );
    return entries.first.key;
  }

  String _firstTermFromObserved(String term, int semesterIndex) {
    final match = RegExp(r'^(20\d{2})\.([12])$').firstMatch(term);
    if (match == null || semesterIndex < 1) return '';
    final observedHalf =
        int.parse(match.group(1)!) * 2 + int.parse(match.group(2)!) - 1;
    final firstHalf = observedHalf - semesterIndex + 1;
    if (firstHalf < 0) return '';
    return '${firstHalf ~/ 2}.${firstHalf % 2 + 1}';
  }

  String _termFromSemester(String firstTerm, int semesterIndex) {
    final match = RegExp(r'^(20\d{2})\.([12])$').firstMatch(firstTerm);
    if (match == null || semesterIndex < 1) return '';
    final firstHalf =
        int.parse(match.group(1)!) * 2 + int.parse(match.group(2)!) - 1;
    final half = firstHalf + semesterIndex - 1;
    return '${half ~/ 2}.${half % 2 + 1}';
  }

  bool _isTerm(String value) => RegExp(r'^20\d{2}\.[12]$').hasMatch(value);

  String _normalizeCourseName(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'\s+'), '')
      .replaceAll(RegExp(r'[()（）·・]'), '');

  String _termLabel(String value) {
    if (value == 'all') return '全部';
    if (value.startsWith('year:')) return '${value.substring(5)} 学年';
    return value;
  }

  List<String> _yearFilterValues(List<String> terms) {
    final years =
        terms.map(_yearOf).where((year) => year.isNotEmpty).toSet().toList()
          ..sort((left, right) => right.compareTo(left));
    return years.map((year) => 'year:$year').toList();
  }

  String _yearOf(String term) {
    return RegExp(r'^(20\d{2})\.[12]$').firstMatch(term)?.group(1) ?? '';
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.summary,
    required this.selected,
    required this.onPressed,
  });

  final ScoreSummary summary;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fullScale = !EcjtuMetrics.isCompact(size);
    final summaryCaptionSize = EcjtuMetrics.fontMicroFor(size);
    final border = selected
        ? (dark ? const Color(0xFF4A8FD1) : const Color(0xFF79B8E5))
        : (EcjtuColors.borderFrom(
            context,
            dark ? const Color(0xFF30415D) : const Color(0xFFE4E7EC),
          ));
    final surface = selected
        ? (EcjtuColors.surfaceFrom(
            context,
            dark ? const Color(0xFF142A48) : const Color(0xFFF0F8FF),
          ))
        : (dark ? EcjtuColors.surfaceFor(context) : Colors.white);
    final card = Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: selected
            ? EcjtuControlPalette.maybeOf(context)?.selected ?? surface
            : EcjtuColors.surfaceFrom(context, surface),
        border: Border.all(color: EcjtuColors.borderFrom(context, border)),
        borderRadius: BorderRadius.circular(8),
        boxShadow: dark
            ? const []
            : const [
                BoxShadow(
                  color: Color(0x08101828),
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
      ),
      foregroundDecoration: selected
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border(
                left: BorderSide(
                  width: 4,
                  color:
                      EcjtuControlPalette.maybeOf(context)?.focus ??
                      const Color(0xFF0475CC),
                ),
              ),
            )
          : null,
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 14,
              vertical: fullScale ? 16 : 15,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  summary.displayLabel,
                  softWrap: true,
                  style: TextStyle(
                    color: EcjtuColors.mutedFrom(
                      context,
                      dark ? const Color(0xFF9EACC3) : const Color(0xFF667085),
                    ),
                    fontSize: summaryCaptionSize,
                    fontFamily: _scoreFontFamily,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  summary.gpa.toStringAsFixed(2),
                  style: TextStyle(
                    color: EcjtuColors.textFrom(
                      context,
                      dark ? const Color(0xFFF4F7FF) : const Color(0xFF1F2937),
                    ),
                    fontSize: 25,
                    fontWeight: FontWeight.w700,
                    fontFamily: _scoreFontFamily,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${summary.credits.toStringAsFixed(2).replaceFirst(RegExp(r'\.00$'), '')} 学分',
                  style: TextStyle(
                    color: EcjtuColors.mutedFrom(
                      context,
                      dark ? const Color(0xFF9EACC3) : const Color(0xFF667085),
                    ),
                    fontSize: summaryCaptionSize,
                    fontFamily: _scoreFontFamily,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    if (onPressed == null) return card;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onPressed,
      child: card,
    );
  }
}

class _PlannerResult extends StatelessWidget {
  const _PlannerResult({required this.result});

  final GoalPlanResult result;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final captionSize = EcjtuMetrics.fontCaptionFor(size);
    final primaryText = dark ? EcjtuColors.textFor(context) : Colors.white;
    final secondaryText = dark
        ? EcjtuColors.mutedFor(context)
        : const Color(0xFFE5F3FF);
    final mutedText = dark
        ? EcjtuColors.mutedFor(context)
        : const Color(0xFFC6E4FA);
    final cumulativeLabel = result.status == GoalPlanStatus.impossible
        ? '累计最高'
        : '累计预计';
    return Container(
      height: 112,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
      decoration: BoxDecoration(
        color: dark
            ? EcjtuColors.surfaceFor(context)
            : EcjtuGlass.of(context).green
            ? Theme.of(context).colorScheme.primary
            : const Color(0xFF075FA5),
        borderRadius: BorderRadius.circular(8),
        boxShadow: dark
            ? const [
                BoxShadow(
                  color: Color(0x48000000),
                  blurRadius: 28,
                  offset: Offset(0, 10),
                ),
              ]
            : [
                BoxShadow(
                  color:
                      (EcjtuGlass.of(context).green
                              ? Theme.of(context).colorScheme.primary
                              : const Color(0xFF0475CC))
                          .withValues(alpha: .2),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 10,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '本学期预计绩点',
                  style: TextStyle(color: secondaryText, fontSize: captionSize),
                ),
                const SizedBox(height: 9),
                Text(
                  result.termGpa.toStringAsFixed(2),
                  style: TextStyle(
                    color: primaryText,
                    fontSize: 38,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            flex: 7,
            child: Container(
              constraints: const BoxConstraints(minWidth: 118),
              padding: const EdgeInsets.only(left: 17),
              decoration: const BoxDecoration(
                border: Border(left: BorderSide(color: Color(0x33FFFFFF))),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _PlannerMetric(
                    label: cumulativeLabel,
                    value:
                        (result.status == GoalPlanStatus.impossible
                                ? result.maxCumulativeGpa
                                : result.predictedGpa)
                            .toStringAsFixed(2),
                    labelColor: mutedText,
                    valueColor: primaryText,
                  ),
                  const SizedBox(height: 9),
                  _PlannerMetric(
                    label: '大学目标绩点',
                    value: result.targetGpa.toStringAsFixed(2),
                    labelColor: mutedText,
                    valueColor: primaryText,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlannerMetric extends StatelessWidget {
  const _PlannerMetric({
    required this.label,
    required this.value,
    required this.labelColor,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color labelColor;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final labelSize = EcjtuMetrics.fontMicroFor(size);
    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        Expanded(
          child: Text(
            label,
            softWrap: true,
            style: TextStyle(color: labelColor, fontSize: labelSize),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
      ],
    );
  }
}

class _WarningHorizon {
  const _WarningHorizon({
    required this.remainingSemesters,
    required this.futureCredits,
    required this.source,
  });

  final int remainingSemesters;
  final double futureCredits;
  final String source;
}

class _CourseSearchButton extends StatelessWidget {
  const _CourseSearchButton({required this.active, required this.onPressed});

  final bool active;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final normalBackground = EcjtuColors.surfaceFrom(
      context,
      (dark ? const Color(0xFF16263D) : const Color(0xFFF2F8FC)),
    );
    final activeBackground = EcjtuColors.hoverFrom(
      context,
      (dark ? const Color(0xFF1B3553) : const Color(0xFFE4F1F8)),
    );
    final normalBorder = EcjtuColors.borderFrom(
      context,
      (dark ? const Color(0xFF3B5878) : const Color(0xFFA9C9DC)),
    );
    final activeBorder = dark
        ? const Color(0xFF5CA7E8)
        : const Color(0xFF287AA8);
    final foreground = EcjtuColors.textFrom(
      context,
      dark ? const Color(0xFFD9EBFF) : const Color(0xFF275B7A),
    );
    return SizedBox(
      width: 34,
      height: 34,
      child: IconButton(
        tooltip: '搜索课程',
        onPressed: onPressed,
        icon: EcjtuIcon('smart_work_search.svg', size: 16, color: foreground),
        padding: EdgeInsets.zero,
        style: ButtonStyle(
          fixedSize: const WidgetStatePropertyAll(Size(34, 34)),
          minimumSize: const WidgetStatePropertyAll(Size(34, 34)),
          padding: const WidgetStatePropertyAll(EdgeInsets.zero),
          foregroundColor: WidgetStatePropertyAll(foreground),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.hovered) || active
                ? activeBackground
                : normalBackground,
          ),
          side: WidgetStateProperty.resolveWith(
            (states) => BorderSide(
              color: states.contains(WidgetState.hovered) || active
                  ? activeBorder
                  : normalBorder,
            ),
          ),
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(7)),
            ),
          ),
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}

class _CourseSearchField extends StatefulWidget {
  const _CourseSearchField({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  State<_CourseSearchField> createState() => _CourseSearchFieldState();
}

class _CourseSearchFieldState extends State<_CourseSearchField> {
  late final TextEditingController _controller;
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
    _controller.addListener(_onEditingChanged);
  }

  void _onEditingChanged() {
    final editing = _controller.value;
    if (editing.composing.isValid && !editing.composing.isCollapsed) {
      final composing = editing.composing.textInside(editing.text);
      if (RegExp(r'^[a-zA-Z\s]+$').hasMatch(composing)) return;
    }
    if (editing.text != widget.value) widget.onChanged(editing.text);
  }

  @override
  void didUpdateWidget(covariant _CourseSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && _controller.text != widget.value) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.sizeOf(context);
    return ListenableBuilder(
      listenable: _focus,
      builder: (context, _) => Container(
        key: const ValueKey('course-search-painted-outline'),
        height: 34,
        decoration: BoxDecoration(
          color: EcjtuColors.surfaceFrom(
            context,
            dark ? const Color(0xFF14263A) : Colors.white,
          ),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: _focus.hasFocus
                ? Theme.of(context).colorScheme.primary.withValues(alpha: .55)
                : EcjtuColors.borderFrom(
                    context,
                    dark ? const Color(0xFF426B83) : const Color(0xFFB9CFDD),
                  ),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 11),
        child: Center(
          child: TextField(
            controller: _controller,
            focusNode: _focus,
            autofocus: true,
            textAlignVertical: TextAlignVertical.center,
            scrollPadding: EdgeInsets.zero,
            style: TextStyle(
              color: EcjtuColors.textFor(context),
              fontSize: EcjtuMetrics.fontBodyFor(size),
              height: 1.2,
            ),
            decoration: InputDecoration(
              hintText: '搜索课程',
              hintStyle: TextStyle(
                color: EcjtuColors.mutedFor(context),
                fontSize: EcjtuMetrics.fontBodyFor(size),
              ),
              isDense: true,
              isCollapsed: true,
              filled: false,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
            contextMenuBuilder: buildEcjtuPlatformTextContextMenu,
          ),
        ),
      ),
    );
  }
}
