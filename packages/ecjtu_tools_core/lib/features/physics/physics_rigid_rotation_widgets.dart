// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

part of 'physics_rigid_rotation_page.dart';

Widget _rigidRotationFormulaBlock(bool dark) {
  const formulas = [
    r'\bar{t}=\frac{1}{n}\sum_{i=1}^{n}t_i',
    r'I_1=\frac{g k_1 d_5^2}{8h}',
    r'I_2=\frac{m g k_2^2}{2h}',
    r'I=\frac{I_1+I_2}{2}',
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
        Text('计算公式', style: _rigidRotationFormulaTitleStyle(dark)),
        const SizedBox(height: 7),
        for (var index = 0; index < formulas.length; index++)
          _RigidRotationFormulaLine(
            number: '${index + 1}.',
            formula: formulas[index],
            dark: dark,
          ),
      ],
    ),
  );
}

Widget _rigidRotationSection({
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
            Text(title, style: _rigidRotationSectionTitleStyle(dark)),
            const SizedBox(height: 12),
            child,
          ],
        ),
      );
    },
  );
}

class _RigidRotationFormulaLine extends StatelessWidget {
  const _RigidRotationFormulaLine({
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
            child: Text(number, style: _rigidRotationFormulaNumberStyle(dark)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _rigidRotationMath(
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

class _RigidRotationBasicInput extends StatelessWidget {
  const _RigidRotationBasicInput({
    required this.state,
    required this.dark,
    required this.onBasicChanged,
    required this.onDiameterChanged,
  });

  final RigidRotationState state;
  final bool dark;
  final void Function(String field, String value) onBasicChanged;
  final ValueChanged2<int, String> onDiameterChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RigidRotationParameterGrid(
          children: [
            _RigidRotationParameterField(
              prefix: '下落高度',
              formula: r'h\,/\,\mathrm{m}',
              value: state.height,
              label: '下落高度',
              dark: dark,
              onChanged: (value) => onBasicChanged('height', value),
            ),
            _RigidRotationParameterField(
              prefix: '重力加速度',
              formula: r'g\,/\,\mathrm{m\,s^{-2}}',
              value: state.gravity,
              label: '重力加速度',
              dark: dark,
              onChanged: (value) => onBasicChanged('gravity', value),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _RigidRotationTableScroll(
          width: 520,
          dark: dark,
          child: Table(
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            columnWidths: const {
              0: FixedColumnWidth(86),
              1: FlexColumnWidth(1),
            },
            border: _rigidRotationTableBorder(dark),
            children: [
              TableRow(
                decoration: BoxDecoration(
                  color: _rigidRotationHeaderColor(dark),
                ),
                children: [
                  _rigidRotationHeaderCell(const Text('次数'), dark),
                  _rigidRotationHeaderCell(
                    _rigidRotationHeaderMath('塔轮直径', r'd\,/\,\mathrm{m}', dark),
                    dark,
                  ),
                ],
              ),
              for (var index = 0; index < state.diameters.length; index++)
                TableRow(
                  children: [
                    _rigidRotationTableCell(
                      Text(
                        '${index + 1}',
                        style: _rigidRotationCellTextStyle(dark),
                      ),
                      dark,
                      labelCell: true,
                    ),
                    _rigidRotationTableCell(
                      _RigidRotationTextField(
                        key: ValueKey<String>('rigid-diameter-$index'),
                        value: state.diameters[index],
                        label: '塔轮直径第 ${index + 1} 次',
                        dark: dark,
                        compact: true,
                        onChanged: (value) => onDiameterChanged(index, value),
                      ),
                      dark,
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

class _RigidRotationMassInput extends StatelessWidget {
  const _RigidRotationMassInput({
    required this.state,
    required this.dark,
    required this.onChanged,
  });

  final RigidRotationState state;
  final bool dark;
  final void Function(int runIndex, String field, int timeIndex, String value)
  onChanged;

  @override
  Widget build(BuildContext context) {
    return _RigidRotationTableScroll(
      width: 520,
      dark: dark,
      child: Table(
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        columnWidths: const {
          0: FixedColumnWidth(86),
          1: FlexColumnWidth(1),
          2: FlexColumnWidth(1),
          3: FlexColumnWidth(1),
        },
        border: _rigidRotationTableBorder(dark),
        children: [
          TableRow(
            decoration: BoxDecoration(color: _rigidRotationHeaderColor(dark)),
            children: [
              _rigidRotationHeaderCell(const Text('组数'), dark),
              _rigidRotationHeaderCell(
                _rigidRotationHeaderMath(
                  '总质量',
                  r'\sum M_i\,/\,\mathrm{kg}',
                  dark,
                ),
                dark,
              ),
              for (var index = 0; index < 3; index++)
                _rigidRotationHeaderCell(
                  _rigidRotationHeaderMath(
                    '时间 ${index + 1}',
                    't_${index + 1}\\,/\\,\\mathrm{s}',
                    dark,
                  ),
                  dark,
                ),
            ],
          ),
          for (var runIndex = 0; runIndex < state.massRuns.length; runIndex++)
            TableRow(
              children: [
                _rigidRotationTableCell(
                  Text(
                    '${runIndex + 1}',
                    style: _rigidRotationCellTextStyle(dark),
                  ),
                  dark,
                  labelCell: true,
                ),
                _rigidRotationTableCell(
                  _RigidRotationTextField(
                    key: ValueKey<String>('rigid-mass-$runIndex'),
                    value: state.massRuns[runIndex].mass,
                    label: '第 ${runIndex + 1} 组总质量',
                    dark: dark,
                    compact: true,
                    onChanged: (value) =>
                        onChanged(runIndex, 'mass', -1, value),
                  ),
                  dark,
                ),
                for (var timeIndex = 0; timeIndex < 3; timeIndex++)
                  _rigidRotationTableCell(
                    _RigidRotationTextField(
                      key: ValueKey<String>(
                        'rigid-mass-time-$runIndex-$timeIndex',
                      ),
                      value: state.massRuns[runIndex].times[timeIndex],
                      label: '第 ${runIndex + 1} 组时间${timeIndex + 1}',
                      dark: dark,
                      compact: true,
                      onChanged: (value) =>
                          onChanged(runIndex, 'time', timeIndex, value),
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

class _RigidRotationSecondInput extends StatelessWidget {
  const _RigidRotationSecondInput({
    required this.state,
    required this.calculation,
    required this.dark,
    required this.onMassChanged,
    required this.onTimeChanged,
  });

  final RigidRotationState state;
  final RigidRotationCalculation calculation;
  final bool dark;
  final ValueChanged<String> onMassChanged;
  final ValueChanged3<int, int, String> onTimeChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RigidRotationParameterGrid(
          children: [
            _RigidRotationParameterField(
              prefix: '总质量',
              formula: r'm\,/\,\mathrm{kg}',
              value: state.secondMass,
              label: '半径与时间关系总质量',
              dark: dark,
              onChanged: onMassChanged,
            ),
          ],
        ),
        const SizedBox(height: 10),
        _RigidRotationTableScroll(
          width: 520,
          dark: dark,
          child: Table(
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            columnWidths: const {
              0: FixedColumnWidth(86),
              1: FlexColumnWidth(1),
              2: FlexColumnWidth(1),
              3: FlexColumnWidth(1),
              4: FlexColumnWidth(1),
            },
            border: _rigidRotationTableBorder(dark),
            children: [
              TableRow(
                decoration: BoxDecoration(
                  color: _rigidRotationHeaderColor(dark),
                ),
                children: [
                  _rigidRotationHeaderCell(const Text('组数'), dark),
                  _rigidRotationHeaderCell(
                    _rigidRotationHeaderMath(
                      '半径',
                      r'r=d/2\,/\,\mathrm{m}',
                      dark,
                    ),
                    dark,
                  ),
                  for (var index = 0; index < 3; index++)
                    _rigidRotationHeaderCell(
                      _rigidRotationHeaderMath(
                        '时间 ${index + 1}',
                        't_${index + 1}\\,/\\,\\mathrm{s}',
                        dark,
                      ),
                      dark,
                    ),
                ],
              ),
              for (
                var runIndex = 0;
                runIndex < state.secondRuns.length;
                runIndex++
              )
                TableRow(
                  children: [
                    _rigidRotationTableCell(
                      Text(
                        '${runIndex + 1}',
                        style: _rigidRotationCellTextStyle(dark),
                      ),
                      dark,
                      labelCell: true,
                    ),
                    _rigidRotationTableCell(
                      _rigidRotationValue(
                        RigidRotationCalculator.format(
                          calculation.secondRuns[runIndex].radius,
                        ),
                        dark,
                      ),
                      dark,
                    ),
                    for (var timeIndex = 0; timeIndex < 3; timeIndex++)
                      _rigidRotationTableCell(
                        _RigidRotationTextField(
                          key: ValueKey<String>(
                            'rigid-second-time-$runIndex-$timeIndex',
                          ),
                          value: state.secondRuns[runIndex].times[timeIndex],
                          label: '第二关系第 ${runIndex + 1} 组时间${timeIndex + 1}',
                          dark: dark,
                          compact: true,
                          onChanged: (value) =>
                              onTimeChanged(runIndex, timeIndex, value),
                        ),
                        dark,
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

class _RigidRotationResults extends StatelessWidget {
  const _RigidRotationResults({
    required this.calculation,
    required this.dark,
    required this.onExportChart,
  });

  final RigidRotationCalculation calculation;
  final bool dark;
  final ValueChanged<RigidRotationChartSpec> onExportChart;

  @override
  Widget build(BuildContext context) {
    final specs = rigidRotationChartSpecs(calculation);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _rigidRotationResultCard('质量-时间关系', dark, [
          _RigidRotationMassResultTable(calculation: calculation, dark: dark),
          _RigidRotationResultLine(
            prefix: '最小二乘斜率',
            formula: r'k_1',
            value: RigidRotationCalculator.format(calculation.firstFit.slope),
            dark: dark,
          ),
          _RigidRotationResultLine(
            prefix: '转动惯量',
            formula: r'I_1=\frac{g k_1 d_5^2}{8h}\,/\,\mathrm{kg\,m^2}',
            value: RigidRotationCalculator.format(calculation.firstInertia),
            dark: dark,
          ),
        ]),
        const SizedBox(height: 10),
        _rigidRotationResultCard('半径-时间关系', dark, [
          _RigidRotationSecondResultTable(calculation: calculation, dark: dark),
          _RigidRotationResultLine(
            prefix: '最小二乘斜率',
            formula: r'k_2',
            value: RigidRotationCalculator.format(calculation.secondFit.slope),
            dark: dark,
          ),
          _RigidRotationResultLine(
            prefix: '转动惯量',
            formula: r'I_2=\frac{m g k_2^2}{2h}\,/\,\mathrm{kg\,m^2}',
            value: RigidRotationCalculator.format(calculation.secondInertia),
            dark: dark,
          ),
          _RigidRotationResultLine(
            prefix: '最终结果',
            formula: r'I=\frac{I_1+I_2}{2}\,/\,\mathrm{kg\,m^2}',
            value: RigidRotationCalculator.format(calculation.inertia),
            dark: dark,
          ),
        ]),
        const SizedBox(height: 14),
        Text('关系图', style: _rigidRotationResultTitleStyle(dark)),
        const SizedBox(height: 9),
        LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = constraints.maxWidth >= 720
                ? (constraints.maxWidth - 12) / 2
                : constraints.maxWidth;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final spec in specs)
                  SizedBox(
                    width: itemWidth,
                    child: RigidRotationChartCard(
                      spec: spec,
                      dark: dark,
                      onExport: () => onExportChart(spec),
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

class _RigidRotationMassResultTable extends StatelessWidget {
  const _RigidRotationMassResultTable({
    required this.calculation,
    required this.dark,
  });

  final RigidRotationCalculation calculation;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return _RigidRotationTableScroll(
      width: 520,
      dark: dark,
      child: Table(
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        columnWidths: const {
          0: FixedColumnWidth(86),
          1: FlexColumnWidth(1),
          2: FlexColumnWidth(1),
          3: FlexColumnWidth(1),
          4: FlexColumnWidth(1),
        },
        border: _rigidRotationTableBorder(dark),
        children: [
          TableRow(
            decoration: BoxDecoration(color: _rigidRotationHeaderColor(dark)),
            children: [
              _rigidRotationHeaderCell(const Text('组数'), dark),
              _rigidRotationHeaderCell(
                _rigidRotationHeaderMath(
                  '总质量',
                  r'\sum M_i\,/\,\mathrm{kg}',
                  dark,
                ),
                dark,
              ),
              _rigidRotationHeaderCell(
                _rigidRotationHeaderMath(
                  '平均时间',
                  r'\bar t\,/\,\mathrm{s}',
                  dark,
                ),
                dark,
              ),
              _rigidRotationHeaderCell(
                _rigidRotationHeaderMath(
                  '时间平方',
                  r'\bar t^2\,/\,\mathrm{s^2}',
                  dark,
                ),
                dark,
              ),
              _rigidRotationHeaderCell(
                _rigidRotationHeaderMath(
                  '倒数平方',
                  r'1/\bar t^2\,/\,\mathrm{s^{-2}}',
                  dark,
                ),
                dark,
              ),
            ],
          ),
          for (var index = 0; index < calculation.massRuns.length; index++)
            TableRow(
              children: [
                _rigidRotationTableCell(
                  Text(
                    '${index + 1}',
                    style: _rigidRotationCellTextStyle(dark),
                  ),
                  dark,
                  labelCell: true,
                ),
                _rigidRotationTableCell(
                  _rigidRotationValue(
                    RigidRotationCalculator.format(
                      calculation.massRuns[index].mass,
                    ),
                    dark,
                  ),
                  dark,
                ),
                _rigidRotationTableCell(
                  _rigidRotationValue(
                    RigidRotationCalculator.format(
                      calculation.massRuns[index].run.mean,
                    ),
                    dark,
                  ),
                  dark,
                ),
                _rigidRotationTableCell(
                  _rigidRotationValue(
                    RigidRotationCalculator.format(
                      calculation.massRuns[index].run.square,
                    ),
                    dark,
                  ),
                  dark,
                ),
                _rigidRotationTableCell(
                  _rigidRotationValue(
                    RigidRotationCalculator.format(
                      calculation.massRuns[index].run.inverseSquare,
                    ),
                    dark,
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

class _RigidRotationSecondResultTable extends StatelessWidget {
  const _RigidRotationSecondResultTable({
    required this.calculation,
    required this.dark,
  });

  final RigidRotationCalculation calculation;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return _RigidRotationTableScroll(
      width: 520,
      dark: dark,
      child: Table(
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        columnWidths: const {
          0: FixedColumnWidth(86),
          1: FlexColumnWidth(1),
          2: FlexColumnWidth(1),
          3: FlexColumnWidth(1),
        },
        border: _rigidRotationTableBorder(dark),
        children: [
          TableRow(
            decoration: BoxDecoration(color: _rigidRotationHeaderColor(dark)),
            children: [
              _rigidRotationHeaderCell(const Text('组数'), dark),
              _rigidRotationHeaderCell(
                _rigidRotationHeaderMath('半径', r'r\,/\,\mathrm{m}', dark),
                dark,
              ),
              _rigidRotationHeaderCell(
                _rigidRotationHeaderMath(
                  '平均时间',
                  r'\bar t\,/\,\mathrm{s}',
                  dark,
                ),
                dark,
              ),
              _rigidRotationHeaderCell(
                _rigidRotationHeaderMath(
                  '倒数时间',
                  r'1/\bar t\,/\,\mathrm{s^{-1}}',
                  dark,
                ),
                dark,
              ),
            ],
          ),
          for (var index = 0; index < calculation.secondRuns.length; index++)
            TableRow(
              children: [
                _rigidRotationTableCell(
                  Text(
                    '${index + 1}',
                    style: _rigidRotationCellTextStyle(dark),
                  ),
                  dark,
                  labelCell: true,
                ),
                _rigidRotationTableCell(
                  _rigidRotationValue(
                    RigidRotationCalculator.format(
                      calculation.secondRuns[index].radius,
                    ),
                    dark,
                  ),
                  dark,
                ),
                _rigidRotationTableCell(
                  _rigidRotationValue(
                    RigidRotationCalculator.format(
                      calculation.secondRuns[index].run.mean,
                    ),
                    dark,
                  ),
                  dark,
                ),
                _rigidRotationTableCell(
                  _rigidRotationValue(
                    RigidRotationCalculator.format(
                      calculation.secondRuns[index].run.inverseTime,
                    ),
                    dark,
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

class _RigidRotationParameterGrid extends StatelessWidget {
  const _RigidRotationParameterGrid({required this.children});

  final List<Widget> children;

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
            for (final child in children) SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }
}

class _RigidRotationParameterField extends StatelessWidget {
  const _RigidRotationParameterField({
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
    final labelStyle = _rigidRotationFieldLabelStyle(dark);
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
                _rigidRotationMath(
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
        _RigidRotationTextField(
          value: value,
          label: label,
          dark: dark,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _RigidRotationTextField extends StatefulWidget {
  const _RigidRotationTextField({
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
  State<_RigidRotationTextField> createState() =>
      _RigidRotationTextFieldState();
}

class _RigidRotationTextFieldState extends State<_RigidRotationTextField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _RigidRotationTextField oldWidget) {
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

typedef ValueChanged2<A, B> = void Function(A first, B second);
typedef ValueChanged3<A, B, C> = void Function(A first, B second, C third);

class _RigidRotationTableScroll extends StatelessWidget {
  const _RigidRotationTableScroll({
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
        final tableWidth =
            constraints.maxWidth.isFinite && constraints.maxWidth > width
            ? constraints.maxWidth
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

Widget _rigidRotationHeaderMath(String text, String formula, bool dark) {
  return Wrap(
    alignment: WrapAlignment.center,
    children: [
      Text(
        text,
        textAlign: TextAlign.center,
        style: _rigidRotationHeaderTextStyle(dark),
      ),
      const SizedBox(width: 3),
      _rigidRotationMath(formula, dark, fontSize: 11, weight: FontWeight.w700),
    ],
  );
}

Widget _rigidRotationTableCell(
  Widget child,
  bool dark, {
  bool labelCell = false,
}) {
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
      style: _rigidRotationCellTextStyle(dark),
      child: child,
    ),
  );
}

Widget _rigidRotationHeaderCell(Widget child, bool dark) {
  return Container(
    constraints: const BoxConstraints(minHeight: 42),
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
    alignment: Alignment.center,
    color: _rigidRotationHeaderColor(dark),
    child: DefaultTextStyle.merge(
      style: _rigidRotationHeaderTextStyle(dark),
      child: child,
    ),
  );
}

Widget _rigidRotationValue(String value, bool dark) => Text(
  value,
  textAlign: TextAlign.center,
  style: _rigidRotationCellTextStyle(dark),
);

Widget _rigidRotationMath(
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

Widget _rigidRotationResultCard(
  String title,
  bool dark,
  List<Widget> children,
) {
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
        Text(title, style: _rigidRotationResultTitleStyle(dark)),
        const SizedBox(height: 10),
        ...content,
      ],
    ),
  );
}

class _RigidRotationResultLine extends StatelessWidget {
  const _RigidRotationResultLine({
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
            Text(prefix, style: _rigidRotationResultLabelStyle(dark)),
            _rigidRotationMath(formula, dark, fontSize: 12),
          ],
        );
        final valueWidget = Text(
          value,
          textAlign: narrow ? TextAlign.left : TextAlign.right,
          style: _rigidRotationResultValueStyle(dark),
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

TableBorder _rigidRotationTableBorder(bool dark) {
  return TableBorder(
    horizontalInside: BorderSide(
      color: dark ? const Color(0xFF28465C) : const Color(0xFFE5EDF2),
    ),
    verticalInside: BorderSide(
      color: dark ? const Color(0xFF28465C) : const Color(0xFFE5EDF2),
    ),
  );
}

Color _rigidRotationHeaderColor(bool dark) =>
    dark ? const Color(0xFF14263A) : const Color(0xFFEEF6FA);

TextStyle _rigidRotationSectionTitleStyle(bool dark) => TextStyle(
  color: EcjtuColors.platformText(
    dark,
    (dark ? const Color(0xFFE1EDFF) : const Color(0xFF223549)),
  ),
  fontSize: 13,
  fontWeight: FontWeight.w700,
  height: 1.3,
);

TextStyle _rigidRotationResultTitleStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFF9DDCFF) : const Color(0xFF275B7A),
  fontSize: 13,
  fontWeight: FontWeight.w700,
  height: 1.3,
);

TextStyle _rigidRotationFormulaTitleStyle(bool dark) => TextStyle(
  color: EcjtuColors.platformText(
    dark,
    (dark ? const Color(0xFFD6E6F3) : const Color(0xFF275B7A)),
  ),
  fontSize: 12,
  fontWeight: FontWeight.w700,
  height: 1.3,
);

TextStyle _rigidRotationFormulaNumberStyle(bool dark) => TextStyle(
  color: EcjtuColors.platformText(
    dark,
    (dark ? const Color(0xFFE1EDFF) : const Color(0xFF223549)),
  ),
  fontSize: 16,
  fontWeight: FontWeight.w500,
  height: 1.2,
);

TextStyle _rigidRotationFieldLabelStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFFB9E2F7) : const Color(0xFF667B8E),
  fontSize: 11,
  fontWeight: FontWeight.w600,
  height: 1.3,
);

TextStyle _rigidRotationHeaderTextStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFFD6E6F3) : const Color(0xFF5D7487),
  fontSize: 11,
  fontWeight: FontWeight.w700,
  height: 1.25,
);

TextStyle _rigidRotationCellTextStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFFB7D9ED) : const Color(0xFF334F65),
  fontSize: 11,
  height: 1.25,
);

TextStyle _rigidRotationResultLabelStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFF9EACC3) : const Color(0xFF527087),
  fontSize: 12,
  fontWeight: FontWeight.w600,
  height: 1.3,
);

TextStyle _rigidRotationResultValueStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFF8FD2FF) : const Color(0xFF275B7A),
  fontSize: 12,
  fontWeight: FontWeight.w700,
  height: 1.3,
);
