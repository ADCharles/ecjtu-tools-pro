// Copyright (c) 2026 阿东Charles (ADCharles).
// SPDX-License-Identifier: GPL-3.0-only
// See LICENSE-ADDITIONAL.md for author attribution and adapter permissions.

import 'package:flutter/widgets.dart';

/// Keeps platform views attached when an earlier tab is removed or reordered.
class WebPaneStack extends StatelessWidget {
  const WebPaneStack({super.key, required this.index, required this.children});

  final int index;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      for (var i = 0; i < children.length; i++)
        Visibility(
          key: children[i].key,
          visible: i == index,
          maintainState: true,
          maintainAnimation: true,
          maintainSize: true,
          child: children[i],
        ),
    ],
  );
}
