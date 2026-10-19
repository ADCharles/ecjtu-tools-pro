// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

String? webDocumentTitle(String? value, {required bool mobile}) {
  final title = value?.trim() ?? '';
  if (title.isEmpty) return null;
  // WebView2 also emits URL-shaped titles while a navigation is in flight.
  final url = Uri.tryParse(title);
  if (url != null &&
      {
        'http',
        'https',
        'about',
        'data',
        'file',
        'blob',
        'javascript',
        'chrome',
        'edge',
      }.contains(url.scheme.toLowerCase())) {
    return null;
  }
  if (title.startsWith('//') ||
      RegExp(r'^(?:[a-z]:[\\/]|\\\\)', caseSensitive: false).hasMatch(title)) {
    return null;
  }
  if (!title.contains(RegExp(r'\s')) &&
      RegExp(
        r'^(?:www\.)?[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)+(?:[/:?#].*)?$',
      ).hasMatch(title)) {
    return null;
  }
  return title;
}
