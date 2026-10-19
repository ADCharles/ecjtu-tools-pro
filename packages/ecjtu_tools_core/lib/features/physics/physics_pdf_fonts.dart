// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'package:pdf/widgets.dart' as pw;

pw.Font? lookupPhysicsSvgFont({
  required String family,
  required String style,
  required String weight,
  required pw.Font regular,
  required pw.Font bold,
}) {
  if (family != 'NotoSansSCPdf' && family != 'SourceHanSansCN') {
    return null;
  }
  final isBold =
      weight == 'bold' ||
      weight == '600' ||
      weight == '700' ||
      weight == '800' ||
      weight == '900';
  return isBold ? bold : regular;
}
