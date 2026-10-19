// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

part of 'physics_hall_effect_page.dart';

const _hallCombinations = <(String, String)>[
  ('pp', '正正'),
  ('nn', '负负'),
  ('pn', '正负'),
  ('np', '负正'),
];

Widget _hallSection({
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
            Text(title, style: _hallSectionTitleStyle(dark)),
            const SizedBox(height: 12),
            child,
          ],
        ),
      );
    },
  );
}

Widget _hallFormulaBlock(bool dark) {
  const formulas = [
    r'U_H=\frac{U_{++}+U_{--}-U_{+-}-U_{-+}}{4}',
    r'B=\frac{U_H}{170I_s}',
    r'B_{a+b}=B_a+B_b',
    r'\Delta B=B_{a+b}^{(\mathrm{meas})}-(B_a+B_b)',
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
        Text('计算公式', style: _hallFormulaTitleStyle(dark)),
        const SizedBox(height: 7),
        for (var index = 0; index < formulas.length; index++)
          _HallFormulaLine(
            number: '${index + 1}.',
            formula: formulas[index],
            dark: dark,
          ),
      ],
    ),
  );
}

class _HallFormulaLine extends StatelessWidget {
  const _HallFormulaLine({
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
            child: Text(number, style: _hallFormulaNumberStyle(dark)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _hallMath(
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

class _HallParameterField {
  const _HallParameterField({
    required this.prefix,
    required this.formula,
    required this.value,
    required this.label,
    required this.onChanged,
  });

  final String prefix;
  final String formula;
  final String value;
  final String label;
  final ValueChanged<String> onChanged;
}

class _HallParameterGrid extends StatelessWidget {
  const _HallParameterGrid({required this.dark, required this.fields});

  final bool dark;
  final List<_HallParameterField> fields;

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
            for (final field in fields)
              SizedBox(
                width: width,
                child: _HallLabeledInput(
                  prefix: field.prefix,
                  formula: field.formula,
                  value: field.value,
                  label: field.label,
                  dark: dark,
                  onChanged: field.onChanged,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _HallLabeledInput extends StatelessWidget {
  const _HallLabeledInput({
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
              Text(prefix, style: _hallFieldLabelStyle(dark)),
              _hallMath(
                formula,
                dark,
                fontSize: 11,
                color: _hallFieldLabelColor(dark),
              ),
            ],
          ),
        ),
        const SizedBox(height: 5),
        _HallTextField(
          value: value,
          label: label,
          dark: dark,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

Widget _hallTable({
  required double width,
  required List<TableColumnWidth> columnWidths,
  required List<Widget> headers,
  required List<List<Widget>> rows,
  required bool dark,
}) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final actualWidth =
          constraints.maxWidth.isFinite && constraints.maxWidth > width
          ? constraints.maxWidth
          : width;
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
          width: actualWidth,
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
              for (var index = 0; index < columnWidths.length; index++)
                index: columnWidths[index],
            },
            border: TableBorder(
              horizontalInside: BorderSide(
                color: dark ? const Color(0xFF28465C) : const Color(0xFFE5EDF2),
              ),
              verticalInside: BorderSide(
                color: dark ? const Color(0xFF28465C) : const Color(0xFFE5EDF2),
              ),
            ),
            children: [
              TableRow(
                decoration: BoxDecoration(
                  color: dark
                      ? const Color(0xFF14263A)
                      : const Color(0xFFEEF6FA),
                ),
                children: headers,
              ),
              for (final row in rows) TableRow(children: row),
            ],
          ),
        ),
      );
    },
  );
}

Widget _hallCell(
  Widget child,
  bool dark, {
  bool header = false,
  bool labelCell = false,
}) {
  return Container(
    constraints: const BoxConstraints(minHeight: 38),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
    alignment: Alignment.center,
    color: header
        ? (dark ? const Color(0xFF14263A) : const Color(0xFFEEF6FA))
        : labelCell
        ? (dark ? const Color(0xFF14263A) : const Color(0xFFF8FBFD))
        : (EcjtuColors.platformSurface(
            dark,
            (dark ? const Color(0xFF101D31) : Colors.white),
          )),
    child: DefaultTextStyle.merge(
      style: header ? _hallHeaderStyle(dark) : _hallCellTextStyle(dark),
      child: child,
    ),
  );
}

Widget _hallPlainHeader(String text, bool dark) {
  return _hallCell(
    Text(text, textAlign: TextAlign.center, style: _hallHeaderStyle(dark)),
    dark,
    header: true,
  );
}

Widget _hallFormulaHeader(String formula, bool dark) {
  return _hallCell(
    _hallMath(
      formula,
      dark,
      fontSize: 12,
      weight: FontWeight.w700,
      color: dark ? const Color(0xFFD6E6F3) : const Color(0xFF5D7487),
    ),
    dark,
    header: true,
  );
}

Widget _hallMixedHeader(String prefix, String formula, bool dark) {
  return _hallCell(
    _hallMixedLabel(
      prefix: prefix,
      formula: formula,
      dark: dark,
      textStyle: _hallHeaderStyle(dark),
    ),
    dark,
    header: true,
  );
}

Widget _hallTextCell(String value, bool dark, {bool label = false}) {
  return _hallCell(
    Text(
      value,
      textAlign: TextAlign.center,
      style: label ? _hallRowLabelStyle(dark) : _hallCellTextStyle(dark),
    ),
    dark,
    labelCell: label,
  );
}

Widget _hallInputCell({
  required String value,
  required String label,
  required bool dark,
  required ValueChanged<String> onChanged,
}) {
  return _hallCell(
    _HallTextField(
      value: value,
      label: label,
      dark: dark,
      tableInput: true,
      onChanged: onChanged,
    ),
    dark,
  );
}

class _HallSolenoidInputTable extends StatelessWidget {
  const _HallSolenoidInputTable({
    required this.state,
    required this.dark,
    required this.onChanged,
  });

  final HallEffectSolenoidInput state;
  final bool dark;
  final void Function(int row, String field, String value) onChanged;

  @override
  Widget build(BuildContext context) {
    final headers = <Widget>[
      _hallPlainHeader('序号', dark),
      _hallMixedHeader('位置 ', r'x\,/\,\mathrm{cm}', dark),
      for (final combination in _hallCombinations)
        _hallPlainHeader(combination.$2, dark),
    ];
    final rows = [
      for (var index = 0; index < state.rows.length; index++)
        [
          _hallTextCell('${index + 1}', dark, label: true),
          _hallInputCell(
            value: state.rows[index].x,
            label: '位置',
            dark: dark,
            onChanged: (value) => onChanged(index, 'x', value),
          ),
          for (final combination in _hallCombinations)
            _hallInputCell(
              value: _readingValue(state.rows[index].reading, combination.$1),
              label: '${combination.$2}霍尔电压',
              dark: dark,
              onChanged: (value) => onChanged(index, combination.$1, value),
            ),
        ],
    ];
    return _hallTable(
      width: 520,
      columnWidths: [
        const FixedColumnWidth(86),
        for (var index = 0; index < _hallCombinations.length + 1; index++)
          const FlexColumnWidth(1),
      ],
      headers: headers,
      rows: rows,
      dark: dark,
    );
  }
}

class _HallCoilInputTable extends StatelessWidget {
  const _HallCoilInputTable({
    required this.coil,
    required this.coilIndex,
    required this.dark,
    required this.onChanged,
  });

  final HallEffectCoilInput coil;
  final int coilIndex;
  final bool dark;
  final void Function(int row, String group, String field, String value)
  onChanged;

  @override
  Widget build(BuildContext context) {
    const groups = [('a', 'A'), ('b', 'B'), ('combined', '合成')];
    final headers = <Widget>[
      _hallMixedHeader('位置 ', r'x\,/\,\mathrm{cm}', dark),
      for (final group in groups)
        for (final combination in _hallCombinations)
          _hallMixedHeader(
            '${group.$2} ${combination.$2} ',
            r'U_H\,/\,\mathrm{mV}',
            dark,
          ),
    ];
    final rows = [
      for (var rowIndex = 0; rowIndex < coil.rows.length; rowIndex++)
        [
          _hallInputCell(
            value: coil.rows[rowIndex].x,
            label: '线圈 ${coilIndex + 1} 位置',
            dark: dark,
            onChanged: (value) => onChanged(rowIndex, '', 'x', value),
          ),
          for (final group in groups)
            for (final combination in _hallCombinations)
              _hallInputCell(
                value: _coilReadingValue(
                  coil.rows[rowIndex],
                  group.$1,
                  combination.$1,
                ),
                label: '线圈 ${coilIndex + 1} ${group.$2} ${combination.$2} 霍尔电压',
                dark: dark,
                onChanged: (value) =>
                    onChanged(rowIndex, group.$1, combination.$1, value),
              ),
        ],
    ];
    return _hallTable(
      width: 1245,
      columnWidths: [
        const FixedColumnWidth(105),
        for (
          var index = 0;
          index < groups.length * _hallCombinations.length;
          index++
        )
          const FixedColumnWidth(95),
      ],
      headers: headers,
      rows: rows,
      dark: dark,
    );
  }
}

class _HallResults extends StatelessWidget {
  const _HallResults({
    required this.calculation,
    required this.radii,
    required this.dark,
    required this.onExportChart,
  });

  final HallEffectCalculation calculation;
  final List<String> radii;
  final bool dark;
  final ValueChanged<HallEffectChartSpec> onExportChart;

  @override
  Widget build(BuildContext context) {
    final specs = hallEffectChartSpecs(calculation, radii);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HallResultCard(
          title: '直螺线管计算结果',
          dark: dark,
          child: _hallTable(
            width: 520,
            columnWidths: const [
              FlexColumnWidth(1),
              FlexColumnWidth(1),
              FlexColumnWidth(1),
            ],
            headers: [
              _hallMixedHeader('位置 ', r'x\,/\,\mathrm{cm}', dark),
              _hallMixedHeader('霍尔电压 ', r'U_H\,/\,\mathrm{mV}', dark),
              _hallFormulaHeader('B', dark),
            ],
            rows: [
              for (final row in calculation.solenoid)
                [
                  _hallTextCell(HallEffectCalculator.format(row.x), dark),
                  _hallTextCell(
                    HallEffectCalculator.format(row.hallVoltage),
                    dark,
                  ),
                  _hallTextCell(HallEffectCalculator.format(row.field), dark),
                ],
            ],
            dark: dark,
          ),
        ),
        const SizedBox(height: 14),
        _HallChartGroup(
          title: '磁感应强度图',
          spec: specs.first,
          dark: dark,
          onExport: onExportChart,
        ),
        for (var index = 0; index < calculation.coils.length; index++) ...[
          const SizedBox(height: 14),
          _HallResultCard(
            title: '载流圆线圈 a = ${index < radii.length ? radii[index] : ''} cm',
            dark: dark,
            child: _hallTable(
              width: 520,
              columnWidths: const [
                FlexColumnWidth(1),
                FlexColumnWidth(1),
                FlexColumnWidth(1),
                FlexColumnWidth(1),
                FlexColumnWidth(1),
                FlexColumnWidth(1),
              ],
              headers: [
                _hallMixedHeader('位置 ', r'x\,/\,\mathrm{cm}', dark),
                _hallMixedHeader('A ', r'B_a', dark),
                _hallMixedHeader('B ', r'B_b', dark),
                _hallMixedHeader('合成实测 ', r'B_{a+b}', dark),
                _hallMixedHeader('两次之和 ', r'B_a+B_b', dark),
                _hallMixedHeader('差值 ', r'\Delta B', dark),
              ],
              rows: [
                for (final row in calculation.coils[index])
                  [
                    _hallTextCell(HallEffectCalculator.format(row.x), dark),
                    _hallTextCell(
                      HallEffectCalculator.format(row.a.field),
                      dark,
                    ),
                    _hallTextCell(
                      HallEffectCalculator.format(row.b.field),
                      dark,
                    ),
                    _hallTextCell(
                      HallEffectCalculator.format(row.combined.field),
                      dark,
                    ),
                    _hallTextCell(HallEffectCalculator.format(row.sum), dark),
                    _hallTextCell(
                      HallEffectCalculator.format(row.difference),
                      dark,
                    ),
                  ],
              ],
              dark: dark,
            ),
          ),
          const SizedBox(height: 14),
          _HallChartGroup(
            title: '磁场关系图',
            spec: specs[index + 1],
            dark: dark,
            onExport: onExportChart,
          ),
        ],
      ],
    );
  }
}

class _HallResultCard extends StatelessWidget {
  const _HallResultCard({
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
          Text(title, style: _hallResultTitleStyle(dark)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _HallChartGroup extends StatelessWidget {
  const _HallChartGroup({
    required this.title,
    required this.spec,
    required this.dark,
    required this.onExport,
  });

  final String title;
  final HallEffectChartSpec spec;
  final bool dark;
  final ValueChanged<HallEffectChartSpec> onExport;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: _hallChartGroupTitleStyle(dark)),
        const SizedBox(height: 10),
        HallEffectChartCard(
          spec: spec,
          dark: dark,
          onExport: () => onExport(spec),
        ),
      ],
    );
  }
}

class _HallTextField extends StatefulWidget {
  const _HallTextField({
    required this.value,
    required this.label,
    required this.dark,
    required this.onChanged,
    this.tableInput = false,
  });

  final String value;
  final String label;
  final bool dark;
  final ValueChanged<String> onChanged;
  final bool tableInput;

  @override
  State<_HallTextField> createState() => _HallTextFieldState();
}

class _HallTextFieldState extends State<_HallTextField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _HallTextField oldWidget) {
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
    final height = widget.tableInput ? 30.0 : 32.0;
    final radius = widget.tableInput ? 5.0 : 6.0;
    final border = widget.dark
        ? const Color(0xFF426B83)
        : const Color(0xFFB9CFDD);
    return Semantics(
      label: widget.label,
      textField: true,
      child: SizedBox(
        width: double.infinity,
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
              horizontal: widget.tableInput ? 5 : 7,
              vertical: widget.tableInput ? 4 : 5,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(radius),
              borderSide: BorderSide(color: border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(radius),
              borderSide: BorderSide(
                color: widget.dark
                    ? const Color(0xFF8FD2FF)
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

Widget _hallMixedLabel({
  required String prefix,
  required String formula,
  required bool dark,
  TextStyle? textStyle,
}) {
  return Wrap(
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: 3,
    children: [
      Text(prefix, style: textStyle ?? _hallCellTextStyle(dark)),
      _hallMath(
        formula,
        dark,
        fontSize: textStyle?.fontSize ?? 12,
        weight: textStyle?.fontWeight ?? FontWeight.w400,
        color: textStyle?.color,
      ),
    ],
  );
}

Widget _hallMath(
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
        height: 1.3,
      ),
      onErrorFallback: (_) => const SizedBox.shrink(),
    ),
  );
}

String _readingValue(HallEffectReading reading, String field) {
  return switch (field) {
    'pp' => reading.pp,
    'nn' => reading.nn,
    'pn' => reading.pn,
    'np' => reading.np,
    _ => '',
  };
}

String _coilReadingValue(HallEffectCoilRow row, String group, String field) {
  final reading = switch (group) {
    'a' => row.a,
    'b' => row.b,
    'combined' => row.combined,
    _ => HallEffectReading.empty(),
  };
  return _readingValue(reading, field);
}

TextStyle _hallSectionTitleStyle(bool dark) => TextStyle(
  color: EcjtuColors.platformText(
    dark,
    (dark ? const Color(0xFFE1EDFF) : const Color(0xFF223549)),
  ),
  fontSize: 13,
  fontWeight: FontWeight.w700,
  height: 1.3,
);

TextStyle _hallFormulaTitleStyle(bool dark) => TextStyle(
  color: EcjtuColors.platformText(
    dark,
    (dark ? const Color(0xFFD6E6F3) : const Color(0xFF275B7A)),
  ),
  fontSize: 12,
  fontWeight: FontWeight.w700,
  height: 1.3,
);

TextStyle _hallFormulaNumberStyle(bool dark) => TextStyle(
  color: EcjtuColors.platformText(
    dark,
    (dark ? const Color(0xFFE1EDFF) : const Color(0xFF223549)),
  ),
  fontSize: 16,
  fontWeight: FontWeight.w500,
  height: 1.2,
);

TextStyle _hallFieldLabelStyle(bool dark) => TextStyle(
  color: EcjtuColors.platformMuted(
    dark,
    (dark ? const Color(0xFF9EACC3) : const Color(0xFF667B8E)),
  ),
  fontSize: 11,
  height: 1.3,
);

Color _hallFieldLabelColor(bool dark) => EcjtuColors.platformMuted(
  dark,
  (dark ? const Color(0xFF9EACC3) : const Color(0xFF667B8E)),
);

TextStyle _hallHeaderStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFFD6E6F3) : const Color(0xFF5D7487),
  fontSize: 12,
  fontWeight: FontWeight.w700,
  height: 1.25,
);

TextStyle _hallRowLabelStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFFB7D9ED) : const Color(0xFF275B7A),
  fontSize: 12,
  fontWeight: FontWeight.w700,
  height: 1.25,
);

TextStyle _hallCellTextStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFFB7D9ED) : const Color(0xFF334F65),
  fontSize: 12,
  height: 1.25,
);

TextStyle _hallResultTitleStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFF9DDCFF) : const Color(0xFF275B7A),
  fontSize: 13,
  fontWeight: FontWeight.w700,
  height: 1.3,
);

TextStyle _hallChartGroupTitleStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFF9DDCFF) : const Color(0xFF275B7A),
  fontSize: 12,
  fontWeight: FontWeight.w700,
  height: 1.3,
);
