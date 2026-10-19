// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:convert';

class MobileApplicationOpenWith {
  const MobileApplicationOpenWith({
    this.browser = 'builtin',
    this.width = '',
    this.height = '',
    this.extraFields = const <String, dynamic>{},
  });

  final String browser;
  final String width;
  final String height;
  final Map<String, dynamic> extraFields;

  factory MobileApplicationOpenWith.fromJson(Object? value) {
    final source = _mapFromJson(value);
    if (source.isEmpty && value is String && value.trim().isNotEmpty) {
      return MobileApplicationOpenWith(browser: value.trim().toLowerCase());
    }
    return MobileApplicationOpenWith(
      browser: _text(source['browser']).toLowerCase().isEmpty
          ? 'builtin'
          : _text(source['browser']).toLowerCase(),
      width: _text(source['width']),
      height: _text(source['height']),
      extraFields: _withoutKeys(source, const {'browser', 'width', 'height'}),
    );
  }

  Map<String, dynamic> toJson() => {
    ...extraFields,
    'browser': browser,
    'width': width,
    'height': height,
  };
}

class MobileApplicationLaunchDescriptor {
  const MobileApplicationLaunchDescriptor({
    required this.appId,
    required this.rawUrl,
    required this.url,
    required this.type,
    required this.openWith,
    required this.isSso,
    required this.redirectUrl,
    required this.webUrl,
    required this.androidPackageName,
    required this.androidPackageUrl,
    required this.iosPackageName,
    required this.iosPackageUrl,
    required this.requiresPortalSession,
    required this.customInfo,
    required this.extraFields,
  });

  final String appId;
  final String rawUrl;
  final Uri url;
  final String type;
  final MobileApplicationOpenWith openWith;
  final bool isSso;
  final String redirectUrl;
  final String webUrl;
  final String androidPackageName;
  final String androidPackageUrl;
  final String iosPackageName;
  final String iosPackageUrl;
  final bool requiresPortalSession;
  final Object customInfo;
  final Map<String, dynamic> extraFields;

  Map<String, dynamic> toJson() => {
    ...extraFields,
    'appId': appId,
    'url': rawUrl,
    'rawUrl': rawUrl,
    'type': type,
    'openWith': openWith.toJson(),
    'isSso': isSso ? 1 : 0,
    'redirectUrl': redirectUrl,
    'webUrl': webUrl,
    'androidPackageName': androidPackageName,
    'androidPackageUrl': androidPackageUrl,
    'iosPackageName': iosPackageName,
    'iosPackageUrl': iosPackageUrl,
    'requiresPortalSession': requiresPortalSession,
    'customInfo': customInfo,
  };
}

class MobileApplication {
  const MobileApplication({
    required this.id,
    required this.name,
    required this.originalName,
    required this.description,
    required this.category,
    required this.launch,
    required this.extraFields,
    this.source = '',
    this.sort = 0,
  });

  final String id;
  final String name;
  final String originalName;
  final String description;
  final String category;
  final MobileApplicationLaunchDescriptor launch;
  final Map<String, dynamic> extraFields;
  final String source;
  final int sort;

  Uri get url => launch.url;

  String get rawUrl => launch.rawUrl;

  String get type => launch.type;

  MobileApplicationOpenWith get openWith => launch.openWith;

  bool get isSso => launch.isSso;

  String get redirectUrl => launch.redirectUrl;

  String get webUrl => launch.webUrl;

  String get androidPackageName => launch.androidPackageName;

  String get androidPackageUrl => launch.androidPackageUrl;

  String get iosPackageName => launch.iosPackageName;

  String get iosPackageUrl => launch.iosPackageUrl;

  Object get customInfo => launch.customInfo;

  factory MobileApplication.fromJson(Map<String, dynamic> json) {
    final launchSource = _mapFromJson(json['launch']);
    final source = launchSource.isEmpty ? json : launchSource;
    final network = _mapFromJson(source['network_url']);
    final rawUrl = _firstText([
      source['rawUrl'],
      source['raw_url'],
      source['url'],
      network['app_url'],
      network['url'],
      source['app_url'],
      source['appUrl'],
      source['web_url'],
      source['app_redirect_url'],
    ]);
    final parsedUrl = Uri.tryParse(rawUrl);
    if (parsedUrl == null || !parsedUrl.hasScheme) {
      throw const FormatException('移动应用地址无效');
    }

    final appId = _firstText([
      source['appId'],
      source['app_id'],
      source['id'],
      json['app_id'],
      json['id'],
    ]);
    final originalName = _firstText([
      json['app_name'],
      json['originalName'],
      json['name'],
      source['app_name'],
    ]);
    if (appId.isEmpty || originalName.isEmpty) {
      throw const FormatException('移动应用信息不完整');
    }

    final type = _firstText([source['type'], source['app_type']]).toLowerCase();
    final launchFields = _withoutKeys(source, const {
      'appId',
      'app_id',
      'id',
      'url',
      'rawUrl',
      'raw_url',
      'type',
      'app_type',
      'openWith',
      'open_with',
      'isSso',
      'is_sso',
      'redirectUrl',
      'redirect_url',
      'redirect_uri',
      'webUrl',
      'web_url',
      'app_url',
      'appUrl',
      'androidPackageName',
      'android_pakage_name',
      'androidPackageUrl',
      'android_pakage_url',
      'iosPackageName',
      'ios_pakage_name',
      'iosPackageUrl',
      'ios_pakage_url',
      'requiresPortalSession',
      'requires_portal_session',
      'requiresPortal',
      'requires_portal',
      'portalSession',
      'portal_session',
      'needPortalSession',
      'need_portal_session',
      'customInfo',
      'custom_info',
      'network_url',
    });
    final launch = MobileApplicationLaunchDescriptor(
      appId: appId,
      rawUrl: rawUrl,
      url: parsedUrl,
      type: type.isEmpty ? 'websso' : type,
      openWith: MobileApplicationOpenWith.fromJson(
        _openWithValue(source['openWith'] ?? source['open_with']),
      ),
      isSso: _boolean(source['isSso'] ?? source['is_sso']),
      redirectUrl: _firstText([
        source['redirectUrl'],
        source['redirect_url'],
        source['redirect_uri'],
        network['app_url_out'],
        network['web_url_en_out'],
      ]),
      webUrl: _firstText([
        source['webUrl'],
        source['web_url'],
        network['web_url'],
        network['web_url_en'],
      ]),
      androidPackageName: _firstText([
        source['androidPackageName'],
        source['android_pakage_name'],
      ]),
      androidPackageUrl: _firstText([
        source['androidPackageUrl'],
        source['android_pakage_url'],
      ]),
      iosPackageName: _firstText([
        source['iosPackageName'],
        source['ios_pakage_name'],
      ]),
      iosPackageUrl: _firstText([
        source['iosPackageUrl'],
        source['ios_pakage_url'],
      ]),
      requiresPortalSession: _portalSessionRequired(source),
      customInfo: _customInfo(source['customInfo'] ?? source['custom_info']),
      extraFields: launchFields,
    );

    final storedFields = _mapFromJson(json['extraFields'] ?? json['rawFields']);
    final extraFields = storedFields.isEmpty ? _cloneMap(json) : storedFields;
    return MobileApplication(
      id: appId,
      name: _firstText([json['displayName'], json['name'], originalName]),
      originalName: originalName,
      description: _firstText([json['describe'], json['description']]),
      category: _category(json),
      launch: launch,
      extraFields: extraFields,
      source: _firstText([json['source'], source['source']]),
      sort: _number(json['sort']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'originalName': originalName,
    'description': description,
    'category': category,
    'launch': launch.toJson(),
    'source': source,
    'sort': sort,
    'extraFields': extraFields,
  };
}

Object? _openWithValue(Object? value) {
  if (value is! String || value.trim().isEmpty) return value;
  try {
    final decoded = jsonDecode(value);
    return decoded is Map ? decoded : value;
  } on FormatException {
    return value;
  }
}

Map<String, dynamic> _mapFromJson(Object? value) {
  if (value is! Map) return const <String, dynamic>{};
  return _cloneMap(value);
}

Map<String, dynamic> _cloneMap(Map source) {
  return Map<String, dynamic>.unmodifiable({
    for (final entry in source.entries)
      entry.key.toString(): _cloneJsonValue(entry.value),
  });
}

Object? _cloneJsonValue(Object? value) {
  if (value is Map) return _cloneMap(value);
  if (value is List) {
    return List<Object?>.unmodifiable(value.map(_cloneJsonValue));
  }
  if (value == null || value is String || value is num || value is bool) {
    return value;
  }
  return value.toString();
}

Map<String, dynamic> _withoutKeys(
  Map<String, dynamic> source,
  Set<String> keys,
) {
  return Map<String, dynamic>.unmodifiable({
    for (final entry in source.entries)
      if (!keys.contains(entry.key)) entry.key: entry.value,
  });
}

String _firstText(Iterable<Object?> values) {
  for (final value in values) {
    final text = _text(value);
    if (text.isNotEmpty) return text;
  }
  return '';
}

String _text(Object? value) => value?.toString().trim() ?? '';

int _number(Object? value) => int.tryParse(_text(value)) ?? 0;

bool _boolean(Object? value) {
  if (value is bool) return value;
  return const {'1', 'true', 'yes'}.contains(_text(value).toLowerCase());
}

bool _portalSessionRequired(Map<String, dynamic> source) {
  const keys = [
    'requiresPortalSession',
    'requires_portal_session',
    'requiresPortal',
    'requires_portal',
    'portalSession',
    'portal_session',
    'needPortalSession',
    'need_portal_session',
  ];
  for (final key in keys) {
    if (source.containsKey(key)) return _boolean(source[key]);
  }
  return true;
}

Object _customInfo(Object? value) {
  if (value is Map) return _cloneMap(value);
  if (value is List) {
    return List<Object?>.unmodifiable(value.map(_cloneJsonValue));
  }
  return const <Object>[];
}

String _category(Map<String, dynamic> json) {
  final source =
      json['app_category_name'] ??
      json['category_name'] ??
      json['categoryName'] ??
      json['app_category'] ??
      json['category'] ??
      '';
  final value = source is Map
      ? source['category_type'] ?? source['category_name'] ?? source['name']
      : source;
  final text = _text(value).toLowerCase();
  if (RegExp(r'教学|教务|课程|study|education').hasMatch(text)) {
    return 'study';
  }
  if (RegExp(r'办公|office').hasMatch(text)) return 'office';
  if (RegExp(r'科研|research').hasMatch(text)) return 'research';
  if (RegExp(r'生活|life').hasMatch(text)) return 'life';
  if (RegExp(r'校园服务|社交|social').hasMatch(text)) return 'social';
  if (RegExp(r'业务系统|business').hasMatch(text)) return 'business';
  return 'other';
}
