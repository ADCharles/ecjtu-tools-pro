// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'package:ecjtu_tools_core/widgets/ecjtu_text_context_menu.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../features/workbench/workbench_search_catalog.dart';
import '../features/workbench/workbench_search_models.dart';
import '../theme/ecjtu_glass.dart';
import '../theme/ecjtu_desktop_tokens.dart';
import 'ecjtu_icon.dart';

class EcjtuDesktopWorkbenchSearch extends StatefulWidget {
  const EcjtuDesktopWorkbenchSearch({
    super.key,
    required this.loadEntries,
    required this.onOpen,
    required this.noticesAvailable,
  });
  final Future<List<WorkbenchSearchEntry>> Function() loadEntries;
  final ValueChanged<WorkbenchSearchEntry> onOpen;
  final bool noticesAvailable;
  @override
  State<EcjtuDesktopWorkbenchSearch> createState() => _SearchState();
}

class _SearchState extends State<EcjtuDesktopWorkbenchSearch> {
  final _focus = FocusNode();
  final _controller = TextEditingController();
  final _field = GlobalKey();
  final _scroll = ScrollController();
  final _recent = <WorkbenchSearchEntry>[];
  late List<WorkbenchSearchEntry> _entries = [
    ...WorkbenchSearchCatalog.roots(noticesAvailable: widget.noticesAvailable),
    ...WorkbenchSearchCatalog.enhancements,
  ];
  Future<void>? _pending;
  bool _loaded = false;
  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocus);
  }

  void _onFocus() {
    if (_focus.hasFocus && !_loaded && _pending == null) {
      _pending = _load().whenComplete(() {
        _pending = null;
      });
    }
  }

  Future<void> _load() async {
    try {
      final entries = await widget.loadEntries();
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _loaded = true;
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocus);
    _focus.dispose();
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = EcjtuGlass.of(context);
    return RawAutocomplete<WorkbenchSearchEntry>(
      focusNode: _focus,
      textEditingController: _controller,
      displayStringForOption: (entry) => entry.title,
      optionsBuilder: (value) async {
        final query = value.text.trim().toLowerCase();
        if (query.isEmpty) return _recent;
        await _pending;
        if (!mounted) return const <WorkbenchSearchEntry>[];
        return _entries
            .where(
              (entry) => '${entry.title} ${entry.detail}'
                  .toLowerCase()
                  .contains(query),
            )
            .take(12);
      },
      onSelected: (entry) {
        _recent.removeWhere(
          (item) => item.deduplicationKey == entry.deduplicationKey,
        );
        _recent.insert(0, entry);
        if (_recent.length > 8) _recent.removeLast();
        _controller.clear();
        _focus.unfocus();
        widget.onOpen(entry);
      },
      fieldViewBuilder: (context, controller, focus, onSubmitted) => SizedBox(
        key: _field,
        height: 34,
        child: TextField(
          controller: controller,
          focusNode: focus,
          onTapOutside: (_) => focus.unfocus(),
          onSubmitted: (_) => onSubmitted(),
          style: TextStyle(fontSize: EcjtuDesktopType.body, color: colors.text),
          textAlignVertical: TextAlignVertical.center,
          decoration: InputDecoration(
            hintText: '搜索',
            isDense: true,
            filled: true,
            fillColor: colors.panelHighlight,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
            prefixIconConstraints: const BoxConstraints.tightFor(
              width: 34,
              height: 34,
            ),
            prefixIcon: Center(
              child: EcjtuIcon(
                'smart_work_search.svg',
                size: 16,
                color: colors.muted,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colors.panelBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colors.accent),
            ),
          ),

          contextMenuBuilder: buildEcjtuPlatformTextContextMenu,
        ),
      ),
      optionsViewBuilder: (context, onSelected, options) {
        final rows = options.toList();
        final overlay =
            Overlay.of(context).context.findRenderObject() as RenderBox?;
        final box = _field.currentContext?.findRenderObject() as RenderBox?;
        final origin =
            box?.localToGlobal(Offset.zero, ancestor: overlay) ?? Offset.zero;
        final size = overlay?.size ?? MediaQuery.sizeOf(context);
        final width = math.min(
          344.0,
          math.max(160.0, size.width - origin.dx - 16),
        );
        final height = math.min(
          440.0,
          math.max(100.0, size.height - origin.dy - 46),
        );
        return _SearchOverlay(
          child: Positioned(
            left: origin.dx,
            top: origin.dy + (box?.size.height ?? 34),
            width: width,
            child: TextFieldTapRegion(
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Material(
                  key: const ValueKey('workbench-search-popup'),
                  color: colors.card,
                  elevation: 8,
                  shadowColor: Colors.black.withValues(alpha: .18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: colors.contentBorder),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: SizedBox(
                    width: width,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: height),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                            child: Text(
                              _controller.text.trim().isEmpty ? '最近搜索' : '搜索结果',
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.muted,
                              ),
                            ),
                          ),
                          Flexible(
                            child: Scrollbar(
                              controller: _scroll,
                              child: ListView.builder(
                                controller: _scroll,
                                shrinkWrap: true,
                                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                                itemCount: rows.length,
                                itemBuilder: (context, index) {
                                  final entry = rows[index];
                                  final highlighted =
                                      AutocompleteHighlightedOption.of(
                                        context,
                                      ) ==
                                      index;
                                  return Material(
                                    color: highlighted
                                        ? colors.selected
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(8),
                                      onTap: () => onSelected(entry),
                                      child: ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          minHeight: 56,
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 10,
                                          ),
                                          child: Row(
                                            children: [
                                              EcjtuIcon(
                                                entry.icon,
                                                size: 24,
                                                color: colors.accent,
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      entry.title,
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        height: 1.4,
                                                        color: colors.text,
                                                      ),
                                                    ),
                                                    if (entry.detail.isNotEmpty)
                                                      Text(
                                                        entry.detail,
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          height: 1.4,
                                                          color: colors.muted,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SearchOverlay extends StatefulWidget {
  const _SearchOverlay({required this.child});
  final Widget child;
  @override
  State<_SearchOverlay> createState() => _SearchOverlayState();
}

class _SearchOverlayState extends State<_SearchOverlay> {
  final _portal = OverlayPortalController();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _portal.show();
    });
  }

  @override
  Widget build(BuildContext context) => OverlayPortal(
    controller: _portal,
    overlayChildBuilder: (_) => widget.child,
    child: const SizedBox.shrink(),
  );
}
