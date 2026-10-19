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
import 'physics_metal_work_function_calculator.dart';
import 'physics_metal_work_function_chart.dart';
import 'physics_metal_work_function_models.dart';
import 'physics_metal_work_function_pdf.dart';

part 'physics_metal_work_function_widgets.dart';

typedef MetalWorkStateLoader = Future<MetalWorkState?> Function();
typedef MetalWorkStateSaver =
    Future<void> Function(
      MetalWorkState state,
      MetalWorkCalculation calculation,
    );

class PhysicsMetalWorkFunctionPage extends StatefulWidget {
  const PhysicsMetalWorkFunctionPage({
    super.key,
    required this.onBack,
    required this.loadSaved,
    required this.save,
  });

  final VoidCallback onBack;
  final MetalWorkStateLoader loadSaved;
  final MetalWorkStateSaver save;

  @override
  State<PhysicsMetalWorkFunctionPage> createState() =>
      _PhysicsMetalWorkFunctionPageState();
}

class _PhysicsMetalWorkFunctionPageState
    extends State<PhysicsMetalWorkFunctionPage> {
  late MetalWorkState _state;
  late MetalWorkCalculation _calculation;
  bool _saving = false;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _state = MetalWorkState.initial();
    _calculation = MetalWorkCalculator.calculate(_state);
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
              title: '金属电子逸出功',
              backTitle: '返回计算器',
              onBack: widget.onBack,
            ),
            SizedBox(height: sectionGap),
            _metalWorkFormulaBlock(dark),
            for (var index = 0; index < _state.groups.length; index++) ...[
              SizedBox(height: sectionGap),
              _metalWorkSection(
                title: '第 ${index + 1} 组',
                dark: dark,
                child: _MetalWorkGroupInput(
                  group: _state.groups[index],
                  groupIndex: index,
                  dark: dark,
                  onInfoChanged: (field, value) => _changeState(
                    _state.updateGroup(
                      index,
                      filamentCurrent: field == 'filamentCurrent'
                          ? value
                          : null,
                      temperature: field == 'temperature' ? value : null,
                    ),
                  ),
                  onPointChanged: (pointIndex, field, value) => _changeState(
                    _state.updatePoint(index, pointIndex, field, value),
                  ),
                ),
              ),
            ],
            SizedBox(height: sectionGap),
            _metalWorkSection(
              title: '计算常量',
              dark: dark,
              child: _MetalWorkConstantsInput(
                state: _state,
                dark: dark,
                onChanged: (field, value) =>
                    _changeState(_state.updateGlobal(field, value)),
              ),
            ),
            SizedBox(height: sectionGap),
            _metalWorkSection(
              title: '计算结果',
              dark: dark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _MetalWorkResults(
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

  void _changeState(MetalWorkState next) {
    setState(() {
      _state = next;
      _calculation = MetalWorkCalculator.calculate(next);
    });
  }

  Future<void> _restore() async {
    final saved = await widget.loadSaved();
    if (!mounted || saved == null) return;
    setState(() {
      _state = saved;
      _calculation = MetalWorkCalculator.calculate(saved);
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
      await MetalWorkFunctionPdfService.shareAll(_calculation);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('PDF 生成失败：$error')));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _exportChart(MetalWorkChartSpec spec) async {
    try {
      await MetalWorkFunctionPdfService.shareChart(spec);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('PDF 生成失败：$error')));
    }
  }
}
