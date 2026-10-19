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
import 'physics_ohmmeter_calculator.dart';
import 'physics_ohmmeter_models.dart';

part 'physics_ohmmeter_widgets.dart';

typedef OhmmeterStateLoader = Future<OhmmeterState?> Function();
typedef OhmmeterStateSaver =
    Future<void> Function(OhmmeterState state, OhmmeterCalculation calculation);

class PhysicsOhmmeterPage extends StatefulWidget {
  const PhysicsOhmmeterPage({
    super.key,
    required this.onBack,
    required this.loadSaved,
    required this.save,
  });

  final VoidCallback onBack;
  final OhmmeterStateLoader loadSaved;
  final OhmmeterStateSaver save;

  @override
  State<PhysicsOhmmeterPage> createState() => _PhysicsOhmmeterPageState();
}

class _PhysicsOhmmeterPageState extends State<PhysicsOhmmeterPage> {
  late OhmmeterState _state;
  late OhmmeterCalculation _calculation;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _state = OhmmeterState.initial();
    _calculation = OhmmeterCalculator.calculate(_state);
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
              title: '欧姆表的制作',
              backTitle: '返回计算器',
              onBack: widget.onBack,
            ),
            SizedBox(height: sectionGap),
            _ohmmeterFormulaBlock(dark),
            SizedBox(height: sectionGap),
            _ohmmeterSection(
              title: '实验参数',
              dark: dark,
              child: _OhmmeterParameterGrid(
                fields: [
                  _OhmmeterParameter(
                    prefix: '实际分流电阻',
                    formula: r'R_s^{\prime}\,/\,\Omega',
                    value: _state.shuntResistance,
                    label: '实际分流电阻',
                    onChanged: (value) => _changeState(
                      _state.updateParameter('shuntResistance', value),
                    ),
                  ),
                  _OhmmeterParameter(
                    prefix: '实际限流电阻',
                    formula: r'R_d\,/\,\Omega',
                    value: _state.limitingResistance,
                    label: '实际限流电阻',
                    onChanged: (value) => _changeState(
                      _state.updateParameter('limitingResistance', value),
                    ),
                  ),
                  _OhmmeterParameter(
                    prefix: '电池内阻',
                    formula: r'r\,/\,\Omega',
                    value: _state.batteryResistance,
                    label: '电池内阻',
                    onChanged: (value) => _changeState(
                      _state.updateParameter('batteryResistance', value),
                    ),
                  ),
                ],
                dark: dark,
              ),
            ),
            SizedBox(height: sectionGap),
            _ohmmeterSection(
              title: '标定电阻序列',
              dark: dark,
              child: _OhmmeterCalibrationSettings(
                state: _state,
                dark: dark,
                onChanged: (field, value) =>
                    _changeState(_state.updateSetting(field, value)),
                onGenerate: _regenerate,
              ),
            ),
            SizedBox(height: sectionGap),
            _ohmmeterSection(
              title: '实验记录',
              dark: dark,
              child: _OhmmeterRecordTable(
                state: _state,
                dark: dark,
                onMeasuredChanged: (index, value) =>
                    _changeState(_state.updateMeasured(index, value)),
              ),
            ),
            SizedBox(height: sectionGap),
            _ohmmeterSection(
              title: '成表检验',
              dark: dark,
              child: _OhmmeterParameterGrid(
                fields: [
                  _OhmmeterParameter(
                    prefix: '自制欧姆表读数',
                    formula: r'R_{\mathrm{read}}\,/\,\Omega',
                    value: _state.measuredResistance,
                    label: '自制欧姆表读数',
                    onChanged: (value) => _changeState(
                      _state.updateVerification('measuredResistance', value),
                    ),
                  ),
                  _OhmmeterParameter(
                    prefix: '被测电阻标准值',
                    formula: r'R_{\mathrm{true}}\,/\,\Omega',
                    value: _state.trueResistance,
                    label: '被测电阻标准值',
                    onChanged: (value) => _changeState(
                      _state.updateVerification('trueResistance', value),
                    ),
                  ),
                ],
                dark: dark,
              ),
            ),
            SizedBox(height: sectionGap),
            _ohmmeterSection(
              title: '计算结果',
              dark: dark,
              child: _OhmmeterResultContent(
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

  void _changeState(OhmmeterState next) {
    setState(() {
      _state = next;
      _calculation = OhmmeterCalculator.calculate(next);
    });
  }

  void _regenerate() => _changeState(_state.regenerateCalibration());

  Future<void> _restore() async {
    final saved = await widget.loadSaved();
    if (!mounted || saved == null) return;
    setState(() {
      _state = saved;
      _calculation = OhmmeterCalculator.calculate(saved);
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
