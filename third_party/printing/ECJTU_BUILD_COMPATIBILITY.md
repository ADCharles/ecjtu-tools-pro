# Printing local dependency cache support

This package preserves the upstream printing source and Apache-2.0 license. Its Windows CMake supports ECJTU_PDFIUM_ROOT pointing to a preverified PDFium SDK of the same pinned Chromium build. The cached PDFiumConfig.cmake version must match PDFIUM_VERSION; the default upstream download remains the fallback. This avoids uncontrolled dependency downloads when the project already has the correct SDK. Dart and native printing behavior are unchanged.
