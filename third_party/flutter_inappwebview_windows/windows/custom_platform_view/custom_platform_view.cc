#include "../utils/log.h"
#include "custom_platform_view.h"
#include <cmath>
#include "../utils/window_resize.h"
#include "../utils/resize_timing.h"
#include "../utils/resize_trace.h"
#include <algorithm>
#include <dwmapi.h>

#include <flutter/event_stream_handler_functions.h>
#include <flutter/method_result_functions.h>

#ifdef HAVE_FLUTTER_D3D_TEXTURE
#include "texture_bridge_gpu.h"
#else
#include "texture_bridge_fallback.h"
#endif

namespace flutter_inappwebview_plugin
{
  constexpr auto kErrorInvalidArgs = "invalidArguments";

  constexpr auto kMethodSetSize = "setSize";
  constexpr auto kMethodSetPosition = "setPosition";
  constexpr auto kMethodSetCursorPos = "setCursorPos";
  constexpr auto kMethodSetPointerUpdate = "setPointerUpdate";
  constexpr auto kMethodSetPointerButton = "setPointerButton";
  constexpr auto kMethodSetScrollDelta = "setScrollDelta";
  constexpr auto kMethodSetFpsLimit = "setFpsLimit";

  constexpr auto kEventType = "type";
  constexpr auto kEventValue = "value";

  static constexpr wchar_t kPaneWindowClass[] = L"EcjtuWebPaneOwnedWindow";

  static LRESULT CALLBACK PaneWindowProc(HWND hwnd, UINT message,
      WPARAM wparam, LPARAM lparam) {
    if (message == WM_ERASEBKGND) return 1;
    return DefWindowProcW(hwnd, message, wparam, lparam);
  }

  static bool RegisterPaneWindowClass() {
    static const bool registered = [] {
      WNDCLASSEXW klass{sizeof(klass)};
      klass.lpfnWndProc = PaneWindowProc;
      klass.hInstance = GetModuleHandleW(nullptr);
      klass.lpszClassName = kPaneWindowClass;
      return RegisterClassExW(&klass) != 0 ||
          GetLastError() == ERROR_CLASS_ALREADY_EXISTS;
    }();
    return registered;
  }

  static const std::optional<std::pair<double, double>> GetPointFromArgs(
    const flutter::EncodableValue* args)
  {
    const flutter::EncodableList* list =
      std::get_if<flutter::EncodableList>(args);
    if (!list || list->size() != 2) {
      return std::nullopt;
    }
    const auto x = std::get_if<double>(&(*list)[0]);
    const auto y = std::get_if<double>(&(*list)[1]);
    if (!x || !y) {
      return std::nullopt;
    }
    return std::make_pair(*x, *y);
  }

  static const std::optional<std::tuple<double, double, double>>
    GetPointAndScaleFactorFromArgs(const flutter::EncodableValue* args)
  {
    const flutter::EncodableList* list =
      std::get_if<flutter::EncodableList>(args);
    if (!list || list->size() != 3) {
      return std::nullopt;
    }
    const auto x = std::get_if<double>(&(*list)[0]);
    const auto y = std::get_if<double>(&(*list)[1]);
    const auto z = std::get_if<double>(&(*list)[2]);
    if (!x || !y || !z) {
      return std::nullopt;
    }
    return std::make_tuple(*x, *y, *z);
  }

  static const std::string& GetCursorName(const HCURSOR cursor)
  {
    // The cursor names correspond to the Flutter Engine names:
    // in shell/platform/windows/flutter_window_win32.cc
    static const std::string kDefaultCursorName = "basic";
    static const std::pair<std::string, const wchar_t*> mappings[] = {
        {"allScroll", IDC_SIZEALL},
        {kDefaultCursorName, IDC_ARROW},
        {"click", IDC_HAND},
        {"forbidden", IDC_NO},
        {"help", IDC_HELP},
        {"move", IDC_SIZEALL},
        {"none", nullptr},
        {"noDrop", IDC_NO},
        {"precise", IDC_CROSS},
        {"progress", IDC_APPSTARTING},
        {"text", IDC_IBEAM},
        {"resizeColumn", IDC_SIZEWE},
        {"resizeDown", IDC_SIZENS},
        {"resizeDownLeft", IDC_SIZENESW},
        {"resizeDownRight", IDC_SIZENWSE},
        {"resizeLeft", IDC_SIZEWE},
        {"resizeLeftRight", IDC_SIZEWE},
        {"resizeRight", IDC_SIZEWE},
        {"resizeRow", IDC_SIZENS},
        {"resizeUp", IDC_SIZENS},
        {"resizeUpDown", IDC_SIZENS},
        {"resizeUpLeft", IDC_SIZENWSE},
        {"resizeUpRight", IDC_SIZENESW},
        {"resizeUpLeftDownRight", IDC_SIZENWSE},
        {"resizeUpRightDownLeft", IDC_SIZENESW},
        {"wait", IDC_WAIT},
    };

    static std::map<HCURSOR, std::string> cursors;
    static bool initialized = false;

    if (!initialized) {
      initialized = true;
      for (const auto& pair : mappings) {
        HCURSOR cursor_handle = LoadCursor(nullptr, pair.second);
        if (cursor_handle) {
          cursors[cursor_handle] = pair.first;
        }
      }
    }

    const auto it = cursors.find(cursor);
    if (it != cursors.end()) {
      return it->second;
    }
    return kDefaultCursorName;
  }

  CustomPlatformView::CustomPlatformView(flutter::BinaryMessenger* messenger,
    flutter::TextureRegistrar* texture_registrar,
    GraphicsContext* graphics_context,
    HWND hwnd,
    std::shared_ptr<flutter_inappwebview_plugin::InAppWebView> webView)
    : hwnd_(hwnd), view(std::move(webView)), texture_registrar_(texture_registrar)
  {
    native_ = !view->webViewCompositionController;
    if (native_) {
      static int64_t nextNativeId = 1LL << 40;
      texture_id_ = nextNativeId++;
      coordinate_view_ = GetParent(hwnd_);
      parent_ = GetAncestor(coordinate_view_, GA_ROOT);
      if (RegisterPaneWindowClass()) {
        pane_window_ = CreateWindowExW(0,
          kPaneWindowClass, L"", WS_CHILD | WS_CLIPCHILDREN | WS_CLIPSIBLINGS,
          0, 0, 1, 1, parent_, nullptr, GetModuleHandleW(nullptr), nullptr);
      }
      if (pane_window_) {
        SetParent(hwnd_, pane_window_);
        if (GetParent(hwnd_) != pane_window_) {
          DestroyWindow(pane_window_);
          pane_window_ = nullptr;
        } else {
          const int cornerPreference = 1; // DWMWCP_DONOTROUND
          DwmSetWindowAttribute(pane_window_, 33, &cornerPreference,
            sizeof(cornerPreference));
        }
      }
      if (!pane_window_) {
        // Keep the existing embedded path available if the owned window cannot
        // be created; it is better to show a page than to lose the tab.
        SetParent(hwnd_, parent_);
        SetWindowLongPtr(parent_, GWL_STYLE,
          GetWindowLongPtr(parent_, GWL_STYLE) | WS_CLIPCHILDREN);
      }
      SetWindowSubclass(hwnd_, HostProc, 1, reinterpret_cast<DWORD_PTR>(this));
      SetWindowSubclass(parent_, ParentProc, reinterpret_cast<UINT_PTR>(this), reinterpret_cast<DWORD_PTR>(this));
      view->webViewController->put_IsVisible(FALSE);
      view->webViewController->add_GotFocus(Microsoft::WRL::Callback<ICoreWebView2FocusChangedEventHandler>(
        [this](ICoreWebView2Controller*, IUnknown*) -> HRESULT {
          EmitEvent(flutter::EncodableValue(flutter::EncodableMap{
            {flutter::EncodableValue("type"), flutter::EncodableValue("nativeFocus")}}));
          return S_OK;
        }).Get(), &focus_token_);
    } else {
#ifdef HAVE_FLUTTER_D3D_TEXTURE
    texture_bridge_ =
      std::make_unique<TextureBridgeGpu>(graphics_context, view->surface());

    flutter_texture_ =
      std::make_unique<flutter::TextureVariant>(flutter::GpuSurfaceTexture(
        kFlutterDesktopGpuSurfaceTypeDxgiSharedHandle,
        [bridge = static_cast<TextureBridgeGpu*>(texture_bridge_.get())](
          size_t width,
          size_t height) -> const FlutterDesktopGpuSurfaceDescriptor*
        {
          return bridge->GetSurfaceDescriptor(width, height);
        }));
#else
    texture_bridge_ = std::make_unique<TextureBridgeFallback>(
      graphics_context, webview_->surface());

    flutter_texture_ =
      std::make_unique<flutter::TextureVariant>(flutter::PixelBufferTexture(
        [bridge = static_cast<TextureBridgeFallback*>(texture_bridge_.get())](
          size_t width, size_t height) -> const FlutterDesktopPixelBuffer*
        {
          return bridge->CopyPixelBuffer(width, height);
        }));
#endif

    texture_id_ = texture_registrar->RegisterTexture(flutter_texture_.get());
    texture_bridge_->SetOnFrameAvailable(
      [this]() { texture_registrar_->MarkTextureFrameAvailable(texture_id_); });
    // texture_bridge_->SetOnSurfaceSizeChanged([this](Size size) {
    //  view->SetSurfaceSize(size.width, size.height);
    //});

    }

    const auto method_channel_name = "com.pichillilorenzo/custom_platform_view_" + std::to_string(texture_id_);
    method_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
        messenger, method_channel_name,
        &flutter::StandardMethodCodec::GetInstance());
    method_channel_->SetMethodCallHandler([this](const auto& call, auto result)
      {
        HandleMethodCall(call, std::move(result));
      });

    const auto event_channel_name = "com.pichillilorenzo/custom_platform_view_" + std::to_string(texture_id_) + "_events";
    event_channel_ =
      std::make_unique<flutter::EventChannel<flutter::EncodableValue>>(
        messenger, event_channel_name,
        &flutter::StandardMethodCodec::GetInstance());

    auto handler = std::make_unique<
      flutter::StreamHandlerFunctions<flutter::EncodableValue>>(
        [this](const flutter::EncodableValue* arguments,
          std::unique_ptr<flutter::EventSink<flutter::EncodableValue>>&&
          events)
        {
          event_sink_ = std::move(events);
          RegisterEventHandlers();
          return nullptr;
        },
        [this](const flutter::EncodableValue* arguments)
        {
          return nullptr;
        });

    event_channel_->SetStreamHandler(std::move(handler));
  }

  void CustomPlatformView::UnregisterMethodCallHandler() const
  {
    if (method_channel_) {
      method_channel_->SetMethodCallHandler(nullptr);
      if (view && view->channelDelegate) {
        view->channelDelegate->UnregisterMethodCallHandler();
      }
    }
  }

  CustomPlatformView::~CustomPlatformView()
  {
    debugLog("dealloc CustomPlatformView");
    event_sink_ = nullptr;
    if (native_) {
      if (IsWindow(parent_)) RemoveWindowSubclass(parent_, ParentProc, reinterpret_cast<UINT_PTR>(this));
      if (IsWindow(hwnd_)) RemoveWindowSubclass(hwnd_, HostProc, 1);
      if (view && view->webViewController) view->webViewController->remove_GotFocus(focus_token_);
      view.reset();
      if (IsWindow(hwnd_)) DestroyWindow(hwnd_);
      if (IsWindow(pane_window_)) DestroyWindow(pane_window_);
    } else {
      texture_registrar_->UnregisterTexture(texture_id_, nullptr);
    }
  }

  void CustomPlatformView::RegisterEventHandlers()
  {
    if (!view || native_) {
      return;
    }

    view->onSurfaceSizeChanged([this](size_t width, size_t height)
      {
        texture_bridge_->NotifySurfaceSizeChanged();
      });

    view->onCursorChanged([this](const HCURSOR cursor)
      {
        const auto& name = GetCursorName(cursor);
        const auto event = flutter::EncodableValue(
          flutter::EncodableMap { {
              flutter::EncodableValue(kEventType),
                flutter::EncodableValue("cursorChanged")
            },
          { flutter::EncodableValue(kEventValue), name }});
        EmitEvent(event);
      });
  }

  void CustomPlatformView::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result)
  {
    const auto& method_name = method_call.method_name();
    if (method_name == "isNative") { result->Success(native_); return; }
    if (method_name == "getNativePresentation" && native_) {
      BOOL visible = FALSE;
      view->webViewController->get_IsVisible(&visible);
      POINT center{(frame_.left + frame_.right) / 2, (frame_.top + frame_.bottom) / 2};
      const HWND presentedChild = ChildWindowFromPointEx(parent_, center,
        CWP_SKIPINVISIBLE | CWP_SKIPDISABLED | CWP_SKIPTRANSPARENT);
      const HWND presentation = pane_window_ ? pane_window_ : hwnd_;
      ClientToScreen(parent_, &center);
      const HWND hit = WindowFromPoint(center);
      const HWND root = hit ? GetAncestor(hit, GA_ROOT) : nullptr;
      RECT parentRect{};
      RECT hostRect{};
      GetWindowRect(parent_, &parentRect);
      GetWindowRect(hwnd_, &hostRect);
      DWORD hitPid = 0;
      GetWindowThreadProcessId(hit, &hitPid);
      wchar_t hitClass[128]{};
      GetClassNameW(hit, hitClass, 128);
      result->Success(flutter::EncodableMap{
        {flutter::EncodableValue("hasOverlay"), flutter::EncodableValue(occlusion_.has_value())},
        {flutter::EncodableValue("visible"), flutter::EncodableValue(visible != FALSE && IsWindowVisible(hwnd_))},
        {flutter::EncodableValue("width"), flutter::EncodableValue(static_cast<int32_t>(frame_.right - frame_.left))},
        {flutter::EncodableValue("height"), flutter::EncodableValue(static_cast<int32_t>(frame_.bottom - frame_.top))},
        {flutter::EncodableValue("topmostAtCenter"), flutter::EncodableValue(presentedChild == presentation || IsChild(presentation, presentedChild))},
        {flutter::EncodableValue("screenTopmostAtCenter"), flutter::EncodableValue(hit == hwnd_ || IsChild(hwnd_, hit))},
        {flutter::EncodableValue("hitSameRoot"), flutter::EncodableValue(root == parent_)},
        {flutter::EncodableValue("hitSameProcess"), flutter::EncodableValue(hitPid == GetCurrentProcessId())},
        {flutter::EncodableValue("hitClass"), flutter::EncodableValue(wide_to_utf8(hitClass))},
        {flutter::EncodableValue("foreground"), flutter::EncodableValue(GetForegroundWindow() == parent_)},
        {flutter::EncodableValue("centerX"), flutter::EncodableValue(static_cast<int32_t>(center.x))},
        {flutter::EncodableValue("centerY"), flutter::EncodableValue(static_cast<int32_t>(center.y))},
        {flutter::EncodableValue("parentLeft"), flutter::EncodableValue(static_cast<int32_t>(parentRect.left))},
        {flutter::EncodableValue("parentTop"), flutter::EncodableValue(static_cast<int32_t>(parentRect.top))},
        {flutter::EncodableValue("hostLeft"), flutter::EncodableValue(static_cast<int32_t>(hostRect.left))},
        {flutter::EncodableValue("hostTop"), flutter::EncodableValue(static_cast<int32_t>(hostRect.top))}
      });
      return;
    }
    if (method_name == "setGeometry" && native_) {
      const auto* map = std::get_if<flutter::EncodableMap>(method_call.arguments());
      if (!map) { result->Error(kErrorInvalidArgs); return; }
      auto number = [&](const char* key) -> double {
        const auto it = map->find(flutter::EncodableValue(key));
        if (it == map->end()) return 0;
        if (auto d = std::get_if<double>(&it->second)) return *d;
        return 0;
      };
      const double scale = number("scale");
      if (!std::isfinite(scale) || scale <= 0) { result->Error(kErrorInvalidArgs); return; }
      const double x = number("x"), y = number("y"), width = number("width"), height = number("height");
      if (!std::isfinite(x) || !std::isfinite(y) || !std::isfinite(width) || !std::isfinite(height)) {
        result->Error(kErrorInvalidArgs); return;
      }
      RECT client{};
      GetClientRect(parent_, &client);
      POINT origin{};
      MapWindowPoints(coordinate_view_, parent_, &origin, 1);
      const LONG reportedWidth = static_cast<LONG>(std::lround(number("viewportWidth"))) + origin.x;
      const LONG reportedHeight = static_cast<LONG>(std::lround(number("viewportHeight"))) + origin.y;
      const bool animation = GetPropW(parent_, L"EcjtuWebPaneSurfaceLocked") != nullptr;
      // Layout replies can arrive after a newer native resize. They must not
      // replace the live viewport or turn the width delta into a right margin.
      const bool acceptGeometry = !geometry_ready_ || (!sizing_ &&
          (animation || (reportedWidth == client.right && reportedHeight == client.bottom)));
      ecjtu::ResizeTrace::Write(acceptGeometry ? 5 : 6, reportedWidth, client.right, frame_.right, right_gap_);
      if (acceptGeometry) {
        frame_ = {static_cast<LONG>(std::lround(x * scale)), static_cast<LONG>(std::lround(y * scale)),
          static_cast<LONG>(std::lround((x + width) * scale)), static_cast<LONG>(std::lround((y + height) * scale))};
        OffsetRect(&frame_, origin.x, origin.y);
        right_gap_ = (std::max)(0L, reportedWidth - frame_.right);
        bottom_gap_ = (std::max)(0L, reportedHeight - frame_.bottom);
        if (!animation) frame_.right = (std::max)(frame_.left, client.right - right_gap_);
        frame_.bottom = (std::max)(frame_.top, client.bottom - bottom_gap_);
      }
      const auto visible = map->find(flutter::EncodableValue("visible"));
      native_visible_ = visible != map->end() && std::get<bool>(visible->second);
      geometry_ready_ = true;
      const bool hadOverlay = occlusion_.has_value();
      occlusion_.reset();
      if (number("overlayWidth") > 0 && number("overlayHeight") > 0) {
        const double ox = number("overlayX"), oy = number("overlayY");
        occlusion_ = RECT{static_cast<LONG>(std::floor(ox * scale)), static_cast<LONG>(std::floor(oy * scale)),
          static_cast<LONG>(std::ceil((ox + number("overlayWidth")) * scale)),
          static_cast<LONG>(std::ceil((oy + number("overlayHeight")) * scale))};
        OffsetRect(&*occlusion_, origin.x, origin.y);
      }
      ApplyNativeFrame();
      if (occlusion_ && !hadOverlay && native_visible_) SetFocus(coordinate_view_);
      result->Success(acceptGeometry); return;
    }
    if (method_name == "setVisible" && native_) {
      if (const auto* visible = std::get_if<bool>(method_call.arguments())) {
        native_visible_ = *visible;
        ApplyNativeFrame();
        result->Success(); return;
      }
      result->Error(kErrorInvalidArgs); return;
    }

    // setCursorPos: [double x, double y]
    if (method_name.compare(kMethodSetCursorPos) == 0) {
      const auto point = GetPointFromArgs(method_call.arguments());
      if (point && view) {
        view->setCursorPos(point->first, point->second);
        return result->Success();
      }
      return result->Error(kErrorInvalidArgs);
    }

    // setPointerUpdate:
    // [int pointer, int event, double x, double y, double size, double pressure]
    if (method_name.compare(kMethodSetPointerUpdate) == 0) {
      const flutter::EncodableList* list =
        std::get_if<flutter::EncodableList>(method_call.arguments());
      if (!list || list->size() != 6) {
        return result->Error(kErrorInvalidArgs);
      }

      const auto pointer = std::get_if<int32_t>(&(*list)[0]);
      const auto event = std::get_if<int32_t>(&(*list)[1]);
      const auto x = std::get_if<double>(&(*list)[2]);
      const auto y = std::get_if<double>(&(*list)[3]);
      const auto size = std::get_if<double>(&(*list)[4]);
      const auto pressure = std::get_if<double>(&(*list)[5]);

      if (pointer && event && x && y && size && pressure && view) {
        view->setPointerUpdate(*pointer,
          static_cast<flutter_inappwebview_plugin::InAppWebViewPointerEventKind>(*event),
          *x, *y, *size, *pressure);
        return result->Success();
      }
      return result->Error(kErrorInvalidArgs);
    }

    // setScrollDelta: [double dx, double dy]
    if (method_name.compare(kMethodSetScrollDelta) == 0) {
      const auto delta = GetPointFromArgs(method_call.arguments());
      if (delta && view) {
        view->setScrollDelta(delta->first, delta->second);
        return result->Success();
      }
      return result->Error(kErrorInvalidArgs);
    }

    // setPointerButton: {"button": int, "isDown": bool}
    if (method_name.compare(kMethodSetPointerButton) == 0) {
      const auto& map = std::get<flutter::EncodableMap>(*method_call.arguments());

      const auto button = map.find(flutter::EncodableValue("button"));
      const auto isDown = map.find(flutter::EncodableValue("isDown"));
      if (button != map.end() && isDown != map.end()) {
        const auto buttonValue = std::get_if<int32_t>(&button->second);
        const auto isDownValue = std::get_if<bool>(&isDown->second);
        if (buttonValue && isDownValue && view) {
          view->setPointerButtonState(
            static_cast<flutter_inappwebview_plugin::InAppWebViewPointerButton>(*buttonValue), *isDownValue);
          return result->Success();
        }
      }
      return result->Error(kErrorInvalidArgs);
    }

    // setSize: [double width, double height, double scale_factor]
    if (method_name.compare(kMethodSetSize) == 0) {
      auto size = GetPointAndScaleFactorFromArgs(method_call.arguments());
      if (size && view) {
        const auto [width, height, scale_factor] = size.value();

        view->setSurfaceSize(static_cast<size_t>(width),
          static_cast<size_t>(height),
          static_cast<float>(scale_factor));

        if (texture_bridge_) texture_bridge_->Start();
        return result->Success();
      }
      return result->Error(kErrorInvalidArgs);
    }
    else if (method_name.compare(kMethodSetPosition) == 0) {
      auto position = GetPointAndScaleFactorFromArgs(method_call.arguments());
      if (position && view) {
        const auto [x, y, scale_factor] = position.value();

        view->setPosition(static_cast<size_t>(x),
          static_cast<size_t>(y),
          static_cast<float>(scale_factor));

        return result->Success();
      }
      return result->Error(kErrorInvalidArgs);
    }
    else if (method_name.compare(kMethodSetFpsLimit) == 0) {
      if (const auto value = std::get_if<int32_t>(method_call.arguments())) {
        if (texture_bridge_) texture_bridge_->SetFpsLimit(*value == 0 ? std::nullopt
          : std::make_optional(*value));
        return result->Success();
      }
    }

    result->NotImplemented();
  }

  void CustomPlatformView::ApplyNativeRegion(const RECT& frame) {
    HRGN region = nullptr;
    const HWND target = pane_window_ ? pane_window_ : hwnd_;
    if (pane_window_) {
      RECT client{};
      GetClientRect(parent_, &client);
      region = CreateRectRgn(
        (std::max)(0L, client.left - frame.left),
        (std::max)(0L, client.top - frame.top),
        (std::max)(0L, (std::min)(frame.right, client.right) - frame.left),
        (std::max)(0L, (std::min)(frame.bottom, client.bottom) - frame.top));
    } else if (occlusion_) {
      region = CreateRectRgn(0, 0, (std::max)(0L, frame.right - frame.left),
        (std::max)(0L, frame.bottom - frame.top));
    }
    if (region && pane_window_ && bottom_gap_ > 0) {
      const int radius = static_cast<int>(std::lround(12.0 * GetDpiForWindow(parent_) / 96.0));
      HRGN corners = CreateRoundRectRgn(0, -radius,
        (std::max)(0L, frame.right - frame.left) + 1,
        (std::max)(0L, frame.bottom - frame.top) + 1,
        radius * 2, radius * 2);
      CombineRgn(region, region, corners, RGN_AND);
      DeleteObject(corners);
    }
    if (region && occlusion_) {
      HRGN hole = CreateRectRgn(occlusion_->left - frame.left, occlusion_->top - frame.top,
        occlusion_->right - frame.left, occlusion_->bottom - frame.top);
      CombineRgn(region, region, hole, RGN_DIFF);
      DeleteObject(hole);
    }
    HRGN old = CreateRectRgn(0, 0, 0, 0);
    const bool hadRegion = GetWindowRgn(target, old) != ERROR;
    const bool same = region && hadRegion && EqualRgn(region, old);
    DeleteObject(old);
    if (same) DeleteObject(region);
    else if (region || hadRegion) {
      ecjtu::ResizeTrace::Write(4, frame.left, frame.right, frame.top, frame.bottom);
      SetWindowRgn(target, region, FALSE);
      RedrawWindow(target, nullptr, nullptr,
        RDW_INVALIDATE | RDW_NOERASE | RDW_NOCHILDREN);
      InvalidateRect(parent_, nullptr, FALSE);
    }
  }

  void CustomPlatformView::ApplyNativeFrame() {
    if (!geometry_ready_ || !IsWindow(hwnd_) || !view || !view->webViewController) return;
    RECT client{};
    GetClientRect(parent_, &client);
    // Parent clipping handles opening animations without resizing the page each tick.
    // Chromium scrollbar children consume pointer messages before the parent
    // can hit-test. Keep the sizing border outside the WebView viewport.
    const int sizing_border = ecjtu::ResizeBorder(parent_);
    // Temporary OS clipping must not become the next restored layout.
    const RECT presented_frame = ecjtu::ClipWebViewFrame(frame_, client,
      sizing_border, GetPropW(parent_, L"EcjtuWebPaneSurfaceLocked") != nullptr);
    const LONG width = (std::max)(0L, presented_frame.right - presented_frame.left);
    const LONG height = (std::max)(0L, presented_frame.bottom - presented_frame.top);
    ecjtu::ResizeTrace::Write(1, frame_.left, frame_.right, frame_.top, frame_.bottom);
    const RECT bounds{0, 0, width, height};
    RECT currentBounds{};
    view->webViewController->get_Bounds(&currentBounds);
    if (!EqualRect(&bounds, &currentBounds)) {
      ecjtu::ResizeTrace::Write(2, currentBounds.right, currentBounds.bottom, width, height);
      view->webViewController->put_Bounds(bounds);
    }
    RECT previous{};
    if (pane_window_) {
      POINT origin{frame_.left, frame_.top};
      const RECT paneBounds{origin.x, origin.y, origin.x + width,
        origin.y + height};
      GetWindowRect(pane_window_, &previous);
      MapWindowPoints(HWND_DESKTOP, parent_, reinterpret_cast<POINT*>(&previous), 2);
      if (!EqualRect(&previous, &paneBounds)) {
        ecjtu::ResizeTrace::Write(3, frame_.left, frame_.top, width, height);
        SetWindowPos(pane_window_, nullptr, origin.x, origin.y, width,
          height, SWP_NOZORDER | SWP_NOACTIVATE);
      }
      RECT hostFrame{};
      GetWindowRect(hwnd_, &hostFrame);
      MapWindowPoints(HWND_DESKTOP, pane_window_,
        reinterpret_cast<POINT*>(&hostFrame), 2);
      if (hostFrame.left != 0 || hostFrame.top != 0 ||
          hostFrame.right != width || hostFrame.bottom != height)
        SetWindowPos(hwnd_, nullptr, 0, 0, width, height,
          SWP_NOZORDER | SWP_NOACTIVATE);
    } else {
      GetWindowRect(hwnd_, &previous);
      MapWindowPoints(HWND_DESKTOP, parent_, reinterpret_cast<POINT*>(&previous), 2);
      if (!EqualRect(&previous, &presented_frame) ||
          (native_visible_ && !IsWindowVisible(hwnd_))) {
        ecjtu::ResizeTrace::Write(3, frame_.left, frame_.top, width, height);
        SetWindowPos(hwnd_, HWND_TOP, frame_.left, frame_.top, width, height,
          SWP_NOACTIVATE);
      }
    }
    ApplyNativeRegion(presented_frame);
    const bool show = native_visible_ && width > 0 && height > 0 &&
      !IsIconic(parent_) && IsWindowVisible(parent_);
    BOOL visible = FALSE;
    view->webViewController->get_IsVisible(&visible);
    if ((visible != FALSE) != show) view->webViewController->put_IsVisible(show);
    if (pane_window_ && static_cast<bool>(IsWindowVisible(pane_window_)) != show)
      ShowWindow(pane_window_, show ? SW_SHOWNOACTIVATE : SW_HIDE);
    if (static_cast<bool>(IsWindowVisible(hwnd_)) != show) ShowWindow(hwnd_, show ? SW_SHOWNOACTIVATE : SW_HIDE);
    if (show) {
      // Flutter may raise its sibling render window when its surface is resized.
      // Geometry alone leaves a visible WebView underneath that opaque surface.
      const HWND presentation = pane_window_ ? pane_window_ : hwnd_;
      if (GetWindow(presentation, GW_HWNDPREV) != nullptr)
        SetWindowPos(presentation, HWND_TOP, 0, 0, 0, 0,
          SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE);
    }
    if (initial_load_ && width > 0 && height > 0) {
      auto load = std::move(initial_load_);
      load();
    }
  }

  LRESULT CALLBACK CustomPlatformView::HostProc(HWND hwnd, UINT message, WPARAM wparam,
      LPARAM lparam, UINT_PTR, DWORD_PTR data) {
    auto* self = reinterpret_cast<CustomPlatformView*>(data);
    if (message == WM_SIZE && self->geometry_ready_ && self->view && self->view->webViewController) {
      ecjtu::ResizeTiming timing(2, hwnd);
      RECT currentBounds{};
      self->view->webViewController->get_Bounds(&currentBounds);
      RECT bounds{};
      GetClientRect(hwnd, &bounds);
      if (!EqualRect(&bounds, &currentBounds)) {
        ecjtu::ResizeTrace::Write(10, bounds.left, bounds.right, bounds.top, bounds.bottom);
        self->view->webViewController->put_Bounds(bounds);
      }
    }
    if (message == WM_ERASEBKGND) return 1;
    return DefSubclassProc(hwnd, message, wparam, lparam);
  }

  LRESULT CALLBACK CustomPlatformView::ParentProc(HWND hwnd, UINT message, WPARAM wparam,
      LPARAM lparam, UINT_PTR id, DWORD_PTR data) {
    auto* self = reinterpret_cast<CustomPlatformView*>(data);
    if (message == WM_ENTERSIZEMOVE) {
      ecjtu::ResizeTrace::Write(17, self->frame_.left, self->frame_.right, self->frame_.top, self->frame_.bottom);
      self->sizing_ = true;
      self->sizing_left_ = false;
    }
    if (message == WM_SIZING)
      self->sizing_left_ = wparam == WMSZ_LEFT || wparam == WMSZ_TOPLEFT || wparam == WMSZ_BOTTOMLEFT;
    if (message == WM_MOVE && self->native_visible_ && self->view &&
        self->view->webViewController) {
      if (!self->pane_window_ || !(self->sizing_ && self->sizing_left_)) {
        if (self->pane_window_) self->ApplyNativeFrame();
        self->view->webViewController->NotifyParentWindowPositionChanged();
      }
    }
    if (message == WM_SHOWWINDOW && self->pane_window_ && self->geometry_ready_) {
      const auto result = DefSubclassProc(hwnd, message, wparam, lparam);
      self->ApplyNativeFrame();
      return result;
    }
    if (message == WM_SIZE && wparam == SIZE_MINIMIZED && self->pane_window_)
      ShowWindow(self->pane_window_, SW_HIDE);
    if (message == WM_EXITSIZEMOVE) {
      self->sizing_ = false;
      ecjtu::ResizeTiming::Flush();
      ecjtu::ResizeTrace::Write(16, self->frame_.left, self->frame_.right, self->frame_.top, self->frame_.bottom);
      ecjtu::ResizeTrace::Flush();
      self->EmitEvent(flutter::EncodableValue(flutter::EncodableMap{
        {flutter::EncodableValue("type"), flutter::EncodableValue("nativeResizeEnd")}}));
    }
    if (message == WM_SIZE && wparam != SIZE_MINIMIZED && self->geometry_ready_ && self->native_visible_ && self->sizing_) {
      RECT client{};
      GetClientRect(hwnd, &client);
      const auto fixedPane = self->sizing_ && self->sizing_left_
          ? static_cast<LONG>(reinterpret_cast<INT_PTR>(
              GetPropW(hwnd, L"EcjtuFixedLeftResizePaneWidth"))) : 0;
      RECT surface{};
      GetClientRect(self->coordinate_view_, &surface);
      if (fixedPane > 0) {
        self->frame_.left = (std::max)(0L, client.right - fixedPane);
        self->frame_.right = client.right;
        self->right_gap_ = 0;
      }
      const LONG width = GetPropW(hwnd, L"EcjtuWebPaneSurfaceLocked")
          ? (std::max)(client.right, surface.right) : client.right;
      if (fixedPane <= 0)
        self->frame_.right = (std::max)(self->frame_.left, width - self->right_gap_);
      self->frame_.bottom = (std::max)(self->frame_.top, client.bottom - self->bottom_gap_);
      self->ApplyNativeFrame();
    }
    if (message == WM_SIZE && wparam != SIZE_MINIMIZED &&
        self->geometry_ready_ && self->native_visible_ && !self->sizing_) {
      const auto result = DefSubclassProc(hwnd, message, wparam, lparam);
      // Programmatic pane reveals change the parent's clip without changing
      // the page geometry. Refresh the region after Flutter resizes its child.
      self->ApplyNativeFrame();
      return result;
    }
    if (message == WM_NCDESTROY) RemoveWindowSubclass(hwnd, ParentProc, id);
    return DefSubclassProc(hwnd, message, wparam, lparam);
  }
}
