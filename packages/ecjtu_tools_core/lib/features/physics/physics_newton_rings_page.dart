// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'package:ecjtu_tools_core/widgets/ecjtu_text_context_menu.dart';
import '../../theme/ecjtu_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

import '../../widgets/ecjtu_page.dart';
import '../workbench/smart_work_widgets.dart';
import 'physics_newton_rings_calculator.dart';
import 'physics_newton_rings_models.dart';
import 'physics_shared_styles.dart';

part 'physics_newton_rings_widgets.dart';

typedef NewtonRingsStateLoader = Future<NewtonRingsState?> Function();
typedef NewtonRingsStateSaver =
    Future<void> Function(
      NewtonRingsState state,
      NewtonRingsCalculation calculation,
    );

class PhysicsNewtonRingsPage extends StatefulWidget {
  const PhysicsNewtonRingsPage({
    super.key,
    required this.onBack,
    required this.loadSaved,
    required this.save,
  });

  final VoidCallback onBack;
  final NewtonRingsStateLoader loadSaved;
  final NewtonRingsStateSaver save;

  @override
  State<PhysicsNewtonRingsPage> createState() => _PhysicsNewtonRingsPageState();
}

class _PhysicsNewtonRingsPageState extends State<PhysicsNewtonRingsPage> {
  late NewtonRingsState _state;
  late NewtonRingsCalculation _calculation;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _state = NewtonRingsState.initial();
    _calculation = NewtonRingsCalculator.calculate(_state);
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
              title: '牛顿环测球面曲率半径',
              backTitle: '返回计算器',
              onBack: widget.onBack,
            ),
            SizedBox(height: sectionGap),
            _FormulaBlock(dark: dark),
            SizedBox(height: sectionGap),
            _buildInputSection(dark),
            SizedBox(height: sectionGap),
            _buildOutputSection(dark),
          ],
        ),
      ),
    );
  }

  Widget _buildInputSection(bool dark) {
    return _PhysicsCalculatorSection(
      title: '输入数据',
      dark: dark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildParameters(dark),
          const SizedBox(height: 12),
          _buildInputTable(dark),
        ],
      ),
    );
  }

  Widget _buildOutputSection(bool dark) {
    return _PhysicsCalculatorSection(
      title: '计算结果',
      dark: dark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildResults(dark),
          const SizedBox(height: 12),
          _buildSaveButton(dark),
        ],
      ),
    );
  }

  Widget _buildParameters(bool dark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth <= 560 ? 1 : 2;
        final gap = 10.0;
        final fieldWidth = columns == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            SizedBox(
              width: fieldWidth,
              child: _ParameterField(
                label: '钠光波长',
                formula: r'\lambda\,/\,\mathrm{nm}',
                value: _state.wavelength,
                placeholder: NewtonRingsState.defaultWavelength,
                dark: dark,
                onChanged: (value) =>
                    _changeState(_state.copyWith(wavelength: value)),
              ),
            ),
            SizedBox(
              width: fieldWidth,
              child: _ParameterField(
                label: '计算用环序差',
                formula: r'm-n',
                value: _state.pairGap,
                placeholder: NewtonRingsState.defaultPairGap,
                dark: dark,
                onChanged: (value) =>
                    _changeState(_state.copyWith(pairGap: value)),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInputTable(bool dark) {
    final border = EcjtuColors.platformBorder(
      dark,
      (dark ? const Color(0xFF31546B) : const Color(0xFFD5E4EF)),
    );
    return _ScrollableTable(
      minWidth: 660,
      borderColor: border,
      child: Table(
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        columnWidths: const {
          0: FixedColumnWidth(58),
          1: FixedColumnWidth(58),
          2: FixedColumnWidth(92),
          3: FixedColumnWidth(226),
          4: FixedColumnWidth(226),
        },
        border: _tableBorder(dark),
        children: [
          TableRow(
            decoration: BoxDecoration(color: _headerColor(dark)),
            children: [
              _headerCell('环号', dark, result: true),
              _headerCell('类型', dark, result: true),
              _headerCell('环序', dark, result: true),
              _headerCellWithMath(
                '左读数',
                r'X_{\mathrm{L}}\,/\,\mathrm{mm}',
                dark,
                result: true,
              ),
              _headerCellWithMath(
                '右读数',
                r'X_{\mathrm{R}}\,/\,\mathrm{mm}',
                dark,
                result: true,
              ),
            ],
          ),
          for (var index = 0; index < _state.rings.length; index++)
            _inputRow(index, dark),
        ],
      ),
    );
  }

  TableRow _inputRow(int index, bool dark) {
    final ring = _state.rings[index];
    final fixedColumnColor = dark
        ? const Color(0xFF12263A)
        : const Color(0xFFF8FBFD);
    return TableRow(
      children: [
        _tableCell(
          Text('${index + 1}', style: _cellTextStyle(dark)),
          backgroundColor: fixedColumnColor,
        ),
        _tableCell(
          Math.tex(
            ring.kind.value,
            mathStyle: MathStyle.text,
            textStyle: _mathTextStyle(dark, weight: FontWeight.w700),
          ),
          backgroundColor: fixedColumnColor,
        ),
        _tableInputCell(
          index: index,
          field: 'order',
          value: ring.order,
          label: '第 ${index + 1} 个暗环环序',
          dark: dark,
        ),
        _tableInputCell(
          index: index,
          field: 'left',
          value: ring.left,
          label: '第 ${index + 1} 个暗环左读数',
          dark: dark,
        ),
        _tableInputCell(
          index: index,
          field: 'right',
          value: ring.right,
          label: '第 ${index + 1} 个暗环右读数',
          dark: dark,
        ),
      ],
    );
  }

  Widget _buildResults(bool dark) {
    final result = _calculation;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _resultHeading('逐环计算', dark),
        const SizedBox(height: 7),
        _formulaCaption(
          r'D_i=\left|X_{\mathrm{L},i}-X_{\mathrm{R},i}\right|,\qquad D_i^2=D_i\times D_i',
          dark,
        ),
        const SizedBox(height: 8),
        _buildRingResults(result, dark),
        const SizedBox(height: 14),
        _resultHeading('配对计算', dark),
        const SizedBox(height: 7),
        _formulaCaption(r'\Delta_i=D_{m,i}^{2}-D_{n,i}^{2}', dark),
        const SizedBox(height: 8),
        _buildPairResults(result, dark),
        if (!result.complete) ...[
          const SizedBox(height: 10),
          _errorMessage(result.errorMessage ?? '当前数据还不能完成计算', dark),
        ] else ...[
          const SizedBox(height: 14),
          _buildSummary(result, dark),
        ],
      ],
    );
  }

  Widget _buildRingResults(NewtonRingsCalculation result, bool dark) {
    return _ScrollableTable(
      minWidth: 860,
      borderColor: _borderColor(dark),
      child: Table(
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        columnWidths: const {
          0: FixedColumnWidth(58),
          1: FixedColumnWidth(58),
          2: FixedColumnWidth(92),
          3: FixedColumnWidth(142),
          4: FixedColumnWidth(142),
          5: FixedColumnWidth(184),
          6: FixedColumnWidth(184),
        },
        border: _tableBorder(dark),
        children: [
          TableRow(
            decoration: BoxDecoration(color: _headerColor(dark)),
            children: [
              _headerCell('环号', dark),
              _headerCell('类型', dark),
              _headerCell('环序', dark),
              _headerCellWithMath(
                '左读数',
                r'X_{\mathrm{L}}\,/\,\mathrm{mm}',
                dark,
              ),
              _headerCellWithMath(
                '右读数',
                r'X_{\mathrm{R}}\,/\,\mathrm{mm}',
                dark,
              ),
              _headerCellWithMath(
                '直径',
                r'D=\left|X_{\mathrm{L}}-X_{\mathrm{R}}\right|\,/\,\mathrm{mm}',
                dark,
                result: true,
              ),
              _headerCellWithMath(
                '直径平方',
                r'D^2\,/\,\mathrm{mm^2}',
                dark,
                result: true,
              ),
            ],
          ),
          for (final ring in result.rings) _ringResultRow(ring, dark),
        ],
      ),
    );
  }

  TableRow _ringResultRow(NewtonRingComputed ring, bool dark) {
    return TableRow(
      children: [
        _resultTableCell(
          Text('${ring.index + 1}', style: _cellTextStyle(dark)),
        ),
        _resultTableCell(
          Math.tex(
            ring.kind.value,
            mathStyle: MathStyle.text,
            textStyle: _mathTextStyle(dark, weight: FontWeight.w700),
          ),
        ),
        _resultTableCell(_resultText(ring.order, dark)),
        _resultTableCell(_resultText(ring.left, dark)),
        _resultTableCell(_resultText(ring.right, dark)),
        _resultTableCell(_resultText(ring.diameter, dark)),
        _resultTableCell(_resultText(ring.diameterSquare, dark)),
      ],
    );
  }

  Widget _buildPairResults(NewtonRingsCalculation result, bool dark) {
    return _ScrollableTable(
      minWidth: 760,
      borderColor: _borderColor(dark),
      child: Table(
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        columnWidths: const {
          0: FixedColumnWidth(58),
          1: FixedColumnWidth(92),
          2: FixedColumnWidth(92),
          3: FixedColumnWidth(120),
          4: FixedColumnWidth(132),
          5: FixedColumnWidth(132),
          6: FixedColumnWidth(134),
        },
        border: _tableBorder(dark),
        children: [
          TableRow(
            decoration: BoxDecoration(color: _headerColor(dark)),
            children: [
              _headerCell('组号', dark, result: true),
              _headerCellWithMath('环序', 'm', dark, result: true),
              _headerCellWithMath('环序', 'n', dark, result: true),
              _headerCellWithMath('实际环序差', 'm-n', dark, result: true),
              _headerCellWithMath(
                '',
                r'D_m^2\,/\,\mathrm{mm^2}',
                dark,
                result: true,
              ),
              _headerCellWithMath(
                '',
                r'D_n^2\,/\,\mathrm{mm^2}',
                dark,
                result: true,
              ),
              _headerCellWithMath(
                '',
                r'D_m^2-D_n^2\,/\,\mathrm{mm^2}',
                dark,
                result: true,
              ),
            ],
          ),
          for (final pair in result.pairs) _pairResultRow(pair, dark),
        ],
      ),
    );
  }

  TableRow _pairResultRow(NewtonRingPairComputed pair, bool dark) {
    return TableRow(
      children: [
        _resultTableCell(
          Text('${pair.index + 1}', style: _cellTextStyle(dark)),
        ),
        _resultTableCell(_resultText(pair.mOrder, dark)),
        _resultTableCell(_resultText(pair.nOrder, dark)),
        _resultTableCell(_resultText(pair.actualGap, dark)),
        _resultTableCell(_resultText(pair.mSquare, dark)),
        _resultTableCell(_resultText(pair.nSquare, dark)),
        _resultTableCell(_resultText(pair.deltaSquare, dark)),
      ],
    );
  }

  Widget _buildSummary(NewtonRingsCalculation result, bool dark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _summaryLine(
          label: '平方差平均值',
          formula: r'\overline{\Delta}',
          value: result.average!,
          unit: r'\mathrm{mm^2}',
          note: '五组配对平方差的算术平均',
          dark: dark,
        ),
        _summaryLine(
          label: '平方差平均绝对误差',
          formula: 'e',
          value: result.error!,
          unit: r'\mathrm{mm^2}',
          note: '五组平方差相对平均值的绝对偏差平均',
          dark: dark,
        ),
        _summaryLine(
          label: '曲率半径平均值',
          formula: 'R',
          value: result.radiusMeters!,
          unit: r'\mathrm{m}',
          note: '按计算用环序差和钠光波长换算',
          dark: dark,
        ),
        _summaryLine(
          label: '曲率半径误差',
          formula: r'\Delta R',
          value: result.radiusErrorMeters!,
          unit: r'\mathrm{m}',
          note: '由表格量级误差换算为米制',
          dark: dark,
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: dark ? const Color(0xFF2A2417) : const Color(0xFFFFFAF0),
            border: Border(
              left: BorderSide(
                color: dark ? const Color(0xFFE6B85E) : const Color(0xFFC99327),
                width: 3,
              ),
              top: BorderSide(
                color: dark ? const Color(0xFF6B5831) : const Color(0xFFD8C58F),
              ),
              right: BorderSide(
                color: dark ? const Color(0xFF6B5831) : const Color(0xFFD8C58F),
              ),
              bottom: BorderSide(
                color: dark ? const Color(0xFF6B5831) : const Color(0xFFD8C58F),
              ),
            ),
            borderRadius: BorderRadius.circular(7),
          ),
          child: _math(
            'R=${result.radiusMeters!}\\,\\pm\\,${result.radiusErrorMeters!}\\,\\mathrm{m}',
            dark,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: dark ? const Color(0xFFE7CB8A) : const Color(0xFF725A2A),
          ),
        ),
      ],
    );
  }

  Widget _summaryLine({
    required String label,
    required String formula,
    required String value,
    required String unit,
    required String note,
    required bool dark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth <= 560;
          final labelWidget = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: _summaryLabelStyle(dark)),
              const SizedBox(width: 5),
              _math(
                formula,
                dark,
                fontSize: 13,
                color: _summaryLabelColor(dark),
              ),
            ],
          );
          final valueWidget = _math(
            '$value\\,$unit',
            dark,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: dark ? const Color(0xFF8FD2FF) : const Color(0xFF176496),
          );
          final noteWidget = Text(note, style: _noteTextStyle(dark));
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                labelWidget,
                const SizedBox(height: 2),
                valueWidget,
                noteWidget,
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(width: 160, child: labelWidget),
              Expanded(child: valueWidget),
              noteWidget,
            ],
          );
        },
      ),
    );
  }

  Widget _buildSaveButton(bool dark) {
    return physicsSaveButton(
      context,
      saving: _saving,
      enabled: true,
      onPressed: _save,
    );
  }

  Future<void> _restore() async {
    final saved = await widget.loadSaved();
    if (!mounted || saved == null) return;
    setState(() {
      _state = saved;
      _calculation = NewtonRingsCalculator.calculate(saved);
    });
  }

  void _changeState(NewtonRingsState next) {
    setState(() {
      _state = next;
      _calculation = NewtonRingsCalculator.calculate(next);
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

  TableCell _tableInputCell({
    required int index,
    required String field,
    required String value,
    required String label,
    required bool dark,
  }) {
    return _tableCell(
      _NewtonTextField(
        key: ValueKey<String>('newton-$index-$field'),
        value: value,
        label: label,
        height: 29,
        dark: dark,
        onChanged: (next) {
          _changeState(
            _state.updateRing(
              index,
              (ring) => switch (field) {
                'order' => ring.copyWith(order: next),
                'left' => ring.copyWith(left: next),
                'right' => ring.copyWith(right: next),
                _ => ring,
              },
            ),
          );
        },
      ),
    );
  }
}
