#ifndef ECJTU_WINDOW_RESIZE_H_
#define ECJTU_WINDOW_RESIZE_H_
#include <algorithm>
#include <windows.h>
#include <windowsx.h>

namespace ecjtu {
inline RECT ClipWebViewFrame(RECT frame, const RECT& client,
                            int border, bool surface_locked) {
  if (!surface_locked)
    frame.right = (std::min)(frame.right, (std::max)(frame.left, client.right - border));
  frame.bottom = (std::min)(frame.bottom, (std::max)(frame.top, client.bottom - border));
  return frame;
}
inline int ResizeBorder(HWND window) {
  const UINT dpi = GetDpiForWindow(window);
  return IsZoomed(window) ? 0 : MulDiv(6, dpi ? dpi : 96, 96);
}
inline void ApplyMaximizedWorkArea(HWND window, MINMAXINFO* info) {
  MONITORINFO monitor{sizeof(MONITORINFO)};
  if (!GetMonitorInfo(MonitorFromWindow(window, MONITOR_DEFAULTTONEAREST), &monitor)) return;
  info->ptMaxPosition = {monitor.rcWork.left - monitor.rcMonitor.left,
    monitor.rcWork.top - monitor.rcMonitor.top};
  info->ptMaxSize = {monitor.rcWork.right - monitor.rcWork.left,
    monitor.rcWork.bottom - monitor.rcWork.top};
}
inline LRESULT ResizeHitTest(HWND window, LPARAM position) {
  const int edge = ResizeBorder(window);
  if (!edge) return HTCLIENT;
  POINT point{GET_X_LPARAM(position), GET_Y_LPARAM(position)};
  ScreenToClient(window, &point);
  RECT client{};
  GetClientRect(window, &client);
  const bool left = point.x < edge;
  const bool right = point.x >= client.right - edge;
  const bool top = point.y < edge;
  const bool bottom = point.y >= client.bottom - edge;
  if (top && left) return HTTOPLEFT;
  if (top && right) return HTTOPRIGHT;
  if (bottom && left) return HTBOTTOMLEFT;
  if (bottom && right) return HTBOTTOMRIGHT;
  if (left) return HTLEFT;
  if (right) return HTRIGHT;
  if (top) return HTTOP;
  if (bottom) return HTBOTTOM;
  return HTCLIENT;
}
}
#endif
