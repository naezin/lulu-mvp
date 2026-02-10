import 'package:flutter/material.dart';

import '../../core/design_system/lulu_colors.dart';
import '../../core/design_system/lulu_icons.dart';
import '../../data/models/baby_type.dart';

/// Global ScaffoldMessenger key for cross-tab toast display
///
/// Sprint 21 Phase 3-1: Resolves toast not showing/hiding across tab navigation.
/// All SnackBar calls should use [AppToast] instead of ScaffoldMessenger.of(context).
final GlobalKey<ScaffoldMessengerState> appScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

/// App-wide toast utility using global ScaffoldMessenger
///
/// Ensures toasts are shown/hidden correctly regardless of which tab is active.
class AppToast {
  AppToast._();

  /// Show a SnackBar using the global ScaffoldMessenger
  static void show(SnackBar snackBar) {
    appScaffoldMessengerKey.currentState
      ?..clearSnackBars()
      ..showSnackBar(snackBar);
  }

  /// Show a simple text toast with optional action
  static void showText(
    String message, {
    Duration duration = const Duration(seconds: 2),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final snackBar = SnackBar(
      content: Text(message),
      duration: duration,
      action: actionLabel != null
          ? SnackBarAction(
              label: actionLabel,
              textColor: Colors.white,
              onPressed: onAction ?? () {},
            )
          : null,
    );
    show(snackBar);
  }

  /// Show activity-specific toast with type color and checkCircle icon
  ///
  /// [type] determines background color (LuluActivityColors)
  /// [summary] is the pre-formatted message (e.g., "분유 120ml 저장됨")
  static void showActivity(ActivityType type, String summary) {
    show(
      SnackBar(
        content: Row(
          children: [
            const Icon(LuluIcons.checkCircle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(summary)),
          ],
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _activityColor(type),
      ),
    );
  }

  /// Map ActivityType to LuluActivityColors
  static Color _activityColor(ActivityType type) {
    switch (type) {
      case ActivityType.feeding:
        return LuluActivityColors.feeding;
      case ActivityType.sleep:
        return LuluActivityColors.sleep;
      case ActivityType.diaper:
        return LuluActivityColors.diaper;
      case ActivityType.play:
        return LuluActivityColors.play;
      case ActivityType.health:
        return LuluActivityColors.health;
    }
  }

  /// Clear all currently showing SnackBars
  static void clear() {
    appScaffoldMessengerKey.currentState?.clearSnackBars();
  }
}
