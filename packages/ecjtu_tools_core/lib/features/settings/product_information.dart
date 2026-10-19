// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

class ProductInformation {
  const ProductInformation._();

  static const introduction = [
    '4.x 全面使用 Flutter 重写，Windows、Android 和 iOS 统一使用同一套客户端代码。电脑版由浏览器插件改为独立客户端，插件端按需维护，可能继续更新。',
    '在保留 3.x 功能的基础上，补齐智慧学工和消息聊天，扩展物理实验计算器、增强插件与教务查询，并加入软件内更新。',
  ];

  static const updates = <({String title, String body})>[
    (title: '全新界面', body: '电脑和手机界面全面重新设计，导航、页面布局、控件和主题焕新，适配手机横竖屏、平板及电脑分栏。'),
    (
      title: 'AI 助手',
      body:
          '加入 AI 助手，支持校园信息查询、学习问答和文件分析。电脑端提供 Agent 模式，并支持通过 MCP 与 Skill 连接外部 AI 工具。',
    ),
    (
      title: '今日笺与日记',
      body: '今日笺升级为日记编辑，支持文字、Markdown、图片、历史记录和 PDF 导出，并提供日记备份与恢复。',
    ),
    (
      title: '小班序号查询',
      body: '教务工具新增小班序号查询，可按学期筛选、搜索课程，集中查看完整小班信息和序号；日程表也可展开小班、学分与学时信息。',
    ),
  ];
}
