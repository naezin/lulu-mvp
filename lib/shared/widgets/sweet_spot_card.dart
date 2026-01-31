import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/design_system/lulu_colors.dart';
import '../../core/design_system/lulu_spacing.dart';
import '../../core/design_system/lulu_typography.dart';
import '../../features/home/providers/home_provider.dart';
import '../../l10n/generated/app_localizations.dart' show S;

/// Sweet Spot 카드 위젯
///
/// 작업 지시서 v1.2: SweetSpotHeroCard 대체
/// - 단일 색상 시스템 (LuluSweetSpotColors.neutral)
/// - Huckleberry 스타일 확률적 표현
/// - Empty State 포함
class SweetSpotCard extends StatefulWidget {
  /// Sweet Spot 상태 (HomeProvider의 SweetSpotState 사용)
  final SweetSpotState state;

  /// Empty State 여부 (수면 기록 없음)
  final bool isEmpty;

  /// 예상 시간 (예: "약 30분 후")
  final String? estimatedTime;

  /// 수면 기록 버튼 콜백 (Empty State에서 사용)
  final VoidCallback? onRecordSleep;

  // 🆕 Sprint 7 Day 2: 수면 진행 중 props
  /// 수면 진행 중 여부
  final bool isSleeping;

  /// 수면 시작 시간
  final DateTime? sleepStartTime;

  /// 수면 타입 (낮잠/밤잠)
  final String? sleepType;

  /// 아기 이름
  final String? babyName;

  /// 수면 종료 콜백
  final VoidCallback? onEndSleep;

  /// 수면 취소 콜백
  final VoidCallback? onCancelSleep;

  const SweetSpotCard({
    super.key,
    required this.state,
    this.isEmpty = false,
    this.estimatedTime,
    this.onRecordSleep,
    this.isSleeping = false,
    this.sleepStartTime,
    this.sleepType,
    this.babyName,
    this.onEndSleep,
    this.onCancelSleep,
  });

  @override
  State<SweetSpotCard> createState() => _SweetSpotCardState();
}

class _SweetSpotCardState extends State<SweetSpotCard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.isSleeping) {
      _startTimer();
    }
  }

  @override
  void didUpdateWidget(SweetSpotCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 수면 상태 변경 시 타이머 관리
    if (widget.isSleeping && !oldWidget.isSleeping) {
      _startTimer();
    } else if (!widget.isSleeping && oldWidget.isSleeping) {
      _stopTimer();
    }
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }

  void _startTimer() {
    _stopTimer();
    // 1초마다 UI 갱신 (경과 시간 업데이트)
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context)!;

    // 🆕 수면 진행 중이면 수면 카드 표시
    if (widget.isSleeping && widget.sleepStartTime != null) {
      return _buildSleepingCard(context);
    }

    if (widget.isEmpty) {
      return _buildEmptyState(context, l10n);
    }

    return _buildNormalState(context, l10n);
  }

  /// 🆕 수면 진행 중 카드 (OngoingSleepCard 대체)
  Widget _buildSleepingCard(BuildContext context) {
    final sleepTypeText = widget.sleepType == 'night' ? '밤잠' : '낮잠';
    final babyName = widget.babyName ?? '아기';
    final elapsed = DateTime.now().difference(widget.sleepStartTime!);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            LuluActivityColors.sleep.withValues(alpha: 0.15),
            LuluActivityColors.sleep.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: LuluActivityColors.sleep.withValues(alpha: 0.4),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더: 아이콘 + 수면 타입
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: LuluActivityColors.sleep.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.bedtime_rounded,
                    size: 24,
                    color: LuluActivityColors.sleep,
                  ),
                ),
              ),
              const SizedBox(width: LuluSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$babyName $sleepTypeText 중',
                      style: LuluTextStyles.titleSmall.copyWith(
                        color: LuluTextColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDuration(elapsed),
                      style: LuluTextStyles.displaySmall.copyWith(
                        color: LuluActivityColors.sleep,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: LuluSpacing.md),

          // 시작 시간
          _buildInfoRow(
            '시작',
            DateFormat('a h:mm', 'ko').format(widget.sleepStartTime!),
          ),

          const SizedBox(height: LuluSpacing.lg),

          // 버튼: 수면 종료
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.onEndSleep,
              style: ElevatedButton.styleFrom(
                backgroundColor: LuluActivityColors.sleep,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.bedtime_rounded, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '탭하여 수면 종료',
                    style: LuluTextStyles.labelLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Duration 포맷팅
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return '$hours시간 $minutes분';
    }
    return '$minutes분';
  }

  /// 정보 Row
  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: LuluTextStyles.bodyMedium.copyWith(
            color: LuluTextColors.secondary,
          ),
        ),
        Text(
          value,
          style: LuluTextStyles.bodyMedium.copyWith(
            color: LuluTextColors.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// Empty State UI
  Widget _buildEmptyState(BuildContext context, S l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: LuluColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: LuluColors.glassBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.bedtime_outlined,
            size: 40,
            color: LuluTextColors.tertiary,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.sweetSpotEmptyTitle,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: LuluTextColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.sweetSpotEmptySubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: LuluTextColors.secondary,
              height: 1.4,
            ),
          ),
          if (widget.onRecordSleep != null) ...[
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: widget.onRecordSleep,
              icon: const Icon(Icons.add, size: 18),
              label: Text(l10n.buttonStartSleep),
              style: TextButton.styleFrom(
                foregroundColor: LuluSweetSpotColors.neutral,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Normal State UI
  Widget _buildNormalState(BuildContext context, S l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LuluColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: LuluColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 헤더: 제목 + 아이콘
          Row(
            children: [
              Icon(
                Icons.bedtime_outlined,
                size: 20,
                color: LuluSweetSpotColors.icon,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.sweetSpotTitle,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: LuluTextColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 상태 라벨 (Huckleberry 스타일)
          Text(
            _getStateLabel(l10n),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: LuluSweetSpotColors.text,
            ),
          ),

          // 예상 시간 (있는 경우)
          if (widget.estimatedTime != null) ...[
            const SizedBox(height: 4),
            Text(
              widget.estimatedTime!,
              style: TextStyle(
                fontSize: 14,
                color: LuluTextColors.secondary,
              ),
            ),
          ],

          const SizedBox(height: 12),

          // 면책 문구
          Text(
            l10n.sweetSpotDisclaimer,
            style: TextStyle(
              fontSize: 11,
              color: LuluTextColors.tertiary,
            ),
          ),
        ],
      ),
    );
  }

  /// 상태별 라벨 반환 (다국어 지원)
  String _getStateLabel(S l10n) {
    switch (widget.state) {
      case SweetSpotState.unknown:
        return l10n.sweetSpotUnknown;
      case SweetSpotState.tooEarly:
        return l10n.sweetSpotTooEarly;
      case SweetSpotState.approaching:
        return l10n.sweetSpotApproaching;
      case SweetSpotState.optimal:
        return l10n.sweetSpotOptimal;
      case SweetSpotState.overtired:
        return l10n.sweetSpotOvertired;
    }
  }
}
