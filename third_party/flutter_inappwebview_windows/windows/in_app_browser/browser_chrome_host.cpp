#include "browser_chrome_host.h"
#include "../utils/window_resize.h"
#include <flutter/standard_method_codec.h>
#include <filesystem>
#include <algorithm>
#include <cmath>

namespace flutter_inappwebview_plugin {
namespace {
constexpr UINT kLayoutChrome = WM_APP + 0x4f1;
double number(const flutter::EncodableMap& map, const char* key) {
  auto it = map.find(flutter::EncodableValue(key));
  if (it == map.end()) return 0;
  if (auto d = std::get_if<double>(&it->second)) return *d;
  if (auto i = std::get_if<int32_t>(&it->second)) return *i;
  return 0;
}
}
BrowserChromeHost::BrowserChromeHost(HWND parent, std::function<Map()> state,
  std::function<void(const Map&)> action, std::function<void(double)> height)
  : parent_(parent), state_(std::move(state)) {
  wchar_t executable[32768]{};
  GetModuleFileNameW(nullptr, executable, 32768);
  flutter::DartProject project((std::filesystem::path(executable).parent_path() / L"data").wstring());
  project.set_dart_entrypoint("browserChromeMain");
  project.set_ui_thread_policy(flutter::UIThreadPolicy::RunOnSeparateThread);
  RECT client{};
  GetClientRect(parent_, &client);
  MONITORINFO monitor{sizeof(monitor)};
  GetMonitorInfo(MonitorFromWindow(parent_, MONITOR_DEFAULTTONEAREST), &monitor);
  controller_ = std::make_unique<flutter::FlutterViewController>(
    (std::max)(client.right, monitor.rcWork.right - monitor.rcWork.left),
    (std::max)(1L, client.bottom), project);
  if (!valid()) return;
  HWND view = controller_->view()->GetNativeWindow();
  SetParent(view, parent_);
  // Flutter creates its host offscreen; SetParent preserves that position.
  SetWindowPos(view, HWND_TOP, 0, 0, 0, 0, SWP_NOSIZE | SWP_NOACTIVATE);
  ShowWindow(view, SW_HIDE);
  SetWindowSubclass(view, ViewProc, 1, reinterpret_cast<DWORD_PTR>(this));
  channel_ = std::make_unique<flutter::MethodChannel<Value>>(
    controller_->engine()->messenger(), "ecjtu/browser_chrome",
    &flutter::StandardMethodCodec::GetInstance());
  channel_->SetMethodCallHandler([this, action = std::move(action), height = std::move(height)](
    const flutter::MethodCall<Value>& call, std::unique_ptr<flutter::MethodResult<Value>> result) {
    if (call.method_name() == "ready") {
      ready_ = true;
      auto state = snapshot();
      const auto found = state.find(Value("contentReady"));
      contentReady_ = found != state.end() && std::get<bool>(found->second);
      updateRegion();
      const HWND view = controller_->view()->GetNativeWindow();
      controller_->engine()->SetNextFrameCallback([view, alive = alive_]() {
        if (*alive && IsWindow(view)) ShowWindow(view, SW_SHOWNOACTIVATE);
      });
      result->Success(Value(state));
      controller_->ForceRedraw();
    } else if (call.method_name() == "action") {
      auto map = std::get_if<Map>(call.arguments());
      if (map) action(*map);
      result->Success();
    } else if (call.method_name() == "height") {
      const auto* value = std::get_if<double>(call.arguments());
      if (value && std::isfinite(*value) && *value >= 80 && *value < 300) {
        height_ = *value;
        height(*value);
        layout(height_);
      }
      result->Success();
    } else if (call.method_name() == "popup") {
      popup_.reset();
      if (auto map = std::get_if<Map>(call.arguments())) {
        const double scale = GetDpiForWindow(parent_) / 96.0;
        popup_ = RECT{static_cast<LONG>(std::floor(number(*map,"left") * scale)),
          static_cast<LONG>(std::floor(number(*map,"top") * scale)),
          static_cast<LONG>(std::ceil(number(*map,"right") * scale)),
          static_cast<LONG>(std::ceil(number(*map,"bottom") * scale))};
      }
      updateRegion();
      result->Success();
    } else result->NotImplemented();
  });
  layout(height_);

}
BrowserChromeHost::~BrowserChromeHost() {
  *alive_ = false;
  if (channel_) channel_->SetMethodCallHandler(nullptr);
  channel_.reset();
  if (valid()) RemoveWindowSubclass(controller_->view()->GetNativeWindow(), ViewProc, 1);
  controller_.reset();
}
void BrowserChromeHost::layout(double height) {
  if (!valid()) return;
  height_ = height;
  updateRegion();
  if (!layoutPending_) {
    layoutPending_ = PostMessage(controller_->view()->GetNativeWindow(),
      kLayoutChrome, 0, 0) != FALSE;
  }
}
void BrowserChromeHost::updateRegion() {
  if (!valid()) return;
  RECT client{};
  GetClientRect(parent_, &client);
  const UINT dpi = GetDpiForWindow(parent_);
  const auto state = state_();
  const auto error = state.find(Value("error"));
  const auto* errorText = error == state.end() ? nullptr : std::get_if<std::string>(&error->second);
  const int bottom = errorText && !errorText->empty() ? client.bottom
      : static_cast<int>(std::ceil(height_ * dpi / 96.0));
  const HWND view = controller_->view()->GetNativeWindow();
  const int viewHeight = (std::max)(bottom,
    popup_ ? static_cast<int>(popup_->bottom) : bottom);
  RECT previous{};
  GetClientRect(view, &previous);
  // Capacity is independent of the live viewport. Only the title's scene
  // layout changes per WM_SIZE; the native WebView keeps its direct Bounds path.
  // No page pixels, zoom or captured frames pass through this surface.
  const int chromeCapacity = static_cast<int>(std::ceil((height_ + 320) * dpi / 96.0));
  const int capacityHeight = contentReady_
      ? (((std::max)(viewHeight, chromeCapacity) + 255) / 256) * 256
      : (std::max)(static_cast<int>(previous.bottom), ((viewHeight + 255) / 256) * 256);
  if (previous.right != client.right || previous.bottom != capacityHeight) {
    SetWindowPos(view, HWND_TOP, 0, 0, client.right, capacityHeight, SWP_NOACTIVATE);
  }
  const int regionWidth = (std::max)(static_cast<int>(client.right),
    GetSystemMetrics(SM_CXVIRTUALSCREEN));
  HRGN region = CreateRectRgn(0, 0, regionWidth, bottom);
  if (popup_) {
    HRGN menu = CreateRectRgn(popup_->left, popup_->top,
      popup_->right, popup_->bottom);
    CombineRgn(region, region, menu, RGN_OR);
    DeleteObject(menu);
  }
  HRGN previousRegion = CreateRectRgn(0, 0, 0, 0);
  const bool unchanged = GetWindowRgn(view, previousRegion) != ERROR && EqualRgn(previousRegion, region);
  DeleteObject(previousRegion);
  if (unchanged) DeleteObject(region);
  else {
    // The Flutter viewport update paints the new title contents. Forcing a
    // second whole-child redraw here on every width change flashes the chrome.
    SetWindowRgn(view, region, FALSE);
  }
  if (popup_)
    SetWindowPos(view, HWND_TOP, 0, 0, 0, 0,
      SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE);
}
BrowserChromeHost::Map BrowserChromeHost::snapshot() {
  auto state = state_();
  RECT client{};
  GetClientRect(parent_, &client);
  const double scale = GetDpiForWindow(parent_) / 96.0;
  state[Value("viewportWidth")] = Value(client.right / scale);
  state[Value("viewportHeight")] = Value(client.bottom / scale);
  return state;
}
void BrowserChromeHost::publish() {
  auto state = snapshot();
  auto found = state.find(Value("contentReady"));
  const bool contentReady = found != state.end() && std::get<bool>(found->second);
  if (contentReady_ != contentReady) {
    contentReady_ = contentReady;
    layout(height_);
  } else {
    updateRegion();
  }
  if (ready_ && channel_) channel_->InvokeMethod("state", std::make_unique<Value>(state));
}
void BrowserChromeHost::dismissMenu() {
  if (!popup_) return;
  if (ready_ && channel_) channel_->InvokeMethod("dismissMenu", nullptr);
  popup_.reset();
  updateRegion();
}
void BrowserChromeHost::handleTopLevel(HWND hwnd, UINT message, WPARAM wparam, LPARAM lparam) {
  if (controller_) controller_->HandleTopLevelWindowProc(hwnd, message, wparam, lparam);
}
LRESULT CALLBACK BrowserChromeHost::ViewProc(HWND hwnd, UINT message, WPARAM wparam,
  LPARAM lparam, UINT_PTR, DWORD_PTR data) {
  auto* self = reinterpret_cast<BrowserChromeHost*>(data);
  if (message == kLayoutChrome) {
    self->layoutPending_ = false;
    if (self->ready_ && self->channel_) {
      RECT client{};
      GetClientRect(self->parent_, &client);
      const double scale = GetDpiForWindow(self->parent_) / 96.0;
      self->channel_->InvokeMethod("viewport", std::make_unique<Value>(Map{
        {Value("viewportWidth"), Value(client.right / scale)},
        {Value("viewportHeight"), Value(client.bottom / scale)}}));
    }
    return 0;
  }
  if (message == WM_NCHITTEST) {
    const LRESULT edge = ecjtu::ResizeHitTest(self->parent_, lparam);
    if (edge != HTCLIENT) return HTTRANSPARENT;
    POINT point{GET_X_LPARAM(lparam), GET_Y_LPARAM(lparam)};
    ScreenToClient(self->parent_, &point);
    RECT client{};
    GetClientRect(self->parent_, &client);
    const UINT dpi = GetDpiForWindow(self->parent_);
  }
  return DefSubclassProc(hwnd, message, wparam, lparam);
}
}
