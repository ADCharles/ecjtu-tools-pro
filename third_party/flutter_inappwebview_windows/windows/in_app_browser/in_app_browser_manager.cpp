#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <windows.h>

#include "../in_app_webview/in_app_webview_settings.h"
#include "../types/url_request.h"
#include "../types/user_script.h"
#include "../utils/flutter.h"
#include "../utils/log.h"
#include "../utils/string.h"
#include "../utils/vector.h"
#include "../utils/browser_context_menu.h"
#include "in_app_browser_manager.h"
#include "in_app_browser_settings.h"

namespace flutter_inappwebview_plugin
{
  namespace { flutter::EncodableMap chromeDefaults; }
  InAppBrowserManager::InAppBrowserManager(const FlutterInappwebviewWindowsPlugin* plugin)
    : plugin(plugin), ChannelDelegate(plugin->registrar->messenger(), InAppBrowserManager::METHOD_CHANNEL_NAME)
  {}

  void InAppBrowserManager::HandleMethodCall(const flutter::MethodCall<flutter::EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result)
  {
    auto* arguments = std::get_if<flutter::EncodableMap>(method_call.arguments());
    auto& methodName = method_call.method_name();

    if (methodName == "setContextMenuStyle") {
      if (arguments) {
        const auto dark = arguments->find(flutter::EncodableValue("dark"));
        if (dark != arguments->end())
          if (const auto* value = std::get_if<bool>(&dark->second)) ecjtu::browserMenuDark = *value;
        const auto color = arguments->find(flutter::EncodableValue("contentColor"));
        if (color != arguments->end()) {
          uint32_t argb = 0;
          if (const auto* number = std::get_if<int64_t>(&color->second)) argb = static_cast<uint32_t>(*number);
          else if (const auto* integer32 = std::get_if<int32_t>(&color->second)) argb = static_cast<uint32_t>(*integer32);
          ecjtu::browserMenuBase = RGB((argb>>16)&255,(argb>>8)&255,argb&255);
        }
      }
      result->Success();
      return;
    }
    if (methodName == "setChromeDefaults") {
      if (arguments) chromeDefaults = *arguments;
      result->Success();
      return;
    }
    if (methodName == "setDockTarget") {
      InAppBrowser::setDockTarget(plugin->registrar->GetView()->GetNativeWindow(), arguments);
      result->Success();
      return;
    }
    if (string_equals(methodName, "open")) {
      if (plugin) {
        createInAppBrowser(arguments);
        result->Success(true);
      }
      else {
        result->Error("0", "Cannot create the InAppBrowser instance!");

      }
    }
    else if (string_equals(methodName, "openWithSystemBrowser")) {
      auto url = get_fl_map_value<std::string>(*arguments, "url");

      int status = static_cast<int>(reinterpret_cast<INT_PTR>(
        ShellExecute(nullptr, TEXT("open"), utf8_to_wide(url).c_str(),
          nullptr, nullptr, SW_SHOWNORMAL)));

      // Anything >32 indicates success.
      // https://learn.microsoft.com/en-us/windows/win32/api/shellapi/nf-shellapi-shellexecutea#return-value
      if (status <= 32) {
        std::cerr << "Failed to open " << url << ": ShellExecute error code " << status << std::endl;
      }
    }
    else {
      result->NotImplemented();
    }
  }

  void InAppBrowserManager::createInAppBrowser(const flutter::EncodableMap* arguments)
  {
    auto id = get_fl_map_value<std::string>(*arguments, "id");
    auto urlRequestMap = get_optional_fl_map_value<flutter::EncodableMap>(*arguments, "urlRequest");
    auto assetFilePath = get_optional_fl_map_value<std::string>(*arguments, "assetFilePath");
    auto data = get_optional_fl_map_value<std::string>(*arguments, "data");
    auto initialUserScriptList = get_optional_fl_map_value<flutter::EncodableList>(*arguments, "initialUserScripts");
    auto webViewEnvironmentId = get_optional_fl_map_value<std::string>(*arguments, "webViewEnvironmentId");
    auto windowId = get_optional_fl_map_value<int64_t>(*arguments, "windowId");

    std::optional<std::shared_ptr<URLRequest>> urlRequest = urlRequestMap.has_value() ? std::make_shared<URLRequest>(urlRequestMap.value()) : std::optional<std::shared_ptr<URLRequest>>{};

    auto settingsMap = get_fl_map_value<flutter::EncodableMap>(*arguments, "settings");
    auto initialSettings = std::make_unique<InAppBrowserSettings>(settingsMap);
    auto initialWebViewSettings = std::make_unique<InAppWebViewSettings>(settingsMap);
    std::optional<std::vector<std::shared_ptr<UserScript>>> initialUserScripts = initialUserScriptList.has_value() ?
      functional_map(initialUserScriptList.value(), [](const flutter::EncodableValue& map) { return std::make_shared<UserScript>(std::get<flutter::EncodableMap>(map)); }) :
      std::optional<std::vector<std::shared_ptr<UserScript>>>{};

    InAppBrowserCreationParams params = {
      id,
      urlRequest,
      assetFilePath,
      data,
      std::move(initialSettings),
      std::move(initialWebViewSettings),
      initialUserScripts,
      webViewEnvironmentId,
      windowId,
      chromeDefaults
    };

    auto inAppBrowser = std::make_unique<InAppBrowser>(plugin, params);
    inAppBrowser->channelDelegate->browser = inAppBrowser.get();
    browsers.insert({ id, std::move(inAppBrowser) });
  }

  InAppBrowserManager::~InAppBrowserManager()
  {
    debugLog("dealloc InAppBrowserManager");
    browsers.clear();
    plugin = nullptr;
  }
}
