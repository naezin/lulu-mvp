import 'package:flutter/material.dart';
import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_radius.dart';
import '../../../core/design_system/lulu_spacing.dart';

/// 성장 화면 로딩 상태
///
/// Shimmer 효과로 레이아웃 시프트 방지
class GrowthLoadingState extends StatefulWidget {
  const GrowthLoadingState({super.key});

  @override
  State<GrowthLoadingState> createState() => _GrowthLoadingStateState();
}

class _GrowthLoadingStateState extends State<GrowthLoadingState>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Padding(
          padding: const EdgeInsets.all(LuluSpacing.lg),
          child: Column(
            children: [
              // 요약 카드 스켈레톤
              _buildSkeletonCard(height: 180),
              const SizedBox(height: LuluSpacing.lg),

              // 진행률 카드 스켈레톤
              _buildSkeletonCard(height: 120),
              const SizedBox(height: LuluSpacing.lg),

              // 차트 영역 스켈레톤
              _buildSkeletonCard(height: 200),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSkeletonCard({required double height}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(LuluRadius.md),
        gradient: LinearGradient(
          begin: Alignment(_animation.value - 1, 0),
          end: Alignment(_animation.value, 0),
          colors: [
            LuluColors.surfaceElevated,
            LuluColors.surfaceElevatedMedium,
            LuluColors.surfaceElevated,
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(LuluSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSkeletonLine(width: 120, height: 16),
            const SizedBox(height: LuluSpacing.md),
            _buildSkeletonLine(width: 200, height: 12),
            const Spacer(),
            _buildSkeletonLine(width: double.infinity, height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonLine({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: LuluColors.deepBlue,
        borderRadius: BorderRadius.circular(LuluRadius.indicator),
      ),
    );
  }
}
