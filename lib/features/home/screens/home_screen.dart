import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_icons.dart';
import '../../../core/design_system/lulu_typography.dart';
import '../../../core/design_system/lulu_spacing.dart';
import '../../../shared/widgets/baby_tab_bar.dart';
import '../../../shared/widgets/last_activity_row.dart';
import '../../../shared/widgets/sweet_spot_card.dart';
import '../providers/home_provider.dart';
import '../../record/providers/ongoing_sleep_provider.dart';
import '../../record/screens/feeding_record_screen.dart';
import '../../record/screens/sleep_record_screen.dart';
import '../../record/screens/diaper_record_screen.dart';
import '../../record/screens/play_record_screen.dart';
import '../../record/screens/health_record_screen.dart';
import '../../../data/models/activity_model.dart';
import '../../../data/models/baby_type.dart';

/// 홈 화면 (시안 B-4 기반)
///
/// Sprint 7 Day 2: OngoingSleepCard → SweetSpotCard 통합
/// UT 검증 완료:
/// - SAT: 4.58/5
/// - TTC: 3.2초
/// - 핵심 타겟(P2) 만족도: 5.0/5
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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

                      // BUG-004: 아기 2명 이상일 때만 탭바 표시
                      if (homeProvider.babies.length > 1) ...[
                        BabyTabBar(
                          babies: homeProvider.babies,
                          selectedBabyId: homeProvider.selectedBabyId,
                          onBabyChanged: homeProvider.selectBaby,
                        ),
                        const SizedBox(height: LuluSpacing.lg),
                      ] else
                        const SizedBox(height: LuluSpacing.sm),

                      // Sprint 7 Day 2: OngoingSleepCard → SweetSpotCard로 통합됨

                      // 아기가 없으면 빈 상태
                      if (homeProvider.babies.isEmpty)
                        _buildEmptyBabiesState()
                      // 아기는 있지만 활동이 없으면 빈 활동 상태 (BUG-002 FIX: 필터링된 활동 사용)
                      else if (homeProvider.filteredTodayActivities.isEmpty)
                        _buildEmptyActivitiesState(context, homeProvider)
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
  ///
  /// Sprint 7 Day 2 v1.2: 통합 SweetSpotCard 사용
  /// - 2개 카드 → 1개 통합 카드로 스크롤 없이 바로 기록 가능
  Widget _buildEmptyActivitiesState(BuildContext context, HomeProvider homeProvider) {
    final selectedBaby = homeProvider.selectedBaby;
    final babyName = selectedBaby?.name;

    return Consumer<OngoingSleepProvider>(
      builder: (context, sleepProvider, _) {
        // 수면 중인지 확인 (선택된 아기의 수면)
        final isSleeping = sleepProvider.hasSleepInProgress &&
            sleepProvider.currentBabyId == homeProvider.selectedBabyId;

        return Column(
          children: [
            // 🆕 통합 SweetSpotCard (빈 상태 + 3종 버튼 / 수면 중 상태)
            SweetSpotCard(
              state: SweetSpotState.unknown,
              isEmpty: !isSleeping,
              babyName: isSleeping
                  ? (sleepProvider.ongoingSleep?.babyName ?? babyName)
                  : babyName,
              // 수면 중 props
              isSleeping: isSleeping,
              sleepStartTime: sleepProvider.sleepStartTime,
              sleepType: sleepProvider.ongoingSleep?.sleepType,
              onEndSleep: isSleeping
                  ? () => _showEndSleepDialog(context, sleepProvider)
                  : null,
              // 빈 상태 3종 기록 버튼 콜백
              onRecordSleep: () => _navigateToRecord(context, 'sleep'),
              onFeedingTap: () => _navigateToRecord(context, 'feeding'),
              onSleepTap: () => _navigateToRecord(context, 'sleep'),
              onDiaperTap: () => _navigateToRecord(context, 'diaper'),
            ),

            const SizedBox(height: LuluSpacing.lg),

            // 마지막 활동 Row (0 상태)
            const LastActivityRow(
              lastSleep: null,
              lastFeeding: null,
              lastDiaper: null,
            ),
          ],
        );
      },
    );
  }

  /// 정상 상태 콘텐츠 (활동 기록 있음)
  ///
  /// Sprint 7 Day 2: OngoingSleepCard → SweetSpotCard 통합
  /// 1. LastActivityRow (수면/수유/기저귀 시간)
  /// 2. SweetSpotCard (수면 중 상태 + Sweet Spot 예측)
  Widget _buildNormalContent(BuildContext context, HomeProvider homeProvider) {
    // Sweet Spot Empty State 판단: 수면 기록 없음
    final hasSleepRecord = homeProvider.lastSleep != null;

    return Consumer<OngoingSleepProvider>(
      builder: (context, sleepProvider, _) {
        // 현재 선택된 아기가 수면 중인지 확인
        final isSleeping = sleepProvider.hasSleepInProgress &&
            sleepProvider.currentBabyId == homeProvider.selectedBabyId;

        return Column(
          children: [
            // 1. 마지막 활동 Row (수면/수유/기저귀)
            LastActivityRow(
              lastSleep: homeProvider.lastSleepTime,
              lastFeeding: homeProvider.lastFeedingTime,
              lastDiaper: homeProvider.lastDiaperTime,
            ),

            const SizedBox(height: LuluSpacing.lg),

            // 2. Sweet Spot 카드 (수면 중 상태 통합)
            SweetSpotCard(
              // 기존 props
              state: homeProvider.sweetSpotState,
              isEmpty: !hasSleepRecord && !isSleeping,
              estimatedTime: _getEstimatedTimeText(homeProvider),
              onRecordSleep: () => _navigateToRecord(context, 'sleep'),
              // 🆕 수면 중 props (Sprint 7 Day 2)
              isSleeping: isSleeping,
              sleepStartTime: sleepProvider.sleepStartTime,
              sleepType: sleepProvider.ongoingSleep?.sleepType,
              babyName: sleepProvider.ongoingSleep?.babyName ??
                  homeProvider.selectedBaby?.name,
              onEndSleep: () => _showEndSleepDialog(context, sleepProvider),
              // 🆕 Normal State 개선 props (v3)
              progress: homeProvider.sweetSpotProgress,
              recommendedTime: homeProvider.recommendedSleepTime,
              isNightTime: homeProvider.isNightTime,
            ),

            // QuickActionGrid 제거됨 (FAB로 대체) - Sprint 7 Day 2
          ],
        );
      },
    );
  }

  /// Sweet Spot 예상 시간 텍스트
  String? _getEstimatedTimeText(HomeProvider homeProvider) {
    final minutes = homeProvider.minutesUntilSweetSpot;
    if (minutes <= 0) return null;

    if (minutes < 60) {
      return '약 $minutes분 후';
    } else {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      if (mins == 0) {
        return '약 $hours시간 후';
      }
      return '약 $hours시간 $mins분 후';
    }
  }

  /// 기록 화면으로 네비게이션
  ///
  /// QA FIX: debugPrint → 실제 Navigator.push 구현
  void _navigateToRecord(BuildContext context, String type) {
    final homeProvider = context.read<HomeProvider>();
    final family = homeProvider.family;
    final babies = homeProvider.babies;
    final selectedBabyId = homeProvider.selectedBabyId;

    if (family == null || babies.isEmpty) {
      debugPrint('[WARN] Cannot navigate: family or babies not loaded');
      return;
    }

    final Widget screen = switch (type) {
      'feeding' => FeedingRecordScreen(
          familyId: family.id,
          babies: babies,
          preselectedBabyId: selectedBabyId,
          lastFeedingRecord: homeProvider.lastFeeding,
        ),
      'sleep' => SleepRecordScreen(
          familyId: family.id,
          babies: babies,
          preselectedBabyId: selectedBabyId,
          lastSleepRecord: homeProvider.lastSleep,
        ),
      'diaper' => DiaperRecordScreen(
          familyId: family.id,
          babies: babies,
          preselectedBabyId: selectedBabyId,
          lastDiaperRecord: homeProvider.lastDiaper,
        ),
      'play' => PlayRecordScreen(
          familyId: family.id,
          babies: babies,
          preselectedBabyId: selectedBabyId,
          lastPlayRecord: homeProvider.filteredTodayActivities
              .where((a) => a.type == ActivityType.play)
              .toList()
              .firstOrNull,
        ),
      'health' => HealthRecordScreen(
          familyId: family.id,
          babies: babies,
          preselectedBabyId: selectedBabyId,
          lastHealthRecord: homeProvider.filteredTodayActivities
              .where((a) => a.type == ActivityType.health)
              .toList()
              .firstOrNull,
        ),
      _ => throw ArgumentError('Unknown record type: $type'),
    };

    Navigator.push<ActivityModel>(
      context,
      MaterialPageRoute(builder: (_) => screen),
    ).then((savedActivity) {
      // 저장된 활동이 있으면 HomeProvider에 추가
      if (savedActivity != null) {
        homeProvider.addActivity(savedActivity);
      }
    });
  }

  /// 수면 종료 다이얼로그 (OngoingSleepCard에서 이전)
  ///
  /// Sprint 7 Day 2: SweetSpotCard 통합
  void _showEndSleepDialog(
    BuildContext context,
    OngoingSleepProvider sleepProvider,
  ) {
    final babyName = sleepProvider.ongoingSleep?.babyName ?? '아기';
    final startTime = sleepProvider.sleepStartTime;

    if (startTime == null) return;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: LuluColors.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          '수면을 종료할까요?',
          style: LuluTextStyles.titleMedium.copyWith(
            color: LuluTextColors.primary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDialogInfoRow('아기', babyName),
            const SizedBox(height: 8),
            _buildDialogInfoRow(
              '시작',
              DateFormat('a h:mm', 'ko').format(startTime),
            ),
            const SizedBox(height: 8),
            _buildDialogInfoRow(
              '종료',
              DateFormat('a h:mm', 'ko').format(DateTime.now()),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: LuluActivityColors.sleepBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.timer_outlined,
                    color: LuluActivityColors.sleep,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '총 수면: ${sleepProvider.formattedElapsedTime}',
                    style: LuluTextStyles.titleMedium.copyWith(
                      color: LuluActivityColors.sleep,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              '취소',
              style: LuluTextStyles.labelLarge.copyWith(
                color: LuluTextColors.secondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final homeProvider = context.read<HomeProvider>();
              final messenger = ScaffoldMessenger.of(context);

              final savedActivity = await sleepProvider.endSleep();

              // HomeProvider에 활동 추가하여 UI 갱신
              if (savedActivity != null) {
                homeProvider.addActivity(savedActivity);
              }

              messenger.showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(LuluIcons.sleep, size: 18, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        '수면 기록이 저장되었어요',
                        style: LuluTextStyles.bodyMedium.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: LuluActivityColors.sleep,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: LuluActivityColors.sleep,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('종료'),
          ),
        ],
      ),
    );
  }

  /// 다이얼로그 정보 Row
  Widget _buildDialogInfoRow(String label, String value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: LuluTextStyles.bodyMedium.copyWith(
            color: LuluTextColors.secondary,
          ),
        ),
        Text(
          value,
          style: LuluTextStyles.bodyMedium.copyWith(
            color: LuluTextColors.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
