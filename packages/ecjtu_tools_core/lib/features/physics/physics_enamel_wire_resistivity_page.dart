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
import 'physics_enamel_wire_resistivity_calculator.dart';
import 'physics_enamel_wire_resistivity_models.dart';

part 'physics_enamel_wire_resistivity_widgets.dart';

typedef EnamelWireResistivityStateLoader =
    Future<EnamelWireResistivityState?> Function();
typedef EnamelWireResistivityStateSaver =
    Future<void> Function(
      EnamelWireResistivityState state,
      EnamelWireResistivityCalculation calculation,
    );

class PhysicsEnamelWireResistivityPage extends StatefulWidget {
  const PhysicsEnamelWireResistivityPage({
    super.key,
    required this.onBack,
    required this.loadSaved,
    required this.save,
  });

  final VoidCallback onBack;
  final EnamelWireResistivityStateLoader loadSaved;
  final EnamelWireResistivityStateSaver save;

  @override
  State<PhysicsEnamelWireResistivityPage> createState() =>
      _PhysicsEnamelWireResistivityPageState();
}

class _PhysicsEnamelWireResistivityPageState
    extends State<PhysicsEnamelWireResistivityPage> {
  late EnamelWireResistivityState _state;
  late EnamelWireResistivityCalculation _calculation;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _state = EnamelWireResistivityState.initial();
    _calculation = EnamelWireResistivityCalculator.calculate(_state);
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
              title: '漆包线电阻率的测定',
              backTitle: '返回计算器',
              onBack: widget.onBack,
            ),
            SizedBox(height: sectionGap),
            _enamelFormulaBlock(dark),
            SizedBox(height: sectionGap),
            _enamelSection(
              title: '漆包线直径',
              dark: dark,
              child: _EnamelMeasurementTable(
                values: _state.diameters,
                headerText: '直径',
                headerFormula: r'd\,/\,\mathrm{mm}',
                fieldLabel: '漆包线直径',
                dark: dark,
                onChanged: (index, value) =>
                    _changeState(_state.updateDiameter(index, value)),
              ),
            ),
            SizedBox(height: sectionGap),
            _enamelSection(
              title: '漆包线电阻',
              dark: dark,
              child: _EnamelMeasurementTable(
                values: _state.resistances,
                headerText: '电阻',
                headerFormula: r'R\,/\,\Omega',
                fieldLabel: '漆包线电阻',
                dark: dark,
                onChanged: (index, value) =>
                    _changeState(_state.updateResistance(index, value)),
              ),
            ),
            SizedBox(height: sectionGap),
            _enamelSection(
              title: '装置参数',
              dark: dark,
              child: _EnamelParameterGrid(
                dark: dark,
                fields: [
                  _EnamelFieldDefinition(
                    label: '漆包线质量',
                    formula: r'm\,/\,\mathrm{g}',
                    value: _state.mass,
                    semanticLabel: '漆包线质量',
                    onChanged: (value) =>
                        _changeState(_state.updateParameter('mass', value)),
                  ),
                  _EnamelFieldDefinition(
                    label: '天平不确定度',
                    formula: r'u(m)\,/\,\mathrm{g}',
                    value: _state.massError,
                    semanticLabel: '天平不确定度',
                    onChanged: (value) => _changeState(
                      _state.updateParameter('massError', value),
                    ),
                  ),
                  _EnamelFieldDefinition(
                    label: '铜的密度',
                    formula: r'\rho_m\,/\,\mathrm{g\,m^{-3}}',
                    value: _state.density,
                    semanticLabel: '铜的密度',
                    onChanged: (value) =>
                        _changeState(_state.updateParameter('density', value)),
                  ),
                ],
              ),
            ),
            SizedBox(height: sectionGap),
            _enamelSection(
              title: '计算结果',
              dark: dark,
              child: _EnamelOutputContent(
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

  void _changeState(EnamelWireResistivityState next) {
    setState(() {
      _state = next;
      _calculation = EnamelWireResistivityCalculator.calculate(next);
    });
  }

  Future<void> _restore() async {
    final saved = await widget.loadSaved();
    if (!mounted || saved == null) return;
    setState(() {
      _state = saved;
      _calculation = EnamelWireResistivityCalculator.calculate(saved);
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
