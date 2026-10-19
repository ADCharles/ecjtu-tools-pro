// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'ai_bridge.dart';
import 'ai_mcp_server.dart';

enum AiConnectionState { stopped, starting, running, stopping, failed }

class AiIntegrationController extends ChangeNotifier {
  AiIntegrationController({
    required this.bridge,
    AiMcpServer? server,
    String? connectorExecutable,
  }) : server = server ?? AiMcpServer(bridge: bridge),
       _connectorExecutable =
           connectorExecutable ??
           File.fromUri(
             File(
               Platform.resolvedExecutable,
             ).uri.resolve(Platform.isWindows ? 'ecjtu-mcp.exe' : 'ecjtu-mcp'),
           ).path {
    if (!identical(this.server.bridge, bridge)) {
      throw ArgumentError('Server and controller must share the same bridge');
    }
    _subscription = bridge.changes.listen((_) => _notify());
  }

  final AiBridge bridge;
  final AiMcpServer server;
  late final StreamSubscription<void> _subscription;
  AiConnectionState _state = AiConnectionState.stopped;
  String? _error;
  bool _disposed = false;
  Future<void>? _closing;
  String _connectorExecutable;

  AiConnectionState get state => _state;
  String? get error => _error;
  Uri? get endpoint => server.endpoint;
  bool get supportsExternalConnection => server.supportsExternalConnection;
  String get connectorExecutable => _connectorExecutable;
  void selectConnectorExecutable(String path) {
    if (_disposed || !supportsExternalConnection) return;
    _connectorExecutable = File(path).absolute.path;
    _notify();
  }

  String get clientConfiguration => const JsonEncoder.withIndent('  ').convert({
    'mcpServers': {
      'ecjtu-tools': {
        'command': connectorExecutable,
        if (endpoint != null && endpoint!.port != AiMcpServer.defaultPort)
          'args': ['--url', endpoint.toString()],
      },
    },
  });
  bool get busy =>
      state == AiConnectionState.starting ||
      state == AiConnectionState.stopping;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<bool> start() async {
    if (_disposed || _closing != null || busy) return false;
    if (!supportsExternalConnection) return false;
    _state = AiConnectionState.starting;
    _error = null;
    _notify();
    try {
      await server.start();
      if (_disposed || _closing != null) return false;
      _state = AiConnectionState.running;
      return true;
    } catch (_) {
      if (!_disposed && _closing == null) {
        _state = AiConnectionState.failed;
        _error = '连接服务未能启动，请检查端口是否被占用后重试';
      }
      return false;
    } finally {
      _notify();
    }
  }

  Future<void> stop() async {
    if (_disposed || _closing != null) return;
    _state = AiConnectionState.stopping;
    _notify();
    await server.stop();
    _state = AiConnectionState.stopped;
    _error = null;
    _notify();
  }

  /// Await before disposing the shell; the shell owns and closes the bridge.
  Future<void> close() => _closing ??= _close();

  Future<void> _close() async {
    await server.stop();
    _state = AiConnectionState.stopped;
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_subscription.cancel());
    unawaited(close());
    super.dispose();
  }
}
