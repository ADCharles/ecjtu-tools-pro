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
import 'physics_rheostat_characteristic_calculator.dart';
import 'physics_rheostat_characteristic_models.dart';

part 'physics_rheostat_characteristic_widgets.dart';

typedef RheostatStateLoader = Future<RheostatState?> Function();
typedef RheostatStateSaver =
    Future<void> Function(RheostatState state, RheostatCalculation calculation);

class PhysicsRheostatCharacteristicPage extends StatefulWidget {
  const PhysicsRheostatCharacteristicPage({
    super.key,
    required this.onBack,
    required this.loadSaved,
    required this.save,
  });

  final VoidCallback onBack;
  final RheostatStateLoader loadSaved;
  final RheostatStateSaver save;

  @override
  State<PhysicsRheostatCharacteristicPage> createState() =>
      _PhysicsRheostatCharacteristicPageState();
}

class _PhysicsRheostatCharacteristicPageState
    extends State<PhysicsRheostatCharacteristicPage> {
  late RheostatState _state;
  late RheostatCalculation _calculation;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _state = RheostatState.initial();
    _calculation = RheostatCharacteristicCalculator.calculate(_state);
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
              title: '滑线变阻器特性的研究',
              backTitle: '返回计算器',
              onBack: widget.onBack,
            ),
            SizedBox(height: sectionGap),
            _rheostatFormulaBlock(dark),
            SizedBox(height: sectionGap),
            _rheostatSection(
              title: '测量数据',
              dark: dark,
              child: _RheostatInputTable(
                rows: _state.rows,
                dark: dark,
                onChanged: (index, field, value) =>
                    _changeState(_state.updateRow(index, field, value)),
              ),
            ),
            SizedBox(height: sectionGap),
            _rheostatSection(
              title: '不确定度参数',
              dark: dark,
              child: _RheostatParameterGrid(
                dark: dark,
                fields: [
                  _RheostatFieldDefinition(
                    label: '量程电阻',
                    formula: r'R_0\,/\,\Omega',
                    value: _state.rangeResistance,
                    semanticLabel: '量程电阻',
                    onChanged: (value) =>
                        _changeState(_state.updateParameter('range', value)),
                  ),
                  _RheostatFieldDefinition(
                    label: '检验电压',
                    formula: r'U_t\,/\,\mathrm{V}',
                    value: _state.testVoltage,
                    semanticLabel: '检验电压',
                    onChanged: (value) => _changeState(
                      _state.updateParameter('testVoltage', value),
                    ),
                  ),
                  _RheostatFieldDefinition(
                    label: '电压不确定度',
                    formula: r'u(U)\,/\,\mathrm{mV}',
                    value: _state.voltageUncertainty,
                    semanticLabel: '电压不确定度',
                    onChanged: (value) => _changeState(
                      _state.updateParameter('voltageUncertainty', value),
                    ),
                  ),
                  _RheostatFieldDefinition(
                    label: '电流不确定度',
                    formula: r'u(I)\,/\,\mathrm{mA}',
                    value: _state.currentUncertainty,
                    semanticLabel: '电流不确定度',
                    onChanged: (value) => _changeState(
                      _state.updateParameter('currentUncertainty', value),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: sectionGap),
            _rheostatSection(
              title: '计算结果',
              dark: dark,
              child: _RheostatOutputContent(
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

  void _changeState(RheostatState next) {
    setState(() {
      _state = next;
      _calculation = RheostatCharacteristicCalculator.calculate(next);
    });
  }

  Future<void> _restore() async {
    final saved = await widget.loadSaved();
    if (!mounted || saved == null) return;
    setState(() {
      _state = saved;
      _calculation = RheostatCharacteristicCalculator.calculate(saved);
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
