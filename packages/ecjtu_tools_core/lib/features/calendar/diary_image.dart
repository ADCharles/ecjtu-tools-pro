// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'package:ecjtu_tools_core/widgets/ecjtu_text_context_menu.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../widgets/ecjtu_widgets.dart';

class DiaryImage extends StatefulWidget {
  const DiaryImage({
    super.key,
    required this.loadFile,
    required this.width,
    required this.alt,
    this.onWidthChanged,
  });
  final Future<File> Function() loadFile;
  final double width;
  final String alt;
  final ValueChanged<double>? onWidthChanged;
  @override
  State<DiaryImage> createState() => _DiaryImageState();
}

class _DiaryImageState extends State<DiaryImage> {
  late final Future<File> _file = widget.loadFile();
  late double _width = widget.width;
  @override
  void didUpdateWidget(covariant DiaryImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.width != widget.width) _width = widget.width;
  }

  Future<void> _chooseSize() async {
    final result = await showEcjtuDialog<double>(
      context: context,
      builder: (_) => _ImageSizeDialog(initialWidth: _width),
    );
    if (result == null || !mounted) return;
    setState(() => _width = result);
    widget.onWidthChanged?.call(result);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final available = constraints.maxWidth.isFinite
          ? constraints.maxWidth
          : MediaQuery.sizeOf(context).width - 64;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: available * _width,
              child: FutureBuilder<File>(
                future: _file,
                builder: (context, snapshot) {
                  if (snapshot.hasError) return const Text('图片无法读取');
                  if (!snapshot.hasData)
                    return const SizedBox(
                      height: 80,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.file(
                      snapshot.data!,
                      width: available * _width,
                      fit: BoxFit.contain,
                      semanticLabel: widget.alt,
                      cacheWidth: 1400,
                      errorBuilder: (_, __, ___) => const Text('图片无法读取'),
                    ),
                  );
                },
              ),
            ),
            if (widget.onWidthChanged != null) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  EcjtuDialogAction(label: '调整大小', onPressed: _chooseSize),
                  Text(
                    '${(_width * 100).round()}%',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Tooltip(
                    message: '拖动调整大小',
                    child: MouseRegion(
                      cursor: SystemMouseCursors.resizeLeftRight,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onHorizontalDragUpdate: (details) => setState(
                          () => _width = (_width + details.delta.dx / available)
                              .clamp(.01, 1),
                        ),
                        onHorizontalDragEnd: (_) =>
                            widget.onWidthChanged?.call(_width),
                        onHorizontalDragCancel: () =>
                            widget.onWidthChanged?.call(_width),
                        child: Semantics(
                          label: '调整图片大小',
                          child: Container(
                            width: 42,
                            height: 32,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Theme.of(context).dividerColor,
                              ),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Icon(
                              Icons.swap_horiz,
                              size: 20,
                              color: Theme.of(context).hintColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      );
    },
  );
}

class _ImageSizeDialog extends StatefulWidget {
  const _ImageSizeDialog({required this.initialWidth});
  final double initialWidth;
  @override
  State<_ImageSizeDialog> createState() => _ImageSizeDialogState();
}

class _ImageSizeDialogState extends State<_ImageSizeDialog> {
  late double _width = widget.initialWidth;
  late final _input = TextEditingController(
    text: (_width * 100).round().toString(),
  );
  String? _error;
  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => EcjtuDialog(
    title: const Text('图片大小'),
    content: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Slider(
          value: _width,
          min: .01,
          max: 1,
          label: '${(_width * 100).round()}%',
          onChanged: (value) => setState(() {
            _width = value;
            _input.text = (value * 100).round().toString();
            _error = null;
          }),
        ),
        TextField(
          controller: _input,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: '宽度比例',
            suffixText: '%',
            errorText: _error,
          ),
          onChanged: (text) {
            final value = double.tryParse(text);
            if (value != null && value.isFinite && value >= 1 && value <= 100) {
              setState(() {
                _width = value / 100;
                _error = null;
              });
            }
          },

          contextMenuBuilder: buildEcjtuPlatformTextContextMenu,
        ),
      ],
    ),
    actions: [
      EcjtuDialogAction(label: '取消', onPressed: () => Navigator.pop(context)),
      EcjtuDialogAction(
        label: '完成',
        onPressed: () {
          final value = double.tryParse(_input.text);
          if (value == null || !value.isFinite || value < 1 || value > 100) {
            setState(() => _error = '请输入 1–100 之间的比例');
            return;
          }
          Navigator.pop(context, value / 100);
        },
      ),
    ],
  );
}
