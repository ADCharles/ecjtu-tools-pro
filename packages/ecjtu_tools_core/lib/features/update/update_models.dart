// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:typed_data';

import 'package:pointycastle/digests/sha256.dart';

class UpdateFailure implements Exception {
  const UpdateFailure(this.message, {this.needsAuthorization = false});
  final String message;
  final bool needsAuthorization;
  @override
  String toString() => message;
}

class UpdateVersion implements Comparable<UpdateVersion> {
  const UpdateVersion(this.major, this.minor, this.patch, this.build);
  final int major, minor, patch, build;
  factory UpdateVersion.parse(String version, int build) {
    final match = RegExp(r'^(\d+)\.(\d+)\.(\d+)$').firstMatch(version);
    if (match == null || build < 0) {
      throw const FormatException('Invalid update version');
    }
    return UpdateVersion(
      int.parse(match[1]!),
      int.parse(match[2]!),
      int.parse(match[3]!),
      build,
    );
  }
  String get version => '$major.$minor.$patch';
  String get label => '$version+$build';
  String displayLabel({required bool test}) =>
      test ? '$version test v$build' : version;
  @override
  int compareTo(UpdateVersion other) {
    final left = [major, minor, patch, build];
    final right = [other.major, other.minor, other.patch, other.build];
    for (var i = 0; i < left.length; i++) {
      final result = left[i].compareTo(right[i]);
      if (result != 0) return result;
    }
    return 0;
  }

  int compareProductTo(UpdateVersion other) {
    final left = [major, minor, patch];
    final right = [other.major, other.minor, other.patch];
    for (var i = 0; i < left.length; i++) {
      final result = left[i].compareTo(right[i]);
      if (result != 0) return result;
    }
    return 0;
  }
}

class UpdateSource {
  const UpdateSource({required this.test});
  final bool test;
  String get channel => test ? 'test' : 'stable';
  String get repository => test
      ? 'ADCharles/ecjtu-tools-pro-test-releases'
      : 'ADCharles/ecjtu-tools-pro-releases';
  Uri get releases =>
      Uri.https('api.github.com', '/repos/$repository/releases');
  String manifestName(String architecture) =>
      'update-windows-$architecture.json';
}

class ReleaseAsset {
  const ReleaseAsset({
    required this.id,
    required this.name,
    required this.size,
    this.digest,
  });
  final int id, size;
  final String name;
  final String? digest;
  factory ReleaseAsset.fromJson(Map<String, dynamic> json) => ReleaseAsset(
    id: json['id'] as int,
    name: json['name'] as String,
    size: json['size'] as int,
    digest: json['digest'] as String?,
  );
  Uri uri(UpdateSource source) => Uri.https(
    'api.github.com',
    '/repos/${source.repository}/releases/assets/$id',
  );
}

class UpdateRelease {
  const UpdateRelease({
    required this.version,
    required this.installer,
    required this.sha256,
    required this.notes,
    required this.tag,
    required this.channel,
    required this.architecture,
  });
  final UpdateVersion version;
  final ReleaseAsset installer;
  final String sha256, notes, tag, channel, architecture;

  factory UpdateRelease.fromManifest(
    Map<String, dynamic> manifest, {
    required UpdateSource source,
    required String architecture,
    required String tag,
    required String notes,
    required List<ReleaseAsset> assets,
  }) {
    if (manifest['schema'] != 1 ||
        manifest['product'] != 'ecjtu-tools-pro' ||
        manifest['platform'] != 'windows' ||
        manifest['channel'] != source.channel ||
        manifest['architecture'] != architecture) {
      throw const UpdateFailure('更新包与当前版本不匹配');
    }
    final version = UpdateVersion.parse(
      manifest['version'] as String,
      manifest['buildNumber'] as int,
    );
    if (tag != 'windows-v${version.label}' &&
        (source.test ||
            (tag != 'windows-v${version.version}' &&
                tag != 'v${version.version}'))) {
      throw const UpdateFailure('更新版本信息不一致');
    }
    final name = manifest['asset'] as String;
    final hash = manifest['sha256'] as String;
    if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(hash) ||
        !RegExp(
          r'^ECJTU-Tools-Pro-[a-zA-Z0-9.+_-]+-Setup\.exe$',
        ).hasMatch(name)) {
      throw const UpdateFailure('更新包信息无效');
    }
    final matches = assets.where((asset) => asset.name == name).toList();
    if (matches.length != 1 ||
        matches.single.size <= 0 ||
        matches.single.size > 2 * 1024 * 1024 * 1024 ||
        matches.single.size != manifest['size']) {
      throw const UpdateFailure('更新包尚未发布完整');
    }
    final asset = matches.single;
    if (asset.digest != null && asset.digest != 'sha256:$hash') {
      throw const UpdateFailure('更新包校验信息不一致');
    }
    return UpdateRelease(
      version: version,
      installer: asset,
      sha256: hash,
      notes: notes,
      tag: tag,
      channel: source.channel,
      architecture: architecture,
    );
  }
}

String digestHex(SHA256Digest digest) {
  final bytes = Uint8List(digest.digestSize);
  digest.doFinal(bytes, 0);
  return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
}

String sha256Bytes(List<int> bytes) {
  final digest = SHA256Digest();
  final data = Uint8List.fromList(bytes);
  digest.update(data, 0, data.length);
  return digestHex(digest);
}
