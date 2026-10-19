#include "../utils/log.h"
#include "../utils/string.h"
#include "../utils/flutter.h"
#include "../types/url_request.h"
#include "in_app_browser.h"
#include "in_app_browser_channel_delegate.h"

namespace flutter_inappwebview_plugin
{
  InAppBrowserChannelDelegate::InAppBrowserChannelDelegate(const std::string& id, flutter::BinaryMessenger* messenger)
    : ChannelDelegate(messenger, InAppBrowser::METHOD_CHANNEL_NAME_PREFIX + id)
  {}

  void InAppBrowserChannelDelegate::HandleMethodCall(const flutter::MethodCall<flutter::EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result)
  {
    auto& methodName = method_call.method_name();
    if (methodName == "closeTransferredTab") {
      if (browser) browser->closeTransferredTab();
      result->Success();
      return;
    }
    if (methodName == "mergeInto") {
      const auto* targetId = std::get_if<std::string>(method_call.arguments());
      result->Success(browser && targetId && browser->mergeInto(*targetId));
      return;
    }
    if (browser && (methodName == "show" || methodName == "hide" || methodName == "close")) {
      if (methodName == "show") browser->show();
      if (methodName == "hide") browser->hide();
      if (methodName == "close") browser->close();
      result->Success();
      return;
    }
    if (string_equals(methodName, "setChromeStyle")) {
      const auto* style = std::get_if<flutter::EncodableMap>(method_call.arguments());
      if (browser && style) browser->setChromeStyle(*style);
      result->Success();
      return;
    }
    if (string_equals(methodName, "setChromeTheme")) {
      const auto* dark = std::get_if<bool>(method_call.arguments());
      if (browser && dark) browser->setChromeTheme(*dark);
      result->Success();
      return;
    }
    if (string_equals(methodName, "getBounds")) {
      if (!browser || !IsWindow(browser->getHWND())) {
        result->Error("0", "Browser window is not available.");
        return;
      }
      UINT dpi = GetDpiForWindow(browser->getHWND());
      if (dpi == 0) dpi = 96;
      const double scale = dpi / 96.0;
      RECT rect{};
      if (!GetWindowRect(browser->getHWND(), &rect)) {
        result->Error("0", "GetWindowRect failed.");
        return;
      }
      flutter::EncodableMap bounds{
        {flutter::EncodableValue("x"), flutter::EncodableValue(rect.left / scale)},
        {flutter::EncodableValue("y"), flutter::EncodableValue(rect.top / scale)},
        {flutter::EncodableValue("width"), flutter::EncodableValue((rect.right - rect.left) / scale)},
        {flutter::EncodableValue("height"), flutter::EncodableValue((rect.bottom - rect.top) / scale)},
      };
      result->Success(flutter::EncodableValue(bounds));
      return;
    }
    if (string_equals(methodName, "followCursorUntilRelease")) {
      if (!browser || !IsWindow(browser->getHWND())) {
        result->Error("0", "Browser window is not available.");
        return;
      }
      browser->followCursorUntilRelease();
      result->Success();
      return;
    }
    if (string_equals(methodName, "loadUrl")) {
      if (!browser) {
        result->Error("0", "Browser instance is not available.");
        return;
      }
      auto* arguments = std::get_if<flutter::EncodableMap>(method_call.arguments());
      if (arguments == nullptr) {
        result->Error("0", "Missing arguments.");
        return;
      }
      auto url = get_fl_map_value<std::string>(*arguments, "url");
      auto webView = browser->webView.get();
      if (!webView) {
        result->Error("0", "WebView is not available.");
        return;
      }
      flutter::EncodableMap urlRequestMap{
        {flutter::EncodableValue("url"), flutter::EncodableValue(url)},
      };
      webView->loadUrl(std::make_shared<URLRequest>(urlRequestMap));
      ShowWindow(browser->getHWND(), SW_SHOW);
      browser->focusActiveBrowser();
      result->Success(true);
      return;
    }
    result->NotImplemented();
  }

  void InAppBrowserChannelDelegate::onBrowserCreated() const
  {
    if (!channel) {
      return;
    }
    channel->InvokeMethod("onBrowserCreated", nullptr);
  }

  void InAppBrowserChannelDelegate::onMenuItemClicked(int id) const
  {
    if (!channel) return;
    flutter::EncodableMap arguments;
    arguments[flutter::EncodableValue("id")] = flutter::EncodableValue(id);
    channel->InvokeMethod("onMenuItemClicked",
      std::make_unique<flutter::EncodableValue>(arguments));
  }

  void InAppBrowserChannelDelegate::onExit() const
  {
    if (!channel) {
      return;
    }
    channel->InvokeMethod("onExit", nullptr);
  }

  InAppBrowserChannelDelegate::~InAppBrowserChannelDelegate()
  {
    debugLog("dealloc InAppBrowserChannelDelegate");
  }
}
