// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import '../../app/app_edition.dart';

enum DeveloperUnlock { none, dataControls, fullMode }

DeveloperUnlock developerUnlockForProxy(Uri uri) {
  if (uri.scheme.toLowerCase() != 'http') return DeveloperUnlock.none;
  if (uri.host == '6.6.6.6' &&
      uri.port == 6666 &&
      uri.userInfo == '6666:6666') {
    return DeveloperUnlock.dataControls;
  }
  if (AppEdition.supportsFullDeveloperMode &&
      uri.host == '8.8.8.8' &&
      uri.port == 8888 &&
      uri.userInfo == '8888:8888') {
    return DeveloperUnlock.fullMode;
  }
  return DeveloperUnlock.none;
}
