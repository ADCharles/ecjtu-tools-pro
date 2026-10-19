// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:convert';

class _AiLiteralPrivacyPlan {
  const _AiLiteralPrivacyPlan(
    this.replacements,
    this.contextual,
    this.literals,
  );
  final Map<String, String> replacements;
  final List<({RegExp pattern, String label, String replacement})> contextual;
  final RegExp? literals;
}

/// Authorization is a caller-owned snapshot for this request, not model data.
class AiPrivacyPolicy {
  AiPrivacyPolicy({
    this.enabled = true,
    this.userRequest = '',
    Map<String, String> privateFields = const {},
    Set<String> allowedGroups = const {},
  }) : privateFields = Map.unmodifiable(privateFields),
       allowedGroups = Set.unmodifiable(allowedGroups.map(_canonicalGroup));

  final bool enabled;
  final String userRequest;
  final Map<String, String> privateFields;
  final Set<String> allowedGroups;
  late final _literalPlan = _createLiteralPlan();
  late final _knownFields = _indexKnownFields();

  Map<String, List<({String value, String group})>> _indexKnownFields() {
    final result = <String, List<({String value, String group})>>{};
    for (final field in privateFields.entries) {
      final parts = field.key.split(':');
      final label = _normalize(parts.last);
      (result[label] ??= []).add((
        value: field.value,
        group: parts.length > 1
            ? _canonicalGroup(parts.first)
            : (label == 'name' ? 'name' : 'profile'),
      ));
    }
    return result;
  }

  AiPrivacyPolicy withPrivateFields(Map<String, String> fields) =>
      AiPrivacyPolicy(
        enabled: enabled,
        userRequest: userRequest,
        privateFields: {...privateFields, ...fields},
        allowedGroups: allowedGroups,
      );

  AiPrivacyPolicy withDirectoryData(Object? value) {
    if (!allowedGroups.contains('contacts') ||
        value is! Map ||
        value['source'] != 'contacts')
      return this;
    final fields = <String, String>{};
    for (final collection in ['contacts', 'organizations']) {
      for (final item
          in (value[collection] as List? ?? const []).whereType<Map>()) {
        for (final key
            in collection == 'contacts' ? ['name', 'organization'] : ['name']) {
          final text = item[key];
          if (text is String && text.trim().isNotEmpty) {
            fields['contacts:${fields.length}:$key'] = text;
          }
        }
      }
    }
    final directoryValues = fields.values.toList();
    for (final field in privateFields.entries) {
      final label = _normalize(field.key.split(':').last);
      if (_fieldGroup(field.key, value: field.value) == 'profile' &&
          const {
            '学院',
            '专业',
            '班级',
            '年级',
            'college',
            'department',
            'major',
            'classname',
            'class',
            'grade',
            'organization',
          }.contains(label) &&
          field.value.trim().isNotEmpty &&
          directoryValues.any((text) => text.contains(field.value))) {
        fields['contacts:${fields.length}:$label'] = field.value;
      }
    }
    return fields.isEmpty ? this : withPrivateFields(fields);
  }

  Object? filter(Object? value) => withDirectoryData(value)._filter(value);

  /// Null means no additional protected-data group needs confirmation.
  String? requiredGroup(String tool, Map<String, Object?> args) {
    if (!enabled) return null;
    final name = _normalize(tool);
    String? group;
    if (name == 'ecjtugetstatus' || name == 'getstatus') {
      final requested = _requestedProfileGroup();
      if (requested == 'name') group = 'name';
    } else if (name == 'ecjtugetdata' || name == 'getdata') {
      final source = _normalize(args['source']?.toString() ?? '');
      if (source == 'contacts') {
        return _allowsGroup('contacts') ? null : 'contacts';
      }
      if (source != 'smartwork') {
        return null;
      }
      final section = args['section']?.toString().trim() ?? '';
      if (section.isEmpty) return null;
      group = _canonicalGroup(section);
      if (_academicSections.contains(group)) return null;
      if (group == 'profile') group = _requestedProfileGroup();
    } else if (name == 'ecjtugetprofile' || name == 'getprofile') {
      group = _requestedProfileGroup();
    }
    return group != null && !_allowsGroup(group) ? group : null;
  }

  String sanitizeText(String text) => _sanitizeText(text);

  String _sanitizeText(String text, {String? source, String? section}) {
    final trimmed = text.trimLeft();
    if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
      try {
        final decoded = jsonDecode(text);
        if (decoded is Map || decoded is List) {
          return jsonEncode(_filter(decoded, source: source, section: section));
        }
      } on FormatException {
        // Partial JSON received while streaming still uses literal filtering.
      }
    }
    return _sanitizeLiteralText(text);
  }

  Object? _filter(
    Object? value, {
    String? source,
    String? section,
    bool sectionEntry = false,
  }) {
    if (value is String) {
      return _sanitizeText(value, source: source, section: section);
    }
    if (value is List) {
      return [
        for (final item in value)
          if (!_hiddenField(item, section))
            _filter(item, source: source, section: section),
      ];
    }
    if (value is! Map) return value;
    final ownSource = value['source'];
    final dataSource = ownSource is String ? _normalize(ownSource) : source;
    if (enabled && dataSource == 'contacts' && !_allowsGroup('contacts')) {
      return {
        'source': 'contacts',
        'available': false,
        'requiresPrivacyConfirmation': true,
        'authorizationGroup': 'contacts',
      };
    }
    final isSection = sectionEntry || _isSmartWorkSection(value);
    final sectionGroup = isSection
        ? _canonicalGroup(
            (value['id'] ?? value['section'] ?? value['title'] ?? 'unknown')
                .toString(),
          )
        : section;
    final canReadSection = !enabled || _allowsSection(sectionGroup);
    final result = <String, Object?>{};
    final fieldLabel = (value['label'] ?? value['name'] ?? value['key'])
        ?.toString();
    for (final entry in value.entries) {
      final key = entry.key.toString();
      if (_isCredential(key)) continue;
      if (enabled &&
          isSection &&
          !canReadSection &&
          !_directoryKeys.contains(key)) {
        continue;
      }
      if (key == 'value' && fieldLabel != null) {
        if (_isCredential(fieldLabel)) continue;
        if (enabled && !_allowsField(fieldLabel, entry.value, sectionGroup)) {
          continue;
        }
        if (_isIdentityNumber(fieldLabel)) {
          result[key] = _maskIdentity(entry.value);
          continue;
        }
      }
      if (enabled && !_allowsField(key, entry.value, sectionGroup)) continue;
      if (_isIdentityNumber(key)) {
        result[key] = _maskIdentity(entry.value);
      } else if (key == 'sections' && entry.value is List) {
        result[key] = [
          for (final item in entry.value as List)
            _filter(
              item,
              source: dataSource,
              sectionEntry: dataSource == 'smartwork',
            ),
        ];
      } else {
        result[_sanitizeLiteralText(key)] = _filter(
          entry.value,
          source: dataSource,
          section: sectionGroup,
        );
      }
    }
    return result;
  }

  bool _hiddenField(Object? item, String? section) {
    if (item is! Map || !item.containsKey('value')) return false;
    final label = (item['label'] ?? item['name'] ?? item['key'])?.toString();
    return label != null &&
        (_isCredential(label) ||
            (enabled && !_allowsField(label, item['value'], section)));
  }

  bool _allowsField(String key, Object? value, String? section) {
    if (section == null &&
        allowedGroups.contains('contacts') &&
        const {'name', 'organization'}.contains(_normalize(key)) &&
        (_knownFields[_normalize(key)] ??
                const <({String value, String group})>[])
            .any(
              (field) => field.group == 'contacts' && field.value == value,
            )) {
      return true;
    }
    final group = _fieldGroup(key, section: section, value: value);
    return group == null || _allowsGroup(group);
  }

  bool _allowsGroup(String group) {
    if (allowedGroups.contains(group)) return true;
    return allowedGroups.contains('profile') &&
        const {'name', 'studentId', 'contact'}.contains(group);
  }

  bool _allowsSection(String? section) {
    if (section == null) return false;
    if (_academicSections.contains(section)) return true;
    if (section == 'profile') {
      return const {
        'profile',
        'name',
        'studentId',
        'contact',
      }.any(allowedGroups.contains);
    }
    return _allowsGroup(section);
  }

  String? _fieldGroup(String key, {String? section, Object? value}) {
    final parts = key.split(':');
    final prefix = parts.length > 1 ? _canonicalGroup(parts.first) : null;
    final label = _normalize(parts.last);
    if (prefix != null &&
        prefix != 'profile' &&
        prefix != 'identity' &&
        !_academicSections.contains(prefix)) {
      return prefix;
    }
    if (section != null &&
        section != 'profile' &&
        !_academicSections.contains(section)) {
      if (!_structuralKeys.contains(label)) return section;
    }
    if (section == null &&
        const {'contacts', 'contactdirectory'}.contains(label) &&
        (value is Map || value is List))
      return null;
    if (const {
      'accountlabel',
      'studentname',
      'fullname',
      'realname',
      'xm',
      '姓名',
      '学生姓名',
      '曾用名',
      'formername',
    }.contains(label)) {
      return 'name';
    }
    if (const {
      'accountid',
      'studentid',
      'studentnumber',
      'studentno',
      'xh',
      '学号',
    }.contains(label)) {
      return 'studentId';
    }
    if (RegExp(
      r'family|household|homeaddress|家庭|户籍|邮政编码|postcode|^address$',
    ).hasMatch(label)) {
      return 'family';
    }
    if (RegExp(
      r'dormitory|roommate|宿舍|寝室|床位|^bed$|^roomname$',
    ).hasMatch(label)) {
      return 'dormitory';
    }
    if (RegExp(
          r'phone|mobilenumber|mobilephone|email|qq|contact|电话|手机|邮箱|邮件|联系方式|联系号码|联系人',
        ).hasMatch(label) ||
        (label == 'mobile' && value is! Map && value is! List)) {
      return 'contact';
    }
    if (_profileKeys.contains(label)) return 'profile';
    if (label == 'name' &&
        (section == 'profile' || prefix == 'profile' || prefix == 'identity')) {
      return 'name';
    }
    if (prefix == 'profile' || prefix == 'identity') return 'profile';
    for (final known
        in _knownFields[label] ?? const <({String value, String group})>[]) {
      // Generic action/model names are not the profile's literal name.
      if (label == 'name' && value != known.value) continue;
      return known.group;
    }
    if (section == 'profile' && !_structuralKeys.contains(label)) {
      return 'profile';
    }
    return null;
  }

  String _requestedProfileGroup() {
    final requested = <String>{};
    for (final clause in _requestClauses(userRequest)) {
      if (_negative.hasMatch(clause) ||
          _reported.hasMatch(clause) ||
          !_self.hasMatch(clause) ||
          (!_query.hasMatch(clause) && !_profileQuestion.hasMatch(clause))) {
        continue;
      }
      for (final entry in _profileRequests.entries) {
        if (entry.value.hasMatch(clause)) requested.add(entry.key);
      }
    }
    return requested.length == 1 ? requested.single : 'profile';
  }

  bool _wasProvided(String value) =>
      value.trim().isNotEmpty &&
      userRequest
          .split(RegExp(r'[，,。.!！?？;；\n]|但是|不过|然后'))
          .any(
            (clause) => !_negative.hasMatch(clause) && clause.contains(value),
          );

  _AiLiteralPrivacyPlan _createLiteralPlan() {
    final replacements = <String, String>{};
    final contextual = <({RegExp pattern, String label, String replacement})>[];
    // The same name can occur in both identity and cached dormitory records.
    // An authorized identity must not be redacted again by that duplicate.
    final authorizedValues = {
      for (final entry in privateFields.entries)
        if (!_isCredential(entry.key) &&
            !_isIdentityNumber(entry.key) &&
            _allowsGroup(
              _fieldGroup(entry.key, value: entry.value) ?? 'profile',
            ))
          entry.value,
    };
    for (final entry in privateFields.entries) {
      final value = entry.value;
      if (value.trim().isEmpty) continue;
      final credential = _isCredential(entry.key);
      final identityNumber = _isIdentityNumber(entry.key);
      final group = _fieldGroup(entry.key, value: value) ?? 'profile';
      if (!credential &&
          !identityNumber &&
          (!enabled ||
              _allowsGroup(group) ||
              authorizedValues.contains(value) ||
              _wasProvided(value))) {
        continue;
      }
      final replacement = credential
          ? '[凭据已隐藏]'
          : identityNumber
          ? _maskIdentity(value).toString()
          : '[已隐藏]';
      final labelGroup = _fieldGroup(entry.key.split(':').last, value: value);
      final identifying = const {
        'name',
        'studentId',
        'contact',
      }.contains(labelGroup);
      final numeric = RegExp(r'^[+-]?\d+(?:\.\d+)?$').hasMatch(value);
      // Common scalar attributes must not redact unrelated grades or prose.
      if (!credential &&
          !identityNumber &&
          (value.runes.length == 1 ||
              (!identifying && (numeric || value.runes.length <= 2)))) {
        final label = entry.key.split(':').last;
        final pattern = RegExp(
          '${RegExp.escape(label)}([：:=]\\s*)${RegExp.escape(value)}',
        );
        contextual.add((
          pattern: pattern,
          label: label,
          replacement: replacement,
        ));
        continue;
      }
      if (replacements[value] != '[凭据已隐藏]') replacements[value] = replacement;
    }
    final literals = replacements.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    return _AiLiteralPrivacyPlan(
      replacements,
      contextual,
      literals.isEmpty ? null : RegExp(literals.map(RegExp.escape).join('|')),
    );
  }

  String _sanitizeLiteralText(String text) {
    final plan = _literalPlan;
    for (final rule in plan.contextual) {
      text = text.replaceAllMapped(
        rule.pattern,
        (m) => '${rule.label}${m[1]}${rule.replacement}',
      );
    }
    if (plan.literals case final pattern?) {
      // One pass prevents a shorter value from modifying an earlier replacement.
      text = text.replaceAllMapped(pattern, (m) => plan.replacements[m[0]]!);
    }
    // The longer assignment expressions are unnecessary for ordinary prose.
    // Every header/assignment keyword is included in this cheaper hint scan.
    if (!_credentialHint.hasMatch(text)) return text;
    text = text.replaceAllMapped(_credentialHeader, (m) => '${m[1]}[凭据已隐藏]');
    return text.replaceAllMapped(
      _credentialAssignment,
      (m) => '${m[1]}[凭据已隐藏]',
    );
  }

  static Object? _maskIdentity(Object? value) {
    if (value == null) return null;
    if (value is List) return value.map(_maskIdentity).toList();
    final text = value.toString();
    final runes = text.runes.toList();
    if (runes.length <= 4) return '*' * runes.length;
    return '${String.fromCharCodes(runes.take(2))}'
        '${'*' * (runes.length - 4)}'
        '${String.fromCharCodes(runes.skip(runes.length - 2))}';
  }

  static bool _isIdentityNumber(String key) => RegExp(
    r'^(?:identitynumber|identityno|idnumber|idcard|idcardno|idcardnumber|nationalid|sfzh|身份证|身份证号|身份证号码|证件号码)$',
  ).hasMatch(_normalize(key.split(':').last));

  static bool _isCredential(String key) {
    final parts = key.split(':');
    if (parts.length > 1 &&
        const {
          'credential',
          'credentials',
          'secret',
          'secrets',
          'auth',
        }.contains(_normalize(parts.first))) {
      return true;
    }
    return RegExp(
      r'password|passwd|^pwd$|secret|apikey|accesskey|^(?:access|refresh|auth|session|bearer)?token$|cookie|authorization|credential|privatekey|sessionkey|sessionid|ticket|^sk$|^tgt$|密码|口令|密钥|令牌|凭据|认证头',
    ).hasMatch(_normalize(parts.last));
  }

  static bool _isSmartWorkSection(Map value) =>
      (value.containsKey('records') || value.containsKey('fields')) &&
      value['path'] is List &&
      (value['path'] as List).contains('智慧学工');

  static String _normalize(String key) =>
      key.toLowerCase().replaceAll(RegExp(r'[\s_.\-]'), '');

  static String _canonicalGroup(String group) => switch (_normalize(group)) {
    'name' || '姓名' => 'name',
    'studentid' || '学号' => 'studentId',
    'identity' || '身份' => 'identity',
    'profile' || '个人资料' || '个人信息' || '学籍信息' => 'profile',
    'contact' || '联系方式' || '电话' => 'contact',
    'family' || '家庭' || '家庭信息' => 'family',
    'dormitory' || '宿舍' || '宿舍信息' => 'dormitory',
    'changes' || 'enrollment' || '学籍异动' => 'changes',
    'sport' || '体测成绩' => 'sport',
    'scholarships' || '我的奖学金' => 'scholarships',
    'evaluation' || '综测信息' => 'evaluation',
    'honors' || '我的荣誉' => 'honors',
    'smartwork' => 'smart_work',
    _ => group.trim(),
  };

  static const _directoryKeys = {'id', 'title', 'path', 'available', 'total'};
  static const _academicSections = {'credits', 'workbooks', 'school_calendar'};
  static final _credentialHeader = RegExp(
    r'((?:\bauthorization|\bproxy-authorization|\bcookie|\bset-cookie)\s*[:=]\s*)[^\r\n]+',
    caseSensitive: false,
  );
  static final _credentialHint = RegExp(
    r'authoriz|cookie|key|password|passwd|pwd|token|secret|credential|密码|口令|密钥|令牌|凭据',
    caseSensitive: false,
  );
  static final _credentialAssignment = RegExp(
    r'''((?:\bapi[_-]?key|\bpassword|\bpasswd|\bpwd|\b(?:access[_-]?|refresh[_-]?|auth[_-]?|session[_-]?)?token|\bsecret|\bcredential|密码|口令|密钥|令牌|凭据)["']?\s*[:=：]\s*)(?:"[^"\r\n]*(?:"|$)|'[^'\r\n]*(?:'|$)|[^\s,;，；}"']+)''',
    caseSensitive: false,
  );
  static const _structuralKeys = {
    ..._directoryKeys,
    'label',
    'fields',
    'records',
    'value',
    'unit',
  };
  static const _profileKeys = {
    'sex',
    'gender',
    'nation',
    'nativeplace',
    'politicalstatus',
    'birthday',
    'birthdate',
    'identitynumber',
    'idcard',
    'sourceplace',
    'religiousbelief',
    'enrollmentstatus',
    'admissiontype',
    'educationlevel',
    'candidatenumber',
    'studyyears',
    'enrollmentnote',
    'graduationschool',
    'studentprofile',
    'profile',
    '性别',
    '民族',
    '籍贯',
    '政治面貌',
    '出生日期',
    '年龄',
    '身份状态',
    '入学类别',
    '培养层次',
    '考生号',
    '生源地',
    '学习年限',
    '学籍备注',
    '毕业中学',
    '宗教信仰',
    '身份证号',
    '身份证',
    '个人资料',
    '个人信息',
  };
  static final _negative = RegExp(
    r'不要|不用|无需|不准|禁止|别(?:读|查|看|取|显示)|不能|不允许|不想|拒绝|不(?:查询|读取|查看|显示)|\b(?:do\s+not|don.t|never|without|must\s+not)\b',
    caseSensitive: false,
  );
  static final _reported = RegExp(
    r'如果|假如|假设|例如|之前|上次|上轮|曾经|工具(?:说|要求|返回)|结果(?:说|要求)|\b(?:if|example|previously|tool\s+(?:says|said|result))\b',
    caseSensitive: false,
  );
  static final _self = RegExp(r'我的|本人|我自己|我叫什么|\bmy\b', caseSensitive: false);
  static final _query = RegExp(
    r'查询|查看|查一下|查查|查(?:我|本人)|读取|显示|告诉我|看看|列出|获取|核对|确认|是什么|是多少|叫什么|\b(?:show|read|look\s*up|find|tell|list|what|check)\b',
    caseSensitive: false,
  );
  static Iterable<String> _requestClauses(String request) => request
      .replaceAll(
        RegExp(r'```[\s\S]*?```|`[^`]*`|“[^”]*”|「[^」]*」|‘[^’]*’|"[^"]*"'),
        ' ',
      )
      .split(RegExp(r'[，,。.!！?？;；\n]|但是|不过|然后'));
  static final _profileQuestion = RegExp(
    r'^\s*(?:我的|本人(?:的)?)\s*(?:姓名|名字|学号|个人资料|个人信息|联系方式|手机号|邮箱)\s*$',
  );
  static final _profileRequests = {
    'name': RegExp(r'姓名|名字|叫什么|\bname\b', caseSensitive: false),
    'studentId': RegExp(
      r'学号|\bstudent\s*(?:id|number|no)\b',
      caseSensitive: false,
    ),
    'contact': RegExp(
      r'手机号|电话|邮箱|QQ|联系方式|\b(?:phone|email|contact)\b',
      caseSensitive: false,
    ),
    'profile': RegExp(r'个人资料|个人信息|学籍信息|\bprofile\b', caseSensitive: false),
  };
}
