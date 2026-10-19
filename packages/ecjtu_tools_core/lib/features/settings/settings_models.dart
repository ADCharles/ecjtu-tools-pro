// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../app/app_edition.dart';

enum AppThemeMode { system, light, dark }

enum DesktopColorStyle { blue, green, neutral }

extension DesktopColorStyleDetails on DesktopColorStyle {
  String get storageValue => switch (this) {
    DesktopColorStyle.blue => 'blue',
    DesktopColorStyle.green => 'green',
    DesktopColorStyle.neutral => 'neutral',
  };

  String get displayName => switch (this) {
    DesktopColorStyle.blue => '蓝色',
    DesktopColorStyle.green => '交大绿',
    DesktopColorStyle.neutral => '灰白',
  };

  static DesktopColorStyle fromStorage(String? value) => switch (value) {
    'green' => DesktopColorStyle.green,
    'neutral' => DesktopColorStyle.neutral,
    _ => DesktopColorStyle.blue,
  };
}

extension AppThemeModeDetails on AppThemeMode {
  String get storageValue => switch (this) {
    AppThemeMode.system => 'system',
    AppThemeMode.light => 'light',
    AppThemeMode.dark => 'dark',
  };

  ThemeMode get materialMode => switch (this) {
    AppThemeMode.system => ThemeMode.system,
    AppThemeMode.light => ThemeMode.light,
    AppThemeMode.dark => ThemeMode.dark,
  };

  String get displayName => switch (this) {
    AppThemeMode.system => '跟随系统',
    AppThemeMode.light => '白天',
    AppThemeMode.dark => '黑夜',
  };

  static AppThemeMode fromStorage(String? value) => switch (value) {
    'system' => AppThemeMode.system,
    'dark' => AppThemeMode.dark,
    'light' => AppThemeMode.light,
    _ => AppThemeMode.system,
  };
}

enum AppFontFamily { system, sourceHan }

extension AppFontFamilyDetails on AppFontFamily {
  String get storageValue => switch (this) {
    AppFontFamily.system => 'system',
    AppFontFamily.sourceHan => 'source-han',
  };

  /// On Android/iOS this maps to the platform's own sans-serif, which is the
  /// system 黑体 face; on Windows it maps to Microsoft YaHei.
  String get displayName => switch (this) {
    AppFontFamily.system => '系统黑体',
    AppFontFamily.sourceHan => '思源黑体',
  };

  String? get fontFamily => switch (this) {
    AppFontFamily.system =>
      defaultTargetPlatform == TargetPlatform.windows
          ? 'Microsoft YaHei'
          : null,
    AppFontFamily.sourceHan => 'SourceHanSansCN',
  };

  static AppFontFamily fromStorage(String? value) => switch (value) {
    'system' => AppFontFamily.system,
    'source-han' => AppFontFamily.sourceHan,
    'yahei' => AppFontFamily.system,
    _ => AppFontFamily.sourceHan,
  };
}

enum CustomCalendarFormat { academicJson, wechatHtml, eventsJson, ics }

enum CustomCalendarMode { overlay, replace }

enum CalendarSource { wechat, student }

extension CalendarSourceDetails on CalendarSource {
  String get storageValue => switch (this) {
    CalendarSource.wechat => 'wechat',
    CalendarSource.student => 'student',
  };

  String get displayName => switch (this) {
    CalendarSource.wechat => '微信日历',
    CalendarSource.student => '教务系统',
  };

  static CalendarSource fromStorage(String? value) =>
      value == 'wechat' ? CalendarSource.wechat : CalendarSource.student;
}

enum NoticePageMode { scroll, pages }

extension NoticePageModeDetails on NoticePageMode {
  String get storageValue => switch (this) {
    NoticePageMode.scroll => 'scroll',
    NoticePageMode.pages => 'pages',
  };

  String get displayName => switch (this) {
    NoticePageMode.scroll => '滑动加载',
    NoticePageMode.pages => '分页浏览',
  };

  static NoticePageMode fromStorage(String? value) =>
      value == 'pages' ? NoticePageMode.pages : NoticePageMode.scroll;
}

enum NetworkRouteMode { direct, system, httpProxy }

extension NetworkRouteModeDetails on NetworkRouteMode {
  String get storageValue => switch (this) {
    NetworkRouteMode.direct => 'direct',
    NetworkRouteMode.system => 'system',
    NetworkRouteMode.httpProxy => 'http-proxy',
  };

  String get displayName => switch (this) {
    NetworkRouteMode.direct => '直连',
    NetworkRouteMode.system => '跟随系统',
    NetworkRouteMode.httpProxy => 'HTTP 代理',
  };

  static NetworkRouteMode fromStorage(String? value) => switch (value) {
    'system' => NetworkRouteMode.system,
    'http-proxy' => NetworkRouteMode.httpProxy,
    'direct' => NetworkRouteMode.direct,
    _ => NetworkRouteMode.system,
  };
}

class AppSettings {
  const AppSettings({
    this.messagesEnabled = false,
    this.messagesIntroSeen = false,
    this.hideMessagesEntry = false,
    this.autoConnectMessages = false,
    this.mobileDeviceRecovery = true,
    this.themeMode = AppThemeMode.system,
    this.desktopColorStyle = DesktopColorStyle.blue,
    this.fontFamily = AppFontFamily.sourceHan,
    this.fullPageFontScale = 100,
    this.popupFontScale = 100,
    this.calendarSource = CalendarSource.student,
    this.calendarSourceExplicit = false,
    this.calendarSourceMigrated = false,
    this.showScheduleHours = false,
    this.showScheduleCredit = false,
    this.showScheduleSmallClass = false,
    this.showAllScheduleViews = false,
    this.autoRefresh = false,
    this.showDataSyncControls = false,
    this.showBackToTop = false,
    this.showMobileHeaderAccount = false,
    this.showDesktopHeaderAccount = true,
    this.autoRelogin = true,
    this.offlineModeAutoRefreshMigrated = false,
    this.autoSmartWorkRefresh = false,
    this.calendarCacheMinutes = 5,
    this.calendarCacheDays = 5,
    this.smartWorkCacheMinutes = 5,
    this.mobileAppsCacheMinutes = 5,
    this.academicCacheMinutes = 5,
    this.academicFeatureCacheMinutes = const {},
    this.academicFeatureCachePersistent = const {},
    this.calendarCachePersistent = false,
    this.smartWorkCachePersistent = false,
    this.mobileAppsCachePersistent = false,
    this.academicCachePersistent = false,
    this.showCalendarCacheViewer = false,
    this.showNoticePreview = false,
    this.noticePageMode = NoticePageMode.scroll,
    this.offlineMode = false,
    this.experimentalMultiAccount = false,
    this.experimentalDemoMode = false,
    this.networkRouteMode = NetworkRouteMode.system,
    this.httpProxy = '',
    this.dataControlsUnlocked = false,
    this.fullDeveloperMode = AppEdition.isDevelopment,
    this.customCalendarMode = CustomCalendarMode.overlay,
    this.customCalendarEnabled = false,
    this.customCalendarUrl = '',
    this.customCalendarFormat = CustomCalendarFormat.eventsJson,
    this.manualCalendarFallback = false,
    this.localExamFallback = false,
    this.manualSemester = '',
    this.manualWeek = 1,
    this.manualWeekDay = 1,
    this.selectedScheduleTerm = '',
    this.selectedScoreTerm = 'all',
  });

  final bool messagesEnabled;
  final bool messagesIntroSeen;
  final bool hideMessagesEntry;
  final bool autoConnectMessages;
  final bool mobileDeviceRecovery;
  final AppThemeMode themeMode;
  final DesktopColorStyle desktopColorStyle;
  final AppFontFamily fontFamily;
  final int fullPageFontScale;
  final int popupFontScale;
  final CalendarSource calendarSource;
  final bool calendarSourceExplicit;
  final bool calendarSourceMigrated;
  final bool showScheduleHours;
  final bool showScheduleCredit;
  final bool showScheduleSmallClass;
  final bool showAllScheduleViews;
  final bool autoRefresh;
  final bool showDataSyncControls;
  final bool showBackToTop;
  final bool showMobileHeaderAccount, showDesktopHeaderAccount;
  final bool autoRelogin;
  final int mobileAppsCacheMinutes;
  final int academicCacheMinutes;
  final Map<String, int> academicFeatureCacheMinutes;
  final Map<String, bool> academicFeatureCachePersistent;
  int cacheMinutesFor(String feature) =>
      academicFeatureCacheMinutes[feature == 'retakes' ? 'exams' : feature] ??
      academicCacheMinutes;
  bool cachePersistentFor(String feature) =>
      academicFeatureCachePersistent[feature == 'retakes'
          ? 'exams'
          : feature] ??
      academicCachePersistent;
  final bool calendarCachePersistent;
  final bool smartWorkCachePersistent;
  final bool mobileAppsCachePersistent;
  final bool academicCachePersistent;
  final bool offlineModeAutoRefreshMigrated;
  final bool autoSmartWorkRefresh;
  final int calendarCacheMinutes;
  final int calendarCacheDays;
  final int smartWorkCacheMinutes;
  // Kept only so older stored settings can be read safely.
  final bool showCalendarCacheViewer;
  final bool showNoticePreview;
  final NoticePageMode noticePageMode;
  final bool offlineMode;
  final bool experimentalMultiAccount;
  final bool experimentalDemoMode;
  final NetworkRouteMode networkRouteMode;
  final String httpProxy;
  final bool dataControlsUnlocked;
  final bool fullDeveloperMode;
  final CustomCalendarMode customCalendarMode;
  final bool customCalendarEnabled;
  final String customCalendarUrl;
  final CustomCalendarFormat customCalendarFormat;
  final bool manualCalendarFallback;
  final bool localExamFallback;
  final String manualSemester;
  final int manualWeek;
  final int manualWeekDay;
  final String selectedScheduleTerm;
  final String selectedScoreTerm;

  AppSettings copyWith({
    bool? messagesEnabled,
    bool? messagesIntroSeen,
    bool? hideMessagesEntry,
    bool? autoConnectMessages,
    bool? mobileDeviceRecovery,
    AppThemeMode? themeMode,
    DesktopColorStyle? desktopColorStyle,
    AppFontFamily? fontFamily,
    int? fullPageFontScale,
    int? popupFontScale,
    CalendarSource? calendarSource,
    bool? calendarSourceExplicit,
    bool? calendarSourceMigrated,
    bool? showScheduleHours,
    bool? showScheduleCredit,
    bool? showScheduleSmallClass,
    int? mobileAppsCacheMinutes,
    int? academicCacheMinutes,
    Map<String, int>? academicFeatureCacheMinutes,
    Map<String, bool>? academicFeatureCachePersistent,
    bool? calendarCachePersistent,
    bool? smartWorkCachePersistent,
    bool? mobileAppsCachePersistent,
    bool? academicCachePersistent,
    bool? showAllScheduleViews,
    bool? autoRefresh,
    bool? showDataSyncControls,
    bool? showBackToTop,
    bool? showMobileHeaderAccount,
    bool? showDesktopHeaderAccount,
    bool? autoRelogin,
    bool? offlineModeAutoRefreshMigrated,
    bool? autoSmartWorkRefresh,
    int? calendarCacheMinutes,
    int? calendarCacheDays,
    int? smartWorkCacheMinutes,
    bool? showCalendarCacheViewer,
    bool? showNoticePreview,
    NoticePageMode? noticePageMode,
    bool? offlineMode,
    bool? experimentalMultiAccount,
    bool? experimentalDemoMode,
    NetworkRouteMode? networkRouteMode,
    String? httpProxy,
    bool? dataControlsUnlocked,
    bool? fullDeveloperMode,
    CustomCalendarMode? customCalendarMode,
    bool? customCalendarEnabled,
    String? customCalendarUrl,
    CustomCalendarFormat? customCalendarFormat,
    bool? manualCalendarFallback,
    bool? localExamFallback,
    String? manualSemester,
    int? manualWeek,
    int? manualWeekDay,
    String? selectedScheduleTerm,
    String? selectedScoreTerm,
  }) {
    return AppSettings(
      messagesEnabled: messagesEnabled ?? this.messagesEnabled,
      messagesIntroSeen: messagesIntroSeen ?? this.messagesIntroSeen,
      hideMessagesEntry: (messagesEnabled ?? this.messagesEnabled)
          ? false
          : (hideMessagesEntry ?? this.hideMessagesEntry),
      autoConnectMessages: autoConnectMessages ?? this.autoConnectMessages,
      mobileDeviceRecovery: mobileDeviceRecovery ?? this.mobileDeviceRecovery,
      themeMode: themeMode ?? this.themeMode,
      desktopColorStyle: desktopColorStyle ?? this.desktopColorStyle,
      fontFamily: fontFamily ?? this.fontFamily,
      fullPageFontScale: _clampScale(
        fullPageFontScale ?? this.fullPageFontScale,
      ),
      popupFontScale: _clampScale(popupFontScale ?? this.popupFontScale),
      calendarSource: calendarSource ?? this.calendarSource,
      calendarSourceExplicit:
          calendarSourceExplicit ?? this.calendarSourceExplicit,
      calendarSourceMigrated:
          calendarSourceMigrated ?? this.calendarSourceMigrated,
      showScheduleHours: showScheduleHours ?? this.showScheduleHours,
      showScheduleCredit: showScheduleCredit ?? this.showScheduleCredit,
      showScheduleSmallClass:
          showScheduleSmallClass ?? this.showScheduleSmallClass,
      academicCacheMinutes: _clampCacheMinutes(
        academicCacheMinutes ?? this.academicCacheMinutes,
      ),
      academicFeatureCacheMinutes: academicFeatureCacheMinutes == null
          ? this.academicFeatureCacheMinutes
          : Map.unmodifiable(
              academicFeatureCacheMinutes.map(
                (key, value) => MapEntry(key, _clampCacheMinutes(value)),
              ),
            ),
      academicFeatureCachePersistent: academicFeatureCachePersistent == null
          ? this.academicFeatureCachePersistent
          : Map.unmodifiable(academicFeatureCachePersistent),
      academicCachePersistent:
          academicCachePersistent ?? this.academicCachePersistent,
      mobileAppsCacheMinutes: _clampCacheMinutes(
        mobileAppsCacheMinutes ?? this.mobileAppsCacheMinutes,
      ),
      calendarCachePersistent:
          calendarCachePersistent ?? this.calendarCachePersistent,
      smartWorkCachePersistent:
          smartWorkCachePersistent ?? this.smartWorkCachePersistent,
      mobileAppsCachePersistent:
          mobileAppsCachePersistent ?? this.mobileAppsCachePersistent,
      showAllScheduleViews: showAllScheduleViews ?? this.showAllScheduleViews,
      autoRefresh: autoRefresh ?? this.autoRefresh,
      showDataSyncControls: showDataSyncControls ?? this.showDataSyncControls,
      showBackToTop: showBackToTop ?? this.showBackToTop,
      showMobileHeaderAccount:
          showMobileHeaderAccount ?? this.showMobileHeaderAccount,
      showDesktopHeaderAccount:
          showDesktopHeaderAccount ?? this.showDesktopHeaderAccount,
      autoRelogin: autoRelogin ?? this.autoRelogin,
      offlineModeAutoRefreshMigrated:
          offlineModeAutoRefreshMigrated ?? this.offlineModeAutoRefreshMigrated,
      autoSmartWorkRefresh: autoSmartWorkRefresh ?? this.autoSmartWorkRefresh,
      calendarCacheMinutes: _clampCacheMinutes(
        calendarCacheMinutes ?? this.calendarCacheMinutes,
      ),
      calendarCacheDays: (calendarCacheDays ?? this.calendarCacheDays).clamp(
        0,
        365,
      ),
      smartWorkCacheMinutes: _clampCacheMinutes(
        smartWorkCacheMinutes ?? this.smartWorkCacheMinutes,
      ),
      showCalendarCacheViewer:
          showCalendarCacheViewer ?? this.showCalendarCacheViewer,
      showNoticePreview: showNoticePreview ?? this.showNoticePreview,
      noticePageMode: noticePageMode ?? this.noticePageMode,
      offlineMode: offlineMode ?? this.offlineMode,
      experimentalMultiAccount:
          experimentalMultiAccount ?? this.experimentalMultiAccount,
      experimentalDemoMode: experimentalDemoMode ?? this.experimentalDemoMode,
      networkRouteMode: networkRouteMode ?? this.networkRouteMode,
      httpProxy: httpProxy ?? this.httpProxy,
      dataControlsUnlocked: dataControlsUnlocked ?? this.dataControlsUnlocked,
      fullDeveloperMode: fullDeveloperMode ?? this.fullDeveloperMode,
      customCalendarMode: customCalendarMode ?? this.customCalendarMode,
      customCalendarEnabled:
          customCalendarEnabled ?? this.customCalendarEnabled,
      customCalendarUrl: customCalendarUrl ?? this.customCalendarUrl,
      customCalendarFormat: customCalendarFormat ?? this.customCalendarFormat,
      manualCalendarFallback:
          manualCalendarFallback ?? this.manualCalendarFallback,
      localExamFallback: localExamFallback ?? this.localExamFallback,
      manualSemester: manualSemester ?? this.manualSemester,
      manualWeek: (manualWeek ?? this.manualWeek).clamp(1, 30),
      manualWeekDay: (manualWeekDay ?? this.manualWeekDay).clamp(1, 7),
      selectedScheduleTerm: selectedScheduleTerm ?? this.selectedScheduleTerm,
      selectedScoreTerm: selectedScoreTerm ?? this.selectedScoreTerm,
    );
  }

  static int _clampScale(int value) => value.clamp(90, 130);

  static int _clampCacheMinutes(int value) => value.clamp(0, 23 * 60 + 59);

  @override
  bool operator ==(Object other) {
    return other is AppSettings &&
        other.messagesEnabled == messagesEnabled &&
        other.messagesIntroSeen == messagesIntroSeen &&
        other.hideMessagesEntry == hideMessagesEntry &&
        other.autoConnectMessages == autoConnectMessages &&
        other.mobileDeviceRecovery == mobileDeviceRecovery &&
        other.academicCacheMinutes == academicCacheMinutes &&
        mapEquals(
          other.academicFeatureCacheMinutes,
          academicFeatureCacheMinutes,
        ) &&
        mapEquals(
          other.academicFeatureCachePersistent,
          academicFeatureCachePersistent,
        ) &&
        other.academicCachePersistent == academicCachePersistent &&
        other.mobileAppsCacheMinutes == mobileAppsCacheMinutes &&
        other.calendarCachePersistent == calendarCachePersistent &&
        other.smartWorkCachePersistent == smartWorkCachePersistent &&
        other.mobileAppsCachePersistent == mobileAppsCachePersistent &&
        other.themeMode == themeMode &&
        other.desktopColorStyle == desktopColorStyle &&
        other.fontFamily == fontFamily &&
        other.fullPageFontScale == fullPageFontScale &&
        other.popupFontScale == popupFontScale &&
        other.calendarSource == calendarSource &&
        other.calendarSourceExplicit == calendarSourceExplicit &&
        other.calendarSourceMigrated == calendarSourceMigrated &&
        other.showScheduleHours == showScheduleHours &&
        other.showScheduleCredit == showScheduleCredit &&
        other.showScheduleSmallClass == showScheduleSmallClass &&
        other.showAllScheduleViews == showAllScheduleViews &&
        other.autoRefresh == autoRefresh &&
        other.showDataSyncControls == showDataSyncControls &&
        other.showBackToTop == showBackToTop &&
        other.showMobileHeaderAccount == showMobileHeaderAccount &&
        other.showDesktopHeaderAccount == showDesktopHeaderAccount &&
        other.autoRelogin == autoRelogin &&
        other.offlineModeAutoRefreshMigrated ==
            offlineModeAutoRefreshMigrated &&
        other.autoSmartWorkRefresh == autoSmartWorkRefresh &&
        other.calendarCacheMinutes == calendarCacheMinutes &&
        other.calendarCacheDays == calendarCacheDays &&
        other.smartWorkCacheMinutes == smartWorkCacheMinutes &&
        other.showCalendarCacheViewer == showCalendarCacheViewer &&
        other.showNoticePreview == showNoticePreview &&
        other.noticePageMode == noticePageMode &&
        other.offlineMode == offlineMode &&
        other.experimentalMultiAccount == experimentalMultiAccount &&
        other.experimentalDemoMode == experimentalDemoMode &&
        other.networkRouteMode == networkRouteMode &&
        other.httpProxy == httpProxy &&
        other.dataControlsUnlocked == dataControlsUnlocked &&
        other.fullDeveloperMode == fullDeveloperMode &&
        other.customCalendarMode == customCalendarMode &&
        other.customCalendarEnabled == customCalendarEnabled &&
        other.customCalendarUrl == customCalendarUrl &&
        other.customCalendarFormat == customCalendarFormat &&
        other.manualCalendarFallback == manualCalendarFallback &&
        other.localExamFallback == localExamFallback &&
        other.manualSemester == manualSemester &&
        other.manualWeek == manualWeek &&
        other.manualWeekDay == manualWeekDay &&
        other.selectedScheduleTerm == selectedScheduleTerm &&
        other.selectedScoreTerm == selectedScoreTerm;
  }

  @override
  int get hashCode => Object.hashAll([
    messagesEnabled,
    messagesIntroSeen,
    hideMessagesEntry,
    autoConnectMessages,
    mobileDeviceRecovery,

    themeMode,
    desktopColorStyle,
    fontFamily,
    fullPageFontScale,
    popupFontScale,
    calendarSource,
    calendarSourceExplicit,
    calendarSourceMigrated,
    showScheduleHours,
    showScheduleCredit,
    showScheduleSmallClass,
    showAllScheduleViews,
    autoRefresh,
    showDataSyncControls,
    showBackToTop,
    showMobileHeaderAccount,
    showDesktopHeaderAccount,
    autoRelogin,
    offlineModeAutoRefreshMigrated,
    autoSmartWorkRefresh,
    calendarCacheMinutes,
    calendarCacheDays,
    smartWorkCacheMinutes,
    showCalendarCacheViewer,
    showNoticePreview,
    noticePageMode,
    offlineMode,
    experimentalMultiAccount,
    experimentalDemoMode,
    networkRouteMode,
    httpProxy,
    dataControlsUnlocked,
    fullDeveloperMode,
    customCalendarMode,
    customCalendarEnabled,
    customCalendarUrl,
    customCalendarFormat,
    manualCalendarFallback,
    localExamFallback,
    manualSemester,
    manualWeek,
    manualWeekDay,
    selectedScheduleTerm,
    selectedScoreTerm,
    mobileAppsCacheMinutes,
    academicCacheMinutes,
    Object.hashAllUnordered(
      academicFeatureCacheMinutes.entries.map(
        (e) => Object.hash(e.key, e.value),
      ),
    ),
    Object.hashAllUnordered(
      academicFeatureCachePersistent.entries.map(
        (e) => Object.hash(e.key, e.value),
      ),
    ),
    academicCachePersistent,
    calendarCachePersistent,
    smartWorkCachePersistent,
    mobileAppsCachePersistent,
  ]);
}
