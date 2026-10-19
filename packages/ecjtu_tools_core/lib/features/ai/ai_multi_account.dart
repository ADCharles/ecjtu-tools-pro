// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:async';

class AiMultiAccountTarget {
  const AiMultiAccountTarget({
    required this.accountId,
    this.displayName = '',
    this.accountRef = '',
    this.number = 0,
  });
  final String accountId;
  final String displayName;
  final String accountRef;
  final int number;
  String get label => '账户$number';
}

/// Local, current-task consent. Identifiers here are never tool arguments.
class AiMultiAccountGrant {
  AiMultiAccountGrant({
    Map<String, String> targets = const {},
    Map<String, Set<String>> readSources = const {},
    this.switchRef,
    this.initialAccountId,
    this.isCancelled,
  }) : targets = Map.unmodifiable(targets),
       readSources = Map.unmodifiable({
         for (final ref in targets.keys)
           ref: Set<String>.unmodifiable(readSources[ref] ?? const {}),
       });
  final Map<String, String> targets;
  Set<String> get sources => readSources.values.expand((s) => s).toSet();
  final Map<String, Set<String>> readSources;
  final String? switchRef;
  final String? initialAccountId;
  final bool Function()? isCancelled;
  bool get active => !(isCancelled?.call() ?? false);
  bool canRead(AiMultiAccountTarget target, String source) =>
      active &&
      targets[target.accountRef] == target.accountId &&
      (readSources[target.accountRef]?.contains(source) ?? false);
  bool canSwitch(AiMultiAccountTarget target) =>
      active &&
      switchRef == target.accountRef &&
      targets[target.accountRef] == target.accountId;
  AiMultiAccountGrant withCancellation(bool Function() cancelled) =>
      AiMultiAccountGrant(
        targets: targets,
        readSources: readSources,
        switchRef: switchRef,
        initialAccountId: initialAccountId,
        isCancelled: () => !active || cancelled(),
      );
}

class AiMultiAccountScope {
  static final _key = Object();
  static AiMultiAccountGrant? get current =>
      Zone.current[_key] as AiMultiAccountGrant?;
  static T run<T>(AiMultiAccountGrant grant, T Function() body) =>
      runZoned(body, zoneValues: {_key: grant});
}

class AiMultiAccountIntent {
  static AiMultiAccountGrant resolve(
    String request,
    List<AiMultiAccountTarget> directory, {
    String? currentAccountId,
    bool Function()? isCancelled,
  }) {
    final targets = <String, String>{};
    final readSources = <String, Set<String>>{};
    final switching = <String>{};
    final clean = request
        .replaceAll(RegExp(r'```[\s\S]*?```|`[^`]*`'), ' ')
        .replaceAllMapped(RegExp(r'“([^”]*)”|「([^」]*)」|"([^"]*)"'), (match) {
          final value = match.group(1) ?? match.group(2) ?? match.group(3)!;
          return RegExp(
                r'切换|切到|比较|读取|查询|switch|compare|read',
                caseSensitive: false,
              ).hasMatch(value)
              ? ' '
              : value;
        });
    for (final clause in clean.split(RegExp(r'[。;；\n，,]|但是|不过'))) {
      if (RegExp(
        r'不要|不准|不想|不希望|不需要|无需|禁止|拒绝|别(?:切|换|查|读)|不(?:切换|比较|读取|查询)|如果|假如|例如|上次|之前|(?:工具|结果|别人|他|她)(?:说|返回|要求)|\b(?:don.t|do\s+not|never|if|example)\b',
        caseSensitive: false,
      ).hasMatch(clause)) {
        continue;
      }
      final switchTask = RegExp(
        r'切换|切到|换到|转到|switch\s+to',
        caseSensitive: false,
      ).hasMatch(clause);
      final readTask = RegExp(
        r'比较|对比|查(?:询|看|一下)?|读(?:取)?|看看|列出|成绩如何|上什么课|compare|read|show|check',
        caseSensitive: false,
      ).hasMatch(clause);
      if (!switchTask && !readTask) continue;
      final namedAccountTask =
          RegExp(r'账户|账号|account', caseSensitive: false).hasMatch(clause) ||
          (RegExp(r'比较|对比|compare', caseSensitive: false).hasMatch(clause) &&
              !RegExp(
                r'老师|教师|teacher',
                caseSensitive: false,
              ).hasMatch(clause) &&
              directory
                      .where(
                        (a) =>
                            a.displayName.isNotEmpty &&
                            clause.contains(a.displayName),
                      )
                      .map((a) => a.displayName)
                      .toSet()
                      .length >=
                  2);
      final matched = <AiMultiAccountTarget>[];
      final positions = <String, int>{};
      for (final target in directory) {
        final ordinal = target.number;
        const digits = ['', '一', '二', '三', '四', '五', '六', '七', '八', '九', '十'];
        final chinese = ordinal < digits.length ? digits[ordinal] : '';
        final labelMatch = RegExp(
          '(?:账户|账号|account\\s*)$ordinal(?!\\d)|第$ordinal个(?:账户|账号)'
          '${chinese.isEmpty ? '' : '|(?:账户|账号)$chinese(?![一二三四五六七八九十])|第$chinese个(?:账户|账号)'}',
          caseSensitive: false,
        ).firstMatch(clause);
        final idMatch = target.accountId.isEmpty
            ? null
            : RegExp(
                '(?:^|[^a-zA-Z0-9])${RegExp.escape(target.accountId)}(?:\$|[^a-zA-Z0-9])',
              ).firstMatch(clause);
        final uniqueName =
            namedAccountTask &&
            target.displayName.isNotEmpty &&
            directory
                    .where((a) => a.displayName == target.displayName)
                    .length ==
                1 &&
            clause.contains(target.displayName) &&
            (readTask ||
                RegExp(
                  '(?:切换|切到|换到|转到|账户|账号).{0,8}${RegExp.escape(target.displayName)}|${RegExp.escape(target.displayName)}的?(?:账户|账号)',
                ).hasMatch(clause));
        final current =
            target.accountId == currentAccountId &&
            RegExp(
              r'当前(?:账户|账号)|本账户|我的账户|current\s+account',
              caseSensitive: false,
            ).hasMatch(clause);
        if (labelMatch != null || idMatch != null || uniqueName || current) {
          matched.add(target);
          positions[target.accountRef] =
              labelMatch?.start ??
              idMatch?.start ??
              (uniqueName
                  ? clause.indexOf(target.displayName)
                  : clause.indexOf('当前'));
        }
      }
      if (matched.isEmpty) continue;
      Set<String> sourcesIn(String value) => {
        if (readTask &&
            RegExp(
              r'成绩|分数|绩点|学分|gpa|scores?|grades?',
              caseSensitive: false,
            ).hasMatch(value))
          'scores',
        if (readTask &&
            RegExp(
              r'日历|课表|课程安排|上什么课|calendar|schedule',
              caseSensitive: false,
            ).hasMatch(value))
          'calendar',
      };
      final requestedSources = sourcesIn(clause);
      matched.sort(
        (a, b) => positions[a.accountRef]!.compareTo(positions[b.accountRef]!),
      );
      final perTarget = <String, Set<String>>{};
      for (var i = 0; i < matched.length; i++) {
        perTarget[matched[i].accountRef] = sourcesIn(
          clause.substring(
            positions[matched[i].accountRef]!.clamp(0, clause.length),
            i + 1 < matched.length
                ? positions[matched[i + 1].accountRef]
                : null,
          ),
        );
      }
      final commonSuffix =
          matched.length > 1 &&
          perTarget.values.take(matched.length - 1).every((s) => s.isEmpty);
      if (switchTask && matched.length == 1) {
        switching.add(matched.single.accountRef);
      }
      if (requestedSources.isNotEmpty || (switchTask && matched.length == 1)) {
        targets.addAll({
          for (final target in matched) target.accountRef: target.accountId,
        });
        for (final target in matched) {
          readSources
              .putIfAbsent(target.accountRef, () => {})
              .addAll(
                requestedSources.length < 2 || commonSuffix
                    ? requestedSources
                    : perTarget[target.accountRef]!,
              );
        }
      }
    }
    return AiMultiAccountGrant(
      targets: targets,
      readSources: readSources,
      switchRef: switching.length == 1 ? switching.single : null,
      initialAccountId: currentAccountId,
      isCancelled: isCancelled,
    );
  }
}
