import 'package:flutter/material.dart';

import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_radius.dart';
import '../../../core/design_system/lulu_spacing.dart';
import '../../../core/design_system/lulu_typography.dart';
import '../../../data/models/baby_model.dart';

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
              Icons.warning_amber_rounded,
              color: LuluStatusColors.error,
              size: 22,
            ),
          ),
          const SizedBox(width: LuluSpacing.md),
          Expanded(
            child: Text(
              '아기 삭제',
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
            '${widget.baby.name}의 모든 기록이 삭제됩니다.',
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
                  Icons.info_outline_rounded,
                  color: LuluStatusColors.error,
                  size: 20,
                ),
                const SizedBox(width: LuluSpacing.sm),
                Expanded(
                  child: Text(
                    '이 작업은 되돌릴 수 없습니다.',
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
            '취소',
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
                  '삭제',
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('삭제 실패: $e')),
        );
        setState(() => _isDeleting = false);
      }
    }
  }
}
