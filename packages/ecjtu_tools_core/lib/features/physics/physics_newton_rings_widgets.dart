// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

part of 'physics_newton_rings_page.dart';

class _FormulaBlock extends StatelessWidget {
  const _FormulaBlock({required this.dark});

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
          const SizedBox(height: 8),
          _FormulaLine(
            '1.',
            r'D_i=\left|X_{\mathrm{L},i}-X_{\mathrm{R},i}\right|',
            dark,
          ),
          _FormulaLine('2.', r'D_i^2=D_i\times D_i', dark),
          _FormulaLine('3.', r'\Delta_i=D_{m,i}^{2}-D_{n,i}^{2}', dark),
          _FormulaLine(
            '4.',
            r'\overline{\Delta}=\frac{1}{5}\sum_{i=1}^{5}\Delta_i,\quad e=\frac{1}{5}\sum_{i=1}^{5}\left|\Delta_i-\overline{\Delta}\right|',
            dark,
          ),
          _FormulaLine(
            '5.',
            r'R=\frac{\overline{\Delta}}{4(m-n)\lambda},\quad \Delta R=\frac{e}{4(m-n)\lambda}',
            dark,
          ),
        ],
      ),
    );
  }
}

class _FormulaLine extends StatelessWidget {
  const _FormulaLine(this.index, this.formula, this.dark);

  final String index;
  final String formula;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 42),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 28,
            child: Text(
              index,
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
          Expanded(child: _displayMath(formula, dark)),
        ],
      ),
    );
  }
}

class _PhysicsCalculatorSection extends StatelessWidget {
  const _PhysicsCalculatorSection({
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

class _ParameterField extends StatelessWidget {
  const _ParameterField({
    required this.label,
    required this.formula,
    required this.value,
    required this.placeholder,
    required this.dark,
    required this.onChanged,
  });

  final String label;
  final String formula;
  final String value;
  final String placeholder;
  final bool dark;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: _fieldLabelStyle(dark)),
            const SizedBox(width: 4),
            _math(formula, dark, fontSize: 13, color: _fieldLabelColor(dark)),
          ],
        ),
        const SizedBox(height: 5),
        _NewtonTextField(
          value: value,
          label: '$label $formula',
          placeholder: placeholder,
          fullWidth: true,
          height: 32,
          dark: dark,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _NewtonTextField extends StatefulWidget {
  const _NewtonTextField({
    super.key,
    required this.value,
    required this.label,
    required this.dark,
    required this.onChanged,
    this.placeholder = '',
    this.fullWidth = false,
    this.height = 30,
  });

  final String value;
  final String label;
  final bool dark;
  final ValueChanged<String> onChanged;
  final String placeholder;
  final bool fullWidth;
  final double height;

  @override
  State<_NewtonTextField> createState() => _NewtonTextFieldState();
}

class _NewtonTextFieldState extends State<_NewtonTextField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _NewtonTextField oldWidget) {
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
    return SizedBox(
      width: widget.fullWidth ? double.infinity : 88,
      height: widget.height,
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
            fontSize: 12,
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
            borderSide: const BorderSide(color: Color(0xFF287AA8)),
          ),
        ),

        contextMenuBuilder: buildEcjtuPlatformTextContextMenu,
      ),
    );
  }
}

class _ScrollableTable extends StatelessWidget {
  const _ScrollableTable({
    required this.minWidth,
    required this.borderColor,
    required this.child,
  });

  final double minWidth;
  final Color borderColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        width: minWidth,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF101D31)
              : Colors.white,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(7),
        ),
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }
}

TableCell _tableCell(
  Widget child, {
  double minHeight = 34,
  Color? backgroundColor,
  EdgeInsetsGeometry padding = const EdgeInsets.symmetric(
    horizontal: 5,
    vertical: 3,
  ),
}) {
  return TableCell(
    child: Container(
      constraints: BoxConstraints(minHeight: minHeight),
      padding: padding,
      color: backgroundColor,
      alignment: Alignment.center,
      child: child,
    ),
  );
}

TableCell _resultTableCell(Widget child) {
  return _tableCell(
    child,
    minHeight: 32,
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
  );
}

Widget _headerCell(String text, bool dark, {bool result = false}) {
  return _tableCell(
    Text(text, textAlign: TextAlign.center, style: _headerTextStyle(dark)),
    minHeight: result ? 32 : 34,
    padding: result
        ? const EdgeInsets.symmetric(horizontal: 6, vertical: 5)
        : const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
  );
}

Widget _headerCellWithMath(
  String text,
  String formula,
  bool dark, {
  bool result = false,
}) {
  return _tableCell(
    Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (text.isNotEmpty) ...[
          Flexible(
            child: Text(
              text,
              textAlign: TextAlign.center,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: _headerTextStyle(dark),
            ),
          ),
          const SizedBox(width: 3),
        ],
        Flexible(
          child: _math(
            formula,
            dark,
            fontSize: 11,
            color: _headerTextColor(dark),
          ),
        ),
      ],
    ),
    minHeight: result ? 32 : 34,
    padding: result
        ? const EdgeInsets.symmetric(horizontal: 6, vertical: 5)
        : const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
  );
}

Widget _resultHeading(String title, bool dark) {
  return Text(
    title,
    style: TextStyle(
      color: dark ? const Color(0xFF9DDCFF) : const Color(0xFF275B7A),
      fontSize: 13,
      fontWeight: FontWeight.w700,
      height: 1.3,
    ),
  );
}

Widget _formulaCaption(String formula, bool dark) {
  return _math(
    formula,
    dark,
    fontSize: 13,
    color: dark ? const Color(0xFF9EACC3) : const Color(0xFF527087),
  );
}

Widget _resultText(String? value, bool dark) {
  return Text(
    value == null || value.isEmpty ? '—' : value,
    textAlign: TextAlign.center,
    style: _cellTextStyle(dark),
  );
}

Widget _errorMessage(String message, bool dark) {
  return Text(
    message,
    style: const TextStyle(color: Color(0xFFB4533F), fontSize: 11, height: 1.5),
  );
}

Widget _math(
  String formula,
  bool dark, {
  double fontSize = 14,
  Color? color,
  FontWeight? fontWeight,
}) {
  return SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Math.tex(
      formula,
      mathStyle: MathStyle.text,
      textStyle: TextStyle(
        color:
            color ?? (dark ? const Color(0xFFB7D9ED) : const Color(0xFF334F65)),
        fontSize: fontSize,
        fontWeight: fontWeight,
        height: 1.35,
      ),
      onErrorFallback: (error) => Text(
        formula,
        style: TextStyle(
          color:
              color ??
              (dark ? const Color(0xFFB7D9ED) : const Color(0xFF334F65)),
          fontSize: fontSize,
          fontWeight: fontWeight,
          height: 1.35,
        ),
      ),
    ),
  );
}

Widget _displayMath(String formula, bool dark) {
  final color = EcjtuColors.platformText(
    dark,
    (dark ? const Color(0xFFE1EDFF) : const Color(0xFF223549)),
  );
  return SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Math.tex(
      formula,
      mathStyle: MathStyle.display,
      textStyle: TextStyle(color: color, fontSize: 14, height: 1.75),
      onErrorFallback: (error) => Text(
        formula,
        style: TextStyle(color: color, fontSize: 14, height: 1.75),
      ),
    ),
  );
}

TableBorder _tableBorder(bool dark) {
  return TableBorder(
    horizontalInside: BorderSide(
      color: dark ? const Color(0xFF28465C) : const Color(0xFFE5EDF2),
    ),
    verticalInside: BorderSide(
      color: dark ? const Color(0xFF28465C) : const Color(0xFFE5EDF2),
    ),
    top: BorderSide.none,
    bottom: BorderSide.none,
    left: BorderSide.none,
    right: BorderSide.none,
  );
}

Color _headerColor(bool dark) =>
    dark ? const Color(0xFF14263A) : const Color(0xFFEEF6FA);

Color _borderColor(bool dark) => EcjtuColors.platformBorder(
  dark,
  (dark ? const Color(0xFF31546B) : const Color(0xFFD5E4EF)),
);

Color _headerTextColor(bool dark) =>
    dark ? const Color(0xFFD6E6F3) : const Color(0xFF5D7487);

TextStyle _headerTextStyle(bool dark) => TextStyle(
  color: _headerTextColor(dark),
  fontSize: 12,
  fontWeight: FontWeight.w700,
  height: 1.25,
);

TextStyle _cellTextStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFFB7D9ED) : const Color(0xFF334F65),
  fontSize: 12,
  height: 1.25,
);

TextStyle _mathTextStyle(bool dark, {FontWeight? weight}) => TextStyle(
  color: dark ? const Color(0xFFB7D9ED) : const Color(0xFF334F65),
  fontSize: 12,
  fontWeight: weight,
  height: 1.25,
);

TextStyle _fieldLabelStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFFB9E2F7) : const Color(0xFF275B7A),
  fontSize: 11,
  fontWeight: FontWeight.w700,
  height: 1.3,
);

Color _fieldLabelColor(bool dark) =>
    dark ? const Color(0xFFB9E2F7) : const Color(0xFF275B7A);

TextStyle _summaryLabelStyle(bool dark) => TextStyle(
  color: dark ? const Color(0xFF9EACC3) : const Color(0xFF527087),
  fontSize: 12,
  fontWeight: FontWeight.w600,
  height: 1.3,
);

Color _summaryLabelColor(bool dark) =>
    dark ? const Color(0xFF9EACC3) : const Color(0xFF527087);

TextStyle _noteTextStyle(bool dark) => TextStyle(
  color: EcjtuColors.platformMuted(
    dark,
    (dark ? const Color(0xFF9EACC3) : const Color(0xFF667B8E)),
  ),
  fontSize: 11,
  height: 1.3,
);
