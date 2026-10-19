// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

part of 'physics_photoelectric_planck_page.dart';

Widget _photoelectricFormulaBlock(bool dark) {
  const formulas = [
    r'\nu=\frac{c}{\lambda}',
    r'U_s=k\nu+b',
    r'h=e k',
    r'\varepsilon=\frac{|h-h_0|}{|h_0|}',
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
        Text('计算公式', style: _photoelectricFormulaTitleStyle(dark)),
        const SizedBox(height: 7),
        for (var index = 0; index < formulas.length; index++)
          _PhotoelectricFormulaLine(
            number: '${index + 1}.',
            formula: formulas[index],
            dark: dark,
          ),
      ],
    ),
  );
}

Widget _photoelectricSection({
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
            Text(title, style: _photoelectricSectionTitleStyle(dark)),
            const SizedBox(height: 12),
            child,
          ],
        ),
      );
    },
  );
}

class _PhotoelectricFormulaLine extends StatelessWidget {
  const _PhotoelectricFormulaLine({
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
            child: Text(number, style: _photoelectricFormulaNumberStyle(dark)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _photoelectricMath(
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

class _PhotoelectricGroupInput extends StatelessWidget {
  const _PhotoelectricGroupInput({
    required this.group,
    required this.dark,
    required this.onCutoffChanged,
    required this.onPointChanged,
  });

  final PhotoelectricGroupInput group;
  final bool dark;
  final ValueChanged<String> onCutoffChanged;
  final void Function(int index, String field, String value) onPointChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PhotoelectricParameterGrid(
          dark: dark,
          fields: [
            _PhotoelectricParameterField(
              prefix: '截止电压',
              formula: r'U_s\,/\,\mathrm{V}',
              value: group.cutoff,
              label: '波长 ${group.wavelength} nm 截止电压',
              dark: dark,
              onChanged: onCutoffChanged,
            ),
          ],
        ),
        const SizedBox(height: 10),
        _PhotoelectricPointTable(
          group: group,
          dark: dark,
          onChanged: onPointChanged,
        ),
      ],
    );
  }
}

class _PhotoelectricConstantsInput extends StatelessWidget {
  const _PhotoelectricConstantsInput({
    required this.state,
    required this.dark,
    required this.onChanged,
  });

  final PhotoelectricPlanckState state;
  final bool dark;
  final void Function(String field, String value) onChanged;

  @override
  Widget build(BuildContext context) {
    return _PhotoelectricParameterGrid(
      dark: dark,
      fields: [
        _PhotoelectricParameterField(
          prefix: '电子电荷',
          formula: r'e\,/\,\mathrm{C}',
          value: state.electronCharge,
          label: '电子电荷',
          dark: dark,
          onChanged: (value) => onChanged('electronCharge', value),
        ),
        _PhotoelectricParameterField(
          prefix: '普朗克常量公认值',
          formula: r'h_0\,/\,\mathrm{J\,s}',
          value: state.knownH,
          label: '普朗克常量公认值',
          dark: dark,
          onChanged: (value) => onChanged('knownH', value),
        ),
      ],
    );
  }
}

class _PhotoelectricParameterGrid extends StatelessWidget {
  const _PhotoelectricParameterGrid({required this.dark, required this.fields});

  final bool dark;
  final List<_PhotoelectricParameterField> fields;

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

class _PhotoelectricParameterField extends StatelessWidget {
  const _PhotoelectricParameterField({
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
              Text(prefix, style: _photoelectricFieldLabelStyle(dark)),
              _photoelectricMath(
                formula,
                dark,
                fontSize: 11,
                color: _photoelectricFieldLabelColor(dark),
              ),
            ],
          ),
        ),
        const SizedBox(height: 5),
        _PhotoelectricTextField(
          value: value,
          label: label,
          dark: dark,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _PhotoelectricPointTable extends StatelessWidget {
  const _PhotoelectricPointTable({
    required this.group,
    required this.dark,
    required this.onChanged,
  });

  final PhotoelectricGroupInput group;
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
                2: FlexColumnWidth(1),
              },
              border: _photoelectricTableBorder(dark),
              children: [
                TableRow(
                  decoration: BoxDecoration(
                    color: _photoelectricHeaderColor(dark),
                  ),
                  children: [
                    _photoelectricHeaderCell(const Text('序号'), dark),
                    _photoelectricHeaderCell(
                      _photoelectricHeaderMath(
                        '阳极电压',
                        r'U_{ka}\,/\,\mathrm{V}',
                        dark,
                      ),
                      dark,
                    ),
                    _photoelectricHeaderCell(
                      _photoelectricHeaderMath('光电流', r'I_{ka}', dark),
                      dark,
                    ),
                  ],
                ),
                for (var index = 0; index < group.points.length; index++)
                  TableRow(
                    children: [
                      _photoelectricTableCell(
                        Text(
                          '${index + 1}',
                          style: _photoelectricRowLabelStyle(dark),
                        ),
                        dark,
                        labelCell: true,
                      ),
                      _photoelectricTableCell(
                        _PhotoelectricTextField(
                          key: ValueKey<String>(
                            'photoelectric-voltage-${group.wavelength}-$index',
                          ),
                          value: group.points[index].voltage,
                          label:
                              '波长 ${group.wavelength} nm 阳极电压第 ${index + 1} 行',
                          dark: dark,
                          compact: true,
                          onChanged: (value) =>
                              onChanged(index, 'voltage', value),
                        ),
                        dark,
                      ),
                      _photoelectricTableCell(
                        _PhotoelectricTextField(
                          key: ValueKey<String>(
                            'photoelectric-current-${group.wavelength}-$index',
                          ),
                          value: group.points[index].current,
                          label:
                              '波长 ${group.wavelength} nm 光电流第 ${index + 1} 行',
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
          ),
        );
      },
    );
  }
}

class _PhotoelectricResults extends StatelessWidget {
  const _PhotoelectricResults({
    required this.calculation,
    required this.dark,
    required this.onExportChart,
  });

  final PhotoelectricPlanckCalculation calculation;
  final bool dark;
  final ValueChanged<PhotoelectricChartSpec> onExportChart;

  @override
  Widget build(BuildContext context) {
    final specs = photoelectricChartSpecs(calculation);
    final voltageCharts = specs.take(calculation.groups.length).toList();
    final fitChart = specs.last;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PhotoelectricResultCard(
          title: '截止电压与频率',
          dark: dark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PhotoelectricResultTable(
                headers: [
                  _photoelectricHeaderMath(
                    '波长',
                    r'\lambda\,/\,\mathrm{nm}',
                    dark,
                  ),
                  _photoelectricHeaderMath('频率', r'\nu\,/\,\mathrm{Hz}', dark),
                  _photoelectricHeaderMath('截止电压', r'U_s\,/\,\mathrm{V}', dark),
                  _photoelectricHeaderMath(
                    '曲线零点',
                    r'U_{s,0}\,/\,\mathrm{V}',
                    dark,
                  ),
                ],
                rows: [
                  for (final group in calculation.groups)
                    [
                      _photoelectricValue(
                        '${group.wavelength}',
                        dark,
                        labelCell: true,
                      ),
                      _photoelectricValue(
                        PhotoelectricPlanckCalculator.formatDouble(
                          group.frequency,
                        ),
                        dark,
                      ),
                      _photoelectricValue(
                        PhotoelectricPlanckCalculator.format(group.cutoff),
                        dark,
                      ),
                      _photoelectricValue(
                        PhotoelectricPlanckCalculator.format(
                          group.derivedCutoff,
                        ),
                        dark,
                      ),
                    ],
                ],
                dark: dark,
                minWidth: 520,
              ),
              const SizedBox(height: 9),
              _PhotoelectricResultLine(
                prefix: '拟合斜率',
                formula: r'k\,/\,(\mathrm{V\,s})',
                value: PhotoelectricPlanckCalculator.formatDouble(
                  calculation.fit.slope,
                ),
                dark: dark,
              ),
              _PhotoelectricResultLine(
                prefix: '普朗克常量',
                formula: r'h=e k\,/\,\mathrm{J\,s}',
                value: PhotoelectricPlanckCalculator.formatDouble(
                  calculation.h,
                ),
                dark: dark,
              ),
              _PhotoelectricResultLine(
                prefix: '公认值',
                formula: r'h_0\,/\,\mathrm{J\,s}',
                value: PhotoelectricPlanckCalculator.formatDouble(
                  calculation.knownH,
                ),
                dark: dark,
              ),
              _PhotoelectricResultLine(
                prefix: '相对误差',
                formula: r'\varepsilon',
                value: _photoelectricPercent(calculation.relativeError),
                dark: dark,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _PhotoelectricChartGroup(
          title: '伏安特性图',
          specs: voltageCharts,
          dark: dark,
          onExport: onExportChart,
        ),
        const SizedBox(height: 14),
        _PhotoelectricChartGroup(
          title: '截止电压拟合图',
          specs: [fitChart],
          dark: dark,
          onExport: onExportChart,
        ),
      ],
    );
  }
}

class _PhotoelectricChartGroup extends StatelessWidget {
  const _PhotoelectricChartGroup({
    required this.title,
    required this.specs,
    required this.dark,
    required this.onExport,
  });

  final String title;
  final List<PhotoelectricChartSpec> specs;
  final bool dark;
  final ValueChanged<PhotoelectricChartSpec> onExport;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: _photoelectricChartGroupTitleStyle(dark)),
        const SizedBox(height: 9),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 720 ? 2 : 1;
            return GridView.count(
              crossAxisCount: columns,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: columns == 2 ? 1.28 : 1.72,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (final spec in specs)
                  PhotoelectricChartCard(
                    spec: spec,
                    dark: dark,
                    onExport: () => onExport(spec),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _PhotoelectricResultCard extends StatelessWidget {
  const _PhotoelectricResultCard({
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
          Text(title, style: _photoelectricResultTitleStyle(dark)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _PhotoelectricResultTable extends StatelessWidget {
  const _PhotoelectricResultTable({
    required this.headers,
    required this.rows,
    required this.dark,
    required this.minWidth,
  });

  final List<Widget> headers;
  final List<List<Widget>> rows;
  final bool dark;
  final double minWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width =
            constraints.maxWidth.isFinite && constraints.maxWidth > minWidth
            ? constraints.maxWidth
            : minWidth;
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
                for (var index = 0; index < headers.length; index++)
                  index: index == 0
                      ? const FixedColumnWidth(86)
                      : const FlexColumnWidth(1),
              },
              border: _photoelectricTableBorder(dark),
              children: [
                TableRow(
                  decoration: BoxDecoration(
                    color: _photoelectricHeaderColor(dark),
                  ),
                  children: [
                    for (final header in headers)
                      _photoelectricHeaderCell(header, dark),
                  ],
                ),
                for (final row in rows)
                  TableRow(
                    children: [
                      for (var index = 0; index < row.length; index++)
                        _photoelectricTableCell(
                          row[index],
                          dark,
                          labelCell: index == 0,
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

class _PhotoelectricResultLine extends StatelessWidget {
  const _PhotoelectricResultLine({
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
            Text(prefix, style: _photoelectricResultLabelStyle(dark)),
            _photoelectricMath(formula, dark, fontSize: 12),
          ],
        );
        final valueWidget = Text(
          value,
          textAlign: narrow ? TextAlign.left : TextAlign.right,
          style: _photoelectricResultValueStyle(dark),
        );
        return Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 32),
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

class _PhotoelectricTextField extends StatefulWidget {
  const _PhotoelectricTextField({
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
  State<_PhotoelectricTextField> createState() =>
      _PhotoelectricTextFieldState();
}

class _PhotoelectricTextFieldState extends State<_PhotoelectricTextField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _PhotoelectricTextField oldWidget) {
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

Widget _photoelectricHeaderMath(String text, String formula, bool dark) {
  return _photoelectricMixedLabel(
    prefix: text,
    formula: formula,
    dark: dark,
    textStyle: _photoelectricHeaderTextStyle(dark),
  );
}

Widget _photoelectricMixedLabel({
  required String prefix,
  required String formula,
  required bool dark,
  TextStyle? textStyle,
}) {
  return Wrap(
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: 3,
    children: [
      Text(prefix, style: textStyle ?? _photoelectricCellTextStyle(dark)),
      _photoelectricMath(
        formula,
        dark,
        fontSize: textStyle?.fontSize ?? 12,
        weight: textStyle?.fontWeight ?? FontWeight.w400,
        color: textStyle?.color,
      ),
    ],
  );
}

Widget _photoelectricTableCell(
  Widget child,
  bool dark, {
  bool labelCell = false,
}) {
  return Container(
    constraints: const BoxConstraints(minHeight: 38),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
    alignment: Alignment.center,
    color: labelCell
        ? (dark ? const Color(0xFF14263A) : const Color(0xFFF8FBFD))
        : (EcjtuColors.platformSurface(
            dark,
            (dark ? const Color(0xFF101D31) : Colors.white),
          )),
    child: DefaultTextStyle.merge(
      style: labelCell
          ? _photoelectricRowLabelStyle(dark)
          : _photoelectricCellTextStyle(dark),
      child: child,
    ),
  );
}

Widget _photoelectricHeaderCell(Widget child, bool dark) {
  return Container(
    constraints: const BoxConstraints(minHeight: 38),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
    alignment: Alignment.center,
    color: _photoelectricHeaderColor(dark),
    child: DefaultTextStyle.merge(
      style: _photoelectricHeaderTextStyle(dark),
      child: child,
    ),
  );
}

Widget _photoelectricValue(String value, bool dark, {bool labelCell = false}) {
  return Text(
    value,
    textAlign: TextAlign.center,
    style: labelCell
        ? _photoelectricRowLabelStyle(dark)
        : _photoelectricCellTextStyle(dark),
  );
}

Widget _photoelectricMath(
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

String _photoelectricPercent(double? value) {
  if (value == null || !value.isFinite) return '—';
  return '${PhotoelectricPlanckCalculator.formatDouble(value * 100, digits: 4)}%';
}

TableBorder _photoelectricTableBorder(bool dark) {
  return TableBorder(
    horizontalInside: BorderSide(
      color: dark ? const Color(0xFF28465C) : const Color(0xFFE5EDF2),
    ),
    verticalInside: BorderSide(
      color: dark ? const Color(0xFF28465C) : const Color(0xFFE5EDF2),
    ),
  );
}

Color _photoelectricHeaderColor(bool dark) =>
    dark ? const Color(0xFF14263A) : const Color(0xFFEEF6FA);

TextStyle _photoelectricSectionTitleStyle(bool dark) => TextStyle(
  color: EcjtuColors.platformText(
    dark,
    (dark ? const Color(0xFFE1EDFF) : const Color(0xFF223549)),
  ),
  fontSize: 13,
  fontWeight: FontWeight.w700,
  height: 1.3,
);

TextStyle _photoelectricFormulaTitleStyle(bool dark) => TextStyle(
  color: EcjtuColors.platformText(
    dark,
    (dark ? const Color(0xFFD6E6F3) : const Color(0xFF275B7A)),
  ),
  fontSize: 12,
  fontWeight: FontWeight.w700,
  height: 1.3,
);

TextStyle _photoelectricFormulaNumberStyle(bool dark) => TextStyle(
  color: EcjtuColors.platformText(
    dark,
    (dark ? const Color(0xFFE1EDFF) : const Color(0xFF223549)),
  ),
  fontSize: 16,
  fontWeight: FontWeight.w500,
  height: 1.2,
);

TextStyle _photoelectricResultTitleStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFF9DDCFF) : const Color(0xFF275B7A),
  fontSize: 13,
  fontWeight: FontWeight.w700,
  height: 1.3,
);

TextStyle _photoelectricChartGroupTitleStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFF9DDCFF) : const Color(0xFF275B7A),
  fontSize: 12,
  fontWeight: FontWeight.w700,
  height: 1.3,
);

TextStyle _photoelectricFieldLabelStyle(bool dark) => TextStyle(
  color: EcjtuColors.platformMuted(
    dark,
    (dark ? const Color(0xFF9EACC3) : const Color(0xFF667B8E)),
  ),
  fontSize: 11,
  height: 1.3,
);

Color _photoelectricFieldLabelColor(bool dark) => EcjtuColors.platformMuted(
  dark,
  (dark ? const Color(0xFF9EACC3) : const Color(0xFF667B8E)),
);

TextStyle _photoelectricHeaderTextStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFFD6E6F3) : const Color(0xFF5D7487),
  fontSize: 12,
  fontWeight: FontWeight.w700,
  height: 1.25,
);

TextStyle _photoelectricCellTextStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFFB7D9ED) : const Color(0xFF334F65),
  fontSize: 12,
  height: 1.25,
);

TextStyle _photoelectricRowLabelStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFFB7D9ED) : const Color(0xFF275B7A),
  fontSize: 12,
  fontWeight: FontWeight.w700,
  height: 1.25,
);

TextStyle _photoelectricResultLabelStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFF9EACC3) : const Color(0xFF527087),
  fontSize: 12,
  fontWeight: FontWeight.w600,
  height: 1.3,
);

TextStyle _photoelectricResultValueStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFF8FD2FF) : const Color(0xFF275B7A),
  fontSize: 12,
  fontWeight: FontWeight.w700,
  height: 1.3,
);
