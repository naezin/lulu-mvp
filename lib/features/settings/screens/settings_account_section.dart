import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_icons.dart';
import '../../../core/design_system/lulu_radius.dart';
import '../../../core/design_system/lulu_typography.dart';
import '../../../core/utils/app_toast.dart';
import '../../../l10n/generated/app_localizations.dart' show S;
import '../../auth/providers/auth_provider.dart';
import '../../home/providers/home_provider.dart';

/// Settings - Account Section (Logout + Delete Account)
///
/// Sprint 21 Phase 5-1: App Store requirement for account deletion.
/// Handles logout and account deletion with confirmation flow.
class SettingsAccountSection extends StatelessWidget {
  const SettingsAccountSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: LuluColors.surfaceCard,
        borderRadius: BorderRadius.circular(LuluRadius.sm),
      ),
      child: Column(
        children: [
          // Logout
          _buildLogoutTile(context),
          Divider(height: 1, color: LuluColors.glassBorder),
          // Delete Account
          _buildDeleteAccountTile(context),
        ],
      ),
    );
  }

  Widget _buildLogoutTile(BuildContext context) {
    final l10n = S.of(context)!;

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: LuluColors.lavenderLight,
          borderRadius: BorderRadius.circular(LuluRadius.section),
        ),
        child: const Icon(
          LuluIcons.logout,
          color: LuluColors.lavenderMist,
          size: 22,
        ),
      ),
      title: Text(
        l10n.settingsLogout,
        style: LuluTextStyles.bodyLarge.copyWith(
          color: LuluTextColors.primary,
        ),
      ),
      trailing: const Icon(
        LuluIcons.chevronRight,
        color: LuluTextColors.secondary,
      ),
      onTap: () => _showLogoutDialog(context),
    );
  }

  Widget _buildDeleteAccountTile(BuildContext context) {
    final l10n = S.of(context)!;

    return ListTile(
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
        l10n.settingsDeleteAccount,
        style: LuluTextStyles.bodyLarge.copyWith(
          color: LuluStatusColors.error,
        ),
      ),
      subtitle: Text(
        l10n.settingsDeleteAccountDesc,
        style: LuluTextStyles.caption.copyWith(
          color: LuluTextColors.secondary,
        ),
      ),
      trailing: Icon(
        LuluIcons.chevronRight,
        color: LuluStatusColors.errorStrong,
      ),
      onTap: () => _showDeleteAccountDialog(context),
    );
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    final l10n = S.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: LuluColors.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LuluRadius.md),
        ),
        title: Text(
          l10n.settingsLogoutConfirm,
          style: LuluTextStyles.titleMedium.copyWith(
            color: LuluTextColors.primary,
          ),
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
            child: Text(
              l10n.settingsLogout,
              style: LuluTextStyles.labelLarge.copyWith(
                color: LuluColors.lavenderMist,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<AuthProvider>().signOut();
    }
  }

  Future<void> _showDeleteAccountDialog(BuildContext context) async {
    final l10n = S.of(context)!;

    // First confirmation
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
              l10n.settingsDeleteAccount,
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
              l10n.settingsDeleteAccountConfirm,
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
                  _buildWarningItem(l10n.deleteAccountWarningData),
                  _buildWarningItem(l10n.deleteAccountWarningAuth),
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
      await _executeAccountDeletion(context);
    }
  }

  Widget _buildWarningItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            LuluIcons.removeCircleOutline,
            size: 16,
            color: LuluStatusColors.error,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: LuluTextStyles.bodySmall.copyWith(
                color: LuluTextColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _executeAccountDeletion(BuildContext context) async {
    final l10n = S.of(context)!;
    final authProvider = context.read<AuthProvider>();
    final homeProvider = context.read<HomeProvider>();

    // Show loading
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
      // 1. Delete account via RPC (CASCADE handles all data)
      final success = await authProvider.deleteAccount();

      if (!success) {
        // Close loading
        if (context.mounted) Navigator.pop(context);
        AppToast.showText(l10n.deleteAccountFailed);
        return;
      }

      // 2. Clear local data
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      debugPrint('[OK] Local data cleared after account deletion');

      // 3. Reset provider
      homeProvider.reset();

      // Close loading
      if (context.mounted) {
        Navigator.pop(context);
        AppToast.showText(l10n.deleteAccountSuccess);
      }
    } catch (e) {
      // Close loading
      if (context.mounted) Navigator.pop(context);
      debugPrint('[ERROR] _executeAccountDeletion: $e');
      AppToast.showText(l10n.deleteAccountFailed);
    }
  }
}
