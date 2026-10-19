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
import 'physics_franck_hertz_calculator.dart';
import 'physics_franck_hertz_chart.dart';
import 'physics_franck_hertz_models.dart';
import 'physics_franck_hertz_pdf.dart';

part 'physics_franck_hertz_widgets.dart';

typedef FranckHertzStateLoader = Future<FranckHertzState?> Function();
typedef FranckHertzStateSaver =
    Future<void> Function(
      FranckHertzState state,
      FranckHertzCalculation calculation,
    );

class PhysicsFranckHertzPage extends StatefulWidget {
  const PhysicsFranckHertzPage({
    super.key,
    required this.onBack,
    required this.loadSaved,
    required this.save,
  });

  final VoidCallback onBack;
  final FranckHertzStateLoader loadSaved;
  final FranckHertzStateSaver save;

  @override
  State<PhysicsFranckHertzPage> createState() => _PhysicsFranckHertzPageState();
}

class _PhysicsFranckHertzPageState extends State<PhysicsFranckHertzPage> {
  late FranckHertzState _state;
  late FranckHertzCalculation _calculation;
  bool _saving = false;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _state = FranckHertzState.initial();
    _calculation = FranckHertzCalculator.calculate(_state);
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
              title: '弗兰克-赫兹实验',
              backTitle: '返回计算器',
              onBack: widget.onBack,
            ),
            SizedBox(height: sectionGap),
            _franckFormulaBlock(dark),
            SizedBox(height: sectionGap),
            _franckSection(
              title: '特征峰电压',
              dark: dark,
              child: _FranckPeakInput(
                state: _state,
                dark: dark,
                onPeakChanged: (index, value) =>
                    _changeState(_state.updatePeak(index, value)),
                onTheoryChanged: (value) =>
                    _changeState(_state.copyWith(theory: value)),
              ),
            ),
            SizedBox(height: sectionGap),
            _franckSection(
              title: '电流曲线数据',
              dark: dark,
              child: _FranckPointTable(
                state: _state,
                dark: dark,
                onChanged: (index, field, value) =>
                    _changeState(_state.updateRow(index, field, value)),
                onAddRow: () => _changeState(_state.addRow()),
              ),
            ),
            SizedBox(height: sectionGap),
            _franckSection(
              title: '计算结果',
              dark: dark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FranckResults(
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

  void _changeState(FranckHertzState next) {
    setState(() {
      _state = next;
      _calculation = FranckHertzCalculator.calculate(next);
    });
  }

  Future<void> _restore() async {
    final saved = await widget.loadSaved();
    if (!mounted || saved == null) return;
    setState(() {
      _state = saved;
      _calculation = FranckHertzCalculator.calculate(saved);
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
    setState(() => _exporting = true);
    try {
      await FranckHertzPdfService.shareAll(_calculation);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('PDF 生成失败：$error')));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _exportChart(FranckHertzChartSpec spec) async {
    try {
      await FranckHertzPdfService.shareChart(spec);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('PDF 生成失败：$error')));
    }
  }
}
