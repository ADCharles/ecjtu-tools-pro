// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

class SmartWorkPersonalMenuItem {
  const SmartWorkPersonalMenuItem({required this.name, required this.url});

  final String name;
  final String url;

  factory SmartWorkPersonalMenuItem.fromJson(Object? value) {
    final map = _map(value);
    return SmartWorkPersonalMenuItem(
      name: _text(map['name']),
      url: _text(map['url']),
    );
  }

  Map<String, dynamic> toJson() => {'name': name, 'url': url};
}

class SmartWorkSessionSnapshot {
  const SmartWorkSessionSnapshot({
    this.studentId = '',
    this.authenticated = false,
    this.pending = false,
    this.expiresAt = 0,
    this.error = '',
  });

  final String studentId;
  final bool authenticated;
  final bool pending;
  final int expiresAt;
  final String error;
}

class SmartWorkServiceMenuItem {
  const SmartWorkServiceMenuItem({
    required this.category,
    required this.name,
    required this.url,
    this.icon = '',
  });

  final String category;
  final String name;
  final String url;
  final String icon;

  factory SmartWorkServiceMenuItem.fromJson(Object? value) {
    final map = _map(value);
    return SmartWorkServiceMenuItem(
      category: _text(map['category']),
      name: _text(map['name']),
      url: _text(map['url']),
      icon: _text(map['icon']),
    );
  }

  Map<String, dynamic> toJson() => {
    'category': category,
    'name': name,
    'url': url,
    'icon': icon,
  };
}

class SmartWorkFamilyMember {
  const SmartWorkFamilyMember({
    this.name = '',
    this.relation = '',
    this.birthday = '',
    this.age = '',
    this.phone = '',
    this.workplace = '',
  });

  final String name;
  final String relation;
  final String birthday;
  final String age;
  final String phone;
  final String workplace;

  factory SmartWorkFamilyMember.fromJson(Object? value) {
    final map = _map(value);
    return SmartWorkFamilyMember(
      name: _text(map['name']),
      relation: _text(map['relation']),
      birthday: _text(map['birthday']),
      age: _text(map['age']),
      phone: _text(map['phone']),
      workplace: _text(map['workplace']),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'relation': relation,
    'birthday': birthday,
    'age': age,
    'phone': phone,
    'workplace': workplace,
  };
}

class SmartWorkDormitoryMember {
  const SmartWorkDormitoryMember({
    this.bed = '',
    this.name = '',
    this.sex = '',
    this.studentId = '',
    this.college = '',
    this.className = '',
  });

  final String bed;
  final String name;
  final String sex;
  final String studentId;
  final String college;
  final String className;

  factory SmartWorkDormitoryMember.fromJson(Object? value) {
    final map = _map(value);
    return SmartWorkDormitoryMember(
      bed: _text(map['bed']),
      name: _text(map['name']),
      sex: _text(map['sex']),
      studentId: _text(map['studentId']),
      college: _text(map['college']),
      className: _text(map['className']),
    );
  }

  Map<String, dynamic> toJson() => {
    'bed': bed,
    'name': name,
    'sex': sex,
    'studentId': studentId,
    'college': college,
    'className': className,
  };
}

class SmartWorkStudentProfile {
  const SmartWorkStudentProfile({
    this.studentId = '',
    this.name = '',
    this.avatar = '',
    this.avatarUrl = '',
    this.sex = '',
    this.nation = '',
    this.nativePlace = '',
    this.politicalStatus = '',
    this.birthday = '',
    this.identityNumber = '',
    this.sourcePlace = '',
    this.religiousBelief = '',
    this.enrollmentStatus = '',
    this.admissionType = '',
    this.educationLevel = '',
    this.formerName = '',
    this.candidateNumber = '',
    this.studyYears = '',
    this.enrollmentNote = '',
    this.phone = '',
    this.email = '',
    this.qq = '',
    this.emergencyPhone = '',
    this.familyPhone = '',
    this.postcode = '',
    this.address = '',
    this.householdAddress = '',
    this.graduationSchool = '',
    this.familyMembers = const <SmartWorkFamilyMember>[],
    this.dormitoryLabel = '',
    this.dormitoryMembers = const <SmartWorkDormitoryMember>[],
    this.enrollmentChanges = const <Map<String, String>>[],
    this.sectionErrors = const <String, String>{},
  });

  final String studentId;
  final String name;
  final String avatar;
  final String avatarUrl;
  final String sex;
  final String nation;
  final String nativePlace;
  final String politicalStatus;
  final String birthday;
  final String identityNumber;
  final String sourcePlace;
  final String religiousBelief;
  final String enrollmentStatus;
  final String admissionType;
  final String educationLevel;
  final String formerName;
  final String candidateNumber;
  final String studyYears;
  final String enrollmentNote;
  final String phone;
  final String email;
  final String qq;
  final String emergencyPhone;
  final String familyPhone;
  final String postcode;
  final String address;
  final String householdAddress;
  final String graduationSchool;
  final List<SmartWorkFamilyMember> familyMembers;
  final String dormitoryLabel;
  final List<SmartWorkDormitoryMember> dormitoryMembers;
  final List<Map<String, String>> enrollmentChanges;
  final Map<String, String> sectionErrors;

  factory SmartWorkStudentProfile.fromJson(Object? value) {
    final map = _map(value);
    final family = _list(
      map['familyMembers'],
    ).map(SmartWorkFamilyMember.fromJson).toList(growable: false);
    final dormitory = _list(
      map['dormitoryMembers'],
    ).map(SmartWorkDormitoryMember.fromJson).toList(growable: false);
    final changes = _list(map['enrollmentChanges'])
        .map((item) => _stringMap(item))
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    return SmartWorkStudentProfile(
      studentId: _text(map['studentId']),
      name: _text(map['name']),
      avatar: _text(map['avatar']),
      avatarUrl: _text(map['avatarUrl']),
      sex: _text(map['sex']),
      nation: _text(map['nation']),
      nativePlace: _text(map['nativePlace']),
      politicalStatus: _text(map['politicalStatus']),
      birthday: _text(map['birthday']),
      identityNumber: _text(map['identityNumber']),
      sourcePlace: _text(map['sourcePlace']),
      religiousBelief: _text(map['religiousBelief']),
      enrollmentStatus: _text(map['enrollmentStatus']),
      admissionType: _text(map['admissionType']),
      educationLevel: _text(map['educationLevel']),
      formerName: _text(map['formerName']),
      candidateNumber: _text(map['candidateNumber']),
      studyYears: _text(map['studyYears']),
      enrollmentNote: _text(map['enrollmentNote']),
      phone: _text(map['phone']),
      email: _text(map['email']),
      qq: _text(map['qq']),
      emergencyPhone: _text(map['emergencyPhone']),
      familyPhone: _text(map['familyPhone']),
      postcode: _text(map['postcode']),
      address: _text(map['address']),
      householdAddress: _text(map['householdAddress']),
      graduationSchool: _text(map['graduationSchool']),
      familyMembers: family,
      dormitoryLabel: _text(map['dormitoryLabel']),
      dormitoryMembers: dormitory,
      enrollmentChanges: changes,
      sectionErrors: _stringMap(map['sectionErrors']),
    );
  }

  Map<String, dynamic> toJson() => {
    'studentId': studentId,
    'name': name,
    'avatar': avatar,
    'avatarUrl': avatarUrl,
    'sex': sex,
    'nation': nation,
    'nativePlace': nativePlace,
    'politicalStatus': politicalStatus,
    'birthday': birthday,
    'identityNumber': identityNumber,
    'sourcePlace': sourcePlace,
    'religiousBelief': religiousBelief,
    'enrollmentStatus': enrollmentStatus,
    'admissionType': admissionType,
    'educationLevel': educationLevel,
    'formerName': formerName,
    'candidateNumber': candidateNumber,
    'studyYears': studyYears,
    'enrollmentNote': enrollmentNote,
    'phone': phone,
    'email': email,
    'qq': qq,
    'emergencyPhone': emergencyPhone,
    'familyPhone': familyPhone,
    'postcode': postcode,
    'address': address,
    'householdAddress': householdAddress,
    'graduationSchool': graduationSchool,
    'familyMembers': familyMembers.map((item) => item.toJson()).toList(),
    'dormitoryLabel': dormitoryLabel,
    'dormitoryMembers': dormitoryMembers.map((item) => item.toJson()).toList(),
    'enrollmentChanges': enrollmentChanges,
    'sectionErrors': sectionErrors,
  };
}

class SmartWorkSportGrade {
  const SmartWorkSportGrade({
    this.term = '',
    this.totalScore = '',
    this.deferredScore = '',
    this.retestScore = '',
    this.correctionScore = '',
    this.rewardScore = '',
  });

  final String term;
  final String totalScore;
  final String deferredScore;
  final String retestScore;
  final String correctionScore;
  final String rewardScore;

  factory SmartWorkSportGrade.fromJson(Object? value) {
    final map = _map(value);
    return SmartWorkSportGrade(
      term: _text(map['term']),
      totalScore: _text(map['totalScore']),
      deferredScore: _text(map['deferredScore']),
      retestScore: _text(map['retestScore']),
      correctionScore: _text(map['correctionScore']),
      rewardScore: _text(map['rewardScore']),
    );
  }

  Map<String, dynamic> toJson() => {
    'term': term,
    'totalScore': totalScore,
    'deferredScore': deferredScore,
    'retestScore': retestScore,
    'correctionScore': correctionScore,
    'rewardScore': rewardScore,
  };
}

class SmartWorkScholarship {
  const SmartWorkScholarship({
    this.term = '',
    this.name = '',
    this.courseScore = '',
  });

  final String term;
  final String name;
  final String courseScore;

  factory SmartWorkScholarship.fromJson(Object? value) {
    final map = _map(value);
    return SmartWorkScholarship(
      term: _text(map['term']),
      name: _text(map['name']),
      courseScore: _text(map['courseScore']),
    );
  }

  Map<String, dynamic> toJson() => {
    'term': term,
    'name': name,
    'courseScore': courseScore,
  };
}

class SmartWorkEvaluation {
  const SmartWorkEvaluation({
    this.batchName = '',
    this.score = '',
    this.scholarship = '',
  });

  final String batchName;
  final String score;
  final String scholarship;

  factory SmartWorkEvaluation.fromJson(Object? value) {
    final map = _map(value);
    return SmartWorkEvaluation(
      batchName: _text(map['batchName']),
      score: _text(map['score']),
      scholarship: _text(map['scholarship']),
    );
  }

  Map<String, dynamic> toJson() => {
    'batchName': batchName,
    'score': score,
    'scholarship': scholarship,
  };
}

class SmartWorkGenericRecords {
  const SmartWorkGenericRecords({
    required this.name,
    required this.records,
    this.url = '',
    this.source = '',
    this.apply = false,
    this.updatedAt,
  });

  final String name;
  final List<Map<String, String>> records;
  final String url;
  final String source;
  final bool apply;
  final DateTime? updatedAt;

  factory SmartWorkGenericRecords.fromJson(Object? value, {String name = ''}) {
    final map = _map(value);
    final records = _list(
      map['records'],
    ).map(_stringMap).where((item) => item.isNotEmpty).toList(growable: false);
    return SmartWorkGenericRecords(
      name: _text(map['name']).isEmpty ? name : _text(map['name']),
      records: records,
      url: _text(map['url']),
      source: _text(map['source']),
      apply: map['apply'] == true,
      updatedAt: _date(map['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'records': records,
    'url': url,
    'source': source,
    'apply': apply,
    'updatedAt': updatedAt?.toIso8601String(),
  };
}

class SmartWorkPersonalSnapshot {
  const SmartWorkPersonalSnapshot({
    this.menuItems = const <SmartWorkPersonalMenuItem>[],
    this.menuUpdatedAt,
    this.studentProfile,
    this.studentUpdatedAt,
    this.sportGrades = const <SmartWorkSportGrade>[],
    this.sportUpdatedAt,
    this.scholarships = const <SmartWorkScholarship>[],
    this.scholarshipUpdatedAt,
    this.evaluations = const <SmartWorkEvaluation>[],
    this.evaluationUpdatedAt,
    this.serviceMenu = const <SmartWorkServiceMenuItem>[],
    this.serviceMenuUpdatedAt,
    this.genericRecords = const <String, SmartWorkGenericRecords>{},
  });

  final List<SmartWorkPersonalMenuItem> menuItems;
  final DateTime? menuUpdatedAt;
  final SmartWorkStudentProfile? studentProfile;
  final DateTime? studentUpdatedAt;
  final List<SmartWorkSportGrade> sportGrades;
  final DateTime? sportUpdatedAt;
  final List<SmartWorkScholarship> scholarships;
  final DateTime? scholarshipUpdatedAt;
  final List<SmartWorkEvaluation> evaluations;
  final DateTime? evaluationUpdatedAt;
  final List<SmartWorkServiceMenuItem> serviceMenu;
  final DateTime? serviceMenuUpdatedAt;
  final Map<String, SmartWorkGenericRecords> genericRecords;

  SmartWorkPersonalSnapshot copyWith({
    List<SmartWorkPersonalMenuItem>? menuItems,
    DateTime? menuUpdatedAt,
    SmartWorkStudentProfile? studentProfile,
    DateTime? studentUpdatedAt,
    List<SmartWorkSportGrade>? sportGrades,
    DateTime? sportUpdatedAt,
    List<SmartWorkScholarship>? scholarships,
    DateTime? scholarshipUpdatedAt,
    List<SmartWorkEvaluation>? evaluations,
    DateTime? evaluationUpdatedAt,
    List<SmartWorkServiceMenuItem>? serviceMenu,
    DateTime? serviceMenuUpdatedAt,
    Map<String, SmartWorkGenericRecords>? genericRecords,
  }) {
    return SmartWorkPersonalSnapshot(
      menuItems: menuItems ?? this.menuItems,
      menuUpdatedAt: menuUpdatedAt ?? this.menuUpdatedAt,
      studentProfile: studentProfile ?? this.studentProfile,
      studentUpdatedAt: studentUpdatedAt ?? this.studentUpdatedAt,
      sportGrades: sportGrades ?? this.sportGrades,
      sportUpdatedAt: sportUpdatedAt ?? this.sportUpdatedAt,
      scholarships: scholarships ?? this.scholarships,
      scholarshipUpdatedAt: scholarshipUpdatedAt ?? this.scholarshipUpdatedAt,
      evaluations: evaluations ?? this.evaluations,
      evaluationUpdatedAt: evaluationUpdatedAt ?? this.evaluationUpdatedAt,
      serviceMenuUpdatedAt: serviceMenuUpdatedAt ?? this.serviceMenuUpdatedAt,
      serviceMenu: serviceMenu ?? this.serviceMenu,
      genericRecords: genericRecords ?? this.genericRecords,
    );
  }

  factory SmartWorkPersonalSnapshot.fromJson(Object? value) {
    final map = _map(value);
    final generic = <String, SmartWorkGenericRecords>{};
    final genericMap = _map(map['genericRecords']);
    genericMap.forEach((key, item) {
      generic[key] = SmartWorkGenericRecords.fromJson(item, name: key);
    });
    return SmartWorkPersonalSnapshot(
      menuItems: _list(map['menuItems'])
          .map(SmartWorkPersonalMenuItem.fromJson)
          .where((item) => item.name.isNotEmpty && item.url.isNotEmpty)
          .toList(growable: false),
      menuUpdatedAt: _date(map['menuUpdatedAt']),
      studentProfile: map['studentProfile'] == null
          ? null
          : SmartWorkStudentProfile.fromJson(map['studentProfile']),
      studentUpdatedAt: _date(map['studentUpdatedAt']),
      sportGrades: _list(
        map['sportGrades'],
      ).map(SmartWorkSportGrade.fromJson).toList(growable: false),
      sportUpdatedAt: _date(map['sportUpdatedAt']),
      scholarships: _list(
        map['scholarships'],
      ).map(SmartWorkScholarship.fromJson).toList(growable: false),
      scholarshipUpdatedAt: _date(map['scholarshipUpdatedAt']),
      evaluations: _list(
        map['evaluations'],
      ).map(SmartWorkEvaluation.fromJson).toList(growable: false),
      evaluationUpdatedAt: _date(map['evaluationUpdatedAt']),
      serviceMenu: _list(
        map['serviceMenu'],
      ).map(SmartWorkServiceMenuItem.fromJson).toList(growable: false),
      serviceMenuUpdatedAt: _date(map['serviceMenuUpdatedAt']),
      genericRecords: generic,
    );
  }

  Map<String, dynamic> toJson() => {
    'menuItems': menuItems.map((item) => item.toJson()).toList(),
    'menuUpdatedAt': menuUpdatedAt?.toIso8601String(),
    'studentProfile': studentProfile?.toJson(),
    'studentUpdatedAt': studentUpdatedAt?.toIso8601String(),
    'sportGrades': sportGrades.map((item) => item.toJson()).toList(),
    'sportUpdatedAt': sportUpdatedAt?.toIso8601String(),
    'scholarships': scholarships.map((item) => item.toJson()).toList(),
    'scholarshipUpdatedAt': scholarshipUpdatedAt?.toIso8601String(),
    'evaluations': evaluations.map((item) => item.toJson()).toList(),
    'genericRecords': genericRecords.map(
      (key, value) => MapEntry(key, value.toJson()),
    ),
    'evaluationUpdatedAt': evaluationUpdatedAt?.toIso8601String(),
    'serviceMenu': serviceMenu.map((item) => item.toJson()).toList(),
    'serviceMenuUpdatedAt': serviceMenuUpdatedAt?.toIso8601String(),
  };
}

class SmartWorkPersonalLoadResult {
  const SmartWorkPersonalLoadResult({
    required this.snapshot,
    this.failures = const <String>[],
    this.sessionExpired = false,
  });

  final SmartWorkPersonalSnapshot snapshot;
  final List<String> failures;
  final bool sessionExpired;
}

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

List<Object?> _list(Object? value) => value is List ? value : const <Object?>[];

Map<String, String> _stringMap(Object? value) {
  final result = <String, String>{};
  _map(value).forEach((key, item) {
    if (item == null || item is Map || item is List) return;
    final text = item.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
    if (text.isNotEmpty) result[key] = text;
  });
  return result;
}

String _text(Object? value) => value?.toString().trim() ?? '';

DateTime? _date(Object? value) {
  final text = _text(value);
  return text.isEmpty ? null : DateTime.tryParse(text);
}
