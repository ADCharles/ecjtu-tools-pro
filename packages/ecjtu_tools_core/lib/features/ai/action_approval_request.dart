// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

class AiActionApprovalRequest {
  const AiActionApprovalRequest({
    required this.id,
    required this.title,
    required this.details,
  });
  final int id;
  final String title, details;
  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'details': details,
  };
  factory AiActionApprovalRequest.fromJson(Map json) => AiActionApprovalRequest(
    id: json['id'] as int,
    title: json['title'] as String,
    details: json['details'] as String,
  );
}
