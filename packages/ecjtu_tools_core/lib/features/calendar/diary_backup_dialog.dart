// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import '../../platform/native_document_save.dart';
import 'package:ecjtu_tools_core/widgets/ecjtu_text_context_menu.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/ecjtu_widgets.dart';
import 'diary_backup.dart';
import 'diary_models.dart';
import 'diary_storage.dart';

Future<T?> requestDiaryBackupPassword<T extends Object>(
  BuildContext context, {
  required bool exporting,
  required Future<T> Function(String password) operation,
  Future<String?> Function()? defaultPasswordLoader,
}) => showEcjtuDialog<T>(
  context: context,
  barrierDismissible: false,
  builder: (_) => _DiaryPasswordDialog(
    exporting: exporting,
    defaultPasswordLoader: defaultPasswordLoader,
    operation: operation,
  ),
);

Future<String> exportDiaryBackup(
  BuildContext context,
  DiaryStorage storage,
  String account, {
  Future<String?> Function()? defaultPasswordLoader,
}) async {
  final bytes = await requestDiaryBackupPassword<Uint8List>(
    context,
    exporting: true,
    defaultPasswordLoader: defaultPasswordLoader,
    operation: (password) => DiaryBackup.export(storage, account, password),
  );
  if (bytes == null) return '';
  final name = 'diary-${diaryDateKey(DateTime.now())}.ecjdiary';
  final saved = await saveNativeDocument(bytes, name);
  return saved == null ? '' : '日记备份已导出';
}

Future<String> importDiaryBackup(
  BuildContext context,
  DiaryStorage storage,
  String account,
) async {
  final file = await openFile(
    acceptedTypeGroups: const [
      XTypeGroup(
        label: '日记备份',
        extensions: ['ecjdiary'],
        uniformTypeIdentifiers: ['public.data'],
        mimeTypes: ['application/octet-stream'],
      ),
    ],
  );
  if (file == null || !context.mounted) return '';
  if (await file.length() > DiaryBackup.maxBytes * 2) {
    throw const FormatException('备份文件过大');
  }
  final bytes = await file.readAsBytes();
  if (!context.mounted) return '';
  final data = await requestDiaryBackupPassword<DiaryBackupData>(
    context,
    exporting: false,
    operation: (password) => DiaryBackup.open(bytes, password),
  );
  if (data == null || !context.mounted) return '';
  final existing = await storage.readAll(account);
  if (!context.mounted) return '';
  final overlap = data.entries
      .where((entry) => existing.containsKey(entry.date))
      .length;
  var replace = false;
  final confirmed = await showEcjtuDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => EcjtuDialog(
        title: const Text('恢复日记'),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('备份包含 ${data.entries.length} 篇日记和 ${data.assets.length} 张图片。'),
            if (overlap > 0) ...[
              const SizedBox(height: 16),
              Text('其中 $overlap 篇与本机日记日期相同'),
              const SizedBox(height: 10),
              EcjtuSelectBox<bool>(
                value: replace,
                items: const [false, true],
                labelBuilder: (value) => value ? '相同日期使用备份日记' : '相同日期保留本机日记',
                onChanged: (value) => setState(() => replace = value),
              ),
            ],
          ],
        ),
        actions: [
          EcjtuDialogAction(
            label: '取消',
            onPressed: () => Navigator.pop(context, false),
          ),
          EcjtuDialogAction(
            label: '恢复',
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    ),
  );
  if (confirmed != true) return '';
  await DiaryBackup.restore(storage, account, data, replaceExisting: replace);
  return '日记已恢复';
}

class _DiaryPasswordDialog extends StatefulWidget {
  const _DiaryPasswordDialog({
    required this.exporting,
    required this.operation,
    this.defaultPasswordLoader,
  });
  final bool exporting;
  final Future<Object> Function(String password) operation;
  final Future<String?> Function()? defaultPasswordLoader;
  @override
  State<_DiaryPasswordDialog> createState() => _DiaryPasswordDialogState();
}

class _DiaryPasswordDialogState extends State<_DiaryPasswordDialog> {
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _busy = false;
  bool _customPassword = false, _needsDefaultInput = false;
  String? _error;
  @override
  void dispose() {
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    if (widget.exporting &&
        _customPassword &&
        _password.text != _confirmation.text) {
      setState(() => _error = '两次输入的密码不一致');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      var password = _password.text;
      if (widget.exporting && !_customPassword && !_needsDefaultInput) {
        password = await widget.defaultPasswordLoader?.call() ?? '';
        if (password.trim().isEmpty) {
          if (mounted)
            setState(() {
              _needsDefaultInput = true;
              _busy = false;
              _error = '请输入智慧交大密码';
            });
          return;
        }
      }
      if (password.trim().isEmpty || password.length > 1024) {
        throw const FormatException('请输入有效的备份密码');
      }
      final result = await widget.operation(password);
      if (mounted) Navigator.pop(context, result);
    } catch (error) {
      if (mounted)
        setState(() {
          _busy = false;
          _error = error.toString().replaceFirst('FormatException: ', '');
        });
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: EcjtuDialog(
      title: Text(widget.exporting ? '备份日记' : '打开日记备份'),
      showCloseButton: !_busy,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.exporting) ...[
            const Text('备份包含日记和图片。请妥善保存密码，忘记密码将无法恢复。'),
            const SizedBox(height: 16),
            EcjtuSelectBox<bool>(
              value: _customPassword,
              items: const [false, true],
              labelBuilder: (value) => value ? '自定义密码' : '智慧交大密码',
              enabled: !_busy,
              onChanged: (value) => setState(() {
                _customPassword = value;
                _password.clear();
                _confirmation.clear();
                _error = null;
              }),
            ),
            const SizedBox(height: 16),
            if (!_customPassword && !_needsDefaultInput)
              const Text('使用本机保存的智慧交大密码加密。恢复时请输入导出时使用的密码。'),
          ],
          if (!widget.exporting || _customPassword || _needsDefaultInput)
            TextField(
              controller: _password,
              obscureText: true,
              enabled: !_busy,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                labelText: widget.exporting && !_customPassword
                    ? '智慧交大密码'
                    : '备份密码',
              ),
              onSubmitted: (_) {
                if (!widget.exporting) _submit();
              },

              contextMenuBuilder: buildEcjtuPlatformTextContextMenu,
            ),
          if (widget.exporting && _customPassword) ...[
            const SizedBox(height: 14),
            TextField(
              controller: _confirmation,
              obscureText: true,
              enabled: !_busy,
              autocorrect: false,
              enableSuggestions: false,
              decoration: const InputDecoration(labelText: '再次输入密码'),
              onSubmitted: (_) => _submit(),

              contextMenuBuilder: buildEcjtuPlatformTextContextMenu,
            ),
          ],
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          if (_busy)
            const Padding(
              padding: EdgeInsets.only(top: 18),
              child: LinearProgressIndicator(),
            ),
        ],
      ),
      actions: [
        EcjtuDialogAction(
          label: '取消',
          onPressed: _busy ? null : () => Navigator.pop(context),
        ),
        EcjtuDialogAction(
          label: widget.exporting ? '导出' : '打开',
          onPressed: _busy ? null : _submit,
        ),
      ],
    ),
  );
}
