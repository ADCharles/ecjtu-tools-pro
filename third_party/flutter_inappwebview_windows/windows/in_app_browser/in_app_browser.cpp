#include <Windows.h>
#include <windowsx.h>
#include <shellapi.h>
#include <dwmapi.h>
#include <wrl/event.h>

#include <algorithm>
#include <cmath>
#include <cwchar>
#include <filesystem>
#include <unordered_map>

#include "../utils/log.h"
#include "../utils/window_resize.h"
#include "../utils/resize_timing.h"
#include "../utils/strconv.h"
#include "../utils/browser_context_menu.h"
#include "../webview_environment/webview_environment_manager.h"
#include "../in_app_webview/in_app_webview_manager.h"
#include "in_app_browser.h"
#include "in_app_browser_manager.h"

namespace flutter_inappwebview_plugin
{
  namespace
  {
    constexpr int kCaptionHeight = 44;
    constexpr int kTabRowBottom = 44;
    constexpr int kToolbarHeight = 89;
    constexpr int kBackButtonId = 4101;
    constexpr int kForwardButtonId = 4102;
    constexpr int kReloadButtonId = 4103;
    constexpr int kCopyLinkMenuId = 9101;
    constexpr int kOpenExternalMenuId = 9102;
    constexpr int kDockMenuId = 9103;
    std::unordered_map<HWND, InAppBrowser*> g_browserWindows;
    HWND g_dockView = nullptr;
    std::optional<RECT> g_dockBounds;

    bool dockTransferAvailable() {
      return IsWindow(g_dockView) &&
        IsWindowVisible(GetAncestor(g_dockView, GA_ROOT));
    }

    bool dockAvailable() {
      return g_dockBounds && IsWindow(g_dockView) &&
        IsWindowVisible(GetAncestor(g_dockView, GA_ROOT)) &&
        g_dockBounds->right > g_dockBounds->left &&
        g_dockBounds->bottom > g_dockBounds->top;
    }

    RECT dockTarget(HWND parent) {
      RECT rect{};
      if (dockAvailable()) {
        rect = *g_dockBounds;
        MapWindowPoints(g_dockView, nullptr, reinterpret_cast<POINT*>(&rect), 2);
      }
      return rect;
    }

    int scaleForWindow(HWND window, int value)
    {
      UINT dpi = GetDpiForWindow(window);
      if (dpi == 0) dpi = 96;
      return MulDiv(value, static_cast<int>(dpi), 96);
    }



  }

  InAppBrowser::InAppBrowser(const FlutterInappwebviewWindowsPlugin* plugin, const InAppBrowserCreationParams& params)
    : plugin(plugin),
    m_hInstance(GetModuleHandle(nullptr)),
    id(params.id),
    settings(params.initialSettings),
    channelDelegate(std::make_unique<InAppBrowserChannelDelegate>(id, plugin->registrar->messenger()))
  {

    WNDCLASS wndClass = {};
    wndClass.lpszClassName = InAppBrowser::CLASS_NAME;
    wndClass.hInstance = m_hInstance;
    wndClass.hIcon = LoadIcon(NULL, IDI_WINLOGO);
    wndClass.hCursor = LoadCursor(NULL, IDC_ARROW);
    wndClass.hbrBackground = (HBRUSH)GetStockObject(WHITE_BRUSH);
    wndClass.lpfnWndProc = InAppBrowser::WndProc;

    RegisterClass(&wndClass);

    auto parentWindow = plugin->registrar->GetView()->GetNativeWindow();
    m_parentWindow = GetAncestor(parentWindow, GA_ROOT);
    RECT bounds;
    GetWindowRect(parentWindow, &bounds);

    auto x = CW_USEDEFAULT;
    auto y = CW_USEDEFAULT;
    auto width = bounds.right - bounds.left;
    auto height = bounds.bottom - bounds.top;

    if (settings->windowFrame) {
      const UINT parentDpi = GetDpiForWindow(parentWindow);
      const UINT dpi = parentDpi == 0 ? 96 : parentDpi;
      x = MulDiv((int)settings->windowFrame->x, static_cast<int>(dpi), 96);
      y = MulDiv((int)settings->windowFrame->y, static_cast<int>(dpi), 96);
      width = MulDiv((int)settings->windowFrame->width, static_cast<int>(dpi), 96);
      height = MulDiv((int)settings->windowFrame->height, static_cast<int>(dpi), 96);
    }

    m_hWnd = CreateWindowEx(
      settings->windowAlphaValue < 1.0 ? WS_EX_LAYERED : 0,
      wndClass.lpszClassName,		// Window class

      settings->toolbarTopFixedTitle.empty() ? L"" : utf8_to_wide(settings->toolbarTopFixedTitle).c_str(),	// Window text

      (settings->windowType == InAppBrowserWindowType::window ? WS_OVERLAPPEDWINDOW : (WS_CHILDWINDOW | WS_OVERLAPPEDWINDOW)) | WS_CLIPCHILDREN | WS_CLIPSIBLINGS, // Window style

      // Position
      x, y,
      // Size
      width, height,

      settings->windowType == InAppBrowserWindowType::window ? nullptr : parentWindow, // Parent window    
      nullptr,             // Menu
      wndClass.hInstance,  // Instance handle
      this                 // Additional application data
    );
    g_browserWindows[m_hWnd] = this;

    const HINSTANCE executableInstance = GetModuleHandle(nullptr);
    HICON largeIcon = static_cast<HICON>(LoadImageW(executableInstance,
      MAKEINTRESOURCEW(101), IMAGE_ICON, 32, 32, LR_DEFAULTCOLOR));
    HICON smallIcon = static_cast<HICON>(LoadImageW(executableInstance,
      MAKEINTRESOURCEW(101), IMAGE_ICON, 16, 16, LR_DEFAULTCOLOR));
    if (largeIcon) SendMessage(m_hWnd, WM_SETICON, ICON_BIG,
      reinterpret_cast<LPARAM>(largeIcon));
    if (smallIcon) SendMessage(m_hWnd, WM_SETICON, ICON_SMALL,
      reinterpret_cast<LPARAM>(smallIcon));
    MARGINS shadowMargins{1, 1, 1, 1};
    DwmExtendFrameIntoClientArea(m_hWnd, &shadowMargins);

    if (settings->windowAlphaValue < 1.0) {
      SetLayeredWindowAttributes(m_hWnd, 0, (BYTE)(255 * settings->windowAlphaValue), LWA_ALPHA);
    }

    m_toolbarBrush = CreateSolidBrush(RGB(255, 255, 255));
    setChromeStyle(params.chromeStyle);
    SetWindowPos(m_hWnd, nullptr, 0, 0, 0, 0,
      SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_NOACTIVATE | SWP_FRAMECHANGED);

    if (params.urlRequest && params.urlRequest.value()->url) {
      m_address = utf8_to_wide(params.urlRequest.value()->url.value());
      m_waitingForInitialPage = m_address == L"about:blank";
    }
    ShowWindow(m_hWnd, settings->hidden ? SW_HIDE : SW_SHOW);
    if (!settings->hidden) UpdateWindow(m_hWnd);
    m_chrome = std::make_unique<BrowserChromeHost>(m_hWnd,
      [this]() { return chromeState(); },
      [this](const flutter::EncodableMap& action) {
        m_actions.push_back(action);
        PostMessage(m_hWnd, WM_APP + 94, 0, 0);
      },
      [this](double height) {
        m_chromeHeight = height;
        layoutActiveWebView();
      });
    ShowWindow(m_hWnd, settings->hidden ? SW_HIDE : SW_SHOW);

    m_creationParams = std::make_unique<InAppBrowserCreationParams>(params);
    createWebView(params);
  }

  void InAppBrowser::createWebView(const InAppBrowserCreationParams& params)
  {
    if (m_creating || destroyed_) return;
    m_creating = true;
    m_error.clear();
    m_loading = true;
    InAppWebViewCreationParams webViewParams = {
      id,
      params.initialWebViewSettings,
      params.initialUserScripts
    };

    auto webViewEnvironment = params.webViewEnvironmentId.has_value() && map_contains(plugin->webViewEnvironmentManager->webViewEnvironments, params.webViewEnvironmentId.value())
      ? plugin->webViewEnvironmentManager->webViewEnvironments.at(params.webViewEnvironmentId.value()).get() : nullptr;

    InAppWebView::createInAppWebViewEnv(m_hWnd, false, webViewEnvironment, params.initialWebViewSettings,
      [this, alive = m_alive, params, webViewParams](wil::com_ptr<ICoreWebView2Environment> webViewEnv, wil::com_ptr<ICoreWebView2Controller> webViewController, wil::com_ptr<ICoreWebView2CompositionController> webViewCompositionController) -> void
      {
        if (!*alive) {
          if (webViewController) webViewController->Close();
          return;
        }
        m_creating = false;
        if (webViewEnv && webViewController) {
          webView = std::make_unique<InAppWebView>(this, this->plugin, webViewParams, m_hWnd, std::move(webViewEnv), std::move(webViewController), nullptr);
          webView->initChannel(std::nullopt, InAppBrowser::METHOD_CHANNEL_NAME_PREFIX + id);
          if (params.windowId && plugin->inAppWebViewManager) {
            auto& pending = plugin->inAppWebViewManager->windowWebViews;
            const auto popup = pending.find(*params.windowId);
            if (popup != pending.end()) {
              popup->second->args->put_NewWindow(webView->webView.get());
              popup->second->args->put_Handled(TRUE);
              popup->second->deferral->Complete();
              pending.erase(popup);
            }
          }
          EventRegistrationToken navigationToken{};
          webView->webView->add_HistoryChanged(
            Microsoft::WRL::Callback<ICoreWebView2HistoryChangedEventHandler>(
              [this](ICoreWebView2*, IUnknown*) -> HRESULT {
                refreshNavigationState();
                return S_OK;
              }).Get(), &navigationToken);
          webView->webView->add_SourceChanged(
            Microsoft::WRL::Callback<ICoreWebView2SourceChangedEventHandler>(
              [this](ICoreWebView2*, ICoreWebView2SourceChangedEventArgs*) -> HRESULT {
                refreshNavigationState();
                return S_OK;
              }).Get(), &navigationToken);
          webView->webView->add_NavigationStarting(
            Microsoft::WRL::Callback<ICoreWebView2NavigationStartingEventHandler>(
              [this](ICoreWebView2*, ICoreWebView2NavigationStartingEventArgs* args) -> HRESULT {
                wil::unique_cotaskmem_string uri;
                if (args && SUCCEEDED(args->get_Uri(&uri)) && uri &&
                    wcscmp(uri.get(), L"about:blank") != 0)
                  m_waitingForInitialPage = false;
                m_loading = true; publishChrome(); return S_OK;
              }).Get(), &navigationToken);
          webView->webView->add_NavigationCompleted(
            Microsoft::WRL::Callback<ICoreWebView2NavigationCompletedEventHandler>(
              [this](ICoreWebView2*, ICoreWebView2NavigationCompletedEventArgs*) -> HRESULT {
                if (!m_waitingForInitialPage) m_loading = false;
                refreshNavigationState(); return S_OK;
              }).Get(), &navigationToken);
          webView->webViewController->add_GotFocus(
            Microsoft::WRL::Callback<ICoreWebView2FocusChangedEventHandler>(
              [this](ICoreWebView2Controller*, IUnknown*) -> HRESULT {
                auto* owner = m_groupOwner ? m_groupOwner : this;
                if (owner->m_chrome) owner->m_chrome->dismissMenu();
                return S_OK;
              }).Get(), &navigationToken);
           RECT webBounds;
           GetClientRect(m_hWnd, &webBounds);
           webBounds = webViewBounds(webBounds);
           webView->webViewController->put_Bounds(webBounds);
           if (auto controller3 = webView->webViewController.try_query<ICoreWebView2Controller3>()) {
             const UINT dpi = GetDpiForWindow(m_hWnd);
             controller3->put_RasterizationScale((dpi == 0 ? 96.0 : dpi) / 96.0);
             controller3->put_ShouldDetectMonitorScaleChanges(TRUE);
           }
          if (m_groupOwner) {
            webView->webViewController->put_ParentWindow(m_groupOwner->m_hWnd);
            m_groupOwner->layoutActiveWebView();
          } else {
            webView->webViewController->put_IsVisible(TRUE);
            if (m_chrome) m_chrome->layout(m_chromeHeight);
          }
          publishChrome();
          if (!settings->hidden && !m_groupOwner) {
            ShowWindow(m_hWnd, SW_SHOW);
            UpdateWindow(m_hWnd);
          }

          if (channelDelegate) {
            channelDelegate->onBrowserCreated();
          }

          if (params.windowId.has_value()) {
            // WebView2 continues the source window.open navigation after the
            // pending popup receives this child WebView.
          }
          else if (params.urlRequest.has_value()) {
            const auto& initialUrl = params.urlRequest.value()->url;
            if (initialUrl && initialUrl.value() != "about:blank") {
              webView->loadUrl(params.urlRequest.value());
            }
          }
          else if (params.assetFilePath.has_value()) {
            webView->loadFile(params.assetFilePath.value());
          }
          else if (params.data.has_value()) {
            webView->loadData(params.data.value());
          }
        }
        else {
          m_loading = false;
          m_error = "网页视图暂时无法打开，请重试";
          publishChrome();
        }
      });
  }

  InAppBrowser* InAppBrowser::activeBrowser() noexcept
  {
    return m_activeBrowser ? m_activeBrowser : this;
  }

  RECT InAppBrowser::webViewBounds(RECT bounds) const
  {
    bounds.top = static_cast<int>(std::ceil(m_chromeHeight * GetDpiForWindow(m_hWnd) / 96.0));
    if ((GetWindowLongPtrW(m_hWnd, GWL_STYLE) & WS_CHILD) != 0) {
      bounds.left += scaleForWindow(m_hWnd, 5);
      bounds.right -= scaleForWindow(m_hWnd, 9);
      bounds.bottom -= scaleForWindow(m_hWnd, 9);
    }
    bounds.right = (std::max)(bounds.left, bounds.right);
    bounds.bottom = (std::max)(bounds.top, bounds.bottom);
    return bounds;
  }

  void InAppBrowser::updateDockedRegion(RECT client)
  {
    const bool docked = (GetWindowLongPtrW(m_hWnd, GWL_STYLE) & WS_CHILD) != 0;
    HRGN previous = CreateRectRgn(0, 0, 0, 0);
    const bool hasRegion = GetWindowRgn(m_hWnd, previous) != ERROR;
    if (!docked) {
      DeleteObject(previous);
      if (hasRegion) SetWindowRgn(m_hWnd, nullptr, FALSE);
      return;
    }
    const int top = scaleForWindow(m_hWnd, 44);
    HRGN region = CreateRectRgn(0, 0, client.right, top);
    HRGN body = CreateRoundRectRgn(scaleForWindow(m_hWnd, 4), top,
      (std::max)(scaleForWindow(m_hWnd, 5), static_cast<int>(client.right) - scaleForWindow(m_hWnd, 8)),
      (std::max)(top + 1, static_cast<int>(client.bottom) - scaleForWindow(m_hWnd, 8)),
      scaleForWindow(m_hWnd, 24), scaleForWindow(m_hWnd, 24));
    CombineRgn(region, region, body, RGN_OR);
    DeleteObject(body);
    const bool unchanged = hasRegion && EqualRgn(previous, region);
    DeleteObject(previous);
    if (unchanged) DeleteObject(region);
    else SetWindowRgn(m_hWnd, region, FALSE);
  }

  void InAppBrowser::resizeActiveWebView(RECT bounds)
  {
    auto* active = activeBrowser();
    if (!active || !active->webView || !active->webView->webViewController) return;
    bounds = webViewBounds(bounds);
    auto* controller = active->webView->webViewController.get();
    RECT previous{};
    controller->get_Bounds(&previous);
    if (!EqualRect(&previous, &bounds)) controller->put_Bounds(bounds);
  }

  void InAppBrowser::layoutActiveWebView()
  {
    RECT bounds{};
    ecjtu::ResizeTiming timing(3, m_hWnd);
    GetClientRect(m_hWnd, &bounds);
    updateDockedRegion(bounds);
    resizeActiveWebView(bounds);
    auto layout = [&](InAppBrowser* browser) {
      if (!browser || !IsWindow(browser->m_hWnd)) return;
      if (!browser->webView || !browser->webView->webViewController) return;
      const bool active = browser == activeBrowser();
      auto* controller = browser->webView->webViewController.get();
      BOOL visible = FALSE;
      controller->get_IsVisible(&visible);
      if (visible != (active ? TRUE : FALSE)) controller->put_IsVisible(active ? TRUE : FALSE);
      if (active && !m_inSizeMove) controller->NotifyParentWindowPositionChanged();

    };
    layout(this);
    for (auto* browser : m_mergedBrowsers) layout(browser);
    if (m_chrome) m_chrome->layout(m_chromeHeight);
  }
  void InAppBrowser::activateBrowser(InAppBrowser* browser)
  {
    if (!browser || (browser != this &&
        std::find(m_mergedBrowsers.begin(), m_mergedBrowsers.end(), browser) ==
          m_mergedBrowsers.end())) return;
    m_activeBrowser = browser == this ? nullptr : browser;
    layoutActiveWebView();
    publishChrome();
    RECT toolbar{};
    GetClientRect(m_hWnd, &toolbar);
    toolbar.bottom = static_cast<int>(std::ceil(m_chromeHeight * GetDpiForWindow(m_hWnd) / 96.0));
    InvalidateRect(m_hWnd, &toolbar, FALSE);
  }

  void InAppBrowser::adoptBrowser(InAppBrowser* browser)
  {
    if (!browser || browser == this || browser->m_groupOwner) return;
    std::vector<InAppBrowser*> incoming{browser};
    incoming.insert(incoming.end(), browser->m_mergedBrowsers.begin(),
      browser->m_mergedBrowsers.end());
    browser->m_mergedBrowsers.clear();
    for (auto* item : incoming) {
      if (!item || item == this) continue;
      item->m_groupOwner = this;
      ShowWindow(item->m_hWnd, SW_HIDE);
      if (item->webView && item->webView->webViewController) {
        item->webView->webViewController->put_IsVisible(FALSE);
        item->webView->webViewController->put_ParentWindow(m_hWnd);
      }
      m_mergedBrowsers.push_back(item);
    }
    activateBrowser(browser);
  }

  void InAppBrowser::close() const
  {
    PostMessage(m_hWnd, WM_CLOSE, 0, 0);
  }

  void InAppBrowser::show() const
  {
    ShowWindow(m_hWnd, SW_SHOW);
    UpdateWindow(m_hWnd);
    if (webView && webView->webViewController) {
       RECT bounds;
       GetClientRect(m_hWnd, &bounds);
       bounds = webViewBounds(bounds);
       webView->webViewController->put_Bounds(bounds);
      webView->webViewController->put_IsVisible(TRUE);
    }
  }

  void InAppBrowser::refreshNavigationState()
  {
    if (!webView || !webView->webView) return;
    BOOL back = FALSE, forward = FALSE;
    webView->webView->get_CanGoBack(&back);
    webView->webView->get_CanGoForward(&forward);
    m_canGoBack = back != FALSE;
    m_canGoForward = forward != FALSE;
    wil::unique_cotaskmem_string source;
    if (SUCCEEDED(webView->webView->get_Source(&source)) && source) {
      m_address = source.get();
    }
    publishChrome();
    const HWND target = m_groupOwner ? m_groupOwner->m_hWnd : m_hWnd;
    RECT toolbar{};
    GetClientRect(target, &toolbar);
    toolbar.bottom = scaleForWindow(target, kToolbarHeight);
    InvalidateRect(target, &toolbar, FALSE);
  }

  void InAppBrowser::setDockTarget(HWND view, const flutter::EncodableMap* bounds)
  {
    const bool wasAvailable = dockAvailable();
    g_dockView = view;
    g_dockBounds.reset();
    if (bounds) {
      const double scale = GetDpiForWindow(view) / 96.0;
      auto coordinate = [&](const char* name) -> LONG {
        auto found = bounds->find(flutter::EncodableValue(name));
        if (found == bounds->end()) return 0;
        auto value = std::get_if<double>(&found->second);
        return value ? static_cast<LONG>(std::lround(*value * scale)) : 0;
      };
      g_dockBounds = RECT{coordinate("left"), coordinate("top"), coordinate("right"), coordinate("bottom")};
    }
    if (wasAvailable != dockAvailable()) {
      for (const auto& [window, browser] : g_browserWindows) {
        if (browser && !browser->m_groupOwner && IsWindow(window))
          browser->publishChrome();
      }
    }
  }

  void InAppBrowser::followCursorUntilRelease()
  {
    if (!IsWindow(m_hWnd) || m_inSizeMove || m_followPending ||
        !(GetAsyncKeyState(VK_LBUTTON) & 0x8000)) return;
    const HWND foreground = GetForegroundWindow();
    if (foreground != m_hWnd && foreground != m_parentWindow) return;
    GUITHREADINFO thread{sizeof(thread)};
    if (GetGUIThreadInfo(GetCurrentThreadId(), &thread) &&
        (thread.flags & GUI_INMOVESIZE)) return;
    POINT cursor{};
    if (!GetCursorPos(&cursor)) return;
    const RECT target = dockTarget(m_parentWindow);
    m_parentDockArmed = !PtInRect(&target, cursor);
    ReleaseCapture();
    SetForegroundWindow(m_hWnd);
    // Dispatch a queued mouse message rather than entering DefWindowProc from
    // a method callback. USER32's move loop also uses queue mouse metadata.
    m_followPending = PostMessage(m_hWnd, WM_NCLBUTTONDOWN, HTCAPTION,
      MAKELPARAM(cursor.x, cursor.y)) != FALSE;
  }

  void InAppBrowser::setChromeTheme(bool dark)
  {
    m_dark = dark;
    if (m_toolbarBrush) DeleteObject(m_toolbarBrush);
    m_toolbarBrush = CreateSolidBrush(m_backdropColor);
    BOOL enabled = dark;
    DwmSetWindowAttribute(m_hWnd, 20, &enabled, sizeof(enabled));
    InvalidateRect(m_hWnd, nullptr, FALSE);
    publishChrome();
  }


  flutter::EncodableMap InAppBrowser::chromeState()
  {
    using V = flutter::EncodableValue;
    const bool docked = (GetWindowLongPtrW(m_hWnd, GWL_STYLE) & WS_CHILD) != 0;
    const HWND window = docked ? GetAncestor(m_hWnd, GA_ROOT) : m_hWnd;
    flutter::EncodableList tabs;
    auto append = [&](InAppBrowser* browser, int index) {
      wchar_t title[1024]{};
      GetWindowTextW(browser->m_hWnd, title, 1024);
      tabs.emplace_back(flutter::EncodableMap{
        {V("id"), V(index)}, {V("title"), V(wide_to_utf8(title))},
        {V("url"), V(wide_to_utf8(browser->m_address))}});
    };
    std::vector<InAppBrowser*> live{this};
    live.insert(live.end(), m_mergedBrowsers.begin(), m_mergedBrowsers.end());
    m_tabOrder.erase(std::remove_if(m_tabOrder.begin(), m_tabOrder.end(),
      [&](auto* tab) { return std::find(live.begin(), live.end(), tab) == live.end(); }), m_tabOrder.end());
    for (auto* tab : live)
      if (std::find(m_tabOrder.begin(), m_tabOrder.end(), tab) == m_tabOrder.end()) m_tabOrder.push_back(tab);
    int activeIndex = 0;
    for (auto* browser : m_tabOrder) {
      const int index = static_cast<int>(std::find(live.begin(), live.end(), browser) - live.begin());
      append(browser, index);
      if (browser == activeBrowser()) activeIndex = index;
    }
    auto* active = activeBrowser();
    return {{V("tabs"), V(tabs)}, {V("active"), V(activeIndex)},
      {V("url"), V(wide_to_utf8(active->m_address))},
      {V("back"), V(active->m_canGoBack)}, {V("forward"), V(active->m_canGoForward)},
      {V("docked"), V(docked)}, {V("maximized"), V(IsZoomed(window) != FALSE)}, {V("colorStyle"), V(m_colorStyle)}, {V("dark"), V(m_dark)}, {V("font"), V(m_font)}, {V("textScale"), V(m_textScale)},
      {V("dockAvailable"), V(dockTransferAvailable())},
      {V("topmost"), V((GetWindowLongPtrW(m_hWnd, GWL_EXSTYLE) & WS_EX_TOPMOST) != 0)},
      {V("loading"), V(active->m_loading)},
      {V("contentReady"), V(active->webView != nullptr &&
        !active->m_waitingForInitialPage)}, {V("error"), V(active->m_error)}};
  }

  void InAppBrowser::publishChrome()
  {
    auto* owner = m_groupOwner ? m_groupOwner : this;
    if (!owner->destroyed_ && owner->m_chrome) owner->m_chrome->publish();
  }

  void InAppBrowser::setChromeStyle(const flutter::EncodableMap& style)
  {
    using V = flutter::EncodableValue;
    auto readColor = [&](const char* key, COLORREF& color) {
      const auto item = style.find(V(key));
      if (item == style.end()) return;
      uint32_t argb = 0;
      if (auto value = std::get_if<int64_t>(&item->second)) argb = static_cast<uint32_t>(*value);
      else if (auto value = std::get_if<int32_t>(&item->second)) argb = static_cast<uint32_t>(*value);
      else return;
      color = RGB((argb >> 16) & 255, (argb >> 8) & 255, argb & 255);
    };
    readColor("backdropColor", m_backdropColor);
    readColor("contentColor", m_contentColor);
    readColor("borderColor", m_borderColor);
    ecjtu::browserMenuBase = m_contentColor;
    auto colorStyle = style.find(V("colorStyle"));
    if (colorStyle != style.end()) {
      if (auto value = std::get_if<std::string>(&colorStyle->second))
        m_colorStyle = *value == "neutral" ? "neutral" : "blue";
    }
    auto font = style.find(V("font"));
    if (font != style.end()) {
      if (auto value = std::get_if<std::string>(&font->second)) m_font = *value;
    }
    auto scale = style.find(V("textScale"));
    if (scale != style.end()) {
      if (auto value = std::get_if<double>(&scale->second)) m_textScale = *value;
    }
    auto dark = style.find(V("dark"));
    if (dark != style.end()) {
      if (auto value = std::get_if<bool>(&dark->second)) {
        ecjtu::browserMenuDark = *value;
        setChromeTheme(*value);
      }
    }
    publishChrome();
  }

  void InAppBrowser::detachTab(InAppBrowser* browser)
  {
    if (!browser) return;
    if (browser == this && !m_mergedBrowsers.empty()) {
      // Promote another existing host; retain every WebView and its history.
      auto remaining = m_mergedBrowsers;
      m_mergedBrowsers.clear();
      m_activeBrowser = nullptr;
      auto* owner = remaining.front();
      owner->m_groupOwner = nullptr;
      if (owner->webView) owner->webView->webViewController->put_ParentWindow(owner->m_hWnd);
      RECT bounds{};
      GetWindowRect(m_hWnd, &bounds);
      SetWindowPos(owner->m_hWnd, nullptr, bounds.left, bounds.top,
        bounds.right - bounds.left, bounds.bottom - bounds.top, SWP_NOZORDER | SWP_NOACTIVATE);
      for (size_t i = 1; i < remaining.size(); ++i) {
        remaining[i]->m_groupOwner = nullptr;
        owner->adoptBrowser(remaining[i]);
      }
      owner->activateBrowser(owner);
      ShowWindow(owner->m_hWnd, SW_SHOW);
    } else if (browser != this) {
      m_mergedBrowsers.erase(std::remove(m_mergedBrowsers.begin(), m_mergedBrowsers.end(), browser), m_mergedBrowsers.end());
      if (m_activeBrowser == browser) m_activeBrowser = nullptr;
      browser->m_groupOwner = nullptr;
      if (browser->webView) browser->webView->webViewController->put_ParentWindow(browser->m_hWnd);
      activateBrowser(activeBrowser());
    }
    browser->layoutActiveWebView();
    browser->publishChrome();
  }

  void InAppBrowser::closeTab(InAppBrowser* browser)
  {
    if (!browser) return;
    if (browser == this) detachTab(browser);
    PostMessage(browser->m_hWnd, WM_CLOSE, 0, 0);
  }

  void InAppBrowser::handleChromeAction(const flutter::EncodableMap& action)
  {
    using V = flutter::EncodableValue;
    auto nameIt = action.find(V("name"));
    if (nameIt == action.end()) return;
    const auto* name = std::get_if<std::string>(&nameIt->second);
    if (!name) return;
    if (*name == "openMenu") {
      auto coordinate = [&](const char* key) -> double {
        const auto found = action.find(V(key));
        if (found == action.end()) return 0;
        if (const auto value = std::get_if<double>(&found->second)) return *value;
        if (const auto value = std::get_if<int32_t>(&found->second)) return *value;
        return 0;
      };
      showChromeMenu(coordinate("x"), coordinate("y"));
      return;
    }
    auto* tab = activeBrowser();
    auto tabIt = action.find(V("tab"));
    if (tabIt != action.end()) {
      if (auto index = std::get_if<int32_t>(&tabIt->second)) {
        if (*index < 0 || *index > static_cast<int32_t>(m_mergedBrowsers.size())) return;
        tab = *index == 0 ? this : m_mergedBrowsers[*index - 1];
      }
    }
    if (*name == "dragWindow") {
      ReleaseCapture();
      PostMessage(m_hWnd, WM_NCLBUTTONDOWN, HTCAPTION, GetMessagePos());
    }
    else if (*name == "reorderTab") {
      const auto targetIt = action.find(V("target"));
      if (targetIt == action.end()) return;
      const auto* targetIndex = std::get_if<int32_t>(&targetIt->second);
      if (!targetIndex || *targetIndex < 0 || *targetIndex > static_cast<int>(m_mergedBrowsers.size())) return;
      auto* target = *targetIndex == 0 ? this : m_mergedBrowsers[*targetIndex - 1];
      const auto from = std::find(m_tabOrder.begin(), m_tabOrder.end(), tab);
      const auto to = std::find(m_tabOrder.begin(), m_tabOrder.end(), target);
      if (from == m_tabOrder.end() || to == m_tabOrder.end() || from == to) return;
      const auto destination = to - m_tabOrder.begin();
      m_tabOrder.erase(from);
      m_tabOrder.insert(m_tabOrder.begin() + destination, tab);
      publishChrome();
    }
    else if (*name == "mergeWindows") {
      std::vector<InAppBrowser*> incoming;
      for (const auto& entry : g_browserWindows) {
        auto* other = entry.second;
        if (other && other != this && !other->m_groupOwner && !other->destroyed_ &&
            IsWindowVisible(other->m_hWnd) &&
            (GetWindowLongPtrW(other->m_hWnd, GWL_STYLE) & WS_CHILD) == 0)
          incoming.push_back(other);
      }
      for (auto* other : incoming) adoptBrowser(other);
      publishChrome();
    }
    else if (*name == "selectTab") activateBrowser(tab);
    else if (*name == "closeTab") closeTab(tab);
    else if (*name == "closeWindow") PostMessage(GetAncestor(m_hWnd, GA_ROOT), WM_CLOSE, 0, 0);
    else if (*name == "minimize") ShowWindow(GetAncestor(m_hWnd, GA_ROOT), SW_MINIMIZE);
    else if (*name == "maximize") {
      const HWND window = GetAncestor(m_hWnd, GA_ROOT);
      ShowWindow(window, IsZoomed(window) ? SW_RESTORE : SW_MAXIMIZE);
    }
    else if (*name == "toggleTopmost") {
      const bool pinned = (GetWindowLongPtrW(m_hWnd, GWL_EXSTYLE) & WS_EX_TOPMOST) != 0;
      SetWindowPos(m_hWnd, pinned ? HWND_NOTOPMOST : HWND_TOPMOST,
        0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE);
    }
    else if (*name == "dragTab") {
      if (m_inSizeMove || tab->m_inSizeMove || tab->m_followPending ||
          !(GetAsyncKeyState(VK_LBUTTON) & 0x8000)) return;
      const HWND foreground = GetForegroundWindow();
      if (foreground != m_hWnd && foreground != m_parentWindow) return;
      GUITHREADINFO thread{sizeof(thread)};
      if (GetGUIThreadInfo(GetCurrentThreadId(), &thread) &&
          (thread.flags & GUI_INMOVESIZE)) return;
      detachTab(tab);
      POINT cursor{};
      if (GetCursorPos(&cursor)) SetWindowPos(tab->m_hWnd, nullptr,
        cursor.x - scaleForWindow(tab->m_hWnd, 90), cursor.y - scaleForWindow(tab->m_hWnd, 16),
        0, 0, SWP_NOSIZE | SWP_NOZORDER | SWP_NOACTIVATE);
      ShowWindow(tab->m_hWnd, SW_SHOW);
      tab->followCursorUntilRelease();
    } else if (*name == "copyLink" || *name == "openExternal" || *name == "newWindow" || *name == "newTab" ||
               (*name == "transfer" && dockTransferAvailable())) {
      if (tab->channelDelegate) tab->channelDelegate->onMenuItemClicked(
        *name == "copyLink" ? kCopyLinkMenuId : (*name == "openExternal" ? kOpenExternalMenuId : (*name == "newWindow" ? 9104 : (*name == "newTab" ? 9105 : kDockMenuId))));
    } else if (*name == "reload" && !tab->webView && tab->m_creationParams) {
      tab->createWebView(*tab->m_creationParams);
      tab->publishChrome();
    } else if (tab->webView && tab->webView->webView) {
      if (*name == "back" && tab->m_canGoBack) tab->webView->webView->GoBack();
      if (*name == "forward" && tab->m_canGoForward) tab->webView->webView->GoForward();
      if (*name == "reload") tab->webView->webView->Reload();
      if (*name == "stop") {
        tab->webView->webView->Stop();
        tab->m_loading = false;
        tab->publishChrome();
      }
    }
  }

  bool InAppBrowser::mergeInto(const std::string& targetId)
  {
    if (targetId == id || m_groupOwner || destroyed_) return false;
    for (const auto& entry : g_browserWindows) {
      auto* target = entry.second;
      if (target && target->id == targetId && !target->destroyed_) {
        target = target->m_groupOwner ? target->m_groupOwner : target;
        if (target == this || !IsWindow(target->m_hWnd)) return false;
        target->adoptBrowser(this);
        return m_groupOwner == target;
      }
    }
    return false;
  }

  void InAppBrowser::showChromeMenu(double x, double y)
  {
    if (!IsWindow(m_hWnd)) return;
    if (m_menuWnd) {
      closeChromeMenu();
      return;
    }
    closeChromeMenu();
    static const wchar_t* className = L"EcjtuBrowserChromePopup";
    static bool registered = false;
    if (!registered) {
      WNDCLASSW popupClass{};
      popupClass.lpfnWndProc = ChromeMenuProc;
      popupClass.hInstance = m_hInstance;
      popupClass.lpszClassName = className;
      popupClass.hCursor = LoadCursor(nullptr, IDC_ARROW);
      popupClass.style = CS_DROPSHADOW;
      registered = RegisterClassW(&popupClass) != 0 || GetLastError() == ERROR_CLASS_ALREADY_EXISTS;
    }
    if (!registered) return;
    const UINT dpi = (std::max)(96u, GetDpiForWindow(m_hWnd));
    const int width = MulDiv(210, dpi, 96);
    const int height = MulDiv(3 * 28 + 2, dpi, 96);
    POINT anchor{
      static_cast<LONG>(std::lround(x * dpi / 96.0)),
      static_cast<LONG>(std::lround(y * dpi / 96.0))};
    ClientToScreen(m_hWnd, &anchor);
    MONITORINFO monitor{sizeof(monitor)};
    GetMonitorInfoW(MonitorFromPoint(anchor, MONITOR_DEFAULTTONEAREST), &monitor);
    int left = (std::max)(static_cast<int>(monitor.rcWork.left),
      (std::min)(static_cast<int>(anchor.x) - width,
        static_cast<int>(monitor.rcWork.right) - width));
    int top = anchor.y;
    if (top + height > monitor.rcWork.bottom) top = anchor.y - height - MulDiv(32, dpi, 96);
    top = (std::max)(static_cast<int>(monitor.rcWork.top), top);
    m_menuHover = -1;
    m_menuWnd = CreateWindowExW(WS_EX_TOOLWINDOW | WS_EX_NOACTIVATE,
      className, L"", WS_POPUP, left, top, width, height,
      m_hWnd, nullptr, m_hInstance, this);
    if (!m_menuWnd) return;
    ShowWindow(m_menuWnd, SW_SHOWNOACTIVATE);
    SetWindowPos(m_menuWnd, HWND_TOP, 0, 0, 0, 0,
      SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE | SWP_SHOWWINDOW);
    SetCapture(m_menuWnd);
  }

  void InAppBrowser::closeChromeMenu()
  {
    const HWND popup = m_menuWnd;
    m_menuWnd = nullptr;
    m_menuHover = -1;
    if (popup && IsWindow(popup)) DestroyWindow(popup);
    if (GetCapture() == popup) ReleaseCapture();
  }

  LRESULT CALLBACK InAppBrowser::ChromeMenuProc(HWND window, UINT message,
    WPARAM wparam, LPARAM lparam) noexcept
  {
    auto* browser = reinterpret_cast<InAppBrowser*>(GetWindowLongPtrW(window, GWLP_USERDATA));
    if (message == WM_NCCREATE) {
      auto* create = reinterpret_cast<CREATESTRUCTW*>(lparam);
      browser = static_cast<InAppBrowser*>(create->lpCreateParams);
      SetWindowLongPtrW(window, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(browser));
    }
    if (!browser) return DefWindowProcW(window, message, wparam, lparam);
    const UINT dpi = (std::max)(96u, GetDpiForWindow(window));
    const int padding = MulDiv(1, dpi, 96);
    const int itemHeight = MulDiv(28, dpi, 96);
    switch (message) {
    case WM_PAINT: {
      PAINTSTRUCT paint{};
      HDC dc = BeginPaint(window, &paint);
      RECT client{};
      GetClientRect(window, &client);
      HBRUSH surface = CreateSolidBrush(browser->m_dark ? RGB(19, 30, 50) : RGB(255, 255, 255));
      FillRect(dc, &client, surface);
      DeleteObject(surface);
      HPEN border = CreatePen(PS_SOLID, 1,
        browser->m_dark ? RGB(41, 56, 81) : RGB(228, 231, 236));
      HGDIOBJ oldPen = SelectObject(dc, border);
      HGDIOBJ oldBrush = SelectObject(dc, GetStockObject(HOLLOW_BRUSH));
      Rectangle(dc, 0, 0, client.right, client.bottom);
      SelectObject(dc, oldBrush);
      SelectObject(dc, oldPen);
      DeleteObject(border);
      static bool fontLoaded = false;
      if (!fontLoaded) {
        wchar_t executable[32768]{};
        GetModuleFileNameW(nullptr, executable, 32768);
        const auto font = std::filesystem::path(executable).parent_path() /
          L"data/flutter_assets/assets/fonts/SourceHanSansCN-Regular.otf";
        AddFontResourceExW(font.c_str(), FR_PRIVATE, nullptr);
        fontLoaded = true;
      }
      const wchar_t* family = browser->m_font == "Microsoft YaHei"
        ? L"Microsoft YaHei" : L"Source Han Sans CN";
      HFONT font = CreateFontW(-MulDiv(static_cast<int>(std::lround(13 * browser->m_textScale)), dpi, 96),
        0, 0, 0, FW_NORMAL, FALSE, FALSE, FALSE, DEFAULT_CHARSET,
        OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, CLEARTYPE_QUALITY,
        DEFAULT_PITCH, family);
      HGDIOBJ oldFont = SelectObject(dc, font);
      SetBkMode(dc, TRANSPARENT);
      const wchar_t* labels[] = {L"复制链接", L"在默认浏览器中打开", L"移回侧栏"};
      for (int index = 0; index < 3; ++index) {
        RECT item{padding, padding + index * itemHeight,
          client.right - padding, padding + (index + 1) * itemHeight};
        const bool hovered = browser->m_menuHover == index;
        if (hovered) {
          HBRUSH selected = CreateSolidBrush(browser->m_dark ? RGB(38, 74, 113) : RGB(40, 127, 208));
          FillRect(dc, &item, selected);
          DeleteObject(selected);
        }
        SetTextColor(dc, hovered ? RGB(255, 255, 255) :
          browser->m_dark ? RGB(232, 240, 252) : RGB(16, 24, 40));
        DrawTextW(dc, labels[index], -1, &item,
          DT_CENTER | DT_VCENTER | DT_SINGLELINE | DT_NOPREFIX);
      }
      SelectObject(dc, oldFont);
      DeleteObject(font);
      EndPaint(window, &paint);
      return 0;
    }
    case WM_MOUSEMOVE: {
      const int y = GET_Y_LPARAM(lparam);
      RECT client{};
      GetClientRect(window, &client);
      const int x = GET_X_LPARAM(lparam);
      const int hover = x >= padding && x < client.right - padding &&
        y >= padding && y < padding + 3 * itemHeight
        ? (y - padding) / itemHeight : -1;
      if (hover != browser->m_menuHover) {
        browser->m_menuHover = hover;
        InvalidateRect(window, nullptr, FALSE);
      }
      return 0;
    }
    case WM_LBUTTONUP: {
      RECT client{};
      GetClientRect(window, &client);
      const int x = GET_X_LPARAM(lparam);
      const int y = GET_Y_LPARAM(lparam);
      const int selected = x >= padding && x < client.right - padding &&
        y >= padding && y < padding + 3 * itemHeight
        ? (y - padding) / itemHeight : -1;
      browser->closeChromeMenu();
      if (selected >= 0 && selected < 3) {
        auto* active = browser->activeBrowser();
        if (active && active->channelDelegate) {
          const int ids[] = {kCopyLinkMenuId, kOpenExternalMenuId, kDockMenuId};
          active->channelDelegate->onMenuItemClicked(ids[selected]);
        }
      }
      return 0;
    }
    case WM_LBUTTONDOWN:
      return 0;
    case WM_RBUTTONUP:
      browser->closeChromeMenu();
      return 0;
    case WM_NCDESTROY:
      if (browser->m_menuWnd == window) browser->m_menuWnd = nullptr;
      break;
    }
    return DefWindowProcW(window, message, wparam, lparam);
  }

  void InAppBrowser::hide() const
  {
    ShowWindow(m_hWnd, SW_HIDE);
  }

  bool InAppBrowser::isHidden() const
  {
    return !IsWindowVisible(m_hWnd);
  }

  void InAppBrowser::setSettings(const std::shared_ptr<InAppBrowserSettings> newSettings, const flutter::EncodableMap& newSettingsMap)
  {
    if (webView) {
      webView->setSettings(std::make_shared<InAppWebViewSettings>(newSettingsMap), newSettingsMap);
    }

    if (fl_map_contains_not_null(newSettingsMap, "hidden") && settings->hidden != newSettings->hidden) {
      newSettings->hidden ? hide() : show();
    }

    if (fl_map_contains_not_null(newSettingsMap, "toolbarTopFixedTitle") && !string_equals(settings->toolbarTopFixedTitle, newSettings->toolbarTopFixedTitle) && !newSettings->toolbarTopFixedTitle.empty()) {
      SetWindowText(m_hWnd, utf8_to_wide(newSettings->toolbarTopFixedTitle).c_str());
    }

    if (fl_map_contains_not_null(newSettingsMap, "windowAlphaValue") && settings->windowAlphaValue != newSettings->windowAlphaValue) {
      SetLayeredWindowAttributes(m_hWnd, 0, (BYTE)(255 * newSettings->windowAlphaValue), LWA_ALPHA);
    }

    if (fl_map_contains_not_null(newSettingsMap, "windowFrame")) {
      const UINT dpi = GetDpiForWindow(m_hWnd);
      const UINT scaleDpi = dpi == 0 ? 96 : dpi;
      auto x = MulDiv((int)newSettings->windowFrame->x, static_cast<int>(scaleDpi), 96);
      auto y = MulDiv((int)newSettings->windowFrame->y, static_cast<int>(scaleDpi), 96);
      auto width = MulDiv((int)newSettings->windowFrame->width, static_cast<int>(scaleDpi), 96);
      auto height = MulDiv((int)newSettings->windowFrame->height, static_cast<int>(scaleDpi), 96);
      MoveWindow(m_hWnd, x, y, width, height, true);
    }

    settings = newSettings;
  }

  flutter::EncodableValue InAppBrowser::getSettings() const
  {
    if (!settings || !webView) {
      return make_fl_value();
    }

    auto encodableMap = settings->getRealSettings(this);
    encodableMap.merge(std::get<flutter::EncodableMap>(webView->getSettings()));
    return encodableMap;
  }

  void InAppBrowser::didChangeTitle(const std::optional<std::string>& title) const
  {
    if (title.has_value() && settings->toolbarTopFixedTitle.empty()) {
      SetWindowText(m_hWnd, utf8_to_wide(title.value()).c_str());
    }
    RECT toolbar{};
    GetClientRect(m_hWnd, &toolbar);
    toolbar.bottom = static_cast<int>(std::ceil(m_chromeHeight * GetDpiForWindow(m_hWnd) / 96.0));
    InvalidateRect(m_hWnd, &toolbar, FALSE);
    const_cast<InAppBrowser*>(this)->publishChrome();
  }

  LRESULT CALLBACK InAppBrowser::WndProc(
    HWND window,
    UINT message,
    WPARAM wparam,
    LPARAM lparam
  ) noexcept
  {
    if (message == WM_NCCREATE) {
      auto window_struct = reinterpret_cast<CREATESTRUCT*>(lparam);
      SetWindowLongPtr(window, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(window_struct->lpCreateParams));
    }
    else if (InAppBrowser* that = GetThisFromHandle(window)) {
      return that->MessageHandler(window, message, wparam, lparam);
    }

    return DefWindowProc(window, message, wparam, lparam);
  }

  LRESULT InAppBrowser::MessageHandler(
    HWND hwnd,
    UINT message,
    WPARAM wparam,
    LPARAM lparam
  ) noexcept
  {
    if (m_chrome && (message == WM_DPICHANGED ||
        message == WM_SETTINGCHANGE || message == WM_FONTCHANGE)) {
      m_chrome->handleTopLevel(hwnd, message, wparam, lparam);
    }
    switch (message) {
    case WM_WINDOWPOSCHANGING: {
      const auto* next = reinterpret_cast<const WINDOWPOS*>(lparam);
      if (m_inSizeMove && !IsIconic(hwnd) && !(next->flags & SWP_NOSIZE) &&
          next->cx > 0 && next->cy > 0) {
        RECT outer{}, client{};
        GetWindowRect(hwnd, &outer);
        GetClientRect(hwnd, &client);
        // A left/top resize also moves the client origin. Submitting the new
        // width at the old origin creates a viewport that never actually
        // exists; use WM_SIZE/WM_MOVE after USER32 applies that transaction.
        if (!(next->flags & SWP_NOMOVE) &&
            (next->x != outer.left || next->y != outer.top)) break;
        client.right += next->cx - (outer.right - outer.left);
        client.bottom += next->cy - (outer.bottom - outer.top);
        // Prepare the browser child before USER32 exposes the enlarged host.
        // WM_SIZE still reconciles the final client rect after nonclient layout.
        resizeActiveWebView(client);
      }
      break;
    }
    case WM_CAPTURECHANGED:
      return 0;
    case WM_CANCELMODE:
      if (GetCapture() == hwnd) ReleaseCapture();
      return 0;
    case WM_ENTERSIZEMOVE:
      closeChromeMenu();
      if (m_chrome) m_chrome->dismissMenu();
      m_inSizeMove = true;
      m_moved = false;
      return 0;
    case WM_NCCALCSIZE:
      if (wparam) {
        auto* params = reinterpret_cast<NCCALCSIZE_PARAMS*>(lparam);
        if (IsZoomed(hwnd)) {
          MONITORINFO monitor{sizeof(MONITORINFO)};
          if (GetMonitorInfo(MonitorFromWindow(hwnd, MONITOR_DEFAULTTONEAREST), &monitor)) {
            // A maximized thick frame extends beyond the work area. Those
            // invisible frame pixels must not clip the Flutter tab strip.
            params->rgrc[0] = monitor.rcWork;
          }
          return 0;
        }
        const LONG top = params->rgrc[0].top;
        DefWindowProc(hwnd, message, wparam, lparam);
        // Keep the system's nonclient resize frame on the other three sides.
        // Only the caption is replaced by Flutter; no client pixels are
        // reserved as invisible resize gutters inside the page.
        params->rgrc[0].top = top;
        return 0;
      }
      break;
    case WM_NCHITTEST: {
      POINT point{static_cast<short>(LOWORD(lparam)), static_cast<short>(HIWORD(lparam))};
      ScreenToClient(hwnd, &point);
      RECT client{};
      GetClientRect(hwnd, &client);
      const auto hit = ecjtu::ResizeHitTest(hwnd, lparam);
      if (hit != HTCLIENT) return hit;
      if (point.y < scaleForWindow(hwnd, kCaptionHeight) &&
          point.x < client.right - scaleForWindow(hwnd, 43 * 4)) return HTCAPTION;
      return HTCLIENT;
    }
    case WM_PAINT: {
      PAINTSTRUCT paint{};
      HDC dc = BeginPaint(hwnd, &paint);
      RECT client{};
      GetClientRect(hwnd, &client);
      // WS_CLIPCHILDREN excludes the browser and Flutter surfaces from this
      // DC. The remaining client pixels still belong to the host, including
      // resize borders and areas exposed when child bounds change.
      FillRect(dc, &client, m_toolbarBrush);
      RECT caption{0, 0, client.right, scaleForWindow(hwnd, 32)};
      HBRUSH brush = CreateSolidBrush(m_backdropColor);
      FillRect(dc, &caption, brush);
      DeleteObject(brush);
      if ((GetWindowLongPtrW(hwnd, GWL_STYLE) & WS_CHILD) != 0) {
        HBRUSH fill = CreateSolidBrush(m_contentColor);
        HPEN pen = CreatePen(PS_SOLID, scaleForWindow(hwnd, 1), m_borderColor);
        auto oldBrush = SelectObject(dc, fill);
        auto oldPen = SelectObject(dc, pen);
        RoundRect(dc, scaleForWindow(hwnd, 4), scaleForWindow(hwnd, 44),
          client.right - scaleForWindow(hwnd, 8), client.bottom - scaleForWindow(hwnd, 8),
          scaleForWindow(hwnd, 24), scaleForWindow(hwnd, 24));
        SelectObject(dc, oldBrush);
        SelectObject(dc, oldPen);
        DeleteObject(fill);
        DeleteObject(pen);
      }
      EndPaint(hwnd, &paint);
      return 0;
    }
    case WM_CLOSE:
      closeChromeMenu();
      ShowWindow(hwnd, SW_HIDE);
      *m_alive = false;
      {
        auto children = m_mergedBrowsers;
        m_mergedBrowsers.clear();
        for (auto* child : children) {
          child->m_groupOwner = nullptr;
          SendMessage(child->m_hWnd, WM_CLOSE, 0, 0);
        }
      }
      if (GetCapture() == hwnd) ReleaseCapture();
      m_chrome.reset();
      webView.reset();
      DestroyWindow(hwnd);
      return 0;
    case WM_APP + 95:
      // The method channel belongs to this tab, not necessarily its group owner.
      // Detach it before closing so the remaining tabs and their engines survive.
      if (m_groupOwner) m_groupOwner->detachTab(this);
      else if (!m_mergedBrowsers.empty()) detachTab(this);
      PostMessage(hwnd, WM_CLOSE, 0, 0);
      return 0;
    case WM_APP + 94:
      if (!m_actions.empty()) {
        const auto action = m_actions.front();
        m_actions.pop_front();
        handleChromeAction(action);
      }
      return 0;
    case WM_NCLBUTTONDOWN: {
      if (m_inSizeMove || !(GetAsyncKeyState(VK_LBUTTON) & 0x8000)) {
        m_followPending = false;
        return 0;
      }
      if (!m_followPending) break;
      m_followPending = false;
      const HWND foreground = GetForegroundWindow();
      if (foreground != hwnd) return 0;
      GUITHREADINFO thread{sizeof(thread)};
      if (GetGUIThreadInfo(GetCurrentThreadId(), &thread) &&
          (thread.flags & GUI_INMOVESIZE)) return 0;
      break;
    }
    case WM_DESTROY: {
      if (GetCapture() == hwnd) ReleaseCapture();
      // might receive multiple WM_DESTROY messages.
      if (!destroyed_) {
        destroyed_ = true;
        *m_alive = false;

        if (channelDelegate) {
          channelDelegate->onExit();
        }

        if (channelDelegate) {
          channelDelegate->UnregisterMethodCallHandler();
          if (webView && webView->channelDelegate) {
            webView->channelDelegate->UnregisterMethodCallHandler();
          }
        }
        m_chrome.reset();
        if (m_groupOwner) {
          // A merged child being destroyed must detach itself from its group
          // owner, otherwise the owner keeps painting / laying out a dangling
          // pointer (stale vertical line artifacts in the content area).
          // Do NOT run COM calls (activateBrowser/layout) synchronously here:
          // we are inside WM_DESTROY of a window being destroyed, and a
          // synchronous WebView2 call there can re-enter and deadlock/crash.
          auto* owner = m_groupOwner;
          m_groupOwner = nullptr;
          owner->m_mergedBrowsers.erase(
            std::remove(owner->m_mergedBrowsers.begin(),
                        owner->m_mergedBrowsers.end(), this),
            owner->m_mergedBrowsers.end());
          if (owner->m_activeBrowser == this) {
            owner->m_activeBrowser = nullptr;
          }
          PostMessage(owner->m_hWnd, WM_APP + 92, 0, 0);
        } else {
          for (auto* browser : m_mergedBrowsers) {
            if (browser && IsWindow(browser->m_hWnd)) {
              browser->m_groupOwner = nullptr;
              PostMessage(browser->m_hWnd, WM_CLOSE, 0, 0);
            }
          }
          m_mergedBrowsers.clear();
        }
        g_browserWindows.erase(m_hWnd);
        webView.reset();

      }
      return 0;
    }
    case WM_DPICHANGED: {
      auto newRectSize = reinterpret_cast<RECT*>(lparam);
      LONG newWidth = newRectSize->right - newRectSize->left;
      LONG newHeight = newRectSize->bottom - newRectSize->top;

      SetWindowPos(hwnd, nullptr, newRectSize->left, newRectSize->top, newWidth,
        newHeight, SWP_NOZORDER | SWP_NOACTIVATE);
      if (webView && webView->webViewController) {
        layoutActiveWebView();
      }
      return 0;
    }
    case WM_SIZE: {
      closeChromeMenu();
      if (wparam == SIZE_MINIMIZED) return 0;
      RECT client{};
      GetClientRect(hwnd, &client);
      resizeActiveWebView(client);
      if (m_chrome) m_chrome->layout(m_chromeHeight);
      if (m_chrome) m_chrome->handleTopLevel(hwnd, message, wparam, lparam);
      const bool maximized = IsZoomed(GetAncestor(hwnd, GA_ROOT)) != FALSE;
      if (maximized != m_maximizedState) {
        m_maximizedState = maximized;
        publishChrome();
      }
      InvalidateRect(hwnd, nullptr, FALSE);
      if (m_chrome) m_chrome->dismissMenu();
      return 0;
    }
    case WM_WINDOWPOSCHANGED: {
      const bool pinned = (GetWindowLongPtrW(hwnd, GWL_EXSTYLE) & WS_EX_TOPMOST) != 0;
      if (pinned != m_topmostState) {
        m_topmostState = pinned;
        publishChrome();
      }
      break;
    }
    case WM_MOVE:
      if (!m_positionNotificationPending) {
        m_positionNotificationPending = PostMessage(hwnd, WM_APP + 96, 0, 0) != FALSE;
      }
      return 0;
    case WM_APP + 96:
      if (!m_positionNotificationPending) return 0;
      m_positionNotificationPending = false;
      if (m_inSizeMove) {
        const auto now = GetTickCount64();
        if (now - m_lastPositionNotificationTick < 16) return 0;
        m_lastPositionNotificationTick = now;
      }
      if (auto* active = activeBrowser();
          active->webView && active->webView->webViewController) {
        active->webView->webViewController->NotifyParentWindowPositionChanged();
      }
      return 0;
    case WM_MOVING: {
      m_moved = true;
      POINT cursor{};
      GetCursorPos(&cursor);
      const RECT target = dockTarget(m_parentWindow);
      if (!PtInRect(&target, cursor)) m_parentDockArmed = true;
      break;
    }
    case WM_EXITSIZEMOVE: {
      ecjtu::ResizeTiming::Flush();
      m_inSizeMove = false;
      m_positionNotificationPending = false;
      m_lastPositionNotificationTick = 0;
      if (auto* active = activeBrowser();
          active->webView && active->webView->webViewController) {
        active->webView->webViewController->NotifyParentWindowPositionChanged();
      }
      if (!m_moved) return 0;
      m_moved = false;
      RECT windowRect{};
      if (!GetWindowRect(hwnd, &windowRect)) return 0;
      POINT center{
        windowRect.left + (windowRect.right - windowRect.left) / 2,
        windowRect.top + scaleForWindow(hwnd, kCaptionHeight) / 2
      };
      POINT dropPoint = center;
      GetCursorPos(&dropPoint);
      for (const auto& entry : g_browserWindows) {
        auto* target = entry.second;
        if (!target || target == this || target->m_groupOwner ||
            !IsWindowVisible(entry.first)) continue;
        RECT targetRect{};
        if (!GetWindowRect(entry.first, &targetRect)) continue;
        targetRect.top += scaleForWindow(entry.first, kCaptionHeight);
        targetRect.bottom = targetRect.top + scaleForWindow(entry.first,
          static_cast<int>((target->m_chromeHeight - kCaptionHeight) / 2));
        if (PtInRect(&targetRect, dropPoint)) {
          // Defer the merge: running WebView2 COM re-parenting at the very
          // end of a modal drag loop can deadlock the UI thread.
          PostMessage(hwnd, WM_APP + 93,
            reinterpret_cast<WPARAM>(entry.first), 0);
          return 0;
        }
      }
      const RECT parentRect = dockTarget(m_parentWindow);
      if (dockAvailable() && m_parentDockArmed && m_parentWindow &&
          PtInRect(&parentRect, dropPoint)) {
        auto* active = activeBrowser();
        if (active->channelDelegate) active->channelDelegate->onMenuItemClicked(kDockMenuId);
      }
      return 0;
    }
    case WM_APP + 93: {
      // Deferred adopt-a-dragged-window request (WPARAM = target browser).
      const auto found = g_browserWindows.find(reinterpret_cast<HWND>(wparam));
      if (found != g_browserWindows.end() && IsWindow(hwnd)) {
        found->second->adoptBrowser(this);
      }
      return 0;
    }
    case WM_GETMINMAXINFO: {
      auto info = reinterpret_cast<MINMAXINFO*>(lparam);
      ecjtu::ApplyMaximizedWorkArea(hwnd, info);
      info->ptMinTrackSize.x = scaleForWindow(hwnd, 280);
      info->ptMinTrackSize.y = scaleForWindow(hwnd, 360);
      return 0;
    }
    case WM_COMMAND: {
      if (!webView || !webView->webView) return 0;
      switch (LOWORD(wparam)) {
      case kBackButtonId:
        webView->webView->GoBack();
        return 0;
      case kForwardButtonId:
        webView->webView->GoForward();
        return 0;
      case kReloadButtonId:
        webView->webView->Reload();
        return 0;
      }
      break;
    }

    case WM_APP + 92:
      // Deferred re-layout after a merged child was destroyed: safe point
      // for the WebView2 COM calls that cannot run inside WM_DESTROY.
      if (m_activeBrowser == nullptr && !m_mergedBrowsers.empty()) {
        m_activeBrowser = m_mergedBrowsers.front();
      }
      layoutActiveWebView();
      publishChrome();
      InvalidateRect(hwnd, nullptr, FALSE);
      return 0;
    case WM_CTLCOLORSTATIC: {
      const HDC dc = reinterpret_cast<HDC>(wparam);
      SetBkColor(dc, RGB(247, 248, 250));
      SetTextColor(dc, RGB(18, 24, 33));
      return reinterpret_cast<LRESULT>(m_toolbarBrush);
    }
    case WM_ERASEBKGND:
      return 1;
    case WM_ACTIVATE: {
      if (LOWORD(wparam) == WA_INACTIVE && m_chrome) m_chrome->dismissMenu();
      break;
    }
    }

    return DefWindowProc(hwnd, message, wparam, lparam);
  }

  InAppBrowser* InAppBrowser::GetThisFromHandle(HWND const window) noexcept
  {
    return reinterpret_cast<InAppBrowser*>(
      GetWindowLongPtr(window, GWLP_USERDATA));
  }

  InAppBrowser::~InAppBrowser()
  {
    closeChromeMenu();
    debugLog("dealloc InAppBrowser");
    webView.reset();
    *m_alive = false;
    m_chrome.reset();
    if (m_toolbarBrush) DeleteObject(m_toolbarBrush);
    SetWindowLongPtr(m_hWnd, GWLP_USERDATA, 0);
    plugin = nullptr;
  }

}
