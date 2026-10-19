#ifndef ECJTU_BROWSER_CHROME_HOST_H_
#define ECJTU_BROWSER_CHROME_HOST_H_
#include <windows.h>
#include <commctrl.h>
#include <flutter/flutter_view_controller.h>
#include <flutter/method_channel.h>
#include <flutter/encodable_value.h>
#include <functional>
#include <memory>

namespace flutter_inappwebview_plugin {
class BrowserChromeHost {
 public:
  using Value = flutter::EncodableValue;
  using Map = flutter::EncodableMap;
  BrowserChromeHost(HWND parent, std::function<Map()> state,
    std::function<void(const Map&)> action, std::function<void(double)> height);
  ~BrowserChromeHost();
  void layout(double height);
  void publish();
  void dismissMenu();
  void handleTopLevel(HWND hwnd, UINT message, WPARAM wparam, LPARAM lparam);
  bool ready() const { return ready_; }
  bool valid() const { return controller_ && controller_->view(); }
 private:
  static LRESULT CALLBACK ViewProc(HWND, UINT, WPARAM, LPARAM, UINT_PTR, DWORD_PTR);
  void updateRegion();
  Map snapshot();
  std::shared_ptr<bool> alive_ = std::make_shared<bool>(true);
  HWND parent_;
  std::unique_ptr<flutter::FlutterViewController> controller_;
  std::unique_ptr<flutter::MethodChannel<Value>> channel_;
  std::function<Map()> state_;
  bool ready_ = false;
  bool contentReady_ = false;
  bool layoutPending_ = false;
  double height_ = 89;
  std::optional<RECT> popup_;
};
}
#endif
