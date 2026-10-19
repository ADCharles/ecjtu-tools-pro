// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:typed_data';
import '../../platform/native_document_save.dart';

Future<bool> saveDiaryPdf(Uint8List bytes, String date) async =>
    await saveNativeDocument(
      bytes,
      'diary-$date.pdf',
      mimeType: 'application/pdf',
    ) !=
    null;
