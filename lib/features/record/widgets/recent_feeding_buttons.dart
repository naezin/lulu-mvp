import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_icons.dart';
import '../../../core/design_system/lulu_radius.dart';
import '../../../core/design_system/lulu_spacing.dart';
import '../../../core/design_system/lulu_typography.dart';
import '../../../data/models/activity_model.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../providers/feeding_record_provider.dart';
import 'recent_feeding_button.dart';

/// 최근 수유 기록 3개 빠른 버튼
///
/// HOTFIX v1.2: 수유 기록 빠른 저장
/// - 탭 → 바로 저장 (TTC < 2초)
/// - 롱프레스 → 수정 모드 (값 채워짐)
/// - 아기 탭 전환 시 갱신
///
/// BUGFIX v5.3: babyId 검증 추가
/// - 위젯 레벨에서 현재 babyId와 일치하는 기록만 표시
class RecentFeedingButtons extends StatelessWidget {
  /// 현재 선택된 아기 ID (필수!)
  final String babyId;

  /// 수정 모드 요청 콜백
  final Function(ActivityModel) onEditRequest;

  /// 저장 성공 콜백
  final VoidCallback? onSaveSuccess;

  const RecentFeedingButtons({
    super.key,
    required this.babyId,
    required this.onEditRequest,
    this.onSaveSuccess,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);

    return Consumer<FeedingRecordProvider>(
      builder: (context, provider, _) {
        // 🔴 BUGFIX v5.3: babyId 검증 - 현재 아기 기록만 표시
        final validFeedings = provider.recentFeedings.where((feeding) {
          // 단일 아기 기록이고, 현재 선택된 아기와 일치하는지 확인
          return feeding.babyIds.length == 1 && feeding.babyIds[0] == babyId;
        }).toList();

        // 빈 상태
        if (validFeedings.isEmpty) {
          return _buildEmptyState(context, l10n);
        }

        final records = validFeedings;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더 + 힌트
            Row(
              children: [
                Icon(
                  LuluIcons.bolt,
                  size: 18,
                  color: LuluColors.lavenderMist,
                ),
                const SizedBox(width: 4),
                Text(
                  l10n?.quickFeedingTitle ?? '',
                  style: LuluTextStyles.titleSmall,
                ),
                const Spacer(),
                Text(
                  l10n?.quickFeedingHint ?? '',
                  style: LuluTextStyles.caption.copyWith(
                    color: LuluTextColors.tertiary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 버튼 3개
            Row(
              children: records.take(3).map((record) {
                final isLast = record == records.last;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: isLast ? 0 : 8),
                    child: RecentFeedingButton(
                      record: record,
                      onTap: () => _handleQuickSave(context, provider, record),
                      onLongPress: () {
                        HapticFeedback.mediumImpact();
                        onEditRequest(record);
                      },
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // 구분선
            Row(
              children: [
                const Expanded(child: Divider(color: LuluColors.glassBorder)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    l10n?.orNewEntry ?? '',
                    style: LuluTextStyles.caption.copyWith(
                      color: LuluTextColors.tertiary,
                    ),
                  ),
                ),
                const Expanded(child: Divider(color: LuluColors.glassBorder)),
              ],
            ),

            const SizedBox(height: LuluSpacing.lg),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, S? l10n) {
    return Container(
      margin: const EdgeInsets.only(bottom: LuluSpacing.lg),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LuluColors.surfaceCard,
        borderRadius: BorderRadius.circular(LuluRadius.sm),
        border: Border.all(color: LuluColors.glassBorder),
      ),
      child: Row(
        children: [
          Icon(
            LuluIcons.memo,
            size: 32,
            color: LuluTextColors.tertiary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n?.quickFeedingEmpty ?? '',
                  style: LuluTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n?.quickFeedingEmptyDesc ?? '',
                  style: LuluTextStyles.caption.copyWith(
                    color: LuluTextColors.secondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleQuickSave(
    BuildContext context,
    FeedingRecordProvider provider,
    ActivityModel record,
  ) async {
    final l10n = S.of(context);

    // 저장
    final savedId = await provider.quickSaveFeeding(record);

    if (savedId == null) {
      // 에러 또는 연타 방지
      return;
    }

    if (!context.mounted) return;

    // Sprint 20 HF #10/#11: onSaveSuccess가 화면을 닫는 경우
    // SnackBar를 표시하지 않고 햅틱 피드백만 제공 (화면 닫힌 후 SnackBar orphan 방지)
    if (onSaveSuccess != null) {
      HapticFeedback.mediumImpact();
      onSaveSuccess?.call();
      return;
    }

    // onSaveSuccess 없는 경우: 토스트 + 취소 표시 (화면이 안 닫힘)
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(LuluIcons.checkCircle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n?.quickFeedingSaved(_getSummary(record, l10n)) ?? '',
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: l10n?.quickFeedingUndo ?? '',
          textColor: Colors.white,
          onPressed: () async {
            final success = await provider.undoLastSave();
            if (context.mounted && success) {
              HapticFeedback.mediumImpact();
            }
          },
        ),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        backgroundColor: LuluActivityColors.feeding,
      ),
    );
  }

  String _getSummary(ActivityModel record, S? l10n) {
    final data = record.data;
    if (data == null) return l10n?.activityTypeFeeding ?? '';

    final type = data['feeding_type'] as String? ?? 'bottle';
    final side = data['breast_side'] as String?;
    final amountMl = data['amount_ml'];
    final durationMinutes = data['duration_minutes'];

    String typeLabel;
    switch (type) {
      case 'breast':
        final sideLabel = side == 'left'
            ? (l10n?.feedingSideLeft ?? '')
            : side == 'right'
                ? (l10n?.feedingSideRight ?? '')
                : (l10n?.feedingSideBoth ?? '');
        typeLabel =
            '${l10n?.feedingTypeBreast ?? ''} $sideLabel';
        break;
      case 'formula':
      case 'bottle':
        typeLabel = l10n?.feedingTypeFormula ?? '';
        break;
      case 'solid':
        typeLabel = l10n?.feedingTypeSolid ?? '';
        break;
      default:
        typeLabel = l10n?.activityTypeFeeding ?? '';
    }

    String amountLabel = '';
    if (type == 'breast' && durationMinutes != null) {
      amountLabel = l10n?.unitMinutes(durationMinutes as int) ?? '';
    } else if (amountMl != null) {
      amountLabel = '${(amountMl as num).toInt()}ml';
    }

    return amountLabel.isNotEmpty ? '$typeLabel $amountLabel' : typeLabel;
  }
}
