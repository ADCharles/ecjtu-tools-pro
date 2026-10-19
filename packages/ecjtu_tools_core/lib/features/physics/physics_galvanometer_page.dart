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
import 'physics_galvanometer_calculator.dart';
import 'physics_galvanometer_models.dart';

part 'physics_galvanometer_widgets.dart';

typedef GalvanometerStateLoader = Future<GalvanometerState?> Function();
typedef GalvanometerStateSaver =
    Future<void> Function(
      GalvanometerState state,
      GalvanometerCalculation calculation,
    );

class PhysicsGalvanometerPage extends StatefulWidget {
  const PhysicsGalvanometerPage({
    super.key,
    required this.onBack,
    required this.loadSaved,
    required this.save,
  });

  final VoidCallback onBack;
  final GalvanometerStateLoader loadSaved;
  final GalvanometerStateSaver save;

  @override
  State<PhysicsGalvanometerPage> createState() =>
      _PhysicsGalvanometerPageState();
}

class _PhysicsGalvanometerPageState extends State<PhysicsGalvanometerPage> {
  late GalvanometerState _state;
  late GalvanometerCalculation _calculation;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _state = GalvanometerState.initial();
    _calculation = GalvanometerCalculator.calculate(_state);
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
              title: '灵敏电流计特性的研究',
              backTitle: '返回计算器',
              onBack: widget.onBack,
            ),
            SizedBox(height: sectionGap),
            _GalvanometerFormulaBlock(dark: dark),
            SizedBox(height: sectionGap),
            _buildCriticalSection(dark),
            SizedBox(height: sectionGap),
            _buildResistanceSection(dark),
            SizedBox(height: sectionGap),
            _buildSensitivitySection(dark),
            SizedBox(height: sectionGap),
            _buildResultsSection(dark),
          ],
        ),
      ),
    );
  }

  Widget _buildCriticalSection(bool dark) {
    return _galvanometerSection(
      dark: dark,
      title: _galvanometerMixedText(
        prefix: '表一：测定外临界电阻 ',
        formula: r'R_c',
        dark: dark,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth < 560
              ? 1
              : constraints.maxWidth < 700
              ? 2
              : 4;
          final gap = 10.0;
          final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
          final fields = [
            ('临界电阻 ', r'R_c\,/\,\Omega', 'rc', _state.critical.rc, '620'),
            ('电阻 ', r'R_a\,/\,\Omega', 'ra', _state.critical.ra, '10000'),
            ('电阻 ', r'R_b\,/\,\Omega', 'rb', _state.critical.rb, '1'),
            ('距离 ', r'd_m\,/\,\mathrm{mm}', 'dm', _state.critical.dm, '40'),
          ];
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final field in fields)
                SizedBox(
                  width: width,
                  child: _GalvanometerLabeledInput(
                    prefix: field.$1,
                    formula: field.$2,
                    value: field.$4,
                    placeholder: field.$5,
                    label: field.$1,
                    dark: dark,
                    onChanged: (value) => _changeCritical(field.$3, value),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildResistanceSection(bool dark) {
    return _galvanometerSection(
      dark: dark,
      title: _galvanometerMixedText(
        prefix: '表二：测定电流计内阻 ',
        formula: r'R_g',
        dark: dark,
      ),
      child: _buildResistanceInputTable(
        state: _state,
        dark: dark,
        onChanged: _changeResistance,
      ),
    );
  }

  Widget _buildSensitivitySection(bool dark) {
    return _galvanometerSection(
      dark: dark,
      title: _galvanometerMixedParts(
        dark: dark,
        parts: const [
          '表三：测定电流计常量 ',
          _GalvanometerMathPart(r'K_i'),
          ' 及 ',
          _GalvanometerMathPart(r'S_i'),
        ],
      ),
      child: _buildSensitivityInputTable(
        state: _state,
        dark: dark,
        onChanged: _changeSensitivity,
      ),
    );
  }

  Widget _buildResultsSection(bool dark) {
    return _galvanometerSection(
      dark: dark,
      title: Text('计算结果', style: _galvanometerSectionTitleStyle(dark)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildResistanceResults(dark),
          const SizedBox(height: 16),
          _buildSensitivityResults(dark),
          const SizedBox(height: 14),
          physicsSaveButton(
            context,
            saving: _saving,
            enabled: true,
            onPressed: _save,
          ),
        ],
      ),
    );
  }

  void _changeCritical(String field, String value) {
    _changeState(_state.updateCritical(field, value));
  }

  void _changeResistance(int index, String field, String value) {
    _changeState(_state.updateResistance(index, field, value));
  }

  void _changeSensitivity(int index, String field, String value) {
    _changeState(_state.updateSensitivity(index, field, value));
  }

  void _changeState(GalvanometerState next) {
    setState(() {
      _state = next;
      _calculation = GalvanometerCalculator.calculate(next);
    });
  }

  Future<void> _restore() async {
    final saved = await widget.loadSaved();
    if (!mounted || saved == null) return;
    setState(() {
      _state = saved;
      _calculation = GalvanometerCalculator.calculate(saved);
    });
  }

  Future<void> _save() async {
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
