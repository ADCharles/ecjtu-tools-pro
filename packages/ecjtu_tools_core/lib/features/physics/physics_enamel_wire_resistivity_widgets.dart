// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

part of 'physics_enamel_wire_resistivity_page.dart';

Widget _enamelFormulaBlock(bool dark) {
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
        Text('计算公式', style: _enamelFormulaTitleStyle(dark)),
        const SizedBox(height: 7),
        _EnamelFormulaLine(
          number: '1.',
          formula: r'\rho=\frac{R\rho_m\pi^2d^4}{16m}',
          dark: dark,
        ),
        _EnamelFormulaLine(
          number: '2.',
          formula:
              r'u_r(\rho)=\sqrt{\left(4\frac{s_d}{\bar d}\right)^2+\left(\frac{s_R}{\bar R}\right)^2+\left(\frac{u(m)}{m}\right)^2}',
          dark: dark,
        ),
        _EnamelFormulaLine(
          number: '3.',
          formula: r'u(\rho)=\rho u_r(\rho)',
          dark: dark,
        ),
      ],
    ),
  );
}

Widget _enamelSection({
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
            Text(title, style: _enamelSectionTitleStyle(dark)),
            const SizedBox(height: 12),
            child,
          ],
        ),
      );
    },
  );
}

class _EnamelFormulaLine extends StatelessWidget {
  const _EnamelFormulaLine({
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
            child: Text(number, style: _enamelFormulaNumberStyle(dark)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _enamelMath(
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

class _EnamelMeasurementTable extends StatelessWidget {
  const _EnamelMeasurementTable({
    required this.values,
    required this.headerText,
    required this.headerFormula,
    required this.fieldLabel,
    required this.dark,
    required this.onChanged,
  });

  final List<String> values;
  final String headerText;
  final String headerFormula;
  final String fieldLabel;
  final bool dark;
  final void Function(int index, String value) onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width =
            constraints.maxWidth.isFinite && constraints.maxWidth > 520
            ? constraints.maxWidth
            : 520.0;
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
            child: Table(
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              columnWidths: const {
                0: FixedColumnWidth(86),
                1: FlexColumnWidth(1),
              },
              border: _enamelTableBorder(dark),
              children: [
                TableRow(
                  decoration: BoxDecoration(color: _enamelHeaderColor(dark)),
                  children: [
                    _enamelTableCell(const Text('次数'), dark, header: true),
                    _enamelTableCell(
                      _enamelMixedLabel(
                        headerText,
                        headerFormula,
                        dark,
                        textStyle: _enamelHeaderTextStyle(dark),
                      ),
                      dark,
                      header: true,
                    ),
                  ],
                ),
                for (var index = 0; index < values.length; index++)
                  TableRow(
                    children: [
                      _enamelTableCell(
                        Text('${index + 1}', style: _enamelRowLabelStyle(dark)),
                        dark,
                        labelCell: true,
                      ),
                      _enamelTableCell(
                        _EnamelTextField(
                          key: ValueKey<String>(
                            'enamel-${fieldLabel.hashCode}-$index',
                          ),
                          value: values[index],
                          label: '$fieldLabel第 ${index + 1} 次',
                          dark: dark,
                          compact: true,
                          onChanged: (value) => onChanged(index, value),
                        ),
                        dark,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EnamelFieldDefinition {
  const _EnamelFieldDefinition({
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

class _EnamelParameterGrid extends StatelessWidget {
  const _EnamelParameterGrid({required this.dark, required this.fields});

  final bool dark;
  final List<_EnamelFieldDefinition> fields;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns =
            !constraints.maxWidth.isFinite || constraints.maxWidth >= 720
            ? 3
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
                child: _EnamelLabeledInput(
                  key: ValueKey<String>('enamel-field-$index'),
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

class _EnamelLabeledInput extends StatelessWidget {
  const _EnamelLabeledInput({
    super.key,
    required this.definition,
    required this.dark,
  });

  final _EnamelFieldDefinition definition;
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
            child: _enamelMixedLabel(
              definition.label,
              definition.formula,
              dark,
              textStyle: _enamelFieldLabelStyle(dark),
            ),
          ),
        ),
        const SizedBox(height: 5),
        _EnamelTextField(
          value: definition.value,
          label: definition.semanticLabel,
          dark: dark,
          onChanged: definition.onChanged,
        ),
      ],
    );
  }
}

class _EnamelOutputContent extends StatelessWidget {
  const _EnamelOutputContent({
    required this.calculation,
    required this.dark,
    required this.saving,
    required this.onExportPdf,
    required this.onSave,
  });

  final EnamelWireResistivityCalculation calculation;
  final bool dark;
  final bool saving;
  final VoidCallback onExportPdf;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _EnamelResultCard(
          title: '直径计算',
          dark: dark,
          children: [
            _EnamelStatisticsTable(
              values: calculation.diameters,
              squaredDifferences: calculation.diameterSquaredDifferences,
              valueFormula: r'd\,/\,\mathrm{mm}',
              differenceFormula: r'(d_i-\bar d)^2\,/\,\mathrm{mm^2}',
              dark: dark,
            ),
            _enamelResultLine(
              label: _enamelMixedLabel(
                '直径平均值',
                r'\bar d\,/\,\mathrm{mm}',
                dark,
                textStyle: _enamelResultLabelStyle(dark),
              ),
              value: EnamelWireResistivityCalculator.format(
                calculation.diameterMean,
              ),
              dark: dark,
              first: true,
            ),
            _enamelResultLine(
              label: _enamelMixedLabel(
                '直径标准误差',
                r's_d\,/\,\mathrm{mm}',
                dark,
                textStyle: _enamelResultLabelStyle(dark),
              ),
              value: EnamelWireResistivityCalculator.format(
                calculation.diameterStandardError,
              ),
              dark: dark,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _EnamelResultCard(
          title: '电阻计算',
          dark: dark,
          children: [
            _EnamelStatisticsTable(
              values: calculation.resistances,
              squaredDifferences: calculation.resistanceSquaredDifferences,
              valueFormula: r'R\,/\,\Omega',
              differenceFormula: r'(R_i-\bar R)^2\,/\,\Omega^2',
              dark: dark,
            ),
            _enamelResultLine(
              label: _enamelMixedLabel(
                '电阻平均值',
                r'\bar R\,/\,\Omega',
                dark,
                textStyle: _enamelResultLabelStyle(dark),
              ),
              value: EnamelWireResistivityCalculator.format(
                calculation.resistanceMean,
              ),
              dark: dark,
              first: true,
            ),
            _enamelResultLine(
              label: _enamelMixedLabel(
                '电阻标准误差',
                r's_R\,/\,\Omega',
                dark,
                textStyle: _enamelResultLabelStyle(dark),
              ),
              value: EnamelWireResistivityCalculator.format(
                calculation.resistanceStandardError,
              ),
              dark: dark,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _EnamelResultCard(
          title: '电阻率结果',
          dark: dark,
          children: [
            _enamelResultLine(
              label: _enamelMixedLabel(
                '电阻率',
                r'\rho=\frac{R\rho_m\pi^2d^4}{16m}\,/\,\Omega\,m',
                dark,
                textStyle: _enamelResultLabelStyle(dark),
              ),
              value: EnamelWireResistivityCalculator.format(
                calculation.resistivity,
              ),
              dark: dark,
              first: true,
            ),
            _enamelResultLine(
              label: _enamelMixedLabel(
                '相对不确定度',
                r'u_r(\rho)',
                dark,
                textStyle: _enamelResultLabelStyle(dark),
              ),
              value: EnamelWireResistivityCalculator.percent(
                calculation.relativeError,
              ),
              dark: dark,
            ),
            _enamelResultLine(
              label: _enamelMixedLabel(
                '绝对不确定度',
                r'u(\rho)\,/\,\Omega\,m',
                dark,
                textStyle: _enamelResultLabelStyle(dark),
              ),
              value: EnamelWireResistivityCalculator.format(
                calculation.absoluteError,
              ),
              dark: dark,
            ),
            _enamelResultLine(
              label: _enamelMixedLabel(
                '最终结果',
                r'\rho\,/\,\Omega\,m',
                dark,
                textStyle: _enamelResultLabelStyle(dark),
              ),
              value: calculation.resistivity == null
                  ? '—'
                  : '${EnamelWireResistivityCalculator.format(calculation.resistivity)} ± ${EnamelWireResistivityCalculator.format(calculation.absoluteError)}',
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

class _EnamelStatisticsTable extends StatelessWidget {
  const _EnamelStatisticsTable({
    required this.values,
    required this.squaredDifferences,
    required this.valueFormula,
    required this.differenceFormula,
    required this.dark,
  });

  final List<double?> values;
  final List<double?> squaredDifferences;
  final String valueFormula;
  final String differenceFormula;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width =
            constraints.maxWidth.isFinite && constraints.maxWidth > 520
            ? constraints.maxWidth
            : 520.0;
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
            child: Table(
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              columnWidths: const {
                0: FixedColumnWidth(86),
                1: FlexColumnWidth(1),
                2: FlexColumnWidth(1.35),
              },
              border: _enamelTableBorder(dark),
              children: [
                TableRow(
                  decoration: BoxDecoration(color: _enamelHeaderColor(dark)),
                  children: [
                    _enamelTableCell(const Text('次数'), dark, header: true),
                    _enamelTableCell(
                      _enamelMixedLabel(
                        '测量值',
                        valueFormula,
                        dark,
                        textStyle: _enamelHeaderTextStyle(dark),
                      ),
                      dark,
                      header: true,
                    ),
                    _enamelTableCell(
                      _enamelMath(
                        differenceFormula,
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
                for (var index = 0; index < values.length; index++)
                  TableRow(
                    children: [
                      _enamelTableCell(
                        Text('${index + 1}', style: _enamelRowLabelStyle(dark)),
                        dark,
                        labelCell: true,
                      ),
                      _enamelTableCell(
                        Text(
                          EnamelWireResistivityCalculator.format(values[index]),
                          textAlign: TextAlign.center,
                          style: _enamelValueTextStyle(dark),
                        ),
                        dark,
                      ),
                      _enamelTableCell(
                        Text(
                          EnamelWireResistivityCalculator.format(
                            squaredDifferences[index],
                          ),
                          textAlign: TextAlign.center,
                          style: _enamelValueTextStyle(dark),
                        ),
                        dark,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EnamelResultCard extends StatelessWidget {
  const _EnamelResultCard({
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
              Text(title, style: _enamelResultTitleStyle(dark)),
              const SizedBox(height: 10),
              for (var index = 0; index < children.length; index++) ...[
                if (index > 0) const SizedBox(height: 10),
                children[index],
              ],
            ],
          ),
        );
      },
    );
  }
}

Widget _enamelResultLine({
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
        style: _enamelResultValueStyle(dark),
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

class _EnamelTextField extends StatefulWidget {
  const _EnamelTextField({
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
  State<_EnamelTextField> createState() => _EnamelTextFieldState();
}

class _EnamelTextFieldState extends State<_EnamelTextField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _EnamelTextField oldWidget) {
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
    return Semantics(
      label: widget.label,
      textField: true,
      child: SizedBox(
        height: widget.compact ? 30 : 32,
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

Widget _enamelMixedLabel(
  String text,
  String formula,
  bool dark, {
  TextStyle? textStyle,
}) {
  final labelStyle = textStyle ?? _enamelLabelTextStyle(dark);
  return Wrap(
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: 3,
    runSpacing: 2,
    children: [
      Text(text, style: labelStyle),
      _enamelMath(
        formula,
        dark,
        fontSize: labelStyle.fontSize ?? 12,
        weight: labelStyle.fontWeight,
        color: labelStyle.color,
      ),
    ],
  );
}

Widget _enamelMath(
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

Widget _enamelTableCell(
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
            ? _enamelHeaderColor(dark)
            : labelCell
            ? (dark ? const Color(0xFF14263A) : const Color(0xFFF8FBFD))
            : (EcjtuColors.platformSurface(
                dark,
                (dark ? const Color(0xFF101D31) : Colors.white),
              )),
        child: DefaultTextStyle.merge(
          style: header
              ? _enamelHeaderTextStyle(dark)
              : labelCell
              ? _enamelRowLabelStyle(dark)
              : _enamelCellTextStyle(dark),
          child: child,
        ),
      );
    },
  );
}

TableBorder _enamelTableBorder(bool dark) {
  return TableBorder(
    horizontalInside: BorderSide(
      color: dark ? const Color(0xFF28465C) : const Color(0xFFE5EDF2),
    ),
    verticalInside: BorderSide(
      color: dark ? const Color(0xFF28465C) : const Color(0xFFE5EDF2),
    ),
  );
}

Color _enamelHeaderColor(bool dark) =>
    dark ? const Color(0xFF14263A) : const Color(0xFFEEF6FA);

TextStyle _enamelSectionTitleStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFF9DDCFF) : const Color(0xFF275B7A),
  fontSize: 13,
  fontWeight: FontWeight.w700,
  height: 1.3,
);

TextStyle _enamelResultTitleStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFF9DDCFF) : const Color(0xFF275B7A),
  fontSize: 13,
  fontWeight: FontWeight.w700,
  height: 1.3,
);

TextStyle _enamelLabelTextStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFFB9E2F7) : const Color(0xFF667B8E),
  fontSize: 11,
  fontWeight: FontWeight.w600,
  height: 1.3,
);

TextStyle _enamelFormulaTitleStyle(bool dark) => TextStyle(
  color: EcjtuColors.platformText(
    dark,
    (dark ? const Color(0xFFD6E6F3) : const Color(0xFF275B7A)),
  ),
  fontSize: 12,
  fontWeight: FontWeight.w700,
  height: 1.3,
);

TextStyle _enamelFormulaNumberStyle(bool dark) => TextStyle(
  color: EcjtuColors.platformText(
    dark,
    (dark ? const Color(0xFFE1EDFF) : const Color(0xFF223549)),
  ),
  fontSize: 16,
  fontWeight: FontWeight.w500,
  height: 1.2,
);

TextStyle _enamelFieldLabelStyle(bool dark) => TextStyle(
  color: EcjtuColors.platformMuted(
    dark,
    (dark ? const Color(0xFF9EACC3) : const Color(0xFF667B8E)),
  ),
  fontSize: 11,
  fontWeight: FontWeight.w400,
  height: 1.3,
);

TextStyle _enamelResultLabelStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFF9EACC3) : const Color(0xFF527087),
  fontSize: 12,
  fontWeight: FontWeight.w600,
  height: 1.3,
);

TextStyle _enamelHeaderTextStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFFD6E6F3) : const Color(0xFF5D7487),
  fontSize: 12,
  fontWeight: FontWeight.w700,
  height: 1.25,
);

TextStyle _enamelRowLabelStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFFB7D9ED) : const Color(0xFF275B7A),
  fontSize: 12,
  fontWeight: FontWeight.w700,
  height: 1.2,
);

TextStyle _enamelCellTextStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFFB7D9ED) : const Color(0xFF334F65),
  fontSize: 12,
  height: 1.25,
);

TextStyle _enamelValueTextStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFFB7D9ED) : const Color(0xFF334F65),
  fontSize: 12,
  height: 1.25,
);

TextStyle _enamelResultValueStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFF8FD2FF) : const Color(0xFF176496),
  fontSize: 13,
  fontWeight: FontWeight.w800,
  height: 1.25,
);
