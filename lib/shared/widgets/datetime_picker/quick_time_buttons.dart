import 'package:flutter/material.dart';

import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_icons.dart';
import '../../../core/design_system/lulu_radius.dart';
import '../../../core/design_system/lulu_typography.dart';
import '../../../l10n/generated/app_localizations.dart';

/// 빠른 시간 조정 버튼
///
/// HOTFIX v1.1: [지금], [-5분], [-15분], [-30분] 버튼
/// - 원탭으로 빠른 시간 설정
/// - 야간 수유 등 과거 기록 시 편리
class QuickTimeButtons extends StatelessWidget {
  /// 시간 선택 콜백
  final ValueChanged<DateTime> onTimeSelected;

  const QuickTimeButtons({
    super.key,
    required this.onTimeSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _QuickButton(
          label: l10n?.dateTimeNow ?? '지금',
          icon: LuluIcons.time,
          onTap: () => onTimeSelected(DateTime.now()),
          isPrimary: true,
        ),
        _QuickButton(
          label: l10n?.dateTime5MinAgo ?? '-5분',
          onTap: () => onTimeSelected(
            DateTime.now().subtract(const Duration(minutes: 5)),
          ),
        ),
        _QuickButton(
          label: l10n?.dateTime15MinAgo ?? '-15분',
          onTap: () => onTimeSelected(
            DateTime.now().subtract(const Duration(minutes: 15)),
          ),
        ),
        _QuickButton(
          label: l10n?.dateTime30MinAgo ?? '-30분',
          onTap: () => onTimeSelected(
            DateTime.now().subtract(const Duration(minutes: 30)),
          ),
        ),
      ],
    );
  }
}

/// 개별 빠른 버튼
class _QuickButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  final bool isPrimary;

  const _QuickButton({
    required this.label,
    this.icon,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: isPrimary
            ? LuluColors.lavenderLight
            : LuluColors.surfaceCard,
        borderRadius: BorderRadius.circular(LuluRadius.xs),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(LuluRadius.xs),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 16,
                    color: isPrimary
                        ? LuluColors.lavenderMist
                        : LuluTextColors.secondary,
                  ),
                  const SizedBox(width: 4),
                ],
                Text(
                  label,
                  style: LuluTextStyles.labelSmall.copyWith(
                    color: isPrimary
                        ? LuluColors.lavenderMist
                        : LuluTextColors.secondary,
                    fontWeight: isPrimary ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
