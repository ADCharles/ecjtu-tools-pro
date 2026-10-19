// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

export 'mobile_application_model.dart';

enum AuthMode { mobile, cas, jwxt }

extension AuthModeDetails on AuthMode {
  String get storageValue {
    switch (this) {
      case AuthMode.mobile:
        return 'mobile';
      case AuthMode.cas:
        return 'cas';
      case AuthMode.jwxt:
        return 'jwxt';
    }
  }

  String get displayName {
    switch (this) {
      case AuthMode.mobile:
        return '移动华交';
      case AuthMode.cas:
        return '智慧交大';
      case AuthMode.jwxt:
        return '教务系统';
    }
  }
}

class AccountIdentity {
  const AccountIdentity({
    required this.studentId,
    required this.studentName,
    required this.authMode,
    this.calendarUrl = '',
    this.className = '',
    this.enrollmentStatus = '',
  });

  final String studentId;
  final String studentName;
  final AuthMode authMode;
  final String calendarUrl;
  final String className;
  final String enrollmentStatus;

  AccountIdentity copyWith({
    String? studentId,
    String? studentName,
    AuthMode? authMode,
    String? calendarUrl,
    String? className,
    String? enrollmentStatus,
  }) {
    return AccountIdentity(
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      authMode: authMode ?? this.authMode,
      calendarUrl: calendarUrl ?? this.calendarUrl,
      className: className ?? this.className,
      enrollmentStatus: enrollmentStatus ?? this.enrollmentStatus,
    );
  }

  Map<String, dynamic> toJson() => {
    'studentId': studentId,
    'studentName': studentName,
    'authMode': authMode.storageValue,
    'calendarUrl': calendarUrl,
    'className': className,
    'enrollmentStatus': enrollmentStatus,
  };

  static AccountIdentity? fromJson(Object? value) {
    if (value is! Map) return null;
    final studentId = value['studentId']?.toString().trim() ?? '';
    if (studentId.isEmpty) return null;
    final mode = value['authMode']?.toString();
    final authMode = AuthMode.values.firstWhere(
      (candidate) => candidate.storageValue == mode,
      orElse: () => AuthMode.cas,
    );
    return AccountIdentity(
      studentId: studentId,
      studentName: value['studentName']?.toString().trim() ?? '',
      authMode: authMode,
      calendarUrl: value['calendarUrl']?.toString().trim() ?? '',
      className: value['className']?.toString().trim() ?? '',
      enrollmentStatus: value['enrollmentStatus']?.toString().trim() ?? '',
    );
  }
}

enum SessionPartition {
  mobilePortal,
  cas,
  jwxt,
  smartWork,
  mobileApplication,
  payment,
}

extension SessionPartitionDetails on SessionPartition {
  String get storageValue => switch (this) {
    SessionPartition.mobilePortal => 'mobilePortal',
    SessionPartition.cas => 'cas',
    SessionPartition.jwxt => 'jwxt',
    SessionPartition.smartWork => 'smartWork',
    SessionPartition.mobileApplication => 'mobileApplication',
    SessionPartition.payment => 'payment',
  };

  static SessionPartition? fromStorage(Object? value) {
    final raw = value?.toString();
    for (final partition in SessionPartition.values) {
      if (partition.storageValue == raw) return partition;
    }
    return null;
  }
}
