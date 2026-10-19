// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:convert';
import 'dart:io';
import 'session_store.dart';

class StoredHttpCookie {
  const StoredHttpCookie({
    required this.name,
    required this.value,
    required this.domain,
    required this.hostOnly,
    required this.path,
    required this.secure,
    this.httpOnly = false,
    this.expires,
    this.sameSite,
  });

  final String name;
  final String value;
  final String domain;
  final bool hostOnly;
  final String path;
  final bool secure;
  final bool httpOnly;
  final DateTime? expires;
  final String? sameSite;
}

/// Persisted with each account partition, including across SSO redirects.
class HttpCookieJar {
  HttpCookieJar(String? encoded) {
    if (encoded == null) return;
    try {
      for (final entry in jsonDecode(encoded) as List) {
        _cookies.add(Map<String, dynamic>.from(entry as Map));
      }
    } catch (_) {
      _cookies.clear();
    }
  }

  static const storageKey = '_httpCookieJar';
  final _cookies = <Map<String, dynamic>>[];
  String encode() => jsonEncode(_cookies);
  Set<String> get scopedNames =>
      _cookies.map((cookie) => cookie['name'] as String).toSet();

  List<StoredHttpCookie> get records {
    _removeExpired();
    return _cookies
        .where(_isAlive)
        .map(
          (cookie) => StoredHttpCookie(
            name: cookie['name'] as String,
            value: cookie['value'] as String,
            domain: cookie['domain'] as String,
            hostOnly: cookie['hostOnly'] == true,
            path: cookie['path'] as String,
            secure: cookie['secure'] == true,
            httpOnly: cookie['httpOnly'] == true,
            sameSite: cookie['sameSite'] as String?,
            expires: cookie['expires'] is int
                ? DateTime.fromMillisecondsSinceEpoch(
                    cookie['expires'] as int,
                    isUtc: true,
                  )
                : null,
          ),
        )
        .toList(growable: false);
  }

  String header(Uri uri) {
    _removeExpired();
    final matching =
        _cookies.where((c) {
          if (!_isAlive(c)) return false;
          final domain = c['domain'] as String;
          final path = c['path'] as String;
          final requestPath = uri.path.isEmpty ? '/' : uri.path;
          return (uri.host == domain ||
                  c['hostOnly'] == false && uri.host.endsWith('.$domain')) &&
              (requestPath == path ||
                  requestPath.startsWith(path) &&
                      (path.endsWith('/') ||
                          requestPath
                              .substring(path.length)
                              .startsWith('/'))) &&
              (c['secure'] != true || uri.scheme == 'https');
        }).toList()..sort(
          (a, b) => (b['path'] as String).length.compareTo(
            (a['path'] as String).length,
          ),
        );
    return matching.map((c) => '${c['name']}=${c['value']}').join('; ');
  }

  void _removeExpired() {
    // Keep an empty tombstone per scope so legacy aliases cannot resurrect
    // deleted/expired cookies after serialization or browser hand-off.
    for (final cookie in _cookies) {
      if (!_isAlive(cookie)) cookie['value'] = '';
    }
  }

  bool _isAlive(Map<String, dynamic> cookie) =>
      cookie['expires'] == null ||
      (cookie['expires'] as int) > DateTime.now().millisecondsSinceEpoch;

  static String headerForSession(SessionSnapshot session, Uri uri) {
    final jar = HttpCookieJar(session.values[storageKey]);
    final scopedNames = jar.scopedNames;
    final scoped = jar.records.where((cookie) {
      final requestPath = uri.path.isEmpty ? '/' : uri.path;
      return (uri.host == cookie.domain ||
              !cookie.hostOnly && uri.host.endsWith('.${cookie.domain}')) &&
          (requestPath == cookie.path ||
              requestPath.startsWith(cookie.path) &&
                  (cookie.path.endsWith('/') ||
                      requestPath
                          .substring(cookie.path.length)
                          .startsWith('/'))) &&
          (!cookie.secure || uri.scheme == 'https');
    }).toList()..sort((a, b) => b.path.length.compareTo(a.path.length));

    // A flat legacy value must not resurrect a scoped cookie for another
    // host/path or one that just expired. Keep only genuinely unscoped names.
    final legacy = session.cookies.entries.where(
      (entry) => !scopedNames.contains(entry.key),
    );
    return [
      ...scoped.map((cookie) => '${cookie.name}=${cookie.value}'),
      ...legacy.map((entry) => '${entry.key}=${entry.value}'),
    ].join('; ');
  }

  void capture(Uri uri, String value) {
    for (final raw in value.split(RegExp(r',(?=\s*[^\s;,=]+\s*=)'))) {
      try {
        final cookie = Cookie.fromSetCookieValue(raw.trim());
        final domain = (cookie.domain ?? uri.host)
            .replaceFirst(RegExp(r'^\.'), '')
            .toLowerCase();
        if (uri.host != domain && !uri.host.endsWith('.$domain')) continue;
        final slash = uri.path.lastIndexOf('/');
        final defaultPath = slash <= 0 ? '/' : uri.path.substring(0, slash);
        final path = cookie.path?.startsWith('/') == true
            ? cookie.path!
            : defaultPath;
        _cookies.removeWhere(
          (c) =>
              c['name'] == cookie.name &&
              c['domain'] == domain &&
              c['path'] == path,
        );
        final expires = cookie.maxAge != null
            ? DateTime.now()
                  .add(Duration(seconds: cookie.maxAge!))
                  .millisecondsSinceEpoch
            : cookie.expires?.millisecondsSinceEpoch;
        _cookies.add({
          'name': cookie.name,
          'value':
              expires != null &&
                  expires <= DateTime.now().millisecondsSinceEpoch
              ? ''
              : cookie.value,
          'domain': domain,
          'hostOnly': cookie.domain == null,
          'path': path,
          'secure': cookie.secure,
          'httpOnly': cookie.httpOnly,
          'sameSite': RegExp(
            r'(?:^|;)\s*SameSite\s*=\s*(None|Lax|Strict)\s*(?:;|$)',
            caseSensitive: false,
          ).firstMatch(raw)?.group(1)?.toLowerCase(),
          if (expires != null) 'expires': expires,
        });
      } on FormatException {
        // A malformed cookie must not discard other cookies in the response.
      }
    }
  }
}
