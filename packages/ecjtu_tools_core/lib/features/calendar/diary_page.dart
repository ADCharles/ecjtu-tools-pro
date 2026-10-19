// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'package:ecjtu_tools_core/widgets/ecjtu_text_context_menu.dart';
import 'dart:async';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'diary_source_location.dart';
import 'diary_selection_scroll.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';
import '../../theme/ecjtu_theme.dart';
import '../../widgets/ecjtu_widgets.dart';
import '../../widgets/ecjtu_mobile_insets.dart';
import 'diary_models.dart';
import 'diary_math.dart';
import 'diary_storage.dart';
import 'diary_pdf.dart';
import 'diary_files.dart';
import 'diary_image.dart';

part 'diary_page_view.dart';

class DiaryInitialData {
  const DiaryInitialData(this.entries, this.renderScale);
  final Map<String, DiaryEntry> entries;
  final double renderScale;
  static Future<DiaryInitialData> read(
    DiaryStorage storage,
    String account,
  ) async {
    final data = await Future.wait<Object>([
      storage.readAll(account),
      storage.readRenderScale(account),
    ]);
    return DiaryInitialData(
      data[0] as Map<String, DiaryEntry>,
      data[1] as double,
    );
  }
}

class DiaryPage extends StatefulWidget {
  const DiaryPage({
    super.key,
    required this.account,
    required this.initialDate,
    required this.storage,
    this.onClose,
    this.initialData,
  });
  final String account;
  final DateTime initialDate;
  final DiaryStorage storage;
  final VoidCallback? onClose;
  final DiaryInitialData? initialData;
  @override
  State<DiaryPage> createState() => _DiaryPageState();
}

class _DiaryPageState extends State<DiaryPage> with WidgetsBindingObserver {
  final _title = TextEditingController();
  final _body = TextEditingController();
  final _bodyFocus = FocusNode();
  final _portraitEditScroll = ScrollController();
  final _portraitReadScroll = ScrollController();
  final _desktopReadScroll = DiarySelectionScrollController();
  bool _portraitReading = false;
  bool _pureReaderOpen = false;
  final _editorKey = GlobalKey();
  final _bodyFieldKey = GlobalKey();
  final _renderedKey = GlobalKey();
  late DateTime _date = DateUtils.dateOnly(widget.initialDate);
  DiaryEntry? _entry;
  DateTime? _persistedUpdatedAt;
  DiaryEditDraft? _draft;
  bool _conflict = false, _disposing = false;
  Timer? _timer;
  Timer? _inputPreviewTimer;
  int _revision = 0, _savedRevision = 0;
  int _loadGeneration = 0;
  bool _loading = true, _allowPop = false;
  int _saveCount = 0;
  bool get _saving => _saveCount > 0;
  bool _imageBusy = false, _exporting = false;
  bool get _locked =>
      _loading || _switching || _leaving || _imageBusy || _exporting;
  bool get _controlsLocked =>
      _loading || _switching || _imageBusy || _exporting;
  bool _switching = false;
  bool _leaving = false;
  String? _error;
  Future<void> _pendingSave = Future<void>.value();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bodyFocus.addListener(_revealBodyEditor);
    final initial = widget.initialData;
    if (initial == null) {
      unawaited(_load());
    } else {
      _installData(initial);
      unawaited(_loadDraft(_date, ++_loadGeneration));
    }
  }

  void _revealBodyEditor() {
    if (!_bodyFocus.hasFocus || !_portraitLayout) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bodyContext = _bodyFieldKey.currentContext;
      if (mounted && _bodyFocus.hasFocus && bodyContext != null) {
        Scrollable.ensureVisible(bodyContext, alignment: 0);
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      unawaited(_save());
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _inputPreviewTimer?.cancel();
    _disposing = true;
    WidgetsBinding.instance.removeObserver(this);
    if (_revision != _savedRevision && _entry != null) {
      unawaited(_save());
    }
    _title.dispose();
    _body.dispose();
    _bodyFocus.dispose();
    _portraitEditScroll.dispose();
    _portraitReadScroll.dispose();
    _desktopReadScroll.dispose();
    super.dispose();
  }

  DiaryEntry _snapshot() => _entry!.edit(title: _title.text, body: _body.text);
  void _update(VoidCallback callback) {
    if (mounted && !_disposing) {
      setState(callback);
    } else {
      callback();
    }
  }

  Future<void> _load() async {
    final generation = ++_loadGeneration;
    final date = _date;
    try {
      final data = await DiaryInitialData.read(widget.storage, widget.account);
      if (!mounted || _disposing || generation != _loadGeneration) return;
      setState(() {
        _installData(data);
      });
      unawaited(_loadDraft(date, generation));
    } catch (error) {
      if (mounted && !_disposing) {
        setState(() {
          _loading = false;
          _error = _errorText(error);
        });
      }
    }
  }

  void _installData(DiaryInitialData data) {
    _inputPreviewTimer?.cancel();
    final persisted = data.entries[diaryDateKey(_date)];
    _persistedUpdatedAt = persisted?.updatedAt;
    _entry =
        persisted ??
        DiaryEntry.empty(_date).edit(renderScale: data.renderScale);
    _draft = null;
    _conflict = false;
    _title.text = _entry!.title;
    _body.text = _entry!.body;
    _revision = _savedRevision = 0;
    _loading = false;
    _error = null;
  }

  Future<void> _loadDraft(DateTime date, int generation) async {
    try {
      final draft = await widget.storage.readDraft(widget.account, date);
      if (!mounted ||
          _disposing ||
          generation != _loadGeneration ||
          _conflict ||
          _draft != null) {
        return;
      }
      setState(() => _draft = draft);
    } catch (_) {
      // Recovery data must not block access to the diary or its edit queue.
    }
  }

  bool get _iosComposing =>
      defaultTargetPlatform == TargetPlatform.iOS &&
      [_title, _body].any(
        (controller) =>
            controller.value.composing.isValid &&
            !controller.value.composing.isCollapsed,
      );

  void _refreshInputPreview() {
    if (!mounted || _disposing) return;
    if (_iosComposing) {
      _inputPreviewTimer = Timer(
        const Duration(milliseconds: 180),
        _refreshInputPreview,
      );
      return;
    }
    setState(() {});
  }

  void _saveAfterInput() {
    if (!mounted || _disposing) return;
    if (_iosComposing) {
      _timer = Timer(const Duration(milliseconds: 500), _saveAfterInput);
      return;
    }
    unawaited(_save());
  }

  bool get _portraitLayout {
    final view = View.of(context);
    final device = view.physicalSize / view.devicePixelRatio;
    return EcjtuMetrics.phoneLayout(context) &&
        device.shortestSide < 600 &&
        device.width < device.height;
  }

  void _changed() {
    if (_portraitLayout || defaultTargetPlatform == TargetPlatform.iOS) {
      final wasSaved = _revision == _savedRevision;
      ++_revision;
      if (wasSaved || (!_conflict && _error != null)) {
        setState(() {
          if (!_conflict) _error = null;
        });
      }
      _inputPreviewTimer?.cancel();
      if (!_portraitLayout) {
        _inputPreviewTimer = Timer(
          const Duration(milliseconds: 180),
          _refreshInputPreview,
        );
      }
    } else {
      setState(() {
        ++_revision;
        if (!_conflict) _error = null;
      });
    }
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 500), _saveAfterInput);
  }

  Future<bool> _save() async {
    _timer?.cancel();
    if (_entry == null || _revision == _savedRevision) {
      await _pendingSave;
      return _error == null || _conflict;
    }
    final snapshot = _snapshot(), revision = _revision;
    final storage = widget.storage, account = widget.account;
    _update(() => ++_saveCount);
    final task = _pendingSave.then((_) async {
      if (revision <= _savedRevision) return;
      DiaryEntry? saved;
      if (!_conflict) {
        try {
          saved = await storage.saveEditedEntry(
            account,
            snapshot,
            expectedUpdatedAt: _persistedUpdatedAt,
          );
        } on DiaryEditConflict {
          _conflict = true;
        }
      }
      if (_conflict) {
        await storage.saveDraft(
          account,
          snapshot,
          expectedUpdatedAt: _persistedUpdatedAt,
        );
        _update(() {
          _draft = DiaryEditDraft(snapshot, _persistedUpdatedAt);
          _error = '日记已更新，草稿已保留';
        });
        return;
      }
      _update(() {
        _persistedUpdatedAt = saved?.updatedAt;
        _savedRevision = revision;
        if (_revision == revision) _entry = saved ?? snapshot;
        _error = null;
      });
    });
    _pendingSave = task.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    try {
      await task;
      return true;
    } catch (error) {
      _update(() => _error = '保存失败：${_errorText(error)}');
      return false;
    } finally {
      _update(() => --_saveCount);
    }
  }

  Future<bool> _copyDraft({bool current = false}) async {
    final draft = current || _conflict ? _snapshot() : _draft?.entry;
    if (draft == null) return false;
    try {
      await Clipboard.setData(
        ClipboardData(
          text: [
            if (draft.title.isNotEmpty) draft.title,
            draft.body,
          ].join('\n\n'),
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('草稿已复制')));
      }
      return true;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('暂时无法复制草稿')));
      }
      return false;
    }
  }

  Future<void> _reloadLatest() async {
    if (_locked) return;
    setState(() => _switching = true);
    if (!await _save() || !mounted) {
      if (mounted) setState(() => _switching = false);
      return;
    }
    setState(() => _loading = true);
    await _load();
    if (mounted) setState(() => _switching = false);
  }

  void _restoreDraft() {
    final draft = _draft;
    if (_locked || draft == null) return;
    _timer?.cancel();
    setState(() {
      _entry = draft.entry;
      _title.text = draft.entry.title;
      _body.text = draft.entry.body;
      _persistedUpdatedAt = draft.expectedUpdatedAt;
      ++_revision;
      _conflict = true;
      _error = '草稿尚未保存';
    });
  }

  Future<void> _saveDraftAsEntry() async {
    if (_locked || !_conflict) return;
    _timer?.cancel();
    setState(() => _switching = true);
    try {
      await _pendingSave;
      final current = (await widget.storage.readAll(
        widget.account,
      ))[diaryDateKey(_date)];
      if (!mounted) return;
      final confirmed = await showEcjtuDialog<bool>(
        context: context,
        builder: (context) => EcjtuDialog(
          title: const Text('保存草稿'),
          content: Text('将当前草稿替换 ${diaryDateKey(_date)} 的日记内容？'),
          actions: [
            EcjtuDialogAction(
              label: '取消',
              onPressed: () => Navigator.pop(context, false),
            ),
            EcjtuDialogAction(
              label: '保存草稿',
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      _persistedUpdatedAt = current?.updatedAt;
      _conflict = false;
      _error = null;
      if (await _save() && !_conflict) {
        try {
          await widget.storage.clearDraft(widget.account, _date);
        } catch (_) {
          // A committed edit stays saved if stale draft cleanup fails.
        }
        if (mounted) {
          setState(() {
            ++_loadGeneration;
            _draft = null;
          });
        }
      }
    } catch (error) {
      if (mounted) setState(() => _error = '保存失败：${_errorText(error)}');
    } finally {
      if (mounted) setState(() => _switching = false);
    }
  }

  Future<void> _back() async {
    if (_pureReaderOpen) {
      setState(() => _pureReaderOpen = false);
      return;
    }
    if (_switching || _leaving || _imageBusy || _exporting) return;
    setState(() => _leaving = true);
    final saved = await _save();
    if (!mounted) return;
    if (_entry != null && !saved) {
      setState(() => _leaving = false);
      final copyAndLeave = await showEcjtuDialog<bool>(
        context: context,
        builder: (context) => EcjtuDialog(
          title: const Text('草稿尚未保存'),
          content: const Text('可以复制草稿后返回，或继续编辑。'),
          actions: [
            EcjtuDialogAction(
              label: '继续编辑',
              onPressed: () => Navigator.pop(context, false),
            ),
            EcjtuDialogAction(
              label: '复制并返回',
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        ),
      );
      if (copyAndLeave != true || !mounted) return;
      setState(() => _leaving = true);
      if (!await _copyDraft(current: true) || !mounted) {
        if (mounted) setState(() => _leaving = false);
        return;
      }
    }
    setState(() => _allowPop = true);
    if (widget.onClose != null) {
      widget.onClose!();
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop(true);
    });
  }

  Future<void> _chooseDate(DateTime date) async {
    if (_locked ||
        date.isBefore(DateTime(1900)) ||
        date.isAfter(DateTime(2200, 12, 31)) ||
        DateUtils.isSameDay(date, _date)) {
      return;
    }
    setState(() => _switching = true);
    final saved = await _save();
    if (!mounted || !saved) {
      if (mounted) setState(() => _switching = false);
      return;
    }
    setState(() {
      _date = DateUtils.dateOnly(date);
      _loading = true;
      _entry = null;
    });
    await _load();
    if (mounted) setState(() => _switching = false);
  }

  Future<void> _pickDate(BuildContext anchor) async {
    final date = await showEcjtuDatePicker(
      context: anchor,
      initialDate: _date,
      firstDate: DateTime(1900),
      lastDate: DateTime(2200, 12, 31),
      minimumWidth: 320,
    );
    if (date != null) await _chooseDate(date);
  }

  Future<void> _insertImage(bool atEnd) async {
    final entryId = _entry?.id;
    final selection = _body.selection;
    try {
      final image = await openFile(
        acceptedTypeGroups: const [
          XTypeGroup(
            label: '图片',
            uniformTypeIdentifiers: ['public.image'],
            extensions: ['jpg', 'jpeg', 'png', 'webp', 'gif'],
            mimeTypes: ['image/jpeg', 'image/png', 'image/webp', 'image/gif'],
          ),
        ],
      );
      if (image == null || !mounted) return;
      if (await image.length() > 20 * 1024 * 1024) {
        throw const FormatException('图片大小不能超过 20 MB');
      }
      final id = await widget.storage.addImage(
        widget.account,
        await image.readAsBytes(),
      );
      if (!mounted || _entry?.id != entryId) return;
      final text = _body.text;
      final start = atEnd || !selection.isValid
          ? text.length
          : selection.start.clamp(0, text.length);
      final end = atEnd || !selection.isValid
          ? start
          : selection.end.clamp(start, text.length);
      final prefix = start > 0 && text[start - 1] != '\n' ? '\n\n' : '';
      final suffix = end < text.length && text[end] != '\n' ? '\n\n' : '\n';
      final insertion = '$prefix![图片](diary-asset:$id)$suffix';
      _body.value = TextEditingValue(
        text: text.replaceRange(start, end, insertion),
        selection: TextSelection.collapsed(offset: start + insertion.length),
      );
      setState(() => _portraitReading = false);
      _changed();
      _bodyFocus.requestFocus();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_errorText(error))));
      }
    }
  }

  Future<void> _imagePosition() async {
    if (_locked) return;
    setState(() => _imageBusy = true);
    try {
      if (_portraitLayout) {
        await _insertImage(false);
        return;
      }
      final end = await showEcjtuDialog<bool>(
        context: context,
        builder: (context) => EcjtuDialog(
          title: const Text('添加图片'),
          content: const Text('选择图片插入位置'),
          actions: [
            EcjtuDialogAction(
              label: '光标位置',
              onPressed: () => Navigator.pop(context, false),
            ),
            EcjtuDialogAction(
              label: '正文末尾',
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        ),
      );
      if (end != null) await _insertImage(end);
    } finally {
      if (mounted) setState(() => _imageBusy = false);
    }
  }

  Future<void> _exportPdf() async {
    if (_locked || _entry == null) return;
    setState(() => _exporting = true);
    try {
      if (!await _save() || !mounted) return;
      final entry = _snapshot();
      final bytes = await DiaryPdf.export(
        widget.storage,
        widget.account,
        entry,
      );
      if (!mounted) return;
      if (await saveDiaryPdf(bytes, entry.date) && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('日记 PDF 已导出')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('导出失败：${_errorText(error)}')));
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _showHistory() async {
    if (!await _save() || !mounted) return;
    final entries = (await widget.storage.readAll(
      widget.account,
    )).values.toList()..sort((a, b) => b.date.compareTo(a.date));
    if (!mounted) return;
    final date = await showEcjtuDialog<String>(
      context: context,
      builder: (context) => EcjtuDialog(
        title: const Text('日记记录'),
        content: entries.isEmpty
            ? const Text('还没有日记')
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: entries
                    .map(
                      (entry) => ListTile(
                        title: Text(
                          entry.displayTitle.isEmpty
                              ? '无标题'
                              : entry.displayTitle,
                          style: TextStyle(fontFamily: _font(context)),
                        ),
                        subtitle: Text(entry.date),
                        onTap: () => Navigator.pop(context, entry.date),
                      ),
                    )
                    .toList(),
              ),
      ),
    );
    if (date != null) await _chooseDate(diaryDate(date));
  }

  void _locateRenderedSource(PointerDownEvent event) {
    final platform = Theme.of(context).platform;
    if (_locked ||
        !HardwareKeyboard.instance.isControlPressed ||
        ![
          TargetPlatform.windows,
          TargetPlatform.linux,
          TargetPlatform.macOS,
        ].contains(platform) ||
        event.buttons != kPrimaryMouseButton)
      return;
    final hits = HitTestResult();
    WidgetsBinding.instance.hitTestInView(hits, event.position, event.viewId);
    final formula = hits.path
        .map((hit) => hit.target)
        .whereType<RenderMetaData>()
        .where((hit) => hit.metaData is ({String diaryFormula}))
        .firstOrNull;
    TextSelection? selection;
    if (formula != null) {
      final expression =
          (formula.metaData as ({String diaryFormula})).diaryFormula;
      var occurrence = 0;
      var found = false;
      void count(Element element) {
        if (found) return;
        final render = element is RenderObjectElement
            ? element.renderObject
            : null;
        if (identical(render, formula)) {
          found = true;
          return;
        }
        if (render is RenderMetaData && render.metaData == formula.metaData)
          occurrence++;
        element.visitChildren(count);
      }

      _renderedKey.currentContext?.visitChildElements(count);
      for (final match in DiaryMathInlineSyntax().pattern.allMatches(
        _body.text,
      )) {
        if ((match[1] ?? match[2] ?? match[3] ?? match[4])?.trim() !=
            expression.trim())
          continue;
        if (occurrence-- > 0) continue;
        selection = TextSelection(
          baseOffset: match.start,
          extentOffset: match.end,
        );
        break;
      }
    } else {
      final paragraph = hits.path
          .map((hit) => hit.target)
          .whereType<RenderParagraph>()
          .firstOrNull;
      if (paragraph == null) return;
      final text = paragraph.text.toPlainText();
      var occurrence = 0;
      var found = false;
      void count(Element element) {
        if (found) return;
        final render = element is RenderObjectElement
            ? element.renderObject
            : null;
        if (identical(render, paragraph)) {
          found = true;
          return;
        }
        if (render is RenderParagraph && render.text.toPlainText() == text)
          occurrence++;
        element.visitChildren(count);
      }

      _renderedKey.currentContext?.visitChildElements(count);
      final local = paragraph.globalToLocal(event.position);
      var offset = paragraph.getPositionForOffset(local).offset;
      if (offset > 0 &&
          paragraph
              .getBoxesForSelection(
                TextSelection(baseOffset: offset - 1, extentOffset: offset),
              )
              .any((box) => box.toRect().contains(local)))
        offset--;
      selection = diarySourceLocation(
        _body.text,
        text,
        occurrence: occurrence,
        renderedOffset: offset,
      );
    }
    if (selection == null) return;
    final targetSelection = selection;
    _body.selection = targetSelection;
    _bodyFocus.requestFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _body.selection = targetSelection;
      _bodyFocus.requestFocus();
      void reveal(Element element) {
        if (element is StatefulElement && element.state is EditableTextState) {
          (element.state as EditableTextState).bringIntoView(
            targetSelection.base,
          );
        } else {
          element.visitChildren(reveal);
        }
      }

      _bodyFieldKey.currentContext?.visitChildElements(reveal);
    });
  }

  String _font(BuildContext context) =>
      EcjtuMetrics.phoneLayout(context) ? 'LXGWWenKai' : 'KaiTi';
  String _errorText(Object error) => error
      .toString()
      .replaceFirst('FormatException: ', '')
      .replaceFirst('Bad state: ', '');
  @override
  Widget build(BuildContext context) => _buildDiary(context);
}

class DiaryBody extends StatelessWidget {
  const DiaryBody({
    super.key,
    required this.body,
    required this.markdown,
    required this.storage,
    required this.account,
    required this.style,
    this.imageWidths = const {},
    this.onImageWidthChanged,
  });
  final String body, account;
  final bool markdown;
  final DiaryStorage storage;
  final TextStyle style;
  final Map<String, double> imageWidths;
  final void Function(String id, double width)? onImageWidthChanged;
  Widget _selection(Widget child, BuildContext context) =>
      SelectionContainer.maybeOf(context) != null
      ? child
      : SelectionArea(
          contextMenuBuilder: buildEcjtuSelectionContextMenu,
          child: child,
        );

  Widget _image(String source, String? alt) {
    final id = RegExp(r'^diary-asset:([a-f0-9]{64})$').firstMatch(source)?[1];
    if (id == null) return Text(alt ?? '图片', style: style);
    return DiaryImage(
      key: ValueKey('$account:$id'),
      loadFile: () => storage.assetFile(account, id),
      width: imageWidths[id] ?? 1,
      alt: alt ?? '图片',
      onWidthChanged: onImageWidthChanged == null
          ? null
          : (width) => onImageWidthChanged!(id, width),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!markdown) {
      final pattern = RegExp(r'!\[([^\]]*)\]\((diary-asset:[a-f0-9]{64})\)');
      final children = <Widget>[];
      var offset = 0;
      for (final match in pattern.allMatches(body)) {
        if (match.start > offset) {
          children.add(Text(body.substring(offset, match.start), style: style));
        }
        children.add(_image(match[2]!, match[1]));
        offset = match.end;
      }
      if (offset < body.length) {
        children.add(Text(body.substring(offset), style: style));
      }
      return _selection(
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
        context,
      );
    }
    final rendered = MarkdownBody(
      data: body,
      inlineSyntaxes: [DiaryMathInlineSyntax()],
      blockSyntaxes: const [DiaryMathBlockSyntax()],
      builders: {
        'diary-math': DiaryMathBuilder(style),
        'diary-math-block': DiaryMathBuilder(style, block: true),
      },
      selectable: false,
      extensionSet: md.ExtensionSet.gitHubFlavored,
      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
        p: style,
        h1: style.copyWith(
          fontSize: style.fontSize! * 28 / 18,
          fontWeight: FontWeight.w600,
        ),
        h2: style.copyWith(
          fontSize: style.fontSize! * 25 / 18,
          fontWeight: FontWeight.w600,
        ),
        h3: style.copyWith(
          fontSize: style.fontSize! * 23 / 18,
          fontWeight: FontWeight.w600,
        ),
        h4: style.copyWith(
          fontSize: style.fontSize! * 21 / 18,
          fontWeight: FontWeight.w600,
        ),
        h5: style.copyWith(
          fontSize: style.fontSize! * 20 / 18,
          fontWeight: FontWeight.w600,
        ),
        h6: style.copyWith(
          fontSize: style.fontSize! * 19 / 18,
          fontWeight: FontWeight.w600,
        ),
        code: style.copyWith(fontSize: style.fontSize! * 16 / 18),
        blockquote: style,
        tableHead: style.copyWith(fontWeight: FontWeight.w600),
        tableBody: style,
        listBullet: style,
        a: style.copyWith(color: Theme.of(context).colorScheme.primary),
      ),
      imageBuilder: (uri, title, alt) => _image(uri.toString(), alt),
      onTapLink: (text, href, title) async {
        if (HardwareKeyboard.instance.isControlPressed) return;
        final uri = Uri.tryParse(href ?? '');
        if (uri != null && ['https', 'http'].contains(uri.scheme)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
    );
    return _selection(rendered, context);
  }
}
