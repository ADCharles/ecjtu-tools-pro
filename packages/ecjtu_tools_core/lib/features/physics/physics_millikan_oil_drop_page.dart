// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'package:ecjtu_tools_core/widgets/ecjtu_text_context_menu.dart';
import 'package:flutter/material.dart';
import 'physics_shared_styles.dart';
import 'package:flutter_math_fork/flutter_math.dart';

import '../../theme/ecjtu_theme.dart';
import '../../widgets/ecjtu_page.dart';
import '../workbench/smart_work_widgets.dart';
import 'physics_millikan_oil_drop_calculator.dart';
import 'physics_millikan_oil_drop_chart.dart';
import 'physics_millikan_oil_drop_models.dart';
import 'physics_millikan_oil_drop_pdf.dart';

part 'physics_millikan_oil_drop_widgets.dart';

typedef MillikanStateLoader = Future<MillikanState?> Function();
typedef MillikanStateSaver =
    Future<void> Function(MillikanState state, MillikanCalculation calculation);

class PhysicsMillikanOilDropPage extends StatefulWidget {
  const PhysicsMillikanOilDropPage({
    super.key,
    required this.onBack,
    required this.loadSaved,
    required this.save,
  });

  final VoidCallback onBack;
  final MillikanStateLoader loadSaved;
  final MillikanStateSaver save;

  @override
  State<PhysicsMillikanOilDropPage> createState() =>
      _PhysicsMillikanOilDropPageState();
}

class _PhysicsMillikanOilDropPageState
    extends State<PhysicsMillikanOilDropPage> {
  late MillikanState _state;
  late MillikanCalculation _calculation;
  bool _saving = false;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _state = MillikanState.initial();
    _calculation = MillikanCalculator.calculate(_state);
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
              title: '密立根油滴实验',
              backTitle: '返回计算器',
              onBack: widget.onBack,
            ),
            SizedBox(height: sectionGap),
            _millikanFormulaBlock(dark),
            SizedBox(height: sectionGap),
            _millikanSection(
              title: '装置参数',
              dark: dark,
              child: _MillikanConstantsInput(
                constants: _state.constants,
                dark: dark,
                onChanged: (field, value) =>
                    _changeState(_state.updateConstant(field, value)),
              ),
            ),
            for (var index = 0; index < _state.groups.length; index++) ...[
              SizedBox(height: sectionGap),
              _millikanSection(
                title: '第 ${index + 1} 组',
                dark: dark,
                child: _MillikanGroupInput(
                  group: _state.groups[index],
                  groupIndex: index,
                  dark: dark,
                  onVoltageChanged: (value) =>
                      _changeState(_state.updateVoltage(index, value)),
                  onTimeChanged: (timeIndex, value) =>
                      _changeState(_state.updateTime(index, timeIndex, value)),
                ),
              ),
            ],
            SizedBox(height: sectionGap),
            _millikanSection(
              title: '计算结果',
              dark: dark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _MillikanResults(
                    calculation: _calculation,
                    dark: dark,
                    onExportChart: _exportChart,
                  ),
                  SizedBox(height: sectionGap),
                  _buildActions(dark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(bool dark) {
    return Wrap(
      spacing: 9,
      runSpacing: 8,
      children: [
        OutlinedButton(
          onPressed: _exporting ? null : _exportAllPdf,
          child: Text(_exporting ? '正在生成' : '下载全部图 PDF'),
          style: physicsSecondaryButtonStyle(context),
        ),
        physicsSaveButton(
          context,
          saving: _saving,
          enabled: true,
          onPressed: _save,
          alignLeft: false,
        ),
      ],
    );
  }

  void _changeState(MillikanState next) {
    setState(() {
      _state = next;
      _calculation = MillikanCalculator.calculate(next);
    });
  }

  Future<void> _restore() async {
    final saved = await widget.loadSaved();
    if (!mounted || saved == null) return;
    setState(() {
      _state = saved;
      _calculation = MillikanCalculator.calculate(saved);
    });
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

  Future<void> _exportAllPdf() async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      await MillikanOilDropPdfService.shareAll(_calculation);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('PDF 生成失败：$error')));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _exportChart(MillikanChartSpec spec) async {
    try {
      await MillikanOilDropPdfService.shareChart(spec);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('PDF 生成失败：$error')));
    }
  }
}
