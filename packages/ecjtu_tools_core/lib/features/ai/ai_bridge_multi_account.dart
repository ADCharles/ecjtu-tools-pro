// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

part of 'ai_bridge.dart';

extension _AiBridgeMultiAccount on AiBridge {
  void _checkAfterAccountSwitch(String tool) {
    final grant = AiMultiAccountScope.current;
    if (grant == null ||
        grant.initialAccountId == null ||
        grant.initialAccountId == _readAccount()?.accountId)
      return;
    if (!const {
      'ecjtu_get_status',
      'ecjtu_list_accounts',
      'ecjtu_get_account_data',
    }.contains(tool)) {
      throw const AiToolException(
        'account_task_completed',
        '账户已切换，请继续提出需要完成的任务',
      );
    }
  }

  List<Map<String, Object?>> get _multiAccountTools => [
    AiBridge._tool(
      'ecjtu_list_accounts',
      '列出匿名账户目录，使用目录的账户编号选择本次任务明确指定的账户',
      AiBridge._schema({}),
    ),
    AiBridge._tool(
      'ecjtu_get_account_data',
      '读取本次任务指定账户的缓存成绩或某天完整日历；成绩含本地计算的统计供比较，缓存缺失不发请求',
      AiBridge._schema(
        {
          'accountRef': {'type': 'string', 'maxLength': 96},
          'source': {
            'type': 'string',
            'enum': ['scores', 'calendar'],
          },
          'date': {'type': 'string', 'maxLength': 10},
          'term': {'type': 'string', 'maxLength': 128},
          'limit': {'type': 'integer', 'minimum': 1, 'maximum': 200},
        },
        required: ['accountRef', 'source'],
      ),
    ),
  ];

  void _checkMultiAccount() {
    if (!multiAccountEnabled)
      throw const AiToolException('multi_account_disabled', '请先在设置中开启多账户数据交互');
  }

  Future<List<AiMultiAccountTarget>> _localAccountDirectory() async {
    _checkMultiAccount();
    final accounts = await networkScope.readLocal(
      () => readAccounts?.call() ?? <AiMultiAccountTarget>[],
    );
    _checkMultiAccount();
    if (accounts.map((a) => a.accountId).toSet().length != accounts.length) {
      throw const AiToolException('account_directory_unavailable', '账户目录暂不可用');
    }
    return [for (final account in accounts) _updateAccountReference(account)];
  }

  AiMultiAccountTarget _updateAccountReference(AiMultiAccountTarget account) {
    final number =
        _accountReferences[account.accountId]?.number ?? ++_accountSerial;
    return _accountReferences[account.accountId] = AiMultiAccountTarget(
      accountId: account.accountId,
      displayName: account.displayName,
      accountRef: 'account-$number',
      number: number,
    );
  }

  Future<AiMultiAccountTarget> _resolveAccount(Object? ref) async {
    if (ref is! String || !RegExp(r'^account-\d+$').hasMatch(ref))
      AiBridge._invalid();
    final target = (await _localAccountDirectory())
        .where((a) => a.accountRef == ref)
        .firstOrNull;
    if (target == null)
      throw const AiToolException('account_not_found', '此账户当前不可用，请重新选择');
    return target;
  }

  Future<Map<String, Object?>> _multiAccountDirectory(
    Map<String, Object?> args,
  ) async {
    AiBridge._checkKeys(args, {});
    final current = _readAccount()?.accountId;
    return {
      'accounts': [
        for (final account in await _localAccountDirectory())
          {
            'accountRef': account.accountRef,
            'label': account.label,
            'current': account.accountId == current,
          },
      ],
    };
  }

  Future<Map<String, Object?>> _multiAccountData(
    Map<String, Object?> args, {
    bool Function()? isCancelled,
  }) async {
    AiBridge._checkKeys(args, {
      'accountRef',
      'source',
      'date',
      'term',
      'limit',
    });
    final source = args['source'];
    final limit = args['limit'] ?? 200;
    if (!const {'scores', 'calendar'}.contains(source) ||
        limit is! int ||
        limit < 1 ||
        limit > 200 ||
        (args.containsKey('term') &&
            (args['term'] is! String || (args['term'] as String).length > 128)))
      AiBridge._invalid();
    if (source == 'calendar' &&
        (args['date'] is! String ||
            !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(args['date'] as String)))
      AiBridge._invalid();
    if (source == 'scores' && args.containsKey('date')) {
      AiBridge._invalid();
    }
    if (source == 'calendar') {
      final date = args['date'] as String;
      if (DateTime.tryParse(date)?.toIso8601String().substring(0, 10) != date) {
        AiBridge._invalid();
      }
    }
    final target = await _resolveAccount(args['accountRef']);
    void check() {
      _checkMultiAccount();
      if (isCancelled?.call() ?? false)
        throw const AiToolException('action_cancelled', '此操作已取消');
      if (!(AiMultiAccountScope.current?.canRead(target, source as String) ??
          false)) {
        throw const AiToolException(
          'multi_account_not_requested',
          '请明确选择本次要查询或比较的账户',
        );
      }
    }

    check();
    final reader = readAccountData;
    if (reader == null)
      throw const AiToolException('data_unavailable', '此账户数据当前未提供');
    final data = await networkScope.readLocal(
      () => reader(target.accountId, source as String, {
        if (args.containsKey('term')) 'term': args['term'],
        if (args.containsKey('date')) 'date': args['date'],
        'limit': limit,
      }),
    );
    check();
    await _resolveAccount(target.accountRef);
    final anonymous =
        AiPrivacyPolicy(
              privateFields: {
                'identity:姓名': target.displayName,
                'identity:学号': target.accountId,
              },
            ).filter(data)
            as Map;
    return {
      ...Map<String, Object?>.from(anonymous),
      'accountRef': target.accountRef,
      'label': target.label,
      'cached': true,
    };
  }

  AiSemanticAction _multiAccountSwitchAction() => AiSemanticAction(
    id: 'account.switch',
    title: '切换指定账户',
    description: '切换到本次任务明确指定的匿名账户；仅恢复本地账户与缓存，不刷新其他账户',
    kind: AiActionKind.button,
    featureId: 'accounts',
    isAvailable: () => multiAccountEnabled,
    arguments: [
      AiActionArgument(
        name: 'accountRef',
        title: '账户',
        required: true,
        maxLength: 96,
      ),
    ],
    invoke: (args) async {
      final target = await _resolveAccount(args['accountRef']);
      if (!(AiMultiAccountScope.current?.canSwitch(target) ?? false)) {
        throw const AiToolException(
          'multi_account_not_requested',
          '请明确选择本次要切换的账户',
        );
      }
      _switchingAccountId = target.accountId;
      try {
        await networkScope.readLocal(() => switchAccount!(target.accountId));
        if (_readAccount()?.accountId != target.accountId) {
          throw const AiToolException('account_changed', '账户切换未完成，请重新选择');
        }
      } finally {
        notifyContextChanged();
        _switchingAccountId = null;
      }
    },
  );
}

extension AiMultiAccountBridgeApi on AiBridge {
  Future<AiMultiAccountGrant> resolveAccountRequest(
    String userRequest, {
    bool Function()? isCancelled,
  }) async {
    if (!multiAccountEnabled)
      return AiMultiAccountGrant(isCancelled: isCancelled);
    return AiMultiAccountIntent.resolve(
      userRequest,
      await _localAccountDirectory(),
      currentAccountId: _readAccount()?.accountId,
      isCancelled: isCancelled,
    );
  }
}
