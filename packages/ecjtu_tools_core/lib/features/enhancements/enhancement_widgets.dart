// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'package:flutter/material.dart';

import '../../theme/ecjtu_theme.dart';
import '../../widgets/ecjtu_widgets.dart';
import '../../widgets/ecjtu_text_context_menu.dart';
import '../arrangement/arrangement_controls.dart';

class EnhancementMenuTile extends StatefulWidget {
  const EnhancementMenuTile({
    super.key,
    required this.title,
    required this.icon,
    this.compact = false,
    required this.onPressed,
  });

  final String title;
  final String icon;
  final bool compact;
  final VoidCallback onPressed;

  @override
  State<EnhancementMenuTile> createState() => _EnhancementMenuTileState();
}

class _EnhancementMenuTileState extends State<EnhancementMenuTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = dark
        ? const Color(0xFF77BCEB)
        : EcjtuColors.smartWorkIcon;
    return Material(
      type: MaterialType.transparency,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: InkWell(
          onTap: widget.onPressed,
          borderRadius: BorderRadius.circular(6),
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          child: Container(
            constraints: BoxConstraints(minHeight: widget.compact ? 74 : 82),
            padding: EdgeInsets.fromLTRB(
              8,
              widget.compact ? 10 : 12,
              8,
              widget.compact ? 8 : 10,
            ),
            decoration: BoxDecoration(
              color: _hovered
                  ? (EcjtuColors.hoverFrom(
                      context,
                      (dark
                          ? const Color(0xFF172B42)
                          : const Color(0xFFEEF7FC)),
                    ))
                  : (EcjtuColors.surfaceFrom(
                      context,
                      dark
                          ? const Color(0xFF101D31)
                          : EcjtuColors.smartWorkSurface,
                    )),
              border: Border.all(
                color: _hovered
                    ? (dark ? const Color(0xFF5085A3) : const Color(0xFF8DB7D0))
                    : (dark
                          ? const Color(0xFF31546B)
                          : EcjtuColors.smartWorkBorder),
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                EcjtuIcon(widget.icon, size: 28, color: iconColor),
                const SizedBox(height: 8),
                Text(
                  widget.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: dark
                        ? const Color(0xFFD6E6F3)
                        : EcjtuColors.smartWorkCardText,
                    fontSize: EcjtuMetrics.fontSmallFor(size),
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class EnhancementFieldLabel extends StatelessWidget {
  const EnhancementFieldLabel({
    super.key,
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fontFamily = Theme.of(context).textTheme.bodyMedium?.fontFamily;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: fontFamily,
            color: EcjtuColors.mutedFrom(
              context,
              dark ? EcjtuColors.darkTextSecondary : const Color(0xFF667B8E),
            ),
            fontSize: EcjtuMetrics.fontCaptionFor(size),
            height: 1.3,
          ),
        ),
        const SizedBox(height: 5),
        child,
      ],
    );
  }
}

class EnhancementInput extends StatefulWidget {
  const EnhancementInput({
    super.key,
    required this.value,
    required this.onChanged,
    this.keyboardType,
    this.maxLines = 1,
    this.hintText,
    this.readOnly = false,
    this.obscureText = false,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? hintText;
  final bool readOnly;
  final bool obscureText;

  @override
  State<EnhancementInput> createState() => _EnhancementInputState();
}

class _EnhancementInputState extends State<EnhancementInput> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant EnhancementInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value == _controller.text || widget.value == oldWidget.value) {
      return;
    }
    if (widget.readOnly ||
        !_controller.selection.isValid ||
        _controller.text == oldWidget.value) {
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

  bool _revealPassword = false;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fontFamily = Theme.of(context).textTheme.bodyMedium?.fontFamily;
    final field = TextFormField(
      contextMenuBuilder: buildEcjtuTextContextMenu,
      controller: _controller,
      readOnly: widget.readOnly,
      maxLines: widget.maxLines,
      keyboardType: widget.keyboardType,
      obscureText: widget.obscureText && !_revealPassword,
      onChanged: widget.onChanged,
      textAlignVertical: TextAlignVertical.center,
      style: TextStyle(
        fontFamily: fontFamily,
        color: EcjtuColors.textFrom(
          context,
          dark ? EcjtuColors.darkTextPrimary : EcjtuColors.smartWorkStrongText,
        ),
        fontSize: EcjtuMetrics.fontSmallFor(size),
        height: 1.3,
      ),
      decoration: InputDecoration(
        isDense: true,
        constraints: const BoxConstraints(minHeight: 34),
        hintText: widget.hintText,
        hintStyle: TextStyle(
          fontFamily: fontFamily,
          color: EcjtuColors.mutedFrom(
            context,
            dark ? EcjtuColors.darkTextSecondary : const Color(0xFF8A9AAA),
          ),
          fontSize: EcjtuMetrics.fontSmallFor(size),
        ),
        suffixIcon: widget.obscureText
            ? SizedBox(
                width: 30,
                height: 34,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  tooltip: _revealPassword ? '隐藏密码' : '显示密码',
                  onPressed: () =>
                      setState(() => _revealPassword = !_revealPassword),
                  icon: Icon(
                    _revealPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 18,
                  ),
                ),
              )
            : null,
        filled: true,
        fillColor: EcjtuColors.surfaceFrom(
          context,
          dark ? const Color(0xFF14263A) : Colors.white,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(
            color: dark ? const Color(0xFF426B83) : const Color(0xFFB9CFDD),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(
            color: dark ? const Color(0xFF426B83) : const Color(0xFFB9CFDD),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(
            color: dark ? EcjtuColors.darkPrimary : const Color(0xFF287AA8),
          ),
        ),
      ),
    );
    // 单行输入框与 EcjtuSelectBox（pickerHeight 32 + 边框 = 34）完全等高。
    if (widget.maxLines == 1) {
      return SizedBox(height: 34, child: field);
    }
    return field;
  }
}

class EnhancementSelect extends StatelessWidget {
  const EnhancementSelect({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return EcjtuSelectBox<String>(
      value: items.contains(value) ? value : items.first,
      items: items,
      labelBuilder: (item) => item,
      fontSize: EcjtuMetrics.fontSmallFor(size),
      textAlign: TextAlign.center,
      height: 34,
      onChanged: onChanged,
    );
  }
}

class EnhancementDateButton extends StatelessWidget {
  const EnhancementDateButton({
    super.key,
    required this.value,
    required this.onPressed,
    required this.label,
  });

  final String value;
  final String label;
  final ValueChanged<BuildContext> onPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Semantics(
            label: label,
            child: EnhancementInput(
              value: value,
              readOnly: true,
              onChanged: (_) {},
            ),
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 58,
          child: Semantics(
            label: '选择$label',
            child: ArrangementActionButton(
              label: '选择',
              onPressed: () => onPressed(context),
            ),
          ),
        ),
      ],
    );
  }
}

class EnhancementOffsetControl extends StatelessWidget {
  const EnhancementOffsetControl({
    super.key,
    required this.firstValue,
    required this.firstItems,
    required this.firstUnit,
    required this.secondValue,
    required this.secondItems,
    required this.secondUnit,
    required this.onFirstChanged,
    required this.onSecondChanged,
    required this.onApply,
  });

  final int firstValue;
  final List<int> firstItems;
  final String firstUnit;
  final int secondValue;
  final List<int> secondItems;
  final String secondUnit;
  final ValueChanged<int> onFirstChanged;
  final ValueChanged<int> onSecondChanged;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.sizeOf(context);
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Text(
            '+',
            style: TextStyle(
              color: EcjtuColors.mutedFrom(
                context,
                dark ? EcjtuColors.darkTextSecondary : const Color(0xFF667B8E),
              ),
              fontSize: EcjtuMetrics.fontSmallFor(size),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 5),
          SizedBox(
            width: 76,
            child: EcjtuSelectBox<int>(
              value: firstValue,
              items: firstItems,
              labelBuilder: (value) => '$value$firstUnit',
              fontSize: EcjtuMetrics.fontCaptionFor(size),
              onChanged: onFirstChanged,
            ),
          ),
          const SizedBox(width: 5),
          SizedBox(
            width: 76,
            child: EcjtuSelectBox<int>(
              value: secondValue,
              items: secondItems,
              labelBuilder: (value) => '$value$secondUnit',
              fontSize: EcjtuMetrics.fontCaptionFor(size),
              onChanged: onSecondChanged,
            ),
          ),
          const SizedBox(width: 6),
          TextButton(
            onPressed: onApply,
            style: TextButton.styleFrom(
              minimumSize: const Size(48, 34),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              foregroundColor: dark
                  ? const Color(0xFFB9DBF2)
                  : EcjtuColors.smartWorkSecondaryText,
              backgroundColor: EcjtuColors.surfaceFrom(
                context,
                dark
                    ? const Color(0xFF14263A)
                    : EcjtuColors.smartWorkSecondarySurface,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
                side: BorderSide(
                  color: dark
                      ? const Color(0xFF426B83)
                      : EcjtuColors.smartWorkSecondaryBorder,
                ),
              ),
            ),
            child: const Text('应用'),
          ),
        ],
      ),
    );
  }
}

class EnhancementTemplateRow extends StatelessWidget {
  const EnhancementTemplateRow({
    super.key,
    required this.name,
    required this.detail,
    required this.onUse,
    required this.onDelete,
  });

  final String name;
  final String detail;
  final VoidCallback onUse;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fontFamily = Theme.of(context).textTheme.bodyMedium?.fontFamily;
    return Container(
      padding: const EdgeInsets.only(top: 9),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: EcjtuColors.borderFrom(
              context,
              dark ? const Color(0xFF28465C) : const Color(0xFFE1EBF1),
            ),
          ),
        ),
      ),
      child: Row(
        children: [
          TextButton(
            onPressed: onUse,
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 34),
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              foregroundColor: dark
                  ? const Color(0xFFB9DBF2)
                  : EcjtuColors.smartWorkSecondaryText,
              backgroundColor: EcjtuColors.surfaceFrom(
                context,
                dark
                    ? const Color(0xFF14263A)
                    : EcjtuColors.smartWorkSecondarySurface,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
                side: BorderSide(
                  color: dark
                      ? const Color(0xFF426B83)
                      : EcjtuColors.smartWorkSecondaryBorder,
                ),
              ),
              textStyle: TextStyle(
                fontFamily: fontFamily,
                fontSize: EcjtuMetrics.fontSmallFor(size),
                fontWeight: FontWeight.w600,
              ),
            ),
            child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              detail,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: EcjtuColors.mutedFrom(
                  context,
                  dark
                      ? EcjtuColors.darkTextSecondary
                      : const Color(0xFF667B8E),
                ),
                fontSize: EcjtuMetrics.fontCaptionFor(size),
                height: 1.4,
              ),
            ),
          ),
          Tooltip(
            message: '删除模板',
            child: TextButton(
              onPressed: onDelete,
              style: TextButton.styleFrom(
                minimumSize: const Size(30, 34),
                padding: const EdgeInsets.symmetric(horizontal: 7),
                foregroundColor: EcjtuColors.mutedFrom(
                  context,
                  dark ? const Color(0xFF9EACC3) : const Color(0xFF8A6570),
                ),
                backgroundColor: EcjtuColors.surfaceFrom(
                  context,
                  dark
                      ? const Color(0xFF14263A)
                      : EcjtuColors.smartWorkSecondarySurface,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                  side: BorderSide(
                    color: dark
                        ? const Color(0xFF426B83)
                        : EcjtuColors.smartWorkSecondaryBorder,
                  ),
                ),
                textStyle: TextStyle(
                  fontFamily: fontFamily,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  height: 1,
                ),
              ),
              child: const Text('×'),
            ),
          ),
        ],
      ),
    );
  }
}
