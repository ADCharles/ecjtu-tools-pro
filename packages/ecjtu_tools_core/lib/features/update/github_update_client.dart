// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:pointycastle/digests/sha256.dart';

import 'update_models.dart';

class GitHubUpdateClient {
  GitHubUpdateClient({
    required this.source,
    http.Client? client,
    this.accessToken,
  }) : _client = client ?? http.Client();
  final UpdateSource source;
  final http.Client _client;
  final Future<String?> Function()? accessToken;

  void close() => _client.close();
  int _compareVersions(UpdateVersion left, UpdateVersion right) =>
      source.test ? left.compareTo(right) : left.compareProductTo(right);

  static bool trustedDownload(Uri uri) =>
      uri.scheme == 'https' &&
      uri.userInfo.isEmpty &&
      uri.port == 443 &&
      {
        'api.github.com',
        'github.com',
        'release-assets.githubusercontent.com',
        'objects.githubusercontent.com',
      }.contains(uri.host);

  Future<http.StreamedResponse> _get(Uri uri, {bool binary = false}) async {
    final token = source.test ? await accessToken?.call() : null;
    if (source.test && (token == null || token.isEmpty)) {
      throw const UpdateFailure(
        '请先授权 GitHub 以获取测试版更新',
        needsAuthorization: true,
      );
    }
    for (var redirects = 0; redirects < 5; redirects++) {
      if (!trustedDownload(uri)) {
        throw const UpdateFailure('更新下载地址无效');
      }
      final request = http.Request('GET', uri)..followRedirects = false;
      request.headers.addAll({
        'Accept': binary
            ? 'application/octet-stream'
            : 'application/vnd.github+json',
        'User-Agent': 'ECJTU-Tools-Pro-Updater',
        'X-GitHub-Api-Version': '2026-03-10',
      });
      // Signed asset redirects must never receive the user's GitHub token.
      if (token != null &&
          uri.host == 'api.github.com' &&
          uri.path.startsWith('/repos/${source.repository}/')) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      final response = await _client
          .send(request)
          .timeout(const Duration(seconds: 30));
      if ([301, 302, 303, 307, 308].contains(response.statusCode)) {
        final location = response.headers['location'];
        await response.stream.drain<void>().timeout(
          const Duration(seconds: 30),
        );
        if (!binary || location == null) {
          throw const UpdateFailure('更新服务返回了无效地址');
        }
        uri = uri.resolve(location);
        continue;
      }
      if (response.statusCode != 200) {
        await response.stream.drain<void>().timeout(
          const Duration(seconds: 30),
        );
        if (source.test && [401, 404].contains(response.statusCode)) {
          throw const UpdateFailure(
            'GitHub 授权已失效或尚未获得测试仓库访问权限',
            needsAuthorization: true,
          );
        }
        if ([403, 429].contains(response.statusCode)) {
          throw const UpdateFailure('GitHub 暂时限制了访问，请稍后重试');
        }
        throw UpdateFailure('更新服务暂不可用（${response.statusCode}）');
      }
      return response;
    }
    throw const UpdateFailure('更新下载重定向次数过多');
  }

  Future<List<int>> _small(Uri uri, {bool binary = false}) async {
    final response = await _get(uri, binary: binary);
    final bytes = <int>[];
    await for (final chunk in response.stream.timeout(
      const Duration(seconds: 30),
    )) {
      bytes.addAll(chunk);
      if (bytes.length > 2 * 1024 * 1024) {
        throw const UpdateFailure('更新信息过大');
      }
    }
    return bytes;
  }

  Future<Map<String, dynamic>?> applicationNotices({
    required String tag,
  }) async {
    final release =
        jsonDecode(
              utf8.decode(
                await _small(
                  Uri.https(
                    'api.github.com',
                    '/repos/${source.repository}/releases/tags/$tag',
                    {'t': '${DateTime.now().millisecondsSinceEpoch}'},
                  ),
                ),
              ),
            )
            as Map<String, dynamic>;
    if (release['draft'] == true) return null;
    for (final value in release['assets'] as List? ?? const []) {
      if (value['name'] != 'notices.json') continue;
      final id = value['id'];
      if (id is! int || (value['size'] as num? ?? 0) > 256 * 1024)
        throw const FormatException('Notice asset');
      final bytes = await _small(
        Uri.https(
          'api.github.com',
          '/repos/${source.repository}/releases/assets/$id',
        ),
        binary: true,
      );
      final digest = value['digest'] as String?;
      if (digest == null || digest != 'sha256:${sha256Bytes(bytes)}')
        throw const FormatException('Notice digest');
      return jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    }
    return null;
  }

  Future<UpdateRelease?> latest(
    String architecture,
    UpdateVersion current,
  ) async {
    UpdateRelease? newest;
    for (var page = 1; page <= 5; page++) {
      final uri = source.releases.replace(
        queryParameters: {'per_page': '100', 'page': '$page'},
      );
      final releases = jsonDecode(utf8.decode(await _small(uri))) as List;
      for (final raw in releases) {
        final release = raw as Map<String, dynamic>;
        if (release['draft'] == true || release['prerelease'] != source.test) {
          continue;
        }
        final tag = release['tag_name'] as String;
        final match = RegExp(
          source.test
              ? r'^windows-v(\d+\.\d+\.\d+)(?:\+(\d+))?$'
              : r'^(?:windows-)?v(\d+\.\d+\.\d+)(?:\+(\d+))?$',
        ).firstMatch(tag);
        if (match == null || (source.test && match[2] == null)) continue;
        if (!source.test &&
            UpdateVersion.parse(match[1]!, 0).compareProductTo(current) <= 0)
          continue;
        if (match[2] != null) {
          final version = UpdateVersion.parse(match[1]!, int.parse(match[2]!));
          if (_compareVersions(version, current) <= 0 ||
              (newest != null &&
                  _compareVersions(version, newest.version) <= 0))
            continue;
        }
        final assets = (release['assets'] as List)
            .map(
              (value) => ReleaseAsset.fromJson(value as Map<String, dynamic>),
            )
            .toList();
        final manifests = assets
            .where((asset) => asset.name == source.manifestName(architecture))
            .toList();
        if (manifests.length != 1) continue;
        final bytes = await _small(manifests.single.uri(source), binary: true);
        if (manifests.single.digest != null &&
            manifests.single.digest != 'sha256:${sha256Bytes(bytes)}') {
          throw const UpdateFailure('更新信息校验失败');
        }
        final candidate = UpdateRelease.fromManifest(
          jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>,
          source: source,
          architecture: architecture,
          tag: tag,
          notes: release['body'] as String? ?? '',
          assets: assets,
        );
        if (_compareVersions(candidate.version, current) > 0 &&
            (newest == null ||
                _compareVersions(candidate.version, newest.version) > 0)) {
          newest = candidate;
        }
      }
      if (releases.length < 100) break;
    }
    return newest;
  }

  Future<UpdateRelease?> latestAndroid(UpdateVersion current) async {
    UpdateRelease? newest;
    for (var page = 1; page <= 5; page++) {
      final uri = source.releases.replace(
        queryParameters: {'per_page': '100', 'page': '$page'},
      );
      final releases = jsonDecode(utf8.decode(await _small(uri))) as List;
      for (final raw in releases) {
        final value = raw as Map<String, dynamic>;
        if (value['draft'] == true || value['prerelease'] != source.test)
          continue;
        final tag = value['tag_name'] as String;
        final match = RegExp(
          source.test
              ? r'^android-v(\d+\.\d+\.\d+)(?:\+(\d+))?$'
              : r'^(?:android-)?v(\d+\.\d+\.\d+)(?:\+(\d+))?$',
        ).firstMatch(tag);
        if (match == null || (source.test && match[2] == null)) continue;
        if (!source.test &&
            UpdateVersion.parse(match[1]!, 0).compareProductTo(current) <= 0)
          continue;
        final assets = (value['assets'] as List)
            .map((item) => ReleaseAsset.fromJson(item as Map<String, dynamic>))
            .toList();
        final packages = assets
            .where((asset) => asset.name.endsWith('.apk'))
            .toList();
        if (packages.length != 1) continue;
        final apk = packages.single;
        Map<String, dynamic>? manifest;
        if (match[2] == null) {
          final manifests = assets
              .where((a) => a.name == 'update-android-arm64.json')
              .toList();
          if (manifests.length != 1) continue;
          final bytes = await _small(
            manifests.single.uri(source),
            binary: true,
          );
          if (manifests.single.digest != null &&
              manifests.single.digest != 'sha256:${sha256Bytes(bytes)}') {
            throw const UpdateFailure('更新信息校验失败');
          }
          manifest = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
          if (manifest['schema'] != 1 ||
              manifest['product'] != 'ecjtu-tools-pro' ||
              manifest['platform'] != 'android' ||
              manifest['architecture'] != 'arm64' ||
              manifest['channel'] != source.channel ||
              manifest['version'] != match[1] ||
              manifest['asset'] != apk.name ||
              manifest['size'] != apk.size) {
            throw const UpdateFailure('更新包与当前版本不匹配');
          }
        }
        final version = UpdateVersion.parse(
          match[1]!,
          manifest?['buildNumber'] as int? ?? int.parse(match[2]!),
        );
        if (_compareVersions(version, current) <= 0 ||
            newest != null && _compareVersions(version, newest.version) <= 0)
          continue;
        var hash = apk.digest?.replaceFirst('sha256:', '');
        final checksum = assets
            .where(
              (asset) =>
                  asset.name == 'SHA256SUMS.txt' ||
                  asset.name == '${apk.name}.sha256',
            )
            .firstOrNull;
        hash ??= manifest?['sha256'] as String?;
        if (hash == null && checksum != null) {
          final text = utf8.decode(
            await _small(checksum.uri(source), binary: true),
          );
          for (final line in text.split('\n')) {
            final fields = line.trim().split(RegExp(r'\s+'));
            if (fields.length >= 2 &&
                fields.skip(1).join(' ').replaceFirst('*', '') == apk.name)
              hash = fields.first;
          }
        }
        if (hash == null ||
            !RegExp(r'^[a-f0-9]{64}$').hasMatch(hash) ||
            apk.size <= 0)
          throw const UpdateFailure('更新包校验信息不完整');
        if (manifest != null && manifest['sha256'] != hash) {
          throw const UpdateFailure('更新包校验信息不一致');
        }
        newest = UpdateRelease(
          version: version,
          installer: apk,
          sha256: hash,
          notes: value['body'] as String? ?? '',
          tag: tag,
          channel: source.channel,
          architecture: 'android',
        );
      }
      if (releases.length < 100) break;
    }
    return newest;
  }

  Future<UpdateRelease?> latestPhysicsComponent(String platform) async {
    final uri = source.releases.replace(queryParameters: {'per_page': '100'});
    final releases = (jsonDecode(utf8.decode(await _small(uri))) as List)
        .cast<Map<String, dynamic>>();
    final pattern = RegExp(r'^physics-v4\.0\.1\+(\d+)$');
    int revision(Map<String, dynamic> release) =>
        int.tryParse(
          pattern.firstMatch(release['tag_name'] as String)?.group(1) ?? '',
        ) ??
        -1;
    releases.sort((a, b) => revision(b).compareTo(revision(a)));
    for (final release in releases) {
      if (release['draft'] == true ||
          release['prerelease'] != source.test ||
          revision(release) < 1)
        continue;
      final build = revision(release);
      final assets = (release['assets'] as List)
          .map((v) => ReleaseAsset.fromJson(v as Map<String, dynamic>))
          .toList();
      var matches = assets
          .where((v) => v.name == 'physics-$platform-v4.0.1+$build.zip')
          .toList();
      if (matches.isEmpty && platform == 'ios') {
        matches = assets
            .where((v) => v.name == 'physics-portable-v4.0.1+$build.zip')
            .toList();
      }
      if (matches.length != 1) continue;
      final asset = matches.single;
      final hash = asset.digest?.replaceFirst('sha256:', '');
      if (hash == null ||
          !RegExp(r'^[a-f0-9]{64}$').hasMatch(hash) ||
          asset.size <= 0 ||
          asset.size > 160 * 1024 * 1024) {
        throw const UpdateFailure('组件包校验信息不完整');
      }
      return UpdateRelease(
        version: UpdateVersion(4, 0, 1, build),
        installer: asset,
        sha256: hash,
        notes: '',
        tag: release['tag_name'] as String,
        channel: source.channel,
        architecture: platform,
      );
    }
    return null;
  }

  Future<void> download(
    UpdateRelease release,
    File destination,
    void Function(int received, int total) progress,
  ) async {
    final response = await _get(release.installer.uri(source), binary: true);
    final part = File('${destination.path}.part');
    final sink = part.openWrite();
    final digest = SHA256Digest();
    var received = 0;
    try {
      await for (final chunk in response.stream.timeout(
        const Duration(seconds: 30),
      )) {
        received += chunk.length;
        if (received > release.installer.size) {
          throw const UpdateFailure('更新包大小不一致');
        }
        final bytes = Uint8List.fromList(chunk);
        digest.update(bytes, 0, bytes.length);
        sink.add(bytes);
        progress(received, release.installer.size);
      }
      await sink.flush();
      if (received != release.installer.size ||
          digestHex(digest) != release.sha256) {
        throw const UpdateFailure('更新包校验失败，请重新下载');
      }
      await sink.close();
      await part.rename(destination.path);
    } catch (_) {
      await sink.close();
      if (await part.exists()) await part.delete();
      rethrow;
    }
  }
}
