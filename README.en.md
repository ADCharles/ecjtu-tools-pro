# ECJTU Tools Pro

[简体中文](README.md) · [Author's website](https://DongCharles.com) · [Downloads](https://github.com/ADCharles/ecjtu-tools-pro/releases)

Reusable core source from ECJTU Tools Pro: physics laboratory data processing, diary and formula editing, timetable and grade data models, AI conversation infrastructure, and Flutter UI components for Windows and Android.

Created by **阿东Charles (ADCharles)**.

## Packages

| Directory | Purpose |
| --- | --- |
| `packages/ecjtu_physics_core` | A Dart SDK-only package with input models, result models and calculations for 20 physics experiments |
| `packages/ecjtu_tools_core` | A Flutter core package covering laboratory pages, diaries, Markdown and mathematical notation, PDF handling, timetable and grade models, AI conversations, themes and UI components |
| `third_party` | Local platform dependencies and their upstream licenses |

## Run a physics calculation

Use Dart 3.12 or a newer compatible version.

```sh
cd packages/ecjtu_physics_core
dart pub get
dart analyze
dart run example/solid_density.dart
```

The solid-density example uses dimensions 2 × 3 × 4 and mass 24, producing a volume of 24 and density of 1. Results follow the units of the supplied values; use a consistent unit system.

The calculators cover Newton's rings, electron charge, the Hall effect, the Franck–Hertz experiment, the photoelectric effect, Millikan oil drops, metal work functions, sound velocity, Young's modulus, density, refraction, current–voltage measurements, bridge circuits and other laboratory experiments.

## Use the Flutter core

Use a Flutter SDK containing Dart 3.12 or a newer compatible version:

```sh
cd packages/ecjtu_tools_core
flutter pub get
flutter analyze
flutter test
```

The core is a component and data-model package. Import individual libraries as needed:

```dart
import 'package:ecjtu_tools_core/features/calendar/diary_models.dart';
import 'package:ecjtu_tools_core/features/physics/physics_solid_density_calculator.dart';
import 'package:ecjtu_tools_core/widgets/ecjtu_dialog.dart';
```

Its platform overrides reference the repository's `third_party` directory. When consuming the core from another application, mirror the relevant overrides in that application's root pubspec. See [integration notes](docs/INTEGRATION.md).

## License and attribution

Original project source is licensed under **GNU GPL version 3 only**, with an author-attribution term and an additional linking permission for independent campus-service adapters. Preserve the attribution to **阿东Charles (ADCharles)** and the project source when redistributing. When conveying GPL-covered modified versions, provide the Corresponding Source as required by the GPL.

The complete terms are in [LICENSE](LICENSE), [LICENSE-ADDITIONAL.md](LICENSE-ADDITIONAL.md) and [NOTICE](NOTICE). Third-party code, fonts, icons and CA data retain their original licenses; see [third-party notices](THIRD_PARTY_NOTICES.md).

Issues and improvements are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md).

See [release distribution](docs/RELEASING.md) for publishing and repository synchronization.
