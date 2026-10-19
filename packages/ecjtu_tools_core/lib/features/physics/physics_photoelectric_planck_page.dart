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
import 'physics_photoelectric_planck_calculator.dart';
import 'physics_photoelectric_planck_chart.dart';
import 'physics_photoelectric_planck_models.dart';
import 'physics_photoelectric_planck_pdf.dart';

part 'physics_photoelectric_planck_widgets.dart';

typedef PhotoelectricPlanckStateLoader =
    Future<PhotoelectricPlanckState?> Function();
typedef PhotoelectricPlanckStateSaver =
    Future<void> Function(
      PhotoelectricPlanckState state,
      PhotoelectricPlanckCalculation calculation,
    );

class PhysicsPhotoelectricPlanckPage extends StatefulWidget {
  const PhysicsPhotoelectricPlanckPage({
    super.key,
    required this.onBack,
    required this.loadSaved,
    required this.save,
  });

  final VoidCallback onBack;
  final PhotoelectricPlanckStateLoader loadSaved;
  final PhotoelectricPlanckStateSaver save;

  @override
  State<PhysicsPhotoelectricPlanckPage> createState() =>
      _PhysicsPhotoelectricPlanckPageState();
}

class _PhysicsPhotoelectricPlanckPageState
    extends State<PhysicsPhotoelectricPlanckPage> {
  late PhotoelectricPlanckState _state;
  late PhotoelectricPlanckCalculation _calculation;
  bool _saving = false;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _state = PhotoelectricPlanckState.initial();
    _calculation = PhotoelectricPlanckCalculator.calculate(_state);
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
              title: '光电效应测普朗克常量',
              backTitle: '返回计算器',
              onBack: widget.onBack,
            ),
            SizedBox(height: sectionGap),
            _photoelectricFormulaBlock(dark),
            SizedBox(height: sectionGap),
            for (final group in _state.groups) ...[
              _photoelectricSection(
                title: '波长 ${group.wavelength} nm',
                dark: dark,
                child: _PhotoelectricGroupInput(
                  group: group,
                  dark: dark,
                  onCutoffChanged: (value) => _changeState(
                    _state.updateCutoff(_state.groups.indexOf(group), value),
                  ),
                  onPointChanged: (index, field, value) => _changeState(
                    _state.updatePoint(
                      _state.groups.indexOf(group),
                      index,
                      field,
                      value,
                    ),
                  ),
                ),
              ),
              SizedBox(height: sectionGap),
            ],
            _photoelectricSection(
              title: '计算常量',
              dark: dark,
              child: _PhotoelectricConstantsInput(
                state: _state,
                dark: dark,
                onChanged: (field, value) =>
                    _changeState(_state.updateGlobal(field, value)),
              ),
            ),
            SizedBox(height: sectionGap),
            _photoelectricSection(
              title: '计算结果',
              dark: dark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PhotoelectricResults(
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

  void _changeState(PhotoelectricPlanckState next) {
    setState(() {
      _state = next;
      _calculation = PhotoelectricPlanckCalculator.calculate(next);
    });
  }

  Future<void> _restore() async {
    final saved = await widget.loadSaved();
    if (!mounted || saved == null) return;
    setState(() {
      _state = saved;
      _calculation = PhotoelectricPlanckCalculator.calculate(saved);
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
      await PhotoelectricPlanckPdfService.shareAll(_calculation);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('PDF 生成失败：$error')));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _exportChart(PhotoelectricChartSpec spec) async {
    try {
      await PhotoelectricPlanckPdfService.shareChart(spec);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('PDF 生成失败：$error')));
    }
  }
}
