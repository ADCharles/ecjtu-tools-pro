// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

part of 'diary_page.dart';

extension _DiaryPageView on _DiaryPageState {
  Widget _buildDiary(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      Offstage(offstage: _pureReaderOpen, child: _buildDiaryContent(context)),
      if (_pureReaderOpen) _buildPureReading(context),
    ],
  );

  Widget _buildDiaryContent(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final mobile = EcjtuMetrics.phoneLayout(context);
    final scale = _entry?.renderScale ?? 1;
    final style = TextStyle(
      fontFamily: _font(context),
      fontFamilyFallback: const ['LXGWWenKai'],
      fontSize: 18 * scale,
      height: 1.75,
      color: theme.textTheme.bodyLarge?.color,
    );
    final border = EcjtuColors.borderFor(context);
    if (_portraitLayout)
      return _buildPortraitDiary(context, style, dark, border);
    return PopScope(
      canPop: _allowPop && !_pureReaderOpen,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) unawaited(_back());
      },
      child: IgnorePointer(
        ignoring: _leaving,
        child: Scaffold(
          backgroundColor: mobile
              ? theme.scaffoldBackgroundColor
              : Colors.transparent,
          body: SafeArea(
            child: DiarySelectionViewport(
              controller: _desktopReadScroll,
              child: SelectionArea(
                contextMenuBuilder: buildEcjtuSelectionContextMenu,
                child: EcjtuPageColumn(
                  controller: _desktopReadScroll,
                  contentFrameMaxWidth: 960,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SelectionContainer.disabled(
                        child: EcjtuSubpageTitle(
                          title: '今日笺',
                          backTitle: '返回日历',
                          onBack: _controlsLocked ? null : _back,
                        ),
                      ),
                      SizedBox(height: EcjtuMetrics.pageHeaderGapFor(context)),
                      SelectionContainer.disabled(
                        child: _diaryDateToolbar(mobile, dark, border),
                      ),
                      const SizedBox(height: 18),
                      if (_loading)
                        const LinearProgressIndicator()
                      else if (_entry == null)
                        Column(
                          children: [
                            Text(_error ?? '日记无法读取'),
                            EcjtuDialogAction(label: '重新读取', onPressed: _load),
                          ],
                        )
                      else ...[
                        SelectionContainer.disabled(child: _diaryTools(scale)),
                        if (_conflict || _draft != null) ...[
                          const SizedBox(height: 12),
                          SelectionContainer.disabled(
                            child: _diaryDraftActions(),
                          ),
                        ],
                        const SizedBox(height: 12),
                        SelectionContainer.disabled(child: _diarySaveStatus()),
                        const SizedBox(height: 12),
                        Container(
                          padding: EdgeInsets.all(mobile ? 18 : 32),
                          decoration: BoxDecoration(
                            color: EcjtuColors.surfaceFrom(
                              context,
                              dark
                                  ? const Color(0xFF162130)
                                  : const Color(0xFFFDFCF9),
                            ),
                            border: Border.all(color: border),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: dark ? .06 : .025,
                                ),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final editor = KeyedSubtree(
                                key: _editorKey,
                                child: _editorPaper(style, mobile, border),
                              );
                              final rendered = _renderedPaper(style);
                              if (!mobile && constraints.maxWidth >= 760) {
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: editor),
                                    const SizedBox(width: 28),
                                    Expanded(child: rendered),
                                  ],
                                );
                              }
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  rendered,
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 20,
                                    ),
                                    child: Divider(height: 1, color: border),
                                  ),
                                  editor,
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPortraitDiary(
    BuildContext context,
    TextStyle style,
    bool dark,
    Color border,
  ) {
    final theme = Theme.of(context);
    final bottom = EcjtuMobileInsets.bottomOf(context);
    final metrics = EcjtuMetrics.columnForContext(
      context,
      MediaQuery.sizeOf(context),
    );
    return PopScope(
      canPop: _allowPop && !_pureReaderOpen,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) unawaited(_back());
      },
      child: IgnorePointer(
        ignoring: _leaving,
        child: Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                metrics.horizontalPadding,
                metrics.topPadding,
                metrics.horizontalPadding,
                bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SelectionContainer.disabled(
                    child: EcjtuSubpageTitle(
                      title: '今日笺',
                      backTitle: '返回日历',
                      onBack: _controlsLocked ? null : _back,
                    ),
                  ),
                  SizedBox(height: EcjtuMetrics.pageHeaderGapFor(context)),
                  if (_entry != null)
                    Row(
                      key: const ValueKey('diary-mode-switch'),
                      children: [
                        Expanded(
                          child: IgnorePointer(
                            ignoring: _controlsLocked,
                            child: EcjtuSlidingSegments(
                              items: const ['编辑', '阅读'],
                              selectedIndex: _portraitReading ? 1 : 0,
                              height: 36,
                              fontSize: 13,
                              onChanged: (index) {
                                FocusScope.of(context).unfocus();
                                _inputPreviewTimer?.cancel();
                                _update(() => _portraitReading = index == 1);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (_conflict || _draft != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: _diaryDraftActions(),
                    ),
                  const SizedBox(height: 12),
                  if (_loading)
                    const LinearProgressIndicator()
                  else if (_entry == null)
                    Column(
                      children: [
                        Text(_error ?? '日记无法读取'),
                        EcjtuDialogAction(label: '重新读取', onPressed: _load),
                      ],
                    )
                  else
                    Expanded(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Offstage(
                            offstage: _portraitReading,
                            child: SingleChildScrollView(
                              key: const ValueKey('diary-portrait-editor'),
                              controller: _portraitEditScroll,
                              padding: const EdgeInsets.fromLTRB(4, 0, 4, 24),
                              child: KeyedSubtree(
                                key: _editorKey,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _portraitDocumentHeader(dark, border),
                                    _editorPaper(style, true, border),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          if (_portraitReading)
                            SelectionArea(
                              contextMenuBuilder:
                                  buildEcjtuSelectionContextMenu,
                              child: SingleChildScrollView(
                                key: const ValueKey('diary-portrait-reader'),
                                controller: _portraitReadScroll,
                                padding: const EdgeInsets.fromLTRB(4, 0, 4, 24),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    SelectionContainer.disabled(
                                      child: _portraitDocumentHeader(
                                        dark,
                                        border,
                                      ),
                                    ),
                                    _renderedPaper(style),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  if (_entry != null)
                    Container(
                      key: const ValueKey('diary-editor-toolbar'),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        border: Border(top: BorderSide(color: border)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  EcjtuDialogAction(
                                    label: _imageBusy ? '正在添加图片' : '添加图片',
                                    onPressed: _controlsLocked
                                        ? null
                                        : _imagePosition,
                                  ),
                                  const SizedBox(width: 8),
                                  EcjtuDialogAction(
                                    label: _conflict ? '保存草稿' : '保存',
                                    onPressed: _controlsLocked || _saving
                                        ? null
                                        : () {
                                            if (_conflict) {
                                              unawaited(_saveDraftAsEntry());
                                            } else {
                                              unawaited(_save());
                                            }
                                          },
                                  ),
                                  const SizedBox(width: 8),
                                  _pureReadingAction(),
                                  const SizedBox(width: 8),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          EcjtuDialogAction(
                            label: '完成',
                            onPressed: _controlsLocked
                                ? null
                                : () => FocusScope.of(context).unfocus(),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _pureReadingAction() => EcjtuDialogAction(
    label: '纯净阅读',
    onPressed: _controlsLocked ? null : _openPureReading,
  );

  void _openPureReading() {
    if (_pureReaderOpen || _entry == null || _controlsLocked) return;
    FocusScope.of(context).unfocus();
    _inputPreviewTimer?.cancel();
    _update(() {
      _portraitReading = false;
      _pureReaderOpen = true;
    });
  }

  Widget _buildPureReading(BuildContext context) {
    final theme = Theme.of(context);
    final style = TextStyle(
      fontFamily: _font(context),
      fontFamilyFallback: const ['LXGWWenKai'],
      fontSize: 18 * _entry!.renderScale,
      height: 1.75,
      color: theme.textTheme.bodyLarge?.color,
    );
    return Material(
      color: theme.scaffoldBackgroundColor,
      child: SafeArea(
        child: SelectionArea(
          contextMenuBuilder: buildEcjtuSelectionContextMenu,
          child: EcjtuPageColumn(
            key: const ValueKey('diary-pure-reader'),
            contentFrameMaxWidth: 960,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SelectionContainer.disabled(
                  child: EcjtuSubpageTitle(
                    title: '今日笺',
                    backTitle: '返回编辑',
                    onBack: () => _update(() => _pureReaderOpen = false),
                  ),
                ),
                SizedBox(height: EcjtuMetrics.pageHeaderGapFor(context)),
                _renderedPaper(style, readOnly: true),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _portraitDocumentHeader(bool dark, Color border) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _diaryDateToolbar(true, dark, border, compact: true),
      const SizedBox(height: 10),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: _diaryTools(_entry!.renderScale, includeEditorActions: false),
      ),
      const SizedBox(height: 8),
      _diarySaveStatus(),
      const SizedBox(height: 12),
    ],
  );

  Widget _diaryDraftActions() => Wrap(
    spacing: 8,
    runSpacing: 8,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      if (!_conflict) const Text('有保留的草稿'),
      if (_conflict)
        EcjtuDialogAction(
          label: '重新载入',
          onPressed: _controlsLocked || (_saving && !_leaving)
              ? null
              : _reloadLatest,
        ),
      EcjtuDialogAction(
        label: '复制草稿',
        onPressed: _controlsLocked ? null : _copyDraft,
      ),
      if (!_conflict)
        EcjtuDialogAction(
          label: '恢复草稿',
          onPressed: _controlsLocked || (_saving && !_leaving)
              ? null
              : _restoreDraft,
        ),
    ],
  );

  Widget _diaryTools(
    double scale, {
    VoidCallback? onChanged,
    VoidCallback? closeOptions,
    bool includeEditorActions = true,
  }) => Wrap(
    spacing: 8,
    runSpacing: 8,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      SizedBox(
        width: 116,
        child: EcjtuSelectBox<bool>(
          value: _entry!.markdown,
          enabled: !_controlsLocked,
          items: const [true, false],
          labelBuilder: (value) => value ? 'Markdown' : '文本',
          onChanged: (value) {
            _update(() => _entry = _entry!.edit(markdown: value));
            _changed();
            onChanged?.call();
          },
        ),
      ),
      if (includeEditorActions)
        EcjtuDialogAction(
          label: _imageBusy ? '正在添加图片' : '添加图片',
          onPressed: _controlsLocked
              ? null
              : () {
                  closeOptions?.call();
                  unawaited(_imagePosition());
                },
        ),
      SizedBox(
        width: 128,
        child: EcjtuSelectBox<double>(
          value: scale,
          enabled: !_controlsLocked,
          items: [
            for (var percent = 75; percent <= 200; percent += 5) percent / 100,
          ],
          labelBuilder: (value) => '文字 ${(value * 100).round()}%',
          onChanged: (value) async {
            _update(() => _entry = _entry!.edit(renderScale: value));
            _changed();
            onChanged?.call();
            await widget.storage.setRenderScale(widget.account, value);
            await _save();
          },
        ),
      ),
      EcjtuDialogAction(
        label: _exporting ? '正在导出' : '导出 PDF',
        onPressed: _controlsLocked
            ? null
            : () {
                closeOptions?.call();
                unawaited(_exportPdf());
              },
      ),
      if (includeEditorActions)
        EcjtuDialogAction(
          label: _conflict ? '保存草稿' : '保存',
          onPressed: _controlsLocked || (_saving && !_leaving)
              ? null
              : () {
                  closeOptions?.call();
                  if (_conflict) {
                    unawaited(_saveDraftAsEntry());
                  } else {
                    unawaited(_save());
                  }
                },
        ),
      if (includeEditorActions &&
          [
            TargetPlatform.android,
            TargetPlatform.iOS,
          ].contains(Theme.of(context).platform))
        _pureReadingAction(),
    ],
  );

  Widget _diarySaveStatus() {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(
          _error != null
              ? Icons.error_outline
              : (_saving && !_leaving)
              ? Icons.sync
              : Icons.check_circle_outline,
          size: 15,
          color: _error != null ? theme.colorScheme.error : theme.hintColor,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            _error ??
                ((_saving && !_leaving)
                    ? '正在保存'
                    : _revision == _savedRevision
                    ? '已保存'
                    : '未保存'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: _error != null ? theme.colorScheme.error : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _diaryDateToolbar(
    bool mobile,
    bool dark,
    Color border, {
    bool compact = false,
  }) {
    final theme = Theme.of(context);
    return Container(
      key: const ValueKey('diary-date-toolbar'),
      padding: EdgeInsets.all(
        compact
            ? 10
            : mobile
            ? 16
            : 22,
      ),
      decoration: BoxDecoration(
        color: EcjtuColors.surfaceFrom(
          context,
          dark ? const Color(0xFF202020) : Colors.white,
        ),
        border: Border.all(
          color: EcjtuColors.borderFrom(
            context,
            dark ? const Color(0xFF424242) : const Color(0xFFD9D9D9),
          ),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                _date.day.toString().padLeft(2, '0'),
                style: TextStyle(
                  fontFamily: _font(context),
                  fontFamilyFallback: const ['LXGWWenKai'],
                  fontSize: compact
                      ? 30
                      : mobile
                      ? 38
                      : 44,
                  height: 1.15,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_date.year}年${_date.month}月',
                      style: compact
                          ? theme.textTheme.titleMedium?.copyWith(fontSize: 14)
                          : theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '星期${const ['一', '二', '三', '四', '五', '六', '日'][_date.weekday - 1]}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              EcjtuDialogAction(
                label: '日记记录',
                onPressed: _controlsLocked ? null : _showHistory,
              ),
            ],
          ),
          SizedBox(height: compact ? 8 : 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              EcjtuDialogAction(
                label: '前一天',
                onPressed: _controlsLocked || _date == DateTime(1900)
                    ? null
                    : () => _chooseDate(
                        DateTime(_date.year, _date.month, _date.day - 1),
                      ),
              ),
              Builder(
                builder: (anchor) => EcjtuDialogAction(
                  label: '选择日期',
                  onPressed: _controlsLocked ? null : () => _pickDate(anchor),
                ),
              ),
              EcjtuDialogAction(
                label: '后一天',
                onPressed: _controlsLocked || _date == DateTime(2200, 12, 31)
                    ? null
                    : () => _chooseDate(
                        DateTime(_date.year, _date.month, _date.day + 1),
                      ),
              ),
              EcjtuDialogAction(
                label: '今天',
                onPressed: _controlsLocked
                    ? null
                    : () => _chooseDate(DateTime.now()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _renderedPaper(TextStyle style, {bool readOnly = false}) => Listener(
    key: readOnly ? null : _renderedKey,
    onPointerDown: readOnly ? null : _locateRenderedSource,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_title.text.trim().isNotEmpty &&
            (!_entry!.markdown ||
                firstDiaryHeading(_body.text)?.title != _title.text.trim()))
          Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Text(
              _title.text,
              style: style.copyWith(
                fontSize: 27 * _entry!.renderScale,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        DiaryBody(
          body: _body.text,
          markdown: _entry!.markdown,
          storage: widget.storage,
          account: widget.account,
          style: style,
          imageWidths: _entry!.imageWidths,
          onImageWidthChanged: readOnly || _controlsLocked
              ? null
              : (id, width) {
                  _update(
                    () => _entry = _entry!.edit(
                      imageWidths: {..._entry!.imageWidths, id: width},
                    ),
                  );
                  _changed();
                },
        ),
      ],
    ),
  );

  Widget _editorPaper(TextStyle style, bool mobile, Color border) =>
      SelectionContainer.disabled(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _title,
              enabled: !_controlsLocked || _leaving,
              readOnly: _leaving,
              onChanged: (_) => _changed(),
              maxLength: 1000,
              minLines: 1,
              maxLines: null,
              style: style.copyWith(
                fontSize: 26 * _entry!.renderScale,
                fontWeight: FontWeight.w600,
              ),
              decoration: const InputDecoration(
                labelText: '标题',
                hintText: '给今天起个名字',
                counterText: '',
                filled: false,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
              ),

              contextMenuBuilder: buildEcjtuPlatformTextContextMenu,
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: _portraitLayout ? 8 : 16),
              child: Divider(height: 1, color: border),
            ),
            TextField(
              key: _bodyFieldKey,
              controller: _body,
              focusNode: _bodyFocus,
              enabled: !_controlsLocked || _leaving,
              readOnly: _leaving,
              onChanged: (_) => _changed(),
              keyboardType: TextInputType.multiline,
              minLines: mobile ? 8 : 12,
              maxLines: null,
              maxLength: 2000000,
              style: style,
              decoration: const InputDecoration(
                labelText: '正文',
                alignLabelWithHint: true,
                hintText: '写下今天的故事',
                counterText: '',
                filled: false,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
              ),

              contextMenuBuilder: buildEcjtuPlatformTextContextMenu,
            ),
          ],
        ),
      );
}
