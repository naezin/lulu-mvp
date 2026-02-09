import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/design_system/lulu_colors.dart';
import '../../core/design_system/lulu_radius.dart';
import '../../core/design_system/lulu_shadows.dart';
import '../../core/design_system/lulu_icons.dart';
import '../../core/design_system/lulu_spacing.dart';
import '../../core/design_system/lulu_typography.dart';
import '../../data/models/activity_model.dart';
import '../../data/models/baby_type.dart';
import '../../l10n/generated/app_localizations.dart' show S;

/// MB-03: 첫 사용 여부 키
const String _kQuickRecordTooltipShownKey = 'quick_record_tooltip_shown';

/// "마지막 기록 반복" 빠른 기록 버튼 (v5.0 + MB-03)
///
/// "둘 다" 버튼 대체 UX:
/// - 마지막 기록 기반 원탭 저장
/// - 3초 Rule 준수를 위한 핵심 컴포넌트
/// - 터치 피드백 애니메이션 포함
/// - MB-03: 아기 이름 + 시간 표시 개선
class QuickRecordButton extends StatefulWidget {
  /// 마지막 기록 (없으면 버튼 숨김)
  final ActivityModel? lastRecord;

  /// 탭 시 콜백
  final VoidCallback onTap;

  /// 활동 타입 (색상 결정용)
  final ActivityType activityType;

  /// 로딩 상태
  final bool isLoading;

  /// MB-03: 현재 선택된 아기 이름 (다태아 UX 개선)
  final String? babyName;

  const QuickRecordButton({
    super.key,
    required this.lastRecord,
    required this.onTap,
    required this.activityType,
    this.isLoading = false,
    this.babyName,
  });

  @override
  State<QuickRecordButton> createState() => _QuickRecordButtonState();
}

class _QuickRecordButtonState extends State<QuickRecordButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  // MB-03: 툴팁 오버레이
  OverlayEntry? _tooltipOverlay;

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

    // MB-03: 첫 사용 체크
    _checkFirstUse();
  }

  /// MB-03: 첫 사용 시 툴팁 표시
  Future<void> _checkFirstUse() async {
    if (widget.lastRecord == null) return;

    final prefs = await SharedPreferences.getInstance();
    final hasShown = prefs.getBool(_kQuickRecordTooltipShownKey) ?? false;

    if (!hasShown && mounted) {
      // 화면 빌드 후 툴팁 표시
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showTooltipOverlay();

          // 3초 후 자동 닫기
          Future.delayed(const Duration(seconds: 3), _hideTooltip);
        }
      });

      // 표시 완료 저장
      await prefs.setBool(_kQuickRecordTooltipShownKey, true);
    }
  }

  void _showTooltipOverlay() {
    if (_tooltipOverlay != null) return;

    final overlayState = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    _tooltipOverlay = OverlayEntry(
      builder: (context) => Positioned(
        top: position.dy - 40,
        left: position.dx + size.width / 2 - 100,
        child: Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: _hideTooltip,
            child: Container(
              width: 200,
              padding: const EdgeInsets.symmetric(
                horizontal: LuluSpacing.md,
                vertical: LuluSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: LuluColors.surfaceCard,
                borderRadius: BorderRadius.circular(LuluRadius.xs),
                boxShadow: LuluShadows.button,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LuluIcons.tips,
                        size: 14,
                        color: LuluColors.lavenderMist,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          S.of(context)!.quickRecordTooltip,
                          style: LuluTextStyles.bodySmall.copyWith(
                            color: LuluTextColors.primary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // 말풍선 꼬리 (아래쪽)
                  CustomPaint(
                    size: const Size(16, 8),
                    painter: _TooltipArrowPainter(color: LuluColors.surfaceCard),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlayState.insert(_tooltipOverlay!);
  }

  void _hideTooltip() {
    _tooltipOverlay?.remove();
    _tooltipOverlay = null;
  }

  @override
  void dispose() {
    _hideTooltip();
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
            borderRadius: BorderRadius.circular(LuluRadius.md),
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
                  borderRadius: BorderRadius.circular(LuluRadius.sm),
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
                      : Icon(
                          _getIcon(),
                          size: 24,
                          color: color,
                        ),
                ),
              ),
              const SizedBox(width: LuluSpacing.md),
              // 텍스트 (MB-03: 아기 이름 + 시간 추가)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getLabelText(),
                      style: LuluTextStyles.caption.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _getSummaryWithTime(),
                      style: LuluTextStyles.bodyMedium.copyWith(
                        color: LuluTextColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      S.of(context)!.quickRecordTapToSave,
                      style: LuluTextStyles.caption.copyWith(
                        color: LuluTextColors.tertiary,
                      ),
                    ),
                  ],
                ),
              ),
              // 화살표
              Icon(
                LuluIcons.chevronRight,
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

  IconData _getIcon() {
    return switch (widget.activityType) {
      ActivityType.feeding => LuluIcons.feeding,
      ActivityType.sleep => LuluIcons.sleep,
      ActivityType.diaper => LuluIcons.diaper,
      ActivityType.play => LuluIcons.play,
      ActivityType.health => LuluIcons.health,
    };
  }

  /// MB-03: 라벨 텍스트 (아기 이름 포함)
  String _getLabelText() {
    final l10n = S.of(context)!;
    if (widget.babyName != null && widget.babyName!.isNotEmpty) {
      return l10n.quickRecordRepeatWithName(widget.babyName!);
    }
    return l10n.quickRecordRepeat;
  }

  /// MB-03: 요약 + 시간 (예: "모유 120ml (5분 전)")
  String _getSummaryWithTime() {
    final summary = _getRecordSummary();
    final timeAgo = _getTimeAgo();
    if (timeAgo.isNotEmpty) {
      return '$summary ($timeAgo)';
    }
    return summary;
  }

  /// MB-03: 상대 시간 표시 (예: "5분 전", "1시간 전")
  String _getTimeAgo() {
    if (widget.lastRecord == null) return '';

    final l10n = S.of(context)!;
    final now = DateTime.now();
    final recordTime = widget.lastRecord!.startTime;
    final diff = now.difference(recordTime);

    if (diff.inMinutes < 1) {
      return l10n.timeAgoJustNow;
    } else if (diff.inMinutes < 60) {
      return l10n.timeAgoMinutes(diff.inMinutes);
    } else if (diff.inHours < 24) {
      return l10n.timeAgoHours(diff.inHours);
    } else {
      return l10n.daysAgoCount(diff.inDays);
    }
  }

  String _getRecordSummary() {
    final l10n = S.of(context)!;
    final data = widget.lastRecord?.data;
    if (data == null) return l10n.labelRecord;

    switch (widget.activityType) {
      case ActivityType.feeding:
        final feedingType = data['feeding_type'] as String?;
        final amount = data['amount_ml'] as num?;
        final duration = data['duration_minutes'] as int?;

        final typeStr = switch (feedingType) {
          'breast' => l10n.feedingTypeBreast,
          'bottle' => l10n.feedingTypeBottle,
          'formula' => l10n.feedingTypeFormula,
          'solid' => l10n.feedingTypeSolid,
          _ => l10n.activityTypeFeeding,
        };

        if (amount != null && amount > 0) {
          return '$typeStr ${amount.toInt()}ml';
        }
        if (duration != null && duration > 0) {
          return '$typeStr ${l10n.unitMinutes(duration)}';
        }
        return typeStr;

      case ActivityType.sleep:
        final sleepType = data['sleep_type'] as String?;
        return sleepType == 'nap' ? l10n.sleepTypeNap : l10n.sleepTypeNight;

      case ActivityType.diaper:
        final diaperType = data['diaper_type'] as String?;
        return switch (diaperType) {
          'wet' => l10n.diaperTypeWet,
          'dirty' => l10n.diaperTypeDirty,
          'both' => l10n.diaperTypeBoth,
          'dry' => l10n.diaperTypeDry,
          _ => l10n.activityTypeDiaper,
        };

      case ActivityType.play:
        final playType = data['play_type'] as String?;
        final duration = data['duration_minutes'] as int?;
        final typeStr = switch (playType) {
          'tummy_time' => l10n.playTypeTummyTime,
          'bath' => l10n.playTypeBath,
          'outdoor' => l10n.playTypeOutdoor,
          'play' => l10n.playTypeIndoor,
          'reading' => l10n.playTypeReading,
          _ => l10n.activityPlay,
        };
        if (duration != null && duration > 0) {
          return '$typeStr ${l10n.unitMinutes(duration)}';
        }
        return typeStr;

      case ActivityType.health:
        final healthType = data['health_type'] as String?;
        final temp = data['temperature'] as num?;
        if (temp != null) {
          return l10n.healthTempValue(temp.toStringAsFixed(1));
        }
        return switch (healthType) {
          'temperature' => l10n.healthTypeTemperature,
          'symptom' => l10n.healthTypeSymptom,
          'medication' => l10n.healthTypeMedicationShort,
          'hospital' => l10n.healthTypeHospital,
          _ => l10n.activityTypeHealth,
        };
    }
  }
}

/// MB-03: 툴팁 화살표 페인터
class _TooltipArrowPainter extends CustomPainter {
  final Color color;

  _TooltipArrowPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
