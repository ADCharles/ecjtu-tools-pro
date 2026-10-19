// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'academic_snapshot_storage.dart';
import 'arrangement_models.dart';
import 'arrangement_snapshot_merge.dart';
import 'curriculum_models.dart';
import 'score_models.dart';

class AcademicSnapshotFallback {
  AcademicSnapshotBundle saved = const AcademicSnapshotBundle();

  ArrangementSnapshot preview(
    ArrangementSnapshot current, {
    required Set<String> fetched,
  }) => current.copyWith(
    schedules: fetched.contains('schedule') || current.schedules.isNotEmpty
        ? current.schedules
        : saved.arrangement.schedules,
    exams: [
      for (final type in ExamArrangementType.values)
        ...((fetched.contains(
                      type == ExamArrangementType.retake ? 'retakes' : 'exams',
                    ) ||
                    current.exams.any((entry) => entry.type == type))
                ? current.exams
                : saved.arrangement.exams)
            .where((entry) => entry.type == type),
    ],
    currentTerm: current.currentTerm ?? saved.arrangement.currentTerm,
    currentWeek: current.currentWeek ?? saved.arrangement.currentWeek,
  );

  ArrangementSnapshot schedulePreview(ArrangementSnapshot current) =>
      current.schedules.isNotEmpty
      ? current
      : current.copyWith(
          schedules: saved.arrangement.schedules,
          currentTerm: current.currentTerm ?? saved.arrangement.currentTerm,
          currentWeek: current.currentWeek ?? saved.arrangement.currentWeek,
        );

  ArrangementSnapshot withPlanningRegistrations(
    ArrangementSnapshot current,
    List<RegistrationRecord> incoming,
  ) => current.copyWith(
    registrations: arrangement(
      current,
      ArrangementSnapshot(registrations: incoming),
    ).registrations,
  );

  ArrangementSnapshot arrangement(
    ArrangementSnapshot current,
    ArrangementSnapshot incoming,
  ) => mergeArrangementSnapshots(
    mergeArrangementSnapshots(saved.arrangement, current),
    incoming,
  );

  ScoreSnapshot scores(ScoreSnapshot current, ScoreSnapshot incoming) =>
      mergeScoreSnapshots(mergeScoreSnapshots(saved.scores, current), incoming);

  CurriculumSnapshot curriculum(CurriculumSnapshot current) =>
      current.records.isNotEmpty ? current : saved.curriculum;

  AcademicSnapshotBundle forPersistence({
    required ArrangementSnapshot currentArrangement,
    required ScoreSnapshot currentScores,
    required CurriculumSnapshot currentCurriculum,
    required Set<String> fetched,
  }) => AcademicSnapshotBundle(
    arrangement: ArrangementSnapshot(
      schedules: fetched.contains('schedule')
          ? currentArrangement.schedules
          : saved.arrangement.schedules,
      registrations:
          fetched.contains('schedule') || fetched.contains('scorePlanning')
          ? currentArrangement.registrations
          : saved.arrangement.registrations,
      exams: [
        for (final type in ExamArrangementType.values)
          ...(fetched.contains(
                    type == ExamArrangementType.retake ? 'retakes' : 'exams',
                  )
                  ? currentArrangement.exams
                  : saved.arrangement.exams)
              .where((entry) => entry.type == type),
      ],
      currentTerm:
          currentArrangement.currentTerm ?? saved.arrangement.currentTerm,
      currentWeek:
          currentArrangement.currentWeek ?? saved.arrangement.currentWeek,
    ),
    scores: fetched.contains('scores') ? currentScores : saved.scores,
    curriculum: fetched.contains('curriculum')
        ? currentCurriculum
        : saved.curriculum,
    updatedAt: DateTime.now(),
  );
}
