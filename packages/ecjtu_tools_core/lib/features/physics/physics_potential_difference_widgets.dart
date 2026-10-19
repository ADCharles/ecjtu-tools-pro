// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

part of 'physics_potential_difference_page.dart';

Widget _potentialFormulaBlock(bool dark) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(13, 11, 13, 12),
    decoration: BoxDecoration(
      color: dark ? const Color(0xFF14263A) : const Color(0xFFF1F7FB),
      border: const Border(
        left: BorderSide(color: Color(0xFF6DA8D0), width: 3),
      ),
      borderRadius: BorderRadius.circular(5),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('计算公式', style: _potentialFormulaTitleStyle(dark)),
        const SizedBox(height: 7),
        _PotentialFormulaLine(
          number: '1.',
          formula: r'I_{x1}=\frac{U_{x1}}{R_B}',
          dark: dark,
        ),
        _PotentialFormulaLine(
          number: '2.',
          formula: r'I_{x2}=\frac{U_{x2}}{R_B}',
          dark: dark,
        ),
        _PotentialFormulaLine(
          number: '3.',
          formula: r'I_x=\frac{I_{x1}+I_{x2}}{2}',
          dark: dark,
        ),
        _PotentialFormulaLine(
          number: '4.',
          formula: r'\Delta I_x=I_x-I_s',
          dark: dark,
        ),
        _PotentialFormulaLine(
          number: '5.',
          formula: r'K=\frac{|\Delta I_x|_{\max}}{I_{s\max}}\times100\%',
          dark: dark,
        ),
      ],
    ),
  );
}

Widget _potentialSection({
  required String title,
  required bool dark,
  required Widget child,
}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: EcjtuColors.platformSurface(
        dark,
        (dark ? const Color(0xFF101D31) : const Color(0xFFF8FBFD)),
      ),
      border: Border.all(
        color: EcjtuColors.platformBorder(
          dark,
          (dark ? const Color(0xFF31546B) : const Color(0xFFD5E4EF)),
        ),
      ),
      borderRadius: BorderRadius.circular(8),
      boxShadow: physicsCardShadow(dark),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: _potentialSectionTitleStyle(dark)),
        const SizedBox(height: 12),
        child,
      ],
    ),
  );
}

class _PotentialInputContent extends StatelessWidget {
  const _PotentialInputContent({
    required this.state,
    required this.dark,
    required this.onResistanceChanged,
    required this.onUncertaintyChanged,
    required this.onRowChanged,
    required this.onPaste,
  });

  final PotentialDifferenceState state;
  final bool dark;
  final ValueChanged<String> onResistanceChanged;
  final ValueChanged<String> onUncertaintyChanged;
  final void Function(int index, String field, String value) onRowChanged;
  final VoidCallback onPaste;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 280,
          child: _PotentialLabeledInput(
            prefix: '电阻箱',
            formula: r'R_B',
            suffix: '（Ω）',
            value: state.resistance,
            label: '电阻箱电阻',
            dark: dark,
            onChanged: onResistanceChanged,
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: onPaste,
          child: const Text('一键识别粘贴数据'),
          style: physicsSecondaryButtonStyle(context),
        ),
        const SizedBox(height: 10),
        _PotentialInputTable(state: state, dark: dark, onChanged: onRowChanged),
        const SizedBox(height: 10),
        SizedBox(
          width: 280,
          child: _PotentialLabeledInput(
            prefix: '结果不确定度',
            formula: 'u',
            suffix: '（mA，可选）',
            value: state.uncertainty,
            label: '结果不确定度，可选',
            dark: dark,
            onChanged: onUncertaintyChanged,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          '不确定度可以不填；不填不会影响计算，但无法给出建议修约。若你按课程要求自行算出的修约结果不同，请以你的结果为准。',
          style: _potentialMutedTextStyle(dark),
        ),
      ],
    );
  }
}

class _PotentialOutputContent extends StatelessWidget {
  const _PotentialOutputContent({
    required this.calculation,
    required this.dark,
    required this.onExport,
    required this.onSave,
    required this.exporting,
    required this.saving,
  });

  final PotentialDifferenceCalculation calculation;
  final bool dark;
  final VoidCallback onExport;
  final VoidCallback onSave;
  final bool exporting;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    final points = potentialDifferenceChartPoints(calculation);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (calculation.rows.isEmpty)
          Text(
            calculation.error.isEmpty ? '填写完整数据后显示结果' : calculation.error,
            style: _potentialEmptyTextStyle(dark),
          )
        else ...[
          _potentialResultTable(calculation, dark),
          if (calculation.error.isNotEmpty) ...[
            const SizedBox(height: 7),
            Text(calculation.error, style: _potentialErrorTextStyle(dark)),
          ],
        ],
        const SizedBox(height: 14),
        _potentialSummary(calculation, dark),
        const SizedBox(height: 12),
        _potentialChartTitle(dark),
        if (points.isNotEmpty) ...[
          const SizedBox(height: 7),
          PotentialDifferenceChartCard(points: points, dark: dark),
        ],
        if (calculation.recommendedRows.isNotEmpty) ...[
          const SizedBox(height: 12),
          _potentialRounding(calculation, dark),
        ],
        const SizedBox(height: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OutlinedButton(
              onPressed: exporting || points.isEmpty ? null : onExport,
              child: Text(exporting ? '正在生成' : '生成误差图 PDF'),
              style: physicsSecondaryButtonStyle(context),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: saving ? null : onSave,
              child: Text(saving ? '正在保存' : '保存数据'),
              style: physicsSecondaryButtonStyle(context),
            ),
          ],
        ),
      ],
    );
  }
}

class _PotentialFormulaLine extends StatelessWidget {
  const _PotentialFormulaLine({
    required this.number,
    required this.formula,
    required this.dark,
  });

  final String number;
  final String formula;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 42),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 28,
              child: Text(number, style: _potentialFormulaNumberStyle(dark)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Math.tex(
                  formula,
                  mathStyle: MathStyle.display,
                  textStyle: _potentialFormulaTextStyle(dark, 15),
                  onErrorFallback: (_) => const SizedBox.shrink(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PotentialLabeledInput extends StatelessWidget {
  const _PotentialLabeledInput({
    required this.prefix,
    required this.formula,
    this.suffix = '',
    required this.value,
    required this.label,
    required this.dark,
    required this.onChanged,
  });

  final String prefix;
  final String formula;
  final String suffix;
  final String value;
  final String label;
  final bool dark;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _potentialMixedLabel(
          prefix: prefix,
          formula: formula,
          suffix: suffix,
          dark: dark,
        ),
        const SizedBox(height: 5),
        _PotentialTextField(
          value: value,
          label: label,
          dark: dark,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _PotentialTextField extends StatefulWidget {
  const _PotentialTextField({
    super.key,
    required this.value,
    required this.label,
    required this.dark,
    required this.onChanged,
    this.compact = false,
  });

  final String value;
  final String label;
  final bool dark;
  final ValueChanged<String> onChanged;
  final bool compact;

  @override
  State<_PotentialTextField> createState() => _PotentialTextFieldState();
}

class _PotentialTextFieldState extends State<_PotentialTextField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _PotentialTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && _controller.text != widget.value) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final border = widget.dark
        ? const Color(0xFF426B83)
        : const Color(0xFFB9CFDD);
    return Semantics(
      textField: true,
      label: widget.label,
      child: SizedBox(
        height: widget.compact ? 30 : 32,
        child: TextField(
          controller: _controller,
          onChanged: widget.onChanged,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
            signed: true,
          ),
          textAlign: TextAlign.center,
          textInputAction: TextInputAction.next,
          style: TextStyle(
            color: widget.dark
                ? const Color(0xFFE1EDFF)
                : const Color(0xFF223549),
            fontSize: 12,
            height: 1.15,
          ),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: widget.dark ? const Color(0xFF14263A) : Colors.white,
            contentPadding: EdgeInsets.symmetric(
              horizontal: widget.compact ? 5 : 8,
              vertical: widget.compact ? 4 : 6,
            ),
            border: _potentialInputBorder(border),
            enabledBorder: _potentialInputBorder(border),
            focusedBorder: _potentialInputBorder(
              widget.dark ? const Color(0xFF8FD2FF) : const Color(0xFF287AA8),
            ),
          ),

          contextMenuBuilder: buildEcjtuPlatformTextContextMenu,
        ),
      ),
    );
  }
}

class _PotentialInputTable extends StatelessWidget {
  const _PotentialInputTable({
    required this.state,
    required this.dark,
    required this.onChanged,
  });

  final PotentialDifferenceState state;
  final bool dark;
  final void Function(int index, String field, String value) onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        width: 126 + state.rows.length * 94,
        decoration: BoxDecoration(
          color: EcjtuColors.platformSurface(
            dark,
            (dark ? const Color(0xFF101D31) : Colors.white),
          ),
          border: Border.all(color: _potentialBorderColor(dark)),
          borderRadius: BorderRadius.circular(7),
        ),
        clipBehavior: Clip.antiAlias,
        child: Table(
          columnWidths: _potentialColumnWidths(state.rows.length),
          border: _potentialTableBorder(dark),
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            TableRow(
              decoration: BoxDecoration(color: _potentialHeaderColor(dark)),
              children: [
                _potentialHeaderCell('数据项', dark),
                for (var index = 0; index < state.rows.length; index++)
                  _potentialHeaderCell('第 ${index + 1} 组', dark),
              ],
            ),
            _potentialInputRow(
              label: '标准电流',
              formula: r'I_s\,/\,\mathrm{mA}',
              field: 'standard',
              state: state,
              dark: dark,
              onChanged: onChanged,
            ),
            _potentialInputRow(
              label: '第一次测量电压',
              formula: r'U_{x1}\,/\,\mathrm{mV}',
              field: 'ux1',
              state: state,
              dark: dark,
              onChanged: onChanged,
            ),
            _potentialInputRow(
              label: '第二次测量电压',
              formula: r'U_{x2}\,/\,\mathrm{mV}',
              field: 'ux2',
              state: state,
              dark: dark,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

Map<int, TableColumnWidth> _potentialColumnWidths(int count) {
  return {
    0: const FixedColumnWidth(126),
    for (var index = 1; index <= count; index++)
      index: const FixedColumnWidth(94),
  };
}

TableRow _potentialInputRow({
  required String label,
  required String formula,
  required String field,
  required PotentialDifferenceState state,
  required bool dark,
  required void Function(int index, String field, String value) onChanged,
}) {
  return TableRow(
    children: [
      _potentialTableCell(_potentialFormulaLabel(formula, dark), dark),
      for (var index = 0; index < state.rows.length; index++)
        _potentialTableCell(
          _PotentialTextField(
            key: ValueKey<String>('potential-$field-$index'),
            value: switch (field) {
              'standard' => state.rows[index].standard,
              'ux1' => state.rows[index].ux1,
              'ux2' => state.rows[index].ux2,
              _ => '',
            },
            label: '第 ${index + 1} 组 $label',
            dark: dark,
            onChanged: (value) => onChanged(index, field, value),
            compact: true,
          ),
          dark,
        ),
    ],
  );
}

TableCell _potentialTableCell(Widget child, bool dark) {
  return TableCell(
    child: Container(
      constraints: const BoxConstraints(minHeight: 38),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      alignment: Alignment.center,
      child: child,
    ),
  );
}

Widget _potentialHeaderCell(String text, bool dark) {
  return _potentialTableCell(
    Text(
      text,
      textAlign: TextAlign.center,
      style: _potentialHeaderTextStyle(dark),
    ),
    dark,
  );
}

Widget _potentialResultTable(
  PotentialDifferenceCalculation calculation,
  bool dark,
) {
  return SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Container(
      width: 126 + 8 * 94,
      decoration: BoxDecoration(
        color: EcjtuColors.platformSurface(
          dark,
          (dark ? const Color(0xFF101D31) : Colors.white),
        ),
        border: Border.all(color: _potentialBorderColor(dark)),
        borderRadius: BorderRadius.circular(7),
      ),
      clipBehavior: Clip.antiAlias,
      child: Table(
        columnWidths: _potentialColumnWidths(8),
        border: _potentialTableBorder(dark),
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          TableRow(
            decoration: BoxDecoration(color: _potentialHeaderColor(dark)),
            children: [
              _potentialHeaderCell('数据项', dark),
              for (var index = 0; index < 8; index++)
                _potentialHeaderCell('第 ${index + 1} 组', dark),
            ],
          ),
          _potentialResultRow(
            formula: r'I_{x1}\,/\,\mathrm{mA}',
            values: calculation.rows,
            value: (row) => row.ix1,
            dark: dark,
          ),
          _potentialResultRow(
            formula: r'I_{x2}\,/\,\mathrm{mA}',
            values: calculation.rows,
            value: (row) => row.ix2,
            dark: dark,
          ),
          _potentialResultRow(
            formula: r'I_x\,/\,\mathrm{mA}',
            values: calculation.rows,
            value: (row) => row.ix,
            dark: dark,
          ),
          _potentialResultRow(
            formula: r'\Delta I_x\,/\,\mathrm{mA}',
            values: calculation.rows,
            value: (row) => row.delta,
            dark: dark,
          ),
        ],
      ),
    ),
  );
}

TableRow _potentialResultRow({
  required String formula,
  required List<PotentialDifferenceResultRow> values,
  required double? Function(PotentialDifferenceResultRow row) value,
  required bool dark,
}) {
  final rowsByIndex = <int, PotentialDifferenceResultRow>{
    for (final row in values) row.index: row,
  };
  return TableRow(
    children: [
      _potentialTableCell(_potentialFormulaLabel(formula, dark), dark),
      for (var index = 0; index < 8; index++)
        _potentialTableCell(
          Text(
            rowsByIndex[index] != null && !rowsByIndex[index]!.invalid
                ? PotentialDifferenceCalculator.format(
                    value(rowsByIndex[index]!),
                  )
                : '—',
            textAlign: TextAlign.center,
            style: _potentialCellTextStyle(dark),
          ),
          dark,
        ),
    ],
  );
}

Widget _potentialSummary(
  PotentialDifferenceCalculation calculation,
  bool dark,
) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
    decoration: BoxDecoration(
      color: dark ? const Color(0xFF12263A) : const Color(0xFFEEF7FC),
      border: Border.all(
        color: dark ? const Color(0xFF396B87) : const Color(0xFFB8D8EA),
      ),
      borderRadius: BorderRadius.circular(7),
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final value = calculation.k == null
            ? '—'
            : PotentialDifferenceCalculator.format(calculation.k);
        final detail = calculation.k == null
            ? '填写完整数据后自动计算'
            : '最大误差 ${PotentialDifferenceCalculator.format(calculation.maxDelta, digits: 12)}，最大标准电流 ${PotentialDifferenceCalculator.format(calculation.maxStandard, digits: 12)}';
        if (constraints.maxWidth <= 520) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text('级别 K', style: _potentialSummaryLabelStyle(dark)),
                  const SizedBox(width: 10),
                  Flexible(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Text(
                        value,
                        style: _potentialSummaryValueStyle(dark),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(detail, style: _potentialMutedTextStyle(dark)),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text('级别 K', style: _potentialSummaryLabelStyle(dark)),
            const SizedBox(width: 10),
            Flexible(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Text(value, style: _potentialSummaryValueStyle(dark)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: Text(
                detail,
                textAlign: TextAlign.right,
                style: _potentialMutedTextStyle(dark),
              ),
            ),
          ],
        );
      },
    ),
  );
}

Widget _potentialChartTitle(bool dark) {
  final heading = Row(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.baseline,
    textBaseline: TextBaseline.alphabetic,
    children: [
      Text('误差图：', style: _potentialChartTitleStyle(dark)),
      Math.tex(
        r'\Delta I_x-I_s',
        mathStyle: MathStyle.text,
        textStyle: _potentialChartTitleMathStyle(dark),
        onErrorFallback: (_) => const SizedBox.shrink(),
      ),
    ],
  );
  final axes = Wrap(
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: 4,
    children: [
      Text('横轴', style: _potentialChartAxisStyle(dark)),
      Math.tex(
        r'I_s\,/\,\mathrm{mA}',
        mathStyle: MathStyle.text,
        textStyle: _potentialChartAxisMathStyle(dark),
        onErrorFallback: (_) => const SizedBox.shrink(),
      ),
      Text('，纵轴', style: _potentialChartAxisStyle(dark)),
      Math.tex(
        r'\Delta I_x\,/\,\mathrm{mA}',
        mathStyle: MathStyle.text,
        textStyle: _potentialChartAxisMathStyle(dark),
        onErrorFallback: (_) => const SizedBox.shrink(),
      ),
    ],
  );
  return LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth <= 620) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [heading, const SizedBox(height: 4), axes],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(child: heading),
          axes,
        ],
      );
    },
  );
}

Widget _potentialRounding(
  PotentialDifferenceCalculation calculation,
  bool dark,
) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
    decoration: BoxDecoration(
      color: dark ? const Color(0xFF2A2417) : const Color(0xFFFFFAF0),
      border: Border(
        top: BorderSide(
          color: dark ? const Color(0xFF6B5831) : const Color(0xFFD8C58F),
        ),
        right: BorderSide(
          color: dark ? const Color(0xFF6B5831) : const Color(0xFFD8C58F),
        ),
        bottom: BorderSide(
          color: dark ? const Color(0xFF6B5831) : const Color(0xFFD8C58F),
        ),
        left: BorderSide(
          color: dark ? const Color(0xFFE6B85E) : const Color(0xFFC99327),
          width: 3,
        ),
      ),
      borderRadius: BorderRadius.circular(7),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('建议报告值', style: _potentialRoundingTitleStyle(dark)),
        const SizedBox(height: 5),
        for (var index = 0; index < calculation.recommendedRows.length; index++)
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  '第 ${calculation.rows[index].index + 1} 组：',
                  style: _potentialMutedTextStyle(dark),
                ),
                Math.tex(
                  r'I_x=' +
                      (calculation.recommendedRows[index].ix ?? '—') +
                      r'\,\mathrm{mA}',
                  mathStyle: MathStyle.text,
                  textStyle: _potentialMutedTextStyle(dark),
                  onErrorFallback: (_) => const SizedBox.shrink(),
                ),
                Text('，', style: _potentialMutedTextStyle(dark)),
                Math.tex(
                  r'\Delta I_x=' +
                      (calculation.recommendedRows[index].delta ?? '—') +
                      r'\,\mathrm{mA}',
                  mathStyle: MathStyle.text,
                  textStyle: _potentialMutedTextStyle(dark),
                  onErrorFallback: (_) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

Widget _potentialMixedLabel({
  required String prefix,
  required String formula,
  required bool dark,
  double fontSize = 11,
  String suffix = '',
}) {
  return Wrap(
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: 4,
    children: [
      Text(prefix, style: _potentialFieldLabelStyle(dark)),
      Math.tex(
        formula,
        mathStyle: MathStyle.text,
        textStyle: _potentialInputFormulaTextStyle(dark, fontSize + 1),
        onErrorFallback: (_) => const SizedBox.shrink(),
      ),
      if (suffix.isNotEmpty)
        Text(suffix, style: _potentialFieldLabelStyle(dark)),
    ],
  );
}

Widget _potentialFormulaLabel(String formula, bool dark) {
  return SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Math.tex(
      formula,
      mathStyle: MathStyle.text,
      textStyle: _potentialRecordLabelMathStyle(dark),
      onErrorFallback: (_) => const SizedBox.shrink(),
    ),
  );
}

TextStyle _potentialSectionTitleStyle(bool dark) => TextStyle(
  color: EcjtuColors.platformText(
    dark,
    (dark ? const Color(0xFFE1EDFF) : const Color(0xFF223549)),
  ),
  fontSize: 13,
  fontWeight: FontWeight.w700,
  height: 1.3,
);

TextStyle _potentialFormulaTitleStyle(bool dark) => TextStyle(
  color: EcjtuColors.platformText(
    dark,
    (dark ? const Color(0xFFD6E6F3) : const Color(0xFF275B7A)),
  ),
  fontSize: 12,
  fontWeight: FontWeight.w700,
  height: 1.3,
);

TextStyle _potentialFormulaNumberStyle(bool dark) => TextStyle(
  color: EcjtuColors.platformText(
    dark,
    (dark ? const Color(0xFFE1EDFF) : const Color(0xFF223549)),
  ),
  fontSize: 16,
  fontWeight: FontWeight.w500,
  height: 1.2,
);

TextStyle _potentialFormulaTextStyle(bool dark, double size) => TextStyle(
  color: EcjtuColors.platformText(
    dark,
    (dark ? const Color(0xFFE1EDFF) : const Color(0xFF223549)),
  ),
  fontSize: size,
  height: 1.35,
);

TextStyle _potentialInputFormulaTextStyle(bool dark, double size) => TextStyle(
  color: EcjtuColors.platformMuted(
    dark,
    (dark ? const Color(0xFF9EACC3) : const Color(0xFF667B8E)),
  ),
  fontSize: size,
  height: 1.25,
);

TextStyle _potentialRecordLabelMathStyle(bool dark) => TextStyle(
  color: EcjtuColors.platformText(
    dark,
    (dark ? const Color(0xFFD6E6F3) : const Color(0xFF275B7A)),
  ),
  fontSize: 12,
  fontWeight: FontWeight.w700,
  height: 1.2,
);

TextStyle _potentialHeaderTextStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFFD6E6F3) : const Color(0xFF5D7487),
  fontSize: 12,
  fontWeight: FontWeight.w700,
  height: 1.25,
);

TextStyle _potentialCellTextStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFFB7D9ED) : const Color(0xFF334F65),
  fontSize: 12,
  height: 1.25,
);

TextStyle _potentialMutedTextStyle(bool dark) => TextStyle(
  color: EcjtuColors.platformMuted(
    dark,
    (dark ? const Color(0xFF9EACC3) : const Color(0xFF667B8E)),
  ),
  fontSize: 11,
  height: 1.45,
);

TextStyle _potentialFieldLabelStyle(bool dark) => TextStyle(
  color: EcjtuColors.platformMuted(
    dark,
    (dark ? const Color(0xFF9EACC3) : const Color(0xFF667B8E)),
  ),
  fontSize: 11,
  fontWeight: FontWeight.w400,
  height: 1.3,
);

TextStyle _potentialEmptyTextStyle(bool dark) => TextStyle(
  color: EcjtuColors.platformMuted(
    dark,
    (dark ? const Color(0xFF9EACC3) : const Color(0xFF667B8E)),
  ),
  fontSize: 11,
  height: 1.5,
);

TextStyle _potentialErrorTextStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFFFFB5BD) : const Color(0xFFB4533F),
  fontSize: 11,
  height: 1.5,
);

TextStyle _potentialSummaryLabelStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFFB7D9ED) : const Color(0xFF527087),
  fontSize: 12,
  fontWeight: FontWeight.w600,
  height: 1.3,
);

TextStyle _potentialSummaryValueStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFF8FD2FF) : const Color(0xFF176496),
  fontSize: 13,
  fontWeight: FontWeight.w800,
  height: 1.2,
);

TextStyle _potentialChartTitleStyle(bool dark) => TextStyle(
  color: EcjtuColors.platformText(
    dark,
    (dark ? const Color(0xFFE1EDFF) : const Color(0xFF223549)),
  ),
  fontSize: 13,
  fontWeight: FontWeight.w700,
  height: 1.3,
);

TextStyle _potentialChartTitleMathStyle(bool dark) => TextStyle(
  color: EcjtuColors.platformText(
    dark,
    (dark ? const Color(0xFFE1EDFF) : const Color(0xFF223549)),
  ),
  fontSize: 13,
  fontWeight: FontWeight.w700,
  height: 1.3,
);

TextStyle _potentialChartAxisStyle(bool dark) => TextStyle(
  color: EcjtuColors.platformMuted(
    dark,
    (dark ? const Color(0xFF9EACC3) : const Color(0xFF667B8E)),
  ),
  fontSize: 11,
  height: 1.3,
);

TextStyle _potentialChartAxisMathStyle(bool dark) => TextStyle(
  color: EcjtuColors.platformMuted(
    dark,
    (dark ? const Color(0xFF9EACC3) : const Color(0xFF667B8E)),
  ),
  fontSize: 11,
  height: 1.3,
);

TextStyle _potentialRoundingTitleStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFFE7CB8A) : const Color(0xFF725A2A),
  fontSize: 12,
  fontWeight: FontWeight.w700,
  height: 1.3,
);

Color _potentialBorderColor(bool dark) => EcjtuColors.platformBorder(
  dark,
  (dark ? const Color(0xFF31546B) : const Color(0xFFD5E4EF)),
);

Color _potentialHeaderColor(bool dark) =>
    dark ? const Color(0xFF14263A) : const Color(0xFFEEF6FA);

TableBorder _potentialTableBorder(bool dark) {
  final color = dark ? const Color(0xFF28465C) : const Color(0xFFE5EDF2);
  return TableBorder(
    horizontalInside: BorderSide(color: color),
    verticalInside: BorderSide(color: color),
    top: BorderSide.none,
    bottom: BorderSide.none,
    left: BorderSide.none,
    right: BorderSide.none,
  );
}

OutlineInputBorder _potentialInputBorder(Color color) => OutlineInputBorder(
  borderRadius: BorderRadius.circular(6),
  borderSide: BorderSide(color: color),
);
