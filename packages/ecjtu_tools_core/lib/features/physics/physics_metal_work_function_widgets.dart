// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

part of 'physics_metal_work_function_page.dart';

Widget _metalWorkFormulaBlock(bool dark) {
  const formulas = [
    r'x=\sqrt{U_a}',
    r'y=\lg I_a',
    r'z=\lg(I_a/T^2)',
    r'e\varphi=\frac{|m|}{C}',
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
        Text('计算公式', style: _metalWorkFormulaTitleStyle(dark)),
        const SizedBox(height: 7),
        for (var index = 0; index < formulas.length; index++)
          _MetalWorkFormulaLine(
            number: '${index + 1}.',
            formula: formulas[index],
            dark: dark,
          ),
      ],
    ),
  );
}

Widget _metalWorkSection({
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
            Text(title, style: _metalWorkSectionTitleStyle(dark)),
            const SizedBox(height: 12),
            child,
          ],
        ),
      );
    },
  );
}

class _MetalWorkFormulaLine extends StatelessWidget {
  const _MetalWorkFormulaLine({
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
            child: Text(number, style: _metalWorkFormulaNumberStyle(dark)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _metalWorkMath(
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

class _MetalWorkGroupInput extends StatelessWidget {
  const _MetalWorkGroupInput({
    required this.group,
    required this.groupIndex,
    required this.dark,
    required this.onInfoChanged,
    required this.onPointChanged,
  });

  final MetalWorkGroupInput group;
  final int groupIndex;
  final bool dark;
  final void Function(String field, String value) onInfoChanged;
  final void Function(int index, String field, String value) onPointChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MetalWorkParameterGrid(
          dark: dark,
          fields: [
            _MetalWorkParameterField(
              prefix: '灯丝电流',
              formula: r'I_f\,/\,\mathrm{A}',
              value: group.filamentCurrent,
              label: '第 ${groupIndex + 1} 组灯丝电流',
              dark: dark,
              onChanged: (value) => onInfoChanged('filamentCurrent', value),
            ),
            _MetalWorkParameterField(
              prefix: '灯丝温度',
              formula: r'T\,/\,\mathrm{K}',
              value: group.temperature,
              label: '第 ${groupIndex + 1} 组灯丝温度',
              dark: dark,
              onChanged: (value) => onInfoChanged('temperature', value),
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
                    2: FlexColumnWidth(1),
                  },
                  border: _metalWorkTableBorder(dark),
                  children: [
                    TableRow(
                      decoration: BoxDecoration(
                        color: _metalWorkHeaderColor(dark),
                      ),
                      children: [
                        _metalWorkHeaderCell(const Text('序号'), dark),
                        _metalWorkHeaderCell(
                          _metalWorkHeaderMath(
                            '阳极电压',
                            r'U_a\,/\,\mathrm{V}',
                            dark,
                          ),
                          dark,
                        ),
                        _metalWorkHeaderCell(
                          _metalWorkHeaderMath(
                            '阳极电流',
                            r'I_a\,/\,\mathrm{A}',
                            dark,
                          ),
                          dark,
                        ),
                      ],
                    ),
                    for (var index = 0; index < group.points.length; index++)
                      TableRow(
                        children: [
                          _metalWorkTableCell(
                            Text(
                              '${index + 1}',
                              style: _metalWorkRowLabelStyle(dark),
                            ),
                            dark,
                            labelCell: true,
                          ),
                          _metalWorkTableCell(
                            _MetalWorkTextField(
                              key: ValueKey<String>(
                                'metal-work-voltage-$groupIndex-$index',
                              ),
                              value: group.points[index].voltage,
                              label:
                                  '第 ${groupIndex + 1} 组阳极电压第 ${index + 1} 次',
                              dark: dark,
                              compact: true,
                              onChanged: (value) =>
                                  onPointChanged(index, 'voltage', value),
                            ),
                            dark,
                          ),
                          _metalWorkTableCell(
                            _MetalWorkTextField(
                              key: ValueKey<String>(
                                'metal-work-current-$groupIndex-$index',
                              ),
                              value: group.points[index].current,
                              label:
                                  '第 ${groupIndex + 1} 组阳极电流第 ${index + 1} 次',
                              dark: dark,
                              compact: true,
                              onChanged: (value) =>
                                  onPointChanged(index, 'current', value),
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

class _MetalWorkConstantsInput extends StatelessWidget {
  const _MetalWorkConstantsInput({
    required this.state,
    required this.dark,
    required this.onChanged,
  });

  final MetalWorkState state;
  final bool dark;
  final void Function(String field, String value) onChanged;

  @override
  Widget build(BuildContext context) {
    return _MetalWorkParameterGrid(
      dark: dark,
      fields: [
        _MetalWorkParameterField(
          prefix: '常数',
          formula: r'C\,/\,\mathrm{K}',
          value: state.constant,
          label: '常数',
          dark: dark,
          onChanged: (value) => onChanged('constant', value),
        ),
        _MetalWorkParameterField(
          prefix: '逸出功公认值',
          formula: r'e\varphi_0\,/\,\mathrm{eV}',
          value: state.known,
          label: '逸出功公认值',
          dark: dark,
          onChanged: (value) => onChanged('known', value),
        ),
      ],
    );
  }
}

class _MetalWorkParameterGrid extends StatelessWidget {
  const _MetalWorkParameterGrid({required this.dark, required this.fields});

  final bool dark;
  final List<Widget> fields;

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
              SizedBox(width: width, child: fields[index]),
          ],
        );
      },
    );
  }
}

class _MetalWorkParameterField extends StatelessWidget {
  const _MetalWorkParameterField({
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
    final labelStyle = _metalWorkFieldLabelStyle(dark);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 26),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 3,
              runSpacing: 2,
              children: [
                Text(prefix, style: labelStyle),
                _metalWorkMath(
                  formula,
                  dark,
                  fontSize: labelStyle.fontSize ?? 11,
                  weight: labelStyle.fontWeight,
                  color: labelStyle.color,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 5),
        _MetalWorkTextField(
          value: value,
          label: label,
          dark: dark,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _MetalWorkResults extends StatelessWidget {
  const _MetalWorkResults({
    required this.calculation,
    required this.dark,
    required this.onExportChart,
  });

  final MetalWorkCalculation calculation;
  final bool dark;
  final ValueChanged<MetalWorkChartSpec> onExportChart;

  @override
  Widget build(BuildContext context) {
    final specs = metalWorkChartSpecs(calculation);
    final groupSpecs = specs.take(calculation.groups.length).toList();
    final relationSpec = specs.last;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < calculation.groups.length; index++) ...[
          _MetalWorkGroupResult(
            index: index,
            group: calculation.groups[index],
            dark: dark,
          ),
          const SizedBox(height: 10),
        ],
        _metalWorkResultCard(
          '逸出功计算结果',
          dark,
          _MetalWorkResultLine(
            prefix: '直线斜率',
            formula: r'm\,/\,\mathrm{K}',
            value: MetalWorkCalculator.format(calculation.fit.slope),
            dark: dark,
            first: true,
          ),
          _MetalWorkResultLine(
            prefix: '常数',
            formula: r'C\,/\,\mathrm{K}',
            value: MetalWorkCalculator.format(calculation.constant),
            dark: dark,
          ),
          _MetalWorkResultLine(
            prefix: '逸出功',
            formula: r'e\varphi=|m|/C\,/\,\mathrm{eV}',
            value: MetalWorkCalculator.format(calculation.work),
            dark: dark,
          ),
          _MetalWorkResultLine(
            prefix: '公认值',
            formula: r'e\varphi_0\,/\,\mathrm{eV}',
            value: MetalWorkCalculator.format(calculation.known),
            dark: dark,
          ),
          _MetalWorkResultLine(
            prefix: '相对误差',
            formula: r'\varepsilon',
            value: _metalWorkPercent(calculation.relativeError),
            dark: dark,
          ),
        ),
        const SizedBox(height: 14),
        _MetalWorkChartGroup(
          title: '阳极伏安图',
          specs: groupSpecs,
          dark: dark,
          onExport: onExportChart,
        ),
        const SizedBox(height: 14),
        _MetalWorkChartGroup(
          title: '温度关系图',
          specs: [relationSpec],
          dark: dark,
          onExport: onExportChart,
        ),
      ],
    );
  }
}

class _MetalWorkChartGroup extends StatelessWidget {
  const _MetalWorkChartGroup({
    required this.title,
    required this.specs,
    required this.dark,
    required this.onExport,
  });

  final String title;
  final List<MetalWorkChartSpec> specs;
  final bool dark;
  final ValueChanged<MetalWorkChartSpec> onExport;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: _metalWorkResultTitleStyle(dark)),
        const SizedBox(height: 9),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns =
                constraints.maxWidth.isFinite && constraints.maxWidth > 720
                ? 2
                : 1;
            const gap = 12.0;
            final width = constraints.maxWidth.isFinite
                ? (constraints.maxWidth - gap * (columns - 1)) / columns
                : 760.0;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final spec in specs)
                  SizedBox(
                    width: width,
                    child: MetalWorkChartCard(
                      spec: spec,
                      dark: dark,
                      onExport: () => onExport(spec),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _MetalWorkGroupResult extends StatelessWidget {
  const _MetalWorkGroupResult({
    required this.index,
    required this.group,
    required this.dark,
  });

  final int index;
  final MetalWorkGroupCalculation group;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return _metalWorkResultCard(
      '第 ${index + 1} 组中间量',
      dark,
      _MetalWorkIntermediateTable(group: group, dark: dark),
      _MetalWorkResultLine(
        prefix: '拟合截距',
        formula: r'b',
        value: MetalWorkCalculator.format(group.fit.intercept),
        dark: dark,
        first: true,
      ),
      _MetalWorkResultLine(
        prefix: '温度',
        formula: r'T\,/\,\mathrm{K}',
        value: MetalWorkCalculator.format(group.temperature),
        dark: dark,
      ),
      _MetalWorkResultLine(
        prefix: '温度修正对数',
        formula: r'\lg(I_a/T^2)',
        value: MetalWorkCalculator.format(group.lgIT2),
        dark: dark,
      ),
      _MetalWorkResultLine(
        prefix: '倒数温度',
        formula: r'1/T\,/\,\mathrm{K^{-1}}',
        value: MetalWorkCalculator.format(group.inverseTemperature),
        dark: dark,
      ),
    );
  }
}

class _MetalWorkIntermediateTable extends StatelessWidget {
  const _MetalWorkIntermediateTable({required this.group, required this.dark});

  final MetalWorkGroupCalculation group;
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
                0: FlexColumnWidth(1),
                1: FlexColumnWidth(1),
                2: FlexColumnWidth(1),
                3: FlexColumnWidth(1),
              },
              border: _metalWorkTableBorder(dark),
              children: [
                TableRow(
                  decoration: BoxDecoration(color: _metalWorkHeaderColor(dark)),
                  children: [
                    _metalWorkHeaderCell(
                      _metalWorkHeaderMath('阳极电压', r'U_a\,/\,\mathrm{V}', dark),
                      dark,
                    ),
                    _metalWorkHeaderCell(
                      _metalWorkHeaderMath('阳极电流', r'I_a\,/\,\mathrm{A}', dark),
                      dark,
                    ),
                    _metalWorkHeaderCell(
                      _metalWorkHeaderMath('平方根', r'\sqrt{U_a}', dark),
                      dark,
                    ),
                    _metalWorkHeaderCell(
                      _metalWorkHeaderMath('对数', r'\lg I_a', dark),
                      dark,
                    ),
                  ],
                ),
                for (final point in group.points)
                  TableRow(
                    children: [
                      _metalWorkTableCell(
                        _metalWorkValue(
                          MetalWorkCalculator.format(point.voltage),
                          dark,
                        ),
                        dark,
                      ),
                      _metalWorkTableCell(
                        _metalWorkValue(
                          MetalWorkCalculator.format(point.current),
                          dark,
                        ),
                        dark,
                      ),
                      _metalWorkTableCell(
                        _metalWorkValue(
                          MetalWorkCalculator.format(point.sqrtVoltage),
                          dark,
                        ),
                        dark,
                      ),
                      _metalWorkTableCell(
                        _metalWorkValue(
                          MetalWorkCalculator.format(point.lgCurrent),
                          dark,
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

Widget _metalWorkResultCard(
  String title,
  bool dark, [
  Widget? first,
  Widget? second,
  Widget? third,
  Widget? fourth,
  Widget? fifth,
]) {
  final children = <Widget>[?first, ?second, ?third, ?fourth, ?fifth];
  final content = <Widget>[
    for (var index = 0; index < children.length; index++) ...[
      if (index > 0) const SizedBox(height: 10),
      children[index],
    ],
  ];
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(13, 11, 13, 12),
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
        Text(title, style: _metalWorkResultTitleStyle(dark)),
        const SizedBox(height: 10),
        ...content,
      ],
    ),
  );
}

class _MetalWorkResultLine extends StatelessWidget {
  const _MetalWorkResultLine({
    required this.prefix,
    required this.formula,
    required this.value,
    required this.dark,
    this.first = false,
  });

  final String prefix;
  final String formula;
  final String value;
  final bool dark;
  final bool first;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth <= 720;
        final labelStyle = _metalWorkResultLabelStyle(dark);
        final label = Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          runSpacing: 2,
          children: [
            Text(prefix, style: labelStyle),
            _metalWorkMath(
              formula,
              dark,
              fontSize: 12,
              color: labelStyle.color,
            ),
          ],
        );
        final valueWidget = Text(
          value,
          textAlign: narrow ? TextAlign.left : TextAlign.right,
          style: _metalWorkResultValueStyle(dark),
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
}

class _MetalWorkTextField extends StatefulWidget {
  const _MetalWorkTextField({
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
  State<_MetalWorkTextField> createState() => _MetalWorkTextFieldState();
}

class _MetalWorkTextFieldState extends State<_MetalWorkTextField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _MetalWorkTextField oldWidget) {
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
    final height = widget.compact ? 30.0 : 34.0;
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

Widget _metalWorkHeaderMath(String text, String formula, bool dark) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        text,
        textAlign: TextAlign.center,
        style: _metalWorkHeaderTextStyle(dark),
      ),
      const SizedBox(height: 1),
      _metalWorkMath(formula, dark, fontSize: 11, weight: FontWeight.w700),
    ],
  );
}

Widget _metalWorkTableCell(Widget child, bool dark, {bool labelCell = false}) {
  return Container(
    constraints: const BoxConstraints(minHeight: 38),
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 7),
    alignment: labelCell ? Alignment.centerLeft : Alignment.center,
    color: labelCell
        ? (dark ? const Color(0xFF14263A) : const Color(0xFFF8FBFD))
        : (EcjtuColors.platformSurface(
            dark,
            (dark ? const Color(0xFF101D31) : Colors.white),
          )),
    child: DefaultTextStyle.merge(
      style: _metalWorkCellTextStyle(dark),
      child: child,
    ),
  );
}

Widget _metalWorkHeaderCell(Widget child, bool dark) {
  return Container(
    constraints: const BoxConstraints(minHeight: 42),
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
    alignment: Alignment.center,
    color: _metalWorkHeaderColor(dark),
    child: DefaultTextStyle.merge(
      style: _metalWorkHeaderTextStyle(dark),
      child: child,
    ),
  );
}

Widget _metalWorkValue(String value, bool dark) => Text(
  value,
  textAlign: TextAlign.center,
  style: _metalWorkCellTextStyle(dark),
);

Widget _metalWorkMath(
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
        height: display ? 1.25 : 1.3,
      ),
      onErrorFallback: (_) => const SizedBox.shrink(),
    ),
  );
}

String _metalWorkPercent(double? value) {
  if (value == null || !value.isFinite) return '—';
  return '${MetalWorkCalculator.formatDouble(value * 100, digits: 4)}%';
}

TableBorder _metalWorkTableBorder(bool dark) {
  return TableBorder(
    horizontalInside: BorderSide(
      color: dark ? const Color(0xFF28465C) : const Color(0xFFE5EDF2),
    ),
    verticalInside: BorderSide(
      color: dark ? const Color(0xFF28465C) : const Color(0xFFE5EDF2),
    ),
  );
}

Color _metalWorkHeaderColor(bool dark) =>
    dark ? const Color(0xFF14263A) : const Color(0xFFEEF6FA);

TextStyle _metalWorkSectionTitleStyle(bool dark) => TextStyle(
  color: EcjtuColors.platformText(
    dark,
    (dark ? const Color(0xFFE1EDFF) : const Color(0xFF223549)),
  ),
  fontSize: 13,
  fontWeight: FontWeight.w700,
  height: 1.3,
);

TextStyle _metalWorkResultTitleStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFF9DDCFF) : const Color(0xFF275B7A),
  fontSize: 13,
  fontWeight: FontWeight.w700,
  height: 1.3,
);

TextStyle _metalWorkFieldLabelStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFFB9E2F7) : const Color(0xFF667B8E),
  fontSize: 11,
  fontWeight: FontWeight.w600,
  height: 1.3,
);

TextStyle _metalWorkFormulaTitleStyle(bool dark) => TextStyle(
  color: EcjtuColors.platformText(
    dark,
    (dark ? const Color(0xFFD6E6F3) : const Color(0xFF275B7A)),
  ),
  fontSize: 12,
  fontWeight: FontWeight.w700,
  height: 1.3,
);

TextStyle _metalWorkFormulaNumberStyle(bool dark) => TextStyle(
  color: EcjtuColors.platformText(
    dark,
    (dark ? const Color(0xFFE1EDFF) : const Color(0xFF223549)),
  ),
  fontSize: 16,
  fontWeight: FontWeight.w500,
  height: 1.2,
);

TextStyle _metalWorkRowLabelStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFFB7D9ED) : const Color(0xFF275B7A),
  fontSize: 11,
  fontWeight: FontWeight.w700,
  height: 1.25,
);

TextStyle _metalWorkHeaderTextStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFFD6E6F3) : const Color(0xFF5D7487),
  fontSize: 11,
  fontWeight: FontWeight.w700,
  height: 1.25,
);

TextStyle _metalWorkCellTextStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFFB7D9ED) : const Color(0xFF334F65),
  fontSize: 11,
  height: 1.25,
);

TextStyle _metalWorkResultLabelStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFF9EACC3) : const Color(0xFF527087),
  fontSize: 12,
  fontWeight: FontWeight.w600,
  height: 1.3,
);

TextStyle _metalWorkResultValueStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFF8FD2FF) : const Color(0xFF275B7A),
  fontSize: 12,
  fontWeight: FontWeight.w700,
  height: 1.3,
);
