import 'package:flutter/material.dart';

import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_icons.dart';
import '../../../core/design_system/lulu_typography.dart';
import '../../../core/design_system/lulu_spacing.dart';
import '../../../core/constants/animation_constants.dart';
import '../providers/growth_provider.dart';

/// 성장 진행률 카드
///
/// 백분위수 시각화 (진행률 바)
/// 체중, 신장, 두위 3개 지표
class GrowthProgressCard extends StatelessWidget {
  final GrowthPercentiles? percentiles;

  const GrowthProgressCard({
    super.key,
    this.percentiles,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(LuluSpacing.lg),
      decoration: BoxDecoration(
        color: LuluColors.deepBlue,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: LuluColors.surfaceElevated,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(
            children: [
              Icon(LuluIcons.growth, size: 20, color: LuluColors.lavenderMist),
              const SizedBox(width: LuluSpacing.sm),
              Text(
                '성장 백분위',
                style: LuluTextStyles.titleSmall.copyWith(
                  color: LuluTextColors.primary,
                ),
              ),
            ],
          ),

          const SizedBox(height: LuluSpacing.lg),

          // 체중 진행률
          _PercentileBar(
            label: '체중',
            icon: LuluIcons.weight,
            percentile: percentiles?.weight,
          ),

          const SizedBox(height: LuluSpacing.md),

          // 신장 진행률
          _PercentileBar(
            label: '신장',
            icon: LuluIcons.ruler,
            percentile: percentiles?.length,
          ),

          const SizedBox(height: LuluSpacing.md),

          // 두위 진행률
          _PercentileBar(
            label: '두위',
            icon: LuluIcons.head,
            percentile: percentiles?.headCircumference,
          ),

          const SizedBox(height: LuluSpacing.lg),

          // 범례
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LegendItem(color: LuluStatusColors.caution, label: '<3%'),
        const SizedBox(width: LuluSpacing.md),
        _LegendItem(color: LuluStatusColors.warning, label: '3-10%'),
        const SizedBox(width: LuluSpacing.md),
        _LegendItem(color: LuluStatusColors.success, label: '10-90%'),
        const SizedBox(width: LuluSpacing.md),
        _LegendItem(color: LuluStatusColors.warning, label: '90-97%'),
        const SizedBox(width: LuluSpacing.md),
        _LegendItem(color: LuluStatusColors.caution, label: '>97%'),
      ],
    );
  }
}

class _PercentileBar extends StatefulWidget {
  final String label;
  final IconData icon;
  final double? percentile;

  const _PercentileBar({
    required this.label,
    required this.icon,
    this.percentile,
  });

  @override
  State<_PercentileBar> createState() => _PercentileBarState();
}

class _PercentileBarState extends State<_PercentileBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: LuluAnimations.normal,
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: (widget.percentile ?? 50) / 100,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: LuluAnimations.standard,
    ));
    _controller.forward();
  }

  @override
  void didUpdateWidget(_PercentileBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.percentile != widget.percentile) {
      _animation = Tween<double>(
        begin: _animation.value,
        end: (widget.percentile ?? 50) / 100,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: LuluAnimations.standard,
      ));
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final percentile = widget.percentile;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(widget.icon, size: 14, color: LuluTextColors.secondary),
            const SizedBox(width: LuluSpacing.xs),
            Text(
              widget.label,
              style: LuluTextStyles.bodySmall.copyWith(
                color: LuluTextColors.secondary,
              ),
            ),
            const Spacer(),
            Text(
              percentile != null ? '${percentile.round()}%' : '측정 필요',
              style: LuluTextStyles.bodySmall.copyWith(
                color: percentile != null
                    ? _getPercentileColor(percentile)
                    : LuluTextColors.tertiary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: LuluSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 8,
            child: Stack(
              children: [
                // 배경
                Container(
                  decoration: BoxDecoration(
                    color: LuluColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                // 진행 바
                if (percentile != null)
                  AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return FractionallySizedBox(
                        widthFactor: _animation.value.clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _getPercentileColor(percentile),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      );
                    },
                  ),
                // 구간 마커
                ..._buildMarkers(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildMarkers() {
    // 3%, 10%, 50%, 90%, 97% 마커
    final markers = [0.03, 0.10, 0.50, 0.90, 0.97];
    return markers.map((pos) {
      return Positioned(
        left: 0,
        right: 0,
        child: FractionallySizedBox(
          widthFactor: 1,
          child: Align(
            alignment: Alignment(pos * 2 - 1, 0),
            child: Container(
              width: 1,
              height: 8,
              color: LuluColors.midnightNavy.withValues(alpha: 0.5),
            ),
          ),
        ),
      );
    }).toList();
  }

  Color _getPercentileColor(double percentile) {
    if (percentile < 3 || percentile > 97) return LuluStatusColors.caution;
    if (percentile < 10 || percentile > 90) return LuluStatusColors.warning;
    return LuluStatusColors.success;
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: LuluTextStyles.caption.copyWith(
            color: LuluTextColors.tertiary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
