import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_icons.dart';
import '../../../core/design_system/lulu_radius.dart';
import '../../../core/design_system/lulu_typography.dart';
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
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) {
        throw Exception('Not authenticated');
      }

      // 1. Find family_id (family_members first, families fallback)
      String? familyId;

      // 1-1. family_members
      try {
        final memberData = await supabase
            .from('family_members')
            .select('family_id')
            .eq('user_id', userId)
            .maybeSingle();

        if (memberData != null) {
          familyId = memberData['family_id'] as String?;
          debugPrint('[OK] Found family via family_members: $familyId');
        }
      } catch (e) {
        debugPrint('[WARN] family_members query failed: $e');
      }

      // 1-2. fallback: families.user_id
      if (familyId == null) {
        final familyData = await supabase
            .from('families')
            .select('id')
            .eq('user_id', userId)
            .maybeSingle();

        if (familyData != null) {
          familyId = familyData['id'] as String?;
          debugPrint('[OK] Found family via families.user_id: $familyId');
        }
      }

      if (familyId != null) {
        debugPrint('[INFO] Deleting all data for family: $familyId');

        // 2. Delete activities
        await supabase
            .from('activities')
            .delete()
            .eq('family_id', familyId);
        debugPrint('[OK] Activities deleted');

        // 3. Delete babies
        await supabase
            .from('babies')
            .delete()
            .eq('family_id', familyId);
        debugPrint('[OK] Babies deleted');

        // 4. Delete family_invites (Family Sharing v3.2)
        try {
          await supabase
              .from('family_invites')
              .delete()
              .eq('family_id', familyId);
          debugPrint('[OK] Family invites deleted');
        } catch (e) {
          debugPrint('[WARN] family_invites deletion failed: $e');
        }

        // 5. Delete family_members (Family Sharing v3.2)
        try {
          await supabase
              .from('family_members')
              .delete()
              .eq('family_id', familyId);
          debugPrint('[OK] Family members deleted');
        } catch (e) {
          debugPrint('[WARN] family_members deletion failed: $e');
        }

        // 6. Delete families
        await supabase
            .from('families')
            .delete()
            .eq('id', familyId);
        debugPrint('[OK] Family deleted');
      }

      // 7. Clear local data
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      debugPrint('[OK] Local data cleared');

      // 8. Reset Provider
      if (context.mounted) {
        context.read<HomeProvider>().reset();
      }

      // Close loading
      if (context.mounted) {
        Navigator.pop(context);
      }

      debugPrint('[OK] All data reset complete');

      // 9. Sign out (restart to onboarding)
      if (context.mounted) {
        _showSnackBar(context, S.of(context)!.resetCompleteMessage);
        await supabase.auth.signOut();
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
