import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_typography.dart';
import '../../../core/design_system/lulu_spacing.dart';
import '../../../data/models/models.dart';
import '../../../shared/widgets/baby_tab_bar.dart';
import '../../home/providers/home_provider.dart';
import '../providers/growth_provider.dart';
import '../widgets/growth_loading_state.dart';
import '../widgets/growth_empty_state.dart';
import '../widgets/growth_error_state.dart';
import '../widgets/growth_summary_card.dart';
import '../widgets/growth_progress_card.dart';
import 'growth_input_screen.dart';
import 'growth_chart_screen.dart';

/// 성장 화면 (메인)
///
/// Progressive Disclosure 패턴:
/// - 카드 요약 뷰 (기본)
/// - 탭 시 상세 차트 화면으로 이동
///
/// UT 검증 완료 (시안 B+E 통합)
class GrowthScreen extends StatefulWidget {
  const GrowthScreen({super.key});

  @override
  State<GrowthScreen> createState() => _GrowthScreenState();
}

class _GrowthScreenState extends State<GrowthScreen> {
  late GrowthProvider _provider;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _provider = GrowthProvider();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initializeProvider();
      _initialized = true;
    }
  }

  Future<void> _initializeProvider() async {
    // HomeProvider에서 아기 데이터 가져오기
    final homeProvider = context.read<HomeProvider>();
    final babies = homeProvider.babies;

    if (babies.isEmpty) {
      debugPrint('⚠️ [GrowthScreen] No babies data available');
      return;
    }

    debugPrint('✅ [GrowthScreen] Initializing with babies: ${babies.map((b) => b.name).join(", ")}');
    await _provider.initialize(babies);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // HomeProvider 연동: 아기 데이터 확인
    return Consumer<HomeProvider>(
      builder: (context, homeProvider, _) {
        // 1. 아기 없음 상태
        if (homeProvider.babies.isEmpty) {
          return _buildEmptyBabiesState();
        }

        // 2. GrowthProvider로 성장 기록 관리
        return ChangeNotifierProvider.value(
          value: _provider,
          child: Consumer<GrowthProvider>(
            builder: (context, provider, child) {
              return Scaffold(
                backgroundColor: LuluColors.midnightNavy,
                appBar: AppBar(
                  backgroundColor: LuluColors.midnightNavy,
                  elevation: 0,
                  title: Text(
                    '성장',
                    style: LuluTextStyles.titleLarge.copyWith(
                      color: LuluTextColors.primary,
                    ),
                  ),
                  centerTitle: true,
                  actions: [
                    IconButton(
                      icon: Icon(
                        Icons.add_circle_outline,
                        color: LuluColors.lavenderMist,
                      ),
                      onPressed: () => _navigateToInput(context, provider),
                    ),
                  ],
                ),
                body: Column(
                  children: [
                    // 아기 탭바 (Sprint 6 리디자인)
                    BabyTabBar(
                      babies: provider.babies,
                      selectedBabyId: provider.selectedBabyId,
                      onBabyChanged: provider.selectBaby,
                    ),

                    // 콘텐츠
                    Expanded(
                      child: _buildContent(context, provider),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  /// 아기 정보 없음 상태
  Widget _buildEmptyBabiesState() {
    return Scaffold(
      backgroundColor: LuluColors.midnightNavy,
      appBar: AppBar(
        backgroundColor: LuluColors.midnightNavy,
        elevation: 0,
        title: Text(
          '성장',
          style: LuluTextStyles.titleLarge.copyWith(
            color: LuluTextColors.primary,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(LuluSpacing.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 아이콘
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: LuluColors.lavenderMist.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('👶', style: TextStyle(fontSize: 40)),
                ),
              ),

              const SizedBox(height: LuluSpacing.xl),

              // 메시지
              Text(
                '아기 정보가 없습니다',
                style: LuluTextStyles.titleMedium.copyWith(
                  color: LuluTextColors.primary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: LuluSpacing.md),

              Text(
                '온보딩을 완료해주세요',
                style: LuluTextStyles.bodyMedium.copyWith(
                  color: LuluTextColors.secondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, GrowthProvider provider) {
    return switch (provider.state) {
      GrowthScreenState.loading => const GrowthLoadingState(),
      GrowthScreenState.empty => GrowthEmptyState(
          babyName: provider.selectedBaby?.name,
          onAddRecord: () => _navigateToInput(context, provider),
        ),
      GrowthScreenState.error => GrowthErrorState(
          message: provider.errorMessage ?? '알 수 없는 오류',
          onRetry: provider.retry,
        ),
      GrowthScreenState.loaded => _buildLoadedContent(context, provider),
    };
  }

  Widget _buildLoadedContent(BuildContext context, GrowthProvider provider) {
    final measurement = provider.latestMeasurement;
    if (measurement == null) {
      return GrowthEmptyState(
        babyName: provider.selectedBaby?.name,
        onAddRecord: () => _navigateToInput(context, provider),
      );
    }

    return RefreshIndicator(
      onRefresh: provider.loadMeasurements,
      color: LuluColors.lavenderMist,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(LuluSpacing.lg),
        child: Column(
          children: [
            // 요약 카드
            GrowthSummaryCard(
              measurement: measurement,
              previousMeasurement: provider.previousMeasurement,
              percentiles: provider.percentiles,
              chartType: provider.chartType,
              correctedWeeks: provider.correctedWeeks,
              correctedMonths: provider.correctedMonths,
              onTap: () => _navigateToChartScreen(context, provider),
            ),

            const SizedBox(height: LuluSpacing.lg),

            // 진행률 카드
            GrowthProgressCard(
              percentiles: provider.percentiles,
            ),

            const SizedBox(height: LuluSpacing.lg),

            // 기록 추가 버튼
            _buildAddRecordButton(context, provider),

            const SizedBox(height: LuluSpacing.lg),

            // 최근 기록 목록
            _buildRecentRecords(provider),

            const SizedBox(height: 100), // 바텀 네비게이션 여백
          ],
        ),
      ),
    );
  }

  Widget _buildAddRecordButton(BuildContext context, GrowthProvider provider) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () => _navigateToInput(context, provider),
        style: OutlinedButton.styleFrom(
          foregroundColor: LuluColors.lavenderMist,
          side: BorderSide(color: LuluColors.lavenderMist),
          padding: const EdgeInsets.symmetric(vertical: LuluSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📝', style: TextStyle(fontSize: 18)),
            const SizedBox(width: LuluSpacing.sm),
            Text(
              '측정 기록 추가',
              style: LuluTextStyles.bodyMedium.copyWith(
                color: LuluColors.lavenderMist,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentRecords(GrowthProvider provider) {
    final records = provider.measurements.take(5).toList();
    if (records.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '최근 기록',
          style: LuluTextStyles.titleSmall.copyWith(
            color: LuluTextColors.primary,
          ),
        ),
        const SizedBox(height: LuluSpacing.md),
        ...records.map((record) => _buildRecordItem(record)),
      ],
    );
  }

  Widget _buildRecordItem(GrowthMeasurementModel record) {
    final daysAgo = DateTime.now().difference(record.measuredAt).inDays;
    final dateText = daysAgo == 0
        ? '오늘'
        : daysAgo == 1
            ? '어제'
            : '$daysAgo일 전';

    return Container(
      margin: const EdgeInsets.only(bottom: LuluSpacing.sm),
      padding: const EdgeInsets.all(LuluSpacing.md),
      decoration: BoxDecoration(
        color: LuluColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // 날짜
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dateText,
                style: LuluTextStyles.bodySmall.copyWith(
                  color: LuluTextColors.secondary,
                ),
              ),
            ],
          ),
          const Spacer(),
          // 측정값
          Text(
            '${record.weightKg.toStringAsFixed(2)}kg',
            style: LuluTextStyles.bodyMedium.copyWith(
              color: LuluTextColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (record.lengthCm != null) ...[
            const SizedBox(width: LuluSpacing.md),
            Text(
              '${record.lengthCm!.toStringAsFixed(1)}cm',
              style: LuluTextStyles.bodyMedium.copyWith(
                color: LuluTextColors.secondary,
              ),
            ),
          ],
        ],
      ),
    );
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

  void _navigateToChartScreen(BuildContext context, GrowthProvider provider) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: provider,
          child: const GrowthChartScreen(),
        ),
      ),
    );
  }
}
