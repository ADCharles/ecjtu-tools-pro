// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

part of 'physics_single_arm_bridge_page.dart';

Widget _bridgeFormulaBlock(bool dark) {
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
        Text('计算公式', style: _bridgeFormulaTitleStyle(dark)),
        const SizedBox(height: 7),
        _BridgeFormulaLine(
          number: '1.',
          formula: r'\bar{R}=\frac{1}{n}\sum_{i=1}^{n}R_i',
          dark: dark,
        ),
        _BridgeFormulaLine(
          number: '2.',
          formula: r's_R=\sqrt{\frac{\sum_{i=1}^{n}(R_i-\bar{R})^2}{n-1}}',
          dark: dark,
        ),
        _BridgeFormulaLine(
          number: '3.',
          formula: r'R=\bar{R}\pm s_R',
          dark: dark,
        ),
      ],
    ),
  );
}

Widget _bridgeSection({
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
            Text(title, style: _bridgeSectionTitleStyle(dark)),
            const SizedBox(height: 12),
            child,
          ],
        ),
      );
    },
  );
}

class _BridgeFormulaLine extends StatelessWidget {
  const _BridgeFormulaLine({
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
            child: Text(number, style: _bridgeFormulaNumberStyle(dark)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _bridgeMath(
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

class _BridgeInputTable extends StatelessWidget {
  const _BridgeInputTable({
    required this.state,
    required this.dark,
    required this.onChanged,
  });

  final SingleArmBridgeState state;
  final bool dark;
  final void Function(String field, int index, String value) onChanged;

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
                3: FlexColumnWidth(1),
              },
              border: _bridgeTableBorder(dark),
              children: [
                TableRow(
                  decoration: BoxDecoration(color: _bridgeHeaderColor(dark)),
                  children: [
                    _bridgeTableCell(const Text('次数'), dark, header: true),
                    _bridgeTableCell(
                      _bridgeMixedLabel(
                        'R1',
                        r'R_1\,/\,\Omega',
                        dark,
                        textStyle: _bridgeHeaderTextStyle(dark),
                      ),
                      dark,
                      header: true,
                    ),
                    _bridgeTableCell(
                      _bridgeMixedLabel(
                        'R2',
                        r'R_2\,/\,\Omega',
                        dark,
                        textStyle: _bridgeHeaderTextStyle(dark),
                      ),
                      dark,
                      header: true,
                    ),
                    _bridgeTableCell(
                      _bridgeMixedLabel(
                        '并联',
                        r'R_{1\parallel2}\,/\,\Omega',
                        dark,
                        textStyle: _bridgeHeaderTextStyle(dark),
                      ),
                      dark,
                      header: true,
                    ),
                  ],
                ),
                for (
                  var index = 0;
                  index < SingleArmBridgeState.measurementCount;
                  index++
                )
                  TableRow(
                    children: [
                      _bridgeTableCell(
                        Text(
                          (index + 1).toString(),
                          style: _bridgeRowLabelStyle(dark),
                        ),
                        dark,
                        labelCell: true,
                      ),
                      _bridgeTableCell(
                        _BridgeTextField(
                          key: ValueKey<String>('single-arm-bridge-r1-$index'),
                          value: state.r1[index],
                          label: 'R1 第 ${index + 1} 次',
                          dark: dark,
                          onChanged: (value) => onChanged('r1', index, value),
                        ),
                        dark,
                      ),
                      _bridgeTableCell(
                        _BridgeTextField(
                          key: ValueKey<String>('single-arm-bridge-r2-$index'),
                          value: state.r2[index],
                          label: 'R2 第 ${index + 1} 次',
                          dark: dark,
                          onChanged: (value) => onChanged('r2', index, value),
                        ),
                        dark,
                      ),
                      _bridgeTableCell(
                        _BridgeTextField(
                          key: ValueKey<String>(
                            'single-arm-bridge-parallel-$index',
                          ),
                          value: state.parallel[index],
                          label: '并联电阻第 ${index + 1} 次',
                          dark: dark,
                          onChanged: (value) =>
                              onChanged('parallel', index, value),
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

class _BridgeOutputContent extends StatelessWidget {
  const _BridgeOutputContent({
    required this.calculation,
    required this.dark,
    required this.saving,
    required this.onExportPdf,
    required this.onSave,
  });

  final SingleArmBridgeCalculation calculation;
  final bool dark;
  final bool saving;
  final VoidCallback onExportPdf;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BridgeResultCard(
          title: 'R1',
          formula: r'R_1\,/\,\Omega',
          statistics: calculation.r1,
          dark: dark,
        ),
        const SizedBox(height: 12),
        _BridgeResultCard(
          title: 'R2',
          formula: r'R_2\,/\,\Omega',
          statistics: calculation.r2,
          dark: dark,
        ),
        const SizedBox(height: 12),
        _BridgeResultCard(
          title: '并联电阻',
          formula: r'R_{1\parallel2}\,/\,\Omega',
          statistics: calculation.parallel,
          dark: dark,
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

class _BridgeResultCard extends StatelessWidget {
  const _BridgeResultCard({
    required this.title,
    required this.formula,
    required this.statistics,
    required this.dark,
  });

  final String title;
  final String formula;
  final SingleArmBridgeStatistics statistics;
  final bool dark;

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
          Text(title, style: _bridgeResultTitleStyle(dark)),
          const SizedBox(height: 10),
          _BridgeResultTable(statistics: statistics, dark: dark),
          _bridgeResultLine(
            label: _bridgeMixedLabel('结果', formula, dark),
            value: SingleArmBridgeCalculator.resultText(statistics),
            dark: dark,
          ),
        ],
      ),
    );
  }
}

class _BridgeResultTable extends StatelessWidget {
  const _BridgeResultTable({required this.statistics, required this.dark});

  final SingleArmBridgeStatistics statistics;
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
                2: FlexColumnWidth(1),
                3: FlexColumnWidth(1),
              },
              border: _bridgeTableBorder(dark),
              children: [
                TableRow(
                  decoration: BoxDecoration(color: _bridgeHeaderColor(dark)),
                  children: [
                    _bridgeTableCell(const Text('次数'), dark, header: true),
                    _bridgeTableCell(
                      _bridgeMixedLabel(
                        '原始值',
                        r'R\,/\,\Omega',
                        dark,
                        textStyle: _bridgeHeaderTextStyle(dark),
                      ),
                      dark,
                      header: true,
                    ),
                    _bridgeTableCell(
                      _bridgeMixedLabel(
                        '平均值',
                        r'\bar{R}\,/\,\Omega',
                        dark,
                        textStyle: _bridgeHeaderTextStyle(dark),
                      ),
                      dark,
                      header: true,
                    ),
                    _bridgeTableCell(
                      _bridgeMixedLabel(
                        '标准方差',
                        r's_R\,/\,\Omega',
                        dark,
                        textStyle: _bridgeHeaderTextStyle(dark),
                      ),
                      dark,
                      header: true,
                    ),
                  ],
                ),
                for (
                  var index = 0;
                  index < SingleArmBridgeState.measurementCount;
                  index++
                )
                  TableRow(
                    children: [
                      _bridgeTableCell(
                        Text(
                          (index + 1).toString(),
                          style: _bridgeRowLabelStyle(dark),
                        ),
                        dark,
                        labelCell: true,
                      ),
                      _bridgeTableCell(
                        _bridgeValue(statistics.values[index], dark),
                        dark,
                      ),
                      _bridgeTableCell(
                        index == 0
                            ? _bridgeValue(statistics.average, dark)
                            : const SizedBox.shrink(),
                        dark,
                      ),
                      _bridgeTableCell(
                        index == 0
                            ? _bridgeValue(statistics.standardDeviation, dark)
                            : const SizedBox.shrink(),
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

Widget _bridgeResultLine({
  required Widget label,
  required String value,
  required bool dark,
}) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final narrow = constraints.maxWidth < 520;
      final labelWidget = Align(alignment: Alignment.centerLeft, child: label);
      final valueWidget = Text(
        value,
        textAlign: narrow ? TextAlign.left : TextAlign.right,
        style: _bridgeResultValueStyle(dark),
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
                children: [labelWidget, const SizedBox(height: 4), valueWidget],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: labelWidget),
                  const SizedBox(width: 12),
                  Flexible(child: valueWidget),
                ],
              ),
      );
    },
  );
}

Widget _bridgeMixedLabel(
  String text,
  String formula,
  bool dark, {
  TextStyle? textStyle,
  Color? mathColor,
}) {
  return Wrap(
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: 3,
    children: [
      Text(text, style: textStyle ?? _bridgeLabelTextStyle(dark)),
      _bridgeMath(
        formula,
        dark,
        fontSize: textStyle?.fontSize ?? 12,
        weight: textStyle?.fontWeight ?? FontWeight.w400,
        color: mathColor ?? textStyle?.color,
      ),
    ],
  );
}

Widget _bridgeValue(double? value, bool dark) {
  return Text(
    SingleArmBridgeCalculator.format(value),
    textAlign: TextAlign.center,
    style: _bridgeValueTextStyle(dark),
  );
}

Widget _bridgeTableCell(
  Widget child,
  bool dark, {
  bool header = false,
  bool labelCell = false,
}) {
  return Container(
    constraints: const BoxConstraints(minHeight: 38),
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 7),
    alignment: Alignment.center,
    color: header
        ? _bridgeHeaderColor(dark)
        : labelCell
        ? (dark ? const Color(0xFF14263A) : const Color(0xFFF8FBFD))
        : (EcjtuColors.platformSurface(
            dark,
            (dark ? const Color(0xFF101D31) : Colors.white),
          )),
    child: DefaultTextStyle.merge(
      style: header ? _bridgeHeaderTextStyle(dark) : _bridgeCellTextStyle(dark),
      child: child,
    ),
  );
}

class _BridgeTextField extends StatefulWidget {
  const _BridgeTextField({
    super.key,
    required this.value,
    required this.label,
    required this.dark,
    required this.onChanged,
  });

  final String value;
  final String label;
  final bool dark;
  final ValueChanged<String> onChanged;

  @override
  State<_BridgeTextField> createState() => _BridgeTextFieldState();
}

class _BridgeTextFieldState extends State<_BridgeTextField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _BridgeTextField oldWidget) {
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
        height: 30,
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 5,
              vertical: 4,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5),
              borderSide: BorderSide(
                color: widget.dark
                    ? const Color(0xFF426B83)
                    : const Color(0xFFB9CFDD),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5),
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

Widget _bridgeMath(
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

TableBorder _bridgeTableBorder(bool dark) => TableBorder(
  horizontalInside: BorderSide(
    color: dark ? const Color(0xFF28465C) : const Color(0xFFE5EDF2),
  ),
  verticalInside: BorderSide(
    color: dark ? const Color(0xFF28465C) : const Color(0xFFE5EDF2),
  ),
);

Color _bridgeHeaderColor(bool dark) =>
    dark ? const Color(0xFF14263A) : const Color(0xFFEEF6FA);

TextStyle _bridgeSectionTitleStyle(bool dark) => TextStyle(
  color: EcjtuColors.platformText(
    dark,
    (dark ? const Color(0xFFE1EDFF) : const Color(0xFF223549)),
  ),
  fontSize: 13,
  fontWeight: FontWeight.w700,
  height: 1.3,
);

TextStyle _bridgeResultTitleStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFF9DDCFF) : const Color(0xFF275B7A),
  fontSize: 13,
  fontWeight: FontWeight.w700,
  height: 1.3,
);

TextStyle _bridgeFormulaTitleStyle(bool dark) => TextStyle(
  color: EcjtuColors.platformText(
    dark,
    (dark ? const Color(0xFFD6E6F3) : const Color(0xFF275B7A)),
  ),
  fontSize: 12,
  fontWeight: FontWeight.w700,
  height: 1.3,
);

TextStyle _bridgeFormulaNumberStyle(bool dark) => TextStyle(
  color: EcjtuColors.platformText(
    dark,
    (dark ? const Color(0xFFE1EDFF) : const Color(0xFF223549)),
  ),
  fontSize: 16,
  fontWeight: FontWeight.w500,
  height: 1.2,
);

TextStyle _bridgeLabelTextStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFFB9E2F7) : const Color(0xFF527087),
  fontSize: 12,
  fontWeight: FontWeight.w600,
  height: 1.3,
);

TextStyle _bridgeHeaderTextStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFFD6E6F3) : const Color(0xFF5D7487),
  fontSize: 12,
  fontWeight: FontWeight.w700,
  height: 1.25,
);

TextStyle _bridgeRowLabelStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFFB7D9ED) : const Color(0xFF275B7A),
  fontSize: 12,
  fontWeight: FontWeight.w700,
  height: 1.25,
);

TextStyle _bridgeCellTextStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFFB7D9ED) : const Color(0xFF334F65),
  fontSize: 12,
  height: 1.25,
);

TextStyle _bridgeValueTextStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFFB7D9ED) : const Color(0xFF334F65),
  fontSize: 12,
  height: 1.25,
);

TextStyle _bridgeResultValueStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFF8FD2FF) : const Color(0xFF176496),
  fontSize: 13,
  fontWeight: FontWeight.w800,
  height: 1.25,
);
