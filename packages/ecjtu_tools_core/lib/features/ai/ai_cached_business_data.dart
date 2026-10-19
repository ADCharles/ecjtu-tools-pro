// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import '../electricity/electricity_models.dart';
import '../enhancements/enhancement_models.dart';
import '../workbench/smart_work_models.dart';

/// Converts cached business models to the labels used by their pages.
class AiCachedBusinessData {
  static Map<String, Object?> smartWork(
    SmartWorkPersonalSnapshot snapshot,
    Map<String, Object?> args,
  ) {
    final profile = snapshot.studentProfile;
    final sections = <Map<String, Object?>>[];
    void add(
      String id,
      String title,
      bool available,
      DateTime? updatedAt,
      List<Map<String, Object?>> records, {
      List<Map<String, Object?>> fields = const [],
    }) {
      sections.add({
        'id': id,
        'title': title,
        'path': ['智慧学工', '学工信息', title],
        'available': available,
        'updatedAt': updatedAt?.toIso8601String(),
        'records': records,
        if (fields.isNotEmpty) 'fields': fields,
      });
    }

    add(
      'profile',
      '学籍信息',
      profile != null,
      snapshot.studentUpdatedAt,
      [],
      fields: profile == null
          ? []
          : _fields({
              '学号': profile.studentId,
              '姓名': profile.name,
              '性别': profile.sex,
              '民族': profile.nation,
              '籍贯': profile.nativePlace,
              '政治面貌': profile.politicalStatus,
              '出生日期': profile.birthday,
              '身份状态': profile.enrollmentStatus,
              '入学类别': profile.admissionType,
              '培养层次': profile.educationLevel,
              '考生号': profile.candidateNumber,
              '生源地': profile.sourcePlace,
              '学习年限': profile.studyYears,
              '学籍备注': profile.enrollmentNote,
              '联系电话': profile.phone,
              '电子邮箱': profile.email,
              'QQ号码': profile.qq,
              '紧急联系号码': profile.emergencyPhone,
              '家庭联系号码': profile.familyPhone,
              '邮政编码': profile.postcode,
              '家庭住址': profile.address,
              '户籍地址': profile.householdAddress,
              '毕业中学': profile.graduationSchool,
              '宗教信仰': profile.religiousBelief,
              '身份证号': _maskIdentity(profile.identityNumber),
            }),
    );
    add('family', '家庭信息', profile != null, snapshot.studentUpdatedAt, [
      for (final member
          in profile?.familyMembers ?? const <SmartWorkFamilyMember>[])
        {
          'fields': _fields({
            '姓名': member.name,
            '关系': member.relation,
            '出生日期': member.birthday,
            '年龄': member.age,
            '联系方式': member.phone,
            '工作单位': member.workplace,
          }),
        },
    ]);
    add(
      'dormitory',
      '宿舍信息',
      profile != null,
      snapshot.studentUpdatedAt,
      [
        for (final member
            in profile?.dormitoryMembers ?? const <SmartWorkDormitoryMember>[])
          {
            'title': [
              member.name,
              member.bed,
            ].where((v) => v.isNotEmpty).join(' · '),
            'fields': _fields({
              '学号': member.studentId,
              '学院': member.college,
              '班级': member.className,
            }),
          },
      ],
      fields: _fields({'宿舍': profile?.dormitoryLabel ?? ''}),
    );
    add('changes', '学籍异动', profile != null, snapshot.studentUpdatedAt, [
      for (final record
          in profile?.enrollmentChanges ?? const <Map<String, String>>[])
        {
          'fields': _fields({
            '异动操作': _pick(record, ['异动操作', 'operation', 'operate', 'action']),
            '类型': _pick(record, ['类型', 'type', 'changeType']),
            '原专业班级': _pick(record, [
              '原专业班级',
              'oldClass',
              'beforeClass',
              'oldbjname',
            ]),
            '新专业班级': _pick(record, [
              '新专业班级',
              'newClass',
              'afterClass',
              'newbjname',
            ]),
            '异动时间': _pick(record, [
              '异动时间',
              'changeTime',
              'createtime',
              'updatetime',
            ]),
            '原因': _pick(record, ['原因', 'reason', 'remark', 'beizhu']),
          }),
        },
    ]);
    final term = args['term'] as String?;
    add(
      'sport',
      '体测成绩',
      snapshot.sportUpdatedAt != null || snapshot.sportGrades.isNotEmpty,
      snapshot.sportUpdatedAt,
      [
        for (final grade in snapshot.sportGrades.where(
          (g) => term == null || g.term == term,
        ))
          {
            'title': grade.term,
            'term': grade.term,
            'fields': _fields({
              '总分': grade.totalScore,
              '缓测分': grade.deferredScore,
              '补测分': grade.retestScore,
              '更正分': grade.correctionScore,
              '奖励分': grade.rewardScore,
            }),
          },
      ],
    );
    add(
      'scholarships',
      '我的奖学金',
      snapshot.scholarshipUpdatedAt != null || snapshot.scholarships.isNotEmpty,
      snapshot.scholarshipUpdatedAt,
      [
        for (final scholarship in snapshot.scholarships.where(
          (s) => term == null || s.term == term,
        ))
          {
            'term': scholarship.term,
            'fields': _fields({
              '学年学期': scholarship.term,
              '奖学金': scholarship.name,
              '课程成绩': scholarship.courseScore,
            }),
          },
      ],
    );
    add(
      'evaluation',
      '综测信息',
      snapshot.evaluationUpdatedAt != null || snapshot.evaluations.isNotEmpty,
      snapshot.evaluationUpdatedAt,
      [
        for (final evaluation in snapshot.evaluations)
          {
            'title': evaluation.batchName,
            'fields': _fields({
              'F': evaluation.score,
              '奖学金': evaluation.scholarship,
            }),
          },
      ],
    );
    for (final entry in snapshot.genericRecords.entries) {
      final cached = entry.value;
      final title = cached.name.isEmpty ? entry.key : cached.name;
      final columns = cached.records.isEmpty
          ? <String>[]
          : cached.records.first.keys.toList();
      add(title, title, true, cached.updatedAt, [
        for (final record in cached.records)
          if (term == null || _pick(record, ['学年学期', '学期', '学年']) == term)
            {
              'fields': title == '我的荣誉'
                  ? _honor(record)
                  : _fields({
                      for (final column in columns)
                        if (_visibleLabel(column)) column: record[column] ?? '',
                    }),
            },
      ]);
    }
    for (final name in snapshot.menuItems.map((m) => m.name)) {
      if (name.isEmpty ||
          sections.any((s) => s['title'] == name) ||
          name == '个人信息') {
        continue;
      }
      add(name, name, false, null, []);
    }
    final section = (args['section'] as String? ?? '').trim();
    final query = (args['query'] as String? ?? '').trim().toLowerCase();
    final limit = args['limit'] as int? ?? 20;
    final filtered = sections
        .where(
          (s) => section.isEmpty || section == s['id'] || section == s['title'],
        )
        .where(
          (s) =>
              query.isEmpty ||
              '${s['title']} ${s['fields']} ${s['records']}'
                  .toLowerCase()
                  .contains(query),
        )
        .toList();
    final profileErrors = profile?.sectionErrors ?? const <String, String>{};
    for (final section in sections) {
      final error = profileErrors[section['id']];
      if (error != null && error.isNotEmpty) {
        section['error'] = error;
        if ((section['records'] as List).isEmpty &&
            !section.containsKey('fields')) {
          section['available'] = false;
        }
      }
    }
    return {
      'title': '智慧学工',
      'available': filtered.any((s) => s['available'] == true),
      'total': filtered.length,
      'sections': [
        for (final s in filtered.take(limit))
          {
            for (final entry in s.entries)
              if (entry.key != 'records' &&
                  (entry.key != 'fields' ||
                      section.isNotEmpty ||
                      query.isNotEmpty))
                entry.key: entry.value,
            'total': (s['records'] as List?)?.length ?? 0,
            if (section.isNotEmpty || query.isNotEmpty)
              'records': [
                for (final r
                    in (s['records'] as List? ?? const [])
                        .where(
                          (r) =>
                              query.isEmpty ||
                              (s['title'] as String).toLowerCase().contains(
                                query,
                              ) ||
                              r.toString().toLowerCase().contains(query),
                        )
                        .take(limit))
                  r,
              ],
          },
      ],
      'services': [
        for (final item
            in snapshot.serviceMenu
                .where(
                  (m) =>
                      query.isEmpty ||
                      '${m.category} ${m.name}'.toLowerCase().contains(query),
                )
                .take(limit))
          {
            'category': item.category.isEmpty ? '其他功能' : item.category,
            'title': item.name,
          },
      ],
      'hint': '通过 section 读取对应业务记录；请假申请属于智慧学工，快速请假用于预填后打开申请。',
    };
  }

  static Map<String, Object?> electricitySnapshot({
    Map<String, Object?>? snapshot,
    ElectricityPendingPayment? payment,
    List<String> customAmounts = const [],
    int limit = 20,
  }) => electricity(
    state: snapshot?['state'] is Map
        ? ElectricityRechargeState.fromJson(snapshot!['state'])
        : null,
    updatedAt: snapshot?['updatedAt'] as String?,
    payment: payment,
    customAmounts: customAmounts,
    limit: limit,
  );

  static Map<String, Object?> electricity({
    ElectricityRechargeState? state,
    ElectricityPendingPayment? payment,
    List<String> customAmounts = const [],
    String? updatedAt,
    int limit = 20,
  }) => {
    'title': '电费充值',
    'available': state != null || payment != null,
    'updatedAt': updatedAt,
    'balanceAvailable': state != null && state.balance.isNotEmpty,
    'balance': state?.balance,
    'fields': [
      for (final field
          in state?.accountFields ?? const <ElectricityAccountField>[])
        if (field.show &&
            !_sensitiveLabel(field.name) &&
            _safeValue(field.value))
          {'label': field.name, 'value': field.value, 'unit': field.unit},
    ],
    'location': [
      for (final selector
          in state?.selectors ?? const <ElectricityLocationSelector>[])
        {
          'name': selector.type,
          'label': _locationLabel(selector.type),
          'selected': selector.selected,
          'value': selector.options
              .where((o) => o.id == selector.selected)
              .firstOrNull
              ?.name,
          'options': [
            for (final option in selector.options.take(limit))
              {'value': option.id, 'label': option.name},
          ],
          'total': selector.options.length,
        },
    ],
    'amounts': [
      for (final amount
          in (state?.amounts ?? const <ElectricityAmountOption>[]).take(limit))
        {'value': amount.amount, 'label': amount.name},
    ],
    'customAmounts': customAmounts.take(limit).toList(),
    'paymentMethods': [
      for (final method
          in (state?.paymentMethods ?? const <ElectricityPaymentMethod>[]).take(
            limit,
          ))
        {'label': method.name},
    ],
    'lastOrder': payment == null
        ? null
        : {
            'title': '上一次订单',
            'fields': _fields({
              '房间': payment.roomName,
              '充值金额': payment.amount,
              '状态': payment.statusMessage,
            }),
            'status': payment.status,
            'createdAt': payment.createdAt.toIso8601String(),
          },
    'definitions': {
      'fields': '电费页面实际账户字段，label/value/unit 对应显示名称、原值和单位；剩余电量或余额以这些字段为准。',
      'balance': '服务返回的余额原值，未标明单位时不能当作剩余度数。',
      'lastOrder': '上一次充值订单；充值金额不是当前余额或剩余电量。',
    },
  };

  static Map<String, Object?> leaveDraft(QuickLeaveDraft? draft) => {
    'title': '快速请假',
    'available': draft != null,
    'fields': draft == null
        ? <Object?>[]
        : _fields({
            '开始日期': draft.startDate,
            '开始时间': draft.startTime,
            '结束日期': draft.endDate,
            '结束时间': draft.endTime,
            '请假类型': draft.leaveType,
            '请假审批': draft.approval,
            '是否离校': draft.campusStatus,
            '目的地': draft.destination,
            '紧急联系人': draft.emergencyContact,
            '联系方式': draft.contact,
            '离校日期': draft.leaveCampusDate,
            '返校日期': draft.returnSchoolDate,
            '请假事由': draft.reason,
          }),
    'application': {'module': '智慧学工', 'effect': '预填后打开请假申请，提交由申请页面完成'},
  };

  static List<Map<String, Object?>> _fields(Map<String, String> values) => [
    for (final entry in values.entries)
      if (entry.value.trim().isNotEmpty && _safeValue(entry.value))
        {'label': entry.key, 'value': entry.value},
  ];

  static String _pick(Map<String, String> record, List<String> keys) {
    for (final key in keys) {
      final value = record[key]?.trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  static List<Map<String, Object?>> _honor(
    Map<String, String> record,
  ) => _fields({
    '学年': _pick(record, [
      '学年',
      '学年学期',
      'academicyear',
      'xnxq',
      'schoolYear',
      'year',
    ]),
    '荣誉名称': _pick(record, [
      '荣誉名称',
      '获奖名称',
      '奖项名称',
      'awardname',
      'awardName',
      'honorName',
      'name',
      'title',
    ]),
    '姓名': _pick(record, ['姓名', '学生姓名', 'xm', 'studentName']),
    '颁发日期': record['awardyear']?.isNotEmpty == true
        ? '${record['awardyear']}年${record['awardmonth']?.isNotEmpty == true ? '${record['awardmonth']}月' : ''}'
        : _pick(record, [
            '颁发日期',
            '获奖日期',
            '日期',
            'issueDate',
            'awardDate',
            'createTime',
          ]),
  });

  static bool _visibleLabel(String label) =>
      RegExp(r'[\u4e00-\u9fff]').hasMatch(label) && !_sensitiveLabel(label);
  static bool _sensitiveLabel(String label) => RegExp(
    r'密码|口令|令牌|凭据|链接|地址.*URL|证书.*(路径|地址)|token|password|cookie|url',
    caseSensitive: false,
  ).hasMatch(label);
  static bool _safeValue(String value) => !RegExp(
    r'https?://|javascript:|<[^>]*>|(?:token|password|cookie|authorization)\s*[=:]',
    caseSensitive: false,
  ).hasMatch(value);
  static String _maskIdentity(String value) {
    final text = value.trim();
    return text.length <= 4
        ? '*' * text.length
        : '${text.substring(0, 2)}${'*' * (text.length - 4)}${text.substring(text.length - 2)}';
  }

  static String _locationLabel(String type) => switch (type) {
    'bigArea' => '校区',
    'area' => '区域',
    'building' => '楼栋',
    'unit' => '单元',
    'level' => '楼层 / 单元',
    'room' => '房间',
    'subArea' => '分区',
    _ => '位置',
  };
}
