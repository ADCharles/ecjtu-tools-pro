// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:async';

class AiNoticeRequestPolicy {
  static final Object _searchKey = Object();
  static bool get isSearch => Zone.current[_searchKey] == true;

  static Future<T> run<T>(String keyword, FutureOr<T> Function() operation) =>
      runZoned(
        () => Future<T>.sync(operation),
        zoneValues: {_searchKey: keyword.trim().isNotEmpty},
      );
}
