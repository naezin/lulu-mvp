import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_spacing.dart';
import '../../../core/design_system/lulu_typography.dart';

/// PL-01: 터미타임 타이머 위젯
///
/// 기능:
/// - 시작/일시정지/완료 버튼
/// - 경과 시간 실시간 표시
/// - 권장 시간(3-5분) 달성 시 알림
/// - 완료 시 콜백으로 시간 전달
class TummyTimeTimer extends StatefulWidget {
  /// 타이머 완료 시 콜백 (경과 분)
  final void Function(int minutes) onComplete;

  /// 시작 버튼 탭 시 콜백
  final VoidCallback? onStart;

  /// 기본 권장 시간 (분)
  final int recommendedMinutes;

  const TummyTimeTimer({
    super.key,
    required this.onComplete,
    this.onStart,
    this.recommendedMinutes = 5,
  });

  @override
  State<TummyTimeTimer> createState() => _TummyTimeTimerState();
}

class _TummyTimeTimerState extends State<TummyTimeTimer>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  int _elapsedSeconds = 0;
  bool _isRunning = false;
  bool _hasReachedGoal = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startTimer() {
    if (_isRunning) return;

    setState(() => _isRunning = true);
    widget.onStart?.call();
    _pulseController.repeat(reverse: true);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedSeconds++;

        // 권장 시간 달성 시 햅틱 피드백
        if (!_hasReachedGoal &&
            _elapsedSeconds >= widget.recommendedMinutes * 60) {
          _hasReachedGoal = true;
          HapticFeedback.mediumImpact();
        }
      });
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    _pulseController.stop();
    setState(() => _isRunning = false);
  }

  void _completeTimer() {
    _timer?.cancel();
    _pulseController.stop();

    final minutes = (_elapsedSeconds / 60).ceil();
    widget.onComplete(minutes > 0 ? minutes : 1);

    setState(() {
      _isRunning = false;
      _elapsedSeconds = 0;
      _hasReachedGoal = false;
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    _pulseController.stop();
    setState(() {
      _isRunning = false;
      _elapsedSeconds = 0;
      _hasReachedGoal = false;
    });
  }

  String get _formattedTime {
    final minutes = _elapsedSeconds ~/ 60;
    final seconds = _elapsedSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  double get _progress {
    final goalSeconds = widget.recommendedMinutes * 60;
    return (_elapsedSeconds / goalSeconds).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(LuluSpacing.lg),
      decoration: BoxDecoration(
        color: LuluActivityColors.playBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _hasReachedGoal
              ? LuluStatusColors.success
              : LuluActivityColors.play.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          // 상태 배지
          if (_hasReachedGoal)
            Container(
              margin: const EdgeInsets.only(bottom: LuluSpacing.md),
              padding: const EdgeInsets.symmetric(
                horizontal: LuluSpacing.md,
                vertical: LuluSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: LuluStatusColors.successSoft,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: LuluStatusColors.success,
                    size: 16,
                  ),
                  const SizedBox(width: LuluSpacing.xs),
                  Text(
                    '권장 시간 달성!',
                    style: LuluTextStyles.labelSmall.copyWith(
                      color: LuluStatusColors.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

          // 타이머 디스플레이
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _isRunning ? _pulseAnimation.value : 1.0,
                child: child,
              );
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 프로그레스 링
                SizedBox(
                  width: 140,
                  height: 140,
                  child: CircularProgressIndicator(
                    value: _progress,
                    strokeWidth: 8,
                    backgroundColor: LuluColors.surfaceElevated,
                    color: _hasReachedGoal
                        ? LuluStatusColors.success
                        : LuluActivityColors.play,
                  ),
                ),
                // 시간 표시
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formattedTime,
                      style: LuluTextStyles.displayMedium.copyWith(
                        color: LuluTextColors.primary,
                        fontWeight: FontWeight.bold,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    Text(
                      '목표: ${widget.recommendedMinutes}분',
                      style: LuluTextStyles.caption.copyWith(
                        color: LuluTextColors.tertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: LuluSpacing.lg),

          // 컨트롤 버튼
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!_isRunning && _elapsedSeconds == 0)
                // 시작 버튼
                _TimerButton(
                  icon: Icons.play_arrow_rounded,
                  label: '시작',
                  color: LuluActivityColors.play,
                  onTap: _startTimer,
                )
              else if (_isRunning)
                // 일시정지 버튼
                Row(
                  children: [
                    _TimerButton(
                      icon: Icons.pause_rounded,
                      label: '일시정지',
                      color: LuluStatusColors.warning,
                      onTap: _pauseTimer,
                    ),
                    const SizedBox(width: LuluSpacing.md),
                    _TimerButton(
                      icon: Icons.check_rounded,
                      label: '완료',
                      color: LuluStatusColors.success,
                      onTap: _completeTimer,
                    ),
                  ],
                )
              else
                // 일시정지 상태
                Row(
                  children: [
                    _TimerButton(
                      icon: Icons.play_arrow_rounded,
                      label: '계속',
                      color: LuluActivityColors.play,
                      onTap: _startTimer,
                    ),
                    const SizedBox(width: LuluSpacing.md),
                    _TimerButton(
                      icon: Icons.check_rounded,
                      label: '완료',
                      color: LuluStatusColors.success,
                      onTap: _completeTimer,
                    ),
                    const SizedBox(width: LuluSpacing.md),
                    _TimerButton(
                      icon: Icons.refresh_rounded,
                      label: '초기화',
                      color: LuluTextColors.tertiary,
                      onTap: _resetTimer,
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 타이머 컨트롤 버튼
class _TimerButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _TimerButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: LuluSpacing.xs),
          Text(
            label,
            style: LuluTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
