// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:convert';

class ElectricityLocationOption {
  const ElectricityLocationOption({required this.id, required this.name});

  final String id;
  final String name;

  factory ElectricityLocationOption.fromJson(Object? value) {
    final map = _map(value);
    return ElectricityLocationOption(
      id: _text(map['id']),
      name: _text(map['name']),
    );
  }

  Map<String, String> toJson() => {'id': id, 'name': name};
}

class ElectricityLocationSelector {
  const ElectricityLocationSelector({
    required this.type,
    required this.options,
    required this.selected,
  });

  final String type;
  final List<ElectricityLocationOption> options;
  final String selected;

  factory ElectricityLocationSelector.fromJson(Object? value) {
    final map = _map(value);
    final rawOptions = map['options'];
    return ElectricityLocationSelector(
      type: _text(map['type']),
      options: rawOptions is List
          ? rawOptions
                .map(ElectricityLocationOption.fromJson)
                .where((item) => item.id.isNotEmpty && item.name.isNotEmpty)
                .toList(growable: false)
          : const <ElectricityLocationOption>[],
      selected: _text(map['selected']),
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    'options': options.map((item) => item.toJson()).toList(growable: false),
    'selected': selected,
  };
}

class ElectricityAccountField {
  const ElectricityAccountField({
    required this.name,
    required this.value,
    required this.unit,
    required this.show,
  });

  final String name;
  final String value;
  final String unit;
  final bool show;

  factory ElectricityAccountField.fromJson(Object? value) {
    final map = _map(value);
    return ElectricityAccountField(
      name: _text(map['name']),
      value: _text(map['value']),
      unit: _text(map['unit']),
      show: _boolean(map['show'], fallback: true),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'value': value,
    'unit': unit,
    'show': show,
  };
}

class ElectricityAmountOption {
  const ElectricityAmountOption({
    required this.id,
    required this.amount,
    required this.name,
  });

  final String id;
  final String amount;
  final String name;

  factory ElectricityAmountOption.fromJson(Object? value) {
    final map = _map(value);
    return ElectricityAmountOption(
      id: _text(map['id']),
      amount: _text(map['amount'] ?? map['amt']),
      name: _text(map['name']),
    );
  }

  Map<String, String> toJson() => {'id': id, 'amount': amount, 'name': name};
}

class ElectricityPaymentMethod {
  const ElectricityPaymentMethod({
    required this.code,
    required this.name,
    required this.tradeType,
  });

  final String code;
  final String name;
  final String tradeType;

  factory ElectricityPaymentMethod.fromJson(Object? value) {
    final map = _map(value);
    return ElectricityPaymentMethod(
      code: _text(map['code']),
      name: _text(map['name']),
      tradeType: _text(map['tradeType'] ?? map['trade_type']),
    );
  }

  Map<String, dynamic> toJson() => {
    'code': code,
    'name': name,
    'tradeType': tradeType,
  };
}

class ElectricityRechargeState {
  const ElectricityRechargeState({
    required this.location,
    required this.selectors,
    required this.balance,
    required this.accountFields,
    required this.amounts,
    required this.paymentMethods,
  });

  final Map<String, String> location;
  final List<ElectricityLocationSelector> selectors;
  final String balance;
  final List<ElectricityAccountField> accountFields;
  final List<ElectricityAmountOption> amounts;
  final List<ElectricityPaymentMethod> paymentMethods;

  bool get hasRoom => (location['room'] ?? '').trim().isNotEmpty;

  factory ElectricityRechargeState.fromJson(Object? value) {
    final map = _map(value);
    final rawLocation = map['location'];
    final location = <String, String>{};
    if (rawLocation is Map) {
      rawLocation.forEach((key, item) {
        final name = key.toString().trim();
        final text = _text(item);
        if (name.isNotEmpty && text.isNotEmpty) location[name] = text;
      });
    }
    final selectors = _list(map['selectors'])
        .map(ElectricityLocationSelector.fromJson)
        .where((item) => item.type.isNotEmpty)
        .toList(growable: false);
    final accountFields = _list(map['accountFields'])
        .map(ElectricityAccountField.fromJson)
        .where((item) => item.name.isNotEmpty)
        .toList(growable: false);
    final amounts = _list(map['amounts'])
        .map(ElectricityAmountOption.fromJson)
        .where((item) => item.amount.isNotEmpty)
        .toList(growable: false);
    final methods = _list(map['paymentMethods'])
        .map(ElectricityPaymentMethod.fromJson)
        .where((item) => item.code.isNotEmpty)
        .toList(growable: false);
    return ElectricityRechargeState(
      location: location,
      selectors: selectors,
      balance: _text(map['balance']),
      accountFields: accountFields,
      amounts: amounts,
      paymentMethods: methods,
    );
  }

  Map<String, dynamic> toJson() => {
    'location': location,
    'selectors': selectors.map((item) => item.toJson()).toList(),
    'balance': balance,
    'accountFields': accountFields
        .map((item) => item.toJson())
        .toList(growable: false),
    'amounts': amounts.map((item) => item.toJson()).toList(growable: false),
    'paymentMethods': paymentMethods
        .map((item) => item.toJson())
        .toList(growable: false),
  };
}

class ElectricityPaymentResult {
  const ElectricityPaymentResult({
    required this.provider,
    required this.paymentUrl,
    required this.browserUrl,
    required this.officialBridgeUrl,
    required this.partnerJourno,
    required this.payCode,
    required this.amount,
    required this.roomName,
    required this.location,
  });

  final String provider;
  final String paymentUrl;
  final String browserUrl;
  final String officialBridgeUrl;
  final String partnerJourno;
  final String payCode;
  final String amount;
  final String roomName;
  final Map<String, String> location;

  factory ElectricityPaymentResult.fromPending(
    ElectricityPendingPayment value,
  ) {
    return ElectricityPaymentResult(
      provider: value.provider,
      paymentUrl: value.paymentUrl,
      browserUrl: value.browserUrl,
      officialBridgeUrl: value.officialBridgeUrl,
      partnerJourno: value.partnerJourno,
      payCode: value.payCode,
      amount: value.amount,
      roomName: value.roomName,
      location: value.location,
    );
  }

  ElectricityPendingPayment toPending({
    String status = 'pending',
    String statusMessage = '正在读取支付结果',
  }) {
    return ElectricityPendingPayment(
      provider: provider,
      paymentUrl: paymentUrl,
      browserUrl: browserUrl,
      officialBridgeUrl: officialBridgeUrl,
      partnerJourno: partnerJourno,
      payCode: payCode,
      amount: amount,
      roomName: roomName,
      location: location,
      status: status,
      statusMessage: statusMessage,
      createdAt: DateTime.now(),
    );
  }
}

class ElectricityPaymentStatus {
  const ElectricityPaymentStatus({required this.code, required this.message});

  final String code;
  final String message;

  bool get isSuccess => code == '1';
  bool get isFailed => code == '-1';
}

class ElectricityPendingPayment {
  const ElectricityPendingPayment({
    required this.provider,
    required this.paymentUrl,
    required this.browserUrl,
    required this.officialBridgeUrl,
    required this.partnerJourno,
    required this.payCode,
    required this.amount,
    required this.roomName,
    required this.location,
    required this.status,
    required this.statusMessage,
    required this.createdAt,
  });

  final String provider;
  final String paymentUrl;
  final String browserUrl;
  final String officialBridgeUrl;
  final String partnerJourno;
  final String payCode;
  final String amount;
  final String roomName;
  final Map<String, String> location;
  final String status;
  final String statusMessage;
  final DateTime createdAt;

  factory ElectricityPendingPayment.fromJson(Object? value) {
    final map = _map(value);
    return ElectricityPendingPayment(
      provider: _text(map['provider']),
      paymentUrl: _text(map['paymentUrl']),
      browserUrl: _text(map['browserUrl']),
      officialBridgeUrl: _text(map['officialBridgeUrl']),
      partnerJourno: _text(map['partnerJourno']),
      payCode: _text(map['payCode']),
      amount: _text(map['amount']),
      roomName: _text(map['roomName']),
      location: _stringMap(map['location']),
      status: _status(_text(map['status'])),
      statusMessage: _text(map['statusMessage']),
      createdAt: DateTime.tryParse(_text(map['createdAt'])) ?? DateTime.now(),
    );
  }

  ElectricityPendingPayment copyWith({String? status, String? statusMessage}) {
    return ElectricityPendingPayment(
      provider: provider,
      paymentUrl: paymentUrl,
      browserUrl: browserUrl,
      officialBridgeUrl: officialBridgeUrl,
      partnerJourno: partnerJourno,
      payCode: payCode,
      amount: amount,
      roomName: roomName,
      location: location,
      status: status ?? this.status,
      statusMessage: statusMessage ?? this.statusMessage,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'provider': provider,
    'paymentUrl': paymentUrl,
    'browserUrl': browserUrl,
    'officialBridgeUrl': officialBridgeUrl,
    'partnerJourno': partnerJourno,
    'payCode': payCode,
    'amount': amount,
    'roomName': roomName,
    'location': location,
    'status': status,
    'statusMessage': statusMessage,
    'createdAt': createdAt.toIso8601String(),
  };
}

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

List<Object?> _list(Object? value) => value is List ? value : const <Object?>[];

Map<String, String> _stringMap(Object? value) {
  if (value is! Map) return const <String, String>{};
  final result = <String, String>{};
  value.forEach((key, item) {
    final name = key.toString().trim();
    final text = _text(item);
    if (name.isNotEmpty && text.isNotEmpty) result[name] = text;
  });
  return result;
}

String _text(Object? value) => value?.toString().trim() ?? '';

bool _boolean(Object? value, {required bool fallback}) {
  if (value is bool) return value;
  final text = _text(value).toLowerCase();
  if (text.isEmpty) return fallback;
  return const {'1', 'true', 'yes'}.contains(text);
}

String _status(String value) =>
    const {'pending', 'timeout', 'error', 'success', 'failed'}.contains(value)
    ? value
    : 'pending';

String encodeElectricityJson(Object value) => jsonEncode(value);
