// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:typed_data';
import '../../platform/native_document_save.dart';

class PhysicsComponentPdf {
  static Future<bool> Function(Uint8List bytes, String name)? share;
  static Future<bool> sharePdf({
    required Uint8List bytes,
    required String filename,
  }) async => share != null
      ? await share!(bytes, filename)
      : await saveNativeDocument(
              bytes,
              filename,
              mimeType: 'application/pdf',
            ) !=
            null;
}
