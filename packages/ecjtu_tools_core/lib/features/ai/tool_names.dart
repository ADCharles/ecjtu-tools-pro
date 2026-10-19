// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

String aiCanonicalToolName(String name) {
  final short = name.startsWith('ecjtu_') ? name.substring(6) : name;
  return switch (short) {
    'read_text_file' => 'read',
    'write_text_file' => 'write',
    _ => short,
  };
}

Set<String> aiLegacyToolNames(String canonical) => switch (canonical) {
  'read' => {'read_text_file'},
  'write' => {'write_text_file'},
  _ => const {},
};
