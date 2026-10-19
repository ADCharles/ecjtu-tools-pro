// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:convert';

import 'ai_bridge.dart';
import 'business_discovery.dart';
import 'document_tools.dart';
import 'desktop_agent_tools.dart';
import 'agent_workflow.dart';

class AiChatTools {
  AiChatTools(this.bridge, {this.documents, this.hasDocuments, this.workflow});
  final AiBridge bridge;
  final AiDocumentTools? documents;
  final bool Function()? hasDocuments;
  final AiAgentWorkflow? workflow;

  List<Map<String, Object?>> discover(
    String task, {
    bool stableCatalog = false,
  }) {
    final result = <Map<String, Object?>>[];
    final query = task.toLowerCase();
    const baseNames = {
      'ecjtu_get_status',
      'ecjtu_get_data',
      'ecjtu_get_settings',
      'ecjtu_list_actions',
      'ecjtu_invoke_action',
      'ecjtu_get_app_images',
    };
    final provided = bridge.tools;
    for (final tool in [
      ...provided.where((tool) => baseNames.contains(tool['name'])),
      ...provided.where((tool) => !baseNames.contains(tool['name'])),
    ]) {
      final name = tool['name'] as String;
      final scoreCalculation = _scoreCalculationIntent(query);
      final relevant = switch (name) {
        'ecjtu_list_accounts' || 'ecjtu_get_account_data' => RegExp(
          r'账户|账号|比较|对比|切换|account|compare',
        ).hasMatch(query),
        'ecjtu_get_status' ||
        'ecjtu_get_data' ||
        'ecjtu_get_settings' ||
        'ecjtu_list_actions' ||
        'ecjtu_invoke_action' => true,
        'ecjtu_get_app_images' => true,
        'ecjtu_get_scores' =>
          !scoreCalculation &&
              RegExp(
                r'成绩|绩点|学分|课程|分数|考得|学得|学业|挂科|及格|最低|最高|倒数|排名|排序|score|gpa|credit|top\s*\d|bottom\s*\d',
              ).hasMatch(query),
        'ecjtu_analyze_scores' => RegExp(
          r'成绩|绩点|学分|分数|评价|排除|去掉|不算|除了|挂科|最低|最高|倒数|排名|排序|score|gpa|credit|top\s*\d|bottom\s*\d',
        ).hasMatch(query),
        _ => _relevant(tool, query),
      };
      if (!stableCatalog && !relevant) continue;
      result.add(switch (name) {
        'ecjtu_list_actions' => _actionDiscovery(tool),
        'ecjtu_get_data' => stableCatalog ? tool : _dataDiscovery(tool, query),
        _ => tool,
      });
    }
    if (stableCatalog || hasDocuments?.call() == true)
      result.addAll(documents?.tools ?? const []);
    result.addAll(workflow?.tools ?? const []);
    if (stableCatalog) {
      result.sort(
        (a, b) => (a['name'] as String).compareTo(b['name'] as String),
      );
    }
    return result;
  }

  static bool _scoreCalculationIntent(String task) => RegExp(
    r'计算|算算|均分|平均分|gpa.{0,8}(?:多少|降|跌|到|目标|需要)|绩点.{0,8}(?:多少|降|跌|到|目标|需要)|(?:还差|差多少|需要考|考多少|考得多差|去掉|排除|不算)',
    caseSensitive: false,
  ).hasMatch(task);

  bool _relevant(Map<String, Object?> tool, String task) {
    if (const {'list_skills', 'read_skill'}.contains(tool['name'])) return true;
    if (AiDesktopAgentTools.names.contains(tool['name'])) return true;
    if (_messageIntent(task) != _MessageIntent.none &&
        _messageTool.hasMatch(
          '${tool['name']} ${tool['description']}'.toLowerCase(),
        )) {
      return true;
    }
    if ((tool['name'] as String).contains('physics') &&
        RegExp(
          r'物理|实验|电阻|电压|电流|杨氏|霍尔|牛顿|密度|折射|声速|油滴|电荷|电桥|普朗克|功函数|静电|转动|帮.*算|计算',
        ).hasMatch(task)) {
      return true;
    }
    final words = '${tool['name']} ${tool['description']}'
        .toLowerCase()
        .split(RegExp(r'[\s_，、；。:：]+'))
        .where((word) => word.length >= 2);
    return words.any(task.contains);
  }

  static String messageTaskGuidance(String task) => switch (_messageIntent(
    task.toLowerCase(),
  )) {
    _MessageIntent.chat =>
      '本次“发消息”优先理解为应用内即时聊天，不套学校消息的标题/正文表单。先查capabilities及聊天/通讯录、messages目录，以真实联系人和会话定位收件人；目录检索用chat、messages或通讯录等业务词，不把整句收件人和消息内容作为目录关键词。根据真人上下文选渠道，仍有歧义或同名联系人再简短确认。优先使用应用已有聊天，不转荐外部通讯平台。',
    _MessageIntent.school =>
      '本次明确学校消息或标题/正文，优先发现messages学校消息能力及真实字段，不改成即时聊天。依据真实收件人目录执行；若真人上下文另有明确渠道要求，先核对，必要时简短确认。',
    _MessageIntent.ambiguous =>
      '消息请求的渠道尚不明确，先查capabilities及应用内聊天/通讯录、messages两类目录，再结合本轮与真人上下文选择即时聊天或学校消息；仍无法区分才简短确认。不要仅凭“消息”一词套标题/正文表单，也不转荐外部通讯平台。',
    _MessageIntent.none => '',
  };

  static String providerTaskGuidance(String task) {
    final message = messageTaskGuidance(task);
    if (message.isEmpty &&
        !RegExp(
          r'电费|电量|充值|移动应用|移动华交|mobile apps|electricity',
          caseSensitive: false,
        ).hasMatch(task)) {
      return '';
    }
    return '消息/聊天、通讯录、电费充值和移动应用属于移动华交。先核对get_status的authSystem；不为mobile时，说明归属并询问是否切换到移动华交（速度更快、功能更全），不要直接切换系统或账户。${message.isEmpty ? '' : '\n$message'}';
  }

  Map<String, Object?> _dataDiscovery(Map<String, Object?> tool, String task) =>
      _messageIntent(task) == _MessageIntent.none
      ? tool
      : {
          ...tool,
          'description':
              '${tool['description'] ?? ''} 通讯请求先读capabilities发现聊天/通讯录与messages，数据source只选实际schema提供值；短句给某人说一句倾向即时聊天，明确标题/正文倾向学校消息。',
        };

  Map<String, Object?> _actionDiscovery(Map<String, Object?> tool) => {
    ...tool,
    'description':
        '按业务关键词或category分页发现真实动作及参数。增强插件在工作台，category=enhancements 包含快速学生互评、快速请假、电费充值、校园网登录、学习通网页版；不是设置。可按互评、校园网、超星等用途发现具体入口及原生动作，页内配置再读controls。发消息先区分应用内即时聊天（chat/通讯录/会话）与学校消息（messages/标题/正文），按真人上下文发现真实目录，不因字面名称差异排除现有聊天。空教室/自习classrooms：先读真实options/schema；未指定教学楼且仅单对节次时，优先wechat，不填building一次查所有教学楼，不必先追问楼号；跨节次（如1-4、2-3）或精细条件用教务，不以多节次结果并集冒充全时段空闲，不伪造微信结果。逐日日程calendar，培养方案curriculum，校历school_calendar，请假smart_work；通知/竞赛/比赛/讲座notices，notices.search搜索服务端，不限于本机缓存。查不到先读categories或get_data(source:capabilities)，再查同义词及相关类别；页面相关设置同时检查显示/组件配置，不因字面差异排除入口。业务优先原生动作，细操作才读controls并ui.invoke。',
    'inputSchema': {
      'type': 'object',
      'properties': {
        'query': {'type': 'string', 'maxLength': 128},
        'category': {'type': 'string', 'maxLength': 128},
        'offset': {'type': 'integer', 'minimum': 0},
        'limit': {'type': 'integer', 'minimum': 1, 'maximum': 12},
      },
      'required': <String>[],
      'additionalProperties': false,
    },
  };

  Future<Map<String, Object?>> call(
    String name,
    Map<String, Object?> args, {
    bool Function()? isCancelled,
  }) async {
    if (AiAgentWorkflow.names.contains(name) && workflow != null)
      return workflow!.call(name, args);
    if (AiDocumentTools.names.contains(name) && documents != null) {
      return documents!.call(name, args, isCancelled: isCancelled);
    }
    if (name != 'ecjtu_list_actions') {
      final arguments =
          name == 'ecjtu_get_data' &&
              args['source'] == 'smart_work' &&
              args['section'] == 'workbooks'
          ? {...args, 'source': 'academic_tools'}
          : args;
      return bridge.callTool(name, arguments, isCancelled: isCancelled);
    }
    if (args.keys.any(
          (key) => !{'query', 'category', 'offset', 'limit'}.contains(key),
        ) ||
        ['query', 'category'].any(
          (key) =>
              args.containsKey(key) &&
              (args[key] is! String || (args[key] as String).length > 128),
        )) {
      return AiBridge.failure('invalid_arguments', '动作筛选参数不正确');
    }
    final offset = args['offset'] ?? 0;
    final limit = args['limit'] ?? 8;
    if (offset is! int ||
        offset < 0 ||
        limit is! int ||
        limit < 1 ||
        limit > 12) {
      return AiBridge.failure('invalid_arguments', '动作分页参数不正确');
    }
    final tool = bridge.tools.firstWhere((tool) => tool['name'] == name);
    final schema = tool['inputSchema'] as Map?;
    final properties = schema?['properties'] as Map? ?? const {};
    final paginated =
        properties.containsKey('offset') && properties.containsKey('limit');
    final forwarded = <String, Object?>{
      for (final key in ['query', 'category'])
        if (properties.containsKey(key) && args.containsKey(key))
          key: args[key],
      if (paginated) 'offset': offset,
      if (paginated) 'limit': limit,
    };
    final result = await bridge.callTool(
      name,
      forwarded,
      isCancelled: isCancelled,
    );
    if (result['isError'] == true) return result;
    final data = structuredData(result);
    final rawActions = data['actions'];
    if (rawActions is! List) {
      return AiBridge.failure('invalid_result', '动作列表暂时无法读取');
    }
    final actions = rawActions
        .whereType<Map>()
        .map((value) => Map<String, Object?>.from(value))
        .toList();
    final query = (args['query'] as String? ?? '').trim().toLowerCase();
    final category = (args['category'] as String? ?? '').trim().toLowerCase();
    final filtered = actions.where((action) {
      final searchable =
          '${action['id']} ${action['title']} ${action['description']}'
              .toLowerCase();
      return AiBusinessDiscovery.matches(
            query,
            searchable,
            category: _category(action),
          ) &&
          (category.isEmpty ||
              forwarded.containsKey('category') ||
              AiBusinessDiscovery.inCategory(
                category,
                _category(action),
                text: searchable,
              ));
    }).toList();
    final overview = query.isEmpty && category.isEmpty;
    final output = <String, Object?>{
      'categories':
          data['categories'] ??
          (actions.map(_category).toSet().toList()..sort()),
      'total': paginated ? data['total'] ?? filtered.length : filtered.length,
      'offset': offset,
      'nextOffset': paginated
          ? data['nextOffset']
          : offset + limit < filtered.length
          ? offset + limit
          : null,
      'actions': [
        for (final action in filtered.skip(paginated ? 0 : offset).take(limit))
          if (overview)
            {
              'id': action['id'],
              'title': action['title'],
              'category': _category(action),
              'available': action['available'],
            }
          else
            action,
      ],
      if (overview) 'hint': '请按类别或关键词查询参数后再执行动作',
    };
    return {
      'isError': false,
      'structuredContent': output,
      'content': [
        {'type': 'text', 'text': jsonEncode(output)},
      ],
    };
  }

  String _category(Map<String, Object?> action) =>
      action['category'] as String? ??
      (action['id']?.toString() ?? '其他').split('.').first;

  static Map<String, Object?> structuredData(Map<String, Object?> result) {
    if (result['structuredContent'] case final Map value) {
      return Map<String, Object?>.from(value);
    }
    for (final block in result['content'] as List? ?? const []) {
      if (block is Map && block['type'] == 'text' && block['text'] is String) {
        try {
          final value = jsonDecode(block['text'] as String);
          if (value is Map) return Map<String, Object?>.from(value);
        } catch (_) {}
      }
    }
    return const {};
  }
}

enum _MessageIntent { none, chat, school, ambiguous }

final _schoolMessage = RegExp(
  r'(?:学校|校园|校内)(?:消息|通知)|(?:标题|title|正文|body)\s*[:：]|(?:标题|title).{0,80}(?:正文|body)|(?:正文|body).{0,80}(?:标题|title)',
);
final _chatMessage = RegExp(
  r'即时聊天|私聊|聊天|通讯录|联系人|私信|(?:给|向|跟|和).{1,48}(?:发(?:一)?(?:条|个)?(?:消息|信息)|说|聊|捎|回复)|\b(?:chat|contacts?|dm)\b',
);
final _anyMessage = RegExp(
  r'消息|信息|会话|\b(?:messages?|messaging|conversations?)\b',
);
final _messageTool = RegExp(
  r'(?:^|[_\s])(?:chat|messages?|messaging|contacts?|conversations?|recipients?)(?:$|[_\s])|聊天|通讯录|联系人|学校消息|应用消息|发送消息',
);

_MessageIntent _messageIntent(String task) {
  if (_schoolMessage.hasMatch(task)) return _MessageIntent.school;
  if (_chatMessage.hasMatch(task)) return _MessageIntent.chat;
  return _anyMessage.hasMatch(task)
      ? _MessageIntent.ambiguous
      : _MessageIntent.none;
}
