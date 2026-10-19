// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:pdfrx_engine/pdfrx_engine.dart';
import 'package:pointycastle/digests/sha256.dart';

import 'document_text_search.dart';

class PdfContentReader {
  final _indexes = <String, List<Map<String, Object?>>>{};
  static Future<void>? _initialization;
  static const maxBytes = 32 * 1024 * 1024;
  static const maxPagesPerRead = 24;
  static const maxCharactersPerRead = 120000;

  Future<Map<String, Object?>> search(
    Uint8List bytes, {
    required String query,
    int offset = 0,
    int limit = 8,
    bool Function()? isCancelled,
  }) async {
    DocumentTextSearch.search(
      const [],
      query: query,
      offset: offset,
      limit: limit,
    );
    final digest = base64Url.encode(SHA256Digest().process(bytes));
    var index = _indexes[digest];
    if (index == null) {
      final document = await _open(bytes);
      try {
        index = <Map<String, Object?>>[];
        var characters = 0;
        for (final page in document.pages) {
          if (isCancelled?.call() == true) throw StateError('cancelled');
          final text = (await page.loadText())?.fullText ?? '';
          characters += text.length;
          if (characters > 8 * 1024 * 1024) {
            throw const FormatException('Document text index exceeds capacity');
          }
          index.add({'pageNumber': page.pageNumber, 'text': text});
        }
        if (isCancelled?.call() == true) throw StateError('cancelled');
        _indexes[digest] = index;
        while (_indexes.length > 2) _indexes.remove(_indexes.keys.first);
      } finally {
        await document.dispose();
      }
    }
    if (isCancelled?.call() == true) throw StateError('cancelled');
    return DocumentTextSearch.search(
      index,
      query: query,
      offset: offset,
      limit: limit,
    );
  }

  Future<void> _initialize() async {
    final pending = _initialization ??= _initializeEngine();
    try {
      await pending;
    } catch (_) {
      if (identical(_initialization, pending)) _initialization = null;
      rethrow;
    }
  }

  Future<void> _initializeEngine() async {
    Pdfrx.loadAsset ??= (name) async {
      final data = await rootBundle.load(name);
      return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    };
    await PdfrxEntryFunctions.instance.init();
  }

  Future<PdfDocument> _open(Uint8List bytes) async {
    if (bytes.length < 5 ||
        bytes.length > maxBytes ||
        String.fromCharCodes(bytes.sublist(0, 5)) != '%PDF-') {
      throw const FormatException('Invalid PDF document');
    }
    await _initialize();
    return PdfDocument.openData(bytes, sourceName: 'application-document');
  }

  Future<Map<String, Object?>> read(
    Uint8List bytes, {
    int offset = 0,
    int limit = 8,
    bool Function()? isCancelled,
  }) async {
    if (offset < 0 || limit < 1 || limit > maxPagesPerRead) {
      throw const FormatException('Invalid page range');
    }
    final document = await _open(bytes);
    try {
      final pages = <Map<String, Object?>>[];
      var characters = 0;
      var truncatedText = false;
      for (final page in document.pages.skip(offset).take(limit)) {
        if (isCancelled?.call() == true) throw StateError('cancelled');
        final raw = await page.loadText();
        final full = (raw?.fullText ?? '')
            .replaceAll('\r\n', '\n')
            .replaceAll('\u0000', '')
            .trim();
        final remaining = maxCharactersPerRead - characters;
        if (remaining <= 0) break;
        final text = full.length <= remaining
            ? full
            : full.substring(0, remaining);
        characters += text.length;
        truncatedText |= text.length < full.length;
        pages.add({
          'pageNumber': page.pageNumber,
          'width': page.width,
          'height': page.height,
          'text': text,
          'hasText': text.isNotEmpty,
          'truncated': text.length < full.length,
        });
        if (truncatedText) break;
      }
      final next = offset + pages.length;
      final hasText = pages.any((p) => p['hasText'] == true);
      return {
        'available': true,
        'contentStatus': hasText ? 'text' : 'no_text',
        'pageCount': document.pages.length,
        'offset': offset,
        'nextOffset': next < document.pages.length ? next : null,
        'truncatedText': truncatedText,
        'pages': pages,
      };
    } finally {
      await document.dispose();
    }
  }

  Future<Uint8List> renderPage(Uint8List bytes, int pageNumber) async {
    final document = await _open(bytes);
    try {
      if (pageNumber < 1 || pageNumber > document.pages.length) {
        throw const FormatException('Invalid page number');
      }
      final page = document.pages[pageNumber - 1];
      final scale =
          2200 / (page.width > page.height ? page.width : page.height);
      final raster = await page.render(
        fullWidth: page.width * scale,
        fullHeight: page.height * scale,
      );
      if (raster == null) throw StateError('PDF page unavailable');
      try {
        final image = Completer<ui.Image>();
        ui.decodeImageFromPixels(
          raster.pixels,
          raster.width,
          raster.height,
          ui.PixelFormat.bgra8888,
          image.complete,
        );
        final decoded = await image.future;
        try {
          final png = await decoded.toByteData(format: ui.ImageByteFormat.png);
          if (png == null) throw StateError('PDF image unavailable');
          return png.buffer.asUint8List(png.offsetInBytes, png.lengthInBytes);
        } finally {
          decoded.dispose();
        }
      } finally {
        raster.dispose();
      }
    } finally {
      await document.dispose();
    }
  }
}
