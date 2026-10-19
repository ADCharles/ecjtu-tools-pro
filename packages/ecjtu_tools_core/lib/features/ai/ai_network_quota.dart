// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'ai_models.dart';

class AiNetworkLimits {
  const AiNetworkLimits({
    this.operationsPerFeature = 10,
    this.operationsTotal = 30,
    this.requestsPerTicket = 80,
    this.requestsTotal = 500,
  });

  final int operationsPerFeature;
  final int operationsTotal;
  final int requestsPerTicket;
  final int requestsTotal;

  AiNetworkLimits copyWith({
    int? operationsPerFeature,
    int? operationsTotal,
    int? requestsPerTicket,
    int? requestsTotal,
  }) => AiNetworkLimits(
    operationsPerFeature: operationsPerFeature ?? this.operationsPerFeature,
    operationsTotal: operationsTotal ?? this.operationsTotal,
    requestsPerTicket: requestsPerTicket ?? this.requestsPerTicket,
    requestsTotal: requestsTotal ?? this.requestsTotal,
  );

  Map<String, Object?> toJson() => {
    'operationsPerFeature': operationsPerFeature,
    'operationsTotal': operationsTotal,
    'requestsPerTicket': requestsPerTicket,
    'requestsTotal': requestsTotal,
  };

  factory AiNetworkLimits.fromJson(Object? value) {
    const keys = [
      'operationsPerFeature',
      'operationsTotal',
      'requestsPerTicket',
      'requestsTotal',
    ];
    if (value is! Map ||
        keys.any((key) => value[key] is! int || (value[key] as int) < 1)) {
      throw const FormatException('Invalid network limits');
    }
    return AiNetworkLimits(
      operationsPerFeature: value['operationsPerFeature'] as int,
      operationsTotal: value['operationsTotal'] as int,
      requestsPerTicket: value['requestsPerTicket'] as int,
      requestsTotal: value['requestsTotal'] as int,
    );
  }
}

class AiNetworkTicket {
  AiNetworkTicket._(this._owner, this.featureId, this.accountId)
    : id = List.generate(
        16,
        (_) => _random.nextInt(256),
      ).map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();

  static final _random = Random.secure();
  final AiNetworkScope _owner;
  final String featureId;
  final String? accountId;
  final String id;
  int? _startedAt;
  int _requests = 0;
  AiToolException? _denial;
}

class AiNetworkScope {
  AiNetworkScope({this.quota, this.readAccountId, this.unlimited = false});

  static final Object _zoneKey = Object();
  static final Object _localReadKey = Object();
  static final Object _manualKey = Object();
  final AiNetworkQuota? quota;
  final String? Function()? readAccountId;

  /// Temporary rollout switch: network requests are not rate limited.
  final bool unlimited;

  String? get accountId => _accountId(readAccountId?.call());

  static AiNetworkTicket? get currentTicket =>
      Zone.current[_zoneKey] as AiNetworkTicket?;
  static bool get isManualOperation => Zone.current[_manualKey] == true;
  static bool get isLocalRead => Zone.current[_localReadKey] == true;

  AiNetworkTicket? capture() {
    final ticket = currentTicket;
    return ticket != null && identical(ticket._owner, this) ? ticket : null;
  }

  AiNetworkTicket createTicket(String featureId) {
    _validateFeature(featureId);
    return AiNetworkTicket._(this, featureId, accountId);
  }

  Future<T> run<T>(String featureId, FutureOr<T> Function() body) =>
      reenter(capture() ?? createTicket(featureId), body);

  Future<T> runFuture<T>(String featureId, Future<T> Function() body) =>
      run(featureId, body);

  Future<T> readLocal<T>(FutureOr<T> Function() body) => runZoned(
    () => Future<T>.sync(body),
    zoneValues: {_zoneKey: null, _localReadKey: true},
  );

  Future<T> runManual<T>(FutureOr<T> Function() body) => runZoned(
    () => Future<T>.sync(body),
    zoneValues: {_zoneKey: null, _manualKey: true},
  );

  Future<T> reenter<T>(AiNetworkTicket? ticket, FutureOr<T> Function() body) =>
      reenterSync(ticket, () async {
        try {
          final result = await body();
          if (ticket?._denial case final denial?) throw denial;
          return result;
        } catch (_) {
          if (ticket?._denial case final denial?) throw denial;
          rethrow;
        }
      });

  T reenterSync<T>(AiNetworkTicket? ticket, T Function() body) {
    if (ticket != null && !identical(ticket._owner, this)) {
      throw ArgumentError('Network ticket belongs to a different scope');
    }
    if (ticket != null) _checkAccount(ticket);
    return runZoned(
      body,
      zoneValues: {_zoneKey: ticket, if (ticket != null) _manualKey: false},
    );
  }

  Future<void> beforeRequest({
    required String featureId,
    AiNetworkTicket? ticket,
  }) => _reserve(featureId, ticket, true);

  Future<void> reserveFeature(String featureId, {AiNetworkTicket? ticket}) =>
      _reserve(featureId, ticket, false);

  void validateFreeRequest() {
    if (isLocalRead) {
      throw const AiToolException('network_read_only', '此查询仅可读取应用已有数据');
    }
    if (isManualOperation) return;
    final ticket = currentTicket;
    if (ticket == null) return;
    if (!identical(ticket._owner, this)) {
      throw const AiToolException('network_scope_mismatch', '网络操作归属暂不可用');
    }
    _checkAccount(ticket);
    if (ticket._denial case final denial?) throw denial;
  }

  Future<void> _reserve(
    String featureId,
    AiNetworkTicket? ticket,
    bool httpRequest,
  ) async {
    if (isLocalRead) {
      throw const AiToolException('network_read_only', '此查询仅可读取应用已有数据');
    }
    if (isManualOperation) return;
    final effective = currentTicket ?? ticket;
    if (effective == null) return;
    _validateFeature(featureId);
    if (!identical(effective._owner, this)) {
      throw const AiToolException('network_scope_mismatch', '网络操作归属暂不可用');
    }
    try {
      _checkAccount(effective);
      final target = quota;
      if (unlimited) return;
      if (target == null) {
        throw const AiToolException('network_quota_unavailable', '网络操作预算尚未就绪');
      }
      await target.reserve(
        effective,
        featureId: featureId,
        httpRequest: httpRequest,
      );
      _checkAccount(effective);
    } on AiToolException catch (error) {
      // Some business clients turn transport errors into failed data snapshots.
      effective._denial = error;
      rethrow;
    }
  }

  void _checkAccount(AiNetworkTicket ticket) {
    if (ticket._denial?.code == 'network_account_changed') {
      throw ticket._denial!;
    }
    if (accountId != ticket.accountId) {
      final denial = const AiToolException(
        'network_account_changed',
        '账户已切换，请重新发起操作',
      );
      ticket._denial = denial;
      throw denial;
    }
  }

  static String? _accountId(String? value) =>
      value == null || value.isEmpty ? null : value;

  static void _validateFeature(String featureId) {
    if (!RegExp(r'^[a-z][a-z0-9_.-]{0,95}$').hasMatch(featureId)) {
      throw ArgumentError('Invalid network feature ID');
    }
  }
}

class AiNetworkQuota {
  AiNetworkQuota({
    required this.storageFile,
    AiNetworkLimits limits = const AiNetworkLimits(),
    this.limitsProvider,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now,
       _limits = limits {
    if (limits.operationsPerFeature < 1 ||
        limits.operationsTotal < 1 ||
        limits.requestsPerTicket < 1 ||
        limits.requestsTotal < 1) {
      throw ArgumentError('Network limits must be positive');
    }
  }

  static const window = Duration(minutes: 30);
  static final _tails = <String, Future<void>>{};
  final File storageFile;
  AiNetworkLimits _limits;
  AiNetworkLimits get limits => _limits;
  final FutureOr<AiNetworkLimits> Function()? limitsProvider;
  final DateTime Function() _clock;

  Future<AiNetworkLimits> _effectiveLimits(_QuotaState state) async {
    _limits = limitsProvider == null ? _limits : await limitsProvider!();
    AiNetworkLimits.fromJson(_limits.toJson());
    state.limits = _limits;
    return _limits;
  }

  Future<AiNetworkLimits> readLimits() =>
      _locked(() async => _effectiveLimits(await _read()));

  /// Developer UI only; editing limits preserves the complete usage history.
  Future<void> updateLimits(AiNetworkLimits value) {
    AiNetworkLimits.fromJson(value.toJson());
    return _locked(() async {
      final state = await _read();
      state.limits = value;
      state.lastObservedAt = max(
        state.lastObservedAt,
        _clock().toUtc().millisecondsSinceEpoch,
      );
      await _write(state);
      _limits = value;
    });
  }

  Future<T> _locked<T>(Future<T> Function() body) {
    final path = Platform.isWindows
        ? storageFile.absolute.path.toLowerCase()
        : storageFile.absolute.path;
    final previous = _tails[path] ?? Future<void>.value();
    final released = Completer<void>();
    _tails[path] = released.future;
    return () async {
      await previous;
      RandomAccessFile? lock;
      var hasLock = false;
      try {
        await storageFile.parent.create(recursive: true);
        lock = await File(
          '${storageFile.path}.lock',
        ).open(mode: FileMode.append);
        await lock.lock(FileLock.exclusive);
        hasLock = true;
        return await body();
      } on AiToolException {
        rethrow;
      } catch (_) {
        throw const AiToolException(
          'network_quota_unavailable',
          '网络操作预算暂不可用，请稍后重试',
        );
      } finally {
        try {
          if (lock != null) {
            if (hasLock) await lock.unlock();
            await lock.close();
          }
        } catch (_) {
          // Accounting has already committed; release the in-process queue.
        } finally {
          released.complete();
          if (identical(_tails[path], released.future)) _tails.remove(path);
        }
      }
    }();
  }

  Future<_QuotaState> _read() async {
    if (!await storageFile.exists()) return _QuotaState(0, []);
    try {
      if (await storageFile.length() > 4 * 1024 * 1024) {
        throw const FormatException();
      }
      return _QuotaState.fromJson(jsonDecode(await storageFile.readAsString()));
    } catch (_) {
      throw const AiToolException('network_quota_corrupt', '网络操作预算记录无法读取');
    }
  }

  Future<void> _write(_QuotaState state) async {
    final temporary = File('${storageFile.path}.pending');
    await temporary.writeAsString(jsonEncode(state.toJson()), flush: true);
    await temporary.rename(storageFile.path);
  }

  Future<void> reserve(
    AiNetworkTicket ticket, {
    required String featureId,
    bool httpRequest = true,
  }) => _locked(() async {
    ticket._owner._checkAccount(ticket);
    AiNetworkScope._validateFeature(featureId);
    final state = await _read();
    final limits = await _effectiveLimits(state);
    ticket._owner._checkAccount(ticket);
    final now = max(
      _clock().toUtc().millisecondsSinceEpoch,
      state.lastObservedAt,
    );
    final cutoff = now - window.inMilliseconds;
    state.lastObservedAt = now;
    state.tickets.removeWhere(
      (entry) =>
          entry.startedAt <= cutoff &&
          entry.features.values.every((time) => time <= cutoff) &&
          entry.requests.every((time) => time <= cutoff),
    );
    for (final entry in state.tickets) {
      entry.requests.removeWhere((time) => time <= cutoff);
    }
    _QuotaTicket? entry;
    for (final candidate in state.tickets) {
      if (candidate.id == ticket.id) entry = candidate;
    }
    if (entry != null && entry.accountId != ticket.accountId) {
      throw const AiToolException('network_account_changed', '账户已切换，请重新发起操作');
    }
    final startedAt = ticket._startedAt ?? entry?.startedAt;
    final requestCount = max(ticket._requests, entry?.totalRequests ?? 0);
    final charges = [
      for (final value in state.tickets)
        if (value.accountId == ticket.accountId)
          for (final feature in value.features.entries)
            if (feature.value > cutoff) feature.key,
    ];
    final totalRequests = state.tickets
        .where((value) => value.accountId == ticket.accountId)
        .fold<int>(0, (sum, value) => sum + value.requests.length);
    final newFeature = entry == null || !entry.features.containsKey(featureId);
    AiToolException? denial;
    if (startedAt != null && startedAt <= cutoff) {
      denial = const AiToolException(
        'network_operation_expired',
        '本次网络操作已过期，请重新发起操作',
      );
    } else if (httpRequest && requestCount >= limits.requestsPerTicket) {
      denial = const AiToolException(
        'network_ticket_request_limit',
        '本次操作的网络请求已达上限',
      );
    } else if (httpRequest && totalRequests >= limits.requestsTotal) {
      denial = const AiToolException(
        'network_window_request_limit',
        '30 分钟内的网络请求已达上限',
      );
    } else if (newFeature && charges.length >= limits.operationsTotal) {
      denial = const AiToolException(
        'network_global_operation_limit',
        '30 分钟内的网络操作已达上限',
      );
    } else if (newFeature &&
        charges.where((id) => id == featureId).length >=
            limits.operationsPerFeature) {
      denial = const AiToolException(
        'network_feature_operation_limit',
        '此功能在 30 分钟内的网络操作已达上限',
      );
    }
    if (denial != null) {
      // Persist the clock watermark even on denial; restart cannot undo it.
      await _write(state);
      throw denial;
    }
    entry ??= _QuotaTicket(
      ticket.id,
      now,
      0,
      {},
      [],
      accountId: ticket.accountId,
    );
    if (!state.tickets.contains(entry)) state.tickets.add(entry);
    entry.features.putIfAbsent(featureId, () => now);
    if (httpRequest) {
      entry.totalRequests++;
      entry.requests.add(now);
    }
    await _write(state);
    ticket._startedAt ??= entry.startedAt;
    ticket._requests = entry.totalRequests;
  });

  Future<Map<String, Object?>> snapshot({String? accountId}) =>
      _locked(() async {
        final state = await _read();
        final limits = await _effectiveLimits(state);
        final now = max(
          _clock().toUtc().millisecondsSinceEpoch,
          state.lastObservedAt,
        );
        final cutoff = now - window.inMilliseconds;
        final tickets = state.tickets.where(
          (entry) => entry.accountId == AiNetworkScope._accountId(accountId),
        );
        final features = [
          for (final entry in tickets)
            for (final feature in entry.features.entries)
              if (feature.value > cutoff) feature.key,
        ];
        return {
          'windowMinutes': 30,
          'operationsUsed': features.length,
          'requestsUsed': tickets.fold<int>(
            0,
            (sum, entry) =>
                sum + entry.requests.where((time) => time > cutoff).length,
          ),
          'features': {
            for (final id in features.toSet())
              id: features.where((value) => value == id).length,
          },
          'limits': {
            'operationsPerFeature': limits.operationsPerFeature,
            'operationsTotal': limits.operationsTotal,
            'requestsPerTicket': limits.requestsPerTicket,
            'requestsTotal': limits.requestsTotal,
          },
        };
      });
}

class _QuotaState {
  _QuotaState(this.lastObservedAt, this.tickets, {this.limits});
  int lastObservedAt;
  AiNetworkLimits? limits;
  final List<_QuotaTicket> tickets;

  factory _QuotaState.fromJson(Object? raw) {
    if (raw is! Map ||
        !const {1, 2}.contains(raw['version']) ||
        raw['lastObservedAt'] is! int ||
        (raw['lastObservedAt'] as int) < 0 ||
        raw['tickets'] is! List) {
      throw const FormatException('Invalid network quota state');
    }
    final state = _QuotaState(
      raw['lastObservedAt'] as int,
      (raw['tickets'] as List).map(_QuotaTicket.fromJson).toList(),
      limits: raw.containsKey('limits')
          ? AiNetworkLimits.fromJson(raw['limits'])
          : null,
    );
    if (state.tickets.map((entry) => entry.id).toSet().length !=
            state.tickets.length ||
        state.tickets.any(
          (entry) =>
              entry.startedAt > state.lastObservedAt ||
              [...entry.features.values, ...entry.requests].any(
                (time) => time < entry.startedAt || time > state.lastObservedAt,
              ),
        )) {
      throw const FormatException('Invalid network quota timeline');
    }
    return state;
  }

  Map<String, Object?> toJson() => {
    'version': 2,
    'lastObservedAt': lastObservedAt,
    if (limits != null) 'limits': limits!.toJson(),
    'tickets': [for (final ticket in tickets) ticket.toJson()],
  };
}

class _QuotaTicket {
  _QuotaTicket(
    this.id,
    this.startedAt,
    this.totalRequests,
    this.features,
    this.requests, {
    this.accountId,
  });
  final String id;
  final String? accountId;
  final int startedAt;
  int totalRequests;
  final Map<String, int> features;
  final List<int> requests;

  factory _QuotaTicket.fromJson(Object? raw) {
    if (raw is! Map ||
        raw['id'] is! String ||
        !RegExp(r'^[0-9a-f]{32}$').hasMatch(raw['id'] as String) ||
        (raw['accountId'] != null &&
            (raw['accountId'] is! String ||
                (raw['accountId'] as String).isEmpty)) ||
        raw['startedAt'] is! int ||
        (raw['startedAt'] as int) < 0 ||
        raw['totalRequests'] is! int ||
        (raw['totalRequests'] as int) < 0 ||
        raw['features'] is! Map ||
        (raw['features'] as Map).isEmpty ||
        (raw['features'] as Map).entries.any(
          (entry) =>
              entry.key is! String ||
              !RegExp(
                r'^[a-z][a-z0-9_.-]{0,95}$',
              ).hasMatch(entry.key as String) ||
              entry.value is! int,
        ) ||
        raw['requests'] is! List ||
        (raw['requests'] as List).any((time) => time is! int) ||
        (raw['requests'] as List).length > (raw['totalRequests'] as int)) {
      throw const FormatException('Invalid network quota ticket');
    }
    return _QuotaTicket(
      raw['id'] as String,
      raw['startedAt'] as int,
      raw['totalRequests'] as int,
      Map<String, int>.from(raw['features'] as Map),
      List<int>.from(raw['requests'] as List),
      accountId: raw['accountId'] as String?,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'accountId': accountId,
    'startedAt': startedAt,
    'totalRequests': totalRequests,
    'features': features,
    'requests': requests,
  };
}
