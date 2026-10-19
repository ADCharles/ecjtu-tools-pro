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
import 'physics_hall_effect_calculator.dart';
import 'physics_hall_effect_chart.dart';
import 'physics_hall_effect_models.dart';
import 'physics_hall_effect_pdf.dart';

part 'physics_hall_effect_widgets.dart';

typedef HallEffectStateLoader = Future<HallEffectState?> Function();
typedef HallEffectStateSaver =
    Future<void> Function(
      HallEffectState state,
      HallEffectCalculation calculation,
    );

class PhysicsHallEffectPage extends StatefulWidget {
  const PhysicsHallEffectPage({
    super.key,
    required this.onBack,
    required this.loadSaved,
    required this.save,
  });

  final VoidCallback onBack;
  final HallEffectStateLoader loadSaved;
  final HallEffectStateSaver save;

  @override
  State<PhysicsHallEffectPage> createState() => _PhysicsHallEffectPageState();
}

class _PhysicsHallEffectPageState extends State<PhysicsHallEffectPage> {
  late HallEffectState _state;
  late HallEffectCalculation _calculation;
  bool _saving = false;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _state = HallEffectState.initial();
    _calculation = HallEffectCalculator.calculate(_state);
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
              title: '霍尔效应测磁场',
              backTitle: '返回计算器',
              onBack: widget.onBack,
            ),
            SizedBox(height: sectionGap),
            _hallFormulaBlock(dark),
            SizedBox(height: sectionGap),
            _buildSolenoid(dark),
            SizedBox(height: sectionGap),
            for (var index = 0; index < _state.coils.length; index++) ...[
              _buildCoil(index, dark),
              SizedBox(height: sectionGap),
            ],
            _hallSection(
              title: '计算结果',
              dark: dark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HallResults(
                    calculation: _calculation,
                    radii: _state.coils.map((coil) => coil.radius).toList(),
                    dark: dark,
                    onExportChart: _exportChart,
                  ),
                  SizedBox(height: sectionGap),
                  Wrap(
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
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSolenoid(bool dark) {
    return _hallSection(
      title: '直螺线管',
      dark: dark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HallParameterGrid(
            dark: dark,
            fields: [
              _HallParameterField(
                prefix: '励磁电流 ',
                formula: r'I_s\,/\,\mathrm{mA}',
                value: _state.solenoid.current,
                label: '直螺线管励磁电流',
                onChanged: (value) => _changeState(
                  _state.updateSolenoidParameter('current', value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _HallSolenoidInputTable(
            state: _state.solenoid,
            dark: dark,
            onChanged: (row, field, value) =>
                _changeState(_state.updateSolenoidRow(row, field, value)),
          ),
        ],
      ),
    );
  }

  Widget _buildCoil(int index, bool dark) {
    final coil = _state.coils[index];
    return _hallSection(
      title: '载流圆线圈 a = ${coil.radius} cm',
      dark: dark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HallParameterGrid(
            dark: dark,
            fields: [
              _HallParameterField(
                prefix: '线圈半径 ',
                formula: r'a\,/\,\mathrm{cm}',
                value: coil.radius,
                label: '线圈半径',
                onChanged: (value) => _changeState(
                  _state.updateCoilParameter(index, 'radius', value),
                ),
              ),
              _HallParameterField(
                prefix: '线圈 A 电流 ',
                formula: r'I_{s,a}\,/\,\mathrm{mA}',
                value: coil.currents.a,
                label: '线圈 A 电流',
                onChanged: (value) => _changeState(
                  _state.updateCoilParameter(index, 'currentA', value),
                ),
              ),
              _HallParameterField(
                prefix: '线圈 B 电流 ',
                formula: r'I_{s,b}\,/\,\mathrm{mA}',
                value: coil.currents.b,
                label: '线圈 B 电流',
                onChanged: (value) => _changeState(
                  _state.updateCoilParameter(index, 'currentB', value),
                ),
              ),
              _HallParameterField(
                prefix: '合成线圈电流 ',
                formula: r'I_{s,a+b}\,/\,\mathrm{mA}',
                value: coil.currents.combined,
                label: '合成线圈电流',
                onChanged: (value) => _changeState(
                  _state.updateCoilParameter(index, 'currentCombined', value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _HallCoilInputTable(
            coil: coil,
            coilIndex: index,
            dark: dark,
            onChanged: (row, group, field, value) => _changeState(
              _state.updateCoilRow(index, row, group, field, value),
            ),
          ),
        ],
      ),
    );
  }

  void _changeState(HallEffectState next) {
    setState(() {
      _state = next;
      _calculation = HallEffectCalculator.calculate(next);
    });
  }

  Future<void> _restore() async {
    final saved = await widget.loadSaved();
    if (!mounted || saved == null) return;
    setState(() {
      _state = saved;
      _calculation = HallEffectCalculator.calculate(saved);
    });
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
      await HallEffectPdfService.shareAll(
        _calculation,
        _state.coils.map((coil) => coil.radius).toList(growable: false),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('PDF 生成失败：$error')));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _exportChart(HallEffectChartSpec spec) async {
    try {
      await HallEffectPdfService.shareChart(spec);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('PDF 生成失败：$error')));
    }
  }
}
