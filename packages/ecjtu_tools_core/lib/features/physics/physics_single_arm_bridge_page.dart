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
import 'physics_single_arm_bridge_calculator.dart';
import 'physics_single_arm_bridge_models.dart';

part 'physics_single_arm_bridge_widgets.dart';

typedef SingleArmBridgeStateLoader = Future<SingleArmBridgeState?> Function();
typedef SingleArmBridgeStateSaver =
    Future<void> Function(
      SingleArmBridgeState state,
      SingleArmBridgeCalculation calculation,
    );

class PhysicsSingleArmBridgePage extends StatefulWidget {
  const PhysicsSingleArmBridgePage({
    super.key,
    required this.onBack,
    required this.loadSaved,
    required this.save,
  });

  final VoidCallback onBack;
  final SingleArmBridgeStateLoader loadSaved;
  final SingleArmBridgeStateSaver save;

  @override
  State<PhysicsSingleArmBridgePage> createState() =>
      _PhysicsSingleArmBridgePageState();
}

class _PhysicsSingleArmBridgePageState
    extends State<PhysicsSingleArmBridgePage> {
  late SingleArmBridgeState _state;
  late SingleArmBridgeCalculation _calculation;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _state = SingleArmBridgeState.initial();
    _calculation = SingleArmBridgeCalculator.calculate(_state);
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
              title: '单臂电桥法测电阻',
              backTitle: '返回计算器',
              onBack: widget.onBack,
            ),
            SizedBox(height: sectionGap),
            _bridgeFormulaBlock(dark),
            SizedBox(height: sectionGap),
            _bridgeSection(
              title: '测量数据',
              dark: dark,
              child: _BridgeInputTable(
                state: _state,
                dark: dark,
                onChanged: _changeMeasurement,
              ),
            ),
            SizedBox(height: sectionGap),
            _bridgeSection(
              title: '计算结果',
              dark: dark,
              child: _BridgeOutputContent(
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

  void _changeMeasurement(String field, int index, String value) {
    _changeState(_state.update(field, index, value));
  }

  void _changeState(SingleArmBridgeState next) {
    setState(() {
      _state = next;
      _calculation = SingleArmBridgeCalculator.calculate(next);
    });
  }

  Future<void> _restore() async {
    final saved = await widget.loadSaved();
    if (!mounted || saved == null) return;
    setState(() {
      _state = saved;
      _calculation = SingleArmBridgeCalculator.calculate(saved);
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
