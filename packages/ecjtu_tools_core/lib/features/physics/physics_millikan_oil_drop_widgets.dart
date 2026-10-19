// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

part of 'physics_millikan_oil_drop_page.dart';

Widget _millikanFormulaBlock(bool dark) {
  const formulas = [
    r'a=\sqrt{\frac{9\eta l}{2\rho g\bar t_g}}',
    r'q=\frac{18\pi d}{U\sqrt{2\rho g}}\left(\frac{\eta l}{\bar t_g\left(1+b/(pa)\right)}\right)^{3/2}',
    r'N=\frac{q}{e}',
  ];
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
        Text('计算公式', style: _millikanFormulaTitleStyle(dark)),
        const SizedBox(height: 7),
        for (var index = 0; index < formulas.length; index++)
          _MillikanFormulaLine(
            number: '${index + 1}.',
            formula: formulas[index],
            dark: dark,
          ),
      ],
    ),
  );
}

Widget _millikanSection({
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
            Text(title, style: _millikanSectionTitleStyle(dark)),
            const SizedBox(height: 12),
            child,
          ],
        ),
      );
    },
  );
}

class _MillikanFormulaLine extends StatelessWidget {
  const _MillikanFormulaLine({
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
            child: Text(number, style: _millikanFormulaNumberStyle(dark)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _millikanMath(
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

class _MillikanConstantsInput extends StatelessWidget {
  const _MillikanConstantsInput({
    required this.constants,
    required this.dark,
    required this.onChanged,
  });

  final MillikanConstants constants;
  final bool dark;
  final void Function(String field, String value) onChanged;

  @override
  Widget build(BuildContext context) {
    return _MillikanParameterGrid(
      dark: dark,
      fields: [
        _MillikanParameterField(
          prefix: '重力加速度',
          formula: r'g\,/\,\mathrm{m\,s^{-2}}',
          value: constants.g,
          label: '重力加速度',
          dark: dark,
          onChanged: (value) => onChanged('g', value),
        ),
        _MillikanParameterField(
          prefix: '空气粘滞系数',
          formula: r'\eta\,/\,\mathrm{Pa\,s}',
          value: constants.eta,
          label: '空气粘滞系数',
          dark: dark,
          onChanged: (value) => onChanged('eta', value),
        ),
        _MillikanParameterField(
          prefix: '油滴密度',
          formula: r'\rho\,/\,\mathrm{kg\,m^{-3}}',
          value: constants.rho,
          label: '油滴密度',
          dark: dark,
          onChanged: (value) => onChanged('rho', value),
        ),
        _MillikanParameterField(
          prefix: '大气压强',
          formula: r'p\,/\,\mathrm{cmHg}',
          value: constants.pressure,
          label: '大气压强',
          dark: dark,
          onChanged: (value) => onChanged('pressure', value),
        ),
        _MillikanParameterField(
          prefix: '极板距离',
          formula: r'd\,/\,\mathrm{m}',
          value: constants.d,
          label: '极板距离',
          dark: dark,
          onChanged: (value) => onChanged('d', value),
        ),
        _MillikanParameterField(
          prefix: '视野长度',
          formula: r'l\,/\,\mathrm{m}',
          value: constants.l,
          label: '视野长度',
          dark: dark,
          onChanged: (value) => onChanged('l', value),
        ),
        _MillikanParameterField(
          prefix: '修正系数',
          formula: r'b\,/\,\mathrm{m\cdot cmHg}',
          value: constants.b,
          label: '修正系数',
          dark: dark,
          onChanged: (value) => onChanged('b', value),
        ),
        _MillikanParameterField(
          prefix: '电子电荷',
          formula: r'e\,/\,\mathrm{C}',
          value: constants.electronCharge,
          label: '电子电荷',
          dark: dark,
          onChanged: (value) => onChanged('electronCharge', value),
        ),
      ],
    );
  }
}

class _MillikanParameterGrid extends StatelessWidget {
  const _MillikanParameterGrid({required this.dark, required this.fields});

  final bool dark;
  final List<_MillikanParameterField> fields;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth <= 420
            ? 1
            : constraints.maxWidth <= 720
            ? 2
            : 4;
        const gap = 10.0;
        final width = columns == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final field in fields) SizedBox(width: width, child: field),
          ],
        );
      },
    );
  }
}

class _MillikanGroupInput extends StatelessWidget {
  const _MillikanGroupInput({
    required this.group,
    required this.groupIndex,
    required this.dark,
    required this.onVoltageChanged,
    required this.onTimeChanged,
  });

  final MillikanGroupInput group;
  final int groupIndex;
  final bool dark;
  final ValueChanged<String> onVoltageChanged;
  final void Function(int index, String value) onTimeChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MillikanParameterGrid(
          dark: dark,
          fields: [
            _MillikanParameterField(
              prefix: '平衡电压',
              formula: r'U\,/\,\mathrm{V}',
              value: group.voltage,
              label: '第 ${groupIndex + 1} 组平衡电压',
              dark: dark,
              onChanged: onVoltageChanged,
            ),
          ],
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
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
                      (dark
                          ? const Color(0xFF31546B)
                          : const Color(0xFFD5E4EF)),
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
                  border: _millikanTableBorder(dark),
                  children: [
                    TableRow(
                      decoration: BoxDecoration(
                        color: _millikanHeaderColor(dark),
                      ),
                      children: [
                        _millikanHeaderCell(const Text('次数'), dark),
                        _millikanHeaderCell(
                          _millikanHeaderMath(
                            '下降时间',
                            r't_g\,/\,\mathrm{s}',
                            dark,
                          ),
                          dark,
                        ),
                      ],
                    ),
                    for (var index = 0; index < group.times.length; index++)
                      TableRow(
                        children: [
                          _millikanTableCell(
                            Text(
                              '${index + 1}',
                              style: _millikanRowLabelStyle(dark),
                            ),
                            dark,
                            labelCell: true,
                          ),
                          _millikanTableCell(
                            _MillikanTextField(
                              key: ValueKey<String>(
                                'millikan-time-$groupIndex-$index',
                              ),
                              value: group.times[index],
                              label:
                                  '第 ${groupIndex + 1} 组下降时间第 ${index + 1} 次',
                              dark: dark,
                              compact: true,
                              onChanged: (value) => onTimeChanged(index, value),
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
        ),
      ],
    );
  }
}

class _MillikanParameterField extends StatelessWidget {
  const _MillikanParameterField({
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
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 26),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 3,
            children: [
              Text(prefix, style: _millikanFieldLabelStyle(dark)),
              _millikanMath(
                formula,
                dark,
                fontSize: 11,
                color: _millikanFieldLabelColor(dark),
              ),
            ],
          ),
        ),
        const SizedBox(height: 5),
        _MillikanTextField(
          value: value,
          label: label,
          dark: dark,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _MillikanResults extends StatelessWidget {
  const _MillikanResults({
    required this.calculation,
    required this.dark,
    required this.onExportChart,
  });

  final MillikanCalculation calculation;
  final bool dark;
  final ValueChanged<MillikanChartSpec> onExportChart;

  @override
  Widget build(BuildContext context) {
    final chart = millikanChartSpec(calculation);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MillikanResultCard(
          title: '逐组计算结果',
          dark: dark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MillikanResultTable(calculation: calculation, dark: dark),
              const SizedBox(height: 9),
              _MillikanResultLine(
                prefix: '电子电荷',
                formula: r'e\,/\,\mathrm{C}',
                value: MillikanCalculator.format(calculation.electronCharge),
                dark: dark,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text('电荷关系图', style: _millikanChartGroupTitleStyle(dark)),
        const SizedBox(height: 9),
        MillikanChartCard(
          spec: chart,
          dark: dark,
          onExport: () => onExportChart(chart),
        ),
      ],
    );
  }
}

class _MillikanResultCard extends StatelessWidget {
  const _MillikanResultCard({
    required this.title,
    required this.dark,
    required this.child,
  });

  final String title;
  final bool dark;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
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
          Text(title, style: _millikanResultTitleStyle(dark)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _MillikanResultTable extends StatelessWidget {
  const _MillikanResultTable({required this.calculation, required this.dark});

  final MillikanCalculation calculation;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width =
            constraints.maxWidth.isFinite && constraints.maxWidth > 920
            ? constraints.maxWidth
            : 920.0;
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
              columnWidths: {
                0: const FixedColumnWidth(86),
                for (var index = 1; index < 12; index++)
                  index: const FlexColumnWidth(1),
              },
              border: _millikanTableBorder(dark),
              children: [
                TableRow(
                  decoration: BoxDecoration(color: _millikanHeaderColor(dark)),
                  children: [
                    _millikanHeaderCell(const Text('组数'), dark),
                    _millikanHeaderCell(
                      _millikanHeaderMath('电压', r'U\,/\,\mathrm{V}', dark),
                      dark,
                    ),
                    for (var index = 0; index < 5; index++)
                      _millikanHeaderCell(
                        _millikanHeaderMath(
                          '时间 ${index + 1}',
                          't_{g,${index + 1}}\\,/\\,\\mathrm{s}',
                          dark,
                        ),
                        dark,
                      ),
                    _millikanHeaderCell(
                      _millikanHeaderMath(
                        '平均时间',
                        r'\bar t_g\,/\,\mathrm{s}',
                        dark,
                      ),
                      dark,
                    ),
                    _millikanHeaderCell(
                      _millikanHeaderMath('半径', r'a\,/\,\mathrm{m}', dark),
                      dark,
                    ),
                    _millikanHeaderCell(
                      _millikanHeaderMath('电荷', r'q\,/\,\mathrm{C}', dark),
                      dark,
                    ),
                    _millikanHeaderCell(
                      _millikanHeaderMath('电荷数', r'q/e', dark),
                      dark,
                    ),
                    _millikanHeaderCell(
                      _millikanHeaderMath('取整电荷数', 'N', dark),
                      dark,
                    ),
                  ],
                ),
                for (var index = 0; index < calculation.groups.length; index++)
                  _millikanResultRow(index, calculation.groups[index], dark),
              ],
            ),
          ),
        );
      },
    );
  }
}

TableRow _millikanResultRow(
  int index,
  MillikanGroupCalculation group,
  bool dark,
) {
  final values = <String>[
    '${index + 1}',
    MillikanCalculator.format(group.voltage),
    ...group.times.map(MillikanCalculator.format),
    MillikanCalculator.format(group.timeMean),
    MillikanCalculator.format(group.radius),
    MillikanCalculator.format(group.charge),
    MillikanCalculator.format(group.chargeNumber),
    group.nearestChargeNumber?.toString() ?? '—',
  ];
  return TableRow(
    children: [
      _millikanTableCell(
        Text(values[0], style: _millikanRowLabelStyle(dark)),
        dark,
        labelCell: true,
      ),
      for (final value in values.skip(1))
        _millikanTableCell(_millikanValue(value, dark), dark),
    ],
  );
}

class _MillikanResultLine extends StatelessWidget {
  const _MillikanResultLine({
    required this.prefix,
    required this.formula,
    required this.value,
    required this.dark,
  });

  final String prefix;
  final String formula;
  final String value;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth <= 720;
        final label = Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          runSpacing: 2,
          children: [
            Text(prefix, style: _millikanResultLabelStyle(dark)),
            _millikanMath(formula, dark, fontSize: 12),
          ],
        );
        final valueWidget = Text(
          value,
          textAlign: narrow ? TextAlign.left : TextAlign.right,
          style: _millikanResultValueStyle(dark),
        );
        return Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 30),
          padding: const EdgeInsets.only(top: 7),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: dark ? const Color(0xFF28465C) : const Color(0xFFE5EDF2),
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
}

class _MillikanTextField extends StatefulWidget {
  const _MillikanTextField({
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
  State<_MillikanTextField> createState() => _MillikanTextFieldState();
}

class _MillikanTextFieldState extends State<_MillikanTextField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _MillikanTextField oldWidget) {
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
              vertical: widget.compact ? 4 : 6,
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

Widget _millikanHeaderMath(String text, String formula, bool dark) {
  return _millikanMixedLabel(
    prefix: text,
    formula: formula,
    dark: dark,
    textStyle: _millikanHeaderTextStyle(dark),
  );
}

Widget _millikanMixedLabel({
  required String prefix,
  required String formula,
  required bool dark,
  TextStyle? textStyle,
}) {
  return Wrap(
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: 3,
    children: [
      Text(prefix, style: textStyle ?? _millikanCellTextStyle(dark)),
      _millikanMath(
        formula,
        dark,
        fontSize: textStyle?.fontSize ?? 12,
        weight: textStyle?.fontWeight ?? FontWeight.w400,
        color: textStyle?.color,
      ),
    ],
  );
}

Widget _millikanTableCell(Widget child, bool dark, {bool labelCell = false}) {
  return Container(
    constraints: const BoxConstraints(minHeight: 38),
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 7),
    alignment: Alignment.center,
    color: labelCell
        ? (dark ? const Color(0xFF14263A) : const Color(0xFFF8FBFD))
        : (EcjtuColors.platformSurface(
            dark,
            (dark ? const Color(0xFF101D31) : Colors.white),
          )),
    child: DefaultTextStyle.merge(
      style: _millikanCellTextStyle(dark),
      child: child,
    ),
  );
}

Widget _millikanHeaderCell(Widget child, bool dark) {
  return Container(
    constraints: const BoxConstraints(minHeight: 42),
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
    alignment: Alignment.center,
    color: _millikanHeaderColor(dark),
    child: DefaultTextStyle.merge(
      style: _millikanHeaderTextStyle(dark),
      child: child,
    ),
  );
}

Widget _millikanValue(String value, bool dark) {
  return Text(
    value,
    textAlign: TextAlign.center,
    style: _millikanCellTextStyle(dark),
  );
}

Widget _millikanMath(
  String formula,
  bool dark, {
  double fontSize = 14,
  FontWeight? weight,
  Color? color,
  bool display = false,
}) {
  return SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Math.tex(
      formula,
      mathStyle: display ? MathStyle.display : MathStyle.text,
      textStyle: TextStyle(
        color:
            color ?? (dark ? const Color(0xFFB7D9ED) : const Color(0xFF334F65)),
        fontSize: fontSize,
        fontWeight: weight,
        height: 1.35,
      ),
      onErrorFallback: (_) => const SizedBox.shrink(),
    ),
  );
}

TableBorder _millikanTableBorder(bool dark) {
  return TableBorder(
    horizontalInside: BorderSide(
      color: dark ? const Color(0xFF28465C) : const Color(0xFFE5EDF2),
    ),
    verticalInside: BorderSide(
      color: dark ? const Color(0xFF28465C) : const Color(0xFFE5EDF2),
    ),
  );
}

Color _millikanHeaderColor(bool dark) =>
    dark ? const Color(0xFF14263A) : const Color(0xFFEEF6FA);

TextStyle _millikanSectionTitleStyle(bool dark) => TextStyle(
  color: EcjtuColors.platformText(
    dark,
    (dark ? const Color(0xFFE1EDFF) : const Color(0xFF223549)),
  ),
  fontSize: 13,
  fontWeight: FontWeight.w700,
  height: 1.3,
);

TextStyle _millikanFormulaTitleStyle(bool dark) => TextStyle(
  color: EcjtuColors.platformText(
    dark,
    (dark ? const Color(0xFFD6E6F3) : const Color(0xFF275B7A)),
  ),
  fontSize: 12,
  fontWeight: FontWeight.w700,
  height: 1.3,
);

TextStyle _millikanFormulaNumberStyle(bool dark) => TextStyle(
  color: EcjtuColors.platformText(
    dark,
    (dark ? const Color(0xFFE1EDFF) : const Color(0xFF223549)),
  ),
  fontSize: 16,
  fontWeight: FontWeight.w500,
  height: 1.2,
);

TextStyle _millikanResultTitleStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFF9DDCFF) : const Color(0xFF275B7A),
  fontSize: 13,
  fontWeight: FontWeight.w700,
  height: 1.3,
);

TextStyle _millikanChartGroupTitleStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFF9DDCFF) : const Color(0xFF275B7A),
  fontSize: 12,
  fontWeight: FontWeight.w700,
  height: 1.3,
);

TextStyle _millikanFieldLabelStyle(bool dark) => TextStyle(
  color: EcjtuColors.platformMuted(
    dark,
    (dark ? const Color(0xFF9EACC3) : const Color(0xFF667B8E)),
  ),
  fontSize: 11,
  height: 1.3,
);

Color _millikanFieldLabelColor(bool dark) => EcjtuColors.platformMuted(
  dark,
  (dark ? const Color(0xFF9EACC3) : const Color(0xFF667B8E)),
);

TextStyle _millikanHeaderTextStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFFD6E6F3) : const Color(0xFF5D7487),
  fontSize: 11,
  fontWeight: FontWeight.w700,
  height: 1.25,
);

TextStyle _millikanCellTextStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFFB7D9ED) : const Color(0xFF334F65),
  fontSize: 12,
  height: 1.25,
);

TextStyle _millikanRowLabelStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFFB7D9ED) : const Color(0xFF275B7A),
  fontSize: 12,
  fontWeight: FontWeight.w700,
  height: 1.25,
);

TextStyle _millikanResultLabelStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFF9EACC3) : const Color(0xFF527087),
  fontSize: 12,
  fontWeight: FontWeight.w600,
  height: 1.3,
);

TextStyle _millikanResultValueStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFF8FD2FF) : const Color(0xFF275B7A),
  fontSize: 12,
  fontWeight: FontWeight.w700,
  height: 1.3,
);
