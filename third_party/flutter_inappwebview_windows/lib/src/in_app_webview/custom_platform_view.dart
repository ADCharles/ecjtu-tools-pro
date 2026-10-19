import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import '_static_channel.dart';

const Map<String, SystemMouseCursor> _cursors = {
  'none': SystemMouseCursors.none,
  'basic': SystemMouseCursors.basic,
  'click': SystemMouseCursors.click,
  'forbidden': SystemMouseCursors.forbidden,
  'wait': SystemMouseCursors.wait,
  'progress': SystemMouseCursors.progress,
  'contextMenu': SystemMouseCursors.contextMenu,
  'help': SystemMouseCursors.help,
  'text': SystemMouseCursors.text,
  'verticalText': SystemMouseCursors.verticalText,
  'cell': SystemMouseCursors.cell,
  'precise': SystemMouseCursors.precise,
  'move': SystemMouseCursors.move,
  'grab': SystemMouseCursors.grab,
  'grabbing': SystemMouseCursors.grabbing,
  'noDrop': SystemMouseCursors.noDrop,
  'alias': SystemMouseCursors.alias,
  'copy': SystemMouseCursors.copy,
  'disappearing': SystemMouseCursors.disappearing,
  'allScroll': SystemMouseCursors.allScroll,
  'resizeLeftRight': SystemMouseCursors.resizeLeftRight,
  'resizeUpDown': SystemMouseCursors.resizeUpDown,
  'resizeUpLeftDownRight': SystemMouseCursors.resizeUpLeftDownRight,
  'resizeUpRightDownLeft': SystemMouseCursors.resizeUpRightDownLeft,
  'resizeUp': SystemMouseCursors.resizeUp,
  'resizeDown': SystemMouseCursors.resizeDown,
  'resizeLeft': SystemMouseCursors.resizeLeft,
  'resizeRight': SystemMouseCursors.resizeRight,
  'resizeUpLeft': SystemMouseCursors.resizeUpLeft,
  'resizeUpRight': SystemMouseCursors.resizeUpRight,
  'resizeDownLeft': SystemMouseCursors.resizeDownLeft,
  'resizeDownRight': SystemMouseCursors.resizeDownRight,
  'resizeColumn': SystemMouseCursors.resizeColumn,
  'resizeRow': SystemMouseCursors.resizeRow,
  'zoomIn': SystemMouseCursors.zoomIn,
  'zoomOut': SystemMouseCursors.zoomOut,
};

SystemMouseCursor _getCursorByName(String name) =>
    _cursors[name] ?? SystemMouseCursors.basic;

/// Pointer button type
// Order must match InAppWebViewPointerEventKind (see in_app_webview.h)
enum PointerButton { none, primary, secondary, tertiary }

/// Pointer Event kind
// Order must match InAppWebViewPointerEventKind (see in_app_webview.h)
enum InAppWebViewPointerEventKind { activate, down, enter, leave, up, update }

/// Attempts to translate a button constant such as [kPrimaryMouseButton]
/// to a [PointerButton]
PointerButton _getButton(int value) {
  switch (value) {
    case kPrimaryMouseButton:
      return PointerButton.primary;
    case kSecondaryMouseButton:
      return PointerButton.secondary;
    case kTertiaryButton:
      return PointerButton.tertiary;
    default:
      return PointerButton.none;
  }
}

const MethodChannel _pluginChannel = IN_APP_WEBVIEW_STATIC_CHANNEL;

class CustomFlutterViewControllerValue {
  const CustomFlutterViewControllerValue({
    required this.isInitialized,
  });

  final bool isInitialized;

  CustomFlutterViewControllerValue copyWith({
    bool? isInitialized,
  }) {
    return CustomFlutterViewControllerValue(
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }

  CustomFlutterViewControllerValue.uninitialized()
      : this(
          isInitialized: false,
        );
}

/// Controls a WebView and provides streams for various change events.
class CustomPlatformViewController
    extends ValueNotifier<CustomFlutterViewControllerValue> {
  Completer<void> _creatingCompleter = Completer<void>();
  int _textureId = 0;
  bool _isDisposed = false;
  bool _native = false;
  VoidCallback? onNativeFocus;
  VoidCallback? onNativeResizeEnd;

  Future<void> get ready => _creatingCompleter.future;

  late MethodChannel _methodChannel;
  late EventChannel _eventChannel;
  StreamSubscription? _eventStreamSubscription;

  final StreamController<SystemMouseCursor> _cursorStreamController =
      StreamController<SystemMouseCursor>.broadcast();

  /// A stream reflecting the current cursor style.
  Stream<SystemMouseCursor> get _cursor => _cursorStreamController.stream;

  CustomPlatformViewController()
      : super(CustomFlutterViewControllerValue.uninitialized());

  /// Initializes the underlying platform view.
  Future<void> initialize(
      {Function(int id)? onPlatformViewCreated, dynamic arguments}) async {
    if (_isDisposed) {
      return;
    }
    _textureId = (await _pluginChannel.invokeMethod<int>(
        'createInAppWebView', arguments))!;

    _methodChannel =
        MethodChannel('com.pichillilorenzo/custom_platform_view_$_textureId');
    _eventChannel = EventChannel(
        'com.pichillilorenzo/custom_platform_view_${_textureId}_events');
    _eventStreamSubscription =
        _eventChannel.receiveBroadcastStream().listen((event) {
      final map = event as Map<dynamic, dynamic>;
      switch (map['type']) {
        case 'nativeResizeEnd':
          onNativeResizeEnd?.call();
          break;
        case 'nativeFocus':
          onNativeFocus?.call();
          break;
        case 'cursorChanged':
          _cursorStreamController.add(_getCursorByName(map['value']));
          break;
      }
    });

    _methodChannel.setMethodCallHandler((call) {
      throw MissingPluginException('Unknown method ${call.method}');
    });

    _native = await _methodChannel.invokeMethod<bool>('isNative') ?? false;
    value = value.copyWith(isInitialized: true);

    _creatingCompleter.complete();

    onPlatformViewCreated?.call(_textureId);
  }

  @override
  Future<void> dispose() async {
    await _creatingCompleter.future;
    if (!_isDisposed) {
      _isDisposed = true;
      await _eventStreamSubscription?.cancel();
      await _pluginChannel.invokeMethod('dispose', {"id": _textureId});
    }
    super.dispose();
  }

  /// Limits the number of frames per second to the given value.
  Future<void> setFpsLimit([int? maxFps = 0]) async {
    if (_isDisposed) {
      return;
    }
    assert(value.isInitialized);
    return _methodChannel.invokeMethod('setFpsLimit', maxFps);
  }

  /// Sends a Pointer (Touch) update
  Future<void> _setPointerUpdate(InAppWebViewPointerEventKind kind, int pointer,
      Offset position, double size, double pressure) async {
    if (_isDisposed) {
      return;
    }
    assert(value.isInitialized);
    return _methodChannel.invokeMethod('setPointerUpdate',
        [pointer, kind.index, position.dx, position.dy, size, pressure]);
  }

  /// Moves the virtual cursor to [position].
  Future<void> _setCursorPos(Offset position) async {
    if (_isDisposed) {
      return;
    }
    assert(value.isInitialized);
    return _methodChannel
        .invokeMethod('setCursorPos', [position.dx, position.dy]);
  }

  /// Indicates whether the specified [button] is currently down.
  Future<void> _setPointerButtonState(PointerButton button, bool isDown) async {
    if (_isDisposed) {
      return;
    }
    assert(value.isInitialized);
    return _methodChannel.invokeMethod('setPointerButton',
        <String, dynamic>{'button': button.index, 'isDown': isDown});
  }

  /// Sets the horizontal and vertical scroll delta.
  Future<void> _setScrollDelta(double dx, double dy) async {
    if (_isDisposed) {
      return;
    }
    assert(value.isInitialized);
    return _methodChannel.invokeMethod('setScrollDelta', [dx, dy]);
  }

  /// Sets the surface size to the provided [size].
  Future<void> _setSize(Size size, double scaleFactor) async {
    if (_isDisposed) {
      return;
    }
    assert(value.isInitialized);
    return _methodChannel
        .invokeMethod('setSize', [size.width, size.height, scaleFactor]);
  }

  /// Sets the surface size to the provided [size].
  Future<void> _setPosition(Offset position, double scaleFactor) async {
    if (_isDisposed) {
      return;
    }
    assert(value.isInitialized);
    return _methodChannel
        .invokeMethod('setPosition', [position.dx, position.dy, scaleFactor]);
  }
}

class WindowsWebViewPresentation extends InheritedWidget {
  const WindowsWebViewPresentation(
      {super.key,
      required super.child,
      this.visible = true,
      this.overlayBounds,
      this.onFocus});

  final bool visible;
  final Rect? overlayBounds;
  final VoidCallback? onFocus;

  @override
  bool updateShouldNotify(WindowsWebViewPresentation oldWidget) =>
      visible != oldWidget.visible || overlayBounds != oldWidget.overlayBounds;
}

class _NativeGeometryObserver extends LeafRenderObjectWidget {
  const _NativeGeometryObserver({required this.onPaint});
  final VoidCallback onPaint;
  @override
  RenderObject createRenderObject(BuildContext context) =>
      _NativeGeometryRenderBox(onPaint);
  @override
  void updateRenderObject(
      BuildContext context, covariant _NativeGeometryRenderBox renderObject) {
    renderObject.onPaint = onPaint;
  }
}

class _NativeGeometryRenderBox extends RenderBox {
  _NativeGeometryRenderBox(this.onPaint);
  VoidCallback onPaint;
  @override
  bool get sizedByParent => true;
  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.biggest;
  @override
  void performResize() {
    size = constraints.biggest;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    onPaint();
  }
}

/// The laid-out client area can be smaller than the native backing surface.
class WindowsClientViewport extends SingleChildRenderObjectWidget {
  const WindowsClientViewport({super.key, required super.child});

  @override
  RenderProxyBox createRenderObject(BuildContext context) =>
      _RenderWindowsClientViewport();
}

class _RenderWindowsClientViewport extends RenderProxyBox {}

class CustomPlatformView extends StatefulWidget {
  /// An optional scale factor. Defaults to [FlutterView.devicePixelRatio] for
  /// rendering in native resolution.
  /// Setting this to 1.0 will disable high-DPI support.
  /// This should only be needed to mimic old behavior before high-DPI support
  /// was available.
  final double? scaleFactor;

  /// The [FilterQuality] used for scaling the texture's contents.
  /// Defaults to [FilterQuality.none] as this renders in native resolution
  /// unless specifying a [scaleFactor].
  final FilterQuality filterQuality;

  final dynamic creationParams;

  final Function(int id)? onPlatformViewCreated;

  const CustomPlatformView(
      {this.creationParams,
      this.onPlatformViewCreated,
      this.scaleFactor,
      this.filterQuality = FilterQuality.none});

  @override
  _CustomPlatformViewState createState() => _CustomPlatformViewState();
}

class _CustomPlatformViewState extends State<CustomPlatformView>
    with WidgetsBindingObserver {
  final GlobalKey _key = GlobalKey();
  final _downButtons = <int, PointerButton>{};

  PointerDeviceKind _pointerKind = PointerDeviceKind.unknown;

  MouseCursor _cursor = SystemMouseCursors.basic;

  final _controller = CustomPlatformViewController();
  final _focusNode = FocusNode();

  StreamSubscription? _cursorSubscription;
  double _devicePixelRatio = 1;
  bool _geometryScheduled = false;
  bool _nativeVisible = true;
  Rect? _overlayBounds;
  List<Object?>? _lastGeometry;
  List<Object?>? _rejectedGeometry;
  int _geometryRetryCount = 0;

  void _scheduleNativeGeometry() {
    if (_geometryScheduled || !mounted) return;
    _geometryScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _geometryScheduled = false;
      _reportNativeGeometry();
    });
  }

  Future<void> _reportNativeGeometry() async {
    await _controller.ready;
    if (!mounted || !_controller._native || _controller._isDisposed) return;
    final box = _key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final rect = MatrixUtils.transformRect(
      box.getTransformTo(null),
      Offset.zero & box.size,
    );
    RenderObject root = box;
    while (root.parent != null && root is! _RenderWindowsClientViewport) {
      root = root.parent!;
    }
    // Use the viewport which produced this layout, not a newer OS metrics event.
    final viewport = switch (root) {
      _RenderWindowsClientViewport() => root.size * _devicePixelRatio,
      RenderView() => root.size * _devicePixelRatio,
      _ => View.of(context).physicalSize,
    };
    final overlay = _overlayBounds;
    final values = <Object?>[
      rect,
      viewport,
      _devicePixelRatio,
      _nativeVisible,
      overlay,
    ];
    if (_lastGeometry != null &&
        List.generate(values.length, (i) => values[i] == _lastGeometry![i])
            .every((v) => v)) return;
    _lastGeometry = values;
    final accepted =
        await _controller._methodChannel.invokeMethod<bool>('setGeometry', {
      'x': rect.left,
      'y': rect.top,
      'width': rect.width,
      'height': rect.height,
      'viewportWidth': viewport.width,
      'viewportHeight': viewport.height,
      'scale': _devicePixelRatio,
      'visible': _nativeVisible,
      'overlayX': overlay?.left ?? 0.0,
      'overlayY': overlay?.top ?? 0.0,
      'overlayWidth': overlay?.width ?? 0.0,
      'overlayHeight': overlay?.height ?? 0.0,
    });
    if (accepted == false && mounted) {
      _lastGeometry = null;
      if (_rejectedGeometry == null ||
          !List.generate(values.length, (i) => values[i] == _rejectedGeometry![i])
              .every((v) => v)) {
        _geometryRetryCount = 0;
        _rejectedGeometry = values;
      }
      if (_geometryRetryCount++ < 5) {
        _scheduleNativeGeometry();
        WidgetsBinding.instance.scheduleFrame();
      }
    } else if (accepted != false) {
      _rejectedGeometry = null;
      _geometryRetryCount = 0;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _devicePixelRatio = View.of(context).devicePixelRatio;
    final presentation = context
        .dependOnInheritedWidgetOfExactType<WindowsWebViewPresentation>();
    _nativeVisible = TickerMode.of(context) &&
        (ModalRoute.isCurrentOf(context) ?? true) &&
        (presentation?.visible ?? true);
    _overlayBounds = presentation?.overlayBounds;
    _controller.onNativeFocus = presentation?.onFocus;
    _controller.onNativeResizeEnd = () {
      if (!mounted) return;
      _lastGeometry = null;
      _scheduleNativeGeometry();
      WidgetsBinding.instance.scheduleFrame();
    };
    _scheduleNativeGeometry();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _reportSurfaceSize();
      _reportWidgetPosition();
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _controller.initialize(
        onPlatformViewCreated: (id) {
          if (!mounted) return;
          widget.onPlatformViewCreated?.call(id);
          setState(() {});
          _scheduleNativeGeometry();
        },
        arguments: widget.creationParams);

    // Report initial surface size and widget position
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reportSurfaceSize();
      _reportWidgetPosition();
    });

    _cursorSubscription = _controller._cursor.listen((cursor) {
      setState(() {
        _cursor = cursor;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_controller._native) {
      return SizedBox.expand(
          key: _key,
          child: _NativeGeometryObserver(onPaint: _scheduleNativeGeometry));
    }
    return Focus(
      autofocus: true,
      focusNode: _focusNode,
      canRequestFocus: true,
      debugLabel: "flutter_inappwebview_windows_custom_platform_view",
      onFocusChange: (focused) {},
      child: SizedBox.expand(key: _key, child: _buildInner()),
    );
  }

  Widget _buildInner() {
    return NotificationListener<SizeChangedLayoutNotification>(
        onNotification: (notification) {
          _reportSurfaceSize();
          _reportWidgetPosition();
          return true;
        },
        child: SizeChangedLayoutNotifier(
            child: _controller.value.isInitialized
                ? Listener(
                    onPointerHover: (ev) {
                      // ev.kind is for whatever reason not set to touch
                      // even on touch input
                      if (_pointerKind == PointerDeviceKind.touch) {
                        // Ignoring hover events on touch for now
                        return;
                      }
                      _controller._setCursorPos(ev.localPosition);
                    },
                    onPointerDown: (ev) {
                      _reportSurfaceSize();
                      _reportWidgetPosition();

                      if (!_focusNode.hasFocus) {
                        _focusNode.requestFocus();
                        Future.delayed(const Duration(milliseconds: 50), () {
                          if (!_focusNode.hasFocus) {
                            _focusNode.requestFocus();
                          }
                        });
                      }

                      _pointerKind = ev.kind;
                      if (ev.kind == PointerDeviceKind.touch) {
                        _controller._setPointerUpdate(
                            InAppWebViewPointerEventKind.down,
                            ev.pointer,
                            ev.localPosition,
                            ev.size,
                            ev.pressure);
                        return;
                      }
                      final button = _getButton(ev.buttons);
                      _downButtons[ev.pointer] = button;
                      _controller._setPointerButtonState(button, true);
                    },
                    onPointerUp: (ev) {
                      _pointerKind = ev.kind;
                      if (ev.kind == PointerDeviceKind.touch) {
                        _controller._setPointerUpdate(
                            InAppWebViewPointerEventKind.up,
                            ev.pointer,
                            ev.localPosition,
                            ev.size,
                            ev.pressure);
                        return;
                      }
                      final button = _downButtons.remove(ev.pointer);
                      if (button != null) {
                        _controller._setPointerButtonState(button, false);
                      }
                    },
                    onPointerCancel: (ev) {
                      _pointerKind = ev.kind;
                      final button = _downButtons.remove(ev.pointer);
                      if (button != null) {
                        _controller._setPointerButtonState(button, false);
                      }
                    },
                    onPointerMove: (ev) {
                      _pointerKind = ev.kind;
                      if (ev.kind == PointerDeviceKind.touch) {
                        _controller._setPointerUpdate(
                            InAppWebViewPointerEventKind.update,
                            ev.pointer,
                            ev.localPosition,
                            ev.size,
                            ev.pressure);
                      } else {
                        _controller._setCursorPos(ev.localPosition);
                      }
                    },
                    onPointerSignal: (signal) {
                      if (signal is PointerScrollEvent) {
                        _controller._setScrollDelta(
                            -signal.scrollDelta.dx, -signal.scrollDelta.dy);
                      }
                    },
                    onPointerPanZoomUpdate: (ev) {
                      _controller._setScrollDelta(
                          ev.panDelta.dx, ev.panDelta.dy);
                    },
                    child: MouseRegion(
                        cursor: _cursor,
                        child: Texture(
                          textureId: _controller._textureId,
                          filterQuality: widget.filterQuality,
                        )),
                  )
                : const SizedBox()));
  }

  void _reportSurfaceSize() async {
    await _controller.ready;
    if (!mounted) return;
    if (_controller._native) {
      _scheduleNativeGeometry();
      return;
    }
    final box = _key.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) {
      unawaited(_controller._setSize(
          box.size, widget.scaleFactor ?? _devicePixelRatio));
    }
  }

  void _reportWidgetPosition() async {
    await _controller.ready;
    if (!mounted) return;
    if (_controller._native) {
      _scheduleNativeGeometry();
      return;
    }
    final box = _key.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) {
      final position = box.localToGlobal(Offset.zero);
      unawaited(_controller._setPosition(
          position, widget.scaleFactor ?? _devicePixelRatio));
    }
  }

  @override
  void deactivate() {
    if (_controller.value.isInitialized &&
        _controller._native &&
        !_controller._isDisposed) {
      unawaited(
          _controller._methodChannel.invokeMethod<void>('setVisible', false));
    }
    _lastGeometry = null;
    super.deactivate();
  }

  @override
  void activate() {
    super.activate();
    _scheduleNativeGeometry();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
    _cursorSubscription?.cancel();
    _controller.dispose();
    _focusNode.dispose();
  }

  void _refreshNativePresentation() {
    if (!mounted || !_controller._native || _controller._isDisposed) return;
    _lastGeometry = null;
    _scheduleNativeGeometry();
    WidgetsBinding.instance.scheduleFrame();
  }

  @override
  void didChangeMetrics() => _refreshNativePresentation();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshNativePresentation();
  }
}
