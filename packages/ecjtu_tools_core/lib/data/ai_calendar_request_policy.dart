// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:async';

class AiCalendarRequestPolicy {
  static final Object _dateKey = Object();
  static DateTime? get currentDate => Zone.current[_dateKey] as DateTime?;
  static bool isNearby(DateTime date, {DateTime? now}) {
    final today = now ?? DateTime.now();
    return DateTime.utc(date.year, date.month, date.day)
            .difference(DateTime.utc(today.year, today.month, today.day))
            .inDays
            .abs() <=
        14;
  }

  static Future<T> run<T>(DateTime date, FutureOr<T> Function() operation) =>
      runZoned(() => Future<T>.sync(operation), zoneValues: {_dateKey: date});
}
