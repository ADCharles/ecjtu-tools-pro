// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import 'school_public_trust_anchors.dart';

abstract final class SchoolTlsContext {
  static final SecurityContext? _platformContext = Platform.isWindows
      ? createWindowsContext()
      : null;

  static SecurityContext? get platformContext => _platformContext;

  static SecurityContext createWindowsContext({
    Iterable<List<int>> Function()? readRoots,
    Iterable<List<int>> Function()? readDisallowed,
    Iterable<List<int>>? publicRoots,
    bool withSystemRoots = true,
  }) {
    final context = SecurityContext(withTrustedRoots: withSystemRoots);
    final loadedRoots = <List<int>>[];
    try {
      loadedRoots.addAll((readRoots ?? readWindowsTrustedRoots)());
    } catch (_) {
      // Native store access can be unavailable; retain the SDK context.
    }
    Set<String>? disallowed;
    try {
      disallowed = (readDisallowed ?? readWindowsDisallowedCertificates)()
          .map(_certificateKey)
          .toSet();
    } catch (_) {
      // Do not add supplemental anchors if the Windows denial policy is unknown.
    }
    if (disallowed != null) {
      loadedRoots.addAll(
        (publicRoots ?? SchoolPublicTrustAnchors.certificates.map(utf8.encode))
            .where((cert) => !disallowed!.contains(_certificateKey(cert))),
      );
    }
    final seen = <String>{};
    for (final certificate in loadedRoots) {
      final key = _certificateKey(certificate);
      if (!seen.add(key) || (disallowed?.contains(key) ?? false)) continue;
      try {
        final bytes = certificate.isNotEmpty && certificate.first == 0x2d
            ? certificate
            : utf8.encode(
                '-----BEGIN CERTIFICATE-----\n'
                '${base64Encode(certificate).replaceAllMapped(RegExp(r'.{1,64}'), (match) => '${match[0]}\n')}'
                '-----END CERTIFICATE-----\n',
              );
        context.setTrustedCertificatesBytes(bytes);
      } on TlsException {
        // A malformed store entry must not prevent loading the other roots.
      }
    }
    return context;
  }

  static String _certificateKey(List<int> bytes) {
    if (bytes.isNotEmpty && bytes.first == 0x2d) {
      final pem = utf8.decode(bytes, allowMalformed: true);
      final body = RegExp(
        r'-----BEGIN CERTIFICATE-----\s*([A-Za-z0-9+/=\s]+)-----END CERTIFICATE-----',
      ).firstMatch(pem)?.group(1);
      if (body != null) return body.replaceAll(RegExp(r'\s'), '');
    }
    return base64Encode(bytes);
  }

  static List<Uint8List> readWindowsDisallowedCertificates() {
    if (!Platform.isWindows) return const [];
    final stores = _WindowsCertificateStores();
    return [
      ...stores.read('Disallowed'),
      ...stores.read('Disallowed', localMachine: true),
    ];
  }

  static List<Uint8List> readWindowsTrustedRoots() {
    if (!Platform.isWindows) return const [];
    final stores = _WindowsCertificateStores();
    final disallowed = readWindowsDisallowedCertificates()
        .map(base64Encode)
        .toSet();
    final seen = <String>{};
    return [
      for (final certificate in stores.read('ROOT'))
        if (!disallowed.contains(base64Encode(certificate)) &&
            seen.add(base64Encode(certificate)))
          certificate,
    ];
  }
}

final class _WindowsCertificateStores {
  _WindowsCertificateStores() {
    final crypt32 = DynamicLibrary.open('crypt32.dll');
    _open = crypt32
        .lookupFunction<
          Pointer<Void> Function(
            Pointer<Void>,
            Uint32,
            Pointer<Void>,
            Uint32,
            Pointer<Void>,
          ),
          Pointer<Void> Function(
            Pointer<Void>,
            int,
            Pointer<Void>,
            int,
            Pointer<Void>,
          )
        >('CertOpenStore');
    _next = crypt32
        .lookupFunction<
          Pointer<_CertificateContext> Function(
            Pointer<Void>,
            Pointer<_CertificateContext>,
          ),
          Pointer<_CertificateContext> Function(
            Pointer<Void>,
            Pointer<_CertificateContext>,
          )
        >('CertEnumCertificatesInStore');
    _free = crypt32
        .lookupFunction<
          Int32 Function(Pointer<_CertificateContext>),
          int Function(Pointer<_CertificateContext>)
        >('CertFreeCertificateContext');
    _close = crypt32
        .lookupFunction<
          Int32 Function(Pointer<Void>, Uint32),
          int Function(Pointer<Void>, int)
        >('CertCloseStore');
  }

  late final Pointer<Void> Function(
    Pointer<Void>,
    int,
    Pointer<Void>,
    int,
    Pointer<Void>,
  )
  _open;
  late final Pointer<_CertificateContext> Function(
    Pointer<Void>,
    Pointer<_CertificateContext>,
  )
  _next;
  late final int Function(Pointer<_CertificateContext>) _free;
  late final int Function(Pointer<Void>, int) _close;

  List<Uint8List> read(String name, {bool localMachine = false}) {
    final storeName = name.toNativeUtf16();
    // The current-user system store includes inherited local-machine roots.
    final readOnlyFlags =
        (localMachine ? 0x00020000 : 0x00010000) | 0x00004000 | 0x00008000;
    final store = _open(
      Pointer.fromAddress(10),
      0,
      nullptr,
      readOnlyFlags,
      storeName.cast(),
    );
    calloc.free(storeName);
    if (store == nullptr) return const [];
    var certificate = Pointer<_CertificateContext>.fromAddress(0);
    final result = <Uint8List>[];
    var totalBytes = 0;
    try {
      while (result.length < 4096) {
        // CertEnumCertificatesInStore releases the previous context itself.
        certificate = _next(store, certificate);
        if (certificate == nullptr) break;
        final length = certificate.ref.length;
        if (length <= 0 ||
            length > 256 * 1024 ||
            certificate.ref.bytes == nullptr) {
          continue;
        }
        totalBytes += length;
        if (totalBytes > 32 * 1024 * 1024) break;
        result.add(
          Uint8List.fromList(certificate.ref.bytes.asTypedList(length)),
        );
      }
      return result;
    } finally {
      if (certificate != nullptr) _free(certificate);
      _close(store, 0);
    }
  }
}

final class _CertificateContext extends Struct {
  @Uint32()
  external int encoding;
  external Pointer<Uint8> bytes;
  @Uint32()
  external int length;
  external Pointer<Void> information;
  external Pointer<Void> store;
}
