// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:ui';

bool tabHasLeftTitleRow(Offset pointer, Rect titleRow) =>
    !titleRow.inflate(8).contains(pointer);

Uri tabTransferUri(Uri? current, Uri initial) =>
    current != null && (current.scheme == 'http' || current.scheme == 'https')
    ? current
    : initial;
