// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'package:ecjtu_tools_core/widgets/ecjtu_text_context_menu.dart';
import 'package:flutter/material.dart';
import '../../widgets/ecjtu_dialog.dart';
import 'arrangement_controls.dart';
import '../workbench/smart_work_widgets.dart';

class ClassScheduleDetailsDialog extends StatefulWidget {
  const ClassScheduleDetailsDialog({
    required this.title,
    required this.details,
    required this.cardBuilder,
  });
  final String title;
  final Future<List<Map<String, dynamic>>> details;
  final Widget Function(Map<String, dynamic>) cardBuilder;
  @override
  State<ClassScheduleDetailsDialog> createState() =>
      ClassScheduleDetailsDialogState();
}

class ClassScheduleDetailsDialogState
    extends State<ClassScheduleDetailsDialog> {
  final _search = TextEditingController();
  String _keyword = '';
  void _applySearch() =>
      setState(() => _keyword = _search.text.trim().toLowerCase());
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => EcjtuDialog(
    maxWidth: 780,
    title: Text(
      widget.title,
      style: TextStyle(
        fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
        fontFamilyFallback: Theme.of(
          context,
        ).textTheme.bodyMedium?.fontFamilyFallback,
      ),
    ),
    content: SizedBox(
      width: 720,
      height: MediaQuery.sizeOf(context).height * .6,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _search,
                  style: Theme.of(context).textTheme.bodyMedium,
                  decoration: const InputDecoration(
                    hintText: '搜索',
                    isDense: true,
                  ),
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _applySearch(),

                  contextMenuBuilder: buildEcjtuPlatformTextContextMenu,
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 72,
                child: ArrangementActionButton(
                  label: '搜索',
                  onPressed: _applySearch,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: widget.details,
              builder: (context, snapshot) {
                if (snapshot.hasError) return Text('${snapshot.error}');
                if (!snapshot.hasData)
                  return const SmartWorkLoading(message: '正在读取课表详情');
                final tokens = _keyword
                    .split(RegExp(r'\s+'))
                    .where((word) => word.isNotEmpty);
                final items = snapshot.data!.where((item) {
                  final text = item.values.join(' ').toLowerCase();
                  return tokens.every(text.contains);
                }).toList();
                if (items.isEmpty) return const Center(child: Text('暂无课程详情'));
                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (_, index) => DefaultTextStyle.merge(
                    style: Theme.of(context).textTheme.bodyMedium!,
                    child: widget.cardBuilder(items[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ),
    actions: [
      SizedBox(
        width: 80,
        child: ArrangementActionButton(
          label: '关闭',
          onPressed: () => Navigator.pop(context),
        ),
      ),
    ],
  );
}
