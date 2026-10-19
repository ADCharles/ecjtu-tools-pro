// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'package:flutter/material.dart';

import '../theme/ecjtu_theme.dart';
import '../theme/ecjtu_control_palette.dart';
import '../theme/ecjtu_glass.dart';

class EcjtuSlidingSegments extends StatelessWidget {
  const EcjtuSlidingSegments({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onChanged,
    this.height = 40,
    this.columns,
    this.fontSize = 14,
    this.duration = const Duration(milliseconds: 180),
  });
  final List<String> items;
  final int? selectedIndex;
  final int? columns;
  final ValueChanged<int> onChanged;
  final double height, fontSize;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final colors = EcjtuGlass.of(context);
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : this.duration;
    final columnCount = columns ?? items.length;
    final rows = (items.length / columnCount).ceil();
    final rowHeight = height - 8;
    return Container(
      height: rows * rowHeight + 8,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colors.segmentedTrack,
        border: Border.all(color: EcjtuColors.borderFor(context)),
        borderRadius: BorderRadius.circular(7),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth / columnCount;
          return Stack(
            children: [
              if (selectedIndex != null)
                AnimatedPositioned(
                  duration: duration,
                  curve: const Cubic(.25, .1, .25, 1),
                  left: (selectedIndex! % columnCount) * width,
                  top: (selectedIndex! ~/ columnCount) * rowHeight,
                  height: rowHeight,
                  width: width,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.dark ? colors.selected : Colors.white,
                      borderRadius: BorderRadius.circular(5),
                      boxShadow: colors.dark
                          ? null
                          : const [
                              BoxShadow(
                                color: Color(0x10000000),
                                blurRadius: 5,
                                offset: Offset(0, 1),
                              ),
                            ],
                    ),
                  ),
                ),
              Wrap(
                children: [
                  for (var index = 0; index < items.length; index++)
                    SizedBox(
                      width: width,
                      height: rowHeight,
                      child: Semantics(
                        selected: index == selectedIndex,
                        child: TextButton(
                          onPressed: () {
                            if (index != selectedIndex) onChanged(index);
                          },
                          style: ButtonStyle(
                            splashFactory: NoSplash.splashFactory,
                            enableFeedback: false,
                            animationDuration: Duration.zero,
                            foregroundColor: WidgetStatePropertyAll(
                              index == selectedIndex
                                  ? (colors.blue && !colors.dark
                                        ? EcjtuColors.arrangementActive
                                        : colors.accent)
                                  : (colors.dark
                                        ? colors.muted
                                        : const Color(0xFF5F7888)),
                            ),
                            overlayColor: const WidgetStatePropertyAll(
                              Colors.transparent,
                            ),
                            backgroundColor: const WidgetStatePropertyAll(
                              Colors.transparent,
                            ),
                            surfaceTintColor: const WidgetStatePropertyAll(
                              Colors.transparent,
                            ),
                            padding: const WidgetStatePropertyAll(
                              EdgeInsets.symmetric(horizontal: 4),
                            ),
                            minimumSize: const WidgetStatePropertyAll(
                              Size.zero,
                            ),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: WidgetStatePropertyAll(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                            textStyle: WidgetStatePropertyAll(
                              TextStyle(
                                fontFamily: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.fontFamily,
                                fontSize: fontSize,
                                fontWeight: FontWeight.w600,
                                height: 1.2,
                              ),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              items[index],
                              maxLines: 1,
                              textHeightBehavior: const TextHeightBehavior(
                                applyHeightToFirstAscent: false,
                                applyHeightToLastDescent: false,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class EcjtuNavigationBar extends StatefulWidget {
  const EcjtuNavigationBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onChanged,
    this.animateSelection = true,
    this.itemKeys,
  });

  final List<String> items;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final bool animateSelection;
  final List<Key>? itemKeys;

  @override
  State<EcjtuNavigationBar> createState() => _EcjtuNavigationBarState();
}

class _EcjtuNavigationBarState extends State<EcjtuNavigationBar> {
  void _select(int index) {
    if (index != widget.selectedIndex) widget.onChanged(index);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final compact = EcjtuMetrics.isCompact(size);
    return Container(
      height: EcjtuMetrics.navigationHeightFor(size),
      decoration: BoxDecoration(
        color:
            EcjtuControlPalette.maybeOf(context)?.surface ??
            (EcjtuColors.pageFor(context)),
        border: Border(
          bottom: BorderSide(
            color:
                EcjtuControlPalette.maybeOf(context)?.border ??
                (EcjtuColors.borderFor(context)),
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: EcjtuMetrics.navigationHorizontalPaddingFor(size),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var index = 0; index < widget.items.length; index++)
              Expanded(
                child: _NavigationItem(
                  key: widget.itemKeys?[index],
                  title: widget.items[index],
                  active: widget.selectedIndex == index,
                  compact: compact,
                  animateSelection: widget.animateSelection,
                  onPressed: () => _select(index),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    super.key,
    required this.title,
    required this.active,
    required this.compact,
    required this.animateSelection,
    required this.onPressed,
  });

  final String title;
  final bool active;
  final bool compact;
  final bool animateSelection;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final palette = EcjtuControlPalette.maybeOf(context);
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: active
            ? palette?.focus ??
                  (dark ? const Color(0xFFF2F7FF) : EcjtuColors.primary)
            : palette?.muted ??
                  (dark ? const Color(0xFF93A6C3) : EcjtuColors.textSecondary),
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: const RoundedRectangleBorder(),
        overlayColor: Colors.transparent,
      ),
      child: SizedBox.expand(
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Center(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: EcjtuMetrics.fontLabelFor(size),
                  fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: AnimatedContainer(
                duration: animateSelection
                    ? EcjtuAnimation.navigation
                    : Duration.zero,
                curve: EcjtuAnimation.curve,
                width: active ? 32 : 0,
                height: 2,
                decoration: BoxDecoration(
                  color:
                      palette?.focus ??
                      (dark ? const Color(0xFF61ADFF) : EcjtuColors.primary),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(2),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
