// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

part of 'physics_electron_charge_page.dart';

class _ElectronFormulaBlock extends StatelessWidget {
  const _ElectronFormulaBlock({required this.dark});

  final bool dark;

  @override
  Widget build(BuildContext context) {
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
          Text(
            '计算公式',
            style: TextStyle(
              color: EcjtuColors.platformText(
                dark,
                (dark ? const Color(0xFFD6E6F3) : const Color(0xFF275B7A)),
              ),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 7),
          _ElectronFormulaLine(
            number: '1.',
            label: '电偏转',
            formula: r'S=\frac{\overline D}{\overline{U_d}},\qquad D=S U_d',
            dark: dark,
          ),
          _ElectronFormulaLine(
            number: '2.',
            label: '电聚焦',
            formula: r'\frac{U_2}{U_1}=\frac{\overline{U_2}}{\overline{U_1}}',
            dark: dark,
          ),
          _ElectronFormulaLine(
            number: '3.',
            label: '磁偏转',
            formula: r'S=\frac{\overline D}{\overline I},\qquad D=S I',
            dark: dark,
          ),
          _ElectronFormulaLine(
            number: '4.',
            label: '磁聚焦',
            formula:
                r'\frac{e}{m}=\frac{8\pi^2U_2(L^2+D^2)}{\mu_0^2N^2\overline I^{\,2}h^2}',
            dark: dark,
          ),
        ],
      ),
    );
  }
}

class _ElectronFormulaLine extends StatelessWidget {
  const _ElectronFormulaLine({
    required this.number,
    required this.label,
    required this.formula,
    required this.dark,
  });

  final String number;
  final String label;
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
            child: Text(
              number,
              style: TextStyle(
                color: EcjtuColors.platformText(
                  dark,
                  (dark ? const Color(0xFFE1EDFF) : const Color(0xFF223549)),
                ),
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '$label：',
                    style: TextStyle(
                      color: dark
                          ? const Color(0xFF9EACC3)
                          : const Color(0xFF527087),
                      fontSize: 11,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _math(formula, dark, fontSize: 15, scrollable: false),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ElectronCalculatorSection extends StatelessWidget {
  const _ElectronCalculatorSection({
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
        boxShadow: [
          BoxShadow(
            color: dark ? const Color(0x26000000) : const Color(0x121A4160),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: EcjtuColors.platformText(
                dark,
                (dark ? const Color(0xFFE1EDFF) : const Color(0xFF223549)),
              ),
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

Widget _buildDeflectionInputs({
  required String section,
  required List<ElectronChargeSeriesDefinition> definitions,
  required ElectronChargeState state,
  required bool dark,
  required void Function(String, int, int, String, String) onChanged,
}) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth < 700 ? 1 : 2;
      final width = columns == 1
          ? constraints.maxWidth
          : (constraints.maxWidth - 8) / 2;
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (
            var seriesIndex = 0;
            seriesIndex < definitions.length;
            seriesIndex++
          )
            SizedBox(
              width: width,
              child: _DeflectionInputCard(
                section: section,
                seriesIndex: seriesIndex,
                definition: definitions[seriesIndex],
                source: section == 'electric'
                    ? state.electric[seriesIndex]
                    : state.magnetic[seriesIndex],
                dark: dark,
                onChanged: onChanged,
              ),
            ),
        ],
      );
    },
  );
}

class _DeflectionInputCard extends StatelessWidget {
  const _DeflectionInputCard({
    required this.section,
    required this.seriesIndex,
    required this.definition,
    required this.source,
    required this.dark,
    required this.onChanged,
  });

  final String section;
  final int seriesIndex;
  final ElectronChargeSeriesDefinition definition;
  final ElectronChargeSeriesInput source;
  final bool dark;
  final void Function(String, int, int, String, String) onChanged;

  @override
  Widget build(BuildContext context) {
    return _electronCard(
      dark: dark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _electronTitle(definition.titlePrefix, definition.titleFormula, dark),
          const SizedBox(height: 7),
          _electronTable(
            minWidth: 300,
            dark: dark,
            headers: [
              _tablePlainHeader('组数', dark),
              _tableMathHeader(definition.xFormula, dark),
              _tableMathHeader(definition.yFormula, dark),
            ],
            rows: [
              for (var row = 0; row < definition.xDefaults.length; row++)
                [
                  _tableText('${row + 1}', dark),
                  _tableInput(
                    key: 'electron-$section-$seriesIndex-$row-x',
                    value: source.points[row].x,
                    label: '${definition.xSymbol} 第 ${row + 1} 组',
                    dark: dark,
                    onChanged: (value) =>
                        onChanged(section, seriesIndex, row, 'x', value),
                  ),
                  _tableInput(
                    key: 'electron-$section-$seriesIndex-$row-y',
                    value: source.points[row].y,
                    label: '${definition.ySymbol} 第 ${row + 1} 组',
                    placeholder: '请输入读数',
                    dark: dark,
                    onChanged: (value) =>
                        onChanged(section, seriesIndex, row, 'y', value),
                  ),
                ],
            ],
          ),
        ],
      ),
    );
  }
}

Widget _buildElectroFocusInputs(bool dark) {
  return Builder(
    builder: (context) {
      final page = context
          .findAncestorStateOfType<_PhysicsElectronChargePageState>()!;
      return _electronTable(
        minWidth: 300,
        dark: dark,
        headers: [
          _tablePlainHeader('组数', dark),
          _tableMathHeader(r'U_2\,/\,\mathrm{V}', dark),
          _tableMathHeader(r'U_1\,/\,\mathrm{V}', dark),
        ],
        rows: [
          for (var row = 0; row < ElectronChargeState.focusRowCount; row++)
            [
              _tableText('${row + 1}', dark),
              _tableInput(
                key: 'electron-focus-$row-u2',
                value: page._state.electroFocus[row].u2,
                label: 'U2 第 ${row + 1} 组',
                dark: dark,
                onChanged: (value) => page._changeFocus(row, 'u2', value),
              ),
              _tableInput(
                key: 'electron-focus-$row-u1',
                value: page._state.electroFocus[row].u1,
                label: 'U1 第 ${row + 1} 组',
                placeholder: '请输入测量值',
                dark: dark,
                onChanged: (value) => page._changeFocus(row, 'u1', value),
              ),
            ],
        ],
      );
    },
  );
}

Widget _buildMagneticFocusInputs(bool dark) {
  return Builder(
    builder: (context) {
      final page = context
          .findAncestorStateOfType<_PhysicsElectronChargePageState>()!;
      return LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth < 700 ? 1 : 2;
          final width = columns == 1
              ? constraints.maxWidth
              : (constraints.maxWidth - 12) / 2;
          return Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              for (
                var column = 0;
                column < page._state.magneticFocus.length;
                column++
              )
                SizedBox(
                  width: width,
                  child: _MagneticFocusInputCard(
                    column: column,
                    source: page._state.magneticFocus[column],
                    dark: dark,
                    onChanged: page._changeMagneticFocus,
                  ),
                ),
            ],
          );
        },
      );
    },
  );
}

class _MagneticFocusInputCard extends StatelessWidget {
  const _MagneticFocusInputCard({
    required this.column,
    required this.source,
    required this.dark,
    required this.onChanged,
  });

  final int column;
  final ElectronChargeMagneticFocusInput source;
  final bool dark;
  final void Function(int, String, String) onChanged;

  @override
  Widget build(BuildContext context) {
    final titleFormula = 'U_2=${source.u2}\\,\\mathrm{V}';
    final measurementFields = [
      ('正向电流', r'I_+\,/\,\mathrm{A}', 'forward', source.forward, '请输入测量值'),
      ('反向电流', r'I_-\,/\,\mathrm{A}', 'reverse', source.reverse, '请输入测量值'),
    ];
    final parameterFields = [
      ('', r'U_2\,/\,\mathrm{V}', 'u2', source.u2, '例如 700'),
      ('螺线管长度', r'L\,/\,\mathrm{m}', 'L', source.length, '0.234'),
      ('螺线管平均直径', r'D\,/\,\mathrm{m}', 'D', source.diameter, '0.09'),
      ('螺距', r'h\,/\,\mathrm{m}', 'h', source.pitch, '0.145'),
      ('线圈匝数', r'N', 'N', source.turns, '526'),
      (
        '真空磁导率',
        r'\mu_0\,/\,\mathrm{N\,A^{-2}}',
        'mu0',
        source.mu0,
        '1.256637...e-6',
      ),
      (
        '比荷标准值',
        r'(e/m)_0\,/\,\mathrm{C\,kg^{-1}}',
        'standard',
        source.standard,
        '1.758e11',
      ),
    ];
    return _electronCard(
      dark: dark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _electronTitle('磁聚焦与荷质比，', titleFormula, dark),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 430;
              final measurement = _magneticFields(measurementFields, dark);
              final parameters = _magneticParameterFields(
                parameterFields,
                dark,
                stacked:
                    MediaQuery.sizeOf(context).width <= 560 ||
                    constraints.maxWidth < 255,
              );
              if (stacked) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    measurement,
                    const SizedBox(height: 9),
                    parameters,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 8, child: measurement),
                  const SizedBox(width: 10),
                  Expanded(flex: 18, child: parameters),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _magneticFields(
    List<(String, String, String, String, String)> fields,
    bool dark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < fields.length; index++) ...[
          _electronLabeledInput(
            prefix: fields[index].$1,
            formula: fields[index].$2,
            value: fields[index].$4,
            placeholder: fields[index].$5,
            label: fields[index].$1,
            dark: dark,
            onChanged: (value) => onChanged(column, fields[index].$3, value),
          ),
          if (index < fields.length - 1) const SizedBox(height: 9),
        ],
      ],
    );
  }

  Widget _magneticParameterFields(
    List<(String, String, String, String, String)> fields,
    bool dark, {
    required bool stacked,
  }) {
    if (stacked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var index = 0; index < fields.length; index++) ...[
            _electronLabeledInput(
              prefix: fields[index].$1,
              formula: fields[index].$2,
              value: fields[index].$4,
              placeholder: fields[index].$5,
              label: fields[index].$1,
              dark: dark,
              onChanged: (value) => onChanged(column, fields[index].$3, value),
            ),
            if (index < fields.length - 1) const SizedBox(height: 9),
          ],
        ],
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 9.0;
        final width = (constraints.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final field in fields)
              SizedBox(
                width: width,
                child: _electronLabeledInput(
                  prefix: field.$1,
                  formula: field.$2,
                  value: field.$4,
                  placeholder: field.$5,
                  label: field.$1,
                  dark: dark,
                  onChanged: (value) => onChanged(column, field.$3, value),
                ),
              ),
          ],
        );
      },
    );
  }
}

Widget _buildElectronResults(bool dark) {
  return Builder(
    builder: (context) {
      final page = context
          .findAncestorStateOfType<_PhysicsElectronChargePageState>()!;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _renderDeflectionResults(
            page._calculation.electric,
            '1. 电偏转趋势图',
            dark,
            page._exportChart,
          ),
          const SizedBox(height: 16),
          _renderElectroFocusResults(page._calculation.electroFocus, dark),
          const SizedBox(height: 16),
          _renderDeflectionResults(
            page._calculation.magnetic,
            '3. 磁偏转趋势图',
            dark,
            page._exportChart,
          ),
          const SizedBox(height: 16),
          _renderMagneticFocusResults(page._calculation.magneticFocus, dark),
        ],
      );
    },
  );
}

Widget _renderDeflectionResults(
  List<ElectronChargeDeflectionResult> results,
  String heading,
  bool dark,
  Future<void> Function(ElectronChargeDeflectionResult) onExport,
) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _electronResultHeading(heading, dark),
      const SizedBox(height: 9),
      LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth < 700 ? 1 : 2;
          final width = columns == 1
              ? constraints.maxWidth
              : (constraints.maxWidth - 10) / 2;
          return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final result in results)
                SizedBox(
                  width: width,
                  child: _DeflectionResultCard(
                    result: result,
                    dark: dark,
                    onExport: onExport,
                  ),
                ),
            ],
          );
        },
      ),
    ],
  );
}

class _DeflectionResultCard extends StatelessWidget {
  const _DeflectionResultCard({
    required this.result,
    required this.dark,
    required this.onExport,
  });

  final ElectronChargeDeflectionResult result;
  final bool dark;
  final Future<void> Function(ElectronChargeDeflectionResult) onExport;

  @override
  Widget build(BuildContext context) {
    final definition = result.definition;
    return _electronCard(
      dark: dark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _electronTitle(definition.titlePrefix, definition.titleFormula, dark),
          const SizedBox(height: 8),
          _electronTable(
            minWidth: 300,
            dark: dark,
            headers: [
              _tablePlainHeader('组数', dark),
              _tableMathHeader(definition.xFormula, dark),
              _tableMathHeader(definition.yFormula, dark),
              _tableMathHeader(definition.ratioFormula, dark),
            ],
            rows: [
              for (final point in result.points)
                [
                  _tableText('${point.index + 1}', dark),
                  _tableText(_format(point.x), dark),
                  _tableText(_format(point.y), dark),
                  _tableText(_format(point.ratio), dark),
                ],
            ],
          ),
          const SizedBox(height: 8),
          ElectronChargeTrendChart(result: result, dark: dark),
          if (result.hasChart) ...[
            const SizedBox(height: 7),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton(
                onPressed: () => onExport(result),
                child: const Text('下载此图 PDF'),
                style: physicsSecondaryButtonStyle(context),
              ),
            ),
          ],
          const SizedBox(height: 7),
          _renderDeflectionSummary(result, dark),
        ],
      ),
    );
  }
}

Widget _renderDeflectionSummary(
  ElectronChargeDeflectionResult result,
  bool dark,
) {
  final definition = result.definition;
  final children = <Widget>[];
  if (result.fit.complete) {
    children
      ..add(
        _summaryLine(
          '趋势线斜率',
          result.fit.slope!,
          r'S',
          definition.slopeUnit,
          '单位：',
          dark,
        ),
      )
      ..add(
        _summaryLine(
          '趋势线截距',
          result.fit.intercept!,
          '',
          definition.yUnit,
          '单位：',
          dark,
        ),
      )
      ..add(_equationLine(result, dark));
  } else {
    children.add(_emptyText(result.fit.error ?? '趋势线未生成。', dark));
  }
  if (result.averageY != null) {
    children.add(
      _summaryLine(
        '平均偏转',
        result.averageY!,
        r'\overline D',
        definition.yUnit,
        '单位：',
        dark,
      ),
    );
  }
  if (result.summary.complete) {
    children
      ..add(
        _summaryLine(
          '非零点平均横坐标',
          result.summary.averageX!,
          '\\overline{${definition.xSymbol}}',
          definition.xUnit,
          '单位：',
          dark,
        ),
      )
      ..add(
        _summaryLine(
          '逐项比值平均',
          result.summary.ratio!,
          '\\overline{${definition.ratioFormula}}',
          '',
          '非零点数据的平均值',
          dark,
        ),
      )
      ..add(
        _summaryLine(
          '平均值之比',
          result.summary.ratioOfAverages!,
          definition.ratioOfAveragesFormula,
          '',
          '平均偏转与平均横坐标之比',
          dark,
        ),
      );
  }
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: children,
  );
}

Widget _equationLine(ElectronChargeDeflectionResult result, bool dark) {
  final intercept = result.fit.intercept!;
  final sign = intercept.coefficient < BigInt.zero ? '-' : '+';
  final visible = !intercept.isZero;
  final equation =
      '${result.definition.ySymbol}=${_format(result.fit.slope)}\\,${result.definition.xSymbol}${visible ? '$sign${_format(intercept.abs())}' : ''}';
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: _math(equation, dark, fontSize: 14),
  );
}

Widget _renderElectroFocusResults(ElectronChargeFocusResult result, bool dark) {
  final valid = result.validRows;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _electronResultHeading('电聚焦：', dark, formula: r'U_2/U_1'),
      const SizedBox(height: 9),
      _electronTable(
        minWidth: 300,
        dark: dark,
        headers: [
          _tablePlainHeader('组数', dark),
          _tableMathHeader(r'U_2\,/\,\mathrm{V}', dark),
          _tableMathHeader(r'U_1\,/\,\mathrm{V}', dark),
          _tableMathHeader(r'U_2/U_1', dark),
        ],
        rows: [
          for (final row in result.rows)
            [
              _tableText('${row.index + 1}', dark),
              _tableText(_format(row.u2), dark),
              _tableText(_format(row.u1), dark),
              _tableText(_format(row.ratio), dark),
            ],
        ],
      ),
      if (valid.isEmpty)
        _emptyText('填写完整数据后显示比值和平均值。', dark)
      else ...[
        _summaryLine('合计', result.sumU2!, r'\sum U_2', '', '五组数据之和', dark),
        _summaryLine('合计', result.sumU1!, r'\sum U_1', '', '五组数据之和', dark),
        _summaryLine(
          '平均值',
          result.averageU2!,
          r'\overline{U_2}',
          '',
          '五组数据的算术平均',
          dark,
        ),
        _summaryLine(
          '平均值',
          result.averageU1!,
          r'\overline{U_1}',
          '',
          '五组数据的算术平均',
          dark,
        ),
        _summaryLine(
          '比值平均值',
          result.averageRatio!,
          r'\overline{U_2/U_1}',
          '',
          '五个比值的平均值',
          dark,
        ),
        if (result.totalRatio != null)
          _summaryLine(
            '合计之比',
            result.totalRatio!,
            r'\frac{\sum U_2}{\sum U_1}',
            '',
            '两列数据合计之比',
            dark,
          ),
      ],
    ],
  );
}

Widget _renderMagneticFocusResults(
  List<ElectronChargeMagneticFocusResult> results,
  bool dark,
) {
  Widget value(ElectronChargeMagneticFocusResult result, String key) {
    return _tableText(_format(result.valueFor(key)), dark);
  }

  final rows =
      <(String, String, Widget Function(ElectronChargeMagneticFocusResult))>[
        ('U_2\\,/\\,\\mathrm{V}', '', (result) => value(result, 'u2')),
        ('I_+\\,/\\,\\mathrm{A}', '正向电流', (result) => value(result, 'forward')),
        ('I_-\\,/\\,\\mathrm{A}', '反向电流', (result) => value(result, 'reverse')),
        (
          r'\overline I\,/\,\mathrm{A}',
          '平均电流',
          (result) => _tableText(_format(result.averageCurrent), dark),
        ),
        ('L\\,/\\,\\mathrm{m}', '螺线管长度', (result) => value(result, 'L')),
        (
          'L^2\\,/\\,\\mathrm{m^2}',
          '',
          (result) => _tableText(_format(result.lengthSquare), dark),
        ),
        ('D\\,/\\,\\mathrm{m}', '螺线管平均直径', (result) => value(result, 'D')),
        (
          'D^2\\,/\\,\\mathrm{m^2}',
          '',
          (result) => _tableText(_format(result.diameterSquare), dark),
        ),
        ('h\\,/\\,\\mathrm{m}', '螺距', (result) => value(result, 'h')),
        (
          'h^2\\,/\\,\\mathrm{m^2}',
          '',
          (result) => _tableText(_format(result.pitchSquare), dark),
        ),
        ('N', '线圈匝数', (result) => value(result, 'N')),
        ('N^2', '', (result) => _tableText(_format(result.turnsSquare), dark)),
        (
          '\\mu_0\\,/\\,\\mathrm{N\\,A^{-2}}',
          '真空磁导率',
          (result) => value(result, 'mu0'),
        ),
        (
          '\\mu_0^2\\,/\\,(\\mathrm{N\\,A^{-2}})^2',
          '',
          (result) => _tableText(_format(result.mu0Square), dark),
        ),
        (
          'e/m\\,/\\,\\mathrm{C\\,kg^{-1}}',
          '电子荷质比',
          (result) => _tableText(_format(result.chargeMass), dark),
        ),
        (
          '(e/m)_0\\,/\\,\\mathrm{C\\,kg^{-1}}',
          '比荷标准值',
          (result) => value(result, 'standard'),
        ),
        (
          '\\varepsilon',
          '相对误差',
          (result) => _tableText(_format(result.relativeError), dark),
        ),
        (
          '\\varepsilon\\,/\\,\\%',
          '相对误差 / %',
          (result) => _tableText(_formatPercent(result.relativeError), dark),
        ),
      ];
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _electronResultHeading('磁聚焦与荷质比', dark),
      const SizedBox(height: 9),
      _electronTable(
        minWidth: 300,
        dark: dark,
        headers: [
          _tablePlainHeader('项目', dark),
          for (final result in results)
            result.u2 == null
                ? _tablePlainHeader('第 ${result.index + 1} 列', dark)
                : _tableMathHeader(
                    'U_2=${_format(result.u2)}\\,\\mathrm{V}',
                    dark,
                  ),
        ],
        rows: [
          for (final row in rows)
            [
              _tableMixedLabel(row.$2, row.$1, dark),
              for (final result in results) row.$3(result),
            ],
        ],
      ),
      if (results.any((result) => !result.complete))
        _emptyText('两列磁聚焦数据填写完整后显示荷质比。', dark),
    ],
  );
}

Widget _electronCard({required bool dark, required Widget child}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(9),
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
    child: child,
  );
}

Widget _electronTitle(String prefix, String formula, bool dark) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(prefix, style: _electronTitleStyle(dark)),
      _math(formula, dark, fontSize: 12, weight: FontWeight.w700),
    ],
  );
}

Widget _electronResultHeading(String text, bool dark, {String? formula}) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(text, style: _electronResultHeadingStyle(dark)),
      if (formula != null)
        _math(formula, dark, fontSize: 13, weight: FontWeight.w700),
    ],
  );
}

Widget _electronLabeledInput({
  required String prefix,
  required String formula,
  required String value,
  required String label,
  required bool dark,
  required ValueChanged<String> onChanged,
  String placeholder = '',
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (prefix.isNotEmpty) ...[
              Text(prefix, style: _electronFieldLabelStyle(dark)),
              const SizedBox(width: 4),
            ],
            _math(
              formula,
              dark,
              fontSize: 11,
              weight: FontWeight.w700,
              scrollable: false,
            ),
          ],
        ),
      ),
      const SizedBox(height: 5),
      _ElectronTextField(
        key: ValueKey<String>('electron-field-$label-$formula'),
        value: value,
        label: label,
        placeholder: placeholder,
        dark: dark,
        onChanged: onChanged,
      ),
    ],
  );
}

Widget _electronTable({
  required double minWidth,
  required bool dark,
  required List<Widget> headers,
  required List<List<Widget>> rows,
}) {
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

Widget _tablePlainHeader(String text, bool dark) {
  return _tableCell(
    Text(text, textAlign: TextAlign.center, style: _tableHeaderStyle(dark)),
  );
}

Widget _tableMathHeader(String formula, bool dark) {
  return _tableCell(
    _math(formula, dark, fontSize: 12, weight: FontWeight.w700),
  );
}

Widget _tableMixedLabel(String prefix, String formula, bool dark) {
  return _tableCell(
    SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (prefix.isNotEmpty) ...[
            Text(prefix, style: _tableCellStyle(dark)),
            const SizedBox(width: 4),
          ],
          _math(
            formula,
            dark,
            fontSize: 12,
            weight: FontWeight.w700,
            scrollable: false,
          ),
        ],
      ),
    ),
  );
}

Widget _tableText(String text, bool dark) {
  return _tableCell(
    Text(text, textAlign: TextAlign.center, style: _tableCellStyle(dark)),
  );
}

Widget _tableInput({
  required String key,
  required String value,
  required String label,
  required bool dark,
  required ValueChanged<String> onChanged,
  String placeholder = '',
}) {
  return _tableCell(
    _ElectronTextField(
      key: ValueKey<String>(key),
      value: value,
      label: label,
      placeholder: placeholder,
      dark: dark,
      onChanged: onChanged,
    ),
  );
}

Widget _tableCell(Widget child) {
  return Container(
    constraints: const BoxConstraints(minHeight: 34),
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
    alignment: Alignment.center,
    child: child,
  );
}

class _ElectronTextField extends StatefulWidget {
  const _ElectronTextField({
    super.key,
    required this.value,
    required this.label,
    required this.dark,
    required this.onChanged,
    this.placeholder = '',
  });

  final String value;
  final String label;
  final bool dark;
  final ValueChanged<String> onChanged;
  final String placeholder;

  @override
  State<_ElectronTextField> createState() => _ElectronTextFieldState();
}

class _ElectronTextFieldState extends State<_ElectronTextField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _ElectronTextField oldWidget) {
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
        width: double.infinity,
        height: 28,
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
              horizontal: 5,
              vertical: 5,
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

Widget _math(
  String formula,
  bool dark, {
  double fontSize = 14,
  FontWeight? weight,
  Color? color,
  bool scrollable = true,
}) {
  final child = Math.tex(
    formula,
    mathStyle: MathStyle.text,
    textStyle: TextStyle(
      color:
          color ?? (dark ? const Color(0xFFB7D9ED) : const Color(0xFF334F65)),
      fontSize: fontSize,
      fontWeight: weight,
      height: 1.3,
    ),
    onErrorFallback: (_) => const SizedBox.shrink(),
  );
  if (!scrollable) return child;
  return SingleChildScrollView(scrollDirection: Axis.horizontal, child: child);
}

Widget _summaryLine(
  String label,
  PhysicsDecimal value,
  String formula,
  String unit,
  String note,
  bool dark,
) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 560;
        final labelWidget = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: _summaryLabelStyle(dark)),
            if (formula.isNotEmpty) ...[
              const SizedBox(width: 5),
              _math(formula, dark, fontSize: 13, weight: FontWeight.w700),
            ],
          ],
        );
        final valueWidget = Text(
          _format(value),
          style: TextStyle(
            color: dark ? const Color(0xFF8FD2FF) : const Color(0xFF176496),
            fontSize: 13,
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        );
        final noteWidget = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (note.isNotEmpty) Text(note, style: _noteStyle(dark)),
            if (unit.isNotEmpty) ...[
              if (note.isNotEmpty) const SizedBox(width: 4),
              _math(unit, dark, fontSize: 11, scrollable: false),
            ],
          ],
        );
        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              labelWidget,
              const SizedBox(height: 2),
              valueWidget,
              noteWidget,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 150),
              child: labelWidget,
            ),
            Expanded(child: valueWidget),
            Flexible(child: noteWidget),
          ],
        );
      },
    ),
  );
}

Widget _emptyText(String text, bool dark) {
  return Padding(
    padding: const EdgeInsets.only(top: 7),
    child: Text(text, style: _noteStyle(dark)),
  );
}

String _format(PhysicsDecimal? value) => value?.format() ?? '—';

String _formatPercent(PhysicsDecimal? value) {
  if (value == null) return '—';
  return '${(value * PhysicsDecimal.fromInt(100)).format()}%';
}

TextStyle _electronTitleStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFF9DDCFF) : const Color(0xFF275B7A),
  fontSize: 12,
  fontWeight: FontWeight.w700,
  height: 1.3,
);

TextStyle _electronResultHeadingStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFF9DDCFF) : const Color(0xFF275B7A),
  fontSize: 13,
  fontWeight: FontWeight.w700,
  height: 1.3,
);

TextStyle _electronFieldLabelStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFFB9E2F7) : const Color(0xFF527087),
  fontSize: 11,
  fontWeight: FontWeight.w700,
  height: 1.3,
);

TextStyle _tableHeaderStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFFD6E6F3) : const Color(0xFF5D7487),
  fontSize: 12,
  fontWeight: FontWeight.w700,
  height: 1.25,
);

TextStyle _tableCellStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFFB7D9ED) : const Color(0xFF334F65),
  fontSize: 12,
  height: 1.25,
);

TextStyle _summaryLabelStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFF9EACC3) : const Color(0xFF527087),
  fontSize: 12,
  fontWeight: FontWeight.w600,
  height: 1.3,
);

TextStyle _noteStyle(bool dark) => TextStyle(
  color: EcjtuColors.platformMuted(
    dark,
    (dark ? const Color(0xFF9EACC3) : const Color(0xFF667B8E)),
  ),
  fontSize: 11,
  height: 1.3,
);
