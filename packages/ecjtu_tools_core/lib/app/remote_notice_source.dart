// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

class RemoteNoticeSource {
  const RemoteNoticeSource(this.channel)
    : assert(channel == 'dev' || channel == 'test' || channel == 'stable');

  final String channel;
  String get tag => switch (channel) {
    'dev' => 'app-notices-dev',
    'test' => 'app-notices-test',
    _ => 'app-notices-v2',
  };
  String get cacheKey => 'ecjtu.remote_notices.config.v2.$channel';
  String seenKey(String id) => 'ecjtu.remote_notices.seen.v2.$channel.$id';
}
