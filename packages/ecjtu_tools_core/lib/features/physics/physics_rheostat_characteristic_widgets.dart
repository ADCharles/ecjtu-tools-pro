// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

part of 'physics_rheostat_characteristic_page.dart';

Widget _rheostatFormulaBlock(bool dark) {
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
        Text('计算公式', style: _rheostatFormulaTitleStyle(dark)),
        const SizedBox(height: 7),
        _RheostatFormulaLine(
          number: '1.',
          formula: r'R_x=\frac{U}{I}',
          dark: dark,
        ),
        _RheostatFormulaLine(
          number: '2.',
          formula: r'R_{x0}=\frac{R_0U}{R_0I-U}',
          dark: dark,
        ),
        _RheostatFormulaLine(
          number: '3.',
          formula: r'\frac{\partial R}{\partial U}=\frac{R_0^2I}{(R_0I-U)^2}',
          dark: dark,
        ),
        _RheostatFormulaLine(
          number: '4.',
          formula: r'\frac{\partial R}{\partial I}=-\frac{R_0^2U}{(R_0I-U)^2}',
          dark: dark,
        ),
        _RheostatFormulaLine(
          number: '5.',
          formula:
              r'u_B=\sqrt{\left(\frac{\partial R}{\partial U}u(U)\right)^2+\left(\frac{\partial R}{\partial I}u(I)\right)^2}',
          dark: dark,
        ),
        _RheostatFormulaLine(
          number: '6.',
          formula: r'u=\sqrt{u_A^2+u_B^2}',
          dark: dark,
        ),
      ],
    ),
  );
}

Widget _rheostatSection({
  required String title,
  required bool dark,
  required Widget child,
}) {
  return LayoutBuilder(
    builder: (context, constraints) {
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
            Text(title, style: _rheostatSectionTitleStyle(dark)),
            const SizedBox(height: 12),
            child,
          ],
        ),
      );
    },
  );
}

class _RheostatFormulaLine extends StatelessWidget {
  const _RheostatFormulaLine({
    required this.number,
    required this.formula,
    required this.dark,
  });

  final String number;
  final String formula;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 42),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 28,
            child: Text(number, style: _rheostatFormulaNumberStyle(dark)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _rheostatMath(
              formula,
              dark,
              fontSize: 15,
              display: true,
              color: EcjtuColors.platformText(
                dark,
                (dark ? const Color(0xFFE1EDFF) : const Color(0xFF223549)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RheostatInputTable extends StatelessWidget {
  const _RheostatInputTable({
    required this.rows,
    required this.dark,
    required this.onChanged,
  });

  final List<RheostatMeasurementInput> rows;
  final bool dark;
  final void Function(int index, String field, String value) onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width =
            constraints.maxWidth.isFinite && constraints.maxWidth > 520
            ? constraints.maxWidth
            : 520.0;
        return _RheostatTableScroll(
          width: width,
          dark: dark,
          child: Table(
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            columnWidths: const {
              0: FixedColumnWidth(86),
              1: FlexColumnWidth(1),
              2: FlexColumnWidth(1),
            },
            border: _rheostatTableBorder(dark),
            children: [
              TableRow(
                decoration: BoxDecoration(color: _rheostatHeaderColor(dark)),
                children: [
                  _rheostatTableCell(const Text('次数'), dark, header: true),
                  _rheostatTableCell(
                    _rheostatMixedLabel(
                      '电压',
                      r'U\,/\,\mathrm{mV}',
                      dark,
                      textStyle: _rheostatHeaderTextStyle(dark),
                    ),
                    dark,
                    header: true,
                  ),
                  _rheostatTableCell(
                    _rheostatMixedLabel(
                      '电流',
                      r'I\,/\,\mathrm{mA}',
                      dark,
                      textStyle: _rheostatHeaderTextStyle(dark),
                    ),
                    dark,
                    header: true,
                  ),
                ],
              ),
              for (var index = 0; index < rows.length; index++)
                TableRow(
                  children: [
                    _rheostatTableCell(
                      Text('${index + 1}', style: _rheostatRowLabelStyle(dark)),
                      dark,
                      labelCell: true,
                    ),
                    _rheostatTableCell(
                      _RheostatTextField(
                        key: ValueKey<String>('rheostat-voltage-$index'),
                        value: rows[index].voltage,
                        label: '电压第 ${index + 1} 次',
                        dark: dark,
                        compact: true,
                        onChanged: (value) =>
                            onChanged(index, 'voltage', value),
                      ),
                      dark,
                    ),
                    _rheostatTableCell(
                      _RheostatTextField(
                        key: ValueKey<String>('rheostat-current-$index'),
                        value: rows[index].current,
                        label: '电流第 ${index + 1} 次',
                        dark: dark,
                        compact: true,
                        onChanged: (value) =>
                            onChanged(index, 'current', value),
                      ),
                      dark,
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

class _RheostatFieldDefinition {
  const _RheostatFieldDefinition({
    required this.label,
    required this.formula,
    required this.value,
    required this.semanticLabel,
    required this.onChanged,
  });

  final String label;
  final String formula;
  final String value;
  final String semanticLabel;
  final ValueChanged<String> onChanged;
}

class _RheostatParameterGrid extends StatelessWidget {
  const _RheostatParameterGrid({required this.dark, required this.fields});

  final bool dark;
  final List<_RheostatFieldDefinition> fields;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns =
            !constraints.maxWidth.isFinite || constraints.maxWidth >= 720
            ? 4
            : constraints.maxWidth >= 420
            ? 2
            : 1;
        const gap = 10.0;
        final width = constraints.maxWidth.isFinite
            ? (constraints.maxWidth - gap * (columns - 1)) / columns
            : 220.0;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (var index = 0; index < fields.length; index++)
              SizedBox(
                width: width,
                child: _RheostatLabeledInput(
                  key: ValueKey<String>('rheostat-field-$index'),
                  definition: fields[index],
                  dark: dark,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _RheostatLabeledInput extends StatelessWidget {
  const _RheostatLabeledInput({
    super.key,
    required this.definition,
    required this.dark,
  });

  final _RheostatFieldDefinition definition;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 26),
          child: Align(
            alignment: Alignment.centerLeft,
            child: _rheostatMixedLabel(
              definition.label,
              definition.formula,
              dark,
              textStyle: _rheostatFieldLabelStyle(dark),
            ),
          ),
        ),
        const SizedBox(height: 5),
        _RheostatTextField(
          value: definition.value,
          label: definition.semanticLabel,
          dark: dark,
          compact: false,
          onChanged: definition.onChanged,
        ),
      ],
    );
  }
}

class _RheostatOutputContent extends StatelessWidget {
  const _RheostatOutputContent({
    required this.calculation,
    required this.dark,
    required this.saving,
    required this.onExportPdf,
    required this.onSave,
  });

  final RheostatCalculation calculation;
  final bool dark;
  final bool saving;
  final VoidCallback onExportPdf;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RheostatResultCard(
          title: '测量结果',
          dark: dark,
          children: [
            _RheostatMeasurementResultTable(
              calculation: calculation,
              dark: dark,
            ),
            _rheostatResultLine(
              label: _rheostatMixedLabel('直接值平均', r'\bar R_x\,/\,\Omega', dark),
              value: RheostatCharacteristicCalculator.format(
                calculation.directMean,
              ),
              dark: dark,
            ),
            _rheostatResultLine(
              label: _rheostatMixedLabel(
                '修正值平均',
                r'\bar R_{x0}\,/\,\Omega',
                dark,
              ),
              value: RheostatCharacteristicCalculator.format(
                calculation.correctedMean,
              ),
              dark: dark,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _RheostatResultCard(
          title: '不确定度',
          dark: dark,
          children: [
            _rheostatResultLine(
              label: _rheostatMixedLabel('A 类不确定度', r'u_A\,/\,\Omega', dark),
              value: RheostatCharacteristicCalculator.format(
                calculation.aUncertainty,
              ),
              dark: dark,
              first: true,
            ),
            _rheostatResultLine(
              label: _rheostatMixedLabel('检验电流', r'I_t\,/\,\mathrm{mA}', dark),
              value: RheostatCharacteristicCalculator.format(
                calculation.testCurrentMilliampere,
              ),
              dark: dark,
            ),
            _rheostatResultLine(
              label: _rheostatMixedLabel(
                '偏导数',
                r'\frac{\partial R}{\partial U}',
                dark,
              ),
              value: RheostatCharacteristicCalculator.format(
                calculation.voltageDerivative,
              ),
              dark: dark,
            ),
            _rheostatResultLine(
              label: _rheostatMixedLabel(
                '偏导数',
                r'\frac{\partial R}{\partial I}',
                dark,
              ),
              value: RheostatCharacteristicCalculator.format(
                calculation.currentDerivative,
              ),
              dark: dark,
            ),
            _rheostatResultLine(
              label: _rheostatMixedLabel('B 类不确定度', r'u_B\,/\,\Omega', dark),
              value: RheostatCharacteristicCalculator.format(
                calculation.bUncertainty,
              ),
              dark: dark,
            ),
            _rheostatResultLine(
              label: _rheostatMixedLabel('总不确定度', r'u\,/\,\Omega', dark),
              value: RheostatCharacteristicCalculator.format(
                calculation.totalUncertainty,
              ),
              dark: dark,
            ),
            _rheostatResultLine(
              label: _rheostatMixedLabel('相对误差', r'\varepsilon', dark),
              value: RheostatCharacteristicCalculator.percent(
                calculation.relativeError,
              ),
              dark: dark,
            ),
            _rheostatResultLine(
              label: _rheostatMixedLabel('最终结果', r'R_{x0}\,/\,\Omega', dark),
              value: calculation.correctedMean == null
                  ? '—'
                  : '${RheostatCharacteristicCalculator.format(calculation.correctedMean)} ± ${RheostatCharacteristicCalculator.format(calculation.totalUncertainty)}',
              dark: dark,
            ),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 9,
          runSpacing: 8,
          children: [
            OutlinedButton(
              onPressed: onExportPdf,
              child: const Text('下载全部图 PDF'),
              style: physicsSecondaryButtonStyle(context),
            ),
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

class _RheostatMeasurementResultTable extends StatelessWidget {
  const _RheostatMeasurementResultTable({
    required this.calculation,
    required this.dark,
  });

  final RheostatCalculation calculation;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return _RheostatTableScroll(
      width: 920,
      dark: dark,
      child: Table(
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        columnWidths: const {
          0: FixedColumnWidth(86),
          1: FlexColumnWidth(1),
          2: FlexColumnWidth(1),
          3: FlexColumnWidth(1),
          4: FlexColumnWidth(1),
          5: FlexColumnWidth(1),
        },
        border: _rheostatTableBorder(dark),
        children: [
          TableRow(
            decoration: BoxDecoration(color: _rheostatHeaderColor(dark)),
            children: [
              _rheostatTableCell(const Text('次数'), dark, header: true),
              _rheostatTableCell(
                _rheostatMixedLabel(
                  '电压',
                  r'U\,/\,\mathrm{mV}',
                  dark,
                  textStyle: _rheostatHeaderTextStyle(dark),
                ),
                dark,
                header: true,
              ),
              _rheostatTableCell(
                _rheostatMixedLabel(
                  '电流',
                  r'I\,/\,\mathrm{mA}',
                  dark,
                  textStyle: _rheostatHeaderTextStyle(dark),
                ),
                dark,
                header: true,
              ),
              _rheostatTableCell(
                _rheostatMixedLabel(
                  '直接值',
                  r'R_x\,/\,\Omega',
                  dark,
                  textStyle: _rheostatHeaderTextStyle(dark),
                ),
                dark,
                header: true,
              ),
              _rheostatTableCell(
                _rheostatMixedLabel(
                  '修正值',
                  r'R_{x0}\,/\,\Omega',
                  dark,
                  textStyle: _rheostatHeaderTextStyle(dark),
                ),
                dark,
                header: true,
              ),
              _rheostatTableCell(
                _rheostatMath(
                  r'(R_{x0}-\bar R_{x0})^2',
                  dark,
                  fontSize: 12,
                  weight: FontWeight.w700,
                  color: dark
                      ? const Color(0xFFD6E6F3)
                      : const Color(0xFF5D7487),
                ),
                dark,
                header: true,
              ),
            ],
          ),
          for (var index = 0; index < calculation.rows.length; index++)
            TableRow(
              children: [
                _rheostatTableCell(
                  Text('${index + 1}', style: _rheostatRowLabelStyle(dark)),
                  dark,
                  labelCell: true,
                ),
                _rheostatValue(
                  RheostatCharacteristicCalculator.format(
                    calculation.rows[index].voltageMillivolt,
                  ),
                  dark,
                ),
                _rheostatValue(
                  RheostatCharacteristicCalculator.format(
                    calculation.rows[index].currentMilliampere,
                  ),
                  dark,
                ),
                _rheostatValue(
                  RheostatCharacteristicCalculator.format(
                    calculation.rows[index].directResistance,
                  ),
                  dark,
                ),
                _rheostatValue(
                  RheostatCharacteristicCalculator.format(
                    calculation.rows[index].correctedResistance,
                  ),
                  dark,
                ),
                _rheostatValue(
                  RheostatCharacteristicCalculator.format(
                    calculation.squaredDifferences[index],
                  ),
                  dark,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _RheostatResultCard extends StatelessWidget {
  const _RheostatResultCard({
    required this.title,
    required this.dark,
    required this.children,
  });

  final String title;
  final bool dark;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth <= 420;
        final content = <Widget>[
          for (var index = 0; index < children.length; index++) ...[
            if (index > 0) const SizedBox(height: 10),
            children[index],
          ],
        ];
        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(narrow ? 11 : 13),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: _rheostatResultTitleStyle(dark)),
              const SizedBox(height: 10),
              ...content,
            ],
          ),
        );
      },
    );
  }
}

Widget _rheostatResultLine({
  required Widget label,
  required String value,
  required bool dark,
  bool first = false,
}) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final narrow = constraints.maxWidth <= 720;
      final valueWidget = Text(
        value,
        textAlign: narrow ? TextAlign.left : TextAlign.right,
        style: _rheostatResultValueStyle(dark),
      );
      return Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 30),
        padding: EdgeInsets.only(top: first ? 0 : 7),
        decoration: first
            ? const BoxDecoration()
            : BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: dark
                        ? const Color(0xFF28465C)
                        : const Color(0xFFE5EDF2),
                  ),
                ),
              ),
        child: narrow
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [label, const SizedBox(height: 4), valueWidget],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: label),
                  const SizedBox(width: 12),
                  Flexible(child: valueWidget),
                ],
              ),
      );
    },
  );
}

class _RheostatTextField extends StatefulWidget {
  const _RheostatTextField({
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
  State<_RheostatTextField> createState() => _RheostatTextFieldState();
}

class _RheostatTextFieldState extends State<_RheostatTextField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _RheostatTextField oldWidget) {
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
    final height = widget.compact ? 30.0 : 32.0;
    return Semantics(
      label: widget.label,
      textField: true,
      child: SizedBox(
        height: height,
        child: TextField(
          controller: _controller,
          onChanged: widget.onChanged,
          textAlign: TextAlign.center,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
            signed: true,
          ),
          textInputAction: TextInputAction.next,
          style: TextStyle(
            color: widget.dark
                ? const Color(0xFFE1EDFF)
                : const Color(0xFF223549),
            fontSize: 12,
            height: 1.1,
          ),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: widget.dark ? const Color(0xFF14263A) : Colors.white,
            contentPadding: EdgeInsets.symmetric(
              horizontal: widget.compact ? 5 : 7,
              vertical: widget.compact ? 4 : 5,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(widget.compact ? 5 : 6),
              borderSide: BorderSide(
                color: widget.dark
                    ? const Color(0xFF426B83)
                    : const Color(0xFFB9CFDD),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(widget.compact ? 5 : 6),
              borderSide: BorderSide(
                color: widget.dark
                    ? const Color(0xFF9DDCFF)
                    : const Color(0xFF287AA8),
              ),
            ),
          ),

          contextMenuBuilder: buildEcjtuPlatformTextContextMenu,
        ),
      ),
    );
  }
}

Widget _rheostatMixedLabel(
  String text,
  String formula,
  bool dark, {
  TextStyle? textStyle,
}) {
  final labelStyle = textStyle ?? _rheostatLabelTextStyle(dark);
  return Wrap(
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: 3,
    runSpacing: 2,
    children: [
      Text(text, style: labelStyle),
      _rheostatMath(
        formula,
        dark,
        fontSize: labelStyle.fontSize ?? 12,
        weight: labelStyle.fontWeight,
        color: labelStyle.color,
      ),
    ],
  );
}

Widget _rheostatMath(
  String formula,
  bool dark, {
  double fontSize = 14,
  FontWeight? weight,
  Color? color,
  bool display = false,
}) {
  final math = Math.tex(
    formula,
    mathStyle: display ? MathStyle.display : MathStyle.text,
    textStyle: TextStyle(
      color:
          color ?? (dark ? const Color(0xFFB7D9ED) : const Color(0xFF334F65)),
      fontSize: fontSize,
      fontWeight: weight,
      height: display ? 1.25 : 1.3,
    ),
    onErrorFallback: (_) => const SizedBox.shrink(),
  );
  return SingleChildScrollView(scrollDirection: Axis.horizontal, child: math);
}

Widget _rheostatValue(String value, bool dark) {
  return _rheostatTableCell(
    Text(
      value,
      textAlign: TextAlign.center,
      style: _rheostatValueTextStyle(dark),
    ),
    dark,
  );
}

Widget _rheostatTableCell(
  Widget child,
  bool dark, {
  bool header = false,
  bool labelCell = false,
}) {
  return Builder(
    builder: (context) {
      final horizontalPadding = MediaQuery.sizeOf(context).width <= 420
          ? 6.0
          : 8.0;
      return Container(
        constraints: BoxConstraints(minHeight: header ? 42 : 38),
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: 7,
        ),
        alignment: labelCell ? Alignment.centerLeft : Alignment.center,
        color: header
            ? _rheostatHeaderColor(dark)
            : labelCell
            ? (dark ? const Color(0xFF14263A) : const Color(0xFFF8FBFD))
            : (EcjtuColors.platformSurface(
                dark,
                (dark ? const Color(0xFF101D31) : Colors.white),
              )),
        child: DefaultTextStyle.merge(
          style: header
              ? _rheostatHeaderTextStyle(dark)
              : labelCell
              ? _rheostatRowLabelStyle(dark)
              : _rheostatCellTextStyle(dark),
          child: child,
        ),
      );
    },
  );
}

class _RheostatTableScroll extends StatelessWidget {
  const _RheostatTableScroll({
    required this.width,
    required this.dark,
    required this.child,
  });

  final double width;
  final bool dark;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        width: width,
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
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }
}

TableBorder _rheostatTableBorder(bool dark) {
  return TableBorder(
    horizontalInside: BorderSide(
      color: dark ? const Color(0xFF28465C) : const Color(0xFFE5EDF2),
    ),
    verticalInside: BorderSide(
      color: dark ? const Color(0xFF28465C) : const Color(0xFFE5EDF2),
    ),
  );
}

Color _rheostatHeaderColor(bool dark) =>
    dark ? const Color(0xFF14263A) : const Color(0xFFEEF6FA);

TextStyle _rheostatSectionTitleStyle(bool dark) => TextStyle(
  color: EcjtuColors.platformText(
    dark,
    (dark ? const Color(0xFFE1EDFF) : const Color(0xFF223549)),
  ),
  fontSize: 13,
  fontWeight: FontWeight.w700,
  height: 1.3,
);

TextStyle _rheostatResultTitleStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFF9DDCFF) : const Color(0xFF275B7A),
  fontSize: 13,
  fontWeight: FontWeight.w700,
  height: 1.3,
);

TextStyle _rheostatFormulaTitleStyle(bool dark) => TextStyle(
  color: EcjtuColors.platformText(
    dark,
    (dark ? const Color(0xFFD6E6F3) : const Color(0xFF275B7A)),
  ),
  fontSize: 12,
  fontWeight: FontWeight.w700,
  height: 1.3,
);

TextStyle _rheostatFormulaNumberStyle(bool dark) => TextStyle(
  color: EcjtuColors.platformText(
    dark,
    (dark ? const Color(0xFFE1EDFF) : const Color(0xFF223549)),
  ),
  fontSize: 16,
  fontWeight: FontWeight.w500,
  height: 1.2,
);

TextStyle _rheostatLabelTextStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFF9EACC3) : const Color(0xFF527087),
  fontSize: 12,
  fontWeight: FontWeight.w600,
  height: 1.3,
);

TextStyle _rheostatFieldLabelStyle(bool dark) => TextStyle(
  color: EcjtuColors.platformMuted(
    dark,
    (dark ? const Color(0xFF9EACC3) : const Color(0xFF667B8E)),
  ),
  fontSize: 11,
  fontWeight: FontWeight.w400,
  height: 1.3,
);

TextStyle _rheostatHeaderTextStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFFD6E6F3) : const Color(0xFF5D7487),
  fontSize: 12,
  fontWeight: FontWeight.w700,
  height: 1.25,
);

TextStyle _rheostatRowLabelStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFFB7D9ED) : const Color(0xFF275B7A),
  fontSize: 12,
  fontWeight: FontWeight.w700,
  height: 1.2,
);

TextStyle _rheostatCellTextStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFFB7D9ED) : const Color(0xFF334F65),
  fontSize: 12,
  height: 1.25,
);

TextStyle _rheostatValueTextStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFFB7D9ED) : const Color(0xFF334F65),
  fontSize: 12,
  height: 1.25,
);

TextStyle _rheostatResultValueStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFF8FD2FF) : const Color(0xFF176496),
  fontSize: 13,
  fontWeight: FontWeight.w800,
  height: 1.25,
);
