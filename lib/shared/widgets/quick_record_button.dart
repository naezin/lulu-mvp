import 'package:flutter/material.dart';

import '../../core/design_system/lulu_colors.dart';
import '../../core/design_system/lulu_spacing.dart';
import '../../core/design_system/lulu_typography.dart';
import '../../data/models/activity_model.dart';
import '../../data/models/baby_type.dart';

/// "이전과 같이" 빠른 기록 버튼 (v5.0)
///
/// "둘 다" 버튼 대체 UX:
/// - 마지막 기록 기반 원탭 저장
/// - 3초 Rule 준수를 위한 핵심 컴포넌트
/// - 터치 피드백 애니메이션 포함
class QuickRecordButton extends StatefulWidget {
  /// 마지막 기록 (없으면 버튼 숨김)
  final ActivityModel? lastRecord;

  /// 탭 시 콜백
  final VoidCallback onTap;

  /// 활동 타입 (색상 결정용)
  final ActivityType activityType;

  /// 로딩 상태
  final bool isLoading;

  const QuickRecordButton({
    super.key,
    required this.lastRecord,
    required this.onTap,
    required this.activityType,
    this.isLoading = false,
  });

  @override
  State<QuickRecordButton> createState() => _QuickRecordButtonState();
}

class _QuickRecordButtonState extends State<QuickRecordButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (!widget.isLoading) {
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    if (!widget.isLoading) {
      widget.onTap();
    }
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    // 마지막 기록이 없으면 숨김
    if (widget.lastRecord == null) {
      return const SizedBox.shrink();
    }

    final color = _getActivityColor();
    final summary = _getRecordSummary();

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Container(
          padding: const EdgeInsets.all(LuluSpacing.lg),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // 아이콘
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: widget.isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: color,
                          ),
                        )
                      : Text(
                          _getEmoji(),
                          style: const TextStyle(fontSize: 24),
                        ),
                ),
              ),
              const SizedBox(width: LuluSpacing.md),
              // 텍스트
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '이전과 같이',
                      style: LuluTextStyles.caption.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      summary,
                      style: LuluTextStyles.bodyMedium.copyWith(
                        color: LuluTextColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '원탭으로 저장',
                      style: LuluTextStyles.caption.copyWith(
                        color: LuluTextColors.tertiary,
                      ),
                    ),
                  ],
                ),
              ),
              // 화살표
              Icon(
                Icons.chevron_right,
                color: color,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getActivityColor() {
    return switch (widget.activityType) {
      ActivityType.feeding => LuluActivityColors.feeding,
      ActivityType.sleep => LuluActivityColors.sleep,
      ActivityType.diaper => LuluActivityColors.diaper,
      ActivityType.play => LuluActivityColors.play,
      ActivityType.health => LuluActivityColors.health,
    };
  }

  String _getEmoji() {
    return switch (widget.activityType) {
      ActivityType.feeding => '🍼',
      ActivityType.sleep => '😴',
      ActivityType.diaper => '🧷',
      ActivityType.play => '🎮',
      ActivityType.health => '🏥',
    };
  }

  String _getRecordSummary() {
    final data = widget.lastRecord?.data;
    if (data == null) return '기록';

    switch (widget.activityType) {
      case ActivityType.feeding:
        final feedingType = data['feeding_type'] as String?;
        final amount = data['amount_ml'] as num?;
        final duration = data['duration_minutes'] as int?;

        final typeStr = switch (feedingType) {
          'breast' => '모유',
          'bottle' => '젖병',
          'formula' => '분유',
          'solid' => '이유식',
          _ => '수유',
        };

        if (amount != null && amount > 0) {
          return '$typeStr ${amount.toInt()}ml';
        }
        if (duration != null && duration > 0) {
          return '$typeStr $duration분';
        }
        return typeStr;

      case ActivityType.sleep:
        final sleepType = data['sleep_type'] as String?;
        return sleepType == 'nap' ? '낮잠' : '밤잠';

      case ActivityType.diaper:
        final diaperType = data['diaper_type'] as String?;
        return switch (diaperType) {
          'wet' => '소변',
          'dirty' => '대변',
          'both' => '혼합',
          'dry' => '건조',
          _ => '기저귀',
        };

      case ActivityType.play:
        final playType = data['play_type'] as String?;
        final duration = data['duration_minutes'] as int?;
        final typeStr = switch (playType) {
          'tummy_time' => '터미타임',
          'bath' => '목욕',
          'outdoor' => '외출',
          'play' => '실내놀이',
          'reading' => '독서',
          _ => '놀이',
        };
        if (duration != null && duration > 0) {
          return '$typeStr $duration분';
        }
        return typeStr;

      case ActivityType.health:
        final healthType = data['health_type'] as String?;
        final temp = data['temperature'] as num?;
        if (temp != null) {
          return '체온 ${temp.toStringAsFixed(1)}°C';
        }
        return switch (healthType) {
          'temperature' => '체온 측정',
          'symptom' => '증상 기록',
          'medication' => '투약',
          'hospital' => '병원 방문',
          _ => '건강',
        };
    }
  }
}
