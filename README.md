# 华交小助手 Pro · ECJTU Tools Pro

[English](README.en.md) · [作者网站](https://DongCharles.com) · [软件下载](https://github.com/ADCharles/ecjtu-tools-pro/releases)

华交小助手 Pro 的通用核心源码，包含物理实验数据处理、日记与公式编辑、课表和成绩数据模型、AI 会话基础能力，以及适用于 Windows 和 Android 的 Flutter 界面组件。

作者：**阿东Charles（ADCharles）**。

## 内容

| 目录 | 用途 |
| --- | --- |
| `packages/ecjtu_physics_core` | 仅依赖 Dart SDK 的物理实验计算包，包含20组实验的输入模型、结果模型和计算逻辑 |
| `packages/ecjtu_tools_core` | Flutter 通用核心：物理实验页面、日记、Markdown与公式、PDF处理、课表与成绩模型、AI会话、主题与组件 |
| `third_party` | 核心包使用的本地平台依赖及其上游许可证 |

## 物理实验计算

需要 Dart 3.12 或更新的兼容版本。

```sh
cd packages/ecjtu_physics_core
dart pub get
dart analyze
dart run example/solid_density.dart
```

固体密度示例使用长2、宽3、高4、质量24，输出体积24、密度1。计算结果沿用输入量的单位体系，使用时应先统一单位。

计算器覆盖牛顿环、电子电荷、霍尔效应、弗兰克—赫兹实验、光电效应、密立根油滴、金属逸出功、声速、杨氏模量、密度、折射、伏安特性、电桥及其他实验。

## 使用 Flutter 核心

使用包含 Dart 3.12 或更新兼容版本的 Flutter SDK：

```sh
cd packages/ecjtu_tools_core
flutter pub get
flutter analyze
flutter test
```

这个目录是组件与业务模型包。应用可以按需引入库，例如：

```dart
import 'package:ecjtu_tools_core/features/calendar/diary_models.dart';
import 'package:ecjtu_tools_core/features/physics/physics_solid_density_calculator.dart';
import 'package:ecjtu_tools_core/widgets/ecjtu_dialog.dart';
```

本地平台依赖由包内 `dependency_overrides` 指向仓库的 `third_party`。将核心作为另一个应用的依赖时，应在应用根目录继承需要的平台 override。详见[集成说明](docs/INTEGRATION.md)。

## 许可与署名

自有源码采用 **GPLv3（仅第3版）**，并附作者署名保留条款和独立校园适配器链接许可。分发时保留 **阿东Charles（ADCharles）** 的署名及项目来源；分发受 GPL 覆盖的修改版本时，按 GPL 提供对应源码。

完整条件见 [LICENSE](LICENSE)、[LICENSE-ADDITIONAL.md](LICENSE-ADDITIONAL.md) 和 [NOTICE](NOTICE)。第三方代码、字体、图标和CA数据各自遵循原许可证，详见[第三方声明](THIRD_PARTY_NOTICES.md)。

欢迎提交问题和改进。贡献方式见 [CONTRIBUTING.md](CONTRIBUTING.md)。

正式版发布与双仓库同步见[发布说明](docs/RELEASING.md)。
