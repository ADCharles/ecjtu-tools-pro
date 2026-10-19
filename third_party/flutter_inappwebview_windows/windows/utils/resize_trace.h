#pragma once
#include <windows.h>
#include <array>
#include <cstdio>

namespace ecjtu {
// Opt-in tracing of the native web-pane resize path. Events are
// buffered in memory and flushed to a TSV on WM_EXITSIZEMOVE only; never
// perform file I/O inside WM_SIZE/WM_SIZING. Enable with ECJTU_RESIZE_LOG=1.
//
// Tag map (tag, meaning, columns a..d):
//  16 WM_EXITSIZEMOVE(parent)   17 WM_ENTERSIZEMOVE   18 WM_SIZING edge
//   1 ApplyNativeFrame frame (post-clamp l,r,t,b)
//   2 put_Bounds fired (old.width, old.height, new.width, new.height)
//   3 SetWindowPos host (left, top, width, height)
//   4 SetWindowRgn fired (l, r, t, b)
//   5 setGeometry accepted (reportedW, client.r, frame.r, right_gap)
//   6 setGeometry rejected (same columns)
//   7 ParentProc WM_SIZE fixedPane branch (client.r, fixedPane, frame.l, frame.r)
//   9 ParentProc WM_SIZE generic branch (client.r, surface.r, frame.r, right_gap)
//  10 HostProc WM_SIZE put_Bounds fired (l, r, t, b)
//  11 HostProc WM_SIZE put_Bounds skipped (l, r, t, b)
//  21 NotifyClientViewport (width, height, resize_left, pane_width)
//  20 WM_SIZING left-edge branch (client_width, fixed_pane, workspace, 0)
//  24 WM_EXITSIZEMOVE runner (workspace, pane, 0, 0)
class ResizeTrace {
 public:
  struct Entry { LONGLONG when; int tag; LONG a, b, c, d; };
  static bool Enabled() {
    static bool enabled = GetEnvironmentVariableW(L"ECJTU_RESIZE_LOG", nullptr, 0) > 0;
    return enabled;
  }
  static void Write(int tag, LONG a, LONG b, LONG c, LONG d) {
    if (!Enabled()) return;
    LARGE_INTEGER now{}; QueryPerformanceCounter(&now);
    const auto index = count_++ % entries_.size();
    entries_[index] = {now.QuadPart, tag, a, b, c, d};
  }
  static void Flush() {
    if (!Enabled() || count_ == 0) return;
    wchar_t directory[MAX_PATH]{};
    GetTempPathW(MAX_PATH, directory);
    wchar_t path[MAX_PATH]{};
    swprintf_s(path, L"%secjtu-resize-trace-%lu.tsv", directory, GetCurrentProcessId());
    FILE* file = nullptr;
    _wfopen_s(&file, path, L"a");
    if (!file) return;
    LARGE_INTEGER frequency{};
    QueryPerformanceFrequency(&frequency);
    fprintf(file, "#qpc\tfreq=%lld\n", frequency.QuadPart);
    const size_t begin = count_ > entries_.size() ? count_ - entries_.size() : 0;
    for (size_t i = begin; i < count_; ++i) {
      const auto& e = entries_[i % entries_.size()];
      fprintf(file, "%lld\t%d\t%ld\t%ld\t%ld\t%ld\n",
        e.when, e.tag, e.a, e.b, e.c, e.d);
    }
    fclose(file);
    count_ = 0;
  }
 private:
  static inline std::array<Entry, 16384> entries_{};
  static inline size_t count_ = 0;
};
}
