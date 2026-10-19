// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'ai_models.dart';

class AiInstalledSkill {
  const AiInstalledSkill(this.id, this.name, this.description, this.directory);
  final String id, name, description, directory;
  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'directory': directory,
    'instructionPath': p.join(directory, 'SKILL.md'),
  };
}

class AiAgentResourceLibrary {
  static const preferencesKey = 'assistant.external.resources.v1';
  final String home;
  AiAgentResourceLibrary({String? home})
    : home =
          home ??
          Platform.environment['USERPROFILE'] ??
          Platform.environment['HOME'] ??
          '';
  bool get supported =>
      Platform.isWindows || Platform.isMacOS || Platform.isLinux;

  List<String> get defaults => home.isEmpty
      ? []
      : [
          p.join(home, '.agents', 'skills'),
          p.join(home, '.pi', 'agent', 'skills'),
          p.join(home, '.codex', 'skills'),
        ];

  Future<
    ({
      List<String> roots,
      bool globalInstructions,
      List<String> instructionFiles,
    })
  >
  settings() async {
    if (!supported)
      return (
        roots: <String>[],
        globalInstructions: false,
        instructionFiles: <String>[],
      );
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(preferencesKey);
    if (raw == null)
      return (
        roots: defaults,
        globalInstructions: false,
        instructionFiles: <String>[],
      );
    final json = jsonDecode(raw) as Map;
    return (
      roots: List<String>.from(json['roots'] as List),
      globalInstructions: json['globalInstructions'] == true,
      instructionFiles: (json['instructionFiles'] as List? ?? const [])
          .whereType<String>()
          .toList(),
    );
  }

  Future<void> save(
    List<String> roots,
    bool globalInstructions, {
    List<String>? instructionFiles,
  }) async {
    if (!supported || roots.length > 16)
      throw const AiToolException('skill_configuration', '技能目录无法保存');
    final canonical = <String>[];
    for (final root in roots.toSet()) {
      if (!p.isAbsolute(root) || root.startsWith(r'\\'))
        throw const AiToolException('invalid_path', '请选择本机技能目录');
      // Default discovery roots may not exist on a fresh installation.
      canonical.add(
        await Directory(root).exists()
            ? await Directory(root).resolveSymbolicLinks()
            : p.normalize(root),
      );
    }
    final files = instructionFiles ?? (await settings()).instructionFiles;
    if (files.length > 16 ||
        files.any((file) => !p.isAbsolute(file) || file.startsWith(r'\\')))
      throw const AiToolException('invalid_path', '请选择本机指令文件');
    await (await SharedPreferences.getInstance()).setString(
      preferencesKey,
      jsonEncode({
        'roots': canonical,
        'globalInstructions': globalInstructions,
        'instructionFiles': files.toSet().toList(),
      }),
    );
  }

  Future<String?> _readWithin(
    String root,
    String path, {
    int maxBytes = 65536,
  }) async {
    final file = File(path);
    if (!await file.exists()) return null;
    final canonicalRoot = await Directory(root).resolveSymbolicLinks();
    final target = await file.resolveSymbolicLinks();
    if (!p.isWithin(canonicalRoot, target) ||
        await File(target).length() > maxBytes)
      return null;
    return File(target).readAsString();
  }

  Future<List<AiInstalledSkill>> discover() async {
    final config = await settings();
    final skills = <String, AiInstalledSkill>{};
    for (final root in config.roots) {
      if (!await Directory(root).exists()) continue;
      final candidates = <String>[root];
      await for (final entry in Directory(root).list(followLinks: false)) {
        if (entry is Directory) candidates.add(entry.path);
        if (candidates.length > 256) break;
      }
      for (final candidate in candidates) {
        final text = await _readWithin(root, p.join(candidate, 'SKILL.md'));
        if (text == null) continue;
        String field(String key) =>
            RegExp('^$key:\\s*(.+)\$', multiLine: true)
                .firstMatch(text)
                ?.group(1)
                ?.trim()
                .replaceAll(RegExp(r'''^['" ]|['" ]$'''), '') ??
            '';
        final name = field('name');
        final description = field('description');
        final canonical = await Directory(candidate).resolveSymbolicLinks();
        final id = sha256
            .convert(utf8.encode(canonical))
            .toString()
            .substring(0, 24);
        skills[id] = AiInstalledSkill(
          id,
          name.isEmpty ? p.basename(candidate) : name,
          description.length > 400
              ? description.substring(0, 400)
              : description,
          canonical,
        );
      }
    }
    return skills.values.take(256).toList();
  }

  Future<String> readSkill(String id, {String resource = 'SKILL.md'}) async {
    return (await readSkillResource(id, resource: resource))['text'] as String;
  }

  Future<Map<String, Object?>> readSkillResource(
    String id, {
    String resource = 'SKILL.md',
  }) async {
    final skill = (await discover())
        .where((skill) => skill.id == id)
        .firstOrNull;
    if (skill == null || p.isAbsolute(resource) || resource.length > 512)
      throw const AiToolException('skill_unavailable', '未找到该技能资源');
    final content = await _readWithin(
      skill.directory,
      p.join(skill.directory, resource),
    );
    if (content == null)
      throw const AiToolException('skill_resource_denied', '该资源不在技能目录内或超出读取范围');
    return {
      'text': content,
      'directory': skill.directory,
      'path': await File(
        p.join(skill.directory, resource),
      ).resolveSymbolicLinks(),
    };
  }

  Future<String> globalInstructions() async {
    final config = await settings();
    if (!config.globalInstructions) return '';
    final instructions = <String>[];
    for (final path in config.instructionFiles) {
      final root = p.dirname(path);
      if (!await Directory(root).exists()) continue;
      final text = await _readWithin(root, path, maxBytes: 32768);
      if (text != null && text.trim().isNotEmpty) instructions.add(text.trim());
    }
    return instructions.join('\n\n');
  }
}
