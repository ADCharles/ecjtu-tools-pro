// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'ai_bridge.dart';

enum AiMcpPlatform { windows, macos, linux, android, ios, unsupported }

AiMcpPlatform _currentPlatform() {
  if (Platform.isWindows) return AiMcpPlatform.windows;
  if (Platform.isMacOS) return AiMcpPlatform.macos;
  if (Platform.isLinux) return AiMcpPlatform.linux;
  if (Platform.isAndroid) return AiMcpPlatform.android;
  if (Platform.isIOS) return AiMcpPlatform.ios;
  return AiMcpPlatform.unsupported;
}

/// Stateless Streamable HTTP: each JSON response completes its POST request.
class AiMcpServer {
  AiMcpServer({
    required this.bridge,
    this.port = defaultPort,
    this.requestTimeout = const Duration(seconds: 10),
    this.toolTimeout = const Duration(seconds: 30),
    this.maxBodyBytes = 256 * 1024,
    AiMcpPlatform? platform,
  }) : platform = platform ?? _currentPlatform() {
    if (port < 0 ||
        port > 65535 ||
        maxBodyBytes < 1 ||
        requestTimeout <= Duration.zero ||
        toolTimeout <= Duration.zero) {
      throw ArgumentError('Invalid MCP server configuration');
    }
  }

  static const defaultPort = 41731;
  static const protocolVersions = ['2025-11-25', '2025-06-18', '2025-03-26'];

  final AiBridge bridge;
  final int port;
  final Duration requestTimeout;
  final Duration toolTimeout;
  final int maxBodyBytes;
  final AiMcpPlatform platform;
  HttpServer? _server;
  Future<Uri>? _starting;
  Future<void>? _stopping;
  int _generation = 0;

  bool get isRunning => _server != null;
  bool get supportsExternalConnection => switch (platform) {
    AiMcpPlatform.windows || AiMcpPlatform.macos || AiMcpPlatform.linux => true,
    _ => false,
  };
  Uri? get endpoint => _server == null
      ? null
      : Uri(
          scheme: 'http',
          host: '127.0.0.1',
          port: _server!.port,
          path: '/mcp',
        );

  Future<Uri> start() {
    if (!supportsExternalConnection) {
      return Future.error(
        UnsupportedError('External MCP is available on desktop only'),
      );
    }
    if (_stopping != null) return _stopping!.then((_) => start());
    if (_starting != null) return _starting!;
    if (endpoint != null) return Future.value(endpoint);
    final generation = ++_generation;
    final future = _bind(generation);
    _starting = future;
    return future;
  }

  Future<Uri> _bind(int generation) async {
    try {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
      if (generation != _generation) {
        await server.close(force: true);
        throw StateError('MCP start was cancelled');
      }
      _server = server;
      server.idleTimeout = requestTimeout;
      server.listen(
        (request) => unawaited(_handle(request, server, generation)),
        onError: (Object _) {},
      );
      return endpoint!;
    } finally {
      _starting = null;
    }
  }

  Future<void> stop() {
    if (_stopping != null) return _stopping!;
    ++_generation;
    final future = _close();
    _stopping = future;
    return future;
  }

  Future<void> _close() async {
    try {
      final starting = _starting;
      if (starting != null) {
        try {
          await starting;
        } catch (_) {
          // stop() also cancels a bind which has not completed yet.
        }
      }
      final server = _server;
      _server = null;
      await server?.close(force: true);
    } finally {
      _stopping = null;
    }
  }

  Future<void> _handle(
    HttpRequest request,
    HttpServer server,
    int generation,
  ) async {
    final response = request.response;
    response.headers.set(HttpHeaders.cacheControlHeader, 'no-store');
    try {
      if (!_validHost(request, server.port) ||
          !_validOrigin(request, server.port)) {
        await _httpError(response, 403, 'Forbidden origin or host');
        return;
      }
      if (request.uri.path != '/mcp' || request.uri.hasQuery) {
        await _httpError(response, 404, 'Not found');
        return;
      }
      if (request.method != 'POST') {
        response.headers.set(HttpHeaders.allowHeader, 'POST');
        await _httpError(response, 405, 'Use POST for this MCP endpoint');
        return;
      }
      if (request.headers.contentType?.mimeType != 'application/json') {
        await _httpError(response, 415, 'Expected application/json');
        return;
      }
      final accept = request.headers.value(HttpHeaders.acceptHeader);
      if (accept != null &&
          !accept.contains('application/json') &&
          !accept.contains('*/*')) {
        await _httpError(response, 406, 'Expected application/json responses');
        return;
      }
      final version = request.headers.value('MCP-Protocol-Version');
      if (version != null && !protocolVersions.contains(version)) {
        await _httpError(response, 400, 'Unsupported MCP protocol version');
        return;
      }
      if (request.contentLength > maxBodyBytes) {
        await _httpError(response, 413, 'Request body too large');
        return;
      }
      final bytes = await _readBody(request);
      Object? decoded;
      try {
        decoded = jsonDecode(utf8.decode(bytes));
      } on FormatException {
        await _json(response, _error(null, -32700, 'Parse error'), status: 400);
        return;
      }
      if (decoded is! Map<String, dynamic> ||
          decoded['jsonrpc'] != '2.0' ||
          decoded['method'] is! String ||
          (decoded.containsKey('id') &&
              decoded['id'] is! String &&
              decoded['id'] is! int) ||
          (decoded.containsKey('params') && decoded['params'] is! Map)) {
        await _json(
          response,
          _error(null, -32600, 'Invalid Request'),
          status: 400,
        );
        return;
      }
      if (generation != _generation) {
        await _httpError(response, 503, 'MCP server is stopping');
        return;
      }
      final method = decoded['method'] as String;
      final params = (decoded['params'] as Map<String, dynamic>?) ?? {};
      if (!decoded.containsKey('id')) {
        // JSON-RPC notifications never receive a JSON-RPC response.
        response.statusCode = 202;
        await response.close();
        return;
      }
      final id = decoded['id'] as Object;
      try {
        final result = await _dispatch(
          method,
          params,
          isCancelled: () => generation != _generation,
        );
        await _json(response, {'jsonrpc': '2.0', 'id': id, 'result': result});
      } on _RpcError catch (error) {
        await _json(response, _error(id, error.code, error.message));
      }
    } on _BodyTooLarge {
      await _httpError(response, 413, 'Request body too large');
    } on TimeoutException {
      await _httpError(response, 408, 'Request body timed out');
    } catch (_) {
      // Transport and callback exceptions can contain URLs or session details.
      try {
        await _httpError(response, 500, 'MCP request failed');
      } catch (_) {}
    }
  }

  Future<List<int>> _readBody(HttpRequest request) {
    final result = Completer<List<int>>();
    final bytes = BytesBuilder(copy: false);
    final timer = Timer(requestTimeout, () {
      if (!result.isCompleted) {
        result.completeError(TimeoutException('Request body timed out'));
      }
    });
    // Cancelling HttpRequest's subscription closes its socket before a 413/408
    // can be flushed. Discard remaining input until the error response closes it.
    request.listen(
      (chunk) {
        if (result.isCompleted) return;
        if (bytes.length + chunk.length > maxBodyBytes) {
          result.completeError(_BodyTooLarge());
        } else {
          bytes.add(chunk);
        }
      },
      onDone: () {
        if (!result.isCompleted) result.complete(bytes.takeBytes());
      },
      onError: (Object error) {
        if (!result.isCompleted) result.completeError(error);
      },
    );
    return result.future.whenComplete(timer.cancel);
  }

  Future<Map<String, Object?>> _dispatch(
    String method,
    Map<String, dynamic> params, {
    bool Function()? isCancelled,
  }) async {
    switch (method) {
      case 'initialize':
        if (params['protocolVersion'] is! String ||
            params['capabilities'] is! Map ||
            params['clientInfo'] is! Map ||
            (params['clientInfo'] as Map)['name'] is! String ||
            (params['clientInfo'] as Map)['version'] is! String) {
          throw const _RpcError(-32602, 'Invalid initialize parameters');
        }
        final requested = params['protocolVersion'] as String;
        return {
          'protocolVersion': protocolVersions.contains(requested)
              ? requested
              : protocolVersions.first,
          'capabilities': {
            'tools': {'listChanged': false},
          },
          'serverInfo': {'name': 'ecjtu-tools', 'version': '4.1.0'},
          'instructions':
              'Use ecjtu_list_actions to discover available app actions.',
        };
      case 'ping':
        return {};
      case 'tools/list':
        if (params.containsKey('cursor') && params['cursor'] != '') {
          throw const _RpcError(-32602, 'Invalid cursor');
        }
        return {'tools': bridge.tools};
      case 'tools/call':
        if (params['name'] is! String ||
            (params.containsKey('arguments') && params['arguments'] is! Map)) {
          throw const _RpcError(-32602, 'Invalid tools/call parameters');
        }
        var timedOut = false;
        return bridge
            .callTool(
              params['name'] as String,
              (params['arguments'] as Map<String, dynamic>?) ?? {},
              isCancelled: () => timedOut || (isCancelled?.call() ?? false),
            )
            .timeout(
              toolTimeout,
              onTimeout: () {
                timedOut = true;
                return AiBridge.failure(
                  'operation_timeout',
                  '操作等待超时，请在应用中确认结果后再继续',
                );
              },
            );
      default:
        throw const _RpcError(-32601, 'Method not found');
    }
  }

  static bool _loopbackHost(String host) =>
      const {'127.0.0.1', 'localhost'}.contains(host.toLowerCase());

  static bool _validHost(HttpRequest request, int port) {
    final host = request.headers.value(HttpHeaders.hostHeader);
    if (host == null) return false;
    final uri = Uri.tryParse('http://$host');
    return uri != null &&
        _loopbackHost(uri.host) &&
        uri.port == port &&
        uri.userInfo.isEmpty &&
        uri.path.isEmpty &&
        !uri.hasQuery &&
        !uri.hasFragment;
  }

  static bool _validOrigin(HttpRequest request, int port) {
    final origin = request.headers.value('Origin');
    if (origin == null) return true;
    final uri = Uri.tryParse(origin);
    return uri != null &&
        uri.scheme == 'http' &&
        _loopbackHost(uri.host) &&
        uri.port == port &&
        uri.userInfo.isEmpty &&
        uri.path.isEmpty &&
        !uri.hasQuery &&
        !uri.hasFragment;
  }

  static Map<String, Object?> _error(Object? id, int code, String message) => {
    'jsonrpc': '2.0',
    'id': id,
    'error': {'code': code, 'message': message},
  };

  static Future<void> _httpError(
    HttpResponse response,
    int status,
    String message,
  ) {
    response.persistentConnection = false;
    return _json(response, {'error': message}, status: status);
  }

  static Future<void> _json(
    HttpResponse response,
    Map<String, Object?> value, {
    int status = 200,
  }) async {
    response.statusCode = status;
    response.headers.contentType = ContentType.json;
    response.write(jsonEncode(value));
    await response.close();
  }
}

class _RpcError implements Exception {
  const _RpcError(this.code, this.message);
  final int code;
  final String message;
}

class _BodyTooLarge implements Exception {}
