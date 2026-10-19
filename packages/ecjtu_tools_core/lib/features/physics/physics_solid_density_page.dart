// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'package:ecjtu_tools_core/widgets/ecjtu_text_context_menu.dart';
import '../../widgets/ecjtu_pane_surface.dart';
import 'package:flutter/material.dart';
import 'physics_shared_styles.dart';
import 'package:flutter_math_fork/flutter_math.dart';

import '../../theme/ecjtu_theme.dart';
import '../../widgets/ecjtu_page.dart';
import '../workbench/smart_work_widgets.dart';
import 'physics_solid_density_calculator.dart';
import 'physics_solid_density_models.dart';

part 'physics_solid_density_widgets.dart';

typedef SolidDensityStateLoader = Future<SolidDensityState?> Function();
typedef SolidDensityStateSaver =
    Future<void> Function(
      SolidDensityState state,
      SolidDensityCalculation calculation,
    );

class PhysicsSolidDensityPage extends StatefulWidget {
  const PhysicsSolidDensityPage({
    super.key,
    required this.onBack,
    required this.loadSaved,
    required this.save,
  });

  final VoidCallback onBack;
  final SolidDensityStateLoader loadSaved;
  final SolidDensityStateSaver save;

  @override
  State<PhysicsSolidDensityPage> createState() =>
      _PhysicsSolidDensityPageState();
}

class _PhysicsSolidDensityPageState extends State<PhysicsSolidDensityPage> {
  late SolidDensityState _state;
  late SolidDensityCalculation _calculation;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _state = SolidDensityState.initial();
    _calculation = SolidDensityCalculator.calculate(_state);
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
              title: '固体密度的测量',
              backTitle: '返回计算器',
              onBack: widget.onBack,
            ),
            SizedBox(height: sectionGap),
            _solidFormulaBlock(dark),
            SizedBox(height: sectionGap),
            _solidSection(
              title: '规则物体',
              dark: dark,
              child: _SolidRectangularInput(
                input: _state.rectangular,
                dark: dark,
                onMeasurementChanged: (field, index, value) => _changeState(
                  _state.updateRectangularMeasurement(index, field, value),
                ),
                onFieldChanged: (field, value) =>
                    _changeState(_state.updateRectangularField(field, value)),
              ),
            ),
            SizedBox(height: sectionGap),
            _solidSection(
              title: '不规则物体排水法',
              dark: dark,
              child: _SolidDisplacementInput(
                input: _state.displacement,
                dark: dark,
                onChanged: (field, value) =>
                    _changeState(_state.updateDisplacementField(field, value)),
              ),
            ),
            SizedBox(height: sectionGap),
            _solidSection(
              title: '计算结果',
              dark: dark,
              child: _SolidOutputContent(
                calculation: _calculation,
                dark: dark,
                saving: _saving,
                onExportPdf: _showNoCharts,
                onSave: _save,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _changeState(SolidDensityState next) {
    setState(() {
      _state = next;
      _calculation = SolidDensityCalculator.calculate(next);
    });
  }

  Future<void> _restore() async {
    final saved = await widget.loadSaved();
    if (!mounted || saved == null) return;
    setState(() {
      _state = saved;
      _calculation = SolidDensityCalculator.calculate(saved);
    });
  }

  Future<void> _showNoCharts() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      useRootNavigator: !EcjtuPaneDialogScope.contains(context),
      builder: (context) => EcjtuDialog(
        title: const Text('暂无图表'),
        content: const Text('请先填写完整数据生成图形。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
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
}
