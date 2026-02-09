import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_icons.dart';
import '../../../core/design_system/lulu_radius.dart';
import '../../../core/design_system/lulu_typography.dart';
import '../../../core/services/supabase_service.dart';
import '../../../data/repositories/family_repository.dart';
import '../../../l10n/generated/app_localizations.dart' show S;
import '../../home/providers/home_provider.dart';

/// Settings - Reset Data Section
///
/// Extracted from settings_screen.dart for file size management.
/// Handles data reset confirmation dialog and reset logic.
class SettingsResetSection extends StatelessWidget {
  const SettingsResetSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: LuluColors.surfaceCard,
        borderRadius: BorderRadius.circular(LuluRadius.sm),
        border: Border.all(
          color: LuluStatusColors.errorBorder,
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: LuluStatusColors.errorLight,
            borderRadius: BorderRadius.circular(LuluRadius.section),
          ),
          child: Icon(
            LuluIcons.deleteForever,
            color: LuluStatusColors.error,
            size: 22,
          ),
        ),
        title: Text(
          S.of(context)!.resetDataTitle,
          style: LuluTextStyles.bodyLarge.copyWith(
            color: LuluStatusColors.error,
          ),
        ),
        subtitle: Text(
          S.of(context)!.resetDataHint,
          style: LuluTextStyles.caption.copyWith(
            color: LuluTextColors.secondary,
          ),
        ),
        trailing: Icon(
          LuluIcons.chevronRight,
          color: LuluStatusColors.errorStrong,
        ),
        onTap: () => _showResetConfirmDialog(context),
      ),
    );
  }

  Future<void> _showResetConfirmDialog(BuildContext context) async {
    final l10n = S.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: LuluColors.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LuluRadius.md),
        ),
        title: Row(
          children: [
            Icon(LuluIcons.statusWarn, color: LuluStatusColors.error),
            const SizedBox(width: 8),
            Text(
              l10n.resetDataTitle,
              style: LuluTextStyles.titleMedium.copyWith(
                color: LuluTextColors.primary,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.resetDataConfirm,
              style: LuluTextStyles.bodyLarge.copyWith(
                color: LuluTextColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: LuluStatusColors.errorBg,
                borderRadius: BorderRadius.circular(LuluRadius.xs),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWarningItem(l10n.resetWarningRecords),
                  _buildWarningItem(l10n.resetWarningBabies),
                  _buildWarningItem(l10n.resetWarningIrreversible),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              l10n.buttonCancel,
              style: LuluTextStyles.labelLarge.copyWith(
                color: LuluTextColors.secondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(
              foregroundColor: LuluStatusColors.error,
            ),
            child: Text(
              l10n.buttonDelete,
              style: LuluTextStyles.labelLarge.copyWith(
                color: LuluStatusColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await _resetAllData(context);
    }
  }

  Widget _buildWarningItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            LuluIcons.removeCircleOutline,
            size: 16,
            color: LuluStatusColors.error,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: LuluTextStyles.bodySmall.copyWith(
              color: LuluTextColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _resetAllData(BuildContext context) async {
    // Loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(
          color: LuluColors.lavenderMist,
        ),
      ),
    );

    try {
      final familyRepository = FamilyRepository();

      // 1. Repository를 통해 전체 데이터 삭제
      await familyRepository.resetAllData();

      // 2. Clear local data
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      debugPrint('[OK] Local data cleared');

      // 3. Reset Provider
      if (context.mounted) {
        context.read<HomeProvider>().reset();
      }

      // Close loading
      if (context.mounted) {
        Navigator.pop(context);
      }

      // 4. Sign out (restart to onboarding)
      if (context.mounted) {
        _showSnackBar(context, S.of(context)!.resetCompleteMessage);
        await SupabaseService.client.auth.signOut();
      }
    } catch (e) {
      // Close loading
      if (context.mounted) {
        Navigator.pop(context);
      }

      debugPrint('[ERROR] _resetAllData: $e');

      if (context.mounted) {
        _showSnackBar(
            context, S.of(context)!.errorResetFailed(e.toString()));
      }
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: LuluColors.surfaceElevated,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LuluRadius.sm),
        ),
      ),
    );
  }
}
