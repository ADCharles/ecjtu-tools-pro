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
import 'physics_sound_speed_calculator.dart';
import 'physics_sound_speed_models.dart';

part 'physics_sound_speed_widgets.dart';

typedef SoundSpeedStateLoader = Future<SoundSpeedState?> Function();
typedef SoundSpeedStateSaver =
    Future<void> Function(
      SoundSpeedState state,
      SoundSpeedCalculation calculation,
    );

class PhysicsSoundSpeedPage extends StatefulWidget {
  const PhysicsSoundSpeedPage({
    super.key,
    required this.onBack,
    required this.loadSaved,
    required this.save,
  });

  final VoidCallback onBack;
  final SoundSpeedStateLoader loadSaved;
  final SoundSpeedStateSaver save;

  @override
  State<PhysicsSoundSpeedPage> createState() => _PhysicsSoundSpeedPageState();
}

class _PhysicsSoundSpeedPageState extends State<PhysicsSoundSpeedPage> {
  late SoundSpeedState _state;
  late SoundSpeedCalculation _calculation;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _state = SoundSpeedState.initial();
    _calculation = SoundSpeedCalculator.calculate(_state);
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
              title: '声速测量',
              backTitle: '返回计算器',
              onBack: widget.onBack,
            ),
            SizedBox(height: sectionGap),
            _soundFormulaBlock(dark),
            SizedBox(height: sectionGap),
            _soundSection(
              title: '实验参数',
              dark: dark,
              child: _SoundInputContent(
                state: _state,
                dark: dark,
                onGlobalChanged: (field, value) =>
                    _changeState(_state.updateGlobal(field, value)),
                onMeasurementChanged: (method, index, value) => _changeState(
                  _state.updateMeasurement(method, index, value),
                ),
              ),
            ),
            SizedBox(height: sectionGap),
            _soundSection(
              title: '计算结果',
              dark: dark,
              child: _SoundOutputContent(
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

  void _changeState(SoundSpeedState next) {
    setState(() {
      _state = next;
      _calculation = SoundSpeedCalculator.calculate(next);
    });
  }

  Future<void> _restore() async {
    final saved = await widget.loadSaved();
    if (!mounted || saved == null) return;
    setState(() {
      _state = saved;
      _calculation = SoundSpeedCalculator.calculate(saved);
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
