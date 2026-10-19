// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'diary_storage.dart';

class CalendarNotesStorage {
  CalendarNotesStorage({DiaryStorage? diary})
    : diary = diary ?? DiaryStorage.instance;
  final DiaryStorage diary;
  Future<Map<String, String>> read(String studentId) async => {
    for (final entry in (await diary.readAll(studentId)).values)
      entry.date: entry.displayTitle,
  };
  Future<void> write(String studentId, Map<String, String> notes) async {
    for (final entry in notes.entries) {
      await writeOne(studentId, entry.key, entry.value);
    }
  }

  Future<void> writeOne(String studentId, String date, String value) =>
      diary.setTitle(studentId, date, value);
  Future<void> merge(String primaryStudentId, String aliasStudentId) async {
    if (primaryStudentId.trim().isEmpty ||
        aliasStudentId.trim().isEmpty ||
        primaryStudentId.trim() == aliasStudentId.trim())
      return;
    final entries = (await diary.readAll(aliasStudentId)).values.toList();
    for (final id in entries.expand((entry) => entry.assetIds).toSet()) {
      final image = await diary.assetFile(aliasStudentId, id);
      await diary.addImage(primaryStudentId, await image.readAsBytes());
    }
    await diary.mergeEntries(primaryStudentId, entries);
  }
}
