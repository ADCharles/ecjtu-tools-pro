// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

final class _Guid extends Struct {
  @Uint32()
  external int a;
  @Uint16()
  external int b;
  @Uint16()
  external int c;
  @Array(8)
  external Array<Uint8> d;
}

Map<String, String> windowsKnownFolders() {
  if (!Platform.isWindows) return const {};
  final get = DynamicLibrary.open('shell32.dll')
      .lookupFunction<
        Int32 Function(Pointer<_Guid>, Uint32, IntPtr, Pointer<Pointer<Utf16>>),
        int Function(Pointer<_Guid>, int, int, Pointer<Pointer<Utf16>>)
      >('SHGetKnownFolderPath');
  final free = DynamicLibrary.open('ole32.dll')
      .lookupFunction<
        Void Function(Pointer<Void>),
        void Function(Pointer<Void>)
      >('CoTaskMemFree');
  const ids = {
    'desktop': [
      0xB4BFCC3A,
      0xDB2C,
      0x424C,
      0xB0,
      0x29,
      0x7F,
      0xE9,
      0x9A,
      0x87,
      0xC6,
      0x41,
    ],
    'downloads': [
      0x374DE290,
      0x123F,
      0x4565,
      0x91,
      0x64,
      0x39,
      0xC4,
      0x92,
      0x5E,
      0x46,
      0x7B,
    ],
    'documents': [
      0xFDD39AD0,
      0x238F,
      0x46AF,
      0xAD,
      0xB4,
      0x6C,
      0x85,
      0x48,
      0x03,
      0x69,
      0xC7,
    ],
  };
  final paths = <String, String>{};
  for (final entry in ids.entries) {
    final guid = calloc<_Guid>();
    final output = calloc<Pointer<Utf16>>();
    try {
      guid.ref.a = entry.value[0];
      guid.ref.b = entry.value[1];
      guid.ref.c = entry.value[2];
      for (var i = 0; i < 8; i++) {
        guid.ref.d[i] = entry.value[i + 3];
      }
      if (get(guid, 0, 0, output) == 0)
        paths[entry.key] = output.value.toDartString();
    } finally {
      if (output.value != nullptr) free(output.value.cast());
      calloc.free(output);
      calloc.free(guid);
    }
  }
  return paths;
}
