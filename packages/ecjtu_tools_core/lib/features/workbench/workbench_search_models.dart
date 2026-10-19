// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import '../../data/mobile_application_model.dart';

enum WorkbenchSearchKind {
  root,
  smartWorkUrl,
  smartWorkPersonal,
  smartWorkGeneric,
  mobileApplication,
  enhancement,
}

enum WorkbenchSearchRoot {
  smartWork,
  physics,
  enhancements,
  noticesAndCalendar,
}

enum WorkbenchSearchPersonalTarget {
  studentStatus,
  family,
  dormitory,
  changes,
  sport,
  scholarships,
  evaluation,
}

class WorkbenchSearchEntry {
  const WorkbenchSearchEntry({
    required this.title,
    required this.detail,
    required this.icon,
    required this.kind,
    this.root,
    this.personalTarget,
    this.url = '',
    this.application,
  });

  final String title;
  final String detail;
  final String icon;
  final WorkbenchSearchKind kind;
  final WorkbenchSearchRoot? root;
  final WorkbenchSearchPersonalTarget? personalTarget;
  final String url;
  final MobileApplication? application;

  String get deduplicationKey =>
      '${kind.name}|$title|${url.trim()}|${application?.id ?? ''}';
}
