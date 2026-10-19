// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

class CalendarCacheWindow {
  const CalendarCacheWindow._();

  static bool contains(DateTime date, {int days = 5, DateTime? today}) {
    final current = today ?? DateTime.now();
    final offset = DateTime.utc(
      date.year,
      date.month,
      date.day,
    ).difference(DateTime.utc(current.year, current.month, current.day)).inDays;
    return offset.abs() <= days.clamp(0, 365);
  }
}
