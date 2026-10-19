// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:async';
import 'dart:convert';
import 'file_change.dart';

import '../arrangement/score_models.dart';
import 'ai_business_capabilities.dart';
import 'business_discovery.dart';
import 'ai_models.dart';
import 'ai_network_quota.dart';
import 'ai_physics_calculations.dart';
import 'ai_privacy.dart';
import 'ai_privacy_scope.dart';
import 'ai_score_analysis.dart';
import 'ai_multi_account.dart';
import 'attachment_models.dart';
import 'desktop_agent_tools.dart';
import 'chat_execution_mode.dart';
import 'agent_resource_library.dart';

export 'ai_multi_account.dart';
part 'ai_bridge_multi_account.dart';

class AiBridge {
  final _resources = AiAgentResourceLibrary();
  late final _desktopTools = AiDesktopAgentTools(
    readDocumentFile: readDocumentFile,
    approve: (action, args) async {
      final approval = AiAgentScope.current?.approve ?? beforeAction;
      return approval != null && await approval(action, args);
    },
  );
  AiBridge({
    required this.readCurrentAccount,
    this.readSettings,
    this.readData,
    this.readApplicationImages,
    this.beforeAction,
    this.downloadDocument,
    this.readDocumentFile,
    this.readPrivacyEnabled,
    this.readPrivacyFields,
    this.readMultiAccountEnabled,
    this.readMultiAccountAvailable,
    this.readAccounts,
    this.readAccountData,
    this.switchAccount,
    this.actionTimeout = const Duration(seconds: 15),
    Iterable<AiSemanticAction> initialActions = const [],
    AiNetworkScope? networkScope,
    DateTime Function()? clock,
  }) : assert(actionTimeout > Duration.zero),
       networkScope = networkScope ?? AiNetworkScope(unlimited: true),
       _clock = clock ?? DateTime.now {
    for (final action in initialActions) {
      registerAction(action);
    }
    if (switchAccount != null) registerAction(_multiAccountSwitchAction());
  }

  final AiAccountSnapshot? Function() readCurrentAccount;
  final Future<String?> Function(String kind, String id)? downloadDocument;
  final AiAgentDocumentReader? readDocumentFile;
  final Map<String, Object?> Function()? readSettings;
  final FutureOr<Map<String, Object?>> Function(
    String source,
    Map<String, Object?> arguments,
  )?
  readData;
  final AiNetworkScope networkScope;
  final Future<List<AiChatAttachment>> Function(Map<String, Object?>)?
  readApplicationImages;
  final bool Function()? readPrivacyEnabled;
  final FutureOr<Map<String, String>> Function()? readPrivacyFields;
  final bool Function()? readMultiAccountEnabled;
  final bool Function()? readMultiAccountAvailable;
  final FutureOr<List<AiMultiAccountTarget>> Function()? readAccounts;
  final FutureOr<Map<String, Object?>> Function(
    String accountId,
    String source,
    Map<String, Object?> args,
  )?
  readAccountData;
  final FutureOr<void> Function(String accountId)? switchAccount;
  final Duration actionTimeout;
  final _accountReferences = <String, AiMultiAccountTarget>{};
  int _accountSerial = 0;
  String? _switchingAccountId;
  String? get switchingAccountId => _switchingAccountId;

  bool get multiAccountAvailable => readMultiAccountAvailable?.call() ?? false;
  bool get multiAccountEnabled =>
      multiAccountAvailable && (readMultiAccountEnabled?.call() ?? false);

  Future<AiPrivacyPolicy> createPrivacyPolicy({
    String userRequest = '',
    Set<String> allowedGroups = const {},
  }) async {
    final account = _readAccount();
    final fields = <String, String>{
      if (account != null) 'identity:姓名': account.displayName,
      if (account != null) 'identity:学号': account.accountId,
      if (account != null && account.className.trim().isNotEmpty)
        'profile:班级': account.className,
      ...?await networkScope.readLocal(() => readPrivacyFields?.call()),
    };
    return AiPrivacyPolicy(
      enabled: readPrivacyEnabled?.call() ?? true,
      userRequest: userRequest,
      privateFields: fields,
      allowedGroups: allowedGroups,
    );
  }

  final DateTime Function() _clock;
  final FutureOr<bool> Function(
    AiSemanticAction action,
    Map<String, Object?> arguments,
  )?
  beforeAction;
  final _actions = <String, AiSemanticAction>{};
  final _changes = StreamController<void>.broadcast(sync: true);
  int _activeActions = 0;
  final _pendingActions = <String, Future<void>>{};
  bool _closed = false;

  Stream<void> get changes => _changes.stream;
  List<AiSemanticAction> get actions => List.unmodifiable(
    _actions.values.where((a) => !a.requiresAgent || a.available),
  );
  bool get invoking => _activeActions > 0;

  void registerAction(AiSemanticAction action) {
    if (_closed) throw StateError('AI bridge is closed');
    if (_actions.containsKey(action.id)) {
      throw ArgumentError('Action already registered: ${action.id}');
    }
    _actions[action.id] = action;
    notifyContextChanged();
  }

  void unregisterAction(String id) {
    _actions.remove(id);
    notifyContextChanged();
  }

  void notifyContextChanged() {
    if (!_closed) _changes.add(null);
  }

  Future<void> close() async {
    _closed = true;
    _actions.clear();
    await _desktopTools.close();
    await _changes.close();
  }

  AiAccountSnapshot? _readAccount() {
    try {
      return readCurrentAccount();
    } catch (_) {
      throw const AiToolException('context_unavailable', '当前账户信息暂不可用');
    }
  }

  Map<String, Object?> getStatus() {
    final account = _readAccount();
    final now = _clock();
    final result = <String, Object?>{
      'today':
          '${now.year.toString().padLeft(4, '0')}-'
          '${now.month.toString().padLeft(2, '0')}-'
          '${now.day.toString().padLeft(2, '0')}',
      'currentTime': now.toIso8601String(),
      'timeZoneOffsetMinutes': now.timeZoneOffset.inMinutes,
      'accountAvailable': account != null,
      'authSystem': account?.authSystem,
      'accountLabel': account?.displayName,
      'scoresAvailable': account?.matchesAccount ?? false,
      'scoreCount': account != null && account.matchesAccount
          ? account.scores.records.length
          : 0,
      'updatedAt': account?.updatedAt?.toUtc().toIso8601String(),
      'demoMode': account?.demoMode ?? false,
      'actionCount': _actions.length,
      'actionInProgress': invoking,
      'pendingActionIds': _pendingActions.keys.toList(),
    };
    final privacy =
        AiPrivacyScope.current ??
        AiPrivacyPolicy(enabled: readPrivacyEnabled?.call() ?? true);
    return Map<String, Object?>.from(privacy.filter(result) as Map);
  }

  static const toolNames = [
    'ecjtu_get_status',
    'ecjtu_get_scores',
    'ecjtu_analyze_scores',
    'ecjtu_list_actions',
    'ecjtu_get_settings',
    'ecjtu_get_data',
    'ecjtu_physics_catalog',
    'ecjtu_get_physics_schema',
    'ecjtu_calculate_physics',
    'ecjtu_invoke_action',
  ];

  List<Map<String, Object?>> get tools => [
    if (AiAgentScope.current?.mode == AiChatMode.agent)
      for (final read in [false, true])
        {
          'name': read ? 'read_skill' : 'list_skills',
          'description': read
              ? '读取已安装技能的SKILL.md或指定相对资源文件。先获取skillId，按技能步骤执行；技能不能扩大当前文件和进程权限。'
              : '获取已安装的外置和全局技能目录，返回skillId、名称和用途。文档任务可查找匹配技能。',
          'inputSchema': {
            'type': 'object',
            'properties': {
              if (read) ...{
                'skillId': {'type': 'string'},
                'resource': {'type': 'string'},
              },
            },
            'required': [if (read) 'skillId'],
            'additionalProperties': false,
          },
          'annotations': {'readOnlyHint': true},
        },
    ..._desktopTools.tools,
    if (readApplicationImages != null)
      _tool(
        'ecjtu_get_app_images',
        '读取当前应用页面的实际图片。先读get_data(source:page)取得图片编号与id；有视觉能力时直接调用此工具分析海报等，不让用户重新截图。省略imageIds读取当前页面图片。',
        _schema({
          'imageIds': {
            'type': 'array',
            'maxItems': 6,
            'items': {'type': 'string'},
          },
        }),
      ),
    if (multiAccountEnabled) ..._multiAccountTools,
    _tool(
      'ecjtu_get_status',
      '查询当前日期、时间、时区偏移，以及当前账户、系统和数据可用状态。涉及今天、明天和相对日期时使用此工具核对，不沿用历史时间。',
      _schema({}),
    ),
    _tool(
      'ecjtu_get_scores',
      '只读取当前账户已有逐门成绩及实际分数、学分和学期。仅用于展示原始成绩；凡是涉及计算、比较、目标绩点、需要排除课程或分数、最高/最低、平均分、还差多少分，必须改用 ecjtu_analyze_scores，不要在模型中手算。',
      _schema({
        'term': {'type': 'string', 'maxLength': 128},
        'year': {'type': 'integer', 'minimum': 1900, 'maximum': 9999},
        'course': {'type': 'string', 'maxLength': 128},
        'offset': {'type': 'integer', 'minimum': 0},
        'limit': {'type': 'integer', 'minimum': 1, 'maximum': 200},
        'includeDetails': {'type': 'boolean'},
      }),
    ),
    _tool(
      'ecjtu_analyze_scores',
      '必须用于所有成绩计算和比较：目标绩点/降到某值、还差多少、排除课程或分数、GPA/平均分、最高/最低、排名和评价。该工具在设备本地按应用规则完成计算并返回结论，模型不得根据 get_scores 或其他工具结果自行逐门手算。先调用它再回答；需要原始逐门分数时可先读 ecjtu_get_scores。',
      _schema({
        'term': {'type': 'string', 'maxLength': 128},
        'year': {'type': 'integer', 'minimum': 1900, 'maximum': 9999},
        'exclude': {
          'type': 'array',
          'maxItems': 200,
          'description': '精确排除课程记录。只排除指定的两门100分课程时，使用其 id 或学期与课程代码/名称的组合。',
          'items': {
            'type': 'object',
            'properties': {
              'id': {'type': 'string', 'maxLength': 2048},
              'term': {'type': 'string', 'maxLength': 2048},
              'courseCode': {'type': 'string', 'maxLength': 2048},
              'courseName': {'type': 'string', 'maxLength': 2048},
            },
            'additionalProperties': false,
            'oneOf': [
              {
                'required': ['id'],
              },
              {
                'required': ['term'],
                'anyOf': [
                  {
                    'required': ['courseCode'],
                  },
                  {
                    'required': ['courseName'],
                  },
                ],
              },
            ],
          },
        },
        'excludeScores': {
          'type': 'array',
          'maxItems': 200,
          'description':
              '排除 numericScore 等于这些分数的所有记录，例如 [100] 排除全部100分；仅排除指定记录请用 exclude。',
          'items': {'type': 'number', 'minimum': 0, 'maximum': 100},
        },
        'sortOrder': {
          'type': 'string',
          'enum': ['asc', 'desc'],
          'default': 'desc',
          'description': 'asc 为最低分优先，desc 为最高分优先；指定此项或 topN 时返回逐门 ranking。',
        },
        'topN': {
          'type': 'integer',
          'minimum': 1,
          'maximum': 200,
          'default': 10,
          'description':
              '排名返回门数，例如最低3门使用 sortOrder=asc、topN=3；未指定 sortOrder 时默认最高分优先。',
        },
        'futureCredits': {'type': 'number', 'minimum': 0, 'maximum': 1000},
        'remainingSemesters': {'type': 'integer', 'minimum': 0, 'maximum': 20},
        'targetGpa': {'type': 'number', 'minimum': 0, 'maximum': 5},
      }),
    ),
    _tool(
      'ecjtu_list_actions',
      '按类别、关键词分页发现应用操作',
      _schema({
        'query': {'type': 'string', 'maxLength': 128},
        'category': {'type': 'string', 'maxLength': 96},
        'offset': {'type': 'integer', 'minimum': 0},
        'limit': {'type': 'integer', 'minimum': 1, 'maximum': 50},
      }),
    ),
    _tool('ecjtu_get_settings', '读取可调整设置、选项和参数说明', _schema({})),
    _tool(
      'ecjtu_get_data',
      '读取应用已有业务数据。某日上课/课表/日历/安排优先 calendar（含实验），缺失先发现 calendar.fetch；schedule 为教务总览。classrooms是教务/微信空教室目录和查询结果，自习先读当日日历，再发现classrooms类别的options/query直接查询，无需先模拟点击页面。school_calendar填year读实际PDF文字。smart_work不填section列目录；curriculum培养方案分页；notices列表、notice_detail正文。能力不清楚先查capabilities；页面标题栏获取/筛选等按钮在controls中，用ui.invoke操作。',
      _schema(
        {
          'source': {'type': 'string', 'enum': dataSources},
          'date': {'type': 'string', 'pattern': r'^\d{4}-\d{2}-\d{2}$'},
          'fromDate': {'type': 'string', 'pattern': r'^\d{4}-\d{2}-\d{2}$'},
          'toDate': {'type': 'string', 'pattern': r'^\d{4}-\d{2}-\d{2}$'},
          'completed': {'type': 'boolean'},
          'earlyOnly': {
            'type': 'boolean',
            'description': 'schedule_range 仅筛选第一节课',
          },
          'query': {
            'type': 'string',
            'maxLength': 128,
            'description':
                'controls、smart_work、notices、school_calendar、apps、curriculum、capabilities、classrooms 的关键词筛选；通知按标题或发布单位匹配，培养方案按课程名称/编号/平台/模块匹配。',
          },
          'section': {
            'type': 'string',
            'maxLength': 128,
            'description':
                'smart_work 的业务 id 或实际中文标题；capabilities 的业务类别；classrooms的jwxt/wechat来源。',
          },
          'id': {
            'type': 'string',
            'minLength': 1,
            'maxLength': 256,
            'description': 'notice_detail 使用 notices 返回的真实通知 id。',
          },
          'year': {
            'type': 'string',
            'maxLength': 32,
            'description':
                'school_calendar 不填year读学年目录，填目录真实year读取已加载校历的实际文字和页码；缺失时发现school_calendar.read。',
          },
          'offset': {
            'type': 'integer',
            'minimum': 0,
            'description':
                'curriculum课程、academic_tools查询结果/动态目录、classrooms教室或school_calendar文件页的分页起点，下一页使用返回的nextOffset。',
          },
          'platform': {
            'type': 'string',
            'maxLength': 128,
            'description': 'curriculum 课程平台，使用返回的 filters.platforms。',
          },
          'module': {
            'type': 'string',
            'maxLength': 128,
            'description': 'curriculum 课程模块，使用返回的 filters.modules。',
          },
          'semesterIndex': {
            'type': 'integer',
            'minimum': 1,
            'maximum': 30,
            'description': 'curriculum 相对开课学期序号，1=大一上、2=大一下；不是实际年份。',
          },
          'status': {
            'type': 'string',
            'maxLength': 128,
            'description': 'curriculum 使用返回的真实状态，或“未通过”匹配所有非“已过”课程。',
          },
          'term': {'type': 'string', 'maxLength': 128},
          'limit': {'type': 'integer', 'minimum': 1, 'maximum': 100},
        },
        required: ['source'],
      ),
    ),
    _tool(
      'ecjtu_physics_catalog',
      '发现可本地计算的物理实验及其输入格式入口',
      _schema({
        'query': {'type': 'string', 'maxLength': 128},
        'offset': {'type': 'integer', 'minimum': 0},
        'limit': {'type': 'integer', 'minimum': 1, 'maximum': 20},
      }),
    ),
    _tool(
      'ecjtu_get_physics_schema',
      '读取指定物理实验的默认输入、字段结构、数量和单位',
      _schema(
        {
          'experimentId': {'type': 'string', 'maxLength': 96},
        },
        required: ['experimentId'],
      ),
    ),
    _tool(
      'ecjtu_calculate_physics',
      '使用实验页面的计算器本地处理测量数据，返回计算结果和缺数据提示',
      _schema(
        {
          'experimentId': {'type': 'string', 'maxLength': 96},
          'data': {
            'type': 'object',
            'description': '先获取此实验 schema，按其中的字段、单位及数组数量提供输入',
          },
        },
        required: ['experimentId', 'data'],
      ),
    ),
    _tool(
      'ecjtu_invoke_action',
      '调用已注册的功能或按钮；先查看动作列表和对应参数',
      _schema(
        {
          'actionId': {'type': 'string', 'maxLength': 96},
          'arguments': {'type': 'object'},
        },
        required: ['actionId'],
      ),
      readOnly: false,
    ),
  ];

  static Map<String, Object?> _schema(
    Map<String, Object?> properties, {
    List<String> required = const [],
  }) => {
    'type': 'object',
    'properties': properties,
    'required': required,
    'additionalProperties': false,
  };

  static Map<String, Object?> _tool(
    String name,
    String description,
    Map<String, Object?> schema, {
    bool readOnly = true,
  }) => {
    'name': name,
    'description': description,
    'inputSchema': schema,
    'annotations': {
      'readOnlyHint': readOnly,
      'destructiveHint': false,
      'idempotentHint': readOnly,
      'openWorldHint': !readOnly,
    },
  };

  Future<Map<String, Object?>> callTool(
    String name,
    Map<String, Object?> arguments, {
    bool Function()? isCancelled,
  }) async {
    if (_closed) return failure('bridge_closed', 'AI 连接已关闭');
    try {
      _checkAfterAccountSwitch(name);
      final Map<String, Object?> result;
      switch (name) {
        case 'list_skills':
        case 'read_skill':
          if (AiAgentScope.current?.mode != AiChatMode.agent)
            throw const AiToolException('agent_required', '此操作需要桌面 Agent 模式');
          _checkKeys(
            arguments,
            name == 'list_skills' ? {} : {'skillId', 'resource'},
          );
          if (name == 'list_skills') {
            result = {
              'skills': [
                for (final skill in await _resources.discover()) skill.toJson(),
              ],
            };
          } else {
            if (arguments['skillId'] is! String ||
                arguments['resource'] != null &&
                    arguments['resource'] is! String)
              _invalid();
            result = await _resources.readSkillResource(
              arguments['skillId'] as String,
              resource: arguments['resource'] as String? ?? 'SKILL.md',
            );
          }
        case 'ecjtu_get_app_images':
          _checkKeys(arguments, {'imageIds'});
          final ids = arguments['imageIds'];
          if (ids != null &&
              (ids is! List ||
                  ids.length > 6 ||
                  ids.any((id) => id is! String)))
            _invalid();
          final reader = readApplicationImages;
          if (reader == null)
            throw const AiToolException('image_unavailable', '当前页面图片暂不可用');
          final account = _readAccount()?.accountId;
          final images = await networkScope.run(
            'notice_assets',
            () => reader(arguments),
          );
          if (_readAccount()?.accountId != account)
            throw const AiToolException('account_changed', '账户已切换，请重新读取图片');
          final metadata = {
            'images': [for (final image in images) image.summary.toJson()],
            'available': images.isNotEmpty,
          };
          return {
            'isError': false,
            'structuredContent': metadata,
            'content': [
              {'type': 'text', 'text': jsonEncode(metadata)},
              for (final image in images)
                {
                  'type': 'image',
                  'data': image.encodedData,
                  'mimeType': image.summary.mimeType,
                },
            ],
          };
        case 'ecjtu_get_status':
          _checkKeys(arguments, const {});
          result = getStatus();
        case 'ecjtu_list_accounts':
          result = await _multiAccountDirectory(arguments);
        case 'ecjtu_get_account_data':
          result = await _multiAccountData(arguments, isCancelled: isCancelled);
        case 'ecjtu_get_scores':
          result = _getScores(arguments);
        case 'ecjtu_analyze_scores':
          final account = _readAccount();
          if (account == null) {
            throw const AiToolException('no_active_account', '请先在应用中选择账户');
          }
          if (!account.matchesAccount) {
            throw const AiToolException('scores_not_ready', '当前账户成绩尚未就绪');
          }
          result = AiScoreAnalysis.analyze(account, arguments);
        case 'ecjtu_list_actions':
          result = _listActions(arguments);
        case 'ecjtu_get_settings':
          _checkKeys(arguments, const {});
          result = await networkScope.readLocal(
            () => {
              'available': readSettings != null,
              'settings': readSettings?.call() ?? <String, Object?>{},
            },
          );
        case 'ecjtu_get_data':
          result = await _getData(arguments);
        case 'ecjtu_physics_catalog':
          result = AiPhysicsCalculations.catalog(arguments);
        case 'ecjtu_get_physics_schema':
          result = AiPhysicsCalculations.getSchema(arguments);
        case 'ecjtu_calculate_physics':
          result = AiPhysicsCalculations.calculate(arguments);
        case 'ecjtu_invoke_action':
          result = await _invokeAction(arguments, isCancelled: isCancelled);
        default:
          if (AiDesktopAgentTools.names.contains(name)) {
            result = await _desktopTools.call(
              name,
              arguments,
              isCancelled: isCancelled,
            );
            final changes = (result.remove('_fileChanges') as List? ?? const [])
                .whereType<Map>()
                .map(AiFileChange.fromJson)
                .toList();
            if (changes.isNotEmpty)
              AiAgentScope.current?.onFileChanges?.call(changes);
          } else {
            throw const AiToolException('unknown_tool', '未找到此工具');
          }
      }
      final pureCalculation = const {
        'ecjtu_physics_catalog',
        'ecjtu_get_physics_schema',
        'ecjtu_calculate_physics',
      }.contains(name);
      final privacy =
          AiPrivacyScope.current ??
          (pureCalculation
              ? AiPrivacyPolicy(enabled: readPrivacyEnabled?.call() ?? true)
              : await createPrivacyPolicy());
      final filtered = Map<String, Object?>.from(privacy.filter(result) as Map);
      return {
        'content': [
          {'type': 'text', 'text': jsonEncode(filtered)},
        ],
        'structuredContent': filtered,
        'isError': false,
      };
    } on AiToolException catch (error) {
      return failure(error.code, error.message);
    } catch (_) {
      return failure('operation_failed', '操作未完成，请在应用中查看当前状态');
    }
  }

  static Map<String, Object?> failure(String code, String message) {
    final result = {'code': code, 'message': message};
    return {
      'content': [
        {'type': 'text', 'text': jsonEncode(result)},
      ],
      'structuredContent': result,
      'isError': true,
    };
  }

  static Never _invalid() =>
      throw const AiToolException('invalid_arguments', '工具参数不正确');

  static void _checkKeys(Map<String, Object?> values, Set<String> allowed) {
    if (values.keys.any((key) => !allowed.contains(key))) _invalid();
  }

  static const dataSources = [
    'academic_tools',
    'calendar',
    'schedule',
    'schedule_range',
    'curriculum',
    'smart_work',
    'messages',
    'contacts',
    'chat',
    'diary',
    'exams',
    'experiments',
    'controls',
    'page',
    'browser',
    'electricity',
    'apps',
    'notices',
    'notice_detail',
    'school_calendar',
    'leave_draft',
    'capabilities',
    'classrooms',
  ];

  Map<String, Object?> _listActions(Map<String, Object?> args) {
    _checkKeys(args, {'query', 'category', 'offset', 'limit'});
    for (final key in ['query', 'category']) {
      if (args.containsKey(key) &&
          (args[key] is! String ||
              (args[key] as String).length > (key == 'query' ? 128 : 96))) {
        _invalid();
      }
    }
    final offset = args.containsKey('offset') ? args['offset'] : 0;
    final limit = args.containsKey('limit') ? args['limit'] : 20;
    if (offset is! int ||
        offset < 0 ||
        limit is! int ||
        limit < 1 ||
        limit > 50) {
      _invalid();
    }
    final query = (args['query'] as String? ?? '').trim().toLowerCase();
    final category = args['category'] as String?;
    final authSystem = _readAccount()?.authSystem;
    final filtered = actions
        .where(
          (action) =>
              (category == null ||
                  AiBusinessDiscovery.inCategory(
                    category,
                    action.id.split('.').first,
                    text: '${action.id} ${action.title} ${action.description}',
                  )) &&
              AiBusinessDiscovery.matches(
                query,
                '${action.id} ${action.title} ${action.description}',
                category: action.id.split('.').first,
              ),
        )
        .toList();
    return {
      'total': filtered.length,
      'offset': offset,
      'nextOffset': offset + limit < filtered.length ? offset + limit : null,
      'categories': actions
          .map((action) => action.id.split('.').first)
          .toSet()
          .toList(),
      'actions': [
        for (final action in filtered.skip(offset).take(limit))
          AiBusinessCapabilities.describeAction(action, authSystem: authSystem),
      ],
    };
  }

  Future<Map<String, Object?>> _getData(Map<String, Object?> args) async {
    _checkKeys(args, {
      'source',
      'date',
      'fromDate',
      'toDate',
      'completed',
      'earlyOnly',
      'query',
      'section',
      'id',
      'year',
      'offset',
      'platform',
      'module',
      'semesterIndex',
      'status',
      'term',
      'limit',
    });
    final source = args['source'];
    if (source is! String || !dataSources.contains(source)) _invalid();
    for (final key in ['date', 'fromDate', 'toDate']) {
      if (!args.containsKey(key)) continue;
      final raw = args[key];
      if (raw is! String || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(raw)) {
        _invalid();
      }
      final parsed = DateTime.tryParse(raw);
      if (parsed == null || parsed.toIso8601String().substring(0, 10) != raw) {
        _invalid();
      }
    }
    if (args.containsKey('fromDate') &&
        args.containsKey('toDate') &&
        (args['fromDate'] as String).compareTo(args['toDate'] as String) > 0) {
      _invalid();
    }
    if (args.containsKey('completed') &&
        (source != 'experiments' || args['completed'] is! bool)) {
      _invalid();
    }
    if (args.containsKey('earlyOnly') &&
        (source != 'schedule_range' || args['earlyOnly'] is! bool)) {
      _invalid();
    }
    if (args.containsKey('query') &&
        (!const {
              'controls',
              'smart_work',
              'notices',
              'school_calendar',
              'apps',
              'curriculum',
              'capabilities',
              'classrooms',
              'academic_tools',
              'contacts',
              'chat',
            }.contains(source) ||
            args['query'] is! String ||
            (args['query'] as String).length > 128)) {
      _invalid();
    }
    if (args.containsKey('section') &&
        (!const {
              'smart_work',
              'capabilities',
              'classrooms',
              'academic_tools',
            }.contains(source) ||
            args['section'] is! String ||
            (args['section'] as String).length > 128)) {
      _invalid();
    }
    if (args.containsKey('year') &&
        (source != 'school_calendar' ||
            args['year'] is! String ||
            (args['year'] as String).length > 32)) {
      _invalid();
    }
    if ((source == 'notice_detail' && !args.containsKey('id')) ||
        (args.containsKey('id') &&
            (!{'notice_detail', 'chat'}.contains(source) ||
                args['id'] is! String ||
                (args['id'] as String).trim().isEmpty ||
                (args['id'] as String).length > 256))) {
      _invalid();
    }
    if (source == 'experiments' &&
        const ['date', 'fromDate', 'toDate'].any(args.containsKey)) {
      _invalid();
    }
    if (args.containsKey('term') &&
        (args['term'] is! String || (args['term'] as String).length > 128)) {
      _invalid();
    }
    if (source == 'curriculum' && args.containsKey('term')) _invalid();
    for (final key in ['platform', 'module', 'status']) {
      if (args.containsKey(key) &&
          (source != 'curriculum' ||
              args[key] is! String ||
              (args[key] as String).length > 128)) {
        _invalid();
      }
    }
    if (args.containsKey('offset') &&
        (!const {
              'curriculum',
              'school_calendar',
              'academic_tools',
              'classrooms',
              'chat',
              'contacts',
            }.contains(source) ||
            args['offset'] is! int ||
            (args['offset'] as int) < 0)) {
      _invalid();
    }
    if (args.containsKey('semesterIndex') &&
        (source != 'curriculum' ||
            args['semesterIndex'] is! int ||
            (args['semesterIndex'] as int) < 1 ||
            (args['semesterIndex'] as int) > 30)) {
      _invalid();
    }
    final limit = args.containsKey('limit') ? args['limit'] : 20;
    if (limit is! int || limit < 1 || limit > 100) _invalid();
    if (source == 'capabilities') {
      return AiBusinessCapabilities.read(
        actions,
        {...args, 'limit': limit},
        tools: tools,
        authSystem: _readAccount()?.authSystem,
      );
    }
    final account = _readAccount();
    if (account == null && source != 'controls') {
      throw const AiToolException('no_active_account', '请先在应用中选择账户');
    }
    final reader = readData;
    if (reader == null) {
      throw const AiToolException('data_unavailable', '此数据当前未提供');
    }
    // Never inherit an action's ticket for a snapshot-only reader.
    final result = await networkScope.readLocal(
      () => reader(source, Map.unmodifiable({...args, 'limit': limit})),
    );
    if (_readAccount()?.accountId != account?.accountId) {
      throw const AiToolException('account_changed', '账户已切换，请重新查询');
    }
    return result;
  }

  Map<String, Object?> _getScores(Map<String, Object?> args) {
    _checkKeys(args, {
      'term',
      'year',
      'course',
      'offset',
      'limit',
      'includeDetails',
    });
    final year = args['year'];
    if (args.containsKey('year') &&
        (year is! int || year < 1900 || year > 9999)) {
      _invalid();
    }
    for (final key in ['term', 'course']) {
      if (args.containsKey(key) &&
          (args[key] is! String || (args[key] as String).length > 128)) {
        _invalid();
      }
    }
    final offset = args.containsKey('offset') ? args['offset'] : 0;
    final limit = args.containsKey('limit') ? args['limit'] : 100;
    final includeDetails = args.containsKey('includeDetails')
        ? args['includeDetails']
        : false;
    if (offset is! int ||
        offset < 0 ||
        limit is! int ||
        limit < 1 ||
        limit > 200 ||
        includeDetails is! bool) {
      _invalid();
    }
    final account = _readAccount();
    if (account == null) {
      throw const AiToolException('no_active_account', '请先在应用中选择账户');
    }
    if (!account.matchesAccount) {
      throw const AiToolException('scores_not_ready', '当前账户成绩尚未就绪');
    }
    final snapshot = account.scores;
    final entries = AiScoreAnalysis.select(snapshot, args);
    final records = entries.map((entry) => entry.record).toList();
    return {
      'accountLabel': account.displayName,
      'updatedAt': account.updatedAt?.toUtc().toIso8601String(),
      'demoMode': account.demoMode,
      'terms': snapshot.terms,
      'total': records.length,
      'offset': offset,
      'nextOffset': offset + limit < records.length ? offset + limit : null,
      'summary': {
        ...AiScoreAnalysis.summary(records),
        'pageGpa': snapshot.pageGpa,
      },
      'definitions': AiScoreAnalysis.definitions,
      'records': [
        for (final entry in entries.skip(offset).take(limit))
          {
            ...entry.toJson(),
            'courseType': entry.record.courseType,
            'examType': entry.record.examType,
            'examScore': entry.record.examScore,
            'retestScore': entry.record.retestScore,
            'retakeScore': entry.record.retakeScore,
            'finalScoreType': entry.record.finalScoreType,
            if (includeDetails)
              'detail': _detail(snapshot.detailFor(entry.record)),
          },
      ],
    };
  }

  static Map<String, Object?>? _detail(ScoreDetailRecord? record) =>
      record == null
      ? null
      : {
          'usualScore': record.usualScore,
          'usualWeight': record.usualWeight,
          'finalExamScore': record.finalExamScore,
          'finalScore': record.finalScore,
          'remark': record.remark,
        };

  Future<Map<String, Object?>> invokeManualAction(
    String actionId,
    Map<String, Object?> arguments,
  ) async {
    try {
      if (_closed) throw const AiToolException('bridge_closed', 'AI 连接已关闭');
      final result = await networkScope.runManual(
        () => _invokeAction({
          'actionId': actionId,
          'arguments': arguments,
        }, fromAi: false),
      );
      return {
        'content': [
          {'type': 'text', 'text': jsonEncode(result)},
        ],
        'structuredContent': result,
        'isError': false,
      };
    } on AiToolException catch (error) {
      return failure(error.code, error.message);
    } catch (_) {
      return failure('operation_failed', '操作未完成，请在应用中查看当前状态');
    }
  }

  Future<Map<String, Object?>> _invokeAction(
    Map<String, Object?> args, {
    bool fromAi = true,
    bool Function()? isCancelled,
  }) async {
    _checkKeys(args, {'actionId', 'arguments'});
    if (args['actionId'] is! String) _invalid();
    final raw = args.containsKey('arguments')
        ? args['arguments']
        : <String, Object?>{};
    if (raw is! Map<String, Object?>) _invalid();
    final action = _actions[args['actionId']];
    if (action == null) {
      throw const AiToolException('unknown_action', '此操作当前未提供');
    }
    final error = action.validateArguments(raw);
    if (error != null) throw AiToolException('invalid_arguments', error);
    if (fromAi && action.id == 'account.switch') {
      final target = await _resolveAccount(raw['accountRef']);
      if (!(AiMultiAccountScope.current?.canSwitch(target) ?? false)) {
        throw const AiToolException(
          'multi_account_not_requested',
          '请明确选择本次要切换的账户',
        );
      }
    }
    if (fromAi &&
        RegExp(r'^accounts?\.').hasMatch(action.id) &&
        !const {
          'account.switch',
          'accounts.close',
          'accounts.open',
        }.contains(action.id)) {
      throw const AiToolException(
        'account_operation_protected',
        '请在账户管理中完成此操作',
      );
    }
    if (_pendingActions.containsKey(action.id) ||
        _pendingActions.keys.any(
          (id) => _actions[id]?.featureId == action.featureId,
        )) {
      throw const AiToolException('action_busy', '上一项操作仍在进行');
    }
    if (!action.available) {
      final required = AiBusinessCapabilities.requiredSystem(action.id);
      final current = _readAccount()?.authSystem;
      if (required != null && current != null && current != required) {
        throw const AiToolException(
          'auth_system_required',
          '此功能属于移动华交。可询问用户是否切换到移动华交，其速度更快、功能更全；等待用户确认后再继续。',
        );
      }
      throw const AiToolException('action_unavailable', '此操作当前不可用');
    }
    _activeActions++;
    notifyContextChanged();
    var expired = false;
    Timer? cancellationTimer;
    final cancelled = Completer<void>();
    try {
      final operation = Future<void>.sync(() async {
        final values = Map<String, Object?>.unmodifiable(raw);
        final accountId = _readAccount()?.accountId;
        final approval = AiAgentScope.current?.approve ?? beforeAction;
        if (fromAi && approval != null && !await approval(action, values)) {
          throw const AiToolException('action_not_approved', '此操作未获准执行');
        }
        if (expired || (isCancelled?.call() ?? false)) {
          throw const AiToolException('action_cancelled', '此操作已取消');
        }
        if (_closed ||
            !identical(_actions[action.id], action) ||
            !action.available) {
          throw const AiToolException('action_unavailable', '此操作当前不可用');
        }
        if (_readAccount()?.accountId != accountId) {
          throw const AiToolException('account_changed', '账户已切换，请重新发起操作');
        }
        if (fromAi) {
          await networkScope.run(action.featureId, () => action.invoke(values));
        } else {
          await action.invoke(values);
        }
      });
      _pendingActions[action.id] = operation;
      void releasePending() {
        if (identical(_pendingActions[action.id], operation)) {
          _pendingActions.remove(action.id);
          notifyContextChanged();
        }
      }

      unawaited(
        operation.then<void>(
          (_) => releasePending(),
          onError: (Object _, StackTrace _) => releasePending(),
        ),
      );
      if (fromAi && isCancelled != null) {
        cancellationTimer = Timer.periodic(const Duration(milliseconds: 100), (
          _,
        ) {
          if (isCancelled() && !cancelled.isCompleted) {
            expired = true;
            cancelled.completeError(
              const AiToolException('action_cancelled', '此操作已取消'),
            );
          }
        });
      }
      if (fromAi) {
        await Future.any<void>([operation, cancelled.future]).timeout(
          action.id == 'academic.workbooks.download'
              ? const Duration(minutes: 2)
              : actionTimeout,
          onTimeout: () {
            expired = true;
            throw const AiToolException('action_timeout', '操作仍在处理中，请查看状态后继续');
          },
        );
      } else {
        await operation;
      }
      return {
        'actionId': action.id,
        'status': 'completed',
        if (action.readResult != null) 'result': action.readResult!(raw),
      };
    } finally {
      cancellationTimer?.cancel();
      // Pending callbacks keep their per-action guard after the global gate is
      // released; a caller timeout must not permit a duplicate network operation.
      _activeActions--;
      notifyContextChanged();
    }
  }
}
