// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

class PhysicsCalculatorDefinition {
  const PhysicsCalculatorDefinition({
    required this.id,
    required this.title,
    required this.detail,
    this.implemented = false,
  });

  final String id;
  final String title;
  final String detail;
  final bool implemented;
}

class PhysicsCatalog {
  const PhysicsCatalog._();

  static const calculators = <PhysicsCalculatorDefinition>[
    PhysicsCalculatorDefinition(
      id: 'newton-rings',
      title: '牛顿环测球面曲率半径',
      detail: '五组环序和左右读数数据处理，计算曲率半径与误差',
      implemented: true,
    ),
    PhysicsCalculatorDefinition(
      id: 'electron-charge',
      title: '电子比荷的测量',
      detail: '电偏转、电聚焦、磁偏转与磁聚焦数据处理，生成趋势图',
      implemented: true,
    ),
    PhysicsCalculatorDefinition(
      id: 'galvanometer',
      title: '灵敏电流计特性的研究',
      detail: '电流计内阻、常量和灵敏度数据处理',
      implemented: true,
    ),
    PhysicsCalculatorDefinition(
      id: 'electrostatic-field',
      title: '静电场的描绘',
      detail: '同轴圆柱面与两平行导线测量数据处理',
      implemented: true,
    ),
    PhysicsCalculatorDefinition(
      id: 'voltage-current',
      title: '电学元件伏安特性的研究',
      detail: '线性电阻内外接修正与二极管正向特性',
      implemented: true,
    ),
    PhysicsCalculatorDefinition(
      id: 'youngs-modulus',
      title: '拉伸法测定金属丝的杨氏模量',
      detail: '逐差法处理标尺读数，计算杨氏模量与误差',
      implemented: true,
    ),
    PhysicsCalculatorDefinition(
      id: 'potential-difference',
      title: '电位差计的原理和使用',
      detail: '电位差实验数据处理',
      implemented: true,
    ),
    PhysicsCalculatorDefinition(
      id: 'sound-speed',
      title: '声速测量',
      detail: '驻波法与相位法数据处理，计算声速、标准差和相对误差',
      implemented: true,
    ),
    PhysicsCalculatorDefinition(
      id: 'liquid-refractive-index',
      title: '液体折射率的测量',
      detail: '最小偏向法数据处理，计算棱镜和液体折射率、标准差',
      implemented: true,
    ),
    PhysicsCalculatorDefinition(
      id: 'solid-density',
      title: '固体密度的测量',
      detail: '规则物体与排水法数据处理，计算密度和不确定度',
      implemented: true,
    ),
    PhysicsCalculatorDefinition(
      id: 'single-arm-bridge',
      title: '单臂电桥法测电阻',
      detail: '电阻测量、平均值和标准方差处理',
      implemented: true,
    ),
    PhysicsCalculatorDefinition(
      id: 'hall-effect',
      title: '霍尔效应测磁场',
      detail: '霍尔电压、磁感应强度与线圈叠加关系处理',
      implemented: true,
    ),
    PhysicsCalculatorDefinition(
      id: 'franck-hertz',
      title: '弗兰克-赫兹实验',
      detail: '电流曲线与逐差法激发电压处理',
      implemented: true,
    ),
    PhysicsCalculatorDefinition(
      id: 'photoelectric-planck',
      title: '光电效应测普朗克常量',
      detail: '伏安曲线、截止电压和普朗克常量处理',
      implemented: true,
    ),
    PhysicsCalculatorDefinition(
      id: 'millikan-oil-drop',
      title: '密立根油滴实验',
      detail: '油滴时间、电荷和电荷数数据处理',
      implemented: true,
    ),
    PhysicsCalculatorDefinition(
      id: 'metal-work-function',
      title: '金属电子逸出功',
      detail: '阳极伏安数据、温度关系和逸出功处理',
      implemented: true,
    ),
    PhysicsCalculatorDefinition(
      id: 'rigid-rotation',
      title: '刚体转动惯量的研究',
      detail: '两种关系图和转动惯量数据处理',
      implemented: true,
    ),
    PhysicsCalculatorDefinition(
      id: 'ohmmeter',
      title: '欧姆表的制作',
      detail: '电阻刻度、电流读数和测量误差处理',
      implemented: true,
    ),
    PhysicsCalculatorDefinition(
      id: 'enamel-wire-resistivity',
      title: '漆包线电阻率的测定',
      detail: '直径、电阻和电阻率不确定度处理',
      implemented: true,
    ),
    PhysicsCalculatorDefinition(
      id: 'rheostat-characteristic',
      title: '滑线变阻器特性的研究',
      detail: '直接值、修正值和不确定度处理',
      implemented: true,
    ),
  ];
}
