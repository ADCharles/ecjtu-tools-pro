// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

part of 'physics_ohmmeter_page.dart';

Widget _ohmmeterFormulaBlock(bool dark) {
  const formulas = [
    r'R_z=R_d+\frac{4}{7}R_s^{\prime}+r',
    r'I=\frac{R_z}{R_z+R_x}I_{\max}',
    r'\eta=\frac{\left|R_{\mathrm{read}}-R_{\mathrm{true}}\right|}{R_{\mathrm{true}}}\times100\%',
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
        Text('计算公式', style: _ohmmeterFormulaTitleStyle(dark)),
        const SizedBox(height: 7),
        for (var index = 0; index < formulas.length; index++)
          _OhmmeterFormulaLine(
            number: '${index + 1}.',
            formula: formulas[index],
            dark: dark,
          ),
      ],
    ),
  );
}

Widget _ohmmeterSection({
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
            Text(title, style: _ohmmeterSectionTitleStyle(dark)),
            const SizedBox(height: 12),
            child,
          ],
        ),
      );
    },
  );
}

class _OhmmeterFormulaLine extends StatelessWidget {
  const _OhmmeterFormulaLine({
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
            child: Text(number, style: _ohmmeterFormulaNumberStyle(dark)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ohmmeterMath(
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

class _OhmmeterParameter {
  const _OhmmeterParameter({
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

class _OhmmeterParameterGrid extends StatelessWidget {
  const _OhmmeterParameterGrid({required this.fields, required this.dark});

  final List<_OhmmeterParameter> fields;
  final bool dark;

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
            for (final field in fields)
              SizedBox(
                width: width,
                child: _OhmmeterParameterField(field: field, dark: dark),
              ),
          ],
        );
      },
    );
  }
}

class _OhmmeterParameterField extends StatelessWidget {
  const _OhmmeterParameterField({required this.field, required this.dark});

  final _OhmmeterParameter field;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final labelStyle = _ohmmeterFieldLabelStyle(dark);
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
                Text(field.prefix, style: labelStyle),
                _ohmmeterMath(
                  field.formula,
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
        _OhmmeterTextField(
          value: field.value,
          label: field.label,
          dark: dark,
          onChanged: field.onChanged,
        ),
      ],
    );
  }
}

class _OhmmeterCalibrationSettings extends StatelessWidget {
  const _OhmmeterCalibrationSettings({
    required this.state,
    required this.dark,
    required this.onChanged,
    required this.onGenerate,
  });

  final OhmmeterState state;
  final bool dark;
  final void Function(String field, String value) onChanged;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _OhmmeterParameterGrid(
          fields: [
            _OhmmeterParameter(
              prefix: '起始电阻',
              formula: r'R_{start}\,/\,\Omega',
              value: state.startResistance,
              label: '起始电阻',
              onChanged: (value) => onChanged('start', value),
            ),
            _OhmmeterParameter(
              prefix: '结束电阻',
              formula: r'R_{end}\,/\,\Omega',
              value: state.endResistance,
              label: '结束电阻',
              onChanged: (value) => onChanged('end', value),
            ),
            _OhmmeterParameter(
              prefix: '递增值',
              formula: r'\Delta R\,/\,\Omega',
              value: state.resistanceStep,
              label: '递增值',
              onChanged: (value) => onChanged('step', value),
            ),
          ],
          dark: dark,
        ),
        const SizedBox(height: 9),
        Wrap(
          spacing: 9,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              '当前 ${state.calibration.length} 组',
              style: _ohmmeterMutedTextStyle(dark),
            ),
            OutlinedButton(
              onPressed: onGenerate,
              child: const Text('生成标定电阻'),
              style: physicsSecondaryButtonStyle(context),
            ),
          ],
        ),
        if (state.calibrationError.isNotEmpty) ...[
          const SizedBox(height: 7),
          Text(state.calibrationError, style: _ohmmeterErrorTextStyle(dark)),
        ],
      ],
    );
  }
}

class _OhmmeterRecordTable extends StatelessWidget {
  const _OhmmeterRecordTable({
    required this.state,
    required this.dark,
    required this.onMeasuredChanged,
  });

  final OhmmeterState state;
  final bool dark;
  final void Function(int index, String value) onMeasuredChanged;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).shortestSide < 620;
    final columnCount = compact ? 3 : 5;
    return _OhmmeterTableScroll(
      width: 0,
      dark: dark,
      child: Table(
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        columnWidths: _ohmmeterRecordColumnWidths(columnCount),
        border: _ohmmeterTableBorder(dark),
        children: [
          TableRow(
            decoration: BoxDecoration(color: _ohmmeterHeaderColor(dark)),
            children: [
              for (var index = 0; index < columnCount; index++) ...[
                _ohmmeterHeaderCell(
                  _ohmmeterHeaderMath('电阻', r'R_x\,/\,\Omega', dark),
                  dark,
                ),
                _ohmmeterHeaderCell(
                  _ohmmeterHeaderMath('电流', r'I\,/\,\mu\mathrm{A}', dark),
                  dark,
                ),
              ],
            ],
          ),
          for (
            var start = 0;
            start < state.calibration.length;
            start += columnCount
          )
            TableRow(
              children: [
                for (var offset = 0; offset < columnCount; offset++)
                  if (start + offset < state.calibration.length) ...[
                    _ohmmeterTableCell(
                      _ohmmeterValue(
                        state.calibration[start + offset].resistance,
                        dark,
                      ),
                      dark,
                    ),
                    _ohmmeterTableCell(
                      _OhmmeterTextField(
                        key: ValueKey<String>(
                          'ohmmeter-measured-${start + offset}',
                        ),
                        value: state.calibration[start + offset].measured,
                        label:
                            '${state.calibration[start + offset].resistance} 欧姆对应电流读数',
                        dark: dark,
                        compact: true,
                        onChanged: (value) =>
                            onMeasuredChanged(start + offset, value),
                      ),
                      dark,
                    ),
                  ] else ...[
                    _ohmmeterTableCell(const SizedBox.shrink(), dark),
                    _ohmmeterTableCell(const SizedBox.shrink(), dark),
                  ],
              ],
            ),
        ],
      ),
    );
  }
}

class _OhmmeterResultContent extends StatelessWidget {
  const _OhmmeterResultContent({
    required this.calculation,
    required this.dark,
    required this.saving,
    required this.onSave,
  });

  final OhmmeterCalculation calculation;
  final bool dark;
  final bool saving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (calculation.zResistance != null) ...[
          _ohmmeterResultCard(
            title: '计算结果',
            dark: dark,
            children: [
              _OhmmeterResultLine(
                prefix: '中值电阻',
                formula: r'R_z=R_d+\frac{4}{7}R_s^{\prime}+r\,/\,\Omega',
                value: OhmmeterCalculator.format(calculation.zResistance),
                dark: dark,
              ),
              if (calculation.relativeError != null)
                _OhmmeterResultLine(
                  prefix: '相对误差',
                  formula:
                      r'\eta=\frac{\left|R_{\mathrm{read}}-R_{\mathrm{true}}\right|}{R_{\mathrm{true}}}\times100\%',
                  value:
                      '${OhmmeterCalculator.format(calculation.relativeError, digits: 3)}%',
                  dark: dark,
                ),
            ],
          ),
          const SizedBox(height: 10),
          _ohmmeterResultCard(
            title: '理论刻度',
            dark: dark,
            children: [
              _OhmmeterTheoryTable(calculation: calculation, dark: dark),
            ],
          ),
        ],
        const SizedBox(height: 14),
        OutlinedButton(
          onPressed: saving ? null : onSave,
          child: Text(saving ? '正在保存' : '保存数据'),
          style: physicsSecondaryButtonStyle(context),
        ),
      ],
    );
  }
}

class _OhmmeterTheoryTable extends StatelessWidget {
  const _OhmmeterTheoryTable({required this.calculation, required this.dark});

  final OhmmeterCalculation calculation;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).shortestSide < 620;
    final columnCount = compact ? 3 : 5;
    return _OhmmeterTableScroll(
      width: 0,
      dark: dark,
      child: Table(
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        columnWidths: _ohmmeterRecordColumnWidths(columnCount),
        border: _ohmmeterTableBorder(dark),
        children: [
          TableRow(
            decoration: BoxDecoration(color: _ohmmeterHeaderColor(dark)),
            children: [
              for (var index = 0; index < columnCount; index++) ...[
                _ohmmeterHeaderCell(
                  _ohmmeterHeaderMath('电阻', r'R_x\,/\,\Omega', dark),
                  dark,
                ),
                _ohmmeterHeaderCell(
                  _ohmmeterHeaderMath('理论电流', r'I\,/\,\mu\mathrm{A}', dark),
                  dark,
                ),
              ],
            ],
          ),
          for (
            var start = 0;
            start < calculation.rows.length;
            start += columnCount
          )
            TableRow(
              children: [
                for (var offset = 0; offset < columnCount; offset++)
                  if (start + offset < calculation.rows.length) ...[
                    _ohmmeterTableCell(
                      _ohmmeterValue(
                        OhmmeterCalculator.format(
                          calculation.rows[start + offset].resistance,
                        ),
                        dark,
                      ),
                      dark,
                    ),
                    _ohmmeterTableCell(
                      _ohmmeterValue(
                        OhmmeterCalculator.format(
                          calculation.rows[start + offset].theoretical,
                          digits: 3,
                        ),
                        dark,
                      ),
                      dark,
                    ),
                  ] else ...[
                    _ohmmeterTableCell(const SizedBox.shrink(), dark),
                    _ohmmeterTableCell(const SizedBox.shrink(), dark),
                  ],
              ],
            ),
        ],
      ),
    );
  }
}

class _OhmmeterResultLine extends StatelessWidget {
  const _OhmmeterResultLine({
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
            Text(prefix, style: _ohmmeterResultLabelStyle(dark)),
            _ohmmeterMath(formula, dark, fontSize: 12),
          ],
        );
        final valueWidget = Text(
          value,
          textAlign: narrow ? TextAlign.left : TextAlign.right,
          style: _ohmmeterResultValueStyle(dark),
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

class _OhmmeterTextField extends StatefulWidget {
  const _OhmmeterTextField({
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
  State<_OhmmeterTextField> createState() => _OhmmeterTextFieldState();
}

class _OhmmeterTextFieldState extends State<_OhmmeterTextField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _OhmmeterTextField oldWidget) {
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

class _OhmmeterTableScroll extends StatelessWidget {
  const _OhmmeterTableScroll({
    required this.width,
    required this.dark,
    required this.child,
  });

  final double width;
  final bool dark;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tableWidth = constraints.maxWidth.isFinite
            ? (constraints.maxWidth > width ? constraints.maxWidth : width)
            : width;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Container(
            width: tableWidth,
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
      },
    );
  }
}

Map<int, TableColumnWidth> _ohmmeterRecordColumnWidths(int columnCount) {
  final resistanceFraction = columnCount == 3 ? 0.13 : 0.08;
  final currentFraction = (1 - columnCount * resistanceFraction) / columnCount;
  final widths = <int, TableColumnWidth>{};
  for (var index = 0; index < columnCount; index++) {
    widths[index * 2] = FractionColumnWidth(resistanceFraction);
    widths[index * 2 + 1] = FractionColumnWidth(currentFraction);
  }
  return widths;
}

Widget _ohmmeterHeaderMath(String text, String formula, bool dark) {
  return Wrap(
    alignment: WrapAlignment.center,
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: 3,
    runSpacing: 2,
    children: [
      Text(
        text,
        textAlign: TextAlign.center,
        style: _ohmmeterHeaderTextStyle(dark),
      ),
      _ohmmeterMath(formula, dark, fontSize: 11, weight: FontWeight.w700),
    ],
  );
}

Widget _ohmmeterTableCell(Widget child, bool dark, {bool labelCell = false}) {
  return Container(
    constraints: const BoxConstraints(minHeight: 38),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    alignment: labelCell ? Alignment.centerLeft : Alignment.center,
    color: labelCell
        ? (dark ? const Color(0xFF14263A) : const Color(0xFFF8FBFD))
        : (EcjtuColors.platformSurface(
            dark,
            (dark ? const Color(0xFF101D31) : Colors.white),
          )),
    child: DefaultTextStyle.merge(
      style: _ohmmeterCellTextStyle(dark),
      child: child,
    ),
  );
}

Widget _ohmmeterHeaderCell(Widget child, bool dark) {
  return Container(
    constraints: const BoxConstraints(minHeight: 42),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    alignment: Alignment.center,
    color: _ohmmeterHeaderColor(dark),
    child: DefaultTextStyle.merge(
      style: _ohmmeterHeaderTextStyle(dark),
      child: child,
    ),
  );
}

Widget _ohmmeterValue(String value, bool dark) => Text(
  value,
  textAlign: TextAlign.center,
  style: _ohmmeterCellTextStyle(dark),
);

Widget _ohmmeterMath(
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

Widget _ohmmeterResultCard({
  required String title,
  required bool dark,
  required List<Widget> children,
}) {
  final content = <Widget>[
    for (var index = 0; index < children.length; index++) ...[
      if (index > 0) const SizedBox(height: 10),
      children[index],
    ],
  ];
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
        Text(title, style: _ohmmeterResultTitleStyle(dark)),
        const SizedBox(height: 10),
        ...content,
      ],
    ),
  );
}

TableBorder _ohmmeterTableBorder(bool dark) {
  return TableBorder(
    horizontalInside: BorderSide(
      color: dark ? const Color(0xFF28465C) : const Color(0xFFE5EDF2),
    ),
    verticalInside: BorderSide(
      color: dark ? const Color(0xFF28465C) : const Color(0xFFE5EDF2),
    ),
  );
}

Color _ohmmeterHeaderColor(bool dark) =>
    dark ? const Color(0xFF14263A) : const Color(0xFFEEF6FA);

TextStyle _ohmmeterSectionTitleStyle(bool dark) => TextStyle(
  color: EcjtuColors.platformText(
    dark,
    (dark ? const Color(0xFFE1EDFF) : const Color(0xFF223549)),
  ),
  fontSize: 13,
  fontWeight: FontWeight.w700,
  height: 1.3,
);

TextStyle _ohmmeterResultTitleStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFF9DDCFF) : const Color(0xFF275B7A),
  fontSize: 13,
  fontWeight: FontWeight.w700,
  height: 1.3,
);

TextStyle _ohmmeterFormulaTitleStyle(bool dark) => TextStyle(
  color: EcjtuColors.platformText(
    dark,
    (dark ? const Color(0xFFD6E6F3) : const Color(0xFF275B7A)),
  ),
  fontSize: 12,
  fontWeight: FontWeight.w700,
  height: 1.3,
);

TextStyle _ohmmeterFormulaNumberStyle(bool dark) => TextStyle(
  color: EcjtuColors.platformText(
    dark,
    (dark ? const Color(0xFFE1EDFF) : const Color(0xFF223549)),
  ),
  fontSize: 16,
  fontWeight: FontWeight.w500,
  height: 1.2,
);

TextStyle _ohmmeterFieldLabelStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFFB9E2F7) : const Color(0xFF667B8E),
  fontSize: 11,
  fontWeight: FontWeight.w600,
  height: 1.3,
);

TextStyle _ohmmeterHeaderTextStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFFD6E6F3) : const Color(0xFF5D7487),
  fontSize: 11,
  fontWeight: FontWeight.w700,
  height: 1.25,
);

TextStyle _ohmmeterCellTextStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFFB7D9ED) : const Color(0xFF334F65),
  fontSize: 11,
  height: 1.25,
);

TextStyle _ohmmeterMutedTextStyle(bool dark) => TextStyle(
  color: EcjtuColors.platformMuted(
    dark,
    (dark ? const Color(0xFF9EACC3) : const Color(0xFF667B8E)),
  ),
  fontSize: 11,
  height: 1.45,
);

TextStyle _ohmmeterErrorTextStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFFFFB7B7) : const Color(0xFF9C3D3D),
  fontSize: 11,
  height: 1.45,
);

TextStyle _ohmmeterResultLabelStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFF9EACC3) : const Color(0xFF527087),
  fontSize: 12,
  fontWeight: FontWeight.w600,
  height: 1.3,
);

TextStyle _ohmmeterResultValueStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFF8FD2FF) : const Color(0xFF275B7A),
  fontSize: 12,
  fontWeight: FontWeight.w700,
  height: 1.3,
);
