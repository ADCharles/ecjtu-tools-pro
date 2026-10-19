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
import 'physics_youngs_modulus_calculator.dart';
import 'physics_youngs_modulus_chart.dart';
import 'physics_youngs_modulus_models.dart';
import 'physics_youngs_modulus_pdf.dart';

part 'physics_youngs_modulus_widgets.dart';

typedef YoungsModulusStateLoader = Future<YoungsModulusState?> Function();
typedef YoungsModulusStateSaver =
    Future<void> Function(
      YoungsModulusState state,
      YoungsModulusCalculation calculation,
    );
typedef YoungsModulusChartExporter =
    Future<void> Function(String title, List<YoungsModulusChartPoint> points);

class PhysicsYoungsModulusPage extends StatefulWidget {
  const PhysicsYoungsModulusPage({
    super.key,
    required this.onBack,
    required this.loadSaved,
    required this.save,
  });

  final VoidCallback onBack;
  final YoungsModulusStateLoader loadSaved;
  final YoungsModulusStateSaver save;

  @override
  State<PhysicsYoungsModulusPage> createState() =>
      _PhysicsYoungsModulusPageState();
}

class _PhysicsYoungsModulusPageState extends State<PhysicsYoungsModulusPage> {
  late YoungsModulusState _state;
  late YoungsModulusCalculation _calculation;
  bool _saving = false;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _state = YoungsModulusState.initial();
    _calculation = YoungsModulusCalculator.calculate(_state);
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
              title: '拉伸法测定金属丝的杨氏模量',
              backTitle: '返回计算器',
              onBack: widget.onBack,
            ),
            SizedBox(height: sectionGap),
            _youngsFormulaBlock(dark),
            SizedBox(height: sectionGap),
            _youngsSection(
              title: '金属丝直径测量数据',
              dark: dark,
              child: _YoungsDiameterInput(
                zeroError: _state.zeroError,
                diameter: _state.diameter,
                dark: dark,
                onZeroErrorChanged: (value) =>
                    _changeState(_state.copyWith(zeroError: value)),
                onChanged: (index, field, value) =>
                    _changeState(_state.updateDiameter(index, field, value)),
              ),
            ),
            SizedBox(height: sectionGap),
            _youngsSection(
              title: '标尺标度值',
              dark: dark,
              child: _YoungsScaleInput(
                values: _state.scale,
                dark: dark,
                onChanged: (index, field, value) =>
                    _changeState(_state.updateScale(index, field, value)),
              ),
            ),
            SizedBox(height: sectionGap),
            _youngsSection(
              title: '装置参数',
              dark: dark,
              child: _buildDimensions(dark),
            ),
            SizedBox(height: sectionGap),
            _youngsSection(
              title: '计算结果',
              dark: dark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _youngsResultTables(_calculation, dark),
                  SizedBox(height: EcjtuMetrics.pageHeaderGapFor(context)),
                  _youngsResultSummary(_calculation, dark),
                  const SizedBox(height: 18),
                  Text('报告图', style: _youngsResultHeadingStyle(dark)),
                  const SizedBox(height: 9),
                  YoungsModulusChartCard(
                    points: youngsModulusChartPoints(_calculation.scale),
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDimensions(bool dark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportWidth = MediaQuery.sizeOf(context).width;
        final columns = viewportWidth <= 520
            ? 1
            : viewportWidth <= 800
            ? 2
            : 4;
        final gap = 10.0;
        final width = columns == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - gap * (columns - 1)) / columns;
        final fields =
            <({String label, String formula, String key, String value})>[
              (
                label: '镜面与标尺距离',
                formula: r'D\,/\,\mathrm{m}',
                key: 'distance',
                value: _state.dimensions.distance,
              ),
              (
                label: '绝对误差',
                formula: r'\Delta D\,/\,\mathrm{m}',
                key: 'distanceError',
                value: _state.dimensions.distanceError,
              ),
              (
                label: '金属丝原长',
                formula: r'L\,/\,\mathrm{m}',
                key: 'length',
                value: _state.dimensions.length,
              ),
              (
                label: '绝对误差',
                formula: r'\Delta L\,/\,\mathrm{m}',
                key: 'lengthError',
                value: _state.dimensions.lengthError,
              ),
              (
                label: '后足尖到两前足尖垂直距离',
                formula: r'a\,/\,\mathrm{m}',
                key: 'leverArm',
                value: _state.dimensions.leverArm,
              ),
              (
                label: '绝对误差',
                formula: r'\Delta a\,/\,\mathrm{m}',
                key: 'leverArmError',
                value: _state.dimensions.leverArmError,
              ),
              (
                label: '负荷改变量',
                formula: r'\Delta m\,/\,\mathrm{kg}',
                key: 'massIncrement',
                value: _state.dimensions.massIncrement,
              ),
              (
                label: '重力加速度',
                formula: r'g\,/\,\mathrm{m\,s^{-2}}',
                key: 'gravity',
                value: _state.dimensions.gravity,
              ),
            ];
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final field in fields)
              SizedBox(
                width: width,
                child: _YoungsLabeledInput(
                  prefix: field.label,
                  formula: field.formula,
                  value: field.value,
                  label: field.label,
                  dark: dark,
                  onChanged: (value) =>
                      _changeState(_state.updateDimension(field.key, value)),
                ),
              ),
          ],
        );
      },
    );
  }

  void _changeState(YoungsModulusState next) {
    setState(() {
      _state = next;
      _calculation = YoungsModulusCalculator.calculate(next);
    });
  }

  Future<void> _restore() async {
    final saved = await widget.loadSaved();
    if (!mounted || saved == null) return;
    setState(() {
      _state = saved;
      _calculation = YoungsModulusCalculator.calculate(saved);
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
      await YoungsModulusPdfService.shareAll(
        youngsModulusChartPoints(_calculation.scale),
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

  Future<void> _exportChart() async {
    final points = youngsModulusChartPoints(_calculation.scale);
    try {
      await YoungsModulusPdfService.shareChart(
        title: '负荷与标尺读数图',
        points: points,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('PDF 生成失败：$error')));
    }
  }
}
