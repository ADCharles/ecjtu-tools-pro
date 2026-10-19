// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as image;
import '../../widgets/ecjtu_text_context_menu.dart';

import 'attachment_models.dart';

typedef AiClipboardImageReader = Future<Uint8List?> Function();

String? _imageExtension(Uint8List bytes) {
  if (bytes.length < 12) return null;
  if (bytes[0] == 137 && bytes[1] == 80 && bytes[2] == 78 && bytes[3] == 71)
    return 'png';
  if (bytes[0] == 255 && bytes[1] == 216 && bytes[2] == 255) return 'jpg';
  if (String.fromCharCodes(bytes.take(6)).startsWith('GIF8')) return 'gif';
  if (String.fromCharCodes(bytes.take(4)) == 'RIFF' &&
      String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP')
    return 'webp';
  return null;
}

Future<bool> pasteAiClipboardImage({
  required Future<void> Function(Iterable<AiAttachmentInput>) stage,
  AiClipboardImageReader? readImage,
  bool Function()? isCurrent,
}) async {
  Uint8List? bytes;
  try {
    bytes = await (readImage ?? () => Pasteboard.image)().timeout(
      const Duration(seconds: 10),
    );
  } on MissingPluginException {
    return isCurrent?.call() == false;
  } on PlatformException {
    return isCurrent?.call() == false;
  } on TimeoutException {
    return isCurrent?.call() == false;
  } catch (_) {
    return isCurrent?.call() == false;
  }
  if (isCurrent?.call() == false) return true;
  if (bytes == null) return false;
  return insertAiClipboardImage(bytes, stage: stage);
}

Future<bool> insertAiClipboardImage(
  Uint8List bytes, {
  required Future<void> Function(Iterable<AiAttachmentInput>) stage,
}) async {
  if (bytes.length >= 54 && bytes[0] == 0x42 && bytes[1] == 0x4d) {
    final normalized = await compute(
      _clipboardBitmapToPng,
      bytes,
      debugLabel: 'ai-clipboard-bitmap',
    );
    if (normalized == null) return false;
    bytes = normalized;
  }
  final extension = _imageExtension(bytes);
  if (extension == null) return false;
  await stage([AiAttachmentInput(name: '粘贴图片.$extension', bytes: bytes)]);
  return true;
}

Uint8List? _clipboardBitmapToPng(Uint8List bytes) {
  if (bytes.length > 32 * 1024 * 1024) return null;
  final header = ByteData.sublistView(bytes);
  if (header.getUint32(14, Endian.little) < 40) return null;
  final width = header.getInt32(18, Endian.little).abs();
  final height = header.getInt32(22, Endian.little).abs();
  if (width == 0 || height == 0 || width * height > 20 * 1024 * 1024)
    return null;
  try {
    final decoded = image.decodeBmp(bytes);
    return decoded == null
        ? null
        : Uint8List.fromList(image.encodePng(decoded));
  } catch (_) {
    return null;
  }
}

class AiChatImagePasteScope extends StatelessWidget {
  const AiChatImagePasteScope({
    super.key,
    required this.onPasteImage,
    required this.child,
  });
  final Future<bool> Function() onPasteImage;
  final Widget child;

  @override
  Widget build(BuildContext context) => Actions(
    actions: {PasteTextIntent: _AiImagePasteAction(onPasteImage)},
    child: child,
  );
}

class _AiImagePasteAction extends ContextAction<PasteTextIntent> {
  _AiImagePasteAction(this.onPasteImage);
  final Future<bool> Function() onPasteImage;

  @override
  Future<Object?> invoke(
    PasteTextIntent intent, [
    BuildContext? context,
  ]) async {
    final fallback = callingAction;
    if (await onPasteImage()) return null;
    if (context != null && !context.mounted) return null;
    if (fallback is ContextAction<PasteTextIntent>)
      return fallback.invoke(intent, context);
    return fallback?.invoke(intent);
  }
}

Widget aiImagePasteContextMenu(
  BuildContext context,
  EditableTextState editable, {
  required Future<bool> Function() onPasteImage,
}) {
  final items = editable.contextMenuButtonItems.toList();
  void paste() {
    editable.hideToolbar();
    unawaited(() async {
      if (!await onPasteImage() && editable.mounted) {
        await editable.pasteText(SelectionChangedCause.toolbar);
      }
    }());
  }

  final index = items.indexWhere(
    (item) => item.type == ContextMenuButtonType.paste,
  );
  final item = ContextMenuButtonItem(
    type: ContextMenuButtonType.paste,
    onPressed: paste,
  );
  if (index < 0) {
    items.insert(0, item);
  } else {
    items[index] = item;
  }
  return buildEcjtuContextMenu(context, items, editable.contextMenuAnchors);
}
