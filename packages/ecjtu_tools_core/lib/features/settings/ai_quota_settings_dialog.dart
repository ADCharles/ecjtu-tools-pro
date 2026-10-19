// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'package:ecjtu_tools_core/widgets/ecjtu_text_context_menu.dart';
import 'package:flutter/material.dart';

import '../../app/app_edition.dart';
import '../../widgets/ecjtu_widgets.dart';
import '../ai/ai_network_quota.dart';
import '../ai/ai_network_limits_store.dart';
import '../ai/ai_network_quota_storage.dart';

class AiQuotaSettingsDialog extends StatefulWidget {
  const AiQuotaSettingsDialog({super.key, this.store});
  final AiNetworkLimitsStore? store;
  @override
  State<AiQuotaSettingsDialog> createState() => _AiQuotaSettingsDialogState();
}

class _AiQuotaSettingsDialogState extends State<AiQuotaSettingsDialog> {
  late final _store = widget.store ?? AiNetworkLimitsStore();
  final _perFeature = TextEditingController();
  final _total = TextEditingController();
  final _requests = TextEditingController();
  final _totalRequests = TextEditingController();
  bool _loading = true, _saving = false;
  String? _error;
  int _used = 0;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final limits = await _store.read();
      final quota = await createAiNetworkQuota(store: _store);
      final stats = await quota.snapshot();
      if (!mounted) return;
      _perFeature.text = '${limits.operationsPerFeature}';
      _total.text = '${limits.operationsTotal}';
      _requests.text = '${limits.requestsPerTicket}';
      _totalRequests.text = '${limits.requestsTotal}';
      _used = stats['operationsUsed'] as int;
    } catch (_) {
      _error = '限额暂时无法读取';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (!AppEdition.isDevelopment || _saving) return;
    final numbers = [
      _perFeature,
      _total,
      _requests,
      _totalRequests,
    ].map((c) => int.tryParse(c.text)).toList();
    if (numbers.any((n) => n == null || n < 1 || n > 1000000)) {
      setState(() => _error = '请输入 1 至 1000000 的整数');
      return;
    }
    setState(() => _saving = true);
    try {
      await _store.write(
        AiNetworkLimits(
          operationsPerFeature: numbers[0]!,
          operationsTotal: numbers[1]!,
          requestsPerTicket: numbers[2]!,
          requestsTotal: numbers[3]!,
        ),
      );
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) setState(() => _error = '限额保存失败');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    for (final c in [_perFeature, _total, _requests, _totalRequests]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => EcjtuDialog(
    title: const Text('AI 网络限额'),
    maxWidth: 560,
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_loading)
          const Text('正在读取限额…')
        else ...[
          Text('过去 30 分钟已使用 $_used 次网络操作'),
          const SizedBox(height: 16),
          for (final pair in [
            (_perFeature, '每项功能 / 30 分钟'),
            (_total, '全部功能 / 30 分钟'),
            (_requests, '单次操作请求数'),
            (_totalRequests, '全部请求 / 30 分钟'),
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextField(
                controller: pair.$1,
                enabled: !_saving,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: pair.$2),

                contextMenuBuilder: buildEcjtuPlatformTextContextMenu,
              ),
            ),
        ],
        if (_error != null) Text(_error!),
      ],
    ),
    actions: [
      EcjtuDialogAction(
        label: '取消',
        onPressed: _saving ? null : () => Navigator.pop(context),
      ),
      EcjtuDialogAction(
        label: _saving ? '正在保存…' : '保存',
        onPressed: _loading || _saving ? null : _save,
      ),
    ],
  );
}
