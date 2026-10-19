# 集成 / Integration

## Dart package

`ecjtu_physics_core`只使用Dart SDK。引用其路径或Git目录后，通过`ecjtu_physics_core.dart`使用计算器及模型：

```yaml
dependencies:
  ecjtu_physics_core:
    path: ../ecjtu-tools-pro/packages/ecjtu_physics_core
```

The physics package uses the Dart SDK only. Its barrel library exports the experiment calculators and data models.

## Flutter package

在应用根pubspec中引用核心，并继承所使用的平台依赖override。以下示例假设应用与本仓库位于同一父目录：

Add the core to the consuming application's pubspec and mirror its platform dependency overrides. This example assumes the application and repository share a parent directory:

```yaml
dependencies:
  ecjtu_tools_core:
    path: ../ecjtu-tools-pro/packages/ecjtu_tools_core

dependency_overrides:
  flutter_inappwebview_android:
    path: ../ecjtu-tools-pro/third_party/flutter_inappwebview_android
  flutter_inappwebview_windows:
    path: ../ecjtu-tools-pro/third_party/flutter_inappwebview_windows
  flutter_secure_storage_windows:
    path: ../ecjtu-tools-pro/third_party/flutter_secure_storage_windows
  path_provider_windows:
    path: ../ecjtu-tools-pro/third_party/path_provider_windows
  printing:
    path: ../ecjtu-tools-pro/third_party/printing
```

字体和图标作为Flutter包资源分发。PDF字体通过`packages/ecjtu_tools_core/assets/fonts/`读取；日记备份文件内部的`assets/`是其归档格式，含义与Flutter资源路径不同。

Fonts and icons are distributed as Flutter package assets. PDF fonts are loaded from `packages/ecjtu_tools_core/assets/fonts/`. The `assets/` entries inside diary backups are part of the archive format and are separate from Flutter bundle paths.

窗口、文档保存及浏览器平台辅助类通过相应的原生插件或MethodChannel工作。将这些类用于宿主应用时，需要为目标平台提供与调用接口匹配的原生实现。纯数据模型与计算器可独立使用。

Window, document-save and browser helpers use their respective native plugins or MethodChannels. Host applications using these helpers must provide matching native implementations for their target platform. Data models and calculators can be used independently.
