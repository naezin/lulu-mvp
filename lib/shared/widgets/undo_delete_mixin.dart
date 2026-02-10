import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/activity_model.dart';
import '../../data/repositories/activity_repository.dart';
import '../../features/home/providers/home_provider.dart';
import '../../l10n/generated/app_localizations.dart' show S;
import '../../core/design_system/lulu_icons.dart';
import '../../core/utils/app_toast.dart';

/// Undo delete mixin
///
/// Sprint 21 Phase 3-1: GlobalKey ScaffoldMessenger for cross-tab toast.
/// - Stores ActivityModel in memory before delete
/// - Shows 5-second Undo toast via AppToast (global)
/// - Undo creates new UUID to avoid DB duplicate key
mixin UndoDeleteMixin<T extends StatefulWidget> on State<T> {
  final ActivityRepository _activityRepository = ActivityRepository();
  ActivityModel? _pendingDelete;

  /// Delete activity + show Undo toast
  Future<void> deleteActivityWithUndo({
    required ActivityModel activity,
    required HomeProvider homeProvider,
    required BuildContext context,
  }) async {
    // 1. Backup for undo
    _pendingDelete = activity;

    // Sprint 21 Phase 3-1: capture l10n before async gap
    final l10n = S.of(context);

    // 2. Delete immediately (DB + local state)
    try {
      await _activityRepository.deleteActivity(activity.id);
      homeProvider.removeActivity(activity.id);
    } catch (e) {
      _pendingDelete = null;
      AppToast.showText('Delete failed: $e');
      return;
    }

    // 3. Undo toast (5 seconds) via global ScaffoldMessenger
    AppToast.show(
      SnackBar(
        content: Row(
          children: [
            const Icon(LuluIcons.checkCircleOutline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(l10n?.recordDeleted ?? 'Record deleted'),
          ],
        ),
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: l10n?.undoAction ?? 'Undo',
          textColor: Colors.white,
          onPressed: () => _undoDelete(homeProvider),
        ),
      ),
    );

    // 4. Clear backup after 6 seconds
    Future.delayed(const Duration(seconds: 6), () {
      _pendingDelete = null;
    });
  }

  /// Undo delete (re-create with new ID)
  Future<void> _undoDelete(HomeProvider homeProvider) async {
    if (_pendingDelete == null) return;

    try {
      // New UUID to avoid DB duplicate key
      final restoredActivity = _pendingDelete!.copyWith(
        id: const Uuid().v4(),
        createdAt: DateTime.now(),
      );

      final created = await _activityRepository.createActivity(restoredActivity);
      homeProvider.addActivity(created);

      // Sprint 19 G-F1: haptic instead of toast on restore
      HapticFeedback.mediumImpact();
    } catch (e) {
      AppToast.showText('Restore failed: $e');
    } finally {
      _pendingDelete = null;
    }
  }
}
