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
import 'physics_voltage_current_calculator.dart';
import 'physics_voltage_current_chart.dart';
import 'physics_voltage_current_models.dart';
import 'physics_voltage_current_pdf.dart';

part 'physics_voltage_current_widgets.dart';

typedef VoltageCurrentStateLoader = Future<VoltageCurrentState?> Function();
typedef VoltageCurrentStateSaver =
    Future<void> Function(
      VoltageCurrentState state,
      VoltageCurrentCalculation calculation,
    );
typedef VoltageCurrentChartExporter =
    Future<void> Function(
      String title,
      List<VoltageCurrentChartPoint> points,
      String colorHex,
    );

class PhysicsVoltageCurrentPage extends StatefulWidget {
  const PhysicsVoltageCurrentPage({
    super.key,
    required this.onBack,
    required this.loadSaved,
    required this.save,
  });

  final VoidCallback onBack;
  final VoltageCurrentStateLoader loadSaved;
  final VoltageCurrentStateSaver save;

  @override
  State<PhysicsVoltageCurrentPage> createState() =>
      _PhysicsVoltageCurrentPageState();
}

class _PhysicsVoltageCurrentPageState extends State<PhysicsVoltageCurrentPage> {
  late VoltageCurrentState _state;
  late VoltageCurrentCalculation _calculation;
  bool _saving = false;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _state = VoltageCurrentState.initial();
    _calculation = VoltageCurrentCalculator.calculate(_state);
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
              title: '电学元件伏安特性的研究',
              backTitle: '返回计算器',
              onBack: widget.onBack,
            ),
            SizedBox(height: sectionGap),
            _voltageCurrentFormulaBlock(dark),
            SizedBox(height: sectionGap),
            _buildInstrumentSection(dark),
            SizedBox(height: sectionGap),
            for (var index = 0; index < _state.blocks.length; index++) ...[
              _buildBlockSection(index, dark),
              SizedBox(height: sectionGap),
            ],
            _buildDiodeSection(dark),
            SizedBox(height: sectionGap),
            _buildResultsSection(dark),
          ],
        ),
      ),
    );
  }

  Widget _buildInstrumentSection(bool dark) {
    return _voltageCurrentSection(
      dark: dark,
      title: '仪表参数',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = MediaQuery.sizeOf(context).width <= 480 ? 1 : 2;
          final gap = 10.0;
          final availableWidth = constraints.maxWidth < 430
              ? constraints.maxWidth
              : 430.0;
          final width = columns == 1
              ? availableWidth
              : (availableWidth - gap) / columns;
          return SizedBox(
            width: availableWidth,
            child: Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                SizedBox(
                  width: width,
                  child: _VoltageCurrentLabeledInput(
                    prefix: '电压表级别 ',
                    formula: r'k_1',
                    value: _state.instrument.voltageGrade,
                    label: '电压表级别',
                    dark: dark,
                    onChanged: (value) => _changeState(
                      _state.updateInstrument('voltageGrade', value),
                    ),
                  ),
                ),
                SizedBox(
                  width: width,
                  child: _VoltageCurrentLabeledInput(
                    prefix: '电流表级别 ',
                    formula: r'k_2',
                    value: _state.instrument.currentGrade,
                    label: '电流表级别',
                    dark: dark,
                    onChanged: (value) => _changeState(
                      _state.updateInstrument('currentGrade', value),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBlockSection(int index, bool dark) {
    final block = _state.blocks[index];
    return _voltageCurrentSection(
      dark: dark,
      title: '${block.resistance} Ω 电阻 · 电流表${block.connection}法',
      child: _VoltageCurrentBlockInput(
        block: block,
        blockIndex: index,
        dark: dark,
        onParameterChanged: (field, value) =>
            _changeState(_state.updateBlockParameter(index, field, value)),
        onPointChanged: (point, field, value) =>
            _changeState(_state.updatePoint(index, point, field, value)),
      ),
    );
  }

  Widget _buildDiodeSection(bool dark) {
    return _voltageCurrentSection(
      dark: dark,
      title: '半导体二极管正向伏安特性',
      child: _VoltageCurrentDiodeInput(
        points: _state.diode,
        dark: dark,
        onChanged: (index, field, value) =>
            _changeState(_state.updateDiode(index, field, value)),
        onAdd: () => _changeState(
          _state.copyWith(
            diode: [..._state.diode, const VoltageCurrentPointInput()],
          ),
        ),
        onRemove: _state.diode.length > 2
            ? () => _changeState(
                _state.copyWith(
                  diode: _state.diode.sublist(0, _state.diode.length - 1),
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildResultsSection(bool dark) {
    return _voltageCurrentSection(
      dark: dark,
      title: '计算结果',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _voltageCurrentLinearResults(calculation: _calculation, dark: dark),
          SizedBox(height: EcjtuMetrics.pageHeaderGapFor(context)),
          _voltageCurrentDiodeResults(_calculation.diode, dark),
          const SizedBox(height: 18),
          _voltageCurrentCharts(
            calculation: _calculation,
            dark: dark,
            onExport: _exportChart,
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OutlinedButton(
                onPressed: _exporting ? null : _exportAllPdf,
                style: physicsSecondaryButtonStyle(context),
                child: Text(_exporting ? '正在生成' : '下载全部图 PDF'),
              ),
              const SizedBox(height: 12),
              physicsSaveButton(
                context,
                saving: _saving,
                enabled: true,
                onPressed: _save,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _changeState(VoltageCurrentState next) {
    setState(() {
      _state = next;
      _calculation = VoltageCurrentCalculator.calculate(next);
    });
  }

  Future<void> _restore() async {
    final saved = await widget.loadSaved();
    if (!mounted || saved == null) return;
    setState(() {
      _state = saved;
      _calculation = VoltageCurrentCalculator.calculate(saved);
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
      await VoltageCurrentPdfService.shareAll(_calculation);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('PDF 生成失败：$error')));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _exportChart(
    String title,
    List<VoltageCurrentChartPoint> points,
    String colorHex,
  ) async {
    try {
      await VoltageCurrentPdfService.shareChart(
        title: title,
        points: points,
        colorHex: colorHex,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('PDF 生成失败：$error')));
    }
  }
}
