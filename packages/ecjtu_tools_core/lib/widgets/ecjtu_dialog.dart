// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/ecjtu_control_palette.dart';
import '../theme/ecjtu_glass.dart';

import '../theme/ecjtu_theme.dart';
import 'ai_controls_scope.dart';
import 'ecjtu_pane_surface.dart';

class EcjtuDialog extends StatelessWidget {
  const EcjtuDialog({
    super.key,
    required this.title,
    this.content,
    this.actions = const <Widget>[],
    this.maxWidth = 760,
    this.showCloseButton = true,
    this.onClose,
    this.scrollContent = true,
  });

  final VoidCallback? onClose;
  final Widget title;
  final Widget? content;
  final List<Widget> actions;
  final bool scrollContent;
  final double maxWidth;

  /// 是否显示右上角关闭按钮；测试版首启提示在倒计时期间需要隐藏它。
  final bool showCloseButton;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final palette = EcjtuControlPalette.maybeOf(context);
    final ink = palette?.foreground ?? (EcjtuColors.textFor(context));
    final muted = palette?.muted ?? (EcjtuColors.mutedFor(context));
    final border = palette?.border ?? (EcjtuColors.borderFor(context));
    final surface = palette?.surface ?? (EcjtuColors.surfaceFor(context));
    final primary = theme.colorScheme.primary;
    final fontFamily = theme.textTheme.bodyMedium?.fontFamily;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      elevation: 24,
      shadowColor: dark
          ? const Color.fromRGBO(0, 0, 0, 0.42)
          : const Color.fromRGBO(17, 52, 78, 0.24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: border),
      ),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(22, 20, 12, 20),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: DefaultTextStyle(
                      style: TextStyle(
                        color: ink,
                        fontFamily: fontFamily,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                      child: title,
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (showCloseButton) ...[
                    TextButton(
                      onPressed: onClose ?? () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: muted,
                        minimumSize: const Size(34, 34),
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: const CircleBorder(),
                        overlayColor: Colors.transparent,
                      ),
                      child: const Text(
                        '×',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w400,
                          height: 1,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (content != null)
              Flexible(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.72,
                  ),
                  child: scrollContent
                      ? ListView(
                          shrinkWrap: true,
                          padding: const EdgeInsets.fromLTRB(26, 26, 26, 12),
                          children: [
                            DefaultTextStyle(
                              style: TextStyle(
                                color: ink,
                                fontFamily: fontFamily,
                                fontSize: 15,
                                height: 1.75,
                              ),
                              child: content!,
                            ),
                          ],
                        )
                      : Padding(
                          padding: const EdgeInsets.fromLTRB(26, 26, 26, 12),
                          child: DefaultTextStyle(
                            style: TextStyle(
                              color: ink,
                              fontFamily: fontFamily,
                              fontSize: 15,
                              height: 1.75,
                            ),
                            child: content!,
                          ),
                        ),
                ),
              ),
            if (actions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 14, 22, 22),
                child: Theme(
                  data: theme.copyWith(
                    textButtonTheme: TextButtonThemeData(
                      style: TextButton.styleFrom(
                        foregroundColor: ink,
                        backgroundColor: surface,
                        minimumSize: const Size(0, 40),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        textStyle: TextStyle(
                          fontFamily: fontFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                          side: BorderSide(color: border),
                        ),
                        overlayColor: Colors.transparent,
                      ),
                    ),
                    filledButtonTheme: FilledButtonThemeData(
                      style: FilledButton.styleFrom(
                        foregroundColor: theme.colorScheme.onPrimary,
                        backgroundColor: primary,
                        minimumSize: const Size(0, 40),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        textStyle: TextStyle(
                          fontFamily: fontFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        overlayColor: Colors.transparent,
                      ),
                    ),
                  ),
                  child: OverflowBar(
                    alignment: MainAxisAlignment.end,
                    spacing: 10,
                    children: actions,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class EcjtuDialogAction extends StatelessWidget {
  const EcjtuDialogAction({
    super.key,
    required this.label,
    required this.onPressed,
    this.selected = false,
    this.borderRadius = 6,
    this.textStyle,
    this.content,
    this.padding,
    this.backgroundColor,
    this.minimumSize,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool selected;
  final double borderRadius;
  final TextStyle? textStyle;
  final Widget? content;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final Size? minimumSize;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final palette = EcjtuControlPalette.maybeOf(context);
    final color = palette?.foreground ?? (EcjtuColors.textFor(context));
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        backgroundColor:
            backgroundColor ??
            (selected
                ? palette?.selected ??
                      (EcjtuColors.surfaceFrom(
                        context,
                        dark
                            ? EcjtuColors.darkSegmentedSurface
                            : EcjtuColors.segmentedSurface,
                      ))
                : null),
        minimumSize: minimumSize ?? const Size(0, 34),
        padding:
            padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        side: BorderSide(
          color: selected
              ? palette?.border ??
                    (EcjtuColors.borderFrom(
                      context,
                      dark
                          ? EcjtuColors.darkSegmentedBorder
                          : EcjtuColors.segmentedBorder,
                    ))
              : palette?.border ?? (EcjtuColors.borderFor(context)),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        textStyle:
            textStyle ??
            Theme.of(context).textTheme.labelMedium?.copyWith(
              fontSize: EcjtuMetrics.fontCaptionFor(MediaQuery.sizeOf(context)),
              fontWeight: FontWeight.w400,
            ) ??
            EcjtuTheme.buttonTextStyle(
              fontSize: EcjtuMetrics.fontCaptionFor(MediaQuery.sizeOf(context)),
              fontWeight: FontWeight.w400,
            ),
      ),
      child: content ?? Text(label),
    );
  }
}

Future<T?> showEcjtuDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) => showGeneralDialog<T>(
  context: context,
  barrierDismissible: barrierDismissible,
  barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
  barrierColor: Colors.black54,
  useRootNavigator: !EcjtuPaneDialogScope.contains(context),
  transitionDuration: Duration.zero,
  pageBuilder: (dialogContext, _, _) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final chrome = EcjtuGlass.mobileChromeFor(Theme.of(context).brightness);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Color.alphaBlend(Colors.black54, chrome),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemStatusBarContrastEnforced: false,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: dark
            ? Brightness.light
            : Brightness.dark,
      ),
      child: SizedBox.expand(
        child: AiControlsScope.captureDialog(
          context,
          InheritedTheme.captureAll(context, Builder(builder: builder)),
        ),
      ),
    );
  },
);
