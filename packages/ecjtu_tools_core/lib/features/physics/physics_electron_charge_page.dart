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
import 'physics_decimal.dart';
import 'physics_electron_charge_calculator.dart';
import 'physics_electron_charge_chart.dart';
import 'physics_electron_charge_models.dart';
import 'physics_electron_charge_pdf.dart';

part 'physics_electron_charge_widgets.dart';

typedef ElectronChargeStateLoader = Future<ElectronChargeState?> Function();
typedef ElectronChargeStateSaver =
    Future<void> Function(
      ElectronChargeState state,
      ElectronChargeCalculation calculation,
    );

class PhysicsElectronChargePage extends StatefulWidget {
  const PhysicsElectronChargePage({
    super.key,
    required this.onBack,
    required this.loadSaved,
    required this.save,
  });

  final VoidCallback onBack;
  final ElectronChargeStateLoader loadSaved;
  final ElectronChargeStateSaver save;

  @override
  State<PhysicsElectronChargePage> createState() =>
      _PhysicsElectronChargePageState();
}

class _PhysicsElectronChargePageState extends State<PhysicsElectronChargePage> {
  late ElectronChargeState _state;
  late ElectronChargeCalculation _calculation;
  bool _saving = false;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _state = ElectronChargeState.initial();
    _calculation = ElectronChargeCalculator.calculate(_state);
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
              title: '电子比荷的测量',
              backTitle: '返回计算器',
              onBack: widget.onBack,
            ),
            SizedBox(height: sectionGap),
            _ElectronFormulaBlock(dark: dark),
            SizedBox(height: sectionGap),
            _ElectronCalculatorSection(
              title: '1. 电偏转',
              dark: dark,
              child: _buildDeflectionInputs(
                section: 'electric',
                definitions: ElectronChargeDefinitions.electric,
                state: _state,
                dark: dark,
                onChanged: _changeDeflection,
              ),
            ),
            SizedBox(height: sectionGap),
            _ElectronCalculatorSection(
              title: '2. 电聚焦',
              dark: dark,
              child: _buildElectroFocusInputs(dark),
            ),
            SizedBox(height: sectionGap),
            _ElectronCalculatorSection(
              title: '3. 磁偏转',
              dark: dark,
              child: _buildDeflectionInputs(
                section: 'magnetic',
                definitions: ElectronChargeDefinitions.magnetic,
                state: _state,
                dark: dark,
                onChanged: _changeDeflection,
              ),
            ),
            SizedBox(height: sectionGap),
            _ElectronCalculatorSection(
              title: '4. 磁聚焦和荷质比的测量',
              dark: dark,
              child: _buildMagneticFocusInputs(dark),
            ),
            SizedBox(height: sectionGap),
            _ElectronCalculatorSection(
              title: '计算结果',
              dark: dark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildElectronResults(dark),
                  const SizedBox(height: 12),
                  _buildActions(dark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _changeDeflection(
    String section,
    int series,
    int row,
    String field,
    String value,
  ) {
    _changeState(
      _state.updateDeflectionPoint(
        section: section,
        series: series,
        row: row,
        field: field,
        value: value,
      ),
    );
  }

  void _changeFocus(int row, String field, String value) {
    _changeState(_state.updateFocus(row: row, field: field, value: value));
  }

  void _changeMagneticFocus(int column, String field, String value) {
    _changeState(
      _state.updateMagneticFocus(column: column, field: field, value: value),
    );
  }

  void _changeState(ElectronChargeState next) {
    setState(() {
      _state = next;
      _calculation = ElectronChargeCalculator.calculate(next);
    });
  }

  Future<void> _restore() async {
    final saved = await widget.loadSaved();
    if (!mounted || saved == null) return;
    setState(() {
      _state = saved;
      _calculation = ElectronChargeCalculator.calculate(saved);
    });
  }

  Widget _buildActions(bool dark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton(
          onPressed: _exporting ? null : _exportAllPdf,
          style: physicsSecondaryButtonStyle(context),
          child: Text(_exporting ? '正在生成' : '下载全部趋势图 PDF'),
        ),
        const SizedBox(height: 12),
        physicsSaveButton(
          context,
          saving: _saving,
          enabled: true,
          onPressed: _save,
        ),
      ],
    );
  }

  Future<void> _save() async {
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
      await ElectronChargePdfService.shareAll(_calculation);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('PDF 生成失败：$error')));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _exportChart(ElectronChargeDeflectionResult result) async {
    try {
      await ElectronChargePdfService.shareChart(result);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('PDF 生成失败：$error')));
    }
  }
}
