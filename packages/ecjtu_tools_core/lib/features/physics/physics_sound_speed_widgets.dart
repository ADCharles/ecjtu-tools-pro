// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

part of 'physics_sound_speed_page.dart';

Widget _soundFormulaBlock(bool dark) {
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
        Text('计算公式', style: _soundFormulaTitleStyle(dark)),
        const SizedBox(height: 7),
        _SoundFormulaLine(
          number: '1.',
          formula: r'v_{\mathrm{theory}}=331.45\sqrt{1+\frac{t}{273.15}}',
          dark: dark,
        ),
        _SoundFormulaLine(
          number: '2.',
          formula: r'\Delta x_i=x_{i+5}-x_i\qquad u=0.4f\overline{\Delta x}',
          dark: dark,
        ),
        _SoundFormulaLine(
          number: '3.',
          formula:
              r'\sigma_u=u\sqrt{\left(\frac{\sigma_{\Delta x}}{\overline{\Delta x}}\right)^2+\left(\frac{\sigma_f}{f}\right)^2}',
          dark: dark,
        ),
      ],
    ),
  );
}

class _SoundFormulaLine extends StatelessWidget {
  const _SoundFormulaLine({
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
            child: Text(number, style: _soundFormulaNumberStyle(dark)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _soundMath(
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

Widget _soundSection({
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
        Text(title, style: _soundSectionTitleStyle(dark)),
        const SizedBox(height: 12),
        child,
      ],
    ),
  );
}

class _SoundInputContent extends StatelessWidget {
  const _SoundInputContent({
    required this.state,
    required this.dark,
    required this.onGlobalChanged,
    required this.onMeasurementChanged,
  });

  final SoundSpeedState state;
  final bool dark;
  final void Function(String field, String value) onGlobalChanged;
  final void Function(String method, int index, String value)
  onMeasurementChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth < 560 ? 1 : 3;
            final gap = 10.0;
            final width = columns == 1
                ? constraints.maxWidth
                : (constraints.maxWidth - gap * (columns - 1)) / columns;
            final fields = [
              ('频率', r'f', '（kHz）', 'frequency', state.frequency, '请输入'),
              (
                '频率不确定度',
                r'\sigma_f',
                '（kHz）',
                'frequencyUncertainty',
                state.frequencyUncertainty,
                SoundSpeedState.defaultFrequencyUncertainty,
              ),
              ('温度', r't', '（℃）', 'temperature', state.temperature, '请输入'),
            ];
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final field in fields)
                  SizedBox(
                    width: width,
                    child: _SoundLabeledInput(
                      key: ValueKey<String>('sound-global-${field.$4}'),
                      prefix: field.$1,
                      formula: field.$2,
                      suffix: field.$3,
                      value: field.$5,
                      placeholder: field.$6,
                      dark: dark,
                      onChanged: (value) => onGlobalChanged(field.$4, value),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 10),
        _SoundMethodInput(
          title: '驻波法',
          method: 'standing',
          values: state.standing,
          dark: dark,
          onChanged: onMeasurementChanged,
        ),
        const SizedBox(height: 10),
        _SoundMethodInput(
          title: '相位法',
          method: 'phase',
          values: state.phase,
          dark: dark,
          onChanged: onMeasurementChanged,
        ),
      ],
    );
  }
}

class _SoundLabeledInput extends StatelessWidget {
  const _SoundLabeledInput({
    super.key,
    required this.prefix,
    required this.formula,
    required this.suffix,
    required this.value,
    required this.placeholder,
    required this.dark,
    required this.onChanged,
  });

  final String prefix;
  final String formula;
  final String suffix;
  final String value;
  final String placeholder;
  final bool dark;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _soundMixedLabel(
          prefix: prefix,
          formula: formula,
          suffix: suffix,
          dark: dark,
        ),
        const SizedBox(height: 5),
        _SoundTextField(
          value: value,
          placeholder: placeholder,
          label: '$prefix$suffix',
          dark: dark,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

Widget _soundMixedLabel({
  required String prefix,
  required String formula,
  required String suffix,
  required bool dark,
}) {
  return Wrap(
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: 4,
    children: [
      Text(prefix, style: _soundFieldLabelStyle(dark)),
      _soundMath(
        formula,
        dark,
        fontSize: 12,
        color: EcjtuColors.platformMuted(
          dark,
          (dark ? const Color(0xFF9EACC3) : const Color(0xFF667B8E)),
        ),
      ),
      Text(suffix, style: _soundFieldLabelStyle(dark)),
    ],
  );
}

class _SoundMethodInput extends StatelessWidget {
  const _SoundMethodInput({
    required this.title,
    required this.method,
    required this.values,
    required this.dark,
    required this.onChanged,
  });

  final String title;
  final String method;
  final List<String> values;
  final bool dark;
  final void Function(String method, int index, String value) onChanged;

  @override
  Widget build(BuildContext context) {
    final labelWidth = MediaQuery.sizeOf(context).width <= 560 ? 58.0 : 78.0;
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
          Text(title, style: _soundMethodTitleStyle(dark)),
          const SizedBox(height: 7),
          Column(
            children: [
              _soundInputBlock(
                dark: dark,
                method: method,
                title: title,
                values: values,
                start: 0,
                labelWidth: labelWidth,
                onChanged: onChanged,
              ),
              const SizedBox(height: 8),
              _soundInputBlock(
                dark: dark,
                method: method,
                title: title,
                values: values,
                start: SoundSpeedState.differenceCount,
                labelWidth: labelWidth,
                onChanged: onChanged,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Widget _soundInputBlock({
  required bool dark,
  required String method,
  required String title,
  required List<String> values,
  required int start,
  required double labelWidth,
  required void Function(String method, int index, String value) onChanged,
}) {
  return Container(
    width: double.infinity,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      border: Border.all(
        color: EcjtuColors.platformBorder(
          dark,
          (dark ? const Color(0xFF31546B) : const Color(0xFFD5E4EF)),
        ),
      ),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Column(
      children: [
        _soundInputRow(
          dark: dark,
          labelWidth: labelWidth,
          label: Text('位置', style: _soundInputLabelStyle(dark)),
          values: List<Widget>.generate(
            SoundSpeedState.differenceCount,
            (index) => _soundMath(
              'x_{${start + index + 1}}',
              dark,
              fontSize: 12,
              weight: FontWeight.w700,
              color: dark ? const Color(0xFFD6E6F3) : const Color(0xFF5D7487),
            ),
          ),
          header: true,
        ),
        _soundInputRow(
          dark: dark,
          labelWidth: labelWidth,
          label: _soundMath(
            r'x\,/\,\mathrm{mm}',
            dark,
            fontSize: 11,
            weight: FontWeight.w700,
            color: EcjtuColors.platformText(
              dark,
              (dark ? const Color(0xFFD6E6F3) : const Color(0xFF275B7A)),
            ),
          ),
          values: List<Widget>.generate(
            SoundSpeedState.differenceCount,
            (index) => _SoundTextField(
              key: ValueKey<String>('sound-$method-${start + index}'),
              value: values[start + index],
              label: '$title 第 ${start + index + 1} 个位置',
              dark: dark,
              compact: true,
              placeholder: '输入',
              onChanged: (value) => onChanged(method, start + index, value),
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _soundInputRow({
  required bool dark,
  required Widget label,
  required List<Widget> values,
  double labelWidth = 78,
  bool header = false,
}) {
  return SizedBox(
    height: 38,
    child: Row(
      children: [
        _soundGridCell(
          dark: dark,
          width: labelWidth,
          header: header,
          labelCell: true,
          labelHeader: false,
          child: label,
        ),
        for (final value in values)
          Expanded(
            child: _soundGridCell(dark: dark, header: header, child: value),
          ),
      ],
    ),
  );
}

Widget _soundGridCell({
  required bool dark,
  required Widget child,
  bool header = false,
  bool labelCell = false,
  bool labelHeader = false,
  double? width,
}) {
  final content = Container(
    width: width,
    height: 38,
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: labelCell
          ? labelHeader
                ? (dark ? const Color(0xFF14263A) : const Color(0xFFEEF6FA))
                : (dark ? const Color(0xFF14263A) : const Color(0xFFF4F9FC))
          : header
          ? (dark ? const Color(0xFF14263A) : const Color(0xFFEEF6FA))
          : (EcjtuColors.platformSurface(
              dark,
              (dark ? const Color(0xFF101D31) : Colors.white),
            )),
      border: Border(
        left: labelCell
            ? BorderSide.none
            : BorderSide(
                color: dark ? const Color(0xFF28465C) : const Color(0xFFE5EDF2),
              ),
      ),
    ),
    child: child,
  );
  return content;
}

class _SoundOutputContent extends StatelessWidget {
  const _SoundOutputContent({
    required this.calculation,
    required this.dark,
    required this.saving,
    required this.onSave,
  });

  final SoundSpeedCalculation calculation;
  final bool dark;
  final bool saving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (calculation.error.isNotEmpty)
          Text(calculation.error, style: _soundEmptyTextStyle(dark))
        else ...[
          _soundTheoryBox(calculation, dark),
          const SizedBox(height: 18),
          _SoundMethodResult(
            title: '驻波法',
            calculation: calculation.standing,
            dark: dark,
          ),
          const SizedBox(height: 18),
          _SoundMethodResult(
            title: '相位法',
            calculation: calculation.phase,
            dark: dark,
          ),
        ],
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: saving ? null : onSave,
          child: Text(saving ? '正在保存' : '保存数据'),
          style: physicsSecondaryButtonStyle(context),
        ),
      ],
    );
  }
}

Widget _soundTheoryBox(SoundSpeedCalculation calculation, bool dark) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
    decoration: BoxDecoration(
      color: dark ? const Color(0xFF14263A) : const Color(0xFFEEF7FC),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      '空气中声速理论值：${SoundSpeedCalculator.format(calculation.theorySpeed)} m/s',
      style: _soundTheoryTextStyle(dark),
    ),
  );
}

class _SoundMethodResult extends StatelessWidget {
  const _SoundMethodResult({
    required this.title,
    required this.calculation,
    required this.dark,
  });

  final String title;
  final SoundSpeedMethodCalculation calculation;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: _soundMethodResultTitleStyle(dark)),
        const SizedBox(height: 13),
        if (!calculation.complete)
          Text(calculation.message, style: _soundEmptyTextStyle(dark))
        else ...[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 620,
              child: Column(
                children: [
                  _soundResultRow(
                    dark: dark,
                    label: Text('数据项', style: _soundResultHeaderStyle(dark)),
                    values: List<Widget>.generate(
                      SoundSpeedState.differenceCount,
                      (index) => _soundMath(
                        '\\Delta x_{${index + 1}}',
                        dark,
                        fontSize: 12,
                        weight: FontWeight.w700,
                        color: dark
                            ? const Color(0xFFD6E6F3)
                            : const Color(0xFF5D7487),
                      ),
                    ),
                    header: true,
                  ),
                  _soundResultRow(
                    dark: dark,
                    label: _soundMath(
                      r'\Delta x\,/\,\mathrm{mm}',
                      dark,
                      fontSize: 11,
                      weight: FontWeight.w700,
                      color: EcjtuColors.platformText(
                        dark,
                        (dark
                            ? const Color(0xFFD6E6F3)
                            : const Color(0xFF275B7A)),
                      ),
                    ),
                    values: calculation.differences
                        .map(
                          (value) => Text(
                            SoundSpeedCalculator.format(value),
                            textAlign: TextAlign.center,
                            style: _soundCellTextStyle(dark),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 13),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: dark ? const Color(0xFF14263A) : const Color(0xFFEEF5FA),
              border: Border(
                left: BorderSide(
                  color: dark
                      ? const Color(0xFF6DA8D0)
                      : const Color(0xFF6DA8D0),
                  width: 3,
                ),
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _soundMathResult(
                  r'\overline{\Delta x}=' +
                      SoundSpeedCalculator.format(calculation.average) +
                      r'\,\mathrm{mm}',
                  dark,
                ),
                _soundMathResult(
                  r'\sigma_{\Delta x}=' +
                      SoundSpeedCalculator.format(calculation.sigmaDifference) +
                      r'\,\mathrm{mm}',
                  dark,
                ),
                _soundMathResult(
                  r'u=0.4f\overline{\Delta x}=' +
                      SoundSpeedCalculator.format(calculation.speed) +
                      r'\,\mathrm{m/s}',
                  dark,
                ),
                _soundMathResult(
                  r'\sigma_u=' +
                      SoundSpeedCalculator.format(calculation.sigmaSpeed) +
                      r'\,\mathrm{m/s}',
                  dark,
                ),
                _soundMathResult(
                  r'E=' +
                      SoundSpeedCalculator.format(calculation.relativeError) +
                      r'\%',
                  dark,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

Widget _soundResultRow({
  required bool dark,
  required Widget label,
  required List<Widget> values,
  bool header = false,
}) {
  return SizedBox(
    height: 38,
    child: Row(
      children: [
        SizedBox(
          width: 145,
          child: _soundGridCell(
            dark: dark,
            header: header,
            labelCell: true,
            labelHeader: header,
            child: label,
          ),
        ),
        for (final value in values)
          Expanded(
            child: _soundGridCell(dark: dark, header: header, child: value),
          ),
      ],
    ),
  );
}

Widget _soundMathResult(String formula, bool dark) {
  return SizedBox(
    height: 28,
    child: Align(
      alignment: Alignment.centerLeft,
      child: _soundMath(formula, dark, fontSize: 13),
    ),
  );
}

class _SoundTextField extends StatefulWidget {
  const _SoundTextField({
    super.key,
    required this.value,
    required this.label,
    required this.dark,
    required this.onChanged,
    this.placeholder = '',
    this.compact = false,
  });

  final String value;
  final String label;
  final bool dark;
  final ValueChanged<String> onChanged;
  final String placeholder;
  final bool compact;

  @override
  State<_SoundTextField> createState() => _SoundTextFieldState();
}

class _SoundTextFieldState extends State<_SoundTextField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _SoundTextField oldWidget) {
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
    final height = widget.compact ? 29.0 : 34.0;
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
              horizontal: widget.compact ? 5 : 8,
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

Widget _soundMath(
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
            color ??
            (EcjtuColors.platformText(
              dark,
              (dark ? const Color(0xFFE1EDFF) : const Color(0xFF223549)),
            )),
        fontSize: fontSize,
        fontWeight: weight,
        height: 1.35,
      ),
      onErrorFallback: (_) => const SizedBox.shrink(),
    ),
  );
}

TextStyle _soundSectionTitleStyle(bool dark) => TextStyle(
  color: EcjtuColors.platformText(
    dark,
    (dark ? const Color(0xFFE1EDFF) : const Color(0xFF223549)),
  ),
  fontSize: 13,
  fontWeight: FontWeight.w700,
  height: 1.3,
);

TextStyle _soundFormulaTitleStyle(bool dark) => TextStyle(
  color: EcjtuColors.platformText(
    dark,
    (dark ? const Color(0xFFD6E6F3) : const Color(0xFF275B7A)),
  ),
  fontSize: 12,
  fontWeight: FontWeight.w700,
  height: 1.3,
);

TextStyle _soundFormulaNumberStyle(bool dark) => TextStyle(
  color: EcjtuColors.platformText(
    dark,
    (dark ? const Color(0xFFE1EDFF) : const Color(0xFF223549)),
  ),
  fontSize: 16,
  fontWeight: FontWeight.w500,
  height: 1.2,
);

TextStyle _soundInputLabelStyle(bool dark) => TextStyle(
  color: EcjtuColors.platformText(
    dark,
    (dark ? const Color(0xFFD6E6F3) : const Color(0xFF275B7A)),
  ),
  fontSize: 12,
  fontWeight: FontWeight.w700,
  height: 1.2,
);

TextStyle _soundResultHeaderStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFFD6E6F3) : const Color(0xFF5D7487),
  fontSize: 12,
  fontWeight: FontWeight.w700,
  height: 1.2,
);

TextStyle _soundMethodTitleStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFF9DDCFF) : const Color(0xFF275B7A),
  fontSize: 12,
  fontWeight: FontWeight.w700,
  height: 1.3,
);

TextStyle _soundMethodResultTitleStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFFB7D9ED) : const Color(0xFF275B7A),
  fontSize: 13,
  fontWeight: FontWeight.w700,
  height: 1.3,
);

TextStyle _soundFieldLabelStyle(bool dark) => TextStyle(
  color: EcjtuColors.platformMuted(
    dark,
    (dark ? const Color(0xFF9EACC3) : const Color(0xFF667B8E)),
  ),
  fontSize: 11,
  fontWeight: FontWeight.w400,
  height: 1.3,
);

TextStyle _soundCellTextStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFFB7D9ED) : const Color(0xFF334F65),
  fontSize: 11,
  height: 1.25,
);

TextStyle _soundEmptyTextStyle(bool dark) => TextStyle(
  color: EcjtuColors.platformMuted(
    dark,
    (dark ? const Color(0xFF9EACC3) : const Color(0xFF667B8E)),
  ),
  fontSize: 11,
  height: 1.5,
);

TextStyle _soundTheoryTextStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFF8FD2FF) : const Color(0xFF176496),
  fontSize: 12,
  fontWeight: FontWeight.w700,
  height: 1.4,
);
