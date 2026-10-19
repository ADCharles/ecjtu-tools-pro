// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:convert';
import '../../app/app_edition.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'settings_models.dart';

class SettingsStorage {
  Future<void> resetMultiAccount() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_experimentalMultiAccountKey, false);
  }

  static const _messagesIntroSeenKey = 'ecjtu.settings.messagesIntroSeen';
  static const _messagesEnabledKey = 'ecjtu.settings.messagesEnabled';
  static const _hideMessagesEntryKey = 'ecjtu.settings.hideMessagesEntry';
  static const _autoConnectMessagesKey = 'ecjtu.settings.autoConnectMessages';
  static const _mobileDeviceRecoveryKey =
      'ecjtu.settings.mobile_device_recovery';

  static const _showAllScheduleViewsKey =
      'ecjtu.settings.show_all_schedule_views';
  static const _themeModeKey = 'ecjtu.settings.theme_mode';
  static const _desktopColorStyleKey = 'ecjtu.settings.desktop_color_style';
  static const _fontFamilyKey = 'ecjtu.settings.font_family';
  static const _fullPageFontScaleKey = 'ecjtu.settings.font_scale.full_page';
  static const _popupFontScaleKey = 'ecjtu.settings.font_scale.popup';
  static const _calendarSourceKey = 'ecjtu.settings.calendar_source';
  static const _calendarSourceExplicitKey =
      'ecjtu.settings.calendar_source_explicit';
  static const _calendarSourceMigratedKey =
      'ecjtu.settings.calendar_source_migrated';
  static const _showScheduleHoursKey = 'ecjtu.settings.schedule_display.hours';
  static const _showScheduleCreditKey =
      'ecjtu.settings.schedule_display.credit';
  static const _showScheduleSmallClassKey =
      'ecjtu.settings.schedule_display.small_class';
  static const _autoRefreshKey = 'ecjtu.settings.auto_refresh';
  static const _lazyDataSettingsKey = 'ecjtu.settings.lazy_data_v1';
  static const _showDataSyncControlsKey =
      'ecjtu.settings.show_data_sync_controls';
  static const _showMobileHeaderAccountKey =
      'ecjtu.settings.show_mobile_header_account';
  static const _showDesktopHeaderAccountKey =
      'ecjtu.settings.show_desktop_header_account';
  static const _showBackToTopKey = 'ecjtu.settings.show_back_to_top';
  static const _autoReloginKey = 'ecjtu.settings.auto_relogin';
  static const _offlineModeAutoRefreshMigratedKey =
      'ecjtu.settings.offline_mode_auto_refresh_migrated';
  static const _autoSmartWorkRefreshKey =
      'ecjtu.settings.auto_smart_work_refresh';
  static const _calendarCacheMinutesKey =
      'ecjtu.settings.cache.calendar_minutes';
  static const _calendarCacheDaysKey = 'ecjtu.settings.cache.calendar_days';
  static const _smartWorkCacheMinutesKey =
      'ecjtu.settings.cache.smart_work_minutes';
  static const _academicCacheMinutesKey =
      'ecjtu.settings.cache.academic_minutes';
  static const _academicFeatureCacheMinutesKey =
      'ecjtu.settings.cache.academic_features_minutes';
  static const _academicFeatureCachePersistentKey =
      'ecjtu.settings.cache.academic_features_persistent';
  static const _academicCachePersistentKey =
      'ecjtu.settings.cache.academic_persistent';
  static const _mobileAppsCacheMinutesKey =
      'ecjtu.settings.cache.mobile_apps_minutes';
  static const _calendarCachePersistentKey =
      'ecjtu.settings.cache.calendar_persistent';
  static const _smartWorkCachePersistentKey =
      'ecjtu.settings.cache.smart_work_persistent';
  static const _mobileAppsCachePersistentKey =
      'ecjtu.settings.cache.mobile_apps_persistent';
  static const _showCalendarCacheViewerKey =
      'ecjtu.settings.show_calendar_cache_viewer';
  static const _showNoticePreviewKey = 'ecjtu.settings.show_notice_preview';
  static const _noticePageModeKey = 'ecjtu.settings.notice_page_mode';
  static const _offlineModeKey = 'ecjtu.settings.offline_mode';
  static const _experimentalMultiAccountKey =
      'ecjtu.settings.experimental.multi_account';
  static const _experimentalDemoModeKey =
      'ecjtu.settings.experimental.demo_mode';
  static const _networkRouteModeKey =
      'ecjtu.settings.experimental.network_route_mode';
  static const _httpProxyKey = 'ecjtu.settings.experimental.http_proxy';
  static const _dataControlsUnlockedKey =
      'ecjtu.settings.developer.data_controls';
  static const _fullDeveloperModeKey = 'ecjtu.settings.developer.full_mode';
  static const _customCalendarModeKey = 'ecjtu.settings.custom_calendar.mode';
  static const _customCalendarEnabledKey =
      'ecjtu.settings.custom_calendar.enabled';
  static const _customCalendarUrlKey = 'ecjtu.settings.custom_calendar.url';
  static const _customCalendarFormatKey =
      'ecjtu.settings.custom_calendar.source';
  static const _manualCalendarFallbackKey =
      'ecjtu.settings.manual_calendar_fallback';
  static const _localExamFallbackKey = 'ecjtu.settings.local_exam_fallback';
  static const _manualSemesterKey = 'ecjtu.settings.manual_semester';
  static const _manualWeekKey = 'ecjtu.settings.manual_week';
  static const _manualWeekDayKey = 'ecjtu.settings.manual_week_day';
  static const _selectedScheduleTermKey =
      'ecjtu.settings.selected_schedule_term';
  static const _selectedScoreTermKey = 'ecjtu.settings.selected_score_term';

  static const _accountPrefix = 'ecjtu.settings.account.';

  static const _legacyKeys = <String>[
    _themeModeKey,
    _desktopColorStyleKey,
    _fontFamilyKey,
    _fullPageFontScaleKey,
    _popupFontScaleKey,
    _calendarSourceKey,
    _calendarSourceExplicitKey,
    _calendarSourceMigratedKey,
    _showScheduleHoursKey,
    _showScheduleCreditKey,
    _showScheduleSmallClassKey,
    _mobileAppsCacheMinutesKey,
    _academicCacheMinutesKey,
    _academicFeatureCacheMinutesKey,
    _academicFeatureCachePersistentKey,
    _academicCachePersistentKey,
    _calendarCachePersistentKey,
    _smartWorkCachePersistentKey,
    _mobileAppsCachePersistentKey,
    _showAllScheduleViewsKey,
    _autoRefreshKey,
    _lazyDataSettingsKey,
    _showDataSyncControlsKey,
    _showBackToTopKey,
    _showMobileHeaderAccountKey,
    _showDesktopHeaderAccountKey,
    _autoReloginKey,
    _mobileDeviceRecoveryKey,
    _offlineModeAutoRefreshMigratedKey,
    _autoSmartWorkRefreshKey,
    _calendarCacheMinutesKey,
    _calendarCacheDaysKey,
    _smartWorkCacheMinutesKey,
    _showCalendarCacheViewerKey,
    _showNoticePreviewKey,
    _noticePageModeKey,
    _offlineModeKey,
    _customCalendarModeKey,
    _customCalendarEnabledKey,
    _customCalendarUrlKey,
    _customCalendarFormatKey,
    _manualCalendarFallbackKey,
    _localExamFallbackKey,
    _manualSemesterKey,
    _manualWeekKey,
    _manualWeekDayKey,
    _selectedScheduleTermKey,
    _selectedScoreTermKey,
  ];

  Future<AppSettings> read([String? studentId]) async {
    final preferences = await SharedPreferences.getInstance();
    const migratedKey = 'ecjtu.settings.proxy_default_system_v1';
    if (preferences.getBool(migratedKey) != true) {
      if (preferences.getString(_networkRouteModeKey) == 'direct') {
        await preferences.setString(_networkRouteModeKey, 'system');
      }
      await preferences.setBool(migratedKey, true);
    }
    final account = _normalizeAccount(studentId);
    if (account == null) {
      var hasSignedInAccount = false;
      try {
        final data = jsonDecode(
          preferences.getString('ecjtu.auth.accounts') ?? '{}',
        );
        final signedOut =
            preferences.getStringList('ecjtu.auth.signed_out') ??
            const <String>[];
        if (data is Map && data['accounts'] is List) {
          hasSignedInAccount = (data['accounts'] as List).any(
            (item) =>
                item is Map &&
                !signedOut.contains(item['studentId']?.toString()),
          );
        }
      } catch (_) {}
      if (!hasSignedInAccount)
        await preferences.setBool(_experimentalMultiAccountKey, false);
    }
    Map<String, Object?> valuesFor(String? target) {
      final values = _readValues(preferences, account: target);
      values[_networkRouteModeKey] = preferences.getString(
        _networkRouteModeKey,
      );
      values[_httpProxyKey] = preferences.getString(_httpProxyKey);
      values[_dataControlsUnlockedKey] = preferences.getBool(
        _dataControlsUnlockedKey,
      );
      values[_fullDeveloperModeKey] = preferences.getBool(
        _fullDeveloperModeKey,
      );
      values[_experimentalMultiAccountKey] =
          preferences.getBool(_experimentalMultiAccountKey) ??
          (target == null
              ? null
              : preferences.getBool(
                  _scopedKey(_experimentalMultiAccountKey, target),
                ));
      values[_experimentalDemoModeKey] =
          preferences.getBool(_experimentalDemoModeKey) ??
          (target == null
              ? null
              : preferences.getBool(
                  _scopedKey(_experimentalDemoModeKey, target),
                ));
      values[_messagesIntroSeenKey] = preferences.getBool(
        _messagesIntroSeenKey,
      );
      values[_messagesEnabledKey] = preferences.getBool(_messagesEnabledKey);
      values[_hideMessagesEntryKey] = preferences.getBool(
        _hideMessagesEntryKey,
      );
      values[_autoConnectMessagesKey] = preferences.getBool(
        _autoConnectMessagesKey,
      );
      return values;
    }

    if (account != null && !_hasAccountSettings(preferences, account)) {
      if (_hasLegacySettings(preferences)) {
        final legacy = valuesFor(null);
        final migrated = _settingsFromValues(legacy);
        await write(migrated, account);
        await _removeLegacySettings(preferences);
        return migrated;
      }
    }
    return _settingsFromValues(valuesFor(account));
  }

  Future<void> write(AppSettings settings, [String? studentId]) async {
    final preferences = await SharedPreferences.getInstance();
    Future<void> setString(String key, String value) async {
      if (preferences.getString(key) != value)
        await preferences.setString(key, value);
    }

    Future<void> setInt(String key, int value) async {
      if (preferences.getInt(key) != value)
        await preferences.setInt(key, value);
    }

    Future<void> setBool(String key, bool value) async {
      if (preferences.getBool(key) != value)
        await preferences.setBool(key, value);
    }

    await setBool(_messagesIntroSeenKey, settings.messagesIntroSeen);
    await setBool(_messagesEnabledKey, settings.messagesEnabled);
    await setBool(_hideMessagesEntryKey, settings.hideMessagesEntry);
    await setBool(_autoConnectMessagesKey, settings.autoConnectMessages);
    final account = _normalizeAccount(studentId);
    final key = (String base) => _scopedKey(base, account);
    await setBool(key(_mobileDeviceRecoveryKey), settings.mobileDeviceRecovery);
    await setString(key(_themeModeKey), settings.themeMode.storageValue);
    await setString(
      key(_desktopColorStyleKey),
      settings.desktopColorStyle.storageValue,
    );
    await setString(key(_fontFamilyKey), settings.fontFamily.storageValue);
    await setInt(key(_fullPageFontScaleKey), settings.fullPageFontScale);
    await setInt(key(_popupFontScaleKey), settings.popupFontScale);
    await setString(
      key(_calendarSourceKey),
      settings.calendarSource.storageValue,
    );
    await setBool(
      key(_calendarSourceExplicitKey),
      settings.calendarSourceExplicit,
    );
    await setBool(
      key(_calendarSourceMigratedKey),
      settings.calendarSourceMigrated,
    );
    await setBool(key(_showScheduleHoursKey), settings.showScheduleHours);
    await setBool(key(_showScheduleCreditKey), settings.showScheduleCredit);
    await setBool(
      key(_showScheduleSmallClassKey),
      settings.showScheduleSmallClass,
    );
    await setBool(key(_showAllScheduleViewsKey), settings.showAllScheduleViews);
    await setBool(key(_autoRefreshKey), settings.autoRefresh);
    await setBool(key(_lazyDataSettingsKey), true);
    await setBool(key(_showDataSyncControlsKey), settings.showDataSyncControls);
    await setBool(key(_showBackToTopKey), settings.showBackToTop);
    await setBool(
      key(_showMobileHeaderAccountKey),
      settings.showMobileHeaderAccount,
    );
    await setBool(
      key(_showDesktopHeaderAccountKey),
      settings.showDesktopHeaderAccount,
    );
    await setInt(
      key(_mobileAppsCacheMinutesKey),
      settings.mobileAppsCacheMinutes,
    );
    await setBool(
      key(_calendarCachePersistentKey),
      settings.calendarCachePersistent,
    );
    await setBool(
      key(_smartWorkCachePersistentKey),
      settings.smartWorkCachePersistent,
    );
    await setBool(
      key(_mobileAppsCachePersistentKey),
      settings.mobileAppsCachePersistent,
    );
    await setBool(key(_autoReloginKey), settings.autoRelogin);
    await setBool(
      key(_offlineModeAutoRefreshMigratedKey),
      settings.offlineModeAutoRefreshMigrated,
    );
    await setBool(key(_autoSmartWorkRefreshKey), settings.autoSmartWorkRefresh);
    await setInt(key(_academicCacheMinutesKey), settings.academicCacheMinutes);
    await setString(
      key(_academicFeatureCacheMinutesKey),
      jsonEncode(settings.academicFeatureCacheMinutes),
    );
    await setString(
      key(_academicFeatureCachePersistentKey),
      jsonEncode(settings.academicFeatureCachePersistent),
    );
    await setBool(
      key(_academicCachePersistentKey),
      settings.academicCachePersistent,
    );
    await setInt(key(_calendarCacheMinutesKey), settings.calendarCacheMinutes);
    await setInt(key(_calendarCacheDaysKey), settings.calendarCacheDays);
    await setInt(
      key(_smartWorkCacheMinutesKey),
      settings.smartWorkCacheMinutes,
    );
    await setBool(
      key(_showCalendarCacheViewerKey),
      settings.showCalendarCacheViewer,
    );
    await setBool(key(_showNoticePreviewKey), settings.showNoticePreview);
    await setString(
      key(_noticePageModeKey),
      settings.noticePageMode.storageValue,
    );
    await setBool(key(_offlineModeKey), settings.offlineMode);
    await setBool(
      _experimentalMultiAccountKey,
      settings.experimentalMultiAccount,
    );
    await setBool(_experimentalDemoModeKey, settings.experimentalDemoMode);
    await setString(
      _networkRouteModeKey,
      settings.networkRouteMode.storageValue,
    );
    await setString(_httpProxyKey, settings.httpProxy.trim());
    await setBool(
      _dataControlsUnlockedKey,
      settings.dataControlsUnlocked ||
          settings.fullDeveloperMode ||
          preferences.getBool(_dataControlsUnlockedKey) == true,
    );
    await setBool(
      _fullDeveloperModeKey,
      settings.fullDeveloperMode ||
          preferences.getBool(_fullDeveloperModeKey) == true,
    );
    await setString(
      key(_customCalendarModeKey),
      settings.customCalendarMode.name,
    );
    await setBool(
      key(_customCalendarEnabledKey),
      settings.customCalendarEnabled,
    );
    await setString(key(_customCalendarUrlKey), settings.customCalendarUrl);
    await setString(
      key(_customCalendarFormatKey),
      settings.customCalendarFormat.name,
    );
    await setBool(
      key(_manualCalendarFallbackKey),
      settings.manualCalendarFallback,
    );
    await setBool(key(_localExamFallbackKey), settings.localExamFallback);
    await setString(key(_manualSemesterKey), settings.manualSemester);
    await setInt(key(_manualWeekKey), settings.manualWeek);
    await setInt(key(_manualWeekDayKey), settings.manualWeekDay);
    await setString(
      key(_selectedScheduleTermKey),
      settings.selectedScheduleTerm,
    );
    await setString(key(_selectedScoreTermKey), settings.selectedScoreTerm);
  }

  Future<void> merge(String primaryStudentId, String aliasStudentId) async {
    final primary = _normalizeAccount(primaryStudentId);
    final alias = _normalizeAccount(aliasStudentId);
    if (primary == null || alias == null || primary == alias) return;
    final preferences = await SharedPreferences.getInstance();
    if (!_hasAccountSettings(preferences, primary) &&
        _hasAccountSettings(preferences, alias)) {
      final aliasSettings = _settingsFromValues(
        _readValues(preferences, account: alias),
      );
      await write(aliasSettings, primary);
    }
    await _removeAccountSettings(preferences, alias);
  }

  Future<void> clear(String studentId) async {
    final account = _normalizeAccount(studentId);
    if (account == null) return;
    final preferences = await SharedPreferences.getInstance();
    await _removeAccountSettings(preferences, account);
  }

  Future<void> clearAll() async {
    final preferences = await SharedPreferences.getInstance();
    for (final key in preferences.getKeys().where(
      (key) => key.startsWith(_accountPrefix),
    )) {
      await preferences.remove(key);
    }
    await _removeLegacySettings(preferences);
  }

  static String accountKey(String legacyKey, String studentId) {
    final target = studentId.trim();
    if (target.isEmpty) return legacyKey;
    return '$_accountPrefix${Uri.encodeComponent(target)}.$legacyKey';
  }

  AppSettings _settingsFromValues(Map<String, Object?> values) {
    return AppSettings(
      messagesEnabled: values[_messagesEnabledKey] as bool? ?? false,
      messagesIntroSeen: values[_messagesIntroSeenKey] as bool? ?? false,
      hideMessagesEntry: (values[_messagesEnabledKey] as bool? ?? false)
          ? false
          : values[_hideMessagesEntryKey] as bool? ?? false,
      autoConnectMessages: values[_autoConnectMessagesKey] as bool? ?? false,
      mobileDeviceRecovery: values[_mobileDeviceRecoveryKey] as bool? ?? true,
      themeMode: AppThemeModeDetails.fromStorage(
        values[_themeModeKey] as String?,
      ),
      desktopColorStyle: DesktopColorStyleDetails.fromStorage(
        values[_desktopColorStyleKey] as String?,
      ),
      fontFamily: AppFontFamilyDetails.fromStorage(
        values[_fontFamilyKey] as String?,
      ),
      fullPageFontScale: _scale(values[_fullPageFontScaleKey] as int?),
      popupFontScale: _scale(values[_popupFontScaleKey] as int?),
      calendarSource: CalendarSourceDetails.fromStorage(
        values[_calendarSourceKey] as String?,
      ),
      calendarSourceExplicit:
          values[_calendarSourceExplicitKey] as bool? ?? false,
      calendarSourceMigrated:
          values[_calendarSourceMigratedKey] as bool? ?? false,
      showScheduleHours: values[_showScheduleHoursKey] as bool? ?? false,
      showScheduleCredit: values[_showScheduleCreditKey] as bool? ?? false,
      showScheduleSmallClass:
          values[_showScheduleSmallClassKey] as bool? ?? false,
      showAllScheduleViews: values[_showAllScheduleViewsKey] as bool? ?? false,
      autoRefresh:
          values[_lazyDataSettingsKey] == true &&
          (values[_autoRefreshKey] as bool? ?? false),
      showDataSyncControls: values[_showDataSyncControlsKey] as bool? ?? false,
      showBackToTop: values[_showBackToTopKey] as bool? ?? false,
      showMobileHeaderAccount:
          values[_showMobileHeaderAccountKey] as bool? ?? false,
      showDesktopHeaderAccount:
          values[_showDesktopHeaderAccountKey] as bool? ?? true,
      autoRelogin: values[_autoReloginKey] as bool? ?? true,
      offlineModeAutoRefreshMigrated:
          values[_offlineModeAutoRefreshMigratedKey] as bool? ?? false,
      autoSmartWorkRefresh:
          values[_lazyDataSettingsKey] == true &&
          (values[_autoSmartWorkRefreshKey] as bool? ?? false),
      calendarCacheMinutes: _cacheMinutes(
        values[_calendarCacheMinutesKey] as int?,
      ),
      calendarCacheDays: ((values[_calendarCacheDaysKey] as int?) ?? 5).clamp(
        0,
        365,
      ),
      smartWorkCacheMinutes: _cacheMinutes(
        values[_smartWorkCacheMinutesKey] as int?,
      ),
      academicCacheMinutes: _cacheMinutes(
        values[_academicCacheMinutesKey] as int?,
      ),
      academicFeatureCacheMinutes: _featureValues<int>(
        values[_academicFeatureCacheMinutesKey],
      ),
      academicFeatureCachePersistent: _featureValues<bool>(
        values[_academicFeatureCachePersistentKey],
      ),
      academicCachePersistent:
          values[_academicCachePersistentKey] as bool? ?? false,
      mobileAppsCacheMinutes: _cacheMinutes(
        values[_mobileAppsCacheMinutesKey] as int?,
      ),
      calendarCachePersistent:
          values[_calendarCachePersistentKey] as bool? ?? false,
      smartWorkCachePersistent:
          values[_smartWorkCachePersistentKey] as bool? ?? false,
      mobileAppsCachePersistent:
          values[_mobileAppsCachePersistentKey] as bool? ?? false,
      showCalendarCacheViewer:
          values[_showCalendarCacheViewerKey] as bool? ?? false,
      showNoticePreview: values[_showNoticePreviewKey] as bool? ?? false,
      noticePageMode: NoticePageModeDetails.fromStorage(
        values[_noticePageModeKey] as String?,
      ),
      offlineMode: values[_offlineModeKey] as bool? ?? false,
      experimentalMultiAccount:
          values[_experimentalMultiAccountKey] as bool? ?? false,
      experimentalDemoMode: values[_experimentalDemoModeKey] as bool? ?? false,
      networkRouteMode: NetworkRouteModeDetails.fromStorage(
        values[_networkRouteModeKey] as String?,
      ),
      httpProxy: values[_httpProxyKey] as String? ?? '',
      dataControlsUnlocked: values[_dataControlsUnlockedKey] as bool? ?? false,
      fullDeveloperMode:
          AppEdition.isDevelopment ||
          AppEdition.supportsFullDeveloperMode &&
              (values[_fullDeveloperModeKey] as bool? ?? false),
      customCalendarEnabled:
          values[_customCalendarEnabledKey] as bool? ?? false,
      customCalendarUrl: values[_customCalendarUrlKey] as String? ?? '',
      customCalendarMode: CustomCalendarMode.values.firstWhere(
        (v) => v.name == values[_customCalendarModeKey],
        orElse: () => CustomCalendarMode.overlay,
      ),
      customCalendarFormat: CustomCalendarFormat.values.firstWhere(
        (v) => v.name == values[_customCalendarFormatKey],
        orElse: () => CustomCalendarFormat.eventsJson,
      ),
      manualCalendarFallback:
          values[_manualCalendarFallbackKey] as bool? ?? false,
      localExamFallback: values[_localExamFallbackKey] as bool? ?? false,
      manualSemester: values[_manualSemesterKey] as String? ?? '',
      manualWeek: (values[_manualWeekKey] as int? ?? 1).clamp(1, 30),
      manualWeekDay: (values[_manualWeekDayKey] as int? ?? 1).clamp(1, 7),
      selectedScheduleTerm: values[_selectedScheduleTermKey] as String? ?? '',
      selectedScoreTerm: values[_selectedScoreTermKey] as String? ?? 'all',
    );
  }

  Map<String, Object?> _readValues(
    SharedPreferences preferences, {
    String? account,
  }) {
    Object? value(String base) => preferences.get(_scopedKey(base, account));
    return {for (final key in _legacyKeys) key: value(key)};
  }

  String? _normalizeAccount(String? studentId) {
    final target = studentId?.trim() ?? '';
    return target.isEmpty ? null : target;
  }

  String _scopedKey(String legacyKey, String? account) =>
      account == null ? legacyKey : accountKey(legacyKey, account);

  bool _hasLegacySettings(SharedPreferences preferences) =>
      _legacyKeys.any(preferences.containsKey);

  bool _hasAccountSettings(SharedPreferences preferences, String account) =>
      _legacyKeys.any(
        (key) => preferences.containsKey(_scopedKey(key, account)),
      );

  Future<void> _removeLegacySettings(SharedPreferences preferences) async {
    for (final key in _legacyKeys) {
      await preferences.remove(key);
    }
  }

  Future<void> _removeAccountSettings(
    SharedPreferences preferences,
    String account,
  ) async {
    for (final key in _legacyKeys) {
      await preferences.remove(_scopedKey(key, account));
    }
  }

  int _scale(int? value) => (value ?? 100).clamp(90, 130);

  Map<String, T> _featureValues<T>(Object? raw) {
    try {
      final decoded = jsonDecode(raw as String) as Map<String, dynamic>;
      return Map.unmodifiable({
        for (final e in decoded.entries)
          if (e.value is T)
            e.key:
                (e.value is int ? _cacheMinutes(e.value as int) : e.value) as T,
      });
    } catch (_) {
      return const {};
    }
  }

  int _cacheMinutes(int? value) => (value ?? 5).clamp(0, 23 * 60 + 59);
}
