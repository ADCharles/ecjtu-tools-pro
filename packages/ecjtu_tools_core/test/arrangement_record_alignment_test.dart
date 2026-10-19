// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'package:ecjtu_tools_core/features/arrangement/exam_arrangement_view.dart';
import 'package:ecjtu_tools_core/theme/ecjtu_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final width in [390.0, 844.0, 1200.0]) {
    testWidgets('arrangement timing centers and details stay adjacent $width', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 900);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        MaterialApp(
          theme: EcjtuTheme.light,
          home: const Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: ArrangementRecordRow(
                timing: Text('第7周\n星期四\n3,4节'),
                title: '作业调度',
                subtitle: '操作系统 · 必修课',
                details: Text('教26栋108 · 教26栋609 · 教26栋610 · 教26栋611'),
                meta: '上机 · 第1批 · 舒文豪',
              ),
            ),
          ),
        ),
      );
      final heading = tester.getRect(find.text('作业调度'));
      final meta = tester.getRect(find.text('上机 · 第1批 · 舒文豪'));
      expect(
        tester.getCenter(find.text('第7周\n星期四\n3,4节')).dy,
        closeTo((heading.top + meta.bottom) / 2, 0.1),
      );
      expect(
        tester.getRect(find.text('教26栋108 · 教26栋609 · 教26栋610 · 教26栋611')).top,
        closeTo(tester.getRect(find.text('操作系统 · 必修课')).bottom, 0.1),
      );
      expect(tester.takeException(), isNull);
      expect(
        meta.top,
        closeTo(
          tester
              .getRect(find.text('教26栋108 · 教26栋609 · 教26栋610 · 教26栋611'))
              .bottom,
          0.1,
        ),
      );
    });
  }
}
