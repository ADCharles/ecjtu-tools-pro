// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import '../../data/mobile_application_model.dart';
import 'smart_work_models.dart';
import 'workbench_search_models.dart';

class WorkbenchSearchCatalog {
  const WorkbenchSearchCatalog._();

  static const enhancements = <WorkbenchSearchEntry>[
    WorkbenchSearchEntry(
      title: '快速学生互评',
      detail: '增强插件',
      icon: 'smart_work_enhance.svg',
      kind: WorkbenchSearchKind.enhancement,
    ),
    WorkbenchSearchEntry(
      title: '快速请假',
      detail: '增强插件',
      icon: 'smart_work_clipboard.svg',
      kind: WorkbenchSearchKind.enhancement,
    ),
    WorkbenchSearchEntry(
      title: '电费充值',
      detail: '增强插件',
      icon: 'smart_work_wallet.svg',
      kind: WorkbenchSearchKind.enhancement,
    ),
    WorkbenchSearchEntry(
      title: '校园网登录',
      detail: '增强插件',
      icon: 'smart_work_lock.svg',
      kind: WorkbenchSearchKind.enhancement,
    ),
    WorkbenchSearchEntry(
      title: '学习通网页版',
      detail: '增强插件',
      icon: 'smart_work_book.svg',
      kind: WorkbenchSearchKind.enhancement,
    ),
  ];

  static List<WorkbenchSearchEntry> roots({required bool noticesAvailable}) => [
    const WorkbenchSearchEntry(
      title: '智慧学工',
      detail: '工作台·智慧学工',
      icon: 'smart_work_grid.svg',
      kind: WorkbenchSearchKind.root,
      root: WorkbenchSearchRoot.smartWork,
    ),
    const WorkbenchSearchEntry(
      title: '物理实验',
      detail: '工作台·物理实验',
      icon: 'smart_work_physics.svg',
      kind: WorkbenchSearchKind.root,
      root: WorkbenchSearchRoot.physics,
    ),
    const WorkbenchSearchEntry(
      title: '增强插件',
      detail: '工作台·增强插件',
      icon: 'smart_work_enhance.svg',
      kind: WorkbenchSearchKind.root,
      root: WorkbenchSearchRoot.enhancements,
    ),
    if (noticesAvailable)
      const WorkbenchSearchEntry(
        title: '通知与校历',
        detail: '工作台·通知与校历',
        icon: 'smart_work_notification.svg',
        kind: WorkbenchSearchKind.root,
        root: WorkbenchSearchRoot.noticesAndCalendar,
      ),
  ];

  static WorkbenchSearchEntry service(SmartWorkServiceMenuItem item) {
    return WorkbenchSearchEntry(
      title: item.name,
      detail:
          '智慧学工·${item.category.isEmpty || item.category == '功能列表' ? '学工服务' : item.category}·${item.name}',
      icon: _serviceIcon(item),
      kind: WorkbenchSearchKind.smartWorkUrl,
      url: item.url,
    );
  }

  static WorkbenchSearchEntry personal(SmartWorkPersonalMenuItem item) {
    final target = switch (item.name) {
      '学籍信息' => WorkbenchSearchPersonalTarget.studentStatus,
      '体测成绩' => WorkbenchSearchPersonalTarget.sport,
      '我的奖学金' => WorkbenchSearchPersonalTarget.scholarships,
      '综测信息' => WorkbenchSearchPersonalTarget.evaluation,
      _ => null,
    };
    return WorkbenchSearchEntry(
      title: item.name,
      detail: '智慧学工·学工信息·${item.name}',
      icon: _personalIcon(item.name),
      kind: target == null
          ? WorkbenchSearchKind.smartWorkGeneric
          : WorkbenchSearchKind.smartWorkPersonal,
      personalTarget: target,
      url: item.url,
    );
  }

  static const personalSections = <WorkbenchSearchEntry>[
    WorkbenchSearchEntry(
      title: '家庭信息',
      detail: '智慧学工·学工信息·家庭信息',
      icon: 'smart_work_users.svg',
      kind: WorkbenchSearchKind.smartWorkPersonal,
      personalTarget: WorkbenchSearchPersonalTarget.family,
    ),
    WorkbenchSearchEntry(
      title: '宿舍成员',
      detail: '智慧学工·学工信息·宿舍成员',
      icon: 'smart_work_users.svg',
      kind: WorkbenchSearchKind.smartWorkPersonal,
      personalTarget: WorkbenchSearchPersonalTarget.dormitory,
    ),
    WorkbenchSearchEntry(
      title: '学籍异动',
      detail: '智慧学工·学工信息·学籍异动',
      icon: 'smart_work_graduation.svg',
      kind: WorkbenchSearchKind.smartWorkPersonal,
      personalTarget: WorkbenchSearchPersonalTarget.changes,
    ),
  ];

  static WorkbenchSearchEntry mobile(MobileApplication application) {
    return WorkbenchSearchEntry(
      title: application.name,
      detail: '移动应用·${application.name}',
      icon: 'smart_work_mobile_phone.svg',
      kind: WorkbenchSearchKind.mobileApplication,
      application: application,
      url: application.rawUrl,
    );
  }

  static String _serviceIcon(SmartWorkServiceMenuItem item) {
    final text = '${item.name} ${item.category} ${item.url}'.toLowerCase();
    if (text.contains('学籍')) return 'smart_work_graduation.svg';
    if (text.contains('体测')) return 'smart_work_heart.svg';
    if (text.contains('综测')) return 'smart_work_chart.svg';
    if (text.contains('荣誉') || text.contains('奖状')) {
      return 'smart_work_trophy.svg';
    }
    if (text.contains('处分')) return 'smart_work_alert.svg';
    if (text.contains('奖学金') || text.contains('竞赛')) {
      return 'smart_work_medal.svg';
    }
    if (RegExp(r'互评|增强|工具|evaluation|enhance|tool').hasMatch(text)) {
      return 'smart_work_enhance.svg';
    }
    if (RegExp(r'请假|审批|申请|离校|审核|approval|leave').hasMatch(text)) {
      return 'smart_work_clipboard.svg';
    }
    if (RegExp(r'日历|课程|课表|考试|安排|calendar|schedule|exam').hasMatch(text)) {
      return 'smart_work_calendar.svg';
    }
    if (RegExp(r'查询|搜索|检索|query|search').hasMatch(text)) {
      return 'smart_work_search.svg';
    }
    if (RegExp(r'缴费|奖助|资助|财务|银行卡|wallet|payment').hasMatch(text)) {
      return 'smart_work_wallet.svg';
    }
    if (RegExp(r'证明|认证|已完成|资格|badge|certificate').hasMatch(text)) {
      return 'smart_work_badge.svg';
    }
    if (RegExp(r'学生服务|用户|联系人|人员|社团|user|contact').hasMatch(text)) {
      return 'smart_work_users.svg';
    }
    return 'smart_work_book.svg';
  }

  static String _personalIcon(String name) => 'smart_work_id_card.svg';
}
