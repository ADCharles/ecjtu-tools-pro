// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

final class _BasicLimits extends Struct {
  @Int64()
  external int processTime;
  @Int64()
  external int jobTime;
  @Uint32()
  external int flags;
  @UintPtr()
  external int minimumWorkingSet;
  @UintPtr()
  external int maximumWorkingSet;
  @Uint32()
  external int activeProcesses;
  @UintPtr()
  external int affinity;
  @Uint32()
  external int priority;
  @Uint32()
  external int scheduling;
}

final class _ExtendedLimits extends Struct {
  external _BasicLimits basic;
  @Array(6)
  external Array<Uint64> io;
  @UintPtr()
  external int processMemory;
  @UintPtr()
  external int jobMemory;
  @UintPtr()
  external int peakProcessMemory;
  @UintPtr()
  external int peakJobMemory;
}

/// Owns a process tree's lifetime, not a filesystem or security sandbox.
class WindowsProcessJob {
  WindowsProcessJob._(this._handle);
  static final _kernel = DynamicLibrary.open('kernel32.dll');
  static final _close = _kernel
      .lookupFunction<Int32 Function(IntPtr), int Function(int)>('CloseHandle');
  int _handle;

  static WindowsProcessJob attach(int pid) {
    final create = _kernel
        .lookupFunction<
          IntPtr Function(Pointer<Void>, Pointer<Utf16>),
          int Function(Pointer<Void>, Pointer<Utf16>)
        >('CreateJobObjectW');
    final set = _kernel
        .lookupFunction<
          Int32 Function(IntPtr, Int32, Pointer<Void>, Uint32),
          int Function(int, int, Pointer<Void>, int)
        >('SetInformationJobObject');
    final open = _kernel
        .lookupFunction<
          IntPtr Function(Uint32, Int32, Uint32),
          int Function(int, int, int)
        >('OpenProcess');
    final assign = _kernel
        .lookupFunction<Int32 Function(IntPtr, IntPtr), int Function(int, int)>(
          'AssignProcessToJobObject',
        );
    final job = create(nullptr, nullptr);
    if (job == 0) throw const FileSystemException('Process job unavailable');
    final limits = calloc<_ExtendedLimits>();
    var process = 0;
    try {
      limits.ref.basic.flags = 0x2000; // JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE
      if (set(job, 9, limits.cast(), sizeOf<_ExtendedLimits>()) == 0) {
        throw const FileSystemException('Process job configuration failed');
      }
      process = open(0x0101, 0, pid); // PROCESS_SET_QUOTA | PROCESS_TERMINATE
      if (process == 0 || assign(job, process) == 0) {
        throw const FileSystemException('Process job assignment failed');
      }
      return WindowsProcessJob._(job);
    } catch (_) {
      _close(job);
      rethrow;
    } finally {
      if (process != 0) _close(process);
      calloc.free(limits);
    }
  }

  void close() {
    if (_handle == 0) return;
    _close(_handle);
    _handle = 0;
  }
}
