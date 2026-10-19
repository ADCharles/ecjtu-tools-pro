// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

part of 'physics_solid_density_page.dart';

Widget _solidFormulaBlock(bool dark) {
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
        Text('计算公式', style: _solidFormulaTitleStyle(dark)),
        const SizedBox(height: 7),
        _SolidFormulaLine(
          number: '1.',
          formula: r'\bar{x}=\frac{1}{n}\sum_{i=1}^{n}x_i',
          dark: dark,
        ),
        _SolidFormulaLine(number: '2.', formula: r'V=abh', dark: dark),
        _SolidFormulaLine(
          number: '3.',
          formula: r'\rho=\frac{m}{V}=\frac{m}{abh}',
          dark: dark,
        ),
        _SolidFormulaLine(
          number: '4.',
          formula: r'\rho=\frac{(m_2-m_1)\rho_0}{m_3-m_2}',
          dark: dark,
        ),
      ],
    ),
  );
}

Widget _solidSection({
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
            Text(title, style: _solidSectionTitleStyle(dark)),
            const SizedBox(height: 12),
            child,
          ],
        ),
      );
    },
  );
}

class _SolidFormulaLine extends StatelessWidget {
  const _SolidFormulaLine({
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
            child: Text(number, style: _solidFormulaNumberStyle(dark)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _solidMath(
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

class _SolidRectangularInput extends StatelessWidget {
  const _SolidRectangularInput({
    required this.input,
    required this.dark,
    required this.onMeasurementChanged,
    required this.onFieldChanged,
  });

  final SolidDensityRectangularInput input;
  final bool dark;
  final void Function(String field, int index, String value)
  onMeasurementChanged;
  final void Function(String field, String value) onFieldChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SolidMeasurementTable(
          input: input,
          dark: dark,
          onChanged: onMeasurementChanged,
        ),
        const SizedBox(height: 12),
        _SolidFieldGrid(
          dark: dark,
          fields: [
            _SolidFieldDefinition(
              label: '质量',
              formula: r'm\,/\,\mathrm{g}',
              value: input.mass,
              semanticLabel: '质量',
              onChanged: (value) => onFieldChanged('mass', value),
            ),
            _SolidFieldDefinition(
              label: '质量不确定度',
              formula: r'u(m)\,/\,\mathrm{g}',
              value: input.massError,
              semanticLabel: '质量不确定度',
              onChanged: (value) => onFieldChanged('massError', value),
            ),
          ],
        ),
      ],
    );
  }
}

class _SolidMeasurementTable extends StatelessWidget {
  const _SolidMeasurementTable({
    required this.input,
    required this.dark,
    required this.onChanged,
  });

  final SolidDensityRectangularInput input;
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
              border: _solidTableBorder(dark),
              children: [
                TableRow(
                  decoration: BoxDecoration(color: _solidHeaderColor(dark)),
                  children: [
                    _solidTableCell(const Text('次数'), dark, header: true),
                    _solidTableCell(
                      _solidMixedLabel(
                        '长度',
                        r'a\,/\,\mathrm{cm}',
                        dark,
                        textStyle: _solidHeaderTextStyle(dark),
                      ),
                      dark,
                      header: true,
                    ),
                    _solidTableCell(
                      _solidMixedLabel(
                        '宽度',
                        r'b\,/\,\mathrm{cm}',
                        dark,
                        textStyle: _solidHeaderTextStyle(dark),
                      ),
                      dark,
                      header: true,
                    ),
                    _solidTableCell(
                      _solidMixedLabel(
                        '高度',
                        r'h\,/\,\mathrm{cm}',
                        dark,
                        textStyle: _solidHeaderTextStyle(dark),
                      ),
                      dark,
                      header: true,
                    ),
                  ],
                ),
                for (
                  var index = 0;
                  index < SolidDensityRectangularInput.measurementCount;
                  index++
                )
                  TableRow(
                    children: [
                      _solidTableCell(
                        Text('${index + 1}', style: _solidRowLabelStyle(dark)),
                        dark,
                        labelCell: true,
                      ),
                      _solidTableCell(
                        _SolidTextField(
                          key: ValueKey<String>('solid-length-$index'),
                          value: input.length[index],
                          label: '长度第 ${index + 1} 次',
                          dark: dark,
                          tableInput: true,
                          onChanged: (value) =>
                              onChanged('length', index, value),
                        ),
                        dark,
                      ),
                      _solidTableCell(
                        _SolidTextField(
                          key: ValueKey<String>('solid-width-$index'),
                          value: input.width[index],
                          label: '宽度第 ${index + 1} 次',
                          dark: dark,
                          tableInput: true,
                          onChanged: (value) =>
                              onChanged('width', index, value),
                        ),
                        dark,
                      ),
                      _solidTableCell(
                        _SolidTextField(
                          key: ValueKey<String>('solid-height-$index'),
                          value: input.height[index],
                          label: '高度第 ${index + 1} 次',
                          dark: dark,
                          tableInput: true,
                          onChanged: (value) =>
                              onChanged('height', index, value),
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

class _SolidDisplacementInput extends StatelessWidget {
  const _SolidDisplacementInput({
    required this.input,
    required this.dark,
    required this.onChanged,
  });

  final SolidDensityDisplacementInput input;
  final bool dark;
  final void Function(String field, String value) onChanged;

  @override
  Widget build(BuildContext context) {
    return _SolidFieldGrid(
      dark: dark,
      fields: [
        _SolidFieldDefinition(
          label: '空杯质量',
          formula: r'm_1\,/\,\mathrm{g}',
          value: input.m1,
          semanticLabel: '空杯质量',
          onChanged: (value) => onChanged('m1', value),
        ),
        _SolidFieldDefinition(
          label: '物体与水质量',
          formula: r'm_2\,/\,\mathrm{g}',
          value: input.m2,
          semanticLabel: '物体与水质量',
          onChanged: (value) => onChanged('m2', value),
        ),
        _SolidFieldDefinition(
          label: '物体、水和杯质量',
          formula: r'm_3\,/\,\mathrm{g}',
          value: input.m3,
          semanticLabel: '物体、水和杯质量',
          onChanged: (value) => onChanged('m3', value),
        ),
        _SolidFieldDefinition(
          label: '水的密度',
          formula: r'\rho_0\,/\,\mathrm{g\,cm^{-3}}',
          value: input.waterDensity,
          placeholder: SolidDensityDisplacementInput.defaultWaterDensity,
          semanticLabel: '水的密度',
          onChanged: (value) => onChanged('waterDensity', value),
        ),
        _SolidFieldDefinition(
          label: '称量不确定度',
          formula: r'u(m)\,/\,\mathrm{g}',
          value: input.massError,
          semanticLabel: '称量不确定度',
          onChanged: (value) => onChanged('massError', value),
        ),
        _SolidFieldDefinition(
          label: '水密度不确定度',
          formula: r'u(\rho_0)\,/\,\mathrm{g\,cm^{-3}}',
          value: input.waterDensityError,
          semanticLabel: '水密度不确定度',
          onChanged: (value) => onChanged('waterDensityError', value),
        ),
      ],
    );
  }
}

class _SolidFieldDefinition {
  const _SolidFieldDefinition({
    required this.label,
    required this.formula,
    required this.value,
    required this.semanticLabel,
    required this.onChanged,
    this.placeholder = '',
  });

  final String label;
  final String formula;
  final String value;
  final String semanticLabel;
  final String placeholder;
  final ValueChanged<String> onChanged;
}

class _SolidFieldGrid extends StatelessWidget {
  const _SolidFieldGrid({required this.dark, required this.fields});

  final bool dark;
  final List<_SolidFieldDefinition> fields;

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
                child: _SolidLabeledInput(
                  key: ValueKey<String>(
                    'solid-field-$index-${fields[index].label}',
                  ),
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

class _SolidLabeledInput extends StatelessWidget {
  const _SolidLabeledInput({
    super.key,
    required this.definition,
    required this.dark,
  });

  final _SolidFieldDefinition definition;
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
            child: _solidMixedLabel(
              definition.label,
              definition.formula,
              dark,
              textStyle: _solidFieldLabelStyle(dark),
            ),
          ),
        ),
        const SizedBox(height: 5),
        _SolidTextField(
          value: definition.value,
          label: definition.semanticLabel,
          placeholder: definition.placeholder,
          dark: dark,
          onChanged: definition.onChanged,
        ),
      ],
    );
  }
}

class _SolidOutputContent extends StatelessWidget {
  const _SolidOutputContent({
    required this.calculation,
    required this.dark,
    required this.saving,
    required this.onExportPdf,
    required this.onSave,
  });

  final SolidDensityCalculation calculation;
  final bool dark;
  final bool saving;
  final VoidCallback onExportPdf;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SolidResultCard(
          title: '规则物体结果',
          dark: dark,
          children: [
            _SolidStatisticsTable(
              calculation: calculation.rectangular,
              dark: dark,
            ),
            _solidResultLine(
              label: _solidMixedLabel('体积', r'V\,/\,\mathrm{cm^3}', dark),
              value: SolidDensityCalculator.format(
                calculation.rectangular.volume,
              ),
              dark: dark,
              first: true,
            ),
            _solidResultLine(
              label: _solidMixedLabel(
                '密度',
                r'\rho\,/\,\mathrm{g\,cm^{-3}}',
                dark,
              ),
              value: SolidDensityCalculator.format(
                calculation.rectangular.density,
              ),
              dark: dark,
            ),
            _solidResultLine(
              label: _solidMixedLabel('相对不确定度', r'u_r(\rho)', dark),
              value: SolidDensityCalculator.percent(
                calculation.rectangular.relativeUncertainty,
              ),
              dark: dark,
            ),
            _solidResultLine(
              label: _solidMixedLabel(
                '绝对不确定度',
                r'u(\rho)\,/\,\mathrm{g\,cm^{-3}}',
                dark,
              ),
              value: SolidDensityCalculator.format(
                calculation.rectangular.absoluteUncertainty,
              ),
              dark: dark,
            ),
            _solidResultLine(
              label: _solidMixedLabel(
                '结果',
                r'\rho\,/\,\mathrm{g\,cm^{-3}}',
                dark,
              ),
              value: _solidFinalValue(
                calculation.rectangular.density,
                calculation.rectangular.absoluteUncertainty,
              ),
              dark: dark,
            ),
          ],
        ),
        const SizedBox(height: 14),
        _SolidResultCard(
          title: '不规则物体结果',
          dark: dark,
          children: [
            _solidResultLine(
              label: _solidMixedLabel(
                '物体质量',
                r'm=m_2-m_1\,/\,\mathrm{g}',
                dark,
              ),
              value: SolidDensityCalculator.format(
                calculation.displacement.objectMass,
              ),
              dark: dark,
              first: true,
            ),
            _solidResultLine(
              label: _solidMixedLabel('排水质量', r'm_3-m_2\,/\,\mathrm{g}', dark),
              value: SolidDensityCalculator.format(
                calculation.displacement.waterMass,
              ),
              dark: dark,
            ),
            _solidResultLine(
              label: _solidMixedLabel(
                '密度',
                r'\rho=\frac{(m_2-m_1)\rho_0}{m_3-m_2}\,/\,\mathrm{g\,cm^{-3}}',
                dark,
              ),
              value: SolidDensityCalculator.format(
                calculation.displacement.density,
              ),
              dark: dark,
            ),
            _solidResultLine(
              label: _solidMixedLabel('相对不确定度', r'u_r(\rho)', dark),
              value: SolidDensityCalculator.percent(
                calculation.displacement.relativeUncertainty,
              ),
              dark: dark,
            ),
            _solidResultLine(
              label: _solidMixedLabel(
                '绝对不确定度',
                r'u(\rho)\,/\,\mathrm{g\,cm^{-3}}',
                dark,
              ),
              value: SolidDensityCalculator.format(
                calculation.displacement.absoluteUncertainty,
              ),
              dark: dark,
            ),
            _solidResultLine(
              label: _solidMixedLabel(
                '结果',
                r'\rho\,/\,\mathrm{g\,cm^{-3}}',
                dark,
              ),
              value: _solidFinalValue(
                calculation.displacement.density,
                calculation.displacement.absoluteUncertainty,
              ),
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
              style: physicsSecondaryButtonStyle(context),
              child: const Text('下载全部图 PDF'),
            ),
            OutlinedButton(
              onPressed: saving ? null : onSave,
              style: physicsSecondaryButtonStyle(context),
              child: Text(saving ? '正在保存' : '保存数据'),
            ),
          ],
        ),
      ],
    );
  }
}

class _SolidResultCard extends StatelessWidget {
  const _SolidResultCard({
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
              Text(title, style: _solidResultTitleStyle(dark)),
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

class _SolidStatisticsTable extends StatelessWidget {
  const _SolidStatisticsTable({required this.calculation, required this.dark});

  final SolidDensityRectangularCalculation calculation;
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
              },
              border: _solidTableBorder(dark),
              children: [
                TableRow(
                  decoration: BoxDecoration(color: _solidHeaderColor(dark)),
                  children: [
                    _solidTableCell(const Text('数据项'), dark, header: true),
                    _solidTableCell(
                      _solidMixedLabel(
                        '平均值',
                        r'\bar{x}',
                        dark,
                        textStyle: _solidHeaderTextStyle(dark),
                      ),
                      dark,
                      header: true,
                    ),
                    _solidTableCell(
                      _solidMixedLabel(
                        '标准差',
                        r's_x',
                        dark,
                        textStyle: _solidHeaderTextStyle(dark),
                      ),
                      dark,
                      header: true,
                    ),
                  ],
                ),
                _solidStatisticsRow(
                  label: _solidMixedLabel(
                    '长度',
                    r'a\,/\,\mathrm{cm}',
                    dark,
                    textStyle: _solidRowLabelStyle(dark),
                  ),
                  value: calculation.length,
                  dark: dark,
                ),
                _solidStatisticsRow(
                  label: _solidMixedLabel(
                    '宽度',
                    r'b\,/\,\mathrm{cm}',
                    dark,
                    textStyle: _solidRowLabelStyle(dark),
                  ),
                  value: calculation.width,
                  dark: dark,
                ),
                _solidStatisticsRow(
                  label: _solidMixedLabel(
                    '高度',
                    r'h\,/\,\mathrm{cm}',
                    dark,
                    textStyle: _solidRowLabelStyle(dark),
                  ),
                  value: calculation.height,
                  dark: dark,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

TableRow _solidStatisticsRow({
  required Widget label,
  required SolidDensityStatistics value,
  required bool dark,
}) {
  return TableRow(
    children: [
      _solidTableCell(label, dark, labelCell: true),
      _solidTableCell(
        Text(
          SolidDensityCalculator.format(value.average),
          textAlign: TextAlign.center,
          style: _solidValueTextStyle(dark),
        ),
        dark,
      ),
      _solidTableCell(
        Text(
          SolidDensityCalculator.format(value.standardDeviation),
          textAlign: TextAlign.center,
          style: _solidValueTextStyle(dark),
        ),
        dark,
      ),
    ],
  );
}

Widget _solidResultLine({
  required Widget label,
  required String value,
  required bool dark,
  bool first = false,
}) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final narrow = constraints.maxWidth <= 720;
      final labelWidget = Align(alignment: Alignment.centerLeft, child: label);
      final valueWidget = Text(
        value,
        textAlign: narrow ? TextAlign.left : TextAlign.right,
        style: _solidResultValueStyle(dark),
      );
      return Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 30),
        padding: EdgeInsets.only(top: first ? 0 : 7),
        decoration: BoxDecoration(
          border: first
              ? const Border()
              : Border(
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

Widget _solidMixedLabel(
  String text,
  String formula,
  bool dark, {
  TextStyle? textStyle,
  Color? mathColor,
}) {
  final labelStyle = textStyle ?? _solidResultLabelStyle(dark);
  return Wrap(
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: 3,
    children: [
      Text(text, style: labelStyle),
      _solidMath(
        formula,
        dark,
        fontSize: labelStyle.fontSize ?? 12,
        weight: labelStyle.fontWeight ?? FontWeight.w400,
        color: mathColor ?? labelStyle.color,
      ),
    ],
  );
}

String _solidFinalValue(double? density, double? uncertainty) {
  if (density == null) return '—';
  return '${SolidDensityCalculator.format(density)} ± ${SolidDensityCalculator.format(uncertainty)}';
}

Widget _solidTableCell(
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
        constraints: const BoxConstraints(minHeight: 38),
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: 7,
        ),
        alignment: labelCell ? Alignment.centerLeft : Alignment.center,
        color: header
            ? _solidHeaderColor(dark)
            : labelCell
            ? (dark ? const Color(0xFF14263A) : const Color(0xFFF8FBFD))
            : (EcjtuColors.platformSurface(
                dark,
                (dark ? const Color(0xFF101D31) : Colors.white),
              )),
        child: DefaultTextStyle.merge(
          style: header
              ? _solidHeaderTextStyle(dark)
              : labelCell
              ? _solidRowLabelStyle(dark)
              : _solidCellTextStyle(dark),
          child: child,
        ),
      );
    },
  );
}

class _SolidTextField extends StatefulWidget {
  const _SolidTextField({
    super.key,
    required this.value,
    required this.label,
    required this.dark,
    required this.onChanged,
    this.placeholder = '',
    this.tableInput = false,
  });

  final String value;
  final String label;
  final bool dark;
  final ValueChanged<String> onChanged;
  final String placeholder;
  final bool tableInput;

  @override
  State<_SolidTextField> createState() => _SolidTextFieldState();
}

class _SolidTextFieldState extends State<_SolidTextField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _SolidTextField oldWidget) {
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
            hintText: widget.placeholder,
            hintStyle: TextStyle(
              color: widget.dark
                  ? const Color(0xFF7891A7)
                  : const Color(0xFF9AAEBC),
              fontSize: 11,
            ),
            filled: true,
            fillColor: widget.dark ? const Color(0xFF14263A) : Colors.white,
            contentPadding: EdgeInsets.symmetric(
              horizontal: widget.tableInput ? 5 : 7,
              vertical: widget.tableInput ? 4 : 5,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(widget.tableInput ? 5 : 6),
              borderSide: BorderSide(
                color: widget.dark
                    ? const Color(0xFF426B83)
                    : const Color(0xFFB9CFDD),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(widget.tableInput ? 5 : 6),
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

Widget _solidMath(
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

TableBorder _solidTableBorder(bool dark) => TableBorder(
  horizontalInside: BorderSide(
    color: dark ? const Color(0xFF28465C) : const Color(0xFFE5EDF2),
  ),
  verticalInside: BorderSide(
    color: dark ? const Color(0xFF28465C) : const Color(0xFFE5EDF2),
  ),
);

Color _solidHeaderColor(bool dark) =>
    dark ? const Color(0xFF14263A) : const Color(0xFFEEF6FA);

TextStyle _solidSectionTitleStyle(bool dark) => TextStyle(
  color: EcjtuColors.platformText(
    dark,
    (dark ? const Color(0xFFE1EDFF) : const Color(0xFF223549)),
  ),
  fontSize: 13,
  fontWeight: FontWeight.w700,
  height: 1.3,
);

TextStyle _solidResultTitleStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFF9DDCFF) : const Color(0xFF275B7A),
  fontSize: 13,
  fontWeight: FontWeight.w700,
  height: 1.3,
);

TextStyle _solidFormulaTitleStyle(bool dark) => TextStyle(
  color: EcjtuColors.platformText(
    dark,
    (dark ? const Color(0xFFD6E6F3) : const Color(0xFF275B7A)),
  ),
  fontSize: 12,
  fontWeight: FontWeight.w700,
  height: 1.3,
);

TextStyle _solidFormulaNumberStyle(bool dark) => TextStyle(
  color: EcjtuColors.platformText(
    dark,
    (dark ? const Color(0xFFE1EDFF) : const Color(0xFF223549)),
  ),
  fontSize: 16,
  fontWeight: FontWeight.w500,
  height: 1.2,
);

TextStyle _solidFieldLabelStyle(bool dark) => TextStyle(
  color: EcjtuColors.platformMuted(
    dark,
    (dark ? const Color(0xFF9EACC3) : const Color(0xFF667B8E)),
  ),
  fontSize: 11,
  fontWeight: FontWeight.w400,
  height: 1.3,
);

TextStyle _solidRowLabelStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFFB7D9ED) : const Color(0xFF275B7A),
  fontSize: 12,
  fontWeight: FontWeight.w700,
  height: 1.2,
);

TextStyle _solidCellTextStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFFB7D9ED) : const Color(0xFF334F65),
  fontSize: 12,
  height: 1.25,
);

TextStyle _solidHeaderTextStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFFD6E6F3) : const Color(0xFF5D7487),
  fontSize: 12,
  fontWeight: FontWeight.w700,
  height: 1.25,
);

TextStyle _solidResultLabelStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFF9EACC3) : const Color(0xFF527087),
  fontSize: 12,
  fontWeight: FontWeight.w600,
  height: 1.3,
);

TextStyle _solidValueTextStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFFB7D9ED) : const Color(0xFF334F65),
  fontSize: 12,
  height: 1.25,
);

TextStyle _solidResultValueStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFF8FD2FF) : const Color(0xFF176496),
  fontSize: 13,
  fontWeight: FontWeight.w800,
  height: 1.25,
);
