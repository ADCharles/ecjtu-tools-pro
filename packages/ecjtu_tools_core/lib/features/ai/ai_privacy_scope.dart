// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:async';

import 'ai_privacy.dart';

class AiPrivacyScope {
  static final Object _key = Object();
  static AiPrivacyPolicy? get current => Zone.current[_key] as AiPrivacyPolicy?;

  static T run<T>(AiPrivacyPolicy policy, T Function() body) =>
      runZoned(body, zoneValues: {_key: policy});
}
