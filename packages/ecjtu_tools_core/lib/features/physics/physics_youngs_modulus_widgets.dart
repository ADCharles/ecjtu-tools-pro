// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

part of 'physics_youngs_modulus_page.dart';

Widget _youngsFormulaBlock(bool dark) {
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
        Text('计算公式', style: _youngsFormulaTitleStyle(dark)),
        const SizedBox(height: 7),
        _YoungsFormulaLine(
          number: '1.',
          formula: r'\bar l_i=\frac{l_i+l_i\prime}{2}',
          dark: dark,
        ),
        _YoungsFormulaLine(
          number: '2.',
          formula: r'\Delta l_i=\left|\bar l_{i+4}-\bar l_i\right|',
          dark: dark,
        ),
        _YoungsFormulaLine(
          number: '3.',
          formula: r'\overline{\Delta l}=\frac{1}{4}\sum_{i=0}^{3}\Delta l_i',
          dark: dark,
        ),
        _YoungsFormulaLine(
          number: '4.',
          formula: r'Y=\frac{8FLD}{\pi d^2a\overline{\Delta l}}',
          dark: dark,
        ),
        _YoungsFormulaLine(
          number: '5.',
          formula:
              r'E_Y=\frac{\Delta D}{D}+\frac{\Delta L}{L}+2\frac{\Delta d}{d}+\frac{\Delta a}{a}+\frac{\Delta(\Delta l)}{\overline{\Delta l}},\qquad\Delta Y=YE_Y',
          dark: dark,
        ),
      ],
    ),
  );
}

Widget _youngsSection({
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
        Text(title, style: _youngsSectionTitleStyle(dark)),
        const SizedBox(height: 12),
        child,
      ],
    ),
  );
}

class _YoungsFormulaLine extends StatelessWidget {
  const _YoungsFormulaLine({
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
              child: Text(number, style: _youngsFormulaNumberStyle(dark)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _youngsMath(
                formula,
                dark,
                fontSize: 15,
                mathStyle: MathStyle.display,
                color: EcjtuColors.platformText(
                  dark,
                  (dark ? const Color(0xFFE1EDFF) : const Color(0xFF223549)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _YoungsDiameterInput extends StatelessWidget {
  const _YoungsDiameterInput({
    required this.zeroError,
    required this.diameter,
    required this.dark,
    required this.onZeroErrorChanged,
    required this.onChanged,
  });

  final String zeroError;
  final List<YoungsModulusDiameterInput> diameter;
  final bool dark;
  final ValueChanged<String> onZeroErrorChanged;
  final void Function(int index, String field, String value) onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 250,
          child: _YoungsLabeledInput(
            prefix: '螺旋测微计零差',
            formula: r'\delta_0\,/\,\mathrm{mm}',
            value: zeroError,
            label: '螺旋测微计零差',
            dark: dark,
            onChanged: onZeroErrorChanged,
          ),
        ),
        const SizedBox(height: 10),
        _YoungsScrollableTable(
          minWidth: 530,
          dark: dark,
          child: Table(
            columnWidths: const {
              0: FixedColumnWidth(106),
              1: FixedColumnWidth(212),
              2: FixedColumnWidth(212),
            },
            border: _youngsTableBorder(dark),
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              TableRow(
                decoration: BoxDecoration(color: _youngsHeaderColor(dark)),
                children: [
                  _youngsHeaderCell('次数', dark),
                  _youngsHeaderMathCell('初始状态', r'd_0\,/\,\mathrm{mm}', dark),
                  _youngsHeaderMathCell('满负荷', r'd_f\,/\,\mathrm{mm}', dark),
                ],
              ),
              for (var index = 0; index < diameter.length; index++)
                TableRow(
                  children: [
                    _youngsInputRowHeaderCell('${index + 1}', dark),
                    _youngsInputCell(
                      key: 'youngs-diameter-$index-initial',
                      value: diameter[index].initial,
                      label: '金属丝直径第 ${index + 1} 次初始状态',
                      dark: dark,
                      onChanged: (value) => onChanged(index, 'initial', value),
                    ),
                    _youngsInputCell(
                      key: 'youngs-diameter-$index-full-load',
                      value: diameter[index].fullLoad,
                      label: '金属丝直径第 ${index + 1} 次满负荷',
                      dark: dark,
                      onChanged: (value) => onChanged(index, 'fullLoad', value),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _YoungsScaleInput extends StatelessWidget {
  const _YoungsScaleInput({
    required this.values,
    required this.dark,
    required this.onChanged,
  });

  final List<YoungsModulusScaleInput> values;
  final bool dark;
  final void Function(int index, String field, String value) onChanged;

  @override
  Widget build(BuildContext context) {
    return _YoungsScrollableTable(
      minWidth: 530,
      dark: dark,
      child: Table(
        columnWidths: const {
          0: FixedColumnWidth(106),
          1: FixedColumnWidth(212),
          2: FixedColumnWidth(212),
        },
        border: _youngsTableBorder(dark),
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          TableRow(
            decoration: BoxDecoration(color: _youngsHeaderColor(dark)),
            children: [
              _youngsHeaderMathCell('负荷', r'm\,/\,\mathrm{kg}', dark),
              _youngsHeaderMathCell('加砝码', r'l_i\,/\,\mathrm{cm}', dark),
              _youngsHeaderMathCell('减砝码', r"l_i'\,/\,\mathrm{cm}", dark),
            ],
          ),
          for (var index = 0; index < values.length; index++)
            TableRow(
              children: [
                _youngsInputRowHeaderCell('$index', dark),
                _youngsInputCell(
                  key: 'youngs-scale-$index-add',
                  value: values[index].add,
                  label: '负荷 $index kg 加砝码标尺读数',
                  dark: dark,
                  onChanged: (value) => onChanged(index, 'add', value),
                ),
                _youngsInputCell(
                  key: 'youngs-scale-$index-remove',
                  value: values[index].remove,
                  label: '负荷 $index kg 减砝码标尺读数',
                  dark: dark,
                  onChanged: (value) => onChanged(index, 'remove', value),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

Widget _youngsResultTables(YoungsModulusCalculation calculation, bool dark) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('中间数据', style: _youngsResultHeadingStyle(dark)),
      const SizedBox(height: 9),
      _youngsDiameterResultTable(calculation, dark),
      const SizedBox(height: 11),
      _youngsScaleResultTable(calculation, dark),
      const SizedBox(height: 11),
      _youngsDifferenceResultTable(calculation, dark),
    ],
  );
}

Widget _youngsDiameterResultTable(
  YoungsModulusCalculation calculation,
  bool dark,
) {
  return _YoungsScrollableTable(
    minWidth: 530,
    dark: dark,
    child: Table(
      columnWidths: const {0: FixedColumnWidth(106), 1: FixedColumnWidth(424)},
      border: _youngsTableBorder(dark),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          decoration: BoxDecoration(color: _youngsHeaderColor(dark)),
          children: [
            _youngsHeaderCell('次数', dark),
            _youngsHeaderMathCell('直径', r'\bar d_i\,/\,\mathrm{mm}', dark),
          ],
        ),
        for (final item in calculation.diameter)
          TableRow(
            children: [
              _youngsTableCell(
                Text('${item.index + 1}', style: _youngsCellTextStyle(dark)),
              ),
              _youngsResultCell(
                YoungsModulusCalculator.format(item.mean),
                dark,
              ),
            ],
          ),
      ],
    ),
  );
}

Widget _youngsScaleResultTable(
  YoungsModulusCalculation calculation,
  bool dark,
) {
  return _YoungsScrollableTable(
    minWidth: 530,
    dark: dark,
    child: Table(
      columnWidths: const {0: FixedColumnWidth(106), 1: FixedColumnWidth(424)},
      border: _youngsTableBorder(dark),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          decoration: BoxDecoration(color: _youngsHeaderColor(dark)),
          children: [
            _youngsHeaderMathCell('负荷', r'm\,/\,\mathrm{kg}', dark),
            _youngsHeaderMathCell('标尺平均值', r'\bar l_i\,/\,\mathrm{cm}', dark),
          ],
        ),
        for (final item in calculation.scale)
          TableRow(
            children: [
              _youngsTableCell(
                Text('${item.index}', style: _youngsCellTextStyle(dark)),
              ),
              _youngsResultCell(
                YoungsModulusCalculator.format(item.mean),
                dark,
              ),
            ],
          ),
      ],
    ),
  );
}

Widget _youngsDifferenceResultTable(
  YoungsModulusCalculation calculation,
  bool dark,
) {
  return _YoungsScrollableTable(
    minWidth: 720,
    dark: dark,
    child: Table(
      columnWidths: const {
        0: FixedColumnWidth(106),
        1: FixedColumnWidth(160),
        2: FixedColumnWidth(175),
        3: FixedColumnWidth(279),
      },
      border: _youngsTableBorder(dark),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          decoration: BoxDecoration(color: _youngsHeaderColor(dark)),
          children: [
            _youngsHeaderCell('逐差组', dark),
            _youngsHeaderMathCell('低负荷', r'\bar l_i\,/\,\mathrm{cm}', dark),
            _youngsHeaderMathCell('高负荷', r'\bar l_{i+4}\,/\,\mathrm{cm}', dark),
            _youngsHeaderMathCell(
              '伸长量',
              r'\Delta l_i=|\bar l_{i+4}-\bar l_i|\,/\,\mathrm{cm}',
              dark,
            ),
          ],
        ),
        for (final item in calculation.differences)
          TableRow(
            children: [
              _youngsTableCell(
                Text('${item.index + 1}', style: _youngsCellTextStyle(dark)),
              ),
              _youngsResultCell(
                YoungsModulusCalculator.format(item.lower),
                dark,
              ),
              _youngsResultCell(
                YoungsModulusCalculator.format(item.upper),
                dark,
              ),
              _youngsResultCell(
                YoungsModulusCalculator.format(item.difference),
                dark,
              ),
            ],
          ),
      ],
    ),
  );
}

Widget _youngsResultSummary(YoungsModulusCalculation calculation, bool dark) {
  final items = [
    (
      label: '金属丝直径平均值',
      formula: r'\bar d\,/\,\mathrm{mm}',
      value: YoungsModulusCalculator.format(
        calculation.diameterAverageMillimeter,
      ),
    ),
    (
      label: '金属丝直径平均绝对误差',
      formula: r'\Delta d\,/\,\mathrm{mm}',
      value: YoungsModulusCalculator.format(
        calculation.diameterErrorMillimeter,
      ),
    ),
    (
      label: '伸长量平均值',
      formula: r'\overline{\Delta l}\,/\,\mathrm{cm}',
      value: YoungsModulusCalculator.format(calculation.extensionCentimeter),
    ),
    (
      label: '伸长量平均偏差',
      formula: r'\Delta(\Delta l)\,/\,\mathrm{cm}',
      value: YoungsModulusCalculator.format(
        calculation.extensionErrorCentimeter,
      ),
    ),
    (
      label: '作用力',
      formula: r'F\,/\,\mathrm{N}',
      value: YoungsModulusCalculator.format(calculation.force),
    ),
    (
      label: '杨氏弹性模量',
      formula: r'Y\,/\,\mathrm{Pa}',
      value: YoungsModulusCalculator.format(calculation.young),
    ),
    (
      label: '相对误差',
      formula: r'E_Y',
      value: calculation.relativeError == null
          ? '—'
          : '${YoungsModulusCalculator.format(calculation.relativeError! * 100)}%',
    ),
    (
      label: '绝对误差',
      formula: r'\Delta Y\,/\,\mathrm{Pa}',
      value: YoungsModulusCalculator.format(calculation.absoluteError),
    ),
  ];
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('杨氏模量', style: _youngsResultHeadingStyle(dark)),
      const SizedBox(height: 9),
      LayoutBuilder(
        builder: (context, constraints) {
          final columns = MediaQuery.sizeOf(context).width <= 520 ? 1 : 2;
          final gap = 9.0;
          final width = columns == 1
              ? constraints.maxWidth
              : (constraints.maxWidth - gap) / columns;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final item in items)
                SizedBox(
                  width: width,
                  child: _youngsSummaryLine(
                    label: item.label,
                    formula: item.formula,
                    value: item.value,
                    dark: dark,
                  ),
                ),
            ],
          );
        },
      ),
      const SizedBox(height: 10),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: dark ? const Color(0xFF12263A) : const Color(0xFFF0F8FC),
          border: Border.all(
            color: dark ? const Color(0xFF396B87) : const Color(0xFF9FC6DC),
          ),
          borderRadius: BorderRadius.circular(7),
        ),
        child: _youngsMath(
          calculation.young != null && calculation.absoluteError != null
              ? 'Y=(${YoungsModulusCalculator.format(calculation.young)}\\pm${YoungsModulusCalculator.format(calculation.absoluteError)})\\,\\mathrm{Pa}'
              : r'Y=(\quad\pm\quad)\,\mathrm{Pa}',
          dark,
          fontSize: 16,
          color: dark ? const Color(0xFF8FD2FF) : const Color(0xFF176496),
        ),
      ),
    ],
  );
}

Widget _youngsSummaryLine({
  required String label,
  required String formula,
  required String value,
  required bool dark,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
    decoration: BoxDecoration(
      color: EcjtuColors.platformSurface(
        dark,
        (dark ? const Color(0xFF101D31) : Colors.white),
      ),
      border: Border.all(
        color: EcjtuColors.platformBorder(
          dark,
          (dark ? const Color(0xFF31546B) : const Color(0xFFD5E4EF)),
        ),
      ),
      borderRadius: BorderRadius.circular(7),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: _youngsMixedLabel(
            prefix: label,
            formula: formula,
            dark: dark,
            fontSize: 12,
            summary: true,
          ),
        ),
        const SizedBox(width: 8),
        Text(value, style: _youngsSummaryValueStyle(dark)),
      ],
    ),
  );
}

class _YoungsLabeledInput extends StatelessWidget {
  const _YoungsLabeledInput({
    required this.prefix,
    required this.formula,
    required this.value,
    required this.label,
    required this.dark,
    required this.onChanged,
  });

  final String prefix;
  final String formula;
  final String value;
  final String label;
  final bool dark;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _youngsMixedLabel(prefix: prefix, formula: formula, dark: dark),
        const SizedBox(height: 5),
        _YoungsTextField(
          value: value,
          label: label,
          dark: dark,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _YoungsTextField extends StatefulWidget {
  const _YoungsTextField({
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
  State<_YoungsTextField> createState() => _YoungsTextFieldState();
}

class _YoungsTextFieldState extends State<_YoungsTextField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _YoungsTextField oldWidget) {
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
        height: widget.compact ? 29 : 34,
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
            border: _youngsInputBorder(border),
            enabledBorder: _youngsInputBorder(border),
            focusedBorder: _youngsInputBorder(
              widget.dark ? const Color(0xFF8FD2FF) : const Color(0xFF287AA8),
            ),
          ),

          contextMenuBuilder: buildEcjtuPlatformTextContextMenu,
        ),
      ),
    );
  }
}

class _YoungsScrollableTable extends StatelessWidget {
  const _YoungsScrollableTable({
    required this.minWidth,
    required this.dark,
    required this.child,
  });

  final double minWidth;
  final bool dark;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        width: minWidth,
        decoration: BoxDecoration(
          color: EcjtuColors.platformSurface(
            dark,
            (dark ? const Color(0xFF101D31) : Colors.white),
          ),
          border: Border.all(color: _youngsBorderColor(dark)),
          borderRadius: BorderRadius.circular(7),
        ),
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }
}

TableCell _youngsTableCell(Widget child, {Color? backgroundColor}) {
  return TableCell(
    child: Container(
      constraints: const BoxConstraints(minHeight: 34),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      alignment: Alignment.center,
      color: backgroundColor,
      child: child,
    ),
  );
}

TableCell _youngsInputRowHeaderCell(String text, bool dark) {
  return _youngsTableCell(
    Text(text, style: _youngsRowHeaderTextStyle(dark)),
    backgroundColor: dark ? const Color(0xFF12263A) : const Color(0xFFF8FBFD),
  );
}

Widget _youngsHeaderCell(String text, bool dark) {
  return _youngsTableCell(
    Text(
      text,
      textAlign: TextAlign.center,
      style: _youngsHeaderTextStyle(dark),
    ),
  );
}

Widget _youngsHeaderMathCell(String text, String formula, bool dark) {
  return _youngsTableCell(
    _youngsMixedLabel(prefix: text, formula: formula, dark: dark, header: true),
  );
}

TableCell _youngsInputCell({
  required String key,
  required String value,
  required String label,
  required bool dark,
  required ValueChanged<String> onChanged,
}) {
  return _youngsTableCell(
    SizedBox(
      width: 100,
      child: _YoungsTextField(
        key: ValueKey<String>(key),
        value: value,
        label: label,
        dark: dark,
        onChanged: onChanged,
        compact: true,
      ),
    ),
  );
}

Widget _youngsResultCell(String value, bool dark) {
  return _youngsTableCell(
    Text(
      value.isEmpty ? '—' : value,
      textAlign: TextAlign.center,
      style: _youngsCellTextStyle(dark),
    ),
  );
}

Widget _youngsMixedLabel({
  required String prefix,
  required String formula,
  required bool dark,
  double fontSize = 11,
  bool summary = false,
  bool header = false,
}) {
  return Wrap(
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: 4,
    children: [
      Text(
        prefix,
        style: header
            ? _youngsHeaderTextStyle(dark)
            : summary
            ? _youngsSummaryLabelStyle(dark)
            : _youngsFieldLabelStyle(dark),
      ),
      _youngsInlineMath(
        formula,
        dark,
        fontSize: header || summary ? 12 : fontSize + 1,
        color: header
            ? (dark ? const Color(0xFFD6E6F3) : const Color(0xFF5D7487))
            : summary
            ? (dark ? const Color(0xFF9EACC3) : const Color(0xFF527087))
            : (EcjtuColors.platformMuted(
                dark,
                (dark ? const Color(0xFF9EACC3) : const Color(0xFF667B8E)),
              )),
      ),
    ],
  );
}

Widget _youngsMath(
  String formula,
  bool dark, {
  double fontSize = 14,
  Color? color,
  MathStyle mathStyle = MathStyle.text,
}) {
  return SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Math.tex(
      formula,
      mathStyle: mathStyle,
      textStyle: TextStyle(
        color:
            color ?? (dark ? const Color(0xFFB7D9ED) : const Color(0xFF334F65)),
        fontSize: fontSize,
        height: 1.35,
      ),
      onErrorFallback: (_) => const SizedBox.shrink(),
    ),
  );
}

Widget _youngsInlineMath(
  String formula,
  bool dark, {
  double fontSize = 12,
  Color? color,
}) {
  return Math.tex(
    formula,
    mathStyle: MathStyle.text,
    textStyle: TextStyle(
      color:
          color ?? (dark ? const Color(0xFFB7D9ED) : const Color(0xFF334F65)),
      fontSize: fontSize,
      height: 1.25,
    ),
    onErrorFallback: (_) => const SizedBox.shrink(),
  );
}

TextStyle _youngsSectionTitleStyle(bool dark) => TextStyle(
  color: EcjtuColors.platformText(
    dark,
    (dark ? const Color(0xFFE1EDFF) : const Color(0xFF223549)),
  ),
  fontSize: 13,
  fontWeight: FontWeight.w700,
  height: 1.3,
);

TextStyle _youngsFormulaTitleStyle(bool dark) => TextStyle(
  color: EcjtuColors.platformText(
    dark,
    (dark ? const Color(0xFFD6E6F3) : const Color(0xFF275B7A)),
  ),
  fontSize: 12,
  fontWeight: FontWeight.w700,
  height: 1.3,
);

TextStyle _youngsFormulaNumberStyle(bool dark) => TextStyle(
  color: EcjtuColors.platformText(
    dark,
    (dark ? const Color(0xFFE1EDFF) : const Color(0xFF223549)),
  ),
  fontSize: 16,
  fontWeight: FontWeight.w500,
  height: 1.2,
);

TextStyle _youngsResultHeadingStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFF9DDCFF) : const Color(0xFF275B7A),
  fontSize: 13,
  fontWeight: FontWeight.w700,
  height: 1.3,
);

TextStyle _youngsHeaderTextStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFFD6E6F3) : const Color(0xFF5D7487),
  fontSize: 12,
  fontWeight: FontWeight.w700,
  height: 1.25,
);

TextStyle _youngsCellTextStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFFB7D9ED) : const Color(0xFF334F65),
  fontSize: 12,
  height: 1.25,
);

TextStyle _youngsRowHeaderTextStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFFB7D9ED) : const Color(0xFF3D647D),
  fontSize: 12,
  fontWeight: FontWeight.w700,
  height: 1.2,
);

TextStyle _youngsFieldLabelStyle(bool dark) => TextStyle(
  color: EcjtuColors.platformMuted(
    dark,
    (dark ? const Color(0xFF9EACC3) : const Color(0xFF667B8E)),
  ),
  fontSize: 11,
  fontWeight: FontWeight.w400,
  height: 1.3,
);

TextStyle _youngsSummaryLabelStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFF9EACC3) : const Color(0xFF527087),
  fontSize: 12,
  fontWeight: FontWeight.w600,
  height: 1.3,
);

TextStyle _youngsSummaryValueStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFF8FD2FF) : const Color(0xFF176496),
  fontSize: 13,
  fontWeight: FontWeight.w800,
  height: 1.2,
);

Color _youngsBorderColor(bool dark) => EcjtuColors.platformBorder(
  dark,
  (dark ? const Color(0xFF31546B) : const Color(0xFFD5E4EF)),
);

Color _youngsHeaderColor(bool dark) =>
    dark ? const Color(0xFF14263A) : const Color(0xFFEEF6FA);

TableBorder _youngsTableBorder(bool dark) {
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

OutlineInputBorder _youngsInputBorder(Color color) => OutlineInputBorder(
  borderRadius: BorderRadius.circular(6),
  borderSide: BorderSide(color: color),
);
