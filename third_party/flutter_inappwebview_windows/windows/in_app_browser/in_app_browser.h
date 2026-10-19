#ifndef FLUTTER_INAPPWEBVIEW_PLUGIN_IN_APP_BROWSER_H_
#define FLUTTER_INAPPWEBVIEW_PLUGIN_IN_APP_BROWSER_H_

#include <optional>
#include <string>
#include <vector>
#include <Windows.h>

#include "../flutter_inappwebview_windows_plugin.h"
#include "../in_app_webview/in_app_webview.h"
#include "../in_app_webview/in_app_webview_settings.h"
#include "../types/url_request.h"
#include "in_app_browser_channel_delegate.h"
#include "in_app_browser_settings.h"
#include "browser_chrome_host.h"
#include <deque>

namespace flutter_inappwebview_plugin
{
  struct InAppBrowserCreationParams
  {
    const std::string id;
    const std::optional<std::shared_ptr<URLRequest>> urlRequest;
    const std::optional<std::string> assetFilePath;
    const std::optional<std::string> data;
    const std::shared_ptr<InAppBrowserSettings> initialSettings;
    const std::shared_ptr<InAppWebViewSettings> initialWebViewSettings;
    const std::optional<std::vector<std::shared_ptr<UserScript>>> initialUserScripts;
    const std::optional<std::string> webViewEnvironmentId;
    const std::optional<int64_t> windowId;
    const flutter::EncodableMap chromeStyle;
  };

  class InAppBrowser {
  public:
    static inline const std::string METHOD_CHANNEL_NAME_PREFIX = "com.pichillilorenzo/flutter_inappbrowser_";
    static inline const wchar_t* CLASS_NAME = L"InAppBrowser";

    static LRESULT CALLBACK WndProc(HWND window,
      UINT message,
      WPARAM wparam,
      LPARAM lparam) noexcept;


    const FlutterInappwebviewWindowsPlugin* plugin;
    const std::string id;
    std::unique_ptr<InAppWebView> webView;
    std::unique_ptr<InAppBrowserChannelDelegate> channelDelegate;
    std::shared_ptr<InAppBrowserSettings> settings;

    InAppBrowser(const FlutterInappwebviewWindowsPlugin* plugin, const InAppBrowserCreationParams& params);
    ~InAppBrowser();

    void close() const;
    void show() const;
    void hide() const;
    bool isHidden() const;
    void setSettings(const std::shared_ptr<InAppBrowserSettings> newSettings, const flutter::EncodableMap& newSettingsMap);
    flutter::EncodableValue getSettings() const;

    void didChangeTitle(const std::optional<std::string>& title) const;
    void focusActiveBrowser()
    {
      activateBrowser(this);
    }
    void followCursorUntilRelease();
    void closeTransferredTab() {
      PostMessage(m_hWnd, WM_APP + 95, 0, 0);
    }
    void setChromeTheme(bool dark);
    static void setDockTarget(HWND view, const flutter::EncodableMap* bounds);
    void setChromeStyle(const flutter::EncodableMap& style);
    bool mergeInto(const std::string& targetId);
    HWND getHWND() const
    {
      return m_hWnd;
    }
  private:
    const HINSTANCE m_hInstance;
    HWND m_hWnd;
    HWND m_parentWindow = nullptr;
    HBRUSH m_toolbarBrush = nullptr;
    COLORREF m_backdropColor = RGB(243, 243, 243);
    COLORREF m_contentColor = RGB(255, 255, 255);
    COLORREF m_borderColor = RGB(220, 220, 220);

    std::vector<InAppBrowser*> m_mergedBrowsers;
    std::vector<InAppBrowser*> m_tabOrder;
    InAppBrowser* m_groupOwner = nullptr;
    InAppBrowser* m_activeBrowser = nullptr;
    bool destroyed_ = false;
    bool m_dark = false;
    bool m_topmostState = false;

    double m_chromeHeight = 89;
    bool m_maximizedState = false;
    std::string m_colorStyle = "blue";
    std::string m_font = "SourceHanSansCN";
    double m_textScale = 1;
    bool m_loading = true;
    bool m_waitingForInitialPage = false;
    bool m_creating = false;
    std::string m_error;
    std::unique_ptr<InAppBrowserCreationParams> m_creationParams;
    void createWebView(const InAppBrowserCreationParams& params);
    bool m_moved = false;
    bool m_parentDockArmed = true;
    std::unique_ptr<BrowserChromeHost> m_chrome;
    std::shared_ptr<bool> m_alive = std::make_shared<bool>(true);
    std::deque<flutter::EncodableMap> m_actions;
    flutter::EncodableMap chromeState();
    void publishChrome();
    void handleChromeAction(const flutter::EncodableMap& action);
    void showChromeMenu(double x, double y);
    void closeChromeMenu();
    static LRESULT CALLBACK ChromeMenuProc(HWND window, UINT message,
      WPARAM wparam, LPARAM lparam) noexcept;
    HWND m_menuWnd = nullptr;
    int m_menuHover = -1;
    void closeTab(InAppBrowser* browser);
    void detachTab(InAppBrowser* browser);

    bool m_inSizeMove = false;
    bool m_followPending = false;
    bool m_positionNotificationPending = false;
    ULONGLONG m_lastPositionNotificationTick = 0;
    bool m_canGoBack = false;
    bool m_canGoForward = false;
    std::wstring m_address;
    void refreshNavigationState();
    InAppBrowser* activeBrowser() noexcept;
    void adoptBrowser(InAppBrowser* browser);
    void activateBrowser(InAppBrowser* browser);
    void layoutActiveWebView();
    void resizeActiveWebView(RECT client);
    RECT webViewBounds(RECT client) const;
    void updateDockedRegion(RECT client);

    static InAppBrowser* GetThisFromHandle(HWND window) noexcept;
    LRESULT MessageHandler(HWND window,
      UINT message,
      WPARAM wparam,
      LPARAM lparam) noexcept;
  };
}
#endif //FLUTTER_INAPPWEBVIEW_PLUGIN_IN_APP_BROWSER_H_
