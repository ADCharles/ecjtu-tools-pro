// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:pointycastle/export.dart';
import '../update/update_models.dart' show sha256Bytes;
import 'diary_models.dart';
import 'diary_storage.dart';

class DiaryBackupData {
  const DiaryBackupData(this.entries, this.assets, {this.renderScale = 1});
  final List<DiaryEntry> entries;
  final Map<String, Uint8List> assets;
  final double renderScale;
}

class DiaryBackup {
  static const maxBytes = 128 * 1024 * 1024;
  static const iterations = 210000;
  static Map<String, dynamic> _header(String salt, String nonce) => {
    'format': 'adcharles.diary.backup',
    'schema': 1,
    'encryption': {
      'cipher': 'AES-256-GCM',
      'kdf': 'PBKDF2-HMAC-SHA256',
      'iterations': iterations,
      'salt': salt,
      'nonce': nonce,
    },
  };
  static Uint8List _key(String password, Uint8List salt) =>
      (PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
            ..init(Pbkdf2Parameters(salt, iterations, 32)))
          .process(Uint8List.fromList(utf8.encode(password)));
  static Uint8List encrypt(DiaryBackupData data, String password) {
    if (password.trim().isEmpty || password.length > 1024) {
      throw const FormatException('请输入有效的备份密码');
    }
    final manifest = utf8.encode(
      jsonEncode({
        'format': 'adcharles.diary',
        'schema': 1,
        'renderer': {'font': 'kai', 'scale': data.renderScale},
        'entries': data.entries.map((entry) => entry.toJson()).toList(),
        'assets': data.assets.entries
            .map(
              (asset) => {
                'id': asset.key,
                'path': 'assets/${asset.key}',
                'mimeType': DiaryStorage.imageMime(asset.value),
                'size': asset.value.length,
                'sha256': sha256Bytes(asset.value),
              },
            )
            .toList(),
      }),
    );
    var size = manifest.length;
    final archive = Archive()
      ..addFile(ArchiveFile('manifest.json', manifest.length, manifest));
    for (final asset in data.assets.entries) {
      size += asset.value.length;
      if (size > maxBytes) throw const FormatException('日记备份超过 128 MB');
      archive.addFile(
        ArchiveFile('assets/${asset.key}', asset.value.length, asset.value),
      );
    }
    for (final file in archive) {
      file.compression = CompressionType.none;
    }
    final zip = Uint8List.fromList(ZipEncoder().encode(archive));
    if (zip.length + 16 > maxBytes)
      throw const FormatException('日记备份超过 128 MB');
    final random = Random.secure();
    Uint8List bytes(int count) =>
        Uint8List.fromList(List.generate(count, (_) => random.nextInt(256)));
    final salt = bytes(16), nonce = bytes(12);
    final header = _header(base64Encode(salt), base64Encode(nonce));
    final key = _key(password, salt);
    try {
      final cipher = GCMBlockCipher(AESEngine())
        ..init(
          true,
          AEADParameters(
            KeyParameter(key),
            128,
            nonce,
            Uint8List.fromList(utf8.encode(jsonEncode(header))),
          ),
        );
      return Uint8List.fromList(
        utf8.encode(
          jsonEncode({
            ...header,
            'ciphertext': base64Encode(cipher.process(zip)),
          }),
        ),
      );
    } finally {
      key.fillRange(0, key.length, 0);
    }
  }

  static DiaryBackupData decrypt(Uint8List bytes, String password) {
    if (bytes.length > maxBytes * 2 || password.length > 1024) {
      throw const FormatException('备份文件过大');
    }
    final value = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    final encryption = value['encryption'] as Map<String, dynamic>;
    if (value['format'] != 'adcharles.diary.backup' ||
        value['schema'] != 1 ||
        encryption['cipher'] != 'AES-256-GCM' ||
        encryption['kdf'] != 'PBKDF2-HMAC-SHA256' ||
        encryption['iterations'] != iterations) {
      throw const FormatException('不支持的日记备份格式');
    }
    final salt = base64Decode(encryption['salt'] as String);
    final nonce = base64Decode(encryption['nonce'] as String);
    final encrypted = base64Decode(value['ciphertext'] as String);
    if (salt.length != 16 ||
        nonce.length != 12 ||
        encrypted.length < 16 ||
        encrypted.length > maxBytes)
      throw const FormatException('备份数据无效');
    final header = _header(
      encryption['salt'] as String,
      encryption['nonce'] as String,
    );
    final key = _key(password, salt);
    Uint8List zip;
    try {
      final cipher = GCMBlockCipher(AESEngine())
        ..init(
          false,
          AEADParameters(
            KeyParameter(key),
            128,
            nonce,
            Uint8List.fromList(utf8.encode(jsonEncode(header))),
          ),
        );
      zip = cipher.process(encrypted);
    } on InvalidCipherTextException {
      throw const FormatException('密码不正确，或备份文件已损坏');
    } finally {
      key.fillRange(0, key.length, 0);
    }
    final directory = ZipDirectory()..read(InputMemoryStream(zip));
    if (directory.fileHeaders.length > 20001)
      throw const FormatException('备份文件数量过多');
    final paths = <String>{};
    var total = 0;
    for (final header in directory.fileHeaders) {
      total += header.uncompressedSize;
      final local = header.file;
      if (total > maxBytes ||
          header.uncompressedSize < 0 ||
          header.compressionMethod != 0 ||
          header.compressedSize != header.uncompressedSize ||
          (header.generalPurposeBitFlag & 1) != 0 ||
          ((header.externalFileAttributes >> 16) & 0xf000) == 0xa000 ||
          !paths.add(header.filename) ||
          local == null ||
          local.filename != header.filename ||
          local.compressionMethod != CompressionType.none ||
          local.uncompressedSize != header.uncompressedSize ||
          (header.filename != 'manifest.json' &&
              !RegExp(r'^assets/[a-f0-9]{64}$').hasMatch(header.filename))) {
        throw const FormatException('备份文件结构无效');
      }
    }
    final archive = ZipDecoder().decodeBytes(zip);
    if (archive.length > 20001) throw const FormatException('备份文件数量过多');
    var size = 0;
    final files = <String, Uint8List>{};
    for (final file in archive) {
      size += file.size;
      if (!file.isFile ||
          file.compression != CompressionType.none ||
          file.isSymbolicLink ||
          file.size < 0 ||
          size > maxBytes ||
          (file.name != 'manifest.json' &&
              !RegExp(r'^assets/[a-f0-9]{64}$').hasMatch(file.name)) ||
          files.containsKey(file.name)) {
        throw const FormatException('备份文件结构无效');
      }
      final content = Uint8List.fromList(file.content);
      if (content.length != file.size || getCrc32(content) != file.crc32)
        throw const FormatException('备份文件不完整');
      files[file.name] = content;
    }
    final manifestBytes = files.remove('manifest.json');
    if (manifestBytes == null) throw const FormatException('日记清单缺失');
    final manifest =
        jsonDecode(utf8.decode(manifestBytes)) as Map<String, dynamic>;
    if (manifest['format'] != 'adcharles.diary' || manifest['schema'] != 1) {
      throw const FormatException('日记数据版本无效');
    }
    final entries = <DiaryEntry>[];
    final dates = <String>{}, ids = <String>{};
    for (final value in manifest['entries'] as List) {
      final entry = DiaryEntry.fromJson(value as Map<String, dynamic>);
      if (!dates.add(entry.date) || !ids.add(entry.id))
        throw const FormatException('日记重复');
      entries.add(entry);
    }
    final assets = <String, Uint8List>{};
    for (final value in manifest['assets'] as List) {
      final item = value as Map<String, dynamic>;
      final id = item['id'] as String;
      final content = files.remove('assets/$id');
      if (content == null ||
          assets.containsKey(id) ||
          content.length > 20 * 1024 * 1024 ||
          item['path'] != 'assets/$id' ||
          item['size'] != content.length ||
          item['sha256'] != id ||
          sha256Bytes(content) != id ||
          DiaryStorage.imageMime(content) != item['mimeType']) {
        throw const FormatException('备份图片校验失败');
      }
      assets[id] = content;
    }
    if (files.isNotEmpty ||
        entries.any(
          (entry) => entry.assetIds.any((id) => !assets.containsKey(id)),
        )) {
      throw const FormatException('日记图片缺失');
    }
    final scale = ((manifest['renderer'] as Map?)?['scale'] as num? ?? 1)
        .toDouble();
    if (!scale.isFinite || scale < .75 || scale > 2)
      throw const FormatException('文字比例无效');
    return DiaryBackupData(entries, assets, renderScale: scale);
  }

  static Future<Uint8List> export(
    DiaryStorage storage,
    String account,
    String password,
  ) async {
    final entries = (await storage.readAll(account)).values.toList();
    final assets = <String, Uint8List>{};
    for (final id in entries.expand((entry) => entry.assetIds).toSet()) {
      final file = await storage.assetFile(account, id);
      final bytes = await file.readAsBytes();
      if (sha256Bytes(bytes) != id) throw const FormatException('日记图片损坏');
      assets[id] = bytes;
    }
    final data = DiaryBackupData(
      entries,
      assets,
      renderScale: await storage.readRenderScale(account),
    );
    return Isolate.run(() => encrypt(data, password));
  }

  static Future<DiaryBackupData> open(Uint8List bytes, String password) =>
      Isolate.run(() => decrypt(bytes, password));
  static Future<void> restore(
    DiaryStorage storage,
    String account,
    DiaryBackupData data, {
    bool replaceExisting = false,
  }) async {
    for (final image in data.assets.entries) {
      final id = await storage.addImage(account, image.value);
      if (id != image.key) throw const FormatException('备份图片标识无效');
    }
    await storage.mergeEntries(
      account,
      data.entries,
      replaceExisting: replaceExisting,
    );
    await storage.setRenderScale(account, data.renderScale);
  }
}
