// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:ffi';
import 'dart:io';

abstract final class WindowsPasswordIme {
  static void preferLatin() {
    if (!Platform.isWindows) return;
    try {
      final user32 = DynamicLibrary.open('user32.dll');
      final imm32 = DynamicLibrary.open('imm32.dll');
      final getForegroundWindow = user32
          .lookupFunction<IntPtr Function(), int Function()>(
            'GetForegroundWindow',
          );
      final hwnd = getForegroundWindow();
      if (hwnd == 0) return;
      final immGetContext = imm32
          .lookupFunction<IntPtr Function(IntPtr), int Function(int)>(
            'ImmGetContext',
          );
      final himc = immGetContext(hwnd);
      if (himc == 0) return;
      final immSetOpenStatus = imm32
          .lookupFunction<
            Int32 Function(IntPtr, Int32),
            int Function(int, int)
          >('ImmSetOpenStatus');
      immSetOpenStatus(himc, 0);
      final immSetConversionStatus = imm32
          .lookupFunction<
            Int32 Function(IntPtr, Uint32, Uint32),
            int Function(int, int, int)
          >('ImmSetConversionStatus');
      immSetConversionStatus(himc, 0, 0);
      final immReleaseContext = imm32
          .lookupFunction<
            Int32 Function(IntPtr, IntPtr),
            int Function(int, int)
          >('ImmReleaseContext');
      immReleaseContext(hwnd, himc);
    } catch (_) {}
  }
}
