// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'package:flutter/material.dart';

class EcjtuPaneSurface extends StatefulWidget {
  const EcjtuPaneSurface({super.key, required this.child, this.contentKey});
  final Widget child;
  final GlobalKey? contentKey;

  @override
  State<EcjtuPaneSurface> createState() => _EcjtuPaneSurfaceState();
}

class _EcjtuPaneSurfaceState extends State<EcjtuPaneSurface> {
  late final _child = ValueNotifier(widget.child);
  final _navigator = GlobalKey<NavigatorState>();

  @override
  void didUpdateWidget(EcjtuPaneSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    _child.value = widget.child;
  }

  @override
  void dispose() {
    _child.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => TickerMode(
      enabled: ModalRoute.isCurrentOf(context) ?? true,
      child: ClipRect(
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(size: constraints.biggest),
          child: EcjtuPaneDialogScope(
            child: NavigatorPopHandler<Object?>(
              onPopWithResult: (result) {
                // A root route can handle back through PopScope without having
                // a second route. pop() would remove that root unconditionally.
                _navigator.currentState?.maybePop(result);
              },
              child: Navigator(
                key: _navigator,
                onGenerateRoute: (_) => PageRouteBuilder<void>(
                  transitionDuration: Duration.zero,
                  reverseTransitionDuration: Duration.zero,
                  pageBuilder: (_, _, _) => Builder(
                    key: widget.contentKey,
                    builder: (_) => ValueListenableBuilder<Widget>(
                      valueListenable: _child,
                      builder: (_, child, _) => child,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class EcjtuPaneDialogScope extends InheritedWidget {
  const EcjtuPaneDialogScope({super.key, required super.child});

  static bool contains(BuildContext context) =>
      context.getInheritedWidgetOfExactType<EcjtuPaneDialogScope>() != null;

  @override
  bool updateShouldNotify(EcjtuPaneDialogScope oldWidget) => false;
}
