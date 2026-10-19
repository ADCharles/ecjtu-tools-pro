// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../settings/settings_models.dart';

class WebViewRuntime {
  WebViewRuntime._();

  static WebViewEnvironment? environment;
  static NetworkRouteMode activeNetworkRouteMode = NetworkRouteMode.system;
  static String activeHttpProxy = '';
  static Future<void>? _initialization;

  static void configure({
    NetworkRouteMode networkRouteMode = NetworkRouteMode.system,
    String httpProxy = '',
  }) {
    activeNetworkRouteMode = networkRouteMode;
    activeHttpProxy = httpProxy;
  }

  static Future<void> ensureInitialized() {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.windows)
      return Future.value();
    return _initialization ??= _createEnvironment();
  }

  static Future<void> initialize({
    NetworkRouteMode networkRouteMode = NetworkRouteMode.system,
    String httpProxy = '',
  }) {
    configure(networkRouteMode: networkRouteMode, httpProxy: httpProxy);
    return ensureInitialized();
  }

  static Future<void> _createEnvironment() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.windows) return;
    final networkRouteMode = activeNetworkRouteMode;
    final httpProxy = activeHttpProxy;
    try {
      final availableVersion = await WebViewEnvironment.getAvailableVersion()
          .timeout(const Duration(seconds: 4));
      if (availableVersion != null) {
        // WebView2's fluent overlay scrollbars stay hidden until hover and
        // ignore ::-webkit-scrollbar styling, which makes the horizontal
        // scrollbar in the narrow sidebar pane appear missing. Disable that
        // style so the classic custom-drawn scrollbars from the injected CSS
        // apply instead.
        const scrollbarFeatureDisable =
            '--disable-features=msOverlayScrollbarWinStyle,msFluentOverlayScrollbar,msOverlayScrollbarWinAnimations,OverlayScrollbar';
        final arguments = switch (networkRouteMode) {
          NetworkRouteMode.direct =>
            '$scrollbarFeatureDisable --no-proxy-server',
          NetworkRouteMode.system => scrollbarFeatureDisable,
          NetworkRouteMode.httpProxy =>
            '$scrollbarFeatureDisable ${_proxyArgument(httpProxy)}',
        };
        environment = await WebViewEnvironment.create(
          settings: WebViewEnvironmentSettings(
            additionalBrowserArguments: arguments,
          ),
        ).timeout(const Duration(seconds: 8));
      }
    } catch (_) {
      environment = null;
    }
  }

  static String _proxyArgument(String value) {
    final normalized = value.trim();
    final uri = Uri.tryParse(
      normalized.contains('://') ? normalized : 'http://$normalized',
    );
    if (uri == null || uri.host.isEmpty || !uri.hasPort) {
      return '--no-proxy-server';
    }
    return '--proxy-server=http://${uri.host}:${uri.port}';
  }
}
