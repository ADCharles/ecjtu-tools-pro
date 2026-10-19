#ifndef ECJTU_NATIVE_BROWSER_BRIDGE_H_
#define ECJTU_NATIVE_BROWSER_BRIDGE_H_
#include <windows.h>

// Dock/undock handshake between the browser plugin and the runner.
//
// The docked browser is one live InAppBrowser window whose HWND becomes a real
// child region of the main window. The runner is the single layout owner: it
// commits the workspace, divider and browser rectangles together, so the drag
// the user is not performing can never move the other region. The plugin only
// reports that it wants to dock or undock and then lets the runner place it.
//
// Both the plugin (packages/flutter_inappwebview_windows) and the runner
// (windows/runner) include this header, so the message ids stay in one place.

namespace ecjtu {

// WPARAM = browser HWND, LPARAM = requested pane width in physical pixels.
inline constexpr UINT kAttachNativeBrowser = WM_APP + 60;
// WPARAM = browser HWND.
inline constexpr UINT kDetachNativeBrowser = WM_APP + 61;
// WPARAM = browser HWND. Removes the browser from the layout without resizing
// the main window; used when the browser is closing or the account changed.
inline constexpr UINT kReleaseNativeBrowser = WM_APP + 66;
// WPARAM = current pane HWND, LPARAM = replacement pane HWND.
inline constexpr UINT kReplaceNativeBrowser = WM_APP + 67;

// Browser pane metrics, in logical pixels at 96 DPI.
inline constexpr double kBrowserPaneMinimumWidth = 380.0;
inline constexpr double kBrowserWorkspaceMinimumWidth = 360.0;
inline constexpr double kBrowserSplitterWidth = 6.0;

inline int ScaleForDpi(HWND window, double logical) {
  UINT dpi = window == nullptr ? 96 : GetDpiForWindow(window);
  if (dpi == 0) dpi = 96;
  return static_cast<int>(logical * dpi / 96.0 + 0.5);
}

}  // namespace ecjtu

#endif  // ECJTU_NATIVE_BROWSER_BRIDGE_H_
