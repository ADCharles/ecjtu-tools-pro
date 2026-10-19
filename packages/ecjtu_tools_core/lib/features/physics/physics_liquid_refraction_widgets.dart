// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

part of 'physics_liquid_refraction_page.dart';

Widget _liquidFormulaBlock(bool dark) {
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
        Text('计算公式', style: _liquidFormulaTitleStyle(dark)),
        const SizedBox(height: 7),
        _LiquidFormulaLine(
          number: '1.',
          formula:
              r'\delta=\frac{\left|\theta_1\prime-\theta_0\prime\right|+\left|\theta_1-\theta_0\right|}{2}',
          dark: dark,
        ),
        _LiquidFormulaLine(
          number: '2.',
          formula:
              r'n_{\mathrm{prism}}=2\sin\left(\frac{60^\circ+\delta}{2}\right)',
          dark: dark,
        ),
        _LiquidFormulaLine(
          number: '3.',
          formula:
              r'\left|\phi_i\right|=\frac{\left|\theta_{2,i}\prime-\theta_{1,i}\prime\right|+\left|\theta_{2,i}-\theta_{1,i}\right|}{2}',
          dark: dark,
        ),
        _LiquidFormulaLine(
          number: '4.',
          formula:
              r'n_{\mathrm{liquid},i}=\sin60^\circ\sqrt{n_{\mathrm{prism}}^2-\sin^2\left|\phi_i\right|}-\cos60^\circ\sin\left|\phi_i\right|',
          dark: dark,
        ),
      ],
    ),
  );
}

Widget _liquidSection({
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
        Text(title, style: _liquidSectionTitleStyle(dark)),
        const SizedBox(height: 12),
        child,
      ],
    ),
  );
}

class _LiquidFormulaLine extends StatelessWidget {
  const _LiquidFormulaLine({
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
            child: Text(number, style: _liquidFormulaNumberStyle(dark)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _liquidMath(
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

class _LiquidCalibrationInput extends StatelessWidget {
  const _LiquidCalibrationInput({
    required this.calibration,
    required this.dark,
    required this.onChanged,
  });

  final LiquidRefractionCalibration calibration;
  final bool dark;
  final void Function(String field, String part, String value) onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = _liquidGridColumns(constraints.maxWidth);
        final gap = 10.0;
        final width = _liquidGridWidth(constraints.maxWidth, columns, gap);
        final fields = [
          ('最小偏向位置', r'\theta_1', 'minimum1', calibration.minimum1),
          ('最小偏向位置', r"\theta_1'", 'minimum2', calibration.minimum2),
          ('基准位置', r'\theta_0', 'reference1', calibration.reference1),
          ('基准位置', r"\theta_0'", 'reference2', calibration.reference2),
        ];
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final field in fields)
              SizedBox(
                width: width,
                child: _LiquidAngleInput(
                  key: ValueKey<String>('liquid-calibration-${field.$3}'),
                  label: field.$1,
                  symbol: field.$2,
                  value: field.$4,
                  dark: dark,
                  onChanged: (part, value) => onChanged(field.$3, part, value),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _LiquidTrialsInput extends StatelessWidget {
  const _LiquidTrialsInput({
    required this.trials,
    required this.dark,
    required this.onChanged,
  });

  final List<LiquidRefractionTrialInput> trials;
  final bool dark;
  final void Function(int index, String field, String part, String value)
  onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < trials.length; index++) ...[
          if (index > 0) const SizedBox(height: 10),
          _LiquidTrialInput(
            index: index,
            trial: trials[index],
            dark: dark,
            onChanged: onChanged,
          ),
        ],
      ],
    );
  }
}

class _LiquidTrialInput extends StatelessWidget {
  const _LiquidTrialInput({
    required this.index,
    required this.trial,
    required this.dark,
    required this.onChanged,
  });

  final int index;
  final LiquidRefractionTrialInput trial;
  final bool dark;
  final void Function(int index, String field, String part, String value)
  onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
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
          Text('第 ${index + 1} 组', style: _liquidTrialTitleStyle(dark)),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = _liquidGridColumns(constraints.maxWidth);
              final gap = 10.0;
              final width = _liquidGridWidth(
                constraints.maxWidth,
                columns,
                gap,
              );
              final fields = [
                ('极限光位置', r'\theta_1', 'limit1', trial.limit1),
                ('极限光位置', r"\theta_1'", 'limit2', trial.limit2),
                ('法线位置', r'\theta_2', 'normal1', trial.normal1),
                ('法线位置', r"\theta_2'", 'normal2', trial.normal2),
              ];
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final field in fields)
                    SizedBox(
                      width: width,
                      child: _LiquidAngleInput(
                        key: ValueKey<String>(
                          'liquid-trial-$index-${field.$3}',
                        ),
                        label: field.$1,
                        symbol: field.$2,
                        value: field.$4,
                        dark: dark,
                        onChanged: (part, value) =>
                            onChanged(index, field.$3, part, value),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _LiquidAngleInput extends StatelessWidget {
  const _LiquidAngleInput({
    super.key,
    required this.label,
    required this.symbol,
    required this.value,
    required this.dark,
    required this.onChanged,
  });

  final String label;
  final String symbol;
  final LiquidRefractionAngleInput value;
  final bool dark;
  final void Function(String part, String value) onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          children: [
            Text(label, style: _liquidFieldLabelStyle(dark)),
            _liquidMath(
              symbol,
              dark,
              fontSize: 12,
              color: EcjtuColors.platformMuted(
                dark,
                (dark ? const Color(0xFF9EACC3) : const Color(0xFF667B8E)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            Expanded(
              child: _LiquidTextField(
                key: ValueKey<String>('${key ?? label}-degree'),
                value: value.degree,
                label: '$label 度',
                placeholder: '度',
                dark: dark,
                onChanged: (next) => onChanged('degree', next),
              ),
            ),
            const SizedBox(width: 5),
            Text('°', style: _liquidAngleUnitStyle(dark)),
            const SizedBox(width: 5),
            Expanded(
              child: _LiquidTextField(
                key: ValueKey<String>('${key ?? label}-minute'),
                value: value.minute,
                label: '$label 分',
                placeholder: '分',
                dark: dark,
                onChanged: (next) => onChanged('minute', next),
              ),
            ),
            const SizedBox(width: 5),
            Text('′', style: _liquidAngleUnitStyle(dark)),
          ],
        ),
      ],
    );
  }
}

class _LiquidOutputContent extends StatelessWidget {
  const _LiquidOutputContent({
    required this.calculation,
    required this.dark,
    required this.saving,
    required this.onSave,
  });

  final LiquidRefractionCalculation calculation;
  final bool dark;
  final bool saving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final hasCalibration =
        calculation.calibrationDegrees != null &&
        calculation.minimumDeviation != null &&
        calculation.prismIndex != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasCalibration) ...[
          _liquidSummaryBox(
            dark: dark,
            lines: [
              _LiquidSummaryLine(
                label: _liquidLabel('最小偏向角', r'\delta', '（度）', dark),
                value: LiquidRefractionCalculator.format(
                  calculation.minimumDeviation,
                ),
              ),
              _LiquidSummaryLine(
                label: _liquidLabel('棱镜折射率', r'n_{\mathrm{prism}}', '', dark),
                value: LiquidRefractionCalculator.format(
                  calculation.prismIndex,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _LiquidResultTable(
            dark: dark,
            minWidth: 560,
            headers: [
              const Text('转换结果'),
              _liquidMath(
                r'\theta_1',
                dark,
                fontSize: 12,
                color: _liquidHeaderTextColor(dark),
              ),
              _liquidMath(
                r"\theta_1'",
                dark,
                fontSize: 12,
                color: _liquidHeaderTextColor(dark),
              ),
              _liquidMath(
                r'\theta_0',
                dark,
                fontSize: 12,
                color: _liquidHeaderTextColor(dark),
              ),
              _liquidMath(
                r"\theta_0'",
                dark,
                fontSize: 12,
                color: _liquidHeaderTextColor(dark),
              ),
            ],
            rows: [
              _LiquidTableRow(
                label: const Text('转换为（度）'),
                values: calculation.calibrationDegrees!
                    .map((value) => _liquidValue(value, dark))
                    .toList(growable: false),
              ),
            ],
          ),
        ],
        if (calculation.rows.isNotEmpty) ...[
          const SizedBox(height: 12),
          _LiquidResultTable(
            dark: dark,
            minWidth: 720,
            headers: [
              const Text('测量次数'),
              const Text('第 1 组'),
              const Text('第 2 组'),
              const Text('第 3 组'),
            ],
            rows: [
              _LiquidTableRow(
                label: _liquidLabel('极限光位置', r'\theta_1', '（度）', dark),
                values: calculation.rows
                    .map((row) => row.limit1)
                    .map((value) => _liquidValue(value, dark))
                    .toList(growable: false),
              ),
              _LiquidTableRow(
                label: _liquidLabel('极限光位置', r"\theta_1'", '（度）', dark),
                values: calculation.rows
                    .map((row) => row.limit2)
                    .map((value) => _liquidValue(value, dark))
                    .toList(growable: false),
              ),
              _LiquidTableRow(
                label: _liquidLabel('法线位置', r'\theta_2', '（度）', dark),
                values: calculation.rows
                    .map((row) => row.normal1)
                    .map((value) => _liquidValue(value, dark))
                    .toList(growable: false),
              ),
              _LiquidTableRow(
                label: _liquidLabel('法线位置', r"\theta_2'", '（度）', dark),
                values: calculation.rows
                    .map((row) => row.normal2)
                    .map((value) => _liquidValue(value, dark))
                    .toList(growable: false),
              ),
              _LiquidTableRow(
                label: _liquidLabel(
                  '极限角绝对值',
                  r'\left|\phi_i\right|',
                  '（度）',
                  dark,
                ),
                values: calculation.rows
                    .map((row) => row.limitAngle)
                    .map((value) => _liquidValue(value, dark))
                    .toList(growable: false),
              ),
              _LiquidTableRow(
                label: _liquidLabel(
                  '液体折射率',
                  r'n_{\mathrm{liquid},i}',
                  '',
                  dark,
                ),
                values: calculation.rows
                    .map((row) => row.liquidIndex)
                    .map((value) => _liquidValue(value, dark))
                    .toList(growable: false),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _liquidSummaryBox(
            dark: dark,
            lines: [
              _LiquidSummaryLine(
                label: _liquidLabel('液体折射率', r'\overline{n}', '的平均值', dark),
                value: LiquidRefractionCalculator.format(calculation.average),
              ),
              _LiquidSummaryLine(
                label: _liquidLabel('液体折射率', r'\sigma_n', '的标准差', dark),
                value: LiquidRefractionCalculator.format(
                  calculation.standardDeviation,
                ),
              ),
              _LiquidSummaryLine(
                label: const Text('计算值 ± 误差'),
                value:
                    '${LiquidRefractionCalculator.format(calculation.average)} ± ${LiquidRefractionCalculator.format(calculation.standardDeviation)}',
                divided: true,
              ),
            ],
          ),
        ],
        if (calculation.error.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              calculation.hasAnyInput
                  ? '输入有误：${calculation.error}'
                  : '填写完整数据后显示结果',
              style: _liquidEmptyTextStyle(dark),
            ),
          ),
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

class _LiquidResultTable extends StatelessWidget {
  const _LiquidResultTable({
    required this.dark,
    required this.minWidth,
    required this.headers,
    required this.rows,
  });

  final bool dark;
  final double minWidth;
  final List<Widget> headers;
  final List<_LiquidTableRow> rows;

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
            0: const FixedColumnWidth(126),
            for (var index = 1; index < headers.length; index++)
              index: const FlexColumnWidth(1),
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
              decoration: BoxDecoration(color: _liquidHeaderColor(dark)),
              children: [
                for (final header in headers)
                  _liquidTableCell(header, dark, header: true),
              ],
            ),
            for (final row in rows)
              TableRow(
                children: [
                  _liquidTableCell(row.label, dark, labelCell: true),
                  for (final value in row.values) _liquidTableCell(value, dark),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _LiquidTableRow {
  const _LiquidTableRow({required this.label, required this.values});

  final Widget label;
  final List<Widget> values;
}

class _LiquidSummaryLine {
  const _LiquidSummaryLine({
    required this.label,
    required this.value,
    this.divided = false,
  });

  final Widget label;
  final String value;
  final bool divided;
}

Widget _liquidSummaryBox({
  required bool dark,
  required List<_LiquidSummaryLine> lines,
}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      color: dark ? const Color(0xFF14263A) : const Color(0xFFEEF5FA),
      border: const Border(
        left: BorderSide(color: Color(0xFF6DA8D0), width: 3),
      ),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < lines.length; index++) ...[
          if (index > 0 && lines[index].divided)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Divider(
                height: 1,
                color: dark ? const Color(0xFF28465C) : const Color(0xFFCBDDE8),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: lines[index].label,
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    lines[index].value,
                    textAlign: TextAlign.right,
                    style: _liquidSummaryValueStyle(dark),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    ),
  );
}

Widget _liquidLabel(String before, String formula, String after, bool dark) {
  return Wrap(
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: 3,
    children: [
      Text(before, style: _liquidSummaryLabelStyle(dark)),
      _liquidMath(
        formula,
        dark,
        fontSize: 12,
        color: dark ? const Color(0xFFB7D9ED) : const Color(0xFF527087),
      ),
      if (after.isNotEmpty) Text(after, style: _liquidSummaryLabelStyle(dark)),
    ],
  );
}

Widget _liquidValue(double value, bool dark) {
  return Text(
    LiquidRefractionCalculator.format(value),
    textAlign: TextAlign.center,
    style: _liquidCellTextStyle(dark),
  );
}

Widget _liquidTableCell(
  Widget child,
  bool dark, {
  bool header = false,
  bool labelCell = false,
}) {
  return Container(
    constraints: const BoxConstraints(minHeight: 38),
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
    alignment: labelCell ? Alignment.centerLeft : Alignment.center,
    color: header
        ? _liquidHeaderColor(dark)
        : labelCell
        ? (dark ? const Color(0xFF14263A) : const Color(0xFFF4F9FC))
        : (EcjtuColors.platformSurface(
            dark,
            (dark ? const Color(0xFF101D31) : Colors.white),
          )),
    child: DefaultTextStyle.merge(
      style: header ? _liquidHeaderTextStyle(dark) : _liquidCellTextStyle(dark),
      child: child,
    ),
  );
}

class _LiquidTextField extends StatefulWidget {
  const _LiquidTextField({
    super.key,
    required this.value,
    required this.label,
    required this.placeholder,
    required this.dark,
    required this.onChanged,
  });

  final String value;
  final String label;
  final String placeholder;
  final bool dark;
  final ValueChanged<String> onChanged;

  @override
  State<_LiquidTextField> createState() => _LiquidTextFieldState();
}

class _LiquidTextFieldState extends State<_LiquidTextField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _LiquidTextField oldWidget) {
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
        height: 32,
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
            hintText: widget.placeholder,
            hintStyle: TextStyle(
              color: widget.dark
                  ? const Color(0xFF7891A7)
                  : const Color(0xFF9AAEBC),
              fontSize: 11,
            ),
            filled: true,
            fillColor: widget.dark ? const Color(0xFF14263A) : Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 7,
              vertical: 5,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(
                color: widget.dark
                    ? const Color(0xFF426B83)
                    : const Color(0xFFB9CFDD),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
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

Widget _liquidMath(
  String formula,
  bool dark, {
  double fontSize = 14,
  FontWeight weight = FontWeight.w400,
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

int _liquidGridColumns(double width) {
  if (!width.isFinite || width > 560) return 4;
  if (width >= 380) return 2;
  return 1;
}

double _liquidGridWidth(double width, int columns, double gap) {
  if (!width.isFinite) return 220;
  return (width - gap * (columns - 1)) / columns;
}

Color _liquidHeaderColor(bool dark) =>
    dark ? const Color(0xFF14263A) : const Color(0xFFEEF6FA);

TextStyle _liquidSectionTitleStyle(bool dark) => TextStyle(
  color: EcjtuColors.platformText(
    dark,
    (dark ? const Color(0xFFE1EDFF) : const Color(0xFF223549)),
  ),
  fontSize: 13,
  fontWeight: FontWeight.w700,
  height: 1.3,
);

TextStyle _liquidFormulaTitleStyle(bool dark) => TextStyle(
  color: EcjtuColors.platformText(
    dark,
    (dark ? const Color(0xFFD6E6F3) : const Color(0xFF275B7A)),
  ),
  fontSize: 12,
  fontWeight: FontWeight.w700,
  height: 1.3,
);

TextStyle _liquidFormulaNumberStyle(bool dark) => TextStyle(
  color: EcjtuColors.platformText(
    dark,
    (dark ? const Color(0xFFE1EDFF) : const Color(0xFF223549)),
  ),
  fontSize: 16,
  fontWeight: FontWeight.w500,
  height: 1.2,
);

TextStyle _liquidTrialTitleStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFF9DDCFF) : const Color(0xFF275B7A),
  fontSize: 12,
  fontWeight: FontWeight.w700,
  height: 1.3,
);

TextStyle _liquidFieldLabelStyle(bool dark) => TextStyle(
  color: EcjtuColors.platformMuted(
    dark,
    (dark ? const Color(0xFF9EACC3) : const Color(0xFF667B8E)),
  ),
  fontSize: 11,
  fontWeight: FontWeight.w400,
  height: 1.3,
);

TextStyle _liquidAngleUnitStyle(bool dark) => TextStyle(
  color: EcjtuColors.platformMuted(
    dark,
    (dark ? const Color(0xFF9EACC3) : const Color(0xFF667B8E)),
  ),
  fontSize: 11,
  fontWeight: FontWeight.w600,
  height: 1,
);

TextStyle _liquidCellTextStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFFB7D9ED) : const Color(0xFF334F65),
  fontSize: 12,
  height: 1.25,
);

TextStyle _liquidHeaderTextStyle(bool dark) => TextStyle(
  color: _liquidHeaderTextColor(dark),
  fontSize: 12,
  fontWeight: FontWeight.w700,
  height: 1.2,
);

Color _liquidHeaderTextColor(bool dark) =>
    dark ? const Color(0xFFD6E6F3) : const Color(0xFF5D7487);

TextStyle _liquidEmptyTextStyle(bool dark) => TextStyle(
  color: EcjtuColors.platformMuted(
    dark,
    (dark ? const Color(0xFF9EACC3) : const Color(0xFF667B8E)),
  ),
  fontSize: 11,
  height: 1.5,
);

TextStyle _liquidSummaryLabelStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFF9EACC3) : const Color(0xFF527087),
  fontSize: 12,
  fontWeight: FontWeight.w600,
  height: 1.3,
);

TextStyle _liquidSummaryValueStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFF8FD2FF) : const Color(0xFF176496),
  fontSize: 13,
  fontWeight: FontWeight.w800,
  height: 1.25,
);
