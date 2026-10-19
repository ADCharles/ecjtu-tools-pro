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
import 'physics_liquid_refraction_calculator.dart';
import 'physics_liquid_refraction_models.dart';

part 'physics_liquid_refraction_widgets.dart';

typedef LiquidRefractionStateLoader = Future<LiquidRefractionState?> Function();
typedef LiquidRefractionStateSaver =
    Future<void> Function(
      LiquidRefractionState state,
      LiquidRefractionCalculation calculation,
    );

class PhysicsLiquidRefractionPage extends StatefulWidget {
  const PhysicsLiquidRefractionPage({
    super.key,
    required this.onBack,
    required this.loadSaved,
    required this.save,
  });

  final VoidCallback onBack;
  final LiquidRefractionStateLoader loadSaved;
  final LiquidRefractionStateSaver save;

  @override
  State<PhysicsLiquidRefractionPage> createState() =>
      _PhysicsLiquidRefractionPageState();
}

class _PhysicsLiquidRefractionPageState
    extends State<PhysicsLiquidRefractionPage> {
  late LiquidRefractionState _state;
  late LiquidRefractionCalculation _calculation;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _state = LiquidRefractionState.initial();
    _calculation = LiquidRefractionCalculator.calculate(_state);
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
              title: '液体折射率的测量',
              backTitle: '返回计算器',
              onBack: widget.onBack,
            ),
            SizedBox(height: sectionGap),
            _liquidFormulaBlock(dark),
            SizedBox(height: sectionGap),
            _liquidSection(
              title: '棱镜标定',
              dark: dark,
              child: _LiquidCalibrationInput(
                calibration: _state.calibration,
                dark: dark,
                onChanged: (field, part, value) =>
                    _changeState(_state.updateCalibration(field, part, value)),
              ),
            ),
            SizedBox(height: sectionGap),
            _liquidSection(
              title: '液体测量',
              dark: dark,
              child: _LiquidTrialsInput(
                trials: _state.trials,
                dark: dark,
                onChanged: (index, field, part, value) =>
                    _changeState(_state.updateTrial(index, field, part, value)),
              ),
            ),
            SizedBox(height: sectionGap),
            _liquidSection(
              title: '计算结果',
              dark: dark,
              child: _LiquidOutputContent(
                calculation: _calculation,
                dark: dark,
                saving: _saving,
                onSave: _save,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _changeState(LiquidRefractionState next) {
    setState(() {
      _state = next;
      _calculation = LiquidRefractionCalculator.calculate(next);
    });
  }

  Future<void> _restore() async {
    final saved = await widget.loadSaved();
    if (!mounted || saved == null) return;
    setState(() {
      _state = saved;
      _calculation = LiquidRefractionCalculator.calculate(saved);
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
}
