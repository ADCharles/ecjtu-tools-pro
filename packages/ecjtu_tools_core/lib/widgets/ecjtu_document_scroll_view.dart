// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'package:flutter/material.dart';

import '../theme/ecjtu_theme.dart';

class EcjtuDocumentScrollView extends StatefulWidget {
  const EcjtuDocumentScrollView({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
  }) : itemBuilder = null,
       itemCount = null;

  const EcjtuDocumentScrollView.builder({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.padding = EdgeInsets.zero,
  }) : child = null;

  final Widget? child;
  final IndexedWidgetBuilder? itemBuilder;
  final int? itemCount;
  final EdgeInsetsGeometry padding;

  @override
  State<EcjtuDocumentScrollView> createState() =>
      _EcjtuDocumentScrollViewState();
}

class _EcjtuDocumentScrollViewState extends State<EcjtuDocumentScrollView> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ScrollConfiguration(
    behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
    child: Builder(
      builder: (context) {
        final content = widget.itemBuilder != null
            ? ListView.builder(
                controller: _scroll,
                primary: false,
                physics: const ClampingScrollPhysics(),
                padding: widget.padding,
                itemCount: widget.itemCount,
                itemBuilder: widget.itemBuilder!,
              )
            : SingleChildScrollView(
                controller: _scroll,
                primary: false,
                physics: const ClampingScrollPhysics(),
                padding: widget.padding,
                child: widget.child,
              );
        final platform = Theme.of(context).platform;
        if (platform == TargetPlatform.android ||
            platform == TargetPlatform.iOS) {
          return ScrollConfiguration(
            behavior: ScrollConfiguration.of(
              context,
            ).copyWith(scrollbars: false),
            child: content,
          );
        }
        return Scrollbar(
          controller: _scroll,
          thumbVisibility: !EcjtuMetrics.phoneLayout(context),
          interactive: true,
          child: content,
        );
      },
    ),
  );
}
