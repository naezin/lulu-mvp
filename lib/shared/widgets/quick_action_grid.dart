import 'package:flutter/material.dart';

import '../../core/design_system/lulu_colors.dart';
import '../../core/design_system/lulu_icons.dart';
import '../../core/design_system/lulu_spacing.dart';
import '../../core/design_system/lulu_typography.dart';

/// Quick Action 버튼 그리드 (Sprint 6 Day 2)
///
/// F-3 컴팩트 레이아웃의 핵심 컴포넌트
/// - 버튼 크기: 64x64dp (야간 대응)
/// - 5종 기록: 수유, 수면, 기저귀, 놀이, 건강
class QuickActionGrid extends StatelessWidget {
  final VoidCallback? onFeedingTap;
  final VoidCallback? onSleepTap;
  final VoidCallback? onDiaperTap;
  final VoidCallback? onPlayTap;
  final VoidCallback? onHealthTap;

  const QuickActionGrid({
    super.key,
    this.onFeedingTap,
    this.onSleepTap,
    this.onDiaperTap,
    this.onPlayTap,
    this.onHealthTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(LuluSpacing.lg),
      decoration: BoxDecoration(
        color: LuluColors.deepBlue,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: LuluColors.glassBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '빠른 기록',
            style: LuluTextStyles.labelMedium.copyWith(
              color: LuluTextColors.secondary,
            ),
          ),
          const SizedBox(height: LuluSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _QuickActionButton(
                icon: LuluIcons.feeding,
                label: '수유',
                color: LuluActivityColors.feeding,
                onTap: onFeedingTap,
              ),
              _QuickActionButton(
                icon: LuluIcons.sleep,
                label: '수면',
                color: LuluActivityColors.sleep,
                onTap: onSleepTap,
              ),
              _QuickActionButton(
                icon: LuluIcons.diaper,
                label: '기저귀',
                color: LuluActivityColors.diaper,
                onTap: onDiaperTap,
              ),
              _QuickActionButton(
                icon: LuluIcons.play,
                label: '놀이',
                color: LuluActivityColors.play,
                onTap: onPlayTap,
              ),
              _QuickActionButton(
                icon: LuluIcons.health,
                label: '건강',
                color: LuluActivityColors.health,
                onTap: onHealthTap,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Quick Action 개별 버튼 (터치 피드백 포함)
class _QuickActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  State<_QuickActionButton> createState() => _QuickActionButtonState();
}

class _QuickActionButtonState extends State<_QuickActionButton>
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
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap?.call();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 64x64dp 버튼 (야간 대응)
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.color.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Center(
                child: Icon(
                  widget.icon,
                  size: 28,
                  color: widget.color,
                ),
              ),
            ),
            const SizedBox(height: LuluSpacing.xs),
            Text(
              widget.label,
              style: LuluTextStyles.caption.copyWith(
                color: LuluTextColors.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
