import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/models/activity_model.dart';
import '../../data/repositories/activity_repository.dart';
import '../../features/home/providers/home_provider.dart';
import '../../l10n/generated/app_localizations.dart' show S;
import '../../core/design_system/lulu_colors.dart';
import '../../core/design_system/lulu_typography.dart';
import '../../core/utils/app_toast.dart';

/// Delete with confirmation dialog mixin
///
/// Replaces Undo toast approach (Sprint 21 HF #1/#2 cascade issues).
/// - Shows confirm dialog before delete
/// - On confirm: deletes + shows simple 2-second toast
/// - No Undo, no rebuild cascade, no _skipNextReload needed
mixin UndoDeleteMixin<T extends StatefulWidget> on State<T> {
  final ActivityRepository _activityRepository = ActivityRepository();

  /// Delete activity with confirmation dialog
  ///
  /// Returns true if deleted, false if cancelled.
  Future<bool> deleteActivityWithConfirm({
    required ActivityModel activity,
    required HomeProvider homeProvider,
    required BuildContext context,
  }) async {
    // 1. Capture l10n before async gap
    final l10n = S.of(context);

    // 2. Show confirm dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: LuluColors.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          l10n?.confirmDeleteRecord ?? 'Delete this record?',
          style: LuluTextStyles.titleSmall.copyWith(
            color: LuluTextColors.primary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              l10n?.cancel ?? 'Cancel',
              style: LuluTextStyles.bodyMedium.copyWith(
                color: LuluTextColors.secondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              l10n?.deleteButton ?? 'Delete',
              style: LuluTextStyles.bodyMedium.copyWith(
                color: LuluStatusColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return false;

    // 3. Delete (DB + local state)
    try {
      await _activityRepository.deleteActivity(activity.id);
      homeProvider.removeActivity(activity.id);
      HapticFeedback.mediumImpact();
    } catch (e) {
      debugPrint('[ERR] [UndoDeleteMixin] Delete failed: $e');
      AppToast.showText('Delete failed');
      return false;
    }

    // 4. Simple toast (2 seconds, no Undo)
    AppToast.showText(l10n?.recordDeleted ?? 'Record deleted');

    return true;
  }
}
