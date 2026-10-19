// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'package:ecjtu_tools_core/widgets/ecjtu_text_context_menu.dart';
import '../../widgets/ecjtu_pane_surface.dart';
import 'package:flutter/material.dart';
import 'physics_shared_styles.dart';
import 'package:flutter/services.dart';
import 'package:flutter_math_fork/flutter_math.dart';

import '../../theme/ecjtu_theme.dart';
import '../../widgets/ecjtu_page.dart';
import '../workbench/smart_work_widgets.dart';
import 'physics_potential_difference_calculator.dart';
import 'physics_potential_difference_chart.dart';
import 'physics_potential_difference_models.dart';
import 'physics_potential_difference_pdf.dart';

part 'physics_potential_difference_widgets.dart';

typedef PotentialDifferenceStateLoader =
    Future<PotentialDifferenceState?> Function();
typedef PotentialDifferenceStateSaver =
    Future<void> Function(
      PotentialDifferenceState state,
      PotentialDifferenceCalculation calculation,
    );

class PhysicsPotentialDifferencePage extends StatefulWidget {
  const PhysicsPotentialDifferencePage({
    super.key,
    required this.onBack,
    required this.loadSaved,
    required this.save,
  });

  final VoidCallback onBack;
  final PotentialDifferenceStateLoader loadSaved;
  final PotentialDifferenceStateSaver save;

  @override
  State<PhysicsPotentialDifferencePage> createState() =>
      _PhysicsPotentialDifferencePageState();
}

class _PhysicsPotentialDifferencePageState
    extends State<PhysicsPotentialDifferencePage> {
  late PotentialDifferenceState _state;
  late PotentialDifferenceCalculation _calculation;
  bool _saving = false;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _state = PotentialDifferenceState.initial();
    _calculation = PotentialDifferenceCalculator.calculate(_state);
    _restore();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final compact = EcjtuMetrics.isCompact(MediaQuery.sizeOf(context));
    final sectionGap = compact ? 14.0 : 18.0;
    return EcjtuPageColumn(
      contentFrameMaxWidth: 1580,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1580),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SmartWorkPageHeader(
              title: '电位差计的原理和使用',
              backTitle: '返回计算器',
              onBack: widget.onBack,
            ),
            SizedBox(height: sectionGap),
            _potentialFormulaBlock(dark),
            SizedBox(height: sectionGap),
            _potentialSection(
              title: '输入数据',
              dark: dark,
              child: _PotentialInputContent(
                state: _state,
                dark: dark,
                onResistanceChanged: (value) =>
                    _changeState(_state.copyWith(resistance: value)),
                onUncertaintyChanged: (value) =>
                    _changeState(_state.copyWith(uncertainty: value)),
                onRowChanged: (index, field, value) =>
                    _changeState(_state.updateRow(index, field, value)),
                onPaste: _showPasteDialog,
              ),
            ),
            SizedBox(height: sectionGap),
            _potentialSection(
              title: '计算结果',
              dark: dark,
              child: _PotentialOutputContent(
                calculation: _calculation,
                dark: dark,
                onExport: _exportChart,
                onSave: _save,
                exporting: _exporting,
                saving: _saving,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _changeState(PotentialDifferenceState next) {
    setState(() {
      _state = next;
      _calculation = PotentialDifferenceCalculator.calculate(next);
    });
  }

  Future<void> _restore() async {
    final saved = await widget.loadSaved();
    if (!mounted || saved == null) return;
    setState(() {
      _state = saved;
      _calculation = PotentialDifferenceCalculator.calculate(saved);
    });
  }

  Future<void> _showPasteDialog() async {
    final clipboard = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted) return;
    final controller = TextEditingController(text: clipboard?.text ?? '');
    try {
      final text = await showDialog<String>(
        context: context,
        useRootNavigator: !EcjtuPaneDialogScope.contains(context),
        builder: (context) => EcjtuDialog(
          title: const Text('一键识别电位差计数据'),
          content: SizedBox(
            width: 560,
            child: TextField(
              controller: controller,
              autofocus: true,
              minLines: 5,
              maxLines: 9,
              keyboardType: TextInputType.multiline,
              decoration: const InputDecoration(
                hintText: '三行数据，每行 8 个数字，列之间用 Tab 或空格分隔',
                alignLabelWithHint: true,
              ),

              contextMenuBuilder: buildEcjtuPlatformTextContextMenu,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('识别'),
            ),
          ],
        ),
      );
      if (!mounted || text == null) return;
      final rows = PotentialDifferenceCalculator.parsePaste(text);
      if (rows == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请确保粘贴的是 3 行、每行 8 个数字的数据')),
        );
        return;
      }
      _changeState(_state.copyWith(rows: rows));
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('数据已填入')));
    } finally {
      controller.dispose();
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await widget.save(_state, _calculation);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('数据已保存')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('保存失败：$error')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _exportChart() async {
    if (_exporting) return;
    final points = potentialDifferenceChartPoints(_calculation);
    setState(() => _exporting = true);
    try {
      await PotentialDifferencePdfService.shareChart(points);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('PDF 生成失败：$error')));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }
}
