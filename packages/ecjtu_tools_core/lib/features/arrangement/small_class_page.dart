// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'package:flutter/material.dart';
import '../../theme/ecjtu_theme.dart';
import '../../widgets/ecjtu_page.dart';
import '../../widgets/ecjtu_select_box.dart';
import '../../widgets/ecjtu_text_context_menu.dart';
import '../workbench/smart_work_widgets.dart';
import 'arrangement_models.dart';
import 'small_class_models.dart';

class SmallClassPage extends StatefulWidget {
  const SmallClassPage({
    super.key,
    required this.snapshot,
    required this.onBack,
    this.currentTerm,
    this.loading = false,
    this.error,
    this.onRequest,
  });
  final ArrangementSnapshot snapshot;
  final VoidCallback onBack;
  final String? currentTerm, error;
  final bool loading;
  final VoidCallback? onRequest;
  @override
  State<SmallClassPage> createState() => _SmallClassPageState();
}

class _SmallClassPageState extends State<SmallClassPage> {
  String _term = 'all';
  String _query = '';
  @override
  void initState() {
    super.initState();
    _term = widget.currentTerm ?? 'all';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onRequest?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    final all = smallClassEntries(widget.snapshot);
    final terms = {
      ...widget.snapshot.registrationTerms,
      ...widget.snapshot.scheduleTerms,
      if (widget.currentTerm?.isNotEmpty == true) widget.currentTerm!,
    }.toList()..sort((a, b) => b.compareTo(a));
    final selected = terms.contains(_term) ? _term : 'all';
    final rows = all
        .where(
          (entry) =>
              (selected == 'all' || entry.term == selected) &&
              ('${entry.course} ${entry.code}').toLowerCase().contains(
                _query.trim().toLowerCase(),
              ),
        )
        .toList();
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SmartWorkPageHeader(
          title: '小班序号查询',
          backTitle: '返回教务工具',
          onBack: widget.onBack,
        ),
        SizedBox(height: EcjtuMetrics.pageHeaderGapFor(context)),
        Row(
          children: [
            SizedBox(
              width: 140,
              child: EcjtuSelectBox<String>(
                value: selected,
                items: ['all', ...terms],
                labelBuilder: (value) => value == 'all' ? '全部学期' : value,
                onChanged: (value) => setState(() => _term = value),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Visibility(
                visible: widget.loading,
                maintainSize: true,
                maintainState: true,
                maintainAnimation: true,
                child: const SmartWorkLoadingText(
                  message: '正在获取最新课程表',
                  maxLines: 1,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 36,
          child: TextField(
            key: const ValueKey('small-class-course-search'),
            textAlignVertical: TextAlignVertical.center,
            contextMenuBuilder: buildEcjtuPlatformTextContextMenu,
            onChanged: (value) => setState(() => _query = value),
            style: Theme.of(context).textTheme.bodyMedium,
            decoration: const InputDecoration(
              hintText: '搜索课程',
              isDense: true,
              prefixIcon: Icon(Icons.search, size: 18),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 0),
            ),
          ),
        ),
        SizedBox(height: EcjtuMetrics.pageHeaderGapFor(context)),
        if (widget.error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SmartWorkInlineMessage(message: widget.error!, error: true),
          ),
        if (rows.isEmpty && !widget.loading)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              _query.trim().isNotEmpty ? '未找到相关课程' : '暂无小班序号',
              textAlign: TextAlign.center,
            ),
          ),
        for (final item in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: EcjtuCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.course,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        item.term,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    fullSmallClassLabel(
                      full: item.full,
                      small: item.small,
                      number: item.number,
                    ),
                    contextMenuBuilder: buildEcjtuPlatformTextContextMenu,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
