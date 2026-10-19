// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:convert';
import 'dart:io';

final _readOnlyChecks = <String, Future<bool>>{};

Future<bool> aiReadOnlyPowerShell(String executable, String command) {
  final key = '$executable\n$command';
  if (_readOnlyChecks.length >= 128) _readOnlyChecks.clear();
  return _readOnlyChecks.putIfAbsent(key, () async {
    final data = base64Encode(utf8.encode(command));
    final script =
        r'''
$source=[Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('__INPUT__'))
$tokens=$null; $errors=$null
$tree=[Management.Automation.Language.Parser]::ParseInput($source,[ref]$tokens,[ref]$errors)
if($errors.Count){exit 1}
$types=@('ScriptBlockAst','NamedBlockAst','StatementBlockAst','PipelineAst','CommandAst','CommandParameterAst','CommandExpressionAst','StringConstantExpressionAst','ExpandableStringExpressionAst','ConstantExpressionAst','VariableExpressionAst','ArrayLiteralAst','ArrayExpressionAst','ParenExpressionAst','SubExpressionAst','BinaryExpressionAst','UnaryExpressionAst','AssignmentStatementAst','ForEachStatementAst')
$commands=@('Get-ChildItem','Get-Content','Test-Path','Get-Item','Get-Location','Get-Command','Select-Object','Sort-Object','Measure-Object','Write-Output','Out-String','Format-Table','Format-List','Join-Path','Split-Path','Resolve-Path')
foreach($node in $tree.FindAll({param($n) $true},$true)) {
 if($node.GetType().Name -notin $types){exit 1}
 if($node -is [Management.Automation.Language.CommandAst]) {
  $name=$node.GetCommandName()
  if(!$name -or $name -notin $commands){exit 1}
  if($name -eq 'Get-Command') {
   if($node.Extent.Text.Trim() -notmatch '^Get-Command\s+(?:-Name\s+)?[A-Za-z0-9_.-]+(?:\s*,\s*[A-Za-z0-9_.-]+)*(?:\s+-ErrorAction\s+(?:SilentlyContinue|Stop|Continue))?$'){exit 1}
  }
 }
 if($node -is [Management.Automation.Language.AssignmentStatementAst]) {
  if($node.Left -isnot [Management.Automation.Language.VariableExpressionAst]){exit 1}
  $name=$node.Left.VariablePath.UserPath
  if($name.Contains(':') -or $name -match '^PS|^ExecutionContext$|^Host$'){exit 1}
 }
 if($node -is [Management.Automation.Language.ForEachStatementAst]) {
  $name=$node.Variable.VariablePath.UserPath
  if($name.Contains(':') -or $name -match '^PS|^ExecutionContext$|^Host$'){exit 1}
 }
}
exit 0
'''
            .replaceFirst('__INPUT__', data);
    final encoded = base64Encode([
      for (final unit in script.codeUnits) ...[unit & 255, unit >> 8],
    ]);
    try {
      final result = await Process.run(executable, [
        '-NoLogo',
        '-NoProfile',
        '-OutputFormat',
        'Text',
        '-EncodedCommand',
        encoded,
      ]).timeout(const Duration(seconds: 5));
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  });
}
