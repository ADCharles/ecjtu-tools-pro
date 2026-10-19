// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../features/update/update_models.dart' show sha256Bytes;

String _windowIntentSignature(Map<String, Object?> value) {
  final args = Map<String, Object?>.from(value['arguments'] as Map);
  if (args['bytes'] case final Uint8List bytes) {
    args['bytes'] = {'length': bytes.length, 'digest': sha256Bytes(bytes)};
  }
  return sha256Bytes(utf8.encode(jsonEncode({...value, 'arguments': args})));
}

Future<String> _intentSignature(AiChatWindowIntent intent) {
  final value = intent.toMap();
  return intent.arguments['bytes'] is Uint8List
      ? compute(
          _windowIntentSignature,
          value,
          debugLabel: 'ai-window-image-intent',
        )
      : Future.value(_windowIntentSignature(value));
}

enum AiChatWindowOperation {
  send,
  enqueue,
  steer,
  stop,
  draft,
  newConversation,
  selectConversation,
  renameConversation,
  deleteConversation,
  moveConversation,
  compact,
  confirmPrivacy,
  confirmAction,
  openSettings,
  openAgent,
  changeModel,
  changeReasoning,
  setPermissionMode,
  setChatMode,
  setWorkspace,
  editUserMessage,
  regenerate,
  selectMessageVersion,
  settings,
  pickAttachments,
  removeAttachment,
  pasteImage,
  insertImage,
  readAttachment,
  downloadDocument,
  dock,
}

enum AiChatWindowSettingsSection { configuration, model, context, permissions }

class AiChatWindowIntent {
  const AiChatWindowIntent({
    required this.operation,
    required this.conversationId,
    this.arguments = const {},
  });

  final AiChatWindowOperation operation;
  final String? conversationId;
  final Map<String, Object?> arguments;

  factory AiChatWindowIntent.fromMap(Map value) {
    final name = value['operation'];
    final operation = AiChatWindowOperation.values
        .where((operation) => operation.name == name)
        .firstOrNull;
    final arguments = value['arguments'];
    if (operation == null ||
        value.keys.any(
          (key) =>
              !const {'operation', 'conversationId', 'arguments'}.contains(key),
        ) ||
        (value['conversationId'] != null &&
            value['conversationId'] is! String) ||
        arguments is! Map ||
        arguments.keys.any((key) => key is! String)) {
      throw PlatformException(code: 'invalid_window_intent');
    }
    return AiChatWindowIntent(
      operation: operation,
      conversationId: value['conversationId'] as String?,
      arguments: Map<String, Object?>.unmodifiable(
        Map<String, Object?>.from(arguments),
      ),
    );
  }

  Map<String, Object?> toMap() => {
    'operation': operation.name,
    'conversationId': conversationId,
    'arguments': arguments,
  };
}

/// The native second engine is a view; the owner passed here stays in AppShell.
class AiChatWindowHost extends ChangeNotifier {
  AiChatWindowHost({
    required this.owner,
    required this.readState,
    required this.onIntent,
    required this.onDock,
    this.channel = const MethodChannel('ecjtu/ai_chat_window'),
    this.readyTimeout = const Duration(seconds: 10),
    this.onReleased,
  }) {
    owner.addListener(_changed);
    channel.setMethodCallHandler(_nativeCall);
  }

  final Listenable owner;
  final Map<String, Object?> Function() readState;
  final FutureOr<Object?> Function(AiChatWindowIntent) onIntent;
  final VoidCallback onDock;
  final VoidCallback? onReleased;
  final Duration readyTimeout;
  final MethodChannel channel;
  String? _windowId;
  Completer<void>? _ready;
  Future<void>? _opening;
  int _revision = 0;
  bool _detached = false;
  bool _disposed = false;
  bool _publishing = false;
  bool _dirty = false;
  Timer? _publishTimer;
  String? _publishedConversation;
  List<Object?>? _publishedEntries;
  int _publishedRevision = -1;
  int _lastRequestId = 0;
  final _requests =
      <int, ({Future<String> signature, Future<Object?> result})>{};

  bool get detached => _detached;
  bool get opening => _opening != null;
  String? get windowId => _windowId;

  Map<String, Object?> _snapshot(String id, {bool incremental = false}) {
    final state = readState();
    final entries = state['entries'];
    final previous = _publishedEntries;
    Map<String, Object?> published = state;
    if (incremental &&
        entries is List &&
        previous != null &&
        state['conversationId'] == _publishedConversation) {
      published = {
        for (final field in state.entries)
          if (field.key != 'entries') field.key: field.value,
        'entriesDelta': {
          'baseRevision': _publishedRevision,
          'length': entries.length,
          'replacements': [
            for (var i = 0; i < entries.length; i++)
              if (i >= previous.length || !identical(previous[i], entries[i]))
                {'index': i, 'entry': entries[i]},
          ],
        },
      };
    }
    final revision = ++_revision;
    _publishedEntries = entries is List ? List<Object?>.of(entries) : null;
    _publishedConversation = state['conversationId'] as String?;
    _publishedRevision = revision;
    return {'windowId': id, 'revision': revision, 'state': published};
  }

  Future<void> detach() {
    if (_disposed) return Future.error(StateError('Window host disposed'));
    if (_opening != null) return _opening!;
    if (_detached) {
      return channel.invokeMethod<void>('focus', {'windowId': _windowId});
    }
    late final Future<void> opening;
    opening = _open().whenComplete(() {
      if (identical(_opening, opening)) _opening = null;
    });
    _opening = opening;
    return opening;
  }

  Future<void> _open() async {
    final random = Random.secure();
    final id =
        'aw_${List.generate(16, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join()}';
    _windowId = id;
    _requests.clear();
    _lastRequestId = 0;
    onReleased?.call();
    final ready = Completer<void>();
    _ready = ready;
    try {
      await channel
          .invokeMethod<void>('open', _snapshot(id))
          .timeout(readyTimeout);
      await ready.future.timeout(readyTimeout);
      if (_disposed || _windowId != id) {
        throw PlatformException(code: 'window_closed');
      }
      _detached = true;
      notifyListeners();
      _changed();
    } catch (_) {
      if (_windowId == id) _release(id);
      try {
        await channel.invokeMethod<void>('close', {'windowId': id});
      } catch (_) {}
      rethrow;
    } finally {
      if (identical(_ready, ready)) _ready = null;
    }
  }

  Future<void> dock() async {
    final id = _windowId;
    if (id == null) return;
    _release(id);
    await channel.invokeMethod<void>('close', {'windowId': id});
  }

  void _release(String id) {
    if (_windowId != id) return;
    _windowId = null;
    _detached = false;
    _publishTimer?.cancel();
    _publishTimer = null;
    _publishedEntries = null;
    _publishedConversation = null;
    _dirty = false;
    _requests.clear();
    _lastRequestId = 0;
    onReleased?.call();
    final ready = _ready;
    if (ready != null && !ready.isCompleted) ready.complete();
    if (!_disposed) {
      onDock();
      notifyListeners();
    }
  }

  Future<Object?> _nativeCall(MethodCall call) async {
    final args = call.arguments;
    if (_disposed ||
        args is! Map ||
        args['windowId'] != _windowId ||
        _windowId == null) {
      throw PlatformException(code: 'window_stale');
    }
    final id = _windowId!;
    if (call.method == 'ready') {
      final ready = _ready;
      if (ready != null && !ready.isCompleted) ready.complete();
      return _snapshot(id);
    }
    if (call.method == 'closed') {
      _release(id);
      return null;
    }
    if (call.method != 'intent' || !_detached) {
      throw PlatformException(code: 'window_not_ready');
    }
    final requestId = args['requestId'];
    final raw = args['intent'];
    if (requestId is! int || requestId < 1 || raw is! Map) {
      throw PlatformException(code: 'invalid_window_intent');
    }
    final intent = AiChatWindowIntent.fromMap(raw);
    final signature = _intentSignature(intent);
    final previous = _requests[requestId];
    if (previous != null) {
      if (await previous.signature != await signature) {
        throw PlatformException(code: 'duplicate_window_request');
      }
      return previous.result;
    }
    if (requestId <= _lastRequestId) {
      throw PlatformException(code: 'window_request_stale');
    }
    _lastRequestId = requestId;
    final result = Future<Object?>.sync(
      () => intent.operation == AiChatWindowOperation.dock
          ? dock().then((_) => null)
          : onIntent(intent),
    );
    _requests[requestId] = (signature: signature, result: result);
    if (intent.operation == AiChatWindowOperation.readAttachment) {
      unawaited(
        result.then<void>(
          (_) {
            if (identical(_requests[requestId]?.result, result)) {
              _requests.remove(requestId);
            }
          },
          onError: (Object _, StackTrace _) {
            if (identical(_requests[requestId]?.result, result)) {
              _requests.remove(requestId);
            }
          },
        ),
      );
    }
    if (_requests.length > 128) _requests.remove(_requests.keys.first);
    return result;
  }

  void refreshAppearance() => _changed();

  void _changed() {
    if (_disposed || !_detached || _windowId == null) return;
    _dirty = true;
    _publishTimer ??= Timer(const Duration(milliseconds: 50), () {
      _publishTimer = null;
      unawaited(_publish());
    });
  }

  Future<void> _publish() async {
    if (_publishing || _disposed) return;
    _publishing = true;
    try {
      if (_dirty && !_disposed && _detached) {
        _dirty = false;
        final id = _windowId;
        if (id != null) {
          try {
            await channel.invokeMethod<void>(
              'state',
              _snapshot(id, incremental: true),
            );
          } catch (_) {
            if (_windowId == id) _release(id);
          }
        }
      }
    } finally {
      _publishing = false;
      if (_dirty && !_disposed && _detached) _changed();
    }
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    owner.removeListener(_changed);
    _publishTimer?.cancel();
    channel.setMethodCallHandler(null);
    final id = _windowId;
    if (id != null) {
      _release(id);
      unawaited(
        channel
            .invokeMethod<void>('close', {'windowId': id})
            .catchError((Object _) {}),
      );
    }
    super.dispose();
  }
}

/// Display-side client. It cannot instantiate a provider, store, or bridge.
class AiChatWindowClient extends ChangeNotifier {
  AiChatWindowClient({
    required this.windowId,
    this.channel = const MethodChannel('ecjtu/ai_chat_window'),
  }) {
    channel.setMethodCallHandler((call) async {
      if (call.method == 'state') _accept(call.arguments);
      if (call.method == 'viewport' && call.arguments is Map) {
        maximized.value = (call.arguments as Map)['maximized'] == true;
        final args = call.arguments as Map;
        final width = args['width'];
        final height = args['height'];
        if (!_disposed &&
            width is num &&
            height is num &&
            width.isFinite &&
            height.isFinite &&
            width > 0 &&
            height > 0) {
          viewport.value = Size(width.toDouble(), height.toDouble());
        }
      }
    });
  }

  final String windowId;
  final MethodChannel channel;
  Map<String, Object?> _state = const {};
  final viewport = ValueNotifier<Size?>(null);
  final maximized = ValueNotifier<bool>(false);
  int _revision = -1;
  int _sequence = 0;
  bool _disposed = false;
  Map<String, Object?> get state => _state;
  int get revision => _revision;

  Future<void> initialize() async => _accept(
    await channel.invokeMethod<Object?>('ready', {'windowId': windowId}),
  );

  void _accept(Object? value) {
    if (_disposed || value is! Map || value['windowId'] != windowId) return;
    final revision = value['revision'];
    final state = value['state'];
    if (revision is! int || revision <= _revision || state is! Map) return;
    final next = Map<String, Object?>.from(state);
    final delta = next.remove('entriesDelta');
    if (delta is Map) {
      if (delta['baseRevision'] != _revision ||
          next['conversationId'] != _state['conversationId']) {
        unawaited(initialize().catchError((Object _) {}));
        return;
      }
      final length = delta['length'];
      final replacements = delta['replacements'];
      final previous = _state['entries'];
      if (length is! int ||
          length < 0 ||
          length > 131072 ||
          replacements is! List ||
          previous is! List)
        return;
      final entries = List<Object?>.generate(
        length,
        (i) => i < previous.length ? previous[i] : null,
      );
      for (final replacement in replacements) {
        if (replacement is! Map) return;
        final index = replacement['index'];
        final entry = replacement['entry'];
        if (index is! int || index < 0 || index >= length || entry is! Map)
          return;
        entries[index] = entry;
      }
      if (entries.any((entry) => entry is! Map)) return;
      next['entries'] = entries;
    }
    _revision = revision;
    _state = Map<String, Object?>.unmodifiable(next);
    notifyListeners();
  }

  Future<Object?> invoke(AiChatWindowIntent intent) {
    if (_disposed) return Future.error(StateError('Window client disposed'));
    return channel.invokeMethod<Object?>('intent', {
      'windowId': windowId,
      'requestId': ++_sequence,
      'intent': intent.toMap(),
    });
  }

  @override
  void dispose() {
    _disposed = true;
    channel.setMethodCallHandler(null);
    viewport.dispose();
    maximized.dispose();
    super.dispose();
  }
}
