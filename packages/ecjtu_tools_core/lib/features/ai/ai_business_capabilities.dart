// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'ai_models.dart';
import 'ai_physics_calculations.dart';
import 'business_discovery.dart';

class AiBusinessCapabilities {
  static const sources = <String, Map<String, Object?>>{
    'contacts': {
      'title': '通讯录',
      'description':
          '移动华交真实联系人、组织目录及搜索缓存，缺少时使用contacts.search或contacts.directory获取，不猜联系人编号。',
      'filters': ['query', 'offset', 'limit'],
      'requiredAuthSystem': 'mobile',
    },
    'chat': {
      'title': '即时聊天',
      'description': '移动华交会话和聊天内容缓存，准备草稿使用chat.prepare，不套标题正文表单。',
      'filters': ['id', 'offset', 'limit'],
      'requiredAuthSystem': 'mobile',
    },
    'academic_tools': {
      'title': '教务原生查询',
      'description':
          '教师课表、教师授课与教学任务、班级课表与教学任务、学生手册（学生工作簿）、教务和微信学分统计及素质扩展学分。先发现 academic 动作获取真实筛选目录，再查询并读取此缓存；不需要模拟页面按钮。培养方案和空教室使用各自来源。',
      'filters': ['section', 'query', 'term', 'offset', 'limit'],
      'sections': [
        'teacher_schedule',
        'teacher_assign',
        'class_task',
        'workbooks',
        'credits',
      ],
    },
    'classrooms': {
      'title': '空教室',
      'description':
          '教务和微信空教室目录及按日期节次查询的缓存结果；先发现classrooms.options/query；结合当日日历给自习时间建议，未确定的时间标明为建议。',
      'filters': ['section', 'query', 'date', 'offset', 'limit'],
    },
    'capabilities': {
      'title': '功能能力目录',
      'description': '按业务关键词或类别发现本地数据来源、已注册入口关系、独立计算工具和可填字段。',
      'filters': ['query', 'section', 'limit'],
    },
    'calendar': {
      'title': '日历',
      'description':
          '按具体日期查看完整每日安排的首选来源，含日历内的实验课、普通课程、考试和个人事项；不要用教务课表替代此日期的完整安排。',
      'filters': ['date', 'limit'],
    },
    'schedule': {
      'title': '课程安排',
      'description': '教务课程与考试总览；周次课程不一定包含日历中的实验。某天上什么课应优先读取 calendar。',
      'filters': ['term', 'limit'],
    },
    'schedule_range': {
      'title': '日期范围课程',
      'description':
          '先按日历缓存读取范围内每日课程（包括实验），缺失日期以 missingCalendarDates 标明；教务投影仅作参考，不代表完整每日安排。earlyOnly 筛选第一节课。',
      'filters': ['fromDate', 'toDate', 'earlyOnly', 'limit'],
    },
    'curriculum': {
      'title': '培养方案',
      'description':
          '课程平台、模块、编号、名称、考核类型、学分、学时、状态和开课学期。分页返回 total/nextOffset，summary 汇总全部匹配课程。',
      'filters': [
        'query',
        'platform',
        'module',
        'semesterIndex',
        'status',
        'offset',
        'limit',
      ],
    },
    'exams': {
      'title': '考试安排',
      'description': '已有考试记录，可按学期或已解析的真实日期筛选。',
      'filters': ['term', 'fromDate', 'toDate', 'limit'],
    },
    'experiments': {
      'title': '实验安排',
      'description': '已有实验记录，可按学期及完成状态筛选。',
      'filters': ['term', 'completed', 'limit'],
    },
    'messages': {
      'title': '应用消息',
      'description': '已有应用消息的标题、预览、发送人、时间和已读状态。',
      'filters': ['limit'],
      'requiredAuthSystem': 'mobile',
    },
    'diary': {
      'title': '今日笺',
      'description': '本机已有日记；指定 date 读取内容，否则列出日记标题目录。',
      'filters': ['date', 'limit'],
    },
    'controls': {
      'title': '当前页面操作',
      'description': '按名称发现当前业务页面的可操作控件。',
      'filters': ['query', 'limit'],
    },
    'smart_work': {
      'title': '智慧学工',
      'description':
          '学籍信息、家庭信息、宿舍信息、学籍异动、体测成绩、我的奖学金、综测信息及已缓存的个人业务记录；不指定 section 时列出业务目录。',
      'filters': ['section', 'query', 'term', 'limit'],
    },
    'electricity': {
      'title': '电费充值',
      'description':
          '已有房间、电费页面账户字段（实际 label/value/unit，含服务返回的剩余电量/余额）、充值金额与上一次订单。电费充值和智慧学工请假是不同入口；订单金额不是当前余额或剩余度数。',
      'filters': ['limit'],
      'requiredAuthSystem': 'mobile',
    },
    'leave_draft': {
      'title': '快速请假',
      'description': '当前预填草稿；请假申请在智慧学工，快速请假用于填写后打开申请页面。',
      'filters': <String>[],
    },
    'notices': {
      'title': '通知与校历',
      'description':
          '已有通知及最近的服务端搜索结果，query按标题或发布单位筛选；具体主题应发现notices.search按关键词搜索服务端全部通知，不受本机缓存条数限制。无关键词逐页浏览使用notices.fetch。',
      'filters': ['query', 'limit'],
    },
    'notice_detail': {
      'title': '通知详情',
      'description': '按通知列表中的 id 读取已缓存正文、附件名称；缓存为空时可发现获取/打开通知的动作。',
      'filters': ['id'],
    },
    'school_calendar': {
      'title': '校历',
      'description':
          '不填year读取学年目录；填写目录中的year读取实际校历PDF各页文字和页码。文件缺失时发现school_calendar.read获取；校运会、假期等安排必须据实际文件内容回答，no_text时不能用目录推断。',
      'filters': ['query', 'year', 'offset', 'limit'],
    },
    'apps': {
      'title': '移动应用',
      'description': '已有应用目录。',
      'filters': ['query', 'limit'],
      'requiredAuthSystem': 'mobile',
    },
    'page': {
      'title': '当前页面',
      'description': '应用当前页面状态。',
      'filters': <String>[],
    },
    'browser': {
      'title': '应用内网页标签',
      'description':
          '读取实际网页宿主标签的标题、活动状态、加载状态、错误和后退能力。按返回的 tabId/revision 使用 browser.back/close/select 操作网页标签。',
      'filters': <String>[],
    },
  };

  static Map<String, Object?> read(
    Iterable<AiSemanticAction> registered,
    Map<String, Object?> args, {
    Iterable<Map<String, Object?>> tools = const [],
    String? authSystem,
  }) {
    final query = (args['query'] as String? ?? '').trim().toLowerCase();
    final section = (args['section'] as String? ?? '').trim();
    final limit = args['limit'] as int? ?? 20;
    final selectedTools = tools
        .where((tool) => tool['name'] != 'ecjtu_invoke_action')
        .where(
          (tool) => section == 'physics'
              ? (tool['name'] as String).contains('physics')
              : section == 'scores'
              ? const {
                  'ecjtu_get_scores',
                  'ecjtu_analyze_scores',
                }.contains(tool['name'])
              : query.isNotEmpty &&
                    '${tool['name']} ${tool['description']}'
                        .toLowerCase()
                        .contains(query),
        )
        .toList();
    final physicsCatalog = AiPhysicsCalculations.catalog({
      'query': section == 'physics' || query == '物理' || query == 'physics'
          ? ''
          : query,
      'limit': limit > 20 ? 20 : limit,
    });
    final showPhysics =
        section == 'physics' ||
        query.isNotEmpty && (physicsCatalog['total'] as int) > 0;
    bool matches(String value, String category) =>
        AiBusinessDiscovery.matches(query, value, category: category) ||
        _academicMatches(query, value, category);
    final sourceEntries = sources.entries
        .where(
          (s) =>
              (section.isEmpty ||
                  section == s.key ||
                  section == s.value['title']) &&
              matches('${s.key} ${s.value}', s.key),
        )
        .toList();
    final actions = registered
        .where(
          (a) =>
              (section.isEmpty ||
                  AiBusinessDiscovery.inCategory(
                    section,
                    a.id.split('.').first,
                    text: '${a.title} ${a.description}',
                  ) ||
                  (section == 'academic_tools' &&
                      a.id.startsWith('academic.')) ||
                  (section == 'leave_draft' && a.id == 'leave.prepare')) &&
              matches(
                '${a.id} ${a.title} ${a.description} ${a.arguments.map((arg) => arg.title).join(' ')}',
                a.id.split('.').first,
              ),
        )
        .toList();
    final showActions = query.isNotEmpty || section.isNotEmpty;
    final leave = registered.where((a) => a.id == 'leave.prepare').firstOrNull;
    final officialLeave = registered
        .where((a) => a.id == 'smart_work.leave')
        .firstOrNull;
    final preparedLeave = registered
        .where((a) => a.id == 'leave.open')
        .firstOrNull;
    return {
      'source': 'capabilities',
      'available': true,
      'sources': [
        for (final source in sourceEntries.take(limit))
          {'source': source.key, ...source.value},
      ],
      'sourceTotal': sourceEntries.length,
      'actionTotal': showActions ? actions.length : 0,
      'actions': showActions
          ? [
              for (final action in actions.take(limit))
                describeAction(action, authSystem: authSystem),
            ]
          : <Object?>[],
      if (selectedTools.isNotEmpty) 'tools': selectedTools.take(limit).toList(),
      if (showPhysics)
        'physics': {
          ...physicsCatalog,
          'effect':
              '本地计算测量数据使用独立工具，不需要先打开实验页面；experimentId 使用目录返回的 id。页面导航另按已注册 physics 动作发现。',
          'flow': [
            'ecjtu_physics_catalog',
            'ecjtu_get_physics_schema',
            'ecjtu_calculate_physics',
          ],
        },
      if (!showActions)
        'localToolGroups': [
          {
            'category': 'scores',
            'title': '成绩与GPA分析',
            'tools': ['ecjtu_get_scores', 'ecjtu_analyze_scores'],
          },
          {
            'category': 'physics',
            'title': '物理实验数据计算',
            'tools': [
              'ecjtu_physics_catalog',
              'ecjtu_get_physics_schema',
              'ecjtu_calculate_physics',
            ],
          },
        ],
      if ((leave != null || officialLeave != null || preparedLeave != null) &&
          (section == 'leave_draft' ||
              section == 'smart_work' ||
              query.contains('请假') ||
              query.contains('leave')))
        'relationships': [
          {
            'title': '请假',
            'officialModule': '智慧学工',
            'helperTitle': '快速请假',
            if (leave != null) 'prepareAction': leave.id,
            if (officialLeave != null) 'officialAction': officialLeave.id,
            if (preparedLeave != null) 'openPreparedAction': preparedLeave.id,
            'effect': [
              if (officialLeave != null) '只打开申请调用 officialAction，原生授权后打开浏览器。',
              if (leave != null) '需要预填使用 prepareAction。',
              if (preparedLeave != null) '打开预填结果使用 openPreparedAction。',
            ].join(''),
            if (leave?.arguments.any((a) => a.name == 'openOfficial') == true)
              'openOfficial': 'true 时填写后直接打开预填申请',
            'fields': [
              for (final arg in leave?.arguments ?? <AiActionArgument>[])
                {'name': arg.name, 'label': arg.title, ...arg.toSchema()},
            ],
          },
        ],
      'hint': '按 query 或 section 查询业务入口及其可填字段；动作仅来自当前已注册入口。',
      'currentAuthSystem': authSystem,
      if (section == 'enhancements' ||
          section == '增强插件' ||
          AiBusinessDiscovery.groups['enhancements']!.words.any(query.contains))
        'enhancements': {
          'title': '增强插件',
          'entryAction': registered.any((a) => a.id == 'enhancements.open')
              ? 'enhancements.open'
              : null,
          'items': [
            for (final entry in const {
              '快速请假': ['enhancements.leave', 'leave.prepare', 'leave.open'],
              '电费充值': ['enhancements.electricity', 'electricity.refresh'],
              '校园网登录': ['enhancements.campusnetwork'],
              '快速学生互评': ['enhancements.mutual_evaluation'],
              '学习通网页版': ['enhancements.online_learning'],
            }.entries)
              if (registered.any((a) => entry.value.contains(a.id)))
                {
                  'title': entry.key,
                  'actions': [
                    for (final a in registered.where(
                      (a) => entry.value.contains(a.id),
                    ))
                      describeAction(a, authSystem: authSystem),
                  ],
                },
          ],
          'guidance':
              '增强插件是工作台的业务辅助入口，不是显示/组件设置。按这里的真实动作直接打开具体功能；校园网配置、请假模板等页内选项打开后读 controls，页面变化重读。快速学生互评与查询综测成绩不同。',
        },
      'systemRequirements': {
        'mobile': {
          'title': '移动华交',
          'features': [
            'messages',
            'chat',
            'contacts',
            'electricity',
            'mobile_apps',
          ],
          'available': authSystem == 'mobile',
          'guidance': '这些功能属于移动华交；当前使用其他系统时，先询问用户是否切换。移动华交速度更快、功能更全。',
        },
      },
    };
  }

  static String? requiredSystem(String actionId) =>
      const {
            'messages',
            'chat',
            'contacts',
            'electricity',
            'mobile_apps',
          }.contains(actionId.split('.').first) ||
          actionId == 'enhancements.electricity'
      ? 'mobile'
      : null;

  static Map<String, Object?> describeAction(
    AiSemanticAction action, {
    String? authSystem,
  }) {
    final required = requiredSystem(action.id);
    return {
      ...action.toJson(),
      if (required != null) 'requiredAuthSystem': required,
      if (required != null && authSystem != null && authSystem != required)
        'unavailableReason': '此功能属于移动华交。可询问用户是否切换到移动华交，其速度更快、功能更全；先等待用户确认。',
    };
  }

  static bool _academicMatches(String query, String value, String category) {
    if (category != 'academic' &&
        category != 'academic_tools' &&
        category != 'curriculum' &&
        category != 'classrooms') {
      return false;
    }
    final groups = <List<String>>[
      ['教务工具', '教学查询', '教务原生', 'academic tools'],
      ['教师课表', '老师课表', '教师课程', 'teacher schedule'],
      ['教学任务', '教师授课', '老师授课', 'teacher assign'],
      ['班级课表', '班级上课', '班级课程', 'class task'],
      ['学生手册', '学生工作簿', '学生工作薄', '学生工作册', 'workbook'],
      ['学分统计', '已修学分', '欠学分', '素质扩展', '素质拓展', '第二课堂', 'credits'],
    ];
    return groups.any(
      (words) =>
          words.any(query.contains) &&
          ((words == groups.first) || words.any(value.toLowerCase().contains)),
    );
  }
}
