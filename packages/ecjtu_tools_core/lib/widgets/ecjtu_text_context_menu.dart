// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'package:flutter/material.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;

import '../theme/ecjtu_theme.dart';
import '../theme/ecjtu_control_palette.dart';

bool _desktop(BuildContext context) => const {
  TargetPlatform.windows,
  TargetPlatform.linux,
  TargetPlatform.macOS,
}.contains(Theme.of(context).platform);

Widget buildEcjtuPlatformTextContextMenu(
  BuildContext context,
  EditableTextState state,
) => _desktop(context)
    ? buildEcjtuTextContextMenu(context, state)
    : AdaptiveTextSelectionToolbar.editableText(editableTextState: state);

Widget buildEcjtuPlatformSelectionContextMenu(
  BuildContext context,
  SelectableRegionState state,
) => _desktop(context)
    ? buildEcjtuSelectionContextMenu(context, state)
    : AdaptiveTextSelectionToolbar.selectableRegion(
        selectableRegionState: state,
      );

Widget buildEcjtuTextContextMenu(
  BuildContext context,
  EditableTextState editableTextState,
) {
  if (!_desktop(context)) {
    return AdaptiveTextSelectionToolbar.editableText(
      editableTextState: editableTextState,
    );
  }
  final items = editableTextState.contextMenuButtonItems;
  if (items.isEmpty) return const SizedBox.shrink();
  final anchors = editableTextState.contextMenuAnchors;
  return buildEcjtuContextMenu(context, items, anchors);
}

Widget buildEcjtuSelectionContextMenu(
  BuildContext context,
  SelectableRegionState state,
) {
  if (!_desktop(context)) {
    return AdaptiveTextSelectionToolbar.selectableRegion(
      selectableRegionState: state,
    );
  }
  final items = [...state.contextMenuButtonItems];
  if (!items.any((item) => item.type == ContextMenuButtonType.selectAll)) {
    items.add(
      ContextMenuButtonItem(
        type: ContextMenuButtonType.selectAll,
        onPressed: () {
          state.selectAll();
          state.hideToolbar();
        },
      ),
    );
  }
  return buildEcjtuContextMenu(context, items, state.contextMenuAnchors);
}

Widget buildEcjtuContextMenu(
  BuildContext context,
  List<ContextMenuButtonItem> items,
  TextSelectionToolbarAnchors anchors,
) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  final palette = EcjtuControlPalette.maybeOf(context);
  final surface = Color.alphaBlend(
    Colors.white.withValues(alpha: dark ? .10 : .60),
    palette?.surface ??
        (EcjtuColors.surfaceFrom(
          context,
          dark ? const Color(0xFF232C38) : Colors.white,
        )),
  );
  final border =
      palette?.border ??
      (EcjtuColors.borderFrom(
        context,
        dark ? const Color(0xFF426B83) : const Color(0xFFB9CFDD),
      ));
  final desktop = _desktop(context);
  const labels = <ContextMenuButtonType, String>{
    ContextMenuButtonType.cut: '剪切',
    ContextMenuButtonType.copy: '复制',
    ContextMenuButtonType.paste: '粘贴',
    ContextMenuButtonType.selectAll: '全选',
    ContextMenuButtonType.delete: '删除',
    ContextMenuButtonType.lookUp: '查找',
    ContextMenuButtonType.searchWeb: '网页搜索',
    ContextMenuButtonType.share: '分享',
    ContextMenuButtonType.liveTextInput: '文字识别',
  };
  final toolbar = TextSelectionToolbar(
    anchorAbove: anchors.primaryAnchor,
    anchorBelow: anchors.secondaryAnchor ?? anchors.primaryAnchor,
    toolbarBuilder: (context, child) => desktop
        ? SizedBox(
            width: 148,
            child: fluent.FluentTheme(
              data: fluent.FluentThemeData(
                brightness: Theme.of(context).brightness,
              ),
              child: fluent.Acrylic(
                tint: surface,
                tintAlpha: MediaQuery.highContrastOf(context) ? 1 : .96,
                luminosityAlpha: .65,
                blurAmount: MediaQuery.highContrastOf(context) ? 0 : 20,
                elevation: 16,
                shadowColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: (dark ? Colors.white : Colors.black).withValues(
                      alpha: dark ? .10 : .06,
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 5,
                    horizontal: 4,
                  ),
                  child: child,
                ),
              ),
            ),
          )
        : Material(
            color: Colors.transparent,
            child: Container(
              width: 148,
              decoration: BoxDecoration(
                color: surface,
                border: Border.all(color: border),
                borderRadius: BorderRadius.circular(palette == null ? 1 : 6),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(28, 31, 37, 0.12),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: child,
            ),
          ),
    children: [
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final item in items)
            SizedBox(
              width: desktop ? 140 : 146,
              height: desktop ? 34 : EcjtuMetrics.pickerItemHeight,
              child: InkWell(
                onTap: item.onPressed,
                borderRadius: BorderRadius.circular(desktop ? 6 : 0),
                hoverColor: desktop
                    ? (dark ? Colors.white : Colors.black).withValues(
                        alpha: .06,
                      )
                    : null,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (desktop) ...[
                          Icon(
                            switch (item.type) {
                              ContextMenuButtonType.copy => Icons.copy_outlined,
                              ContextMenuButtonType.cut =>
                                Icons.content_cut_outlined,
                              ContextMenuButtonType.paste =>
                                Icons.content_paste_outlined,
                              ContextMenuButtonType.selectAll =>
                                Icons.select_all_outlined,
                              ContextMenuButtonType.delete =>
                                Icons.delete_outline,
                              ContextMenuButtonType.share =>
                                Icons.ios_share_outlined,
                              _ => Icons.search_outlined,
                            },
                            size: 16,
                            color:
                                palette?.foreground ??
                                (EcjtuColors.textFrom(
                                  context,
                                  dark
                                      ? EcjtuColors.darkTextPrimary
                                      : EcjtuColors.smartWorkStrongText,
                                )),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Flexible(
                          child: Text(
                            labels[item.type] ?? item.label ?? '',
                            style: TextStyle(
                              color:
                                  palette?.foreground ??
                                  (EcjtuColors.textFrom(
                                    context,
                                    dark
                                        ? EcjtuColors.darkTextPrimary
                                        : EcjtuColors.smartWorkStrongText,
                                  )),
                              fontSize: desktop
                                  ? 14
                                  : EcjtuMetrics.fontSmallFor(
                                      MediaQuery.sizeOf(context),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ],
  );
  if (const {
    TargetPlatform.windows,
    TargetPlatform.linux,
    TargetPlatform.macOS,
  }.contains(Theme.of(context).platform)) {
    const padding = 8.0;
    final above = MediaQuery.paddingOf(context).top + padding;
    return _InstantDesktopContextMenu(
      child: Padding(
        padding: EdgeInsets.fromLTRB(padding, above, padding, padding),
        child: CustomSingleChildLayout(
          delegate: DesktopTextSelectionToolbarLayoutDelegate(
            anchor: anchors.primaryAnchor - Offset(padding, above),
          ),
          child: toolbar.toolbarBuilder(
            context,
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight:
                    (MediaQuery.sizeOf(context).height - above - padding - 12)
                        .clamp(0, double.infinity),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: toolbar.children,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  return toolbar;
}

class _InstantDesktopContextMenu extends StatefulWidget {
  const _InstantDesktopContextMenu({required this.child});
  final Widget child;

  @override
  State<_InstantDesktopContextMenu> createState() =>
      _InstantDesktopContextMenuState();
}

class _InstantDesktopContextMenuState
    extends State<_InstantDesktopContextMenu> {
  final _portal = OverlayPortalController()..show();

  @override
  Widget build(BuildContext context) => OverlayPortal(
    controller: _portal,
    // The selection toolbar adds a fade above the builder. A portal retains
    // its lifetime and theme while painting outside that animated ancestor.
    overlayChildBuilder: (_) => TapRegion(
      groupId: SelectableRegion,
      child: TextFieldTapRegion(child: widget.child),
    ),
  );
}
