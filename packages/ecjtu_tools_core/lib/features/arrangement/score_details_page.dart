// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'package:ecjtu_tools_core/widgets/ecjtu_text_context_menu.dart';
import 'package:flutter/material.dart';

import '../../theme/ecjtu_theme.dart';
import '../../widgets/ecjtu_icon.dart';
import '../../widgets/ecjtu_page.dart';
import '../../widgets/ecjtu_select_box.dart';
import 'score_models.dart';

const _scoreDetailsFontFamily = 'SourceHanSansCN';

class ScoreDetailsPage extends StatefulWidget {
  const ScoreDetailsPage({
    super.key,
    required this.snapshot,
    required this.onBack,
  });

  final ScoreSnapshot snapshot;
  final VoidCallback onBack;

  @override
  State<ScoreDetailsPage> createState() => _ScoreDetailsPageState();
}

class _ScoreDetailsPageState extends State<ScoreDetailsPage> {
  final _resultsEndKey = GlobalKey();
  String _selectedFilter = 'all';
  String _query = '';
  bool _searchOpen = false;

  void _updateQuery(String value) {
    final query = value.trim().toLowerCase();
    EcjtuPageScrollAnchor(
      query.isNotEmpty,
      contentEndKey: _resultsEndKey,
    ).dispatch(context);
    setState(() => _query = value);
  }

  @override
  Widget build(BuildContext context) {
    final terms = _terms();
    final years =
        terms.map(_yearOf).where((year) => year.isNotEmpty).toSet().toList()
          ..sort((left, right) => right.compareTo(left));
    final filters = <String>[
      'all',
      ...years.map((year) => 'year:$year'),
      ...terms,
    ];
    final selectedFilter = filters.contains(_selectedFilter)
        ? _selectedFilter
        : 'all';
    final records = _recordsFor(terms, selectedFilter)
        .where(
          (record) =>
              _query.trim().isEmpty ||
              record.courseName.toLowerCase().contains(
                _query.trim().toLowerCase(),
              ),
        )
        .toList();
    final published = records
        .where((record) => record.usualScore.isNotEmpty)
        .toList();
    final unpublished = records
        .where((record) => record.usualScore.isEmpty)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ScoreDetailsHeader(
          filters: filters,
          selectedFilter: selectedFilter,
          searchOpen: _searchOpen,
          query: _query,
          onBack: () {
            const EcjtuPageScrollAnchor(false).dispatch(context);
            widget.onBack();
          },
          onFilterChanged: (value) {
            final searching = _query.trim().isNotEmpty;
            EcjtuPageScrollAnchor(
              searching,
              contentEndKey: searching ? _resultsEndKey : null,
            ).dispatch(context);
            setState(() => _selectedFilter = value);
          },
          onSearchToggle: () {
            if (_searchOpen) {
              const EcjtuPageScrollAnchor(false).dispatch(context);
            }
            setState(() {
              _searchOpen = !_searchOpen;
              if (!_searchOpen) _query = '';
            });
          },
          onQueryChanged: _updateQuery,
        ),
        SizedBox(height: EcjtuMetrics.pageHeaderGapFor(context)),
        Column(
          key: _resultsEndKey,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (terms.isEmpty)
              const _ScoreDetailsEmpty(message: '暂无成绩详情')
            else if (records.isEmpty)
              const _ScoreDetailsEmpty(message: '该范围暂无成绩详情')
            else ...[
              if (published.isNotEmpty) _ScoreDetailGroup(records: published),
              if (published.isNotEmpty && unpublished.isNotEmpty)
                const SizedBox(height: 16),
              if (unpublished.isNotEmpty)
                _ScoreDetailGroup(records: unpublished),
            ],
          ],
        ),
      ],
    );
  }

  List<String> _terms() {
    final terms = widget.snapshot.details.keys
        .where((term) => widget.snapshot.details[term]?.isNotEmpty ?? false)
        .toList();
    terms.sort((left, right) => right.compareTo(left));
    return terms;
  }

  List<ScoreDetailRecord> _recordsFor(
    List<String> terms,
    String selectedFilter,
  ) {
    return terms
        .where(
          (term) =>
              selectedFilter == 'all' ||
              selectedFilter == term ||
              selectedFilter == 'year:${_yearOf(term)}',
        )
        .expand(
          (term) =>
              widget.snapshot.details[term] ?? const <ScoreDetailRecord>[],
        )
        .toList();
  }

  String _yearOf(String term) {
    return RegExp(r'^(20\d{2})\.[12]$').firstMatch(term)?.group(1) ?? '';
  }
}

class _ScoreDetailsHeader extends StatelessWidget {
  const _ScoreDetailsHeader({
    required this.filters,
    required this.selectedFilter,
    required this.searchOpen,
    required this.query,
    required this.onBack,
    required this.onFilterChanged,
    required this.onSearchToggle,
    required this.onQueryChanged,
  });

  final List<String> filters;
  final String selectedFilter;
  final bool searchOpen;
  final String query;
  final VoidCallback onBack;
  final ValueChanged<String> onFilterChanged;
  final VoidCallback onSearchToggle;
  final ValueChanged<String> onQueryChanged;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final filterFontSize = EcjtuMetrics.fontSmallFor(size);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EcjtuSubpageTitle(title: '成绩详情', backTitle: '返回成绩', onBack: onBack),
        SizedBox(height: EcjtuMetrics.pageHeaderGapFor(context)),
        LayoutBuilder(
          builder: (context, constraints) {
            final inline =
                constraints.maxWidth >= (filters.length > 1 ? 360 : 260);
            final field = _ScoreDetailsSearchField(
              value: query,
              onChanged: onQueryChanged,
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    _ScoreDetailsSearchButton(
                      active: searchOpen,
                      onPressed: onSearchToggle,
                    ),
                    if (searchOpen && inline) ...[
                      const SizedBox(width: 8),
                      Expanded(child: field),
                    ] else
                      const Spacer(),
                    if (filters.length > 1) ...[
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 150,
                        child: EcjtuSelectBox<String>(
                          value: selectedFilter,
                          items: filters,
                          labelBuilder: _filterLabel,
                          onChanged: onFilterChanged,
                          fontSize: filterFontSize,
                        ),
                      ),
                    ],
                  ],
                ),
                if (searchOpen && !inline) ...[
                  const SizedBox(height: 10),
                  field,
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  String _filterLabel(String value) {
    if (value == 'all') return '全部成绩';
    if (value.startsWith('year:')) return '${value.substring(5)} 学年';
    return value;
  }
}

class _ScoreDetailsSearchButton extends StatelessWidget {
  const _ScoreDetailsSearchButton({
    required this.active,
    required this.onPressed,
  });

  final bool active;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final normalBackground = EcjtuColors.surfaceFrom(
      context,
      (dark ? const Color(0xFF16263D) : const Color(0xFFF2F8FC)),
    );
    final activeBackground = EcjtuColors.hoverFrom(
      context,
      (dark ? const Color(0xFF1B3553) : const Color(0xFFE4F1F8)),
    );
    final normalBorder = EcjtuColors.borderFrom(
      context,
      (dark ? const Color(0xFF3B5878) : const Color(0xFFA9C9DC)),
    );
    final activeBorder = dark
        ? const Color(0xFF5CA7E8)
        : const Color(0xFF287AA8);
    final foreground = EcjtuColors.textFrom(
      context,
      dark ? const Color(0xFFD9EBFF) : const Color(0xFF275B7A),
    );
    return SizedBox(
      width: 34,
      height: 34,
      child: IconButton(
        tooltip: '搜索课程',
        onPressed: onPressed,
        icon: EcjtuIcon('smart_work_search.svg', size: 16, color: foreground),
        padding: EdgeInsets.zero,
        style: ButtonStyle(
          fixedSize: const WidgetStatePropertyAll(Size(34, 34)),
          minimumSize: const WidgetStatePropertyAll(Size(34, 34)),
          padding: const WidgetStatePropertyAll(EdgeInsets.zero),
          foregroundColor: WidgetStatePropertyAll(foreground),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.hovered) || active
                ? activeBackground
                : normalBackground,
          ),
          side: WidgetStateProperty.resolveWith(
            (states) => BorderSide(
              color: states.contains(WidgetState.hovered) || active
                  ? activeBorder
                  : normalBorder,
            ),
          ),
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(7)),
            ),
          ),
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}

class _ScoreDetailsSearchField extends StatefulWidget {
  const _ScoreDetailsSearchField({
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  State<_ScoreDetailsSearchField> createState() =>
      _ScoreDetailsSearchFieldState();
}

class _ScoreDetailsSearchFieldState extends State<_ScoreDetailsSearchField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value,
  );

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onEditingChanged);
  }

  void _onEditingChanged() {
    final editing = _controller.value;
    if (editing.composing.isValid && !editing.composing.isCollapsed) {
      final composing = editing.composing.textInside(editing.text);
      if (RegExp(r'^[a-zA-Z\s]+$').hasMatch(composing)) return;
    }
    if (editing.text != widget.value) widget.onChanged(editing.text);
  }

  @override
  void didUpdateWidget(covariant _ScoreDetailsSearchField oldWidget) {
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 34,
      child: TextField(
        controller: _controller,
        autofocus: true,
        textAlignVertical: TextAlignVertical.center,
        scrollPadding: EdgeInsets.zero,
        style: TextStyle(
          color: EcjtuColors.textFrom(
            context,
            (EcjtuColors.textFrom(
              context,
              dark ? const Color(0xFFE1EDFF) : const Color(0xFF223549),
            )),
          ),
          fontSize: EcjtuMetrics.fontSmallFor(MediaQuery.sizeOf(context)),
          height: 1.2,
        ),
        decoration: InputDecoration(
          hintText: '搜索课程',
          constraints: const BoxConstraints.tightFor(height: 34),
          hintStyle: TextStyle(
            color: EcjtuColors.mutedFrom(
              context,
              (EcjtuColors.mutedFrom(
                context,
                dark ? const Color(0xFF9EACC3) : const Color(0xFF667B8E),
              )),
            ),
            fontSize: EcjtuMetrics.fontSmallFor(MediaQuery.sizeOf(context)),
          ),
          // Dense decoration shrinks the painted border even with a tight outer height.
          isDense: false,
          filled: true,
          fillColor: EcjtuColors.surfaceFrom(
            context,
            dark ? const Color(0xFF14263A) : Colors.white,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 11,
            vertical: 0,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(7),
            borderSide: BorderSide(
              color: dark ? const Color(0xFF426B83) : const Color(0xFFB9CFDD),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(7),
            borderSide: BorderSide(
              color: dark ? const Color(0xFF426B83) : const Color(0xFFB9CFDD),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(7),
            borderSide: BorderSide(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: .55),
              width: 2,
            ),
          ),
        ),

        contextMenuBuilder: buildEcjtuPlatformTextContextMenu,
      ),
    );
  }
}

class _ScoreDetailGroup extends StatelessWidget {
  const _ScoreDetailGroup({required this.records});

  final List<ScoreDetailRecord> records;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth <= 620
            ? 1
            : constraints.maxWidth <= 980
            ? 2
            : 3;
        const gap = 12.0;
        final cardWidth =
            (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final record in records)
              SizedBox(
                width: cardWidth,
                child: _ScoreDetailCard(record: record),
              ),
          ],
        );
      },
    );
  }
}

class _ScoreDetailCard extends StatelessWidget {
  const _ScoreDetailCard({required this.record});

  final ScoreDetailRecord record;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final titleFontSize = EcjtuMetrics.fontSmallFor(size);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fields = _fields(record);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: BoxDecoration(
        color: EcjtuColors.surfaceFor(context),
        border: Border.all(color: EcjtuColors.borderFor(context)),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            record.courseName,
            softWrap: true,
            style: TextStyle(
              color: EcjtuColors.textFrom(
                context,
                dark ? const Color(0xFFEDF4FF) : EcjtuColors.textPrimary,
              ),
              fontSize: titleFontSize,
              fontWeight: FontWeight.w700,
              fontFamily: _scoreDetailsFontFamily,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 9),
          _ScoreDetailFields(fields: fields),
        ],
      ),
    );
  }

  List<(String, String)> _fields(ScoreDetailRecord record) {
    final fields = <(String, String)>[];
    if (record.usualScore.isNotEmpty) {
      fields.add(('平时成绩', record.usualScore));
      if (record.usualWeight.isNotEmpty) {
        fields.add(('平时成绩占比', '${record.usualWeight}%'));
      }
      if (record.finalExamScore.isNotEmpty) {
        fields.add(('期末成绩', record.finalExamScore));
      }
    } else {
      fields.add(('说明', '教师未公开平时成绩'));
    }
    fields.add(('总评成绩', record.finalScore.isEmpty ? '未公布' : record.finalScore));
    return fields;
  }
}

class _ScoreDetailFields extends StatelessWidget {
  const _ScoreDetailFields({required this.fields});

  final List<(String, String)> fields;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final labelFontSize = EcjtuMetrics.fontCaptionFor(size);
    final valueFontSize = EcjtuMetrics.fontSmallFor(size);
    return LayoutBuilder(
      builder: (context, constraints) {
        const columnGap = 16.0;
        final fieldWidth = (constraints.maxWidth - columnGap) / 2;
        return Wrap(
          spacing: columnGap,
          runSpacing: 10,
          children: [
            for (final field in fields)
              SizedBox(
                width: fieldWidth,
                child: _ScoreDetailField(
                  label: field.$1,
                  value: field.$2,
                  labelFontSize: labelFontSize,
                  valueFontSize: valueFontSize,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ScoreDetailField extends StatelessWidget {
  const _ScoreDetailField({
    required this.label,
    required this.value,
    required this.labelFontSize,
    required this.valueFontSize,
  });

  final String label;
  final String value;
  final double labelFontSize;
  final double valueFontSize;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          softWrap: true,
          style: TextStyle(
            color: EcjtuColors.mutedFor(context),
            fontSize: labelFontSize,
            fontFamily: _scoreDetailsFontFamily,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          softWrap: true,
          style: TextStyle(
            color: EcjtuColors.textFrom(
              context,
              dark ? const Color(0xFFEDF4FF) : EcjtuColors.textPrimary,
            ),
            fontSize: valueFontSize,
            fontWeight: FontWeight.w700,
            fontFamily: _scoreDetailsFontFamily,
          ),
        ),
      ],
    );
  }
}

class _ScoreDetailsEmpty extends StatelessWidget {
  const _ScoreDetailsEmpty({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 76),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: EcjtuColors.mutedFrom(
              context,
              dark ? const Color(0xFFA9B8D0) : const Color(0xFF98A2B3),
            ),
            fontSize: EcjtuMetrics.fontLabelFor(MediaQuery.sizeOf(context)),
            height: 1,
          ),
        ),
      ),
    );
  }
}
