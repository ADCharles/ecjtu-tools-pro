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
import 'physics_electrostatic_field_calculator.dart';
import 'physics_electrostatic_field_chart.dart';
import 'physics_electrostatic_field_models.dart';
import 'physics_electrostatic_field_pdf.dart';

part 'physics_electrostatic_field_widgets.dart';

typedef ElectrostaticFieldStateLoader =
    Future<ElectrostaticFieldState?> Function();
typedef ElectrostaticFieldStateSaver =
    Future<void> Function(
      ElectrostaticFieldState state,
      ElectrostaticFieldCalculation calculation,
    );

class PhysicsElectrostaticFieldPage extends StatefulWidget {
  const PhysicsElectrostaticFieldPage({
    super.key,
    required this.onBack,
    required this.loadSaved,
    required this.save,
  });

  final VoidCallback onBack;
  final ElectrostaticFieldStateLoader loadSaved;
  final ElectrostaticFieldStateSaver save;

  @override
  State<PhysicsElectrostaticFieldPage> createState() =>
      _PhysicsElectrostaticFieldPageState();
}

class _PhysicsElectrostaticFieldPageState
    extends State<PhysicsElectrostaticFieldPage> {
  late ElectrostaticFieldState _state;
  late ElectrostaticFieldCalculation _calculation;
  bool _saving = false;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _state = ElectrostaticFieldState.initial();
    _calculation = ElectrostaticFieldCalculator.calculate(_state);
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
              title: '静电场的描绘',
              backTitle: '返回计算器',
              onBack: widget.onBack,
            ),
            SizedBox(height: sectionGap),
            _ElectrostaticFormulaBlock(dark: dark),
            SizedBox(height: sectionGap),
            _buildParameterSection(dark),
            SizedBox(height: sectionGap),
            _buildCoaxialSection(dark),
            SizedBox(height: sectionGap),
            _buildParallelSection(dark),
            SizedBox(height: sectionGap),
            _buildResultsSection(dark),
          ],
        ),
      ),
    );
  }

  Widget _buildParameterSection(bool dark) {
    return _electrostaticSection(
      dark: dark,
      title: Text('实验参数', style: _electrostaticSectionTitleStyle(dark)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth <= 700 ? 1 : 3;
          final gap = 10.0;
          final width = columns == 1
              ? constraints.maxWidth
              : (constraints.maxWidth - gap * (columns - 1)) / columns;
          final fields = [
            (
              '电源电压 ',
              r'U_a\,/\,\mathrm{V}',
              'voltage',
              _state.parameters.voltage,
              '12',
            ),
            (
              '内电极半径 ',
              r'r_a\,/\,\mathrm{mm}',
              'innerRadius',
              _state.parameters.innerRadius,
              '5',
            ),
            (
              '外电极半径 ',
              r'r_b\,/\,\mathrm{mm}',
              'outerRadius',
              _state.parameters.outerRadius,
              '75',
            ),
          ];
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final field in fields)
                SizedBox(
                  width: width,
                  child: _ElectrostaticLabeledInput(
                    key: ValueKey<String>('electrostatic-${field.$3}'),
                    prefix: field.$1,
                    formula: field.$2,
                    value: field.$4,
                    placeholder: field.$5,
                    label: field.$1,
                    dark: dark,
                    onChanged: (value) =>
                        _changeState(_state.updateParameter(field.$3, value)),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCoaxialSection(bool dark) {
    return _electrostaticSection(
      dark: dark,
      title: Text('同轴圆柱面测量数据', style: _electrostaticSectionTitleStyle(dark)),
      child: _ElectrostaticCoaxialInputTable(
        state: _state,
        dark: dark,
        onChanged: (line, point, value) =>
            _changeState(_state.updateCoaxial(line, point, value)),
      ),
    );
  }

  Widget _buildParallelSection(bool dark) {
    return _electrostaticSection(
      dark: dark,
      title: Text('两平行导线测量数据', style: _electrostaticSectionTitleStyle(dark)),
      child: _ElectrostaticParallelInputTable(
        state: _state,
        dark: dark,
        onChanged: (field, point, value) =>
            _changeState(_state.updateParallel(field, point, value)),
      ),
    );
  }

  Widget _buildResultsSection(bool dark) {
    return _electrostaticSection(
      dark: dark,
      title: Text('计算结果', style: _electrostaticSectionTitleStyle(dark)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ElectrostaticResults(
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

  void _changeState(ElectrostaticFieldState next) {
    setState(() {
      _state = next;
      _calculation = ElectrostaticFieldCalculator.calculate(next);
    });
  }

  Future<void> _restore() async {
    final saved = await widget.loadSaved();
    if (!mounted || saved == null) return;
    setState(() {
      _state = saved;
      _calculation = ElectrostaticFieldCalculator.calculate(saved);
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
      await ElectrostaticFieldPdfService.shareAll(_calculation);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('PDF 生成失败：$error')));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _exportChart(ElectrostaticChartKind kind) async {
    try {
      await ElectrostaticFieldPdfService.shareChart(_calculation, kind);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('PDF 生成失败：$error')));
    }
  }
}
