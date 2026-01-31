import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_icons.dart';
import '../../../core/design_system/lulu_typography.dart';
import '../../../core/design_system/lulu_spacing.dart';
import '../data/fenton_data.dart';
import '../data/growth_data_cache.dart';
import '../providers/growth_provider.dart';
import '../widgets/growth_chart.dart';
import 'growth_input_screen.dart';

/// 성장 차트 상세 화면
///
/// 전체 화면 차트 뷰
/// 체중/신장/두위 탭 전환
class GrowthChartScreen extends StatefulWidget {
  const GrowthChartScreen({super.key});

  @override
  State<GrowthChartScreen> createState() => _GrowthChartScreenState();
}

class _GrowthChartScreenState extends State<GrowthChartScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  GrowthMetric _selectedMetric = GrowthMetric.weight;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() {
        _selectedMetric = GrowthMetric.values[_tabController.index];
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GrowthProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: LuluColors.midnightNavy,
          appBar: AppBar(
            backgroundColor: LuluColors.midnightNavy,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: LuluTextColors.primary),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              '${provider.selectedBaby?.name ?? '아기'} 성장 차트',
              style: LuluTextStyles.titleMedium.copyWith(
                color: LuluTextColors.primary,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.add_circle_outline,
                  color: LuluColors.lavenderMist,
                ),
                onPressed: () => _navigateToInput(context, provider),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: _buildMetricTabs(),
            ),
          ),
          body: Column(
            children: [
              // 차트 정보
              _buildChartInfo(provider),

              // 차트
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(LuluSpacing.lg),
                  child: GrowthChart(
                    chartType: provider.chartType,
                    metric: _selectedMetric,
                    gender: provider.gender,
                    measurements: provider.measurements,
                    showAnimation: true,
                  ),
                ),
              ),

              // 현재 상태
              _buildCurrentStatus(provider),

              const SizedBox(height: LuluSpacing.lg),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: LuluSpacing.lg),
      decoration: BoxDecoration(
        color: LuluColors.deepBlue,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: LuluColors.lavenderMist.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: LuluColors.lavenderMist,
        unselectedLabelColor: LuluTextColors.secondary,
        labelStyle: LuluTextStyles.bodySmall.copyWith(
          fontWeight: FontWeight.w600,
        ),
        dividerColor: Colors.transparent,
        tabs: [
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LuluIcons.weight, size: 14),
                const SizedBox(width: 4),
                const Text('체중'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LuluIcons.ruler, size: 14),
                const SizedBox(width: 4),
                const Text('신장'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LuluIcons.head, size: 14),
                const SizedBox(width: 4),
                const Text('두위'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartInfo(GrowthProvider provider) {
    return Container(
      margin: const EdgeInsets.all(LuluSpacing.lg),
      padding: const EdgeInsets.symmetric(
        horizontal: LuluSpacing.lg,
        vertical: LuluSpacing.md,
      ),
      decoration: BoxDecoration(
        color: LuluColors.deepBlue,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // 차트 유형
          _InfoChip(
            icon: provider.chartType == GrowthChartType.fenton
                ? LuluIcons.calendar
                : LuluIcons.growth,
            label: provider.chartType.label,
          ),

          const SizedBox(width: LuluSpacing.md),

          // 교정연령
          _InfoChip(
            icon: LuluIcons.baby,
            label: provider.chartType == GrowthChartType.fenton
                ? '${provider.correctedWeeks ?? 0}주'
                : '${provider.correctedMonths}개월',
          ),

          const Spacer(),

          // 차트 전환 예정 안내
          if (provider.chartType == GrowthChartType.fenton &&
              (provider.correctedWeeks ?? 0) >= 45)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: LuluSpacing.sm,
                vertical: LuluSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: LuluColors.champagneGold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'WHO 차트 전환 예정',
                style: LuluTextStyles.caption.copyWith(
                  color: LuluColors.champagneGold,
                  fontSize: 10,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCurrentStatus(GrowthProvider provider) {
    final percentiles = provider.percentiles;
    final percentile = switch (_selectedMetric) {
      GrowthMetric.weight => percentiles?.weight,
      GrowthMetric.length => percentiles?.length,
      GrowthMetric.headCircumference => percentiles?.headCircumference,
    };

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: LuluSpacing.lg),
      padding: const EdgeInsets.all(LuluSpacing.lg),
      decoration: BoxDecoration(
        color: LuluColors.deepBlue,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // 현재 값
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '현재 ${_selectedMetric.label}',
                style: LuluTextStyles.caption.copyWith(
                  color: LuluTextColors.secondary,
                ),
              ),
              Text(
                _getCurrentValue(provider),
                style: LuluTextStyles.titleMedium.copyWith(
                  color: LuluTextColors.primary,
                ),
              ),
            ],
          ),

          const Spacer(),

          // 백분위
          if (percentile != null)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: LuluSpacing.lg,
                vertical: LuluSpacing.md,
              ),
              decoration: BoxDecoration(
                color: _getPercentileColor(percentile).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    '${percentile.round()}%',
                    style: LuluTextStyles.titleLarge.copyWith(
                      color: _getPercentileColor(percentile),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '백분위',
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

  String _getCurrentValue(GrowthProvider provider) {
    final measurement = provider.latestMeasurement;
    if (measurement == null) return '측정 필요';

    return switch (_selectedMetric) {
      GrowthMetric.weight =>
        '${measurement.weightKg.toStringAsFixed(2)} ${_selectedMetric.unit}',
      GrowthMetric.length => measurement.lengthCm != null
          ? '${measurement.lengthCm!.toStringAsFixed(1)} ${_selectedMetric.unit}'
          : '미측정',
      GrowthMetric.headCircumference => measurement.headCircumferenceCm != null
          ? '${measurement.headCircumferenceCm!.toStringAsFixed(1)} ${_selectedMetric.unit}'
          : '미측정',
    };
  }

  Color _getPercentileColor(double percentile) {
    if (percentile < 3 || percentile > 97) return LuluStatusColors.caution;
    if (percentile < 10 || percentile > 90) return LuluStatusColors.warning;
    return LuluStatusColors.success;
  }

  void _navigateToInput(BuildContext context, GrowthProvider provider) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GrowthInputScreen(
          babies: provider.babies,
          initialBabyId: provider.selectedBabyId,
          previousMeasurement: provider.latestMeasurement,
          onSave: (measurement) {
            provider.addMeasurement(measurement);
          },
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: LuluSpacing.md,
        vertical: LuluSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: LuluColors.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: LuluColors.lavenderMist),
          const SizedBox(width: LuluSpacing.xs),
          Text(
            label,
            style: LuluTextStyles.caption.copyWith(
              color: LuluTextColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
