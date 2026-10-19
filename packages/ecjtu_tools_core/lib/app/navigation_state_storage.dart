// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class AppNavigationState {
  const AppNavigationState({
    this.root = 'calendar',
    this.academicPage = 'arrangement',
    this.arrangementSection = 'courses',
    this.surface = 'workbench',
    this.physicsCatalogOpen = false,
    this.physicsCalculatorId,
    this.smartWorkPage = 'module',
    this.enhancementPage = 'menu',
    this.noticesCalendarOpen = false,
  });

  final String root;
  final String academicPage;
  final String arrangementSection;
  final String surface;
  final bool physicsCatalogOpen;
  final String? physicsCalculatorId;
  final String smartWorkPage;
  final String enhancementPage;
  final bool noticesCalendarOpen;

  factory AppNavigationState.fromJson(Object? value) {
    if (value is! Map) return const AppNavigationState();
    final map = value.map((key, value) => MapEntry(key.toString(), value));
    final calculatorId = map['physicsCalculatorId']?.toString().trim();
    return AppNavigationState(
      root: _value(map['root'], 'calendar'),
      academicPage: _value(map['academicPage'], 'arrangement'),
      arrangementSection: _value(map['arrangementSection'], 'courses'),
      surface: _value(map['surface'], 'workbench'),
      physicsCatalogOpen: map['physicsCatalogOpen'] == true,
      physicsCalculatorId: calculatorId == null || calculatorId.isEmpty
          ? null
          : calculatorId,
      smartWorkPage: _value(map['smartWorkPage'], 'module'),
      enhancementPage: _value(map['enhancementPage'], 'menu'),
      noticesCalendarOpen: map['noticesCalendarOpen'] == true,
    );
  }

  Map<String, Object?> toJson() => {
    'version': 1,
    'root': root,
    'academicPage': academicPage,
    'arrangementSection': arrangementSection,
    'surface': surface,
    'physicsCatalogOpen': physicsCatalogOpen,
    'physicsCalculatorId': physicsCalculatorId,
    'smartWorkPage': smartWorkPage,
    'enhancementPage': enhancementPage,
    'noticesCalendarOpen': noticesCalendarOpen,
  };

  static String _value(Object? value, String fallback) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }
}

class NavigationStateStorage {
  static const _prefix = 'ecjtu.navigation.';

  Future<AppNavigationState?> read(String studentId) async {
    final target = studentId.trim();
    if (target.isEmpty) return null;
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_key(target));
    if (raw == null || raw.isEmpty) return null;
    try {
      return AppNavigationState.fromJson(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  Future<void> write(String studentId, AppNavigationState state) async {
    final target = studentId.trim();
    if (target.isEmpty) return;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_key(target), jsonEncode(state.toJson()));
  }

  Future<void> clear(String studentId) async {
    final target = studentId.trim();
    if (target.isEmpty) return;
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_key(target));
  }

  Future<void> merge(String primaryStudentId, String aliasStudentId) async {
    final primaryId = primaryStudentId.trim();
    final aliasId = aliasStudentId.trim();
    if (primaryId.isEmpty || aliasId.isEmpty || primaryId == aliasId) return;
    final primary = await read(primaryId);
    final alias = await read(aliasId);
    if (primary == null && alias != null) await write(primaryId, alias);
    await clear(aliasId);
  }

  Future<void> clearAll() async {
    final preferences = await SharedPreferences.getInstance();
    for (final key in preferences.getKeys().where(
      (key) => key.startsWith(_prefix),
    )) {
      await preferences.remove(key);
    }
  }

  String _key(String studentId) => '$_prefix$studentId';
}
