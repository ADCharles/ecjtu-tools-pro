// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'package:ecjtu_tools_core/widgets/ecjtu_text_context_menu.dart';
import 'dart:io';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../theme/ecjtu_theme.dart';
import '../../widgets/ecjtu_document_scroll_view.dart';

class OpenSourceNoticesPage extends StatelessWidget {
  const OpenSourceNoticesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final page = Scaffold(
      appBar: AppBar(
        title: const Text('开源软件声明'),
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      body: const OpenSourceNoticesContent(),
    );
    if (!Platform.isWindows) return page;
    final titleInset = MediaQuery.paddingOf(context).top;
    return Padding(
      padding: EdgeInsets.only(top: titleInset),
      child: MediaQuery.removePadding(
        context: context,
        removeTop: true,
        child: page,
      ),
    );
  }
}

class OpenSourceNoticesContent extends StatefulWidget {
  const OpenSourceNoticesContent({super.key, this.embedded = false});

  final bool embedded;
  static final _prepared = <TargetPlatform, _NoticeBundle>{};

  @visibleForTesting
  static void clearPreparedNotices() => _prepared.clear();

  @override
  State<OpenSourceNoticesContent> createState() =>
      _OpenSourceNoticesContentState();
}

class _OpenSourceNoticesContentState extends State<OpenSourceNoticesContent> {
  StreamIterator<LicenseEntry>? _licenses;
  late final Future<_NoticeBundle?> _bundle;

  @override
  void initState() {
    super.initState();
    final platform = defaultTargetPlatform;
    final cached = OpenSourceNoticesContent._prepared[platform];
    if (cached != null) {
      _bundle = Future.value(cached);
    } else {
      _licenses = StreamIterator(LicenseRegistry.licenses);
      _bundle = _loadNotices(platform);
    }
  }

  Future<_NoticeBundle?> _loadNotices(TargetPlatform platform) async {
    final entries = <LicenseEntry>[];
    final licenses = _licenses!;
    while (mounted && await licenses.moveNext()) {
      if (!mounted) return null;
      entries.add(licenses.current);
      if (entries.length % 4 == 0) {
        await Future<void>.delayed(Duration.zero);
      }
    }
    if (!mounted) return null;
    final bundle = await compute(_buildNoticeBundle, (platform, entries));
    if (mounted) OpenSourceNoticesContent._prepared[platform] = bundle;
    return bundle;
  }

  @override
  void dispose() {
    if (_licenses case final licenses?) unawaited(licenses.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_NoticeBundle?>(
      future: _bundle,
      builder: (context, snapshot) =>
          buildBody(context, snapshot, embedded: widget.embedded),
    );
  }

  static Widget buildBody(
    BuildContext context,
    AsyncSnapshot<_NoticeBundle?> snapshot, {
    required bool embedded,
  }) {
    final ink = EcjtuColors.textFor(context);
    final muted = EcjtuColors.mutedFor(context);
    if (!snapshot.hasData) {
      if (snapshot.hasError) {
        return Center(
          child: Text('许可证信息读取失败', style: TextStyle(color: muted)),
        );
      }
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Text('正在读取', style: TextStyle(color: muted)),
      );
    }
    final bundle = snapshot.data!;
    return SelectionArea(
      contextMenuBuilder: buildEcjtuPlatformSelectionContextMenu,
      child: EcjtuDocumentScrollView.builder(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 44),
        itemCount: bundle.blocks.length,
        itemBuilder: (context, index) {
          final block = bundle.blocks[index];
          if (block.kind == _NoticeKind.divider) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Divider(height: 1, color: EcjtuColors.borderFor(context)),
            );
          }
          final heading = block.kind == _NoticeKind.heading;
          final platform = block.kind == _NoticeKind.platform;
          return Padding(
            padding: EdgeInsets.only(
              bottom: heading
                  ? 3
                  : platform
                  ? 18
                  : 12,
            ),
            child: Text(
              block.text,
              style: TextStyle(
                color: heading || platform ? ink : muted,
                fontSize: heading
                    ? 16
                    : platform
                    ? 15
                    : 13,
                fontWeight: heading ? FontWeight.w700 : FontWeight.normal,
                height: 1.55,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NoticeBundle {
  const _NoticeBundle({required this.blocks});

  final List<_NoticeBlock> blocks;
}

enum _NoticeKind { platform, heading, body, divider }

class _NoticeBlock {
  const _NoticeBlock(this.text, this.kind);
  final String text;
  final _NoticeKind kind;
}

Iterable<_NoticeBlock> _textBlocks(String text) sync* {
  const limit = 2400;
  for (var start = 0; start < text.length;) {
    var end = (start + limit).clamp(0, text.length);
    if (end < text.length) {
      final line = text.lastIndexOf('\n', end);
      if (line > start) end = line + 1;
      final previous = text.codeUnitAt(end - 1);
      if (previous >= 0xD800 && previous <= 0xDBFF) end--;
    }
    yield _NoticeBlock(text.substring(start, end), _NoticeKind.body);
    start = end;
  }
}

class _ComponentNotice {
  const _ComponentNotice({required this.name, required this.licenseNames});

  final String name;
  final List<String> licenseNames;
}

class _LicenseNotice {
  const _LicenseNotice({
    required this.packages,
    required this.licenseName,
    required this.text,
  });

  final List<String> packages;
  final String licenseName;
  final String text;
}

_NoticeBundle _buildNoticeBundle((TargetPlatform, List<LicenseEntry>) input) {
  final (platform, entries) = input;
  final platformPackages = _packagesFor(platform);
  final allPlatformPackages = _platformPackages.values
      .expand((packages) => packages)
      .followedBy(_webOnlyPackages)
      .toSet();
  final notices = <_LicenseNotice>[];
  final componentLicenses = <String, Set<String>>{};
  for (final entry in entries) {
    final packages =
        entry.packages
            .where(
              (package) =>
                  !allPlatformPackages.contains(package) ||
                  platformPackages.contains(package),
            )
            .toSet()
            .toList()
          ..sort();
    if (packages.isEmpty) continue;
    final text = entry.paragraphs.map(_paragraphText).join('\n\n').trim();
    if (text.isEmpty) continue;
    final licenseName = licenseNameForText(text);
    for (final package in packages) {
      componentLicenses.putIfAbsent(package, () => <String>{}).add(licenseName);
    }
    notices.add(
      _LicenseNotice(packages: packages, licenseName: licenseName, text: text),
    );
  }
  notices.sort((a, b) => a.packages.first.compareTo(b.packages.first));
  final components =
      componentLicenses.entries
          .map(
            (entry) => _ComponentNotice(
              name: entry.key,
              licenseNames: entry.value.toList()..sort(),
            ),
          )
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
  final platformLabel = switch (platform) {
    TargetPlatform.windows => 'Windows',
    TargetPlatform.android => 'Android',
    TargetPlatform.iOS => 'iOS',
    TargetPlatform.macOS => 'macOS',
    TargetPlatform.linux => 'Linux',
    TargetPlatform.fuchsia => 'Fuchsia',
  };
  return _NoticeBundle(
    blocks: [
      _NoticeBlock(
        '${platformLabel.toUpperCase()} COMPONENTS:',
        _NoticeKind.platform,
      ),
      ..._textBlocks(
        components
            .map((item) => '${item.name} : ${item.licenseNames.join(' / ')}')
            .join('\n'),
      ),
      const _NoticeBlock('', _NoticeKind.divider),
      for (final notice in notices) ...[
        _NoticeBlock(notice.packages.join('、'), _NoticeKind.heading),
        _NoticeBlock(notice.licenseName, _NoticeKind.body),
        ..._textBlocks(notice.text),
        const _NoticeBlock('', _NoticeKind.divider),
      ],
    ],
  );
}

String _paragraphText(LicenseParagraph paragraph) {
  if (paragraph.indent <= 0) return paragraph.text;
  return '${'  ' * paragraph.indent}${paragraph.text}';
}

@visibleForTesting
String licenseNameForText(String text) {
  final value = text.toLowerCase();
  if (value.contains('apache license') && value.contains('version 2.0')) {
    return 'Apache License 2.0';
  }
  if (value.contains('mozilla public license') || value.contains('mpl 2.0')) {
    return 'Mozilla Public License 2.0';
  }
  if (value.contains('gnu lesser general public license')) return 'LGPL';
  if (value.contains('gnu general public license')) return 'GPL';
  if (value.contains('permission is hereby granted, free of charge')) {
    return 'MIT License';
  }
  if (value.contains('neither the name') &&
      value.contains('redistribution and use in source and binary forms')) {
    return 'BSD 3-Clause';
  }
  if (value.contains('redistribution and use in source and binary forms')) {
    return 'BSD License';
  }
  if (value.contains('isc license') ||
      (value.contains('permission to use, copy, modify, and/or distribute') &&
          value.contains('with or without fee is hereby granted'))) {
    return 'ISC License';
  }
  if (value.contains('sil open font license')) return 'SIL Open Font License';
  if (value.contains('zlib license') ||
      value.contains('this software is provided \'as-is\'')) {
    return 'zlib License';
  }
  return 'Open Source License';
}

Set<String> _packagesFor(TargetPlatform platform) =>
    _platformPackages[platform] ?? const <String>{};

const _platformPackages = <TargetPlatform, Set<String>>{
  TargetPlatform.windows: {
    'file_selector_windows',
    'flutter_inappwebview_windows',
    'flutter_secure_storage_windows',
    'jni',
    'path_provider_windows',
    'screen_retriever_windows',
    'shared_preferences_windows',
    'url_launcher_windows',
    'webview_windows',
    'window_manager',
  },
  TargetPlatform.android: {
    'file_selector_android',
    'flutter_inappwebview_android',
    'jni',
    'jni_flutter',
    'path_provider_android',
    'shared_preferences_android',
    'url_launcher_android',
  },
  TargetPlatform.iOS: {
    'file_selector_ios',
    'flutter_inappwebview_ios',
    'path_provider_foundation',
    'shared_preferences_foundation',
    'url_launcher_ios',
  },
  TargetPlatform.macOS: {
    'file_selector_macos',
    'flutter_inappwebview_macos',
    'flutter_secure_storage_macos',
    'path_provider_foundation',
    'screen_retriever_macos',
    'shared_preferences_foundation',
    'url_launcher_macos',
  },
  TargetPlatform.linux: {
    'file_selector_linux',
    'flutter_secure_storage_linux',
    'path_provider_linux',
    'screen_retriever_linux',
    'shared_preferences_linux',
    'url_launcher_linux',
  },
  TargetPlatform.fuchsia: {},
};

const _webOnlyPackages = <String>{
  'file_selector_web',
  'flutter_inappwebview_web',
  'flutter_secure_storage_web',
  'shared_preferences_web',
  'url_launcher_web',
};
