import 'package:flutter/material.dart';

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

  /// Clear all currently showing SnackBars
  static void clear() {
    appScaffoldMessengerKey.currentState?.clearSnackBars();
  }
}
