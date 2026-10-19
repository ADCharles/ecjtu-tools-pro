// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

class QuickLeaveDraft {
  const QuickLeaveDraft({
    required this.startDate,
    required this.startTime,
    required this.endDate,
    required this.endTime,
    this.leaveType = '事假',
    this.approval = '请假：一天以内',
    this.campusStatus = '在校',
    this.destination = '',
    this.emergencyContact = '',
    this.contact = '',
    this.leaveCampusDate = '',
    this.returnSchoolDate = '',
    this.reason = '',
    this.templateName = '',
  });

  final String startDate;
  final String startTime;
  final String endDate;
  final String endTime;
  final String leaveType;
  final String approval;
  final String campusStatus;
  final String destination;
  final String emergencyContact;
  final String contact;
  final String leaveCampusDate;
  final String returnSchoolDate;
  final String reason;
  final String templateName;

  factory QuickLeaveDraft.initial() {
    final now = DateTime.now();
    final start = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute,
    ).add(const Duration(minutes: 1));
    // End time starts equal to the start time; the user adds duration with
    // the "+" control (each click appends to the current end time).
    return QuickLeaveDraft(
      startDate: _dateText(start),
      startTime: _timeText(start),
      endDate: _dateText(start),
      endTime: _timeText(start),
    );
  }

  QuickLeaveDraft copyWith({
    String? startDate,
    String? startTime,
    String? endDate,
    String? endTime,
    String? leaveType,
    String? approval,
    String? campusStatus,
    String? destination,
    String? emergencyContact,
    String? contact,
    String? leaveCampusDate,
    String? returnSchoolDate,
    String? reason,
    String? templateName,
  }) {
    return QuickLeaveDraft(
      startDate: startDate ?? this.startDate,
      startTime: startTime ?? this.startTime,
      endDate: endDate ?? this.endDate,
      endTime: endTime ?? this.endTime,
      leaveType: leaveType ?? this.leaveType,
      approval: approval ?? this.approval,
      campusStatus: campusStatus ?? this.campusStatus,
      destination: destination ?? this.destination,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      contact: contact ?? this.contact,
      leaveCampusDate: leaveCampusDate ?? this.leaveCampusDate,
      returnSchoolDate: returnSchoolDate ?? this.returnSchoolDate,
      reason: reason ?? this.reason,
      templateName: templateName ?? this.templateName,
    );
  }

  QuickLeaveTemplate toTemplate(String name) {
    return QuickLeaveTemplate(
      name: name,
      startDate: startDate,
      startTime: startTime,
      endDate: endDate,
      endTime: endTime,
      leaveType: leaveType,
      approval: approval,
      campusStatus: campusStatus,
      destination: destination,
      emergencyContact: emergencyContact,
      contact: contact,
      leaveCampusDate: leaveCampusDate,
      returnSchoolDate: returnSchoolDate,
      reason: reason,
    );
  }
}

class QuickLeaveTemplate {
  const QuickLeaveTemplate({
    required this.name,
    required this.startDate,
    required this.startTime,
    required this.endDate,
    required this.endTime,
    required this.leaveType,
    required this.approval,
    required this.campusStatus,
    required this.destination,
    required this.emergencyContact,
    required this.contact,
    required this.leaveCampusDate,
    required this.returnSchoolDate,
    required this.reason,
  });

  final String name;
  final String startDate;
  final String startTime;
  final String endDate;
  final String endTime;
  final String leaveType;
  final String approval;
  final String campusStatus;
  final String destination;
  final String emergencyContact;
  final String contact;
  final String leaveCampusDate;
  final String returnSchoolDate;
  final String reason;

  QuickLeaveDraft toDraft() {
    return QuickLeaveDraft(
      startDate: startDate,
      startTime: startTime,
      endDate: endDate,
      endTime: endTime,
      leaveType: leaveType,
      approval: approval,
      campusStatus: campusStatus,
      destination: destination,
      emergencyContact: emergencyContact,
      contact: contact,
      leaveCampusDate: leaveCampusDate,
      returnSchoolDate: returnSchoolDate,
      reason: reason,
    );
  }

  factory QuickLeaveTemplate.fromJson(Object? value) {
    final map = value is Map ? value : const <Object?, Object?>{};
    String text(String key) => map[key]?.toString() ?? '';
    return QuickLeaveTemplate(
      name: text('name'),
      startDate: text('startDate'),
      startTime: text('startTime'),
      endDate: text('endDate'),
      endTime: text('endTime'),
      leaveType: text('leaveType').isEmpty ? '事假' : text('leaveType'),
      approval: text('approval').isEmpty ? '请假：一天以内' : text('approval'),
      campusStatus: text('campusStatus').isEmpty ? '在校' : text('campusStatus'),
      destination: text('destination'),
      emergencyContact: text('emergencyContact'),
      contact: text('contact'),
      leaveCampusDate: text('leaveCampusDate'),
      returnSchoolDate: text('returnSchoolDate'),
      reason: text('reason'),
    );
  }

  Map<String, String> toJson() => {
    'name': name,
    'startDate': startDate,
    'startTime': startTime,
    'endDate': endDate,
    'endTime': endTime,
    'leaveType': leaveType,
    'approval': approval,
    'campusStatus': campusStatus,
    'destination': destination,
    'emergencyContact': emergencyContact,
    'contact': contact,
    'leaveCampusDate': leaveCampusDate,
    'returnSchoolDate': returnSchoolDate,
    'reason': reason,
  };
}

String _dateText(DateTime value) {
  return '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}

String? validateQuickLeaveDraft(
  QuickLeaveDraft draft, {
  DateTime? now,
  bool requireFutureStart = true,
}) {
  DateTime? parse(String date, String time) {
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date) ||
        !RegExp(r'^\d{2}:\d{2}$').hasMatch(time))
      return null;
    final parsed = DateTime.tryParse('${date}T$time');
    return parsed != null &&
            _dateText(parsed) == date &&
            _timeText(parsed) == time
        ? parsed
        : null;
  }

  final start = parse(draft.startDate, draft.startTime),
      end = parse(draft.endDate, draft.endTime);
  if (start == null) return '请按 YYYY-MM-DD 和 HH:mm 格式填写开始时间。';
  if (end == null) return '请按 YYYY-MM-DD 和 HH:mm 格式填写结束时间。';
  final current = now ?? DateTime.now();
  if (requireFutureStart &&
      !start.isAfter(
        DateTime(
          current.year,
          current.month,
          current.day,
          current.hour,
          current.minute,
        ),
      ))
    return '开始时间必须晚于当前时间。';
  if (!end.isAfter(start)) return '结束时间必须晚于开始时间。';
  if (draft.reason.trim().isEmpty) return '请先填写请假事由。';
  if (draft.campusStatus != '在校' &&
      (draft.destination.trim().isEmpty ||
          draft.emergencyContact.trim().isEmpty ||
          draft.contact.trim().isEmpty ||
          draft.leaveCampusDate.isEmpty ||
          draft.returnSchoolDate.isEmpty))
    return '离校请假还需要填写目的地、紧急联系人、联系方式、离校时间和返校时间。';
  return null;
}

String _timeText(DateTime value) {
  return '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}
