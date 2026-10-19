// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:ecjtu_tools_core/features/calendar/diary_models.dart';
import 'package:ecjtu_tools_core/features/calendar/diary_storage.dart';
import 'package:ecjtu_tools_core/features/calendar/diary_backup.dart';
import 'package:ecjtu_tools_core/features/calendar/calendar_notes_storage.dart';
import 'package:ecjtu_tools_core/features/settings/local_cache_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final picture = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+a3foAAAAASUVORK5CYII=',
  );
  late Directory directory;
  late DiaryStorage storage;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('ecjtu-diary-test-');
    storage = DiaryStorage(directory: directory, migrateLegacy: false);
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => directory.path,
        );
  });
  tearDown(() async {
    // Only the unique test-owned temporary directory is removed.
    await directory.delete(recursive: true);
  });
  test('Markdown first heading, all levels, fenced code and Setext', () {
    for (var level = 1; level <= 6; level++) {
      final body =
          '前言\n\n```md\n# 示例\n```\n\n${'#' * level} **我的** [一天](https://example.org)\n# 后面的标题';
      expect(firstDiaryHeading(body)?.title, '我的 一天');
    }
    expect(firstDiaryHeading('# \n## 真标题')?.title, '真标题');
    expect(
      firstDiaryHeading(
        r'$$'
        '\n# 公式内容\n'
        r'$$'
        '\n## 真标题',
      )?.title,
      '真标题',
    );
    expect(
      DiaryEntry.empty(
        DateTime(2026, 10, 6),
      ).edit(title: '手动标题', body: '# 正文标题').displayTitle,
      '手动标题',
    );
    expect(
      DiaryEntry.empty(
        DateTime(2026, 10, 6),
      ).edit(title: '  ', body: '## 正文标题').displayTitle,
      '正文标题',
    );
    expect(firstDiaryHeading('标题\n====\n正文')?.title, '标题');
    expect(firstDiaryHeading('    # 代码\n\n## 真标题')?.title, '真标题');
  });
  test('outer title updates heading without replacing body or image', () async {
    final date = DateTime(2026, 10, 6);
    final image = await storage.addImage('account-a', picture);
    final entry = DiaryEntry.empty(date).edit(
      title: '备用标题',
      body: '开头\n### 原标题\n正文\n![图片](diary-asset:$image)\n尾段',
    );
    await storage.save('account-a', entry);
    await storage.setTitle('account-a', entry.date, '改后的标题');
    final saved = await storage.readEntry('account-a', date);
    expect(saved.displayTitle, '改后的标题');
    expect(saved.body, contains('正文\n![图片]'));
    expect(saved.body, endsWith('尾段'));
    final literal = entry.withOuterTitle(r'星号*下划线_ [链接](地址) # 和反斜线\');
    expect(literal.displayTitle, r'星号*下划线_ [链接](地址) # 和反斜线\');
    expect((await storage.readAll('account-b')), isEmpty);
  });
  test(
    'queued title writes survive reload and remain scoped per date',
    () async {
      await Future.wait([
        storage.setTitle('account', '2026-10-06', '第一天'),
        storage.setTitle('account', '2026-10-07', '第二天'),
        storage.setTitle('account', '2026-10-06', '第一天修改'),
      ]);
      final reloaded = DiaryStorage(directory: directory, migrateLegacy: false);
      final data = await reloaded.readAll('account');
      expect(data['2026-10-06']?.title, '第一天修改');
      expect(data['2026-10-07']?.title, '第二天');
    },
  );
  test(
    'legacy migration retains titles and is not affected by cache clearing',
    () async {
      SharedPreferences.setMockInitialValues({
        'ecjtu.calendar.daily_notes.account': jsonEncode({
          '2026-10-06': '原来的一句话',
        }),
      });
      final migrating = DiaryStorage(directory: directory);
      final notes = CalendarNotesStorage(diary: migrating);
      expect((await notes.read('account'))['2026-10-06'], '原来的一句话');
      await LocalCacheManager().clearCache();
      expect((await notes.read('account'))['2026-10-06'], '原来的一句话');
      expect(
        (await SharedPreferences.getInstance()).containsKey(
          'ecjtu.calendar.daily_notes.account',
        ),
        isTrue,
      );
    },
  );
  test(
    'encrypted portable backup round trip, authentication and merge policy',
    () async {
      final image = await storage.addImage('desktop', picture);
      final entry = DiaryEntry.empty(DateTime(2026, 10, 6)).edit(
        body: '#### 一天\n\n前段\n\n![图](diary-asset:$image)\n\n后段',
        imageWidths: {image: .65},
      );
      await storage.save('desktop', entry);
      final data = DiaryBackupData([entry], {image: picture});
      final encrypted = DiaryBackup.encrypt(data, 'my-test-password');
      expect(utf8.decode(encrypted), isNot(contains('前段')));
      final decoded = DiaryBackup.decrypt(encrypted, 'my-test-password');
      await DiaryBackup.restore(storage, 'android', decoded);
      expect(
        (await storage.readEntry('android', DateTime(2026, 10, 6))).toJson(),
        entry.toJson(),
      );
      expect(
        await (await storage.assetFile('android', image)).readAsBytes(),
        picture,
      );
      expect(
        () => DiaryBackup.decrypt(encrypted, 'wrong-password'),
        throwsFormatException,
      );
      final envelope =
          jsonDecode(utf8.decode(encrypted)) as Map<String, dynamic>;
      final ciphertext = base64Decode(envelope['ciphertext'] as String);
      ciphertext[0] ^= 1;
      envelope['ciphertext'] = base64Encode(ciphertext);
      expect(
        () => DiaryBackup.decrypt(
          Uint8List.fromList(utf8.encode(jsonEncode(envelope))),
          'my-test-password',
        ),
        throwsFormatException,
      );
      await storage.setTitle('android', entry.date, '本机标题');
      await DiaryBackup.restore(storage, 'android', decoded);
      expect(
        (await storage.readEntry(
          'android',
          DateTime(2026, 10, 6),
        )).displayTitle,
        '本机标题',
      );
      await DiaryBackup.restore(
        storage,
        'android',
        decoded,
        replaceExisting: true,
      );
      expect(
        (await storage.readEntry(
          'android',
          DateTime(2026, 10, 6),
        )).displayTitle,
        '一天',
      );
    },
  );
  test('invalid dates and asset paths are rejected', () async {
    expect(() => diaryDate('2026-02-30'), throwsFormatException);
    await expectLater(
      storage.assetFile('account', '../../outside'),
      throwsFormatException,
    );
    await expectLater(
      storage.addImage('account', Uint8List.fromList([1, 2, 3])),
      throwsFormatException,
    );
  });
  test(
    'rendering scale is portable, backwards compatible and account scoped',
    () async {
      final entry = DiaryEntry.empty(
        DateTime(2026, 10, 6),
      ).edit(body: '正文', renderScale: 1.35);
      await storage.save('desktop', entry);
      await storage.setRenderScale('desktop', 1.35);
      final bytes = await DiaryBackup.export(storage, 'desktop', '123456');
      final data = await DiaryBackup.open(bytes, '123456');
      expect(data.renderScale, 1.35);
      await DiaryBackup.restore(storage, 'android', data);
      expect(
        (await storage.readEntry('android', DateTime(2026, 10, 6))).renderScale,
        1.35,
      );
      expect(await storage.readRenderScale('android'), 1.35);
      expect(await storage.readRenderScale('other'), 1);
      final legacy = entry.toJson()..remove('renderScale');
      expect(DiaryEntry.fromJson(legacy).renderScale, 1);
      expect(
        () => DiaryEntry.fromJson({...entry.toJson(), 'renderScale': 9}),
        throwsFormatException,
      );
      expect(
        () => DiaryBackup.encrypt(DiaryBackupData([], {}), ''),
        throwsFormatException,
      );
    },
  );
  test('previous journal recovers an interrupted or corrupt write', () async {
    final entry = DiaryEntry.empty(DateTime(2026, 10, 6)).edit(title: '保留的日记');
    await storage.save('account', entry);
    await storage.save('account', entry.edit(title: '新日记'));
    final file =
        (await directory
                    .list(recursive: true)
                    .where((file) => file.path.endsWith('entries.json'))
                    .toList())
                .single
            as File;
    await file.writeAsString('{incomplete');
    expect(
      (await storage.readEntry('account', DateTime(2026, 10, 6))).title,
      '保留的日记',
    );
  });
}
