// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/ecjtu_theme.dart';

class EcjtuIconPictures {
  static final _pictures = <String, PictureInfo>{};
  static final _pending = <String, Future<PictureInfo>>{};
  static Future<void>? _preparation;
  static Future<void>? _aiPreparation;
  static String pathOf(String name) =>
      'packages/ecjtu_tools_core/assets/icons/${name.endsWith('.svg') ? name : '$name.svg'}';
  static PictureInfo? read(String name) => _pictures[pathOf(name)];
  static Future<PictureInfo> load(String name) => _loadPath(pathOf(name));
  static Future<PictureInfo> _loadPath(String path) {
    final ready = _pictures[path];
    if (ready != null) return Future.value(ready);
    return _pending.putIfAbsent(path, () async {
      try {
        final picture = await vg.loadPicture(SvgAssetLoader(path), null);
        _pictures[path] = picture;
        return picture;
      } finally {
        _pending.remove(path);
      }
    });
  }

  static Future<void> prepare() => _preparation ??= _prepare();
  static Future<void> prepareAi() =>
      _aiPreparation ??= _prepare(ai: true).catchError((Object error) {
        _aiPreparation = null;
        throw error;
      });
  static Future<void> _prepare({bool ai = false}) async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final paths = manifest
        .listAssets()
        .where(
          (path) =>
              path.startsWith('packages/ecjtu_tools_core/assets/icons/') &&
              path.endsWith('.svg') &&
              path.split('/').last.startsWith('ai_phosphor_') == ai,
        )
        .toList();
    var next = 0;
    Future<void> worker() async {
      while (next < paths.length) {
        final path = paths[next++];
        await _loadPath(path);
        if (ai) await Future<void>.delayed(Duration.zero);
      }
    }

    await Future.wait(List.generate(ai ? 2 : 6, (_) => worker()));
  }
}

class EcjtuIcon extends StatelessWidget {
  const EcjtuIcon(this.name, {super.key, this.size = 24, this.color});

  final String name;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final color =
        this.color ??
        (EcjtuMetrics.phoneLayout(context)
            ? EcjtuColors.smartWorkIcon
            : Theme.of(context).colorScheme.primary);
    Widget picture(PictureInfo info) => Semantics(
      label: name,
      child: ColorFiltered(
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        child: CustomPaint(
          painter: _IconPicturePainter(info),
          size: Size.square(size),
        ),
      ),
    );
    final ready = EcjtuIconPictures.read(name);
    return SizedBox.square(
      dimension: size,
      child: ready != null
          ? picture(ready)
          : FutureBuilder<PictureInfo>(
              future: EcjtuIconPictures.load(name),
              builder: (context, snapshot) => snapshot.hasData
                  ? picture(snapshot.data!)
                  : const SizedBox.expand(),
            ),
    );
  }
}

class _IconPicturePainter extends CustomPainter {
  const _IconPicturePainter(this.info);
  final PictureInfo info;
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / info.size.width < size.height / info.size.height
        ? size.width / info.size.width
        : size.height / info.size.height;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.translate(
      (size.width - info.size.width * scale) / 2,
      (size.height - info.size.height * scale) / 2,
    );
    canvas.scale(scale);
    canvas.drawPicture(info.picture);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_IconPicturePainter oldDelegate) =>
      oldDelegate.info != info;
}

class EcjtuBackGlyph extends StatelessWidget {
  const EcjtuBackGlyph({super.key, this.size = 18, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _BackGlyphPainter(
        color ??
            (Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : EcjtuColors.textPrimary),
      ),
    );
  }
}

class EcjtuVisibilityGlyph extends StatelessWidget {
  const EcjtuVisibilityGlyph({
    super.key,
    required this.visible,
    this.size = 17,
    this.color,
  });

  final bool visible;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size * .72),
      painter: _VisibilityGlyphPainter(
        visible: visible,
        color:
            color ??
            (EcjtuMetrics.phoneLayout(context)
                ? EcjtuColors.smartWorkIcon
                : Theme.of(context).colorScheme.primary),
      ),
    );
  }
}

class EcjtuChevronGlyph extends StatelessWidget {
  const EcjtuChevronGlyph({super.key, this.size = 8, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _ChevronGlyphPainter(color ?? (EcjtuColors.mutedFor(context))),
    );
  }
}

class _BackGlyphPainter extends CustomPainter {
  const _BackGlyphPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * .11
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path()
      ..moveTo(size.width * .7, size.height * .18)
      ..lineTo(size.width * .27, size.height * .5)
      ..lineTo(size.width * .7, size.height * .82);
    canvas.drawPath(path, paint);
    canvas.drawLine(
      Offset(size.width * .29, size.height * .5),
      Offset(size.width * .88, size.height * .5),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _BackGlyphPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _VisibilityGlyphPainter extends CustomPainter {
  const _VisibilityGlyphPainter({required this.visible, required this.color});

  final bool visible;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final outline = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * .094
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final eye = Path()
      ..moveTo(size.width * .06, size.height * .5)
      ..cubicTo(
        size.width * .27,
        size.height * -.08,
        size.width * .73,
        size.height * -.08,
        size.width * .94,
        size.height * .5,
      )
      ..cubicTo(
        size.width * .73,
        size.height * 1.08,
        size.width * .27,
        size.height * 1.08,
        size.width * .06,
        size.height * .5,
      );
    canvas.drawPath(eye, outline);
    canvas.drawCircle(
      Offset(size.width * .5, size.height * .5),
      size.width * .12,
      Paint()..color = color,
    );
    if (visible) {
      canvas.drawLine(
        Offset(size.width * .02, size.height * .08),
        Offset(size.width * .98, size.height * .92),
        outline,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _VisibilityGlyphPainter oldDelegate) {
    return oldDelegate.visible != visible || oldDelegate.color != color;
  }
}

class _ChevronGlyphPainter extends CustomPainter {
  const _ChevronGlyphPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * .19
      ..strokeCap = StrokeCap.square
      ..strokeJoin = StrokeJoin.miter;
    final path = Path()
      ..moveTo(size.width * .12, size.height * .28)
      ..lineTo(size.width * .5, size.height * .72)
      ..lineTo(size.width * .88, size.height * .28);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ChevronGlyphPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
