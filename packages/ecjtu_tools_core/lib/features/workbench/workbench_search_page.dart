// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'package:ecjtu_tools_core/widgets/ecjtu_text_context_menu.dart';
import 'package:flutter/material.dart';

import '../../theme/ecjtu_theme.dart';
import '../../widgets/ecjtu_widgets.dart';
import 'smart_work_widgets.dart';
import 'workbench_search_models.dart';

class WorkbenchSearchPage extends StatefulWidget {
  const WorkbenchSearchPage({
    super.key,
    required this.loadEntries,
    required this.offline,
    required this.onBack,
    this.onOpen,
  });

  final Future<List<WorkbenchSearchEntry>> Function({bool offline}) loadEntries;
  final bool offline;
  final VoidCallback onBack;
  final ValueChanged<WorkbenchSearchEntry>? onOpen;

  @override
  State<WorkbenchSearchPage> createState() => _WorkbenchSearchPageState();
}

class _WorkbenchSearchPageState extends State<WorkbenchSearchPage> {
  String _query = '';
  late Future<List<WorkbenchSearchEntry>> _entriesFuture;

  @override
  void initState() {
    super.initState();
    _entriesFuture = widget.loadEntries(offline: widget.offline);
  }

  @override
  void didUpdateWidget(covariant WorkbenchSearchPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.offline == widget.offline) return;
    _entriesFuture = widget.loadEntries(offline: widget.offline);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final compact = EcjtuMetrics.isCompact(size);
    final query = _query.trim().toLowerCase();
    return WorkbenchSubpageColumn(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SmartWorkPageHeader(
            title: '搜索工作台',
            backTitle: '返回工作台',
            onBack: widget.onBack,
          ),
          SizedBox(height: compact ? 12 : 18),
          _SearchField(
            value: _query,
            onChanged: (value) => setState(() => _query = value),
          ),
          SizedBox(height: compact ? 12 : 18),
          FutureBuilder<List<WorkbenchSearchEntry>>(
            future: _entriesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const SmartWorkLoading(message: '正在读取工作台应用');
              }
              if (snapshot.hasError) {
                return SmartWorkInlineMessage(
                  message: snapshot.error.toString().replaceFirst(
                    'Bad state: ',
                    '',
                  ),
                  error: true,
                );
              }
              final entries = (snapshot.data ?? const <WorkbenchSearchEntry>[])
                  .where(
                    (entry) => '${entry.title} ${entry.detail}'
                        .toLowerCase()
                        .contains(query),
                  )
                  .toList(growable: false);
              return ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var index = 0; index < entries.length; index++) ...[
                      _SearchResultCard(
                        entry: entries[index],
                        onPressed: widget.onOpen == null
                            ? null
                            : () => widget.onOpen!(entries[index]),
                      ),
                      if (index < entries.length - 1) const SizedBox(height: 9),
                    ],
                    if (entries.isEmpty)
                      Text(
                        '没有找到匹配的应用',
                        style: TextStyle(
                          color: EcjtuColors.mutedFrom(
                            context,
                            Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF9EACC3)
                                : const Color(0xFF667B8E),
                          ),
                          fontSize: EcjtuMetrics.fontCaptionFor(size),
                          height: 1.5,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatefulWidget {
  const _SearchField({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _SearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && _controller.text != widget.value) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WorkbenchSearchField(
      controller: _controller,
      hintText: '搜索应用',
      autofocus: true,
      onChanged: widget.onChanged,
    );
  }
}

class WorkbenchSearchField extends StatefulWidget {
  const WorkbenchSearchField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onChanged,
    this.focusNode,
    this.autofocus = false,
    this.onSubmitted,
    this.neutral = false,
    this.fontSize,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hintText;
  final ValueChanged<String> onChanged;
  final bool autofocus;
  final ValueChanged<String>? onSubmitted;
  final bool neutral;
  final double? fontSize;

  @override
  State<WorkbenchSearchField> createState() => _WorkbenchSearchFieldState();
}

class _WorkbenchSearchFieldState extends State<WorkbenchSearchField> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.sizeOf(context);
    final borderColor = widget.neutral && !_focused
        ? (EcjtuColors.borderFor(context))
        : _focused
        ? const Color(0xFF75B8E6)
        : (EcjtuColors.borderFrom(
            context,
            dark ? const Color(0xFF34445F) : const Color(0xFFD3E8F7),
          ));
    return Focus(
      onFocusChange: (focused) {
        if (mounted) setState(() => _focused = focused);
      },
      child: Container(
        alignment: Alignment.center,
        width: double.infinity,
        height: widget.neutral ? 40 : 34,
        decoration: BoxDecoration(
          color: widget.neutral
              ? (EcjtuColors.surfaceFor(context))
              : EcjtuColors.surfaceFrom(
                  context,
                  dark ? const Color(0xFF131E32) : const Color(0xFFF4FAFF),
                ),
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(7),
          boxShadow: _focused
              ? const [
                  BoxShadow(
                    color: Color.fromRGBO(40, 122, 168, .16),
                    blurRadius: 0,
                    spreadRadius: 2,
                  ),
                ]
              : const [],
        ),
        child: TextField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          autofocus: widget.autofocus,
          onChanged: widget.onChanged,
          onSubmitted: widget.onSubmitted,
          textInputAction: TextInputAction.search,
          textAlignVertical: TextAlignVertical.center,
          style: TextStyle(
            color: EcjtuColors.textFrom(
              context,
              (dark ? const Color(0xFFE1EDFF) : const Color(0xFF223549)),
            ),
            fontSize: widget.fontSize ?? EcjtuMetrics.fontBodyFor(size),
            height: 1.2,
          ),
          decoration: InputDecoration(
            isCollapsed: true,
            hintText: widget.hintText,
            prefixIcon: widget.neutral
                ? Padding(
                    padding: const EdgeInsets.all(11),
                    child: EcjtuIcon(
                      'smart_work_search.svg',
                      size: 18,
                      color: EcjtuColors.mutedFor(context),
                    ),
                  )
                : null,
            prefixIconConstraints: widget.neutral
                ? const BoxConstraints(minWidth: 40, minHeight: 40)
                : null,
            hintStyle: TextStyle(
              color: EcjtuColors.mutedFrom(
                context,
                (dark ? const Color(0xFF9EACC3) : const Color(0xFF667B8E)),
              ),
              fontSize: widget.fontSize ?? EcjtuMetrics.fontBodyFor(size),
            ),
            filled: false,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 11,
              vertical: 0,
            ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
          ),

          contextMenuBuilder: buildEcjtuPlatformTextContextMenu,
        ),
      ),
    );
  }
}

class _SearchResultCard extends StatefulWidget {
  const _SearchResultCard({required this.entry, this.onPressed});

  final WorkbenchSearchEntry entry;
  final VoidCallback? onPressed;

  @override
  State<_SearchResultCard> createState() => _SearchResultCardState();
}

class _SearchResultCardState extends State<_SearchResultCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.sizeOf(context);
    final card = Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 82),
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
      decoration: BoxDecoration(
        color: _hovered
            ? (EcjtuColors.hoverFrom(
                context,
                (dark ? const Color(0xFF172B42) : const Color(0xFFEEF7FC)),
              ))
            : (EcjtuColors.surfaceFrom(
                context,
                (dark ? const Color(0xFF101D31) : const Color(0xFFF8FBFD)),
              )),
        border: Border.all(
          color: _hovered
              ? (dark ? const Color(0xFF5085A3) : const Color(0xFF8DB7D0))
              : (EcjtuColors.borderFrom(
                  context,
                  (dark ? const Color(0xFF31546B) : const Color(0xFFD5E4EF)),
                )),
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 38,
            height: 28,
            child: EcjtuIcon(
              widget.entry.icon,
              size: 28,
              color: dark ? const Color(0xFF77BCEB) : EcjtuColors.smartWorkIcon,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.entry.title,
                  softWrap: true,
                  style: TextStyle(
                    color: EcjtuColors.textFrom(
                      context,
                      (dark
                          ? const Color(0xFFE1EDFF)
                          : const Color(0xFF223549)),
                    ),
                    fontSize: EcjtuMetrics.fontBodyFor(size),
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  widget.entry.detail,
                  softWrap: true,
                  style: TextStyle(
                    color: EcjtuColors.mutedFrom(
                      context,
                      (dark
                          ? const Color(0xFF9EACC3)
                          : const Color(0xFF667B8E)),
                    ),
                    fontSize: EcjtuMetrics.fontCaptionFor(size),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    if (widget.onPressed == null) return card;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: widget.onPressed,
          borderRadius: BorderRadius.circular(6),
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          child: card,
        ),
      ),
    );
  }
}
