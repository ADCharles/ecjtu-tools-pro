// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

class TeachingSections {
  static ({int start, int end}) parse(String value) {
    final numbers =
        RegExp(r'\d{1,2}')
            .allMatches(value)
            .map((match) => int.parse(match[0]!))
            .where((number) => number >= 1 && number <= 12)
            .toList()
          ..sort();
    return numbers.isEmpty
        ? (start: 0, end: 0)
        : (start: numbers.first, end: numbers.last);
  }

  static String label(int start, int end) => [
    for (var section = start; section <= end; section++) '$section',
  ].join(',');

  static bool needsLabel(int start, int end) =>
      start > 0 && (end != start + 1 || start.isEven);

  static ({int start, int end}) forExam({
    required String date,
    required String startTime,
    required String endTime,
    required String classroom,
  }) {
    int? minutes(String time) {
      final match = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(time);
      if (match == null) return null;
      final hour = int.parse(match[1]!);
      final minute = int.parse(match[2]!);
      return hour <= 23 && minute <= 59 ? hour * 60 + minute : null;
    }

    final start = minutes(startTime), end = minutes(endTime);
    if (start == null || end == null || end <= start) return (start: 0, end: 0);
    final day = DateTime.tryParse(date);
    final summer =
        day != null &&
        (day.month > 5 || day.month == 5 && day.day >= 6) &&
        (day.month < 10 || day.month == 10 && day.day < 8);
    final building = RegExp(r'(?:教)?(\d+)(?:栋)?[-－](\d)').firstMatch(classroom);
    final block = building == null ? null : int.tryParse(building[1]!);
    final floor = building == null ? null : int.tryParse(building[2]!);
    final early = block == 25 || block == 31 && (floor == 2 || floor == 3);
    final late =
        block == 14 ||
        block == 38 ||
        block == 31 && !early ||
        summer && (block == 6 || block == 10 || classroom.contains('图书馆'));
    final third = late
        ? 620
        : early && !summer
        ? 610
        : 605;
    final fifth = summer ? 870 : 840;
    final periods = [
      (480, 525),
      (535, 580),
      (third, third + 45),
      (third + 55, third + 100),
      (fifth, fifth + 45),
      (fifth + 55, fifth + 100),
      (fifth + 130, fifth + 175),
      (fifth + 185, fifth + 230),
      (1140, 1185),
      (1195, 1240),
    ];
    final matches = <int>[];
    for (var i = 0; i < periods.length; i++) {
      if (start < periods[i].$2 && end > periods[i].$1) matches.add(i + 1);
    }
    if (matches.isEmpty) return (start: 0, end: 0);
    return (
      start: (matches.first + 1) ~/ 2 * 2 - 1,
      end: (matches.last + 1) ~/ 2 * 2,
    );
  }
}
