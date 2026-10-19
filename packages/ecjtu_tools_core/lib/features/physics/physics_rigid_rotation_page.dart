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
import 'physics_rigid_rotation_calculator.dart';
import 'physics_rigid_rotation_chart.dart';
import 'physics_rigid_rotation_models.dart';
import 'physics_rigid_rotation_pdf.dart';

part 'physics_rigid_rotation_widgets.dart';

typedef RigidRotationStateLoader = Future<RigidRotationState?> Function();
typedef RigidRotationStateSaver =
    Future<void> Function(
      RigidRotationState state,
      RigidRotationCalculation calculation,
    );

class PhysicsRigidRotationPage extends StatefulWidget {
  const PhysicsRigidRotationPage({
    super.key,
    required this.onBack,
    required this.loadSaved,
    required this.save,
  });

  final VoidCallback onBack;
  final RigidRotationStateLoader loadSaved;
  final RigidRotationStateSaver save;

  @override
  State<PhysicsRigidRotationPage> createState() =>
      _PhysicsRigidRotationPageState();
}

class _PhysicsRigidRotationPageState extends State<PhysicsRigidRotationPage> {
  late RigidRotationState _state;
  late RigidRotationCalculation _calculation;
  bool _saving = false;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _state = RigidRotationState.initial();
    _calculation = RigidRotationCalculator.calculate(_state);
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
              title: '刚体转动惯量的研究',
              backTitle: '返回计算器',
              onBack: widget.onBack,
            ),
            SizedBox(height: sectionGap),
            _rigidRotationFormulaBlock(dark),
            SizedBox(height: sectionGap),
            _rigidRotationSection(
              title: '基本数据',
              dark: dark,
              child: _RigidRotationBasicInput(
                state: _state,
                dark: dark,
                onBasicChanged: (field, value) =>
                    _changeState(_state.updateBasic(field, value)),
                onDiameterChanged: (index, value) =>
                    _changeState(_state.updateDiameter(index, value)),
              ),
            ),
            SizedBox(height: sectionGap),
            _rigidRotationSection(
              title: '质量与时间数据',
              dark: dark,
              child: _RigidRotationMassInput(
                state: _state,
                dark: dark,
                onChanged: (runIndex, field, timeIndex, value) => _changeState(
                  _state.updateMassRun(runIndex, field, timeIndex, value),
                ),
              ),
            ),
            SizedBox(height: sectionGap),
            _rigidRotationSection(
              title: '半径与时间数据',
              dark: dark,
              child: _RigidRotationSecondInput(
                state: _state,
                calculation: _calculation,
                dark: dark,
                onMassChanged: (value) =>
                    _changeState(_state.updateSecondMass(value)),
                onTimeChanged: (runIndex, timeIndex, value) => _changeState(
                  _state.updateSecondTime(runIndex, timeIndex, value),
                ),
              ),
            ),
            SizedBox(height: sectionGap),
            _rigidRotationSection(
              title: '计算结果',
              dark: dark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _RigidRotationResults(
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

  void _changeState(RigidRotationState next) {
    setState(() {
      _state = next;
      _calculation = RigidRotationCalculator.calculate(next);
    });
  }

  Future<void> _restore() async {
    final saved = await widget.loadSaved();
    if (!mounted || saved == null) return;
    setState(() {
      _state = saved;
      _calculation = RigidRotationCalculator.calculate(saved);
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
      await RigidRotationPdfService.shareAll(_calculation);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('PDF 生成失败：$error')));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _exportChart(RigidRotationChartSpec spec) async {
    try {
      await RigidRotationPdfService.shareChart(spec);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('PDF 生成失败：$error')));
    }
  }
}
