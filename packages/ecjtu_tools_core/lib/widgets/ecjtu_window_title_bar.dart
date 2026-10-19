// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/ecjtu_theme.dart';
import '../theme/ecjtu_glass.dart';
import 'ecjtu_window_caption.dart';

BoxDecoration ecjtuWindowTitleDecoration({
  required bool dark,
  bool gradient = true,
  double extent = 1,
  Color? flatColor,
}) {
  if (!gradient)
    return BoxDecoration(color: flatColor ?? EcjtuColors.loginHeader);
  final span = extent.clamp(.01, 1.0);
  return BoxDecoration(
    gradient: LinearGradient(
      colors: dark
          ? const [
              EcjtuColors.darkHeaderStart,
              EcjtuColors.darkHeaderMiddle,
              EcjtuColors.darkHeaderEnd,
              EcjtuColors.darkHeaderEnd,
            ]
          : const [
              EcjtuColors.headerStart,
              EcjtuColors.headerMiddle,
              EcjtuColors.headerEnd,
              EcjtuColors.headerEnd,
            ],
      stops: [0, span * .5, span, 1],
    ),
  );
}

class EcjtuIndependentWindowFrame extends StatefulWidget {
  const EcjtuIndependentWindowFrame({
    super.key,
    required this.child,
    this.title = 'AI 助手',
    this.maximized = false,
    this.channel = const MethodChannel('ecjtu/windows_close'),
  });
  final Widget child;
  final String title;
  final bool maximized;
  final MethodChannel channel;

  @override
  State<EcjtuIndependentWindowFrame> createState() =>
      _EcjtuIndependentWindowFrameState();
}

class _EcjtuIndependentWindowFrameState
    extends State<EcjtuIndependentWindowFrame> {
  Offset? _down;
  bool _dragging = false;

  Future<void> _invoke(String method) async {
    try {
      await widget.channel.invokeMethod<void>(method);
    } on PlatformException {
    } on MissingPluginException {}
  }

  @override
  Widget build(BuildContext context) => Overlay.wrap(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: EcjtuGlass.of(context).backdrop.first,
          child: SizedBox(
            height: 44,
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onDoubleTap: () =>
                        unawaited(_invoke('toggleMaximizeWindow')),
                    child: Listener(
                      behavior: HitTestBehavior.opaque,
                      onPointerDown: (event) {
                        _down = event.position;
                        _dragging = false;
                      },
                      onPointerMove: (event) {
                        if (_dragging ||
                            _down == null ||
                            event.buttons & 1 == 0 ||
                            (event.position - _down!).distance < 4)
                          return;
                        _dragging = true;
                        unawaited(_invoke('beginDrag'));
                      },
                      onPointerUp: (_) => _down = null,
                      onPointerCancel: (_) => _down = null,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            widget.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'SourceHanSansCN',
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: EcjtuGlass.of(context).chromeText,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                EcjtuWindowCaptionButton(
                  height: 44,
                  color: EcjtuGlass.of(context).chromeText,
                  glyph: WindowCaptionGlyph.minimize,
                  onPressed: () => unawaited(_invoke('minimizeWindow')),
                ),
                EcjtuWindowCaptionButton(
                  height: 44,
                  color: EcjtuGlass.of(context).chromeText,
                  glyph: widget.maximized
                      ? WindowCaptionGlyph.restore
                      : WindowCaptionGlyph.maximize,
                  onPressed: () => unawaited(_invoke('toggleMaximizeWindow')),
                ),
                EcjtuWindowCaptionButton(
                  height: 44,
                  color: EcjtuGlass.of(context).chromeText,
                  glyph: WindowCaptionGlyph.close,
                  closeButton: true,
                  onPressed: () => unawaited(_invoke('requestCloseWindow')),
                ),
              ],
            ),
          ),
        ),
        Expanded(child: widget.child),
      ],
    ),
  );
}
