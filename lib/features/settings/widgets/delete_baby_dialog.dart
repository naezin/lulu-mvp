import 'package:flutter/material.dart';

import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_icons.dart';
import '../../../core/design_system/lulu_radius.dart';
import '../../../core/design_system/lulu_spacing.dart';
import '../../../core/design_system/lulu_typography.dart';
import '../../../core/utils/app_toast.dart';
import '../../../data/models/baby_model.dart';
import '../../../l10n/generated/app_localizations.dart' show S;

/// 아기 삭제 확인 다이얼로그
///
/// 삭제 전 경고 및 확인 절차
class DeleteBabyDialog extends StatefulWidget {
  final BabyModel baby;
  final VoidCallback onConfirm;

  const DeleteBabyDialog({
    super.key,
    required this.baby,
    required this.onConfirm,
  });

  @override
  State<DeleteBabyDialog> createState() => _DeleteBabyDialogState();
}

class _DeleteBabyDialogState extends State<DeleteBabyDialog> {
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context)!;
    return AlertDialog(
      backgroundColor: LuluColors.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(LuluRadius.lg),
      ),
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: LuluStatusColors.errorSoft,
              borderRadius: BorderRadius.circular(LuluRadius.section),
            ),
            child: const Icon(
              LuluIcons.statusWarn,
              color: LuluStatusColors.error,
              size: 22,
            ),
          ),
          const SizedBox(width: LuluSpacing.md),
          Expanded(
            child: Text(
              l10n.deleteBabyTitle,
              style: LuluTextStyles.titleMedium.copyWith(
                color: LuluTextColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.deleteBabyConfirmMessage(widget.baby.name),
            style: LuluTextStyles.bodyLarge.copyWith(
              color: LuluTextColors.primary,
            ),
          ),
          const SizedBox(height: LuluSpacing.md),
          Container(
            padding: const EdgeInsets.all(LuluSpacing.md),
            decoration: BoxDecoration(
              color: LuluStatusColors.errorSoft,
              borderRadius: BorderRadius.circular(LuluRadius.sm),
            ),
            child: Row(
              children: [
                Icon(
                  LuluIcons.infoOutline,
                  color: LuluStatusColors.error,
                  size: 20,
                ),
                const SizedBox(width: LuluSpacing.sm),
                Expanded(
                  child: Text(
                    l10n.deleteBabyWarning,
                    style: LuluTextStyles.bodySmall.copyWith(
                      color: LuluStatusColors.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            l10n.buttonCancel,
            style: LuluTextStyles.labelLarge.copyWith(
              color: LuluTextColors.secondary,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _isDeleting ? null : _handleDelete,
          style: ElevatedButton.styleFrom(
            backgroundColor: LuluStatusColors.error,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(LuluRadius.sm),
            ),
          ),
          child: _isDeleting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  l10n.buttonDelete,
                  style: LuluTextStyles.labelLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ],
    );
  }

  Future<void> _handleDelete() async {
    setState(() => _isDeleting = true);

    try {
      widget.onConfirm();
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        AppToast.showText(S.of(context)!.errorDeleteFailed(e.toString()));
        setState(() => _isDeleting = false);
      }
    }
  }
}
