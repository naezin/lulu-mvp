import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/design_system/lulu_colors.dart';
import '../../core/design_system/lulu_icons.dart';
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

  // 🆕 Sprint 7 Day 2 v1.2: 빈 상태 3종 기록 버튼용 콜백
  /// 수유 기록 탭 콜백
  final VoidCallback? onFeedingTap;

  /// 수면 기록 탭 콜백 (isEmpty 상태에서 수면 버튼)
  final VoidCallback? onSleepTap;

  /// 기저귀 기록 탭 콜백
  final VoidCallback? onDiaperTap;

  // 🆕 v3: Normal State 개선용 props
  /// Sweet Spot 진행률 (0.0 ~ 1.0)
  final double? progress;

  /// 추천 수면 시간
  final DateTime? recommendedTime;

  /// 밤잠 여부
  final bool isNightTime;

  // 🆕 HOTFIX: 수면 기록 없을 때 안내 메시지
  /// 수면 기록 없지만 다른 활동(수유/기저귀)은 있음
  final bool hasOtherActivitiesOnly;

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
    this.onFeedingTap,
    this.onSleepTap,
    this.onDiaperTap,
    this.progress,
    this.recommendedTime,
    this.isNightTime = false,
    this.hasOtherActivitiesOnly = false,
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
                    LuluIcons.sleep,
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
                  const Icon(LuluIcons.sleep, size: 20),
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

  /// Empty State UI - 통합 카드 (v1.2)
  ///
  /// 2개 카드 → 1개 통합 카드로 스크롤 없이 바로 기록 가능
  Widget _buildEmptyState(BuildContext context, S l10n) {
    final babyName = widget.babyName;

    return Container(
      padding: const EdgeInsets.all(LuluSpacing.lg),
      decoration: BoxDecoration(
        color: LuluColors.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: LuluColors.glassBorder,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 헤더 아이콘
          Icon(
            Icons.celebration_rounded,
            size: 48,
            color: LuluColors.champagneGold,
          ),
          const SizedBox(height: LuluSpacing.md),

          // 타이틀
          Text(
            babyName != null
                ? l10n.sweetSpotEmptyTitleWithName(babyName)
                : l10n.sweetSpotEmptyTitleDefault,
            style: LuluTextStyles.titleMedium.copyWith(
              color: LuluTextColors.primary,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: LuluSpacing.sm),

          // 액션 힌트
          Text(
            l10n.sweetSpotEmptyActionHint,
            style: LuluTextStyles.bodyMedium.copyWith(
              color: LuluTextColors.secondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: LuluSpacing.lg),

          // 3종 기록 버튼 (탭 가능!)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildQuickRecordButton(
                icon: LuluIcons.feeding,
                label: l10n.activityTypeFeeding,
                color: LuluActivityColors.feeding,
                onTap: widget.onFeedingTap,
              ),
              _buildQuickRecordButton(
                icon: LuluIcons.sleep,
                label: l10n.activityTypeSleep,
                color: LuluActivityColors.sleep,
                onTap: widget.onSleepTap ?? widget.onRecordSleep,
              ),
              _buildQuickRecordButton(
                icon: LuluIcons.diaper,
                label: l10n.activityTypeDiaper,
                color: LuluActivityColors.diaper,
                onTap: widget.onDiaperTap,
              ),
            ],
          ),
          const SizedBox(height: LuluSpacing.lg),

          // 힌트 메시지
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lightbulb_outline_rounded,
                size: 16,
                color: LuluColors.champagneGold,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  l10n.sweetSpotEmptyHint,
                  style: LuluTextStyles.caption.copyWith(
                    color: LuluTextColors.tertiary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 빈 상태용 빠른 기록 버튼 (탭 가능)
  Widget _buildQuickRecordButton({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: LuluSpacing.md),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: LuluSpacing.xs),
            Text(
              label,
              style: LuluTextStyles.labelSmall.copyWith(
                color: LuluTextColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Normal State UI (v3 개선)
  Widget _buildNormalState(BuildContext context, S l10n) {
    // 🆕 HOTFIX: 수면 기록 없지만 다른 활동은 있을 때 안내 메시지
    if (widget.hasOtherActivitiesOnly) {
      return _buildNoSleepGuideCard(context, l10n);
    }

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
          // 헤더: 아기 이름 + 수면타입
          Row(
            children: [
              Icon(
                LuluIcons.sleep,
                size: 20,
                color: LuluSweetSpotColors.icon,
              ),
              const SizedBox(width: 8),
              Text(
                _getHeaderTitle(l10n),
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

          // 시간 표시 (12시간제 + 남은 시간)
          const SizedBox(height: 4),
          Text(
            _getTimeText(l10n),
            style: TextStyle(
              fontSize: 14,
              color: LuluTextColors.secondary,
            ),
          ),

          // 프로그레스 바 (조건 충족 시)
          if (_shouldShowProgressBar) _buildProgressBar(),

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

  /// 🆕 HOTFIX: 수면 기록 없을 때 안내 카드
  ///
  /// 수유/기저귀 기록은 있지만 수면 기록이 없을 때 표시
  Widget _buildNoSleepGuideCard(BuildContext context, S l10n) {
    return Container(
      padding: const EdgeInsets.all(LuluSpacing.lg),
      decoration: BoxDecoration(
        color: LuluColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: LuluColors.glassBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 아이콘
          Icon(
            LuluIcons.sleep,
            size: 40,
            color: LuluActivityColors.sleep.withValues(alpha: 0.6),
          ),
          const SizedBox(height: LuluSpacing.md),

          // 안내 메시지
          Text(
            l10n.sweetSpotNoSleepTitle,
            style: LuluTextStyles.titleSmall.copyWith(
              color: LuluTextColors.primary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: LuluSpacing.sm),
          Text(
            l10n.sweetSpotNoSleepHint,
            style: LuluTextStyles.bodySmall.copyWith(
              color: LuluTextColors.secondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: LuluSpacing.lg),

          // 수면 기록 버튼
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: widget.onRecordSleep ?? widget.onSleepTap,
              icon: const Icon(LuluIcons.sleep, size: 18),
              label: Text(l10n.sweetSpotRecordSleepButton),
              style: OutlinedButton.styleFrom(
                foregroundColor: LuluActivityColors.sleep,
                side: BorderSide(
                  color: LuluActivityColors.sleep.withValues(alpha: 0.5),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 헤더 타이틀: "{아기이름}의 다음 {낮잠/밤잠}"
  String _getHeaderTitle(S l10n) {
    final sleepType = widget.isNightTime ? l10n.sleepTypeNight : l10n.sleepTypeNap;

    if (widget.babyName != null) {
      return '${widget.babyName}의 다음 $sleepType';
    }
    return '다음 $sleepType';
  }

  /// 시간 텍스트: "약 오후 2:30 (45분 후)"
  String _getTimeText(S l10n) {
    if (widget.recommendedTime != null) {
      final formattedTime = DateFormat('a h:mm', 'ko').format(widget.recommendedTime!);
      final minutesUntil = widget.recommendedTime!.difference(DateTime.now()).inMinutes.clamp(0, 999);
      return '약 $formattedTime ($minutesUntil분 후)';
    }
    return widget.estimatedTime ?? '';
  }

  /// 프로그레스 바 표시 조건
  bool get _shouldShowProgressBar {
    return !widget.isEmpty &&
        !widget.isSleeping &&
        widget.progress != null &&
        widget.state != SweetSpotState.unknown;
  }

  /// 프로그레스 바 위젯
  Widget _buildProgressBar() {
    final progressValue = widget.progress ?? 0.0;

    return Container(
      height: 8,
      margin: const EdgeInsets.only(top: LuluSpacing.md),
      decoration: BoxDecoration(
        color: LuluColors.surfaceElevated,
        borderRadius: BorderRadius.circular(4),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              // 진행 바
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: constraints.maxWidth * progressValue.clamp(0.0, 1.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getProgressColor(progressValue).withValues(alpha: 0.5),
                      _getProgressColor(progressValue),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              // Sweet Spot 마커 (80% 위치)
              // TODO: Phase 2 - 교정연령별 Sweet Spot 위치 개인화
              Positioned(
                left: constraints.maxWidth * 0.8 - 1.5,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 3,
                  decoration: BoxDecoration(
                    color: LuluColors.champagneGold,
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 진행률에 따른 색상
  Color _getProgressColor(double progress) {
    if (progress >= 1.0) {
      return LuluStatusColors.caution; // 100%+ 과로
    } else if (progress >= 0.8) {
      return LuluColors.champagneGold; // 80-100% Sweet Spot
    }
    return LuluColors.lavenderMist; // 0-80%
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
