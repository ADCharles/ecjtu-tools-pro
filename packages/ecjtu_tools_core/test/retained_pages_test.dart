// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'package:ecjtu_tools_core/widgets/ecjtu_retained_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'hidden pages keep their viewport without resize rebuilds or layouts',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1200, 800);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final active = ValueNotifier('first');
      addTearDown(active.dispose);
      final builds = <String, int>{};
      final layouts = <String, int>{};
      final widths = <String, double>{};
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValueListenableBuilder(
              valueListenable: active,
              builder: (_, value, _) => EcjtuRetainedPages(
                activePage: value,
                pageBuilder: (page) => Builder(
                  builder: (context) {
                    builds.update(page, (n) => n + 1, ifAbsent: () => 1);
                    MediaQuery.sizeOf(context);
                    return LayoutBuilder(
                      builder: (_, constraints) {
                        layouts.update(page, (n) => n + 1, ifAbsent: () => 1);
                        widths[page] = constraints.maxWidth;
                        return const SizedBox.expand();
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      active.value = 'second';
      await tester.pump();
      final hiddenBuilds = builds['first'];
      final hiddenLayouts = layouts['first'];
      for (final width in [1180.0, 1050.0, 900.0, 800.0]) {
        tester.view.physicalSize = Size(width, 800);
        await tester.pump();
        expect(builds['first'], hiddenBuilds);
        expect(layouts['first'], hiddenLayouts);
        expect(widths['second'], width);
      }
      active.value = 'first';
      await tester.pump();
      expect(widths['first'], 800);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'pages keep editing and scroll state, exclude hidden focus and reset per account',
    (tester) async {
      final active = ValueNotifier('first');
      final account = ValueNotifier('one');
      addTearDown(active.dispose);
      addTearDown(account.dispose);
      final created = <String, int>{};
      final disposed = <String, int>{};
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListenableBuilder(
              listenable: Listenable.merge([active, account]),
              builder: (_, _) => EcjtuRetainedPages(
                key: ValueKey(account.value),
                activePage: active.value,
                pageBuilder: (page) => _ProbePage(
                  page: page,
                  created: created,
                  disposed: disposed,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(created, {'first': 1});
      await tester.enterText(find.byType(TextField), '保留输入');
      final state = tester.state<_ProbePageState>(find.byType(_ProbePage));
      state.focus.unfocus();
      await tester.pumpAndSettle();
      state.scroll.jumpTo(240);
      await tester.pump();
      active.value = 'second';
      await tester.pumpAndSettle();
      expect(created, {'first': 1, 'second': 1});
      expect(state.focus.hasFocus, isFalse);
      state.focus.requestFocus();
      await tester.pump();
      expect(state.focus.hasFocus, isFalse);
      active.value = 'first';
      await tester.pumpAndSettle();
      expect(state.text.text, '保留输入');
      expect(state.scroll.offset, 240);
      expect(created['first'], 1);
      account.value = 'two';
      await tester.pumpAndSettle();
      expect(disposed, {'first': 1, 'second': 1});
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '',
      );
      expect(created['first'], 2);
    },
  );
}

class _ProbePage extends StatefulWidget {
  const _ProbePage({
    required this.page,
    required this.created,
    required this.disposed,
  });
  final String page;
  final Map<String, int> created, disposed;
  @override
  State<_ProbePage> createState() => _ProbePageState();
}

class _ProbePageState extends State<_ProbePage> {
  final text = TextEditingController();
  final focus = FocusNode();
  final scroll = ScrollController();
  @override
  void initState() {
    super.initState();
    widget.created.update(widget.page, (count) => count + 1, ifAbsent: () => 1);
  }

  @override
  void dispose() {
    widget.disposed.update(
      widget.page,
      (count) => count + 1,
      ifAbsent: () => 1,
    );
    text.dispose();
    focus.dispose();
    scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListView(
    controller: scroll,
    children: [
      TextField(controller: text, focusNode: focus),
      const SizedBox(height: 1500),
    ],
  );
}
