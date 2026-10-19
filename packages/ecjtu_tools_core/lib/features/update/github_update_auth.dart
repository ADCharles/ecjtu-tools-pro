// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../data/serialized_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'update_models.dart';

class GitHubDeviceCode {
  const GitHubDeviceCode(this.device, this.user, this.expires, this.interval);
  final String device, user;
  final DateTime expires;
  final int interval;
}

class GitHubUpdateAuth {
  GitHubUpdateAuth({
    http.Client? client,
    FlutterSecureStorage? storage,
    this.clientId = defaultClientId,
    Future<void> Function(Duration)? wait,
  }) : _client = client ?? http.Client(),
       _storage = storage ?? const SerializedSecureStorage(),
       _wait = wait ?? Future<void>.delayed;
  static const defaultClientId = 'Ov23liPnYEC4RSV4DXFt';
  static const _key = 'ecjtu.pro.test.github.authorization';
  final String clientId;
  final http.Client _client;
  final FlutterSecureStorage _storage;
  final Future<void> Function(Duration) _wait;
  int _generation = 0;
  Future<String?>? _refreshing;
  Future<void> _writes = Future<void>.value();

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, String> body,
  ) async {
    final response = await _client
        .post(
          Uri.https('github.com', path),
          headers: {
            'Accept': 'application/json',
            'User-Agent': 'ECJTU-Tools-Pro',
          },
          body: body,
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      throw const UpdateFailure('GitHub 授权服务暂不可用');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<GitHubDeviceCode> begin() async {
    _generation++;
    final value = await _post('/login/device/code', {
      'client_id': clientId,
      'scope': 'repo offline_access',
    });
    if (value['error'] != null) {
      throw const UpdateFailure('无法开始 GitHub 授权，请稍后重试');
    }
    return GitHubDeviceCode(
      value['device_code'] as String,
      value['user_code'] as String,
      DateTime.now().add(Duration(seconds: value['expires_in'] as int)),
      (value['interval'] as int?) ?? 5,
    );
  }

  void cancel() => _generation++;

  Future<String?> complete(GitHubDeviceCode code) async {
    final generation = _generation;
    var interval = code.interval;
    while (DateTime.now().isBefore(code.expires)) {
      await _wait(Duration(seconds: interval));
      if (generation != _generation) return null;
      final result = await _post('/login/oauth/access_token', {
        'client_id': clientId,
        'device_code': code.device,
        'grant_type': 'urn:ietf:params:oauth:grant-type:device_code',
      });
      if (generation != _generation) return null;
      if (result['access_token'] != null) {
        final login = await _validate(result['access_token'] as String);
        if (generation != _generation) return null;
        await _save(result, login, generation);
        return login;
      }
      switch (result['error']) {
        case 'authorization_pending':
          continue;
        case 'slow_down':
          final next = result['interval'] as int?;
          interval = next != null && next > interval ? next : interval + 5;
          continue;
        case 'access_denied':
          throw const UpdateFailure('GitHub 授权已取消');
        default:
          throw const UpdateFailure('GitHub 授权码已失效，请重新授权');
      }
    }
    throw const UpdateFailure('GitHub 授权码已过期，请重新授权');
  }

  Future<String> _validate(String token) async {
    final headers = {
      'Authorization': 'Bearer $token',
      'Accept': 'application/vnd.github+json',
      'User-Agent': 'ECJTU-Tools-Pro',
    };
    final profile = await _client
        .get(Uri.https('api.github.com', '/user'), headers: headers)
        .timeout(const Duration(seconds: 30));
    final repo = await _client
        .get(
          Uri.https(
            'api.github.com',
            '/repos/ADCharles/ecjtu-tools-pro-test-releases',
          ),
          headers: headers,
        )
        .timeout(const Duration(seconds: 30));
    if (profile.statusCode != 200 || repo.statusCode != 200) {
      throw const UpdateFailure(
        '此 GitHub 账号尚未获得测试仓库访问权限',
        needsAuthorization: true,
      );
    }
    return (jsonDecode(profile.body) as Map)['login'] as String;
  }

  Future<String> savePersonalToken(String token) async {
    final generation = ++_generation;
    final value = token.trim();
    if (value.isEmpty || value.contains(RegExp(r'\s'))) {
      throw const UpdateFailure('请输入有效的 GitHub 访问令牌');
    }
    final login = await _validate(value);
    if (generation != _generation) {
      throw const UpdateFailure('GitHub 授权已取消');
    }
    await _save({'access_token': value}, login, generation);
    return login;
  }

  Future<void> _save(Map<String, dynamic> value, String login, int generation) {
    final operation = _writes.then((_) async {
      if (generation != _generation) return;
      await _storage.write(
        key: _key,
        value: jsonEncode({
          'token': value['access_token'],
          'refresh': value['refresh_token'],
          'expires': value['expires_in'] is int
              ? DateTime.now()
                    .add(Duration(seconds: value['expires_in'] as int))
                    .toUtc()
                    .toIso8601String()
              : null,
          'login': login,
        }),
      );
    });
    _writes = operation.then<void>(
      (_) {},
      onError: (Object error, StackTrace stack) {},
    );
    return operation;
  }

  Future<Map<String, dynamic>?> _read() async {
    await _writes;
    final raw = await _storage.read(key: _key);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<String?> login() async => (await _read())?['login'] as String?;
  Future<void> signOut() async {
    cancel();
    final operation = _writes.then((_) => _storage.delete(key: _key));
    _writes = operation.then<void>(
      (_) {},
      onError: (Object error, StackTrace stack) {},
    );
    await operation;
  }

  Future<String?> token() async {
    if (_refreshing != null) return _refreshing;
    final pending = _token();
    _refreshing = pending;
    try {
      return await pending;
    } finally {
      _refreshing = null;
    }
  }

  Future<String?> _token() async {
    final value = await _read();
    if (value == null) return null;
    final expires = DateTime.tryParse(value['expires'] as String? ?? '');
    if (expires == null ||
        expires.isAfter(DateTime.now().add(const Duration(minutes: 2)))) {
      return value['token'] as String?;
    }
    if (value['refresh'] == null) return null;
    final generation = _generation;
    final result = await _post('/login/oauth/access_token', {
      'client_id': clientId,
      'grant_type': 'refresh_token',
      'refresh_token': value['refresh'] as String,
    });
    if (generation != _generation) return null;
    if (result['access_token'] == null) {
      throw const UpdateFailure('GitHub 授权已过期，请重新授权', needsAuthorization: true);
    }
    final login = await _validate(result['access_token'] as String);
    if (generation != _generation) return null;
    await _save(result, login, generation);
    return result['access_token'] as String;
  }
}
