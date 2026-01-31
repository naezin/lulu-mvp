import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_icons.dart';
import '../../../core/design_system/lulu_typography.dart';
import '../../../core/design_system/lulu_spacing.dart';
import '../../../data/models/models.dart';
import '../../../shared/widgets/baby_tab_bar.dart';
import '../../../shared/widgets/quick_action_grid.dart';
import '../../../shared/widgets/cry_analysis_placeholder.dart';
import '../../../shared/widgets/mini_timeline.dart';
import '../providers/home_provider.dart';
import '../widgets/sweet_spot_hero_card.dart';
import '../widgets/last_activity_card.dart';
import '../widgets/today_summary_card.dart';
import '../widgets/ongoing_sleep_card.dart';
import '../../record/providers/ongoing_sleep_provider.dart';

/// 홈 화면 (시안 B-4 기반)
///
/// UT 검증 완료:
/// - SAT: 4.58/5
/// - TTC: 3.2초
/// - 핵심 타겟(P2) 만족도: 5.0/5
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LuluColors.midnightNavy,
      body: SafeArea(
        child: Consumer<HomeProvider>(
          builder: (context, homeProvider, child) {
            return CustomScrollView(
              slivers: [
                // App Bar
                SliverAppBar(
                  backgroundColor: LuluColors.midnightNavy,
                  floating: true,
                  elevation: 0,
                  leading: Padding(
                    padding: const EdgeInsets.only(left: LuluSpacing.lg),
                    child: Icon(
                      Icons.menu,
                      color: LuluTextColors.secondary,
                    ),
                  ),
                  title: Text(
                    'Lulu',
                    style: LuluTextStyles.titleLarge.copyWith(
                      color: LuluColors.champagneGold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  centerTitle: true,
                  actions: [
                    Padding(
                      padding: const EdgeInsets.only(right: LuluSpacing.lg),
                      child: Icon(
                        Icons.settings_outlined,
                        color: LuluTextColors.secondary,
                      ),
                    ),
                  ],
                ),

                // Content
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: LuluSpacing.lg),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: LuluSpacing.md),

                      // 아기 탭바 (Sprint 6 리디자인)
                      BabyTabBar(
                        babies: homeProvider.babies,
                        selectedBabyId: homeProvider.selectedBabyId,
                        onBabyChanged: homeProvider.selectBaby,
                      ),

                      const SizedBox(height: LuluSpacing.lg),

                      // QA-03: 진행 중인 수면 카드 (아기가 있을 때 모든 상태에서 표시)
                      if (homeProvider.babies.isNotEmpty)
                        Consumer<OngoingSleepProvider>(
                          builder: (context, sleepProvider, _) {
                            // 현재 선택된 아기의 수면만 표시
                            if (sleepProvider.hasSleepInProgress &&
                                sleepProvider.currentBabyId == homeProvider.selectedBabyId) {
                              return const Padding(
                                padding: EdgeInsets.only(bottom: LuluSpacing.lg),
                                child: OngoingSleepCard(),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),

                      // 아기가 없으면 빈 상태
                      if (homeProvider.babies.isEmpty)
                        _buildEmptyBabiesState()
                      // 아기는 있지만 활동이 없으면 빈 활동 상태 (BUG-002 FIX: 필터링된 활동 사용)
                      else if (homeProvider.filteredTodayActivities.isEmpty)
                        _buildEmptyActivitiesState(homeProvider)
                      // 정상 상태: 모든 카드 표시
                      else
                        _buildNormalContent(context, homeProvider),

                      const SizedBox(height: 100), // FAB 공간
                    ]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// 아기 정보 없음 상태
  Widget _buildEmptyBabiesState() {
    return Container(
      padding: const EdgeInsets.all(LuluSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Icon(
            LuluIcons.baby,
            size: 64,
            color: LuluTextColors.tertiary,
          ),
          const SizedBox(height: LuluSpacing.lg),
          Text(
            '아기 정보가 없습니다',
            style: LuluTextStyles.titleMedium.copyWith(
              color: LuluTextColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: LuluSpacing.sm),
          Text(
            '온보딩을 완료해주세요',
            style: LuluTextStyles.bodyMedium.copyWith(
              color: LuluTextColors.secondary,
            ),
          ),
        ],
      ),
    );
  }

  /// 활동 없음 상태 (아기 정보는 있음)
  Widget _buildEmptyActivitiesState(HomeProvider homeProvider) {
    final selectedBaby = homeProvider.selectedBaby;
    final babyName = selectedBaby?.name ?? '아기';

    return Column(
      children: [
        // Sweet Spot 카드 (빈 상태용)
        _buildEmptySweetSpotCard(selectedBaby),

        const SizedBox(height: LuluSpacing.lg),

        // 첫 기록 유도 카드
        Container(
          padding: const EdgeInsets.all(LuluSpacing.xl),
          decoration: BoxDecoration(
            color: LuluColors.deepBlue,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: LuluColors.lavenderMist.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                LuluIcons.celebration,
                size: 48,
                color: LuluColors.champagneGold,
              ),
              const SizedBox(height: LuluSpacing.md),
              Text(
                '$babyName의 첫 기록을 시작해보세요',
                style: LuluTextStyles.titleMedium.copyWith(
                  color: LuluTextColors.primary,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: LuluSpacing.sm),
              Text(
                '아래 + 버튼을 눌러\n수유, 수면, 기저귀 기록을 시작하세요',
                style: LuluTextStyles.bodyMedium.copyWith(
                  color: LuluTextColors.secondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: LuluSpacing.lg),
              // 기록 유형 힌트
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildRecordHintWithIcon(LuluIcons.feeding, '수유', LuluActivityColors.feeding),
                  _buildRecordHintWithIcon(LuluIcons.sleep, '수면', LuluActivityColors.sleep),
                  _buildRecordHintWithIcon(LuluIcons.diaper, '기저귀', LuluActivityColors.diaper),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: LuluSpacing.lg),

        // 오늘 요약 (0으로 표시)
        TodaySummaryCard(
          feedingCount: 0,
          sleepDuration: '0m',
          diaperCount: 0,
        ),
      ],
    );
  }

  /// 빈 상태용 Sweet Spot 카드
  Widget _buildEmptySweetSpotCard(BabyModel? baby) {
    return Container(
      padding: const EdgeInsets.all(LuluSpacing.lg),
      decoration: BoxDecoration(
        color: LuluColors.deepBlue,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: LuluColors.lavenderMist.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(
            children: [
              const Text('🌙', style: TextStyle(fontSize: 24)),
              const SizedBox(width: LuluSpacing.sm),
              Text(
                baby != null ? '${baby.name}의 Sweet Spot' : 'Sweet Spot',
                style: LuluTextStyles.titleMedium.copyWith(
                  color: LuluTextColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: LuluSpacing.lg),
          // 안내 메시지
          Center(
            child: Column(
              children: [
                Text(
                  '수면 기록이 필요해요',
                  style: LuluTextStyles.bodyMedium.copyWith(
                    color: LuluTextColors.secondary,
                  ),
                ),
                const SizedBox(height: LuluSpacing.sm),
                Text(
                  '수면 기록을 추가하면\n최적의 수면 시간을 알려드려요',
                  style: LuluTextStyles.bodySmall.copyWith(
                    color: LuluTextColors.tertiary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: LuluSpacing.md),
          // 교정연령 정보 (조산아인 경우)
          if (baby != null && baby.isPreterm)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: LuluSpacing.md,
                vertical: LuluSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: LuluColors.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text('📅', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: LuluSpacing.xs),
                      Text(
                        '교정연령: ${baby.effectiveAgeInMonths}개월',
                        style: LuluTextStyles.bodySmall.copyWith(
                          color: LuluTextColors.secondary,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    baby.recommendedGrowthChart == GrowthChartType.fenton
                        ? 'Fenton 차트 적용'
                        : 'WHO 차트 적용',
                    style: LuluTextStyles.caption.copyWith(
                      color: LuluColors.lavenderMist,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// 기록 유형 힌트 위젯 (아이콘 버전)
  Widget _buildRecordHintWithIcon(IconData icon, String label, Color color) {
    return Column(
      children: [
        Icon(icon, size: 28, color: color),
        const SizedBox(height: LuluSpacing.xs),
        Text(
          label,
          style: LuluTextStyles.caption.copyWith(
            color: LuluTextColors.tertiary,
          ),
        ),
      ],
    );
  }

  /// 정상 상태 콘텐츠 (활동 기록 있음)
  Widget _buildNormalContent(BuildContext context, HomeProvider homeProvider) {
    final selectedBaby = homeProvider.selectedBaby;
    final lastFeeding = homeProvider.lastFeeding;
    final lastSleep = homeProvider.lastSleep;

    return Column(
      children: [
        // Sweet Spot Hero Card
        SweetSpotHeroCard(
          babyName: selectedBaby?.name,
          correctedAgeMonths: selectedBaby?.effectiveAgeInMonths,
          isPreterm: selectedBaby?.isPreterm ?? false,
          recommendedTime: _formatTime(homeProvider.recommendedSleepTime),
          minutesUntil: homeProvider.minutesUntilSweetSpot,
          progress: homeProvider.sweetSpotProgress,
        ),

        const SizedBox(height: LuluSpacing.lg),

        // 마지막 활동 카드들
        Row(
          children: [
            Expanded(
              child: LastActivityCard(
                type: 'feeding',
                title: '마지막 수유',
                time: lastFeeding != null
                    ? DateFormat('HH:mm').format(lastFeeding.startTime)
                    : '--:--',
                detail: lastFeeding != null
                    ? _getFeedingDetail(lastFeeding)
                    : '기록 없음',
              ),
            ),
            const SizedBox(width: LuluSpacing.md),
            Expanded(
              child: LastActivityCard(
                type: 'sleep',
                title: '마지막 수면',
                time: lastSleep != null
                    ? _getSleepTimeRange(lastSleep)
                    : '--:--',
                detail: lastSleep != null
                    ? _getSleepDuration(lastSleep)
                    : '기록 없음',
              ),
            ),
          ],
        ),

        const SizedBox(height: LuluSpacing.lg),

        // 오늘 요약 (한 줄)
        TodaySummaryCard(
          feedingCount: homeProvider.todayFeedingCount,
          sleepDuration: homeProvider.todaySleepDuration,
          diaperCount: homeProvider.todayDiaperCount,
        ),

        const SizedBox(height: LuluSpacing.lg),

        // Phase 2 울음 분석 예약 영역
        const CryAnalysisPlaceholder(),

        const SizedBox(height: LuluSpacing.lg),

        // Quick Action 버튼 (64dp)
        QuickActionGrid(
          onFeedingTap: () => _navigateToRecord(context, 'feeding'),
          onSleepTap: () => _navigateToRecord(context, 'sleep'),
          onDiaperTap: () => _navigateToRecord(context, 'diaper'),
          onPlayTap: () => _navigateToRecord(context, 'play'),
          onHealthTap: () => _navigateToRecord(context, 'health'),
        ),

        const SizedBox(height: LuluSpacing.lg),

        // 최근 기록 미니 타임라인
        MiniTimeline(
          activities: homeProvider.todayActivities,
          onViewAllTap: () => _navigateToTimeline(context),
        ),
      ],
    );
  }

  void _navigateToRecord(BuildContext context, String type) {
    // TODO: 각 기록 화면으로 네비게이션
    debugPrint('Navigate to $type record');
  }

  void _navigateToTimeline(BuildContext context) {
    // TODO: 타임라인 화면으로 네비게이션
    debugPrint('Navigate to timeline');
  }

  /// 시간 포맷
  String _formatTime(DateTime? time) {
    if (time == null) return '--:--';
    return DateFormat('HH:mm').format(time);
  }

  /// 수유 상세 정보
  String _getFeedingDetail(ActivityModel activity) {
    final data = activity.data;
    if (data == null) return '';

    final feedingType = data['feeding_type'] as String? ?? '';
    final typeStr = switch (feedingType) {
      'breast' => '모유',
      'bottle' => '젖병',
      'formula' => '분유',
      'solid' => '이유식',
      _ => '수유',
    };

    final amount = data['amount_ml'] as num?;
    if (amount != null && amount > 0) {
      return '$typeStr ${amount.toInt()}ml';
    }

    final duration = data['duration_minutes'] as int?;
    if (duration != null && duration > 0) {
      return '$typeStr $duration분';
    }

    return typeStr;
  }

  /// 수면 시간 범위
  String _getSleepTimeRange(ActivityModel activity) {
    final start = DateFormat('HH:mm').format(activity.startTime);
    if (activity.endTime == null) return '$start - 진행 중';
    final end = DateFormat('HH:mm').format(activity.endTime!);
    return '$start - $end';
  }

  /// 수면 시간 (자정 넘김 처리 포함 - QA-01)
  String _getSleepDuration(ActivityModel activity) {
    if (activity.endTime == null) return '진행 중';

    // durationMinutes getter 사용 (자정 넘김 처리 포함)
    final totalMins = activity.durationMinutes ?? 0;
    final hours = totalMins ~/ 60;
    final mins = totalMins % 60;

    if (hours > 0 && mins > 0) return '$hours시간 $mins분';
    if (hours > 0) return '$hours시간';
    return '$mins분';
  }

}
