// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'package:ecjtu_tools_core/widgets/ecjtu_text_context_menu.dart';
import '../../theme/ecjtu_theme.dart';
import 'package:flutter/material.dart';

import '../../widgets/ecjtu_icon.dart';
import '../../widgets/ecjtu_page.dart';
import '../workbench/smart_work_widgets.dart';
import 'physics_catalog.dart';

class PhysicsPage extends StatefulWidget {
  const PhysicsPage({
    super.key,
    required this.onBack,
    required this.onOpenOfficial,
    this.onOpenCalculator,
    this.initialCatalogOpen = false,
    this.onNavigationChanged,
  });

  final VoidCallback onBack;
  final VoidCallback onOpenOfficial;
  final ValueChanged<PhysicsCalculatorDefinition>? onOpenCalculator;
  final bool initialCatalogOpen;
  final ValueChanged<bool>? onNavigationChanged;

  @override
  State<PhysicsPage> createState() => _PhysicsPageState();
}

class _PhysicsPageState extends State<PhysicsPage> {
  bool _catalogOpen = false;
  bool _searchOpen = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _catalogOpen = widget.initialCatalogOpen;
  }

  @override
  void didUpdateWidget(covariant PhysicsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialCatalogOpen != widget.initialCatalogOpen &&
        _catalogOpen != widget.initialCatalogOpen) {
      _catalogOpen = widget.initialCatalogOpen;
      _query = '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final key = ValueKey<String>(_catalogOpen ? 'catalog' : 'home');
    return SmartWorkPageSwitcher(
      pageKey: key,
      child: _catalogOpen ? _buildCatalog() : _buildHome(),
    );
  }

  Widget _buildHome() {
    return WorkbenchSubpageColumn(
      key: const ValueKey<String>('physics-home-page'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SmartWorkPageHeader(
            title: '物理实验',
            backTitle: '返回工作台',
            onBack: _backToWorkbench,
          ),
          SizedBox(height: workbenchHeaderGap(context)),
          _PhysicsModuleEntry(
            icon: 'smart_work_physics.svg',
            title: '物理实验官网',
            detail: '',
            onPressed: widget.onOpenOfficial,
          ),
          SizedBox(height: workbenchEntryGap(context)),
          _PhysicsModuleEntry(
            icon: 'smart_work_calculator.svg',
            title: '物理实验计算器',
            detail: '',
            onPressed: () {
              setState(() => _catalogOpen = true);
              _notifyNavigation();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCatalog() {
    final size = MediaQuery.sizeOf(context);
    final compact = EcjtuMetrics.isCompact(size);
    final query = _query.trim().toLowerCase();
    final calculators = PhysicsCatalog.calculators
        .where(
          (calculator) =>
              query.isEmpty ||
              '${calculator.title} ${calculator.detail}'.toLowerCase().contains(
                query,
              ),
        )
        .toList(growable: false);
    return WorkbenchSubpageColumn(
      key: const ValueKey<String>('physics-catalog-page'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SmartWorkPageHeader(
            title: '物理实验计算器',
            backTitle: _searchOpen ? '返回计算器' : '返回物理实验',
            onBack: () {
              if (_searchOpen) {
                setState(() {
                  _searchOpen = false;
                  _query = '';
                });
              } else {
                setState(() => _catalogOpen = false);
                _notifyNavigation();
              }
            },
            trailing: _searchOpen
                ? null
                : _PhysicsSearchButton(
                    active: false,
                    onPressed: () => setState(() => _searchOpen = true),
                  ),
          ),
          if (_searchOpen) ...[
            SizedBox(height: compact ? 12 : 18),
            _PhysicsSearchField(
              value: _query,
              onChanged: (value) => setState(() => _query = value),
            ),
          ],
          SizedBox(height: EcjtuMetrics.pageHeaderGapFor(context)),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: workbenchEntryMaxWidth(context),
            ),
            child: calculators.isEmpty
                ? Text(
                    '没有找到匹配的计算器',
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF9EACC3)
                          : const Color(0xFF667B8E),
                      fontSize: EcjtuMetrics.fontCaptionFor(size),
                      height: 1.5,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (
                        var index = 0;
                        index < calculators.length;
                        index++
                      ) ...[
                        _PhysicsModuleEntry(
                          icon: 'smart_work_calculator.svg',
                          title: calculators[index].title,
                          detail: '',
                          onPressed:
                              calculators[index].implemented &&
                                  widget.onOpenCalculator != null
                              ? () =>
                                    widget.onOpenCalculator!(calculators[index])
                              : null,
                        ),
                        if (index < calculators.length - 1)
                          SizedBox(height: workbenchEntryGap(context)),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  void _backToWorkbench() {
    setState(() {
      _catalogOpen = false;
      _query = '';
    });
    _notifyNavigation();
    widget.onBack();
  }

  void _notifyNavigation() => widget.onNavigationChanged?.call(_catalogOpen);
}

class _PhysicsSearchField extends StatefulWidget {
  const _PhysicsSearchField({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  State<_PhysicsSearchField> createState() => _PhysicsSearchFieldState();
}

class _PhysicsSearchFieldState extends State<_PhysicsSearchField> {
  late final TextEditingController _controller;
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _PhysicsSearchField oldWidget) {
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
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.sizeOf(context);
    return ListenableBuilder(
      listenable: _focus,
      builder: (context, _) => Container(
        key: const ValueKey('physics-search-painted-outline'),
        width: double.infinity,
        height: EcjtuBackAction.heightFor(context),
        padding: const EdgeInsets.symmetric(horizontal: 11),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: _focus.hasFocus
                ? Theme.of(context).colorScheme.primary.withValues(alpha: .55)
                : EcjtuColors.borderFor(context),
          ),
        ),
        child: Center(
          child: TextField(
            controller: _controller,
            focusNode: _focus,
            autofocus: true,
            textAlignVertical: TextAlignVertical.center,
            onChanged: widget.onChanged,
            textInputAction: TextInputAction.search,
            style: TextStyle(
              color: EcjtuColors.platformText(
                dark,
                (dark ? const Color(0xFFE1EDFF) : const Color(0xFF223549)),
              ),
              fontSize: EcjtuMetrics.fontBodyFor(size),
              height: 1.2,
            ),
            decoration: InputDecoration(
              hintText: '搜索物理实验计算器',
              hintStyle: TextStyle(
                color: EcjtuColors.platformMuted(
                  dark,
                  (dark ? const Color(0xFF9EACC3) : const Color(0xFF667B8E)),
                ),
                fontSize: EcjtuMetrics.fontBodyFor(size),
              ),
              isDense: true,
              isCollapsed: true,
              filled: false,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
            ),

            contextMenuBuilder: buildEcjtuPlatformTextContextMenu,
          ),
        ),
      ),
    );
  }
}

class _PhysicsModuleEntry extends StatelessWidget {
  const _PhysicsModuleEntry({
    required this.icon,
    required this.title,
    required this.detail,
    this.onPressed,
  });

  final String icon;
  final String title;
  final String detail;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: BoxConstraints(maxWidth: workbenchEntryMaxWidth(context)),
    child: EcjtuEntryCard(
      fixedPreview: true,
      icon: icon,
      title: title,
      detail: detail,
      onPressed: onPressed,
    ),
  );
}

class _PhysicsSearchButton extends StatelessWidget {
  const _PhysicsSearchButton({required this.active, required this.onPressed});

  final bool active;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final foreground = EcjtuColors.textFor(context);
    return SizedBox(
      width: EcjtuBackAction.heightFor(context),
      height: EcjtuBackAction.heightFor(context),
      child: IconButton(
        tooltip: '搜索计算器',
        onPressed: onPressed,
        icon: EcjtuIcon('smart_work_search.svg', size: 16, color: foreground),
        padding: EdgeInsets.zero,
        style: EcjtuBackAction.styleFor(context).copyWith(
          fixedSize: WidgetStatePropertyAll(
            Size.square(EcjtuBackAction.heightFor(context)),
          ),
          minimumSize: WidgetStatePropertyAll(
            Size.square(EcjtuBackAction.heightFor(context)),
          ),
          padding: const WidgetStatePropertyAll(EdgeInsets.zero),
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}
