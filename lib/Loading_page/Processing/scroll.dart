// lib/utils/scroll_sync.dart

import 'package:flutter/widgets.dart';

/// ScrollSyncer は 2 つの ScrollController のオフセットを同期します。
class ScrollSyncer {
  final ScrollController primary;
  final ScrollController secondary;

  ScrollSyncer({required this.primary, required this.secondary}) {
    _attach();
  }

  void _attach() {
    primary.addListener(_syncFromPrimary);
    secondary.addListener(_syncFromSecondary);
  }

  void _syncFromPrimary() {
    if (secondary.hasClients && secondary.offset != primary.offset) {
      secondary.jumpTo(primary.offset);
    }
  }

  void _syncFromSecondary() {
    if (primary.hasClients && primary.offset != secondary.offset) {
      primary.jumpTo(secondary.offset);
    }
  }

  /// リスナー解除
  void dispose() {
    primary.removeListener(_syncFromPrimary);
    secondary.removeListener(_syncFromSecondary);
  }
}
