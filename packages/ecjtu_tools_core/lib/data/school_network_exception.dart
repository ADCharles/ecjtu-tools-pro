// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

class SchoolNetworkException implements IOException {
  const SchoolNetworkException(this.code, this.message);

  final String code;
  final String message;

  static SchoolNetworkException? from(Object error) {
    if (error is SchoolNetworkException) return error;
    if (error is TlsException) {
      return const SchoolNetworkException(
        'NETWORK_CERTIFICATE',
        '无法验证学校服务器的安全证书，请检查系统时间和网络后重试',
      );
    }
    if (error is SocketException || error is http.ClientException) {
      final message = error is SocketException
          ? error.message
          : (error as http.ClientException).message;
      if (message.contains('Failed host lookup')) {
        return const SchoolNetworkException(
          'NETWORK_DNS',
          '无法解析学校服务器地址，请检查网络连接后重试',
        );
      }
      return const SchoolNetworkException(
        'NETWORK_CONNECTION',
        '连接学校服务失败，请检查网络连接后重试',
      );
    }
    // Authentication already handles TimeoutException separately.
    if (error is TimeoutException) return null;
    return null;
  }

  @override
  String toString() => message;
}
