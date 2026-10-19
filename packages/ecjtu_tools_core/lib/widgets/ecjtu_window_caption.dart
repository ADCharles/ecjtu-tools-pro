// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:async';
import 'package:window_manager/window_manager.dart';
import 'package:flutter/material.dart';

enum WindowCaptionGlyph { pin, minimize, maximize, restore, close }

class EcjtuWindowCaptionButton extends StatefulWidget {
  const EcjtuWindowCaptionButton({
    super.key,
    required this.glyph,
    required this.onPressed,
    this.closeButton = false,
    this.pressed = false,
    this.color = Colors.white,
    this.height = 32,
    this.trackMainWindow = false,
  });

  final WindowCaptionGlyph glyph;
  final VoidCallback onPressed;
  final bool closeButton;
  final bool pressed;
  final Color color;
  final double height;
  final bool trackMainWindow;

  @override
  State<EcjtuWindowCaptionButton> createState() =>
      EcjtuWindowCaptionButtonState();
}

class EcjtuWindowCaptionButtonState extends State<EcjtuWindowCaptionButton>
    with WindowListener {
  bool _hovered = false;
  bool _maximized = false;

  @override
  void initState() {
    super.initState();
    if (widget.trackMainWindow) {
      windowManager.addListener(this);
      unawaited(
        windowManager.isMaximized().then((value) {
          if (mounted) setState(() => _maximized = value);
        }),
      );
    }
  }

  @override
  void onWindowMaximize() => setState(() => _maximized = true);

  @override
  void onWindowUnmaximize() => setState(() => _maximized = false);

  @override
  void dispose() {
    if (widget.trackMainWindow) windowManager.removeListener(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final glyph = widget.glyph == WindowCaptionGlyph.maximize && _maximized
        ? WindowCaptionGlyph.restore
        : widget.glyph;
    final label = switch (glyph) {
      WindowCaptionGlyph.pin => '窗口置顶',
      WindowCaptionGlyph.minimize => '最小化',
      WindowCaptionGlyph.maximize => '最大化',
      WindowCaptionGlyph.restore => '还原',
      WindowCaptionGlyph.close => '关闭',
    };
    final hoverColor = widget.closeButton
        ? const Color(0xFFE81123)
        : widget.color.withValues(alpha: 0.12);
    return Semantics(
      label: label,
      button: true,
      toggled: widget.glyph == WindowCaptionGlyph.pin ? widget.pressed : null,
      child: Tooltip(
        message: label,
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: InkWell(
            splashFactory: NoSplash.splashFactory,
            hoverColor: Colors.transparent,
            onTap: widget.onPressed,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 90),
              width: 43,
              height: widget.height,
              color: _hovered || widget.pressed
                  ? hoverColor
                  : Colors.transparent,
              alignment: Alignment.center,
              child: widget.glyph == WindowCaptionGlyph.pin
                  ? Icon(
                      widget.pressed ? Icons.push_pin : Icons.push_pin_outlined,
                      color: widget.color,
                      size: 15,
                    )
                  : CustomPaint(
                      size: const Size(10, 10),
                      painter: WindowCaptionGlyphPainter(
                        glyph,
                        color: _hovered && widget.closeButton
                            ? Colors.white
                            : widget.color,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class WindowCaptionGlyphPainter extends CustomPainter {
  const WindowCaptionGlyphPainter(this.glyph, {this.color = Colors.white});

  final WindowCaptionGlyph glyph;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.15
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;
    switch (glyph) {
      case WindowCaptionGlyph.pin:
        break;
      case WindowCaptionGlyph.minimize:
        canvas.drawLine(
          Offset(1, size.height - 2),
          Offset(size.width - 1, size.height - 2),
          paint,
        );
      case WindowCaptionGlyph.maximize:
        canvas.drawRect(
          Rect.fromLTWH(1.5, 1.5, size.width - 3, size.height - 3),
          paint,
        );
      case WindowCaptionGlyph.restore:
        canvas.drawPath(
          Path()
            ..moveTo(3.5, 2)
            ..lineTo(8, 2)
            ..lineTo(8, 6.5),
          paint,
        );
        canvas.drawRect(const Rect.fromLTWH(1, 4, 5.5, 5), paint);
      case WindowCaptionGlyph.close:
        canvas.drawLine(
          const Offset(1.5, 1.5),
          Offset(size.width - 1.5, size.height - 1.5),
          paint,
        );
        canvas.drawLine(
          Offset(size.width - 1.5, 1.5),
          Offset(1.5, size.height - 1.5),
          paint,
        );
    }
  }

  @override
  bool shouldRepaint(covariant WindowCaptionGlyphPainter oldDelegate) =>
      oldDelegate.glyph != glyph || oldDelegate.color != color;
}
