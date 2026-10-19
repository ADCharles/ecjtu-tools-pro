#pragma once
#include <windows.h>
#include <array>
#include <cstdio>

namespace ecjtu {
// Opt-in, memory-buffered timing: never perform file I/O inside WM_SIZE.
class ResizeTiming {
 public:
  struct Entry { LONGLONG start, elapsed; int stage; LONG width, height; };
  static bool Enabled() {
    static bool enabled = GetEnvironmentVariableW(L"ECJTU_RESIZE_TIMING", nullptr, 0) > 0;
    return enabled;
  }
  ResizeTiming(int stage, HWND window) : stage_(stage) {
    if (!Enabled()) return;
    RECT rect{}; GetClientRect(window, &rect);
    width_ = rect.right; height_ = rect.bottom;
    QueryPerformanceCounter(&start_);
  }
  ~ResizeTiming() {
    if (!Enabled()) return;
    LARGE_INTEGER end{}; QueryPerformanceCounter(&end);
    const auto index = count_++ % entries_.size();
    entries_[index] = {start_.QuadPart, end.QuadPart - start_.QuadPart, stage_, width_, height_};
  }
  static void Flush() {
    if (!Enabled() || count_ == 0) return;
    wchar_t directory[MAX_PATH]{}; GetTempPathW(MAX_PATH, directory);
    wchar_t path[MAX_PATH]{};
    swprintf_s(path, L"%secjtu-resize-%lu.tsv", directory, GetCurrentProcessId());
    FILE* file = nullptr; _wfopen_s(&file, path, L"a");
    if (!file) return;
    LARGE_INTEGER frequency{}; QueryPerformanceFrequency(&frequency);
    const size_t begin = count_ > entries_.size() ? count_ - entries_.size() : 0;
    for (size_t i = begin; i < count_; ++i) {
      const auto& e = entries_[i % entries_.size()];
      fprintf(file, "%lld\t%d\t%ld\t%ld\t%.3f\n", e.start, e.stage,
        e.width, e.height, e.elapsed * 1000.0 / frequency.QuadPart);
    }
    fclose(file); count_ = 0;
  }
 private:
  int stage_; LONG width_ = 0, height_ = 0; LARGE_INTEGER start_{};
  static inline std::array<Entry, 4096> entries_{};
  static inline size_t count_ = 0;
};
}
