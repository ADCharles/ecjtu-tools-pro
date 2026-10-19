// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:async';
import 'dart:io';

import 'package:ecjtu_tools_core/features/calendar/diary_models.dart';
import 'package:ecjtu_tools_core/features/calendar/diary_page.dart';
import 'package:ecjtu_tools_core/features/calendar/diary_storage.dart';
import 'package:ecjtu_tools_core/theme/ecjtu_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

final _date = DateTime(2026, 10, 6);
const _account = 'diary-concurrent-fixture';

class _MemoryDiary extends DiaryStorage {
  final entries = <String, DiaryEntry>{};
  final drafts = <String, DiaryEditDraft>{};
  Completer<void>? nextWrite;
  Completer<void>? writeStarted;
  bool failDraft = false;

  @override
  Future<Map<String, DiaryEntry>> readAll(String account) async => {...entries};
  @override
  Future<void> save(String account, DiaryEntry entry) async {
    final gate = nextWrite;
    nextWrite = null;
    writeStarted?.complete();
    writeStarted = null;
    if (gate != null) await gate.future;
    if (entry.isEmpty) {
      entries.remove(entry.date);
    } else {
      entries[entry.date] = entry;
    }
  }

  @override
  Future<double> readRenderScale(String account) async => 1;
  @override
  Future<DiaryEditDraft?> readDraft(String account, DateTime date) async =>
      drafts[diaryDateKey(date)];
  @override
  Future<void> saveDraft(
    String account,
    DiaryEntry entry, {
    required DateTime? expectedUpdatedAt,
  }) async {
    if (failDraft) throw StateError('draft fixture write failed');
    drafts[entry.date] = DiaryEditDraft(entry, expectedUpdatedAt);
  }

  @override
  Future<void> clearDraft(String account, DateTime date) async {
    drafts.remove(diaryDateKey(date));
  }
}

Future<void> _pumpPage(WidgetTester tester, DiaryStorage storage) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: EcjtuTheme.light,
      home: DiaryPage(account: _account, initialDate: _date, storage: storage),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _edit(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.byType(TextField).last);
  await tester.enterText(find.byType(TextField).last, text);
}

Future<void> _tap(WidgetTester tester, String label) async {
  await tester.ensureVisible(find.text(label).last);
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

Future<void> _autosave(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pumpAndSettle();
}

Future<void> _aiEdit(DiaryStorage storage, String body) => storage.updateEntry(
  _account,
  _date,
  (current) => (current ?? DiaryEntry.empty(_date)).edit(body: body),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('atomic edit storage', () {
    late Directory directory;
    late DiaryStorage storage;
    setUp(() async {
      directory = await Directory.systemTemp.createTemp('ecjtu-diary-cas-');
      storage = DiaryStorage(directory: directory, migrateLegacy: false);
    });
    tearDown(() async {
      await directory.delete(recursive: true);
    });

    test(
      'AI update wins over stale editor and save keeps default compatibility',
      () async {
        final original = DiaryEntry.empty(_date).edit(body: 'original');
        await storage.save(_account, original);
        await _aiEdit(storage, 'AI latest');
        final latest = await storage.readEntry(_account, _date);
        await expectLater(
          storage.saveEditedEntry(
            _account,
            original.edit(body: 'stale editor'),
            expectedUpdatedAt: original.updatedAt,
          ),
          throwsA(
            isA<DiaryEditConflict>().having(
              (e) => e.current!.body,
              'current body',
              'AI latest',
            ),
          ),
        );
        expect(
          (await storage.readEntry(_account, _date)).updatedAt,
          latest.updatedAt,
        );
        await storage.save(_account, original);
        expect((await storage.readEntry(_account, _date)).body, 'original');
      },
    );

    test(
      'two concurrent CAS writes have one winner and preserve other dates/accounts',
      () async {
        final original = DiaryEntry.empty(_date).edit(body: 'original');
        final other = DiaryEntry.empty(
          DateTime(2026, 10, 7),
        ).edit(body: 'other date');
        await storage.save(_account, original);
        await storage.save(_account, other);
        await storage.save(
          'another-account',
          original.edit(body: 'another account'),
        );
        final attempts = ['one', 'two'].map(
          (body) => storage
              .saveEditedEntry(
                _account,
                original.edit(body: body),
                expectedUpdatedAt: original.updatedAt,
              )
              .then<Object>(
                (entry) => entry!,
                onError: (Object error) => error,
              ),
        );
        final results = await Future.wait(attempts);
        expect(results.whereType<DiaryEntry>(), hasLength(1));
        expect(results.whereType<DiaryEditConflict>(), hasLength(1));
        expect(
          (await storage.readAll(_account))[other.date]!.body,
          'other date',
        );
        expect(
          (await storage.readEntry('another-account', _date)).body,
          'another account',
        );
      },
    );

    test(
      'absence, deletion and strictly advancing committed versions',
      () async {
        final draft = DiaryEntry.empty(_date).edit(body: 'first');
        final created = (await storage.saveEditedEntry(
          _account,
          draft,
          expectedUpdatedAt: null,
        ))!;
        await expectLater(
          storage.saveEditedEntry(
            _account,
            draft.edit(body: 'stale new'),
            expectedUpdatedAt: null,
          ),
          throwsA(isA<DiaryEditConflict>()),
        );
        final future = DiaryEntry.fromJson({
          ...created.toJson(),
          'updatedAt': DateTime.utc(2030).toIso8601String(),
        });
        await storage.save(_account, future);
        final next = (await storage.saveEditedEntry(
          _account,
          future.edit(body: 'next'),
          expectedUpdatedAt: future.updatedAt,
        ))!;
        expect(next.updatedAt.isAfter(future.updatedAt), true);
        await _aiEdit(storage, 'AI after next');
        expect(
          (await storage.readEntry(
            _account,
            _date,
          )).updatedAt.isAfter(next.updatedAt),
          true,
        );
        await expectLater(
          storage.saveEditedEntry(
            _account,
            next.edit(body: ''),
            expectedUpdatedAt: next.updatedAt,
          ),
          throwsA(isA<DiaryEditConflict>()),
        );
        final latest = await storage.readEntry(_account, _date);
        expect(
          await storage.saveEditedEntry(
            _account,
            latest.edit(body: ''),
            expectedUpdatedAt: latest.updatedAt,
          ),
          null,
        );
        expect((await storage.readAll(_account)), isEmpty);
        await storage.saveEditedEntry(_account, draft, expectedUpdatedAt: null);
      },
    );

    test(
      'conflict drafts survive reload without replacing diary, with account isolation',
      () async {
        final original = DiaryEntry.empty(
          _date,
        ).edit(title: 'title', body: 'original');
        await storage.save(_account, original);
        await _aiEdit(storage, 'AI latest');
        final draft = original.edit(body: 'user draft');
        await storage.saveDraft(
          _account,
          draft,
          expectedUpdatedAt: original.updatedAt,
        );
        final reloaded = DiaryStorage(
          directory: directory,
          migrateLegacy: false,
        );
        final savedDraft = await reloaded.readDraft(_account, _date);
        expect(savedDraft!.entry.body, 'user draft');
        expect(savedDraft.expectedUpdatedAt, original.updatedAt);
        expect((await reloaded.readEntry(_account, _date)).body, 'AI latest');
        expect(await reloaded.readDraft('another-account', _date), null);
        await reloaded.clearDraft(_account, _date);
        expect(await reloaded.readDraft(_account, _date), null);
      },
    );
    test('damaged draft recovers the previous atomic snapshot', () async {
      final draft = DiaryEntry.empty(_date).edit(body: 'previous draft');
      await storage.saveDraft(_account, draft, expectedUpdatedAt: null);
      await storage.saveDraft(
        _account,
        draft.edit(body: 'next draft'),
        expectedUpdatedAt: null,
      );
      final file = await directory
          .list(recursive: true)
          .where(
            (entity) =>
                entity is File && entity.path.endsWith('2026-10-06.json'),
          )
          .cast<File>()
          .single;
      await file.writeAsString('damaged');
      expect(
        (await storage.readDraft(_account, _date))!.entry.body,
        'previous draft',
      );
      await storage.clearDraft(_account, _date);
      expect(await storage.readDraft(_account, _date), null);
    });
  });

  for (final size in [const Size(390, 844), const Size(1200, 900)]) {
    testWidgets('AI update preserves editor draft and recovery at $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final storage = _MemoryDiary();
      storage.entries[diaryDateKey(_date)] = DiaryEntry.empty(
        _date,
      ).edit(body: 'original');
      await _pumpPage(tester, storage);
      await _edit(tester, 'user draft');
      await _aiEdit(storage, 'AI latest');
      await _autosave(tester);
      expect(storage.entries[diaryDateKey(_date)]!.body, 'AI latest');
      expect(
        tester.widget<TextField>(find.byType(TextField).last).controller!.text,
        'user draft',
      );
      expect(find.text('日记已更新，草稿已保留'), findsOneWidget);
      expect(storage.drafts[diaryDateKey(_date)]!.entry.body, 'user draft');
      String? clipboard;
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          clipboard = (call.arguments as Map)['text'] as String;
        }
        return null;
      });
      addTearDown(
        () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
      );
      await _tap(tester, '复制草稿');
      expect(clipboard, 'user draft');
      await _tap(tester, '重新载入');
      expect(
        tester.widget<TextField>(find.byType(TextField).last).controller!.text,
        'AI latest',
      );
      expect(find.text('有保留的草稿'), findsOneWidget);
      await _tap(tester, '恢复草稿');
      expect(
        tester.widget<TextField>(find.byType(TextField).last).controller!.text,
        'user draft',
      );
      expect(storage.entries[diaryDateKey(_date)]!.body, 'AI latest');
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      expect(tester.takeException(), null);
    });
  }

  testWidgets(
    'dispose before autosave uses CAS and keeps a recoverable draft',
    (tester) async {
      final storage = _MemoryDiary();
      await _pumpPage(tester, storage);
      await _edit(tester, 'new entry draft');
      await _aiEdit(storage, 'AI newly created');
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      expect(storage.entries[diaryDateKey(_date)]!.body, 'AI newly created');
      expect(
        storage.drafts[diaryDateKey(_date)]!.entry.body,
        'new entry draft',
      );
      await _pumpPage(tester, storage);
      expect(find.text('有保留的草稿'), findsOneWidget);
      await _tap(tester, '恢复草稿');
      expect(
        tester.widget<TextField>(find.byType(TextField).last).controller!.text,
        'new entry draft',
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      expect(tester.takeException(), null);
    },
  );

  testWidgets('queued autosaves follow the last committed version', (
    tester,
  ) async {
    final storage = _MemoryDiary();
    await _pumpPage(tester, storage);
    final gate = storage.nextWrite = Completer<void>();
    final started = storage.writeStarted = Completer<void>();
    await _edit(tester, 'first revision');
    await _autosave(tester);
    expect(started.isCompleted, true);
    await _edit(tester, 'second revision');
    await _autosave(tester);
    gate.complete();
    await tester.pumpAndSettle();
    expect(storage.entries[diaryDateKey(_date)]!.body, 'second revision');
    expect(find.text('日记已更新，草稿已保留'), findsNothing);
    expect(find.text('已保存'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('AI update between queued autosaves is retained', (tester) async {
    final storage = _MemoryDiary();
    await _pumpPage(tester, storage);
    final gate = storage.nextWrite = Completer<void>();
    await _edit(tester, 'first revision');
    await _autosave(tester);
    final aiUpdate = _aiEdit(storage, 'AI between saves');
    await _edit(tester, 'second revision');
    await _autosave(tester);
    gate.complete();
    await tester.pumpAndSettle();
    await aiUpdate;
    expect(storage.entries[diaryDateKey(_date)]!.body, 'AI between saves');
    expect(storage.drafts[diaryDateKey(_date)]!.entry.body, 'second revision');
    expect(find.text('日记已更新，草稿已保留'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets(
    'conflict permits date switch and back without losing the draft',
    (tester) async {
      final storage = _MemoryDiary();
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigator,
          theme: EcjtuTheme.light,
          home: const Scaffold(body: Text('calendar fixture')),
        ),
      );
      final route = navigator.currentState!.push<bool>(
        MaterialPageRoute(
          builder: (_) => DiaryPage(
            account: _account,
            initialDate: _date,
            storage: storage,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _edit(tester, 'user draft');
      await _aiEdit(storage, 'AI latest');
      await _autosave(tester);
      await _tap(tester, '后一天');
      await _edit(tester, 'next day');
      await _tap(tester, '前一天');
      expect(storage.entries['2026-10-07']!.body, 'next day');
      expect(
        tester.widget<TextField>(find.byType(TextField).last).controller!.text,
        'AI latest',
      );
      await _tap(tester, '恢复草稿');
      await _edit(tester, 'user draft continued');
      await _tap(tester, '返回日历');
      expect(await route, true);
      expect(find.text('calendar fixture'), findsOneWidget);
      expect(storage.entries[diaryDateKey(_date)]!.body, 'AI latest');
      expect(
        storage.drafts[diaryDateKey(_date)]!.entry.body,
        'user draft continued',
      );
    },
  );

  testWidgets('explicit draft save rechecks changes made during confirmation', (
    tester,
  ) async {
    final storage = _MemoryDiary();
    await _pumpPage(tester, storage);
    await _edit(tester, 'user draft');
    await _aiEdit(storage, 'AI first');
    await _autosave(tester);
    await _tap(tester, '保存草稿');
    expect(find.text('将当前草稿替换 2026-10-06 的日记内容？'), findsOneWidget);
    await _aiEdit(storage, 'AI during confirmation');
    await _tap(tester, '保存草稿');
    expect(
      storage.entries[diaryDateKey(_date)]!.body,
      'AI during confirmation',
    );
    expect(find.text('日记已更新，草稿已保留'), findsOneWidget);
    await _tap(tester, '保存草稿');
    await _tap(tester, '保存草稿');
    expect(storage.entries[diaryDateKey(_date)]!.body, 'user draft');
    expect(storage.drafts, isEmpty);
    await _edit(tester, 'user later revision');
    await _autosave(tester);
    expect(storage.entries[diaryDateKey(_date)]!.body, 'user later revision');
    expect(find.text('日记已更新，草稿已保留'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets(
    'restored draft can be edited, saved and followed by normal date changes',
    (tester) async {
      final storage = _MemoryDiary();
      await _pumpPage(tester, storage);
      await _edit(tester, 'original draft');
      await _aiEdit(storage, 'AI latest');
      await _autosave(tester);
      await _tap(tester, '重新载入');
      await _tap(tester, '恢复草稿');
      await _edit(tester, 'restored draft edited');
      await _autosave(tester);
      expect(storage.entries[diaryDateKey(_date)]!.body, 'AI latest');
      expect(
        storage.drafts[diaryDateKey(_date)]!.entry.body,
        'restored draft edited',
      );
      await _tap(tester, '保存草稿');
      await _tap(tester, '保存草稿');
      expect(
        storage.entries[diaryDateKey(_date)]!.body,
        'restored draft edited',
      );
      expect(storage.drafts, isEmpty);
      await _tap(tester, '后一天');
      await _edit(tester, 'next day normal');
      await _tap(tester, '前一天');
      expect(storage.entries['2026-10-07']!.body, 'next day normal');
      expect(
        tester.widget<TextField>(find.byType(TextField).last).controller!.text,
        'restored draft edited',
      );
      await _edit(tester, 'saved during dispose');
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      expect(
        storage.entries[diaryDateKey(_date)]!.body,
        'saved during dispose',
      );
      expect(storage.drafts, isEmpty);
      expect(tester.takeException(), null);
    },
  );

  testWidgets('queued dispose save retains an intervening AI edit', (
    tester,
  ) async {
    final storage = _MemoryDiary();
    await _pumpPage(tester, storage);
    final gate = storage.nextWrite = Completer<void>();
    await _edit(tester, 'first revision');
    await _autosave(tester);
    final ai = _aiEdit(storage, 'AI before dispose');
    await _edit(tester, 'dispose revision');
    await tester.pumpWidget(const SizedBox());
    gate.complete();
    await tester.pumpAndSettle();
    await ai;
    expect(storage.entries[diaryDateKey(_date)]!.body, 'AI before dispose');
    expect(storage.drafts[diaryDateKey(_date)]!.entry.body, 'dispose revision');
    expect(tester.takeException(), null);
  });

  testWidgets('draft write failure still permits copying and returning', (
    tester,
  ) async {
    final storage = _MemoryDiary();
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        theme: EcjtuTheme.light,
        home: const Scaffold(body: Text('calendar fixture')),
      ),
    );
    final route = navigator.currentState!.push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            DiaryPage(account: _account, initialDate: _date, storage: storage),
      ),
    );
    await tester.pumpAndSettle();
    await _edit(tester, 'copy before leaving');
    await _aiEdit(storage, 'AI latest');
    storage.failDraft = true;
    await _autosave(tester);
    await _tap(tester, '返回日历');
    expect(find.text('草稿尚未保存'), findsOneWidget);
    String? clipboard;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        clipboard = (call.arguments as Map)['text'] as String;
      }
      return null;
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
    );
    await _tap(tester, '复制并返回');
    expect(await route, true);
    expect(clipboard, 'copy before leaving');
    expect(storage.entries[diaryDateKey(_date)]!.body, 'AI latest');
    expect(find.text('calendar fixture'), findsOneWidget);
    expect(tester.takeException(), null);
  });
}
