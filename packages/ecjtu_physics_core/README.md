# ECJTU Physics Core

物理实验数据计算与测量模型，包含20组实验计算器。可用于密度测量、牛顿环、霍尔效应、声速、杨氏模量、伏安特性、密立根油滴及其他实验的数据处理。

计算层只依赖 Dart SDK。每个实验由输入/结果模型及对应 Calculator 组成。

```dart
import 'package:ecjtu_physics_core/ecjtu_physics_core.dart';

void main() {
  final result = SolidDensityCalculator.calculate(
    SolidDensityState.initial(),
  );
  print(result.rectangular.density);
}
```

原作者：阿东Charles（ADCharles）。
