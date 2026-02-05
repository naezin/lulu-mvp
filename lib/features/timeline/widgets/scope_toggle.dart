import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_typography.dart';
import '../../../l10n/generated/app_localizations.dart' show S;

/// 일간/주간 스코프 토글
///
/// Sprint 18-R Phase 2: 일간 뷰와 주간 뷰를 전환하는 토글 버튼
class ScopeToggle extends StatelessWidget {
  const ScopeToggle({
    super.key,
    required this.isWeeklyScope,
    required this.onScopeChanged,
  });

  /// 현재 주간 스코프인지 여부
  final bool isWeeklyScope;

  /// 스코프 변경 콜백
  final ValueChanged<bool> onScopeChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: LuluColors.deepBlue,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            // 일간 버튼
            Expanded(
              child: _ScopeButton(
                label: l10n?.scopeDaily ?? 'Daily',
                isSelected: !isWeeklyScope,
                onTap: () {
                  if (isWeeklyScope) {
                    HapticFeedback.selectionClick();
                    onScopeChanged(false);
                  }
                },
              ),
            ),
            // 주간 버튼
            Expanded(
              child: _ScopeButton(
                label: l10n?.scopeWeekly ?? 'Weekly',
                isSelected: isWeeklyScope,
                onTap: () {
                  if (!isWeeklyScope) {
                    HapticFeedback.selectionClick();
                    onScopeChanged(true);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 스코프 선택 버튼
class _ScopeButton extends StatelessWidget {
  const _ScopeButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isSelected ? LuluColors.lavenderMist : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: LuluTextStyles.bodyMedium.copyWith(
            color: isSelected ? LuluColors.midnightNavy : LuluTextColors.secondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
