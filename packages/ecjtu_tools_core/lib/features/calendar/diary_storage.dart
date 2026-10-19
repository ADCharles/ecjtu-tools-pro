// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../update/update_models.dart' show sha256Bytes;
import 'diary_models.dart';

class DiaryEditConflict implements Exception {
  const DiaryEditConflict(this.current);
  final DiaryEntry? current;
  @override
  String toString() => '日记已更新，草稿尚未保存';
}

class DiaryEditDraft {
  const DiaryEditDraft(this.entry, this.expectedUpdatedAt);
  final DiaryEntry entry;
  final DateTime? expectedUpdatedAt;
}

class _DiaryTransaction {
  _DiaryTransaction(this.account);
  final String account;
  bool active = true;
}

class DiaryStorage {
  DiaryStorage({this.directory, this.migrateLegacy = true});
  static final instance = DiaryStorage();
  final Directory? directory;
  final bool migrateLegacy;
  final _queues = <String, Future<void>>{};
  final _transactionKey = Object();
  Future<Directory> _root() async =>
      directory ??
      Directory(
        '${(await getApplicationSupportDirectory()).path}/calendar-diary/v1',
      );
  Future<Directory> _account(String account) async {
    if (account.trim().isEmpty) throw StateError('请先登录');
    final hash = sha256Bytes(utf8.encode(account.trim()));
    return Directory('${(await _root()).path}/accounts/$hash');
  }

  Future<T> _serial<T>(String account, Future<T> Function() operation) async {
    final key = account.trim();
    final transaction = Zone.current[_transactionKey] as _DiaryTransaction?;
    if (transaction != null &&
        transaction.active &&
        transaction.account == key) {
      return operation();
    }
    final previous = _queues[key] ?? Future<void>.value();
    final result = previous.then((_) async {
      final transaction = _DiaryTransaction(key);
      try {
        // Nested public reads/writes participate in the same edit transaction.
        return await runZoned(
          operation,
          zoneValues: {_transactionKey: transaction},
        );
      } finally {
        transaction.active = false;
      }
    });
    final settled = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    _queues[key] = settled;
    try {
      return await result;
    } finally {
      if (identical(_queues[key], settled)) _queues.remove(key);
    }
  }

  Future<void> _atomicWrite(File file, String data) async {
    await file.parent.create(recursive: true);
    final temporary = File('${file.path}.tmp');
    await temporary.writeAsString(data, flush: true);
    if (await file.exists()) await file.copy('${file.path}.previous');
    await temporary.rename(file.path);
  }

  Future<Map<String, DiaryEntry>> _read(String account) async {
    final folder = await _account(account);
    final file = File('${folder.path}/entries.json');
    Map<String, DiaryEntry> decode(String raw) {
      final value = jsonDecode(raw) as Map<String, dynamic>;
      if (value['format'] != 'adcharles.diary' || value['schema'] != 1) {
        throw const FormatException('日记数据版本无效');
      }
      final entries = <String, DiaryEntry>{};
      for (final raw in value['entries'] as List) {
        final entry = DiaryEntry.fromJson(raw as Map<String, dynamic>);
        if (entries.containsKey(entry.date)) {
          throw const FormatException('日期重复');
        }
        entries[entry.date] = entry;
      }
      return entries;
    }

    if (await file.exists()) {
      try {
        return decode(await file.readAsString());
      } catch (_) {
        final previous = File('${file.path}.previous');
        if (!await previous.exists()) rethrow;
        return decode(await previous.readAsString());
      }
    }
    final entries = <String, DiaryEntry>{};
    if (migrateLegacy) {
      final preferences = await SharedPreferences.getInstance();
      final raw = preferences.getString(
        'ecjtu.calendar.daily_notes.${account.trim()}',
      );
      if (raw != null && raw.isNotEmpty) {
        final legacy = jsonDecode(raw) as Map;
        for (final item in legacy.entries) {
          final date = diaryDate(item.key as String);
          entries[item.key as String] = DiaryEntry.empty(
            date,
          ).edit(title: item.value as String, markdown: false);
        }
        await _write(account, entries);
      }
    }
    return entries;
  }

  Future<void> _write(String account, Map<String, DiaryEntry> entries) async {
    final folder = await _account(account);
    final dates = entries.keys.toList()..sort();
    await _atomicWrite(
      File('${folder.path}/entries.json'),
      jsonEncode({
        'format': 'adcharles.diary',
        'schema': 1,
        'entries': dates.map((date) => entries[date]!.toJson()).toList(),
      }),
    );
  }

  Future<Map<String, DiaryEntry>> readAll(String account) =>
      _serial(account, () => _read(account));
  Future<double> readRenderScale(String account) => _serial(account, () async {
    final file = File('${(await _account(account)).path}/preferences.json');
    if (!await file.exists()) return 1;
    final value = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    final scale = (value['renderScale'] as num? ?? 1).toDouble();
    return scale.isFinite && scale >= .75 && scale <= 2 ? scale : 1;
  });
  Future<void> setRenderScale(String account, double scale) =>
      _serial(account, () async {
        if (!scale.isFinite || scale < .75 || scale > 2) {
          throw const FormatException('文字比例无效');
        }
        await _atomicWrite(
          File('${(await _account(account)).path}/preferences.json'),
          jsonEncode({'font': 'kai', 'renderScale': scale}),
        );
      });
  Future<DiaryEntry> readEntry(String account, DateTime date) async =>
      (await readAll(account))[diaryDateKey(date)] ?? DiaryEntry.empty(date);
  Future<void> save(String account, DiaryEntry entry) =>
      _serial(account, () async {
        final entries = await _read(account);
        if (entry.isEmpty) {
          entries.remove(entry.date);
        } else {
          entries[entry.date] = entry;
        }
        await _write(account, entries);
      });
  Future<void> updateEntry(
    String account,
    DateTime date,
    DiaryEntry Function(DiaryEntry? current) update,
  ) => _serial(account, () async {
    final entries = await readAll(account);
    final key = diaryDateKey(date);
    var next = update(entries[key]);
    if (next.date != key) throw const FormatException('日记日期无效');
    final current = entries[key];
    if (current != null && !next.updatedAt.isAfter(current.updatedAt)) {
      next = DiaryEntry.fromJson({
        ...next.toJson(),
        'updatedAt': current.updatedAt
            .add(const Duration(microseconds: 1))
            .toUtc()
            .toIso8601String(),
      });
    }
    await save(account, next);
  });

  /// A null expected version means the date had no persisted entry.
  Future<DiaryEntry?> saveEditedEntry(
    String account,
    DiaryEntry entry, {
    required DateTime? expectedUpdatedAt,
  }) => _serial(account, () async {
    diaryDate(entry.date);
    final current = (await readAll(account))[entry.date];
    final matches = current == null
        ? expectedUpdatedAt == null
        : expectedUpdatedAt != null &&
              current.updatedAt.isAtSameMomentAs(expectedUpdatedAt);
    if (!matches) throw DiaryEditConflict(current);
    var updatedAt = DateTime.now().toUtc();
    if (current != null && !updatedAt.isAfter(current.updatedAt)) {
      updatedAt = current.updatedAt.add(const Duration(microseconds: 1));
    }
    final saved = DiaryEntry.fromJson({
      ...entry.toJson(),
      'updatedAt': updatedAt.toIso8601String(),
    });
    await save(account, saved);
    return saved.isEmpty ? null : saved;
  });

  Future<File> _draftFile(String account, DateTime date) async => File(
    '${(await _account(account)).path}/drafts/${diaryDateKey(date)}.json',
  );

  Future<void> saveDraft(
    String account,
    DiaryEntry entry, {
    required DateTime? expectedUpdatedAt,
  }) => _serial(account, () async {
    await _atomicWrite(
      await _draftFile(account, diaryDate(entry.date)),
      jsonEncode({
        'format': 'adcharles.diary.draft',
        'schema': 1,
        'entry': entry.toJson(),
        'expectedUpdatedAt': expectedUpdatedAt?.toUtc().toIso8601String(),
      }),
    );
  });

  Future<DiaryEditDraft?> readDraft(String account, DateTime date) async {
    final file = await _draftFile(account, date);
    if (!await file.exists()) return null;
    DiaryEditDraft decode(String raw) {
      final value = jsonDecode(raw) as Map<String, dynamic>;
      if (value['format'] != 'adcharles.diary.draft' || value['schema'] != 1) {
        throw const FormatException('草稿数据版本无效');
      }
      final entry = DiaryEntry.fromJson(value['entry'] as Map<String, dynamic>);
      if (entry.date != diaryDateKey(date)) {
        throw const FormatException('草稿日期无效');
      }
      return DiaryEditDraft(
        entry,
        value['expectedUpdatedAt'] == null
            ? null
            : DateTime.parse(value['expectedUpdatedAt'] as String).toUtc(),
      );
    }

    try {
      return decode(await file.readAsString());
    } catch (_) {
      final previous = File('${file.path}.previous');
      if (!await previous.exists()) rethrow;
      return decode(await previous.readAsString());
    }
  }

  Future<void> clearDraft(String account, DateTime date) =>
      _serial(account, () async {
        final file = await _draftFile(account, date);
        for (final path in [
          file.path,
          '${file.path}.previous',
          '${file.path}.tmp',
        ]) {
          final draft = File(path);
          if (await draft.exists()) await draft.delete();
        }
      });
  Future<void> setTitle(String account, String date, String title) =>
      _serial(account, () async {
        final entries = await _read(account);
        final entry = (entries[date] ?? DiaryEntry.empty(diaryDate(date)))
            .withOuterTitle(title);
        if (entry.isEmpty) {
          entries.remove(date);
        } else {
          entries[date] = entry;
        }
        await _write(account, entries);
      });
  Future<void> mergeEntries(
    String account,
    Iterable<DiaryEntry> imported, {
    bool replaceExisting = false,
  }) => _serial(account, () async {
    final entries = await _read(account);
    for (final entry in imported) {
      final current = entries[entry.date];
      if (current == null || replaceExisting) {
        entries[entry.date] = entry;
      }
    }
    await _write(account, entries);
  });
  Future<File> assetFile(String account, String id) async {
    if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(id)) {
      throw const FormatException('图片标识无效');
    }
    return File('${(await _account(account)).path}/assets/$id');
  }

  static String imageMime(List<int> bytes) {
    bool starts(List<int> prefix) =>
        bytes.length >= prefix.length &&
        List.generate(
          prefix.length,
          (i) => bytes[i] == prefix[i],
        ).every((v) => v);
    if (starts([137, 80, 78, 71, 13, 10, 26, 10])) return 'image/png';
    if (starts([255, 216, 255])) return 'image/jpeg';
    if (starts([71, 73, 70, 56])) return 'image/gif';
    if (starts([82, 73, 70, 70]) &&
        bytes.length >= 12 &&
        ascii.decode(bytes.sublist(8, 12), allowInvalid: true) == 'WEBP') {
      return 'image/webp';
    }
    throw const FormatException('请选择 PNG、JPEG、GIF 或 WebP 图片');
  }

  Future<String> addImage(String account, Uint8List bytes) async {
    if (bytes.isEmpty || bytes.length > 20 * 1024 * 1024) {
      throw const FormatException('图片大小不能超过 20 MB');
    }
    imageMime(bytes);
    final id = sha256Bytes(bytes);
    final file = await assetFile(account, id);
    await file.parent.create(recursive: true);
    if (!await file.exists()) {
      final temporary = File('${file.path}.${newDiaryId()}.tmp');
      await temporary.writeAsBytes(bytes, flush: true);
      await temporary.rename(file.path);
    }
    return id;
  }
}
