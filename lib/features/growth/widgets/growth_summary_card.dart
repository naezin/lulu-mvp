import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_radius.dart';
import '../../../core/design_system/lulu_icons.dart';
import '../../../core/design_system/lulu_typography.dart';
import '../../../core/design_system/lulu_spacing.dart';
import '../../../core/constants/animation_constants.dart';
import '../../../data/models/growth_measurement_model.dart';
import '../data/growth_data_cache.dart';
import '../providers/growth_provider.dart';

/// 성장 요약 카드
///
/// 최신 측정값 + 백분위수 + 차트 유형 표시
/// Progressive Disclosure: 탭하면 상세 화면으로 이동
class GrowthSummaryCard extends StatefulWidget {
  final GrowthMeasurementModel measurement;
  final GrowthMeasurementModel? previousMeasurement;
  final GrowthPercentiles? percentiles;
  final GrowthChartType chartType;
  final int? correctedWeeks;
  final int correctedMonths;
  final VoidCallback? onTap;

  const GrowthSummaryCard({
    super.key,
    required this.measurement,
    this.previousMeasurement,
    this.percentiles,
    required this.chartType,
    this.correctedWeeks,
    required this.correctedMonths,
    this.onTap,
  });

  @override
  State<GrowthSummaryCard> createState() => _GrowthSummaryCardState();
}

class _GrowthSummaryCardState extends State<GrowthSummaryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: LuluAnimations.normal,
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: LuluAnimations.enter),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: LuluAnimations.enter));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            padding: const EdgeInsets.all(LuluSpacing.lg),
            decoration: BoxDecoration(
              color: LuluColors.deepBlue,
              borderRadius: BorderRadius.circular(LuluRadius.lg),
              border: Border.all(
                color: LuluColors.lavenderSelected,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 헤더
                _buildHeader(),
                const SizedBox(height: LuluSpacing.lg),

                // 측정값 그리드
                _buildMeasurementGrid(),

                const SizedBox(height: LuluSpacing.lg),

                // 차트 유형 + 연령 정보
                _buildChartInfo(),

                // 상세 보기 힌트
                if (widget.onTap != null) ...[
                  const SizedBox(height: LuluSpacing.md),
                  _buildDetailHint(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final formatter = DateFormat('M월 d일', 'ko_KR');
    final daysAgo = DateTime.now().difference(widget.measurement.measuredAt).inDays;
    final dateText = daysAgo == 0
        ? '오늘'
        : daysAgo == 1
            ? '어제'
            : '$daysAgo일 전';

    return Row(
      children: [
        Icon(LuluIcons.chart, size: 24, color: LuluColors.lavenderMist),
        const SizedBox(width: LuluSpacing.sm),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '성장 현황',
              style: LuluTextStyles.titleMedium.copyWith(
                color: LuluTextColors.primary,
              ),
            ),
            Text(
              '${formatter.format(widget.measurement.measuredAt)} 측정 ($dateText)',
              style: LuluTextStyles.caption.copyWith(
                color: LuluTextColors.secondary,
              ),
            ),
          ],
        ),
        const Spacer(),
        if (widget.onTap != null)
          Icon(
            LuluIcons.chevronRight,
            color: LuluTextColors.tertiary,
          ),
      ],
    );
  }

  Widget _buildMeasurementGrid() {
    return Row(
      children: [
        // 체중
        Expanded(
          child: _MeasurementItem(
            icon: LuluIcons.weight,
            label: '체중',
            value: '${widget.measurement.weightKg.toStringAsFixed(2)} kg',
            percentile: widget.percentiles?.weight,
            change: widget.previousMeasurement != null
                ? widget.measurement.weightKg - widget.previousMeasurement!.weightKg
                : null,
            changeUnit: 'kg',
          ),
        ),
        const SizedBox(width: LuluSpacing.md),

        // 신장
        Expanded(
          child: _MeasurementItem(
            icon: LuluIcons.ruler,
            label: '신장',
            value: widget.measurement.lengthCm != null
                ? '${widget.measurement.lengthCm!.toStringAsFixed(1)} cm'
                : '미측정',
            percentile: widget.percentiles?.length,
            change: widget.previousMeasurement?.lengthCm != null &&
                    widget.measurement.lengthCm != null
                ? widget.measurement.lengthCm! - widget.previousMeasurement!.lengthCm!
                : null,
            changeUnit: 'cm',
          ),
        ),
        const SizedBox(width: LuluSpacing.md),

        // 두위
        Expanded(
          child: _MeasurementItem(
            icon: LuluIcons.head,
            label: '두위',
            value: widget.measurement.headCircumferenceCm != null
                ? '${widget.measurement.headCircumferenceCm!.toStringAsFixed(1)} cm'
                : '미측정',
            percentile: widget.percentiles?.headCircumference,
            change: widget.previousMeasurement?.headCircumferenceCm != null &&
                    widget.measurement.headCircumferenceCm != null
                ? widget.measurement.headCircumferenceCm! -
                    widget.previousMeasurement!.headCircumferenceCm!
                : null,
            changeUnit: 'cm',
          ),
        ),
      ],
    );
  }

  Widget _buildChartInfo() {
    final ageText = widget.chartType == GrowthChartType.fenton
        ? '${widget.correctedWeeks}주'
        : '${widget.correctedMonths}개월';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: LuluSpacing.md,
        vertical: LuluSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: LuluColors.surfaceElevated,
        borderRadius: BorderRadius.circular(LuluRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            widget.chartType == GrowthChartType.fenton
                ? LuluIcons.calendar
                : LuluIcons.growth,
            size: 14,
            color: LuluColors.lavenderMist,
          ),
          const SizedBox(width: LuluSpacing.xs),
          Text(
            '${widget.chartType.label} 적용',
            style: LuluTextStyles.caption.copyWith(
              color: LuluColors.lavenderMist,
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: LuluSpacing.sm),
            width: 1,
            height: 12,
            color: LuluTextColors.tertiary,
          ),
          Text(
            '교정연령 $ageText',
            style: LuluTextStyles.caption.copyWith(
              color: LuluTextColors.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailHint() {
    return Center(
      child: Text(
        '탭하여 성장 차트 보기',
        style: LuluTextStyles.caption.copyWith(
          color: LuluTextColors.tertiary,
        ),
      ),
    );
  }
}

class _MeasurementItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final double? percentile;
  final double? change;
  final String changeUnit;

  const _MeasurementItem({
    required this.icon,
    required this.label,
    required this.value,
    this.percentile,
    this.change,
    required this.changeUnit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(LuluSpacing.md),
      decoration: BoxDecoration(
        color: LuluColors.surfaceElevated,
        borderRadius: BorderRadius.circular(LuluRadius.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: LuluTextColors.secondary),
              const SizedBox(width: LuluSpacing.xs),
              Text(
                label,
                style: LuluTextStyles.caption.copyWith(
                  color: LuluTextColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: LuluSpacing.xs),
          Text(
            value,
            style: LuluTextStyles.bodyLarge.copyWith(
              color: LuluTextColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (percentile != null) ...[
            const SizedBox(height: LuluSpacing.xs),
            Text(
              '${percentile!.round()}%ile',
              style: LuluTextStyles.caption.copyWith(
                color: LuluColors.lavenderMist,
              ),
            ),
          ],
          if (change != null) ...[
            const SizedBox(height: LuluSpacing.xs),
            Text(
              '${change! >= 0 ? '+' : ''}${change!.toStringAsFixed(1)}$changeUnit',
              style: LuluTextStyles.caption.copyWith(
                color: change! >= 0
                    ? LuluStatusColors.success
                    : LuluStatusColors.warning,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
