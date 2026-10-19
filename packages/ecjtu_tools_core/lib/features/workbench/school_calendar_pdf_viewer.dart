// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'package:ecjtu_tools_core/widgets/ecjtu_text_context_menu.dart';

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../../theme/ecjtu_theme.dart';
import 'notices_calendar_models.dart';

class SchoolCalendarPdfViewer extends StatefulWidget {
  const SchoolCalendarPdfViewer({
    super.key,
    required this.pdf,
    required this.compact,
  });

  final SchoolCalendarFile pdf;
  final bool compact;

  @override
  State<SchoolCalendarPdfViewer> createState() =>
      _SchoolCalendarPdfViewerState();
}

class _SchoolCalendarPdfViewerState extends State<SchoolCalendarPdfViewer>
    with SingleTickerProviderStateMixin {
  static const _minScale = 0.2;
  static const _maxScale = 8.0;

  late final TextEditingController _zoomController;
  double _scale = 1;
  int _resetRevision = 0;
  final _transform = TransformationController();
  late final AnimationController _zoomAnimation;
  Animation<Matrix4>? _zoomTween;

  @override
  void initState() {
    super.initState();
    _zoomController = TextEditingController(text: '100');
    _zoomAnimation =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 180),
        )..addListener(() {
          final tween = _zoomTween;
          if (tween != null) _transform.value = tween.value;
        });
  }

  @override
  void didUpdateWidget(covariant SchoolCalendarPdfViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pdf.academicYear != widget.pdf.academicYear) {
      _zoomAnimation.stop();
      _transform.value = Matrix4.identity();
      _scale = 1;
      _syncZoomText();
    }
  }

  @override
  void dispose() {
    _zoomAnimation.dispose();
    _transform.dispose();
    _zoomController.dispose();
    super.dispose();
  }

  Future<Uint8List> _buildDocument(PdfPageFormat _) async => widget.pdf.bytes;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    const rasterDpi = 320.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: ColoredBox(
        color: EcjtuColors.surfaceFrom(
          context,
          dark ? const Color(0xFF0A111E) : const Color(0xFFDFE8EF),
        ),
        child: Column(
          children: [
            _buildToolbar(dark),
            Expanded(
              child: PdfPreview.builder(
                key: ValueKey(widget.pdf.academicYear),
                build: _buildDocument,
                dpi: rasterDpi,
                shouldRepaint: false,
                allowPrinting: false,
                allowSharing: false,
                canChangePageFormat: false,
                canChangeOrientation: false,
                canDebug: false,
                useActions: false,
                maxPageWidth: 1460,
                pdfFileName: widget.pdf.fileName,
                padding: EdgeInsets.zero,
                loadingWidget: _PdfStatus(message: '正在准备校历', dark: dark),
                onError: (_, _) => _PdfStatus(message: '校历显示失败', dark: dark),
                scrollViewDecoration: BoxDecoration(
                  color: EcjtuColors.surfaceFrom(
                    context,
                    dark ? const Color(0xFF0A111E) : const Color(0xFFDFE8EF),
                  ),
                ),
                pagesBuilder: (_, pages) => _buildPages(pages),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar(bool dark) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 44),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      color: EcjtuColors.surfaceFor(context),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _ViewerButton(
            label: '−',
            tooltip: '缩小',
            onPressed: _scale <= _minScale
                ? null
                : () => _setScale(_scale - 0.2),
          ),
          const SizedBox(width: 8),
          _ZoomField(controller: _zoomController, onCommit: _commitZoom),
          const SizedBox(width: 8),
          _ViewerButton(
            label: '+',
            tooltip: '放大',
            onPressed: _scale >= _maxScale
                ? null
                : () => _setScale(_scale + 0.2),
          ),
          const SizedBox(width: 8),
          _ViewerButton(
            label: '重置',
            tooltip: '重置缩放',
            onPressed: _resetView,
            wide: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPages(List<PdfPreviewPageData> pages) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 900.0;
        final padding = widget.compact ? 8.0 : 20.0;
        final availableWidth = (width - padding * 2)
            .clamp(280.0, 1460.0)
            .toDouble();
        if (Theme.of(context).platform == TargetPlatform.windows) {
          final documentWidth = width * _scale;
          return SchoolCalendarDesktopViewport(
            key: ValueKey(_resetRevision),
            onZoom: (delta) => _setScale(_scale + delta),
            child: SizedBox(
              width: documentWidth,
              child: Padding(
                padding: EdgeInsets.all(padding),
                child: Column(
                  children: [
                    for (var i = 0; i < pages.length; i++) ...[
                      if (i > 0) const SizedBox(height: 18),
                      _buildPage(
                        pages[i],
                        (documentWidth - padding * 2).clamp(1, double.infinity),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }
        return InteractiveViewer(
          key: const ValueKey('school-calendar-pan-zoom'),
          transformationController: _transform,
          constrained: false,
          alignment: Alignment.topLeft,
          panAxis: PanAxis.free,
          minScale: _minScale,
          maxScale: _maxScale,
          boundaryMargin: const EdgeInsets.all(200),
          trackpadScrollCausesScale: false,
          onInteractionStart: (_) => _zoomAnimation.stop(),
          onInteractionEnd: (_) => setState(() {
            _scale = _transform.value.getMaxScaleOnAxis();
            _syncZoomText();
          }),
          child: SizedBox(
            width: width,
            child: Padding(
              padding: EdgeInsets.all(padding),
              child: Column(
                children: [
                  for (var index = 0; index < pages.length; index++) ...[
                    if (index > 0) SizedBox(height: widget.compact ? 8 : 18),
                    _buildPage(pages[index], availableWidth),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPage(PdfPreviewPageData page, double width) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.black
            : Colors.white,
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(32, 52, 69, 0.18),
            blurRadius: 18,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: AspectRatio(
        aspectRatio: page.aspectRatio,
        child: ColorFiltered(
          colorFilter: Theme.of(context).brightness == Brightness.dark
              ? const ColorFilter.matrix([
                  -1,
                  0,
                  0,
                  0,
                  255,
                  0,
                  -1,
                  0,
                  0,
                  255,
                  0,
                  0,
                  -1,
                  0,
                  255,
                  0,
                  0,
                  0,
                  1,
                  0,
                ])
              : const ColorFilter.mode(Colors.transparent, BlendMode.srcOver),
          child: Image(
            image: page.image,
            fit: BoxFit.fill,
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
    );
  }

  void _setScale(double value) {
    final normalized = value.clamp(_minScale, _maxScale).toDouble();
    if (normalized == _scale) return;
    if (Theme.of(context).platform == TargetPlatform.windows) {
      setState(() {
        _scale = normalized;
        _syncZoomText();
      });
      return;
    }
    _zoomAnimation.stop();
    final begin = _transform.value.clone();
    final end = begin.clone()
      ..scaleByDouble(
        normalized / begin.getMaxScaleOnAxis(),
        normalized / begin.getMaxScaleOnAxis(),
        1,
        1,
      );
    _zoomTween = Matrix4Tween(begin: begin, end: end).animate(
      CurvedAnimation(parent: _zoomAnimation, curve: Curves.easeOutCubic),
    );
    _zoomAnimation.forward(from: 0);
    setState(() {
      _scale = normalized;
      _syncZoomText();
    });
  }

  void _resetView() {
    _zoomAnimation.stop();
    _zoomTween = null;
    _transform.value = Matrix4.identity();
    setState(() {
      _scale = 1;
      _resetRevision++;
      _syncZoomText();
    });
  }

  void _commitZoom() {
    final entered = double.tryParse(
      _zoomController.text.trim().replaceAll('%', ''),
    );
    if (entered == null || !entered.isFinite) {
      _syncZoomText();
      return;
    }
    _setScale(entered / 100);
  }

  void _syncZoomText() {
    final text = (_scale * 100).round().toString();
    _zoomController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class _ViewerButton extends StatelessWidget {
  const _ViewerButton({
    required this.label,
    required this.tooltip,
    required this.onPressed,
    this.wide = false,
  });

  final String label;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Tooltip(
      message: tooltip,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: EcjtuColors.textFor(context),
          backgroundColor: EcjtuColors.surfaceFor(context),
          disabledForegroundColor: EcjtuColors.mutedFor(context),
          minimumSize: Size(wide ? 48 : 34, 30),
          padding: EdgeInsets.symmetric(horizontal: wide ? 10 : 8, vertical: 4),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
          side: BorderSide(color: EcjtuColors.borderFor(context)),
          textStyle: EcjtuTheme.buttonTextStyle(
            fontSize: EcjtuMetrics.fontCaptionFor(size),
            fontWeight: FontWeight.w700,
            height: 1.1,
          ),
        ),
        child: Text(label),
      ),
    );
  }
}

class _ZoomField extends StatelessWidget {
  const _ZoomField({required this.controller, required this.onCommit});

  final TextEditingController controller;
  final VoidCallback onCommit;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Container(
      width: 72,
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: EcjtuColors.surfaceFor(context),
        border: Border.all(color: EcjtuColors.borderFor(context)),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.right,
              onSubmitted: (_) => onCommit(),
              onEditingComplete: onCommit,
              style: TextStyle(
                color: EcjtuColors.textFor(context),
                fontSize: EcjtuMetrics.fontCaptionFor(size),
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                filled: true,
                fillColor: EcjtuColors.surfaceFor(context),
              ),

              contextMenuBuilder: buildEcjtuPlatformTextContextMenu,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            '%',
            style: TextStyle(
              color: EcjtuColors.textFor(context),
              fontSize: EcjtuMetrics.fontCaptionFor(size),
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _PdfStatus extends StatelessWidget {
  const _PdfStatus({required this.message, required this.dark});

  final String message;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Center(
      child: Text(
        message,
        style: TextStyle(
          color: EcjtuColors.mutedFrom(
            context,
            (dark ? const Color(0xFF9EACC3) : const Color(0xFF667B8E)),
          ),
          fontSize: EcjtuMetrics.fontBodyFor(size),
          height: 1.45,
        ),
      ),
    );
  }
}

class SchoolCalendarDesktopViewport extends StatefulWidget {
  const SchoolCalendarDesktopViewport({
    super.key,
    required this.child,
    required this.onZoom,
  });
  final Widget child;
  final ValueChanged<double> onZoom;
  @override
  State<SchoolCalendarDesktopViewport> createState() => _DesktopViewportState();
}

class _DesktopViewportState extends State<SchoolCalendarDesktopViewport> {
  final _vertical = ScrollController();
  final _horizontal = ScrollController();
  @override
  void dispose() {
    _vertical.dispose();
    _horizontal.dispose();
    super.dispose();
  }

  void _move(ScrollController controller, double delta) {
    if (!controller.hasClients) return;
    final position = controller.position;
    controller.jumpTo(
      (controller.offset - delta).clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      ),
    );
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent &&
        HardwareKeyboard.instance.isControlPressed) {
      GestureBinding.instance.pointerSignalResolver.register(
        event,
        (_) => widget.onZoom(event.scrollDelta.dy < 0 ? .1 : -.1),
      );
    }
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    supportedDevices: const {PointerDeviceKind.mouse},
    behavior: HitTestBehavior.opaque,
    onPanUpdate: (details) {
      _move(_vertical, details.delta.dy);
      _move(_horizontal, details.delta.dx);
    },
    child: Scrollbar(
      controller: _vertical,
      child: SingleChildScrollView(
        key: const ValueKey('school-calendar-desktop-scroll'),
        controller: _vertical,
        primary: false,
        child: Scrollbar(
          controller: _horizontal,
          notificationPredicate: (notification) =>
              notification.metrics.axis == Axis.horizontal,
          child: SingleChildScrollView(
            controller: _horizontal,
            scrollDirection: Axis.horizontal,
            primary: false,
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerSignal: _handlePointerSignal,
              child: widget.child,
            ),
          ),
        ),
      ),
    ),
  );
}
