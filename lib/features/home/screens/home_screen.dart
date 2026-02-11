import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/config/feature_flags.dart';
import '../../../core/utils/app_toast.dart';
import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_radius.dart';
import '../../../core/design_system/lulu_icons.dart';
import '../../../core/design_system/lulu_typography.dart';
import '../../../core/design_system/lulu_spacing.dart';
import '../../../l10n/generated/app_localizations.dart' show S;
import '../../../shared/widgets/baby_tab_bar.dart';
import '../../../shared/widgets/last_activity_row.dart';
import '../../../shared/widgets/sweet_spot_card.dart';
import '../providers/home_provider.dart';
import '../providers/sweet_spot_provider.dart';
import '../../record/providers/ongoing_sleep_provider.dart';
import '../../record/screens/feeding_record_screen.dart';
import '../../record/screens/sleep_record_screen.dart';
import '../../record/screens/diaper_record_screen.dart';
import '../../record/screens/play_record_screen.dart';
import '../../record/screens/health_record_screen.dart';
import '../../../data/models/activity_model.dart';
import '../../../data/models/baby_type.dart';
import '../widgets/cry_analysis_card.dart';
import '../../cry_analysis/screens/cry_analysis_screen.dart';
import '../../badge/badge_provider.dart';
import '../../badge/widgets/badge_collection_screen.dart';
import '../../encouragement/widgets/encouragement_card.dart';
import '../../settings/providers/settings_provider.dart';
import '../../timeline/screens/record_history_screen.dart';

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
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LuluColors.midnightNavy,
      body: SafeArea(
        child: Consumer<HomeProvider>(
          builder: (context, homeProvider, child) {
            return CustomScrollView(
              slivers: [
                // App Bar (C-1: cleaned up — menu/settings icons removed)
                SliverAppBar(
                  backgroundColor: LuluColors.midnightNavy,
                  floating: true,
                  elevation: 0,
                  leading: const SizedBox.shrink(),
                  leadingWidth: 0,
                  title: Text(
                    S.of(context)!.appTitle,
                    style: LuluTextStyles.titleLarge.copyWith(
                      color: LuluColors.champagneGold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  centerTitle: true,
                  actions: [
                    // Badge collection icon with unseen indicator
                    Consumer<BadgeProvider>(
                      builder: (context, badgeProvider, _) {
                        final hasUnseen = badgeProvider.hasUnseenBadges;
                        return GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const BadgeCollectionScreen(),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(right: LuluSpacing.lg),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Icon(
                                  LuluIcons.trophy,
                                  color: LuluTextColors.secondary,
                                ),
                                if (hasUnseen)
                                  Positioned(
                                    right: -2,
                                    top: -2,
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: LuluColors.champagneGold,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
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
                      // Sprint 19 수정 2: 신규 유저(전체 기록 0)만 Empty State 표시
                      // 기존 유저는 오늘 기록 없어도 Normal Content 표시
                      else if (homeProvider.filteredTodayActivities.isEmpty &&
                          !homeProvider.hasAnyRecordsEver)
                        _buildEmptyActivitiesState(context, homeProvider)
                      // 정상 상태: 모든 카드 표시 (오늘 활동 없어도)
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
            S.of(context)!.emptyBabiesTitle,
            style: LuluTextStyles.titleMedium.copyWith(
              color: LuluTextColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: LuluSpacing.sm),
          Text(
            S.of(context)!.emptyBabiesHint,
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

    return Consumer2<OngoingSleepProvider, SettingsProvider>(
      builder: (context, sleepProvider, settingsProvider, _) {
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

            // 🆕 HOTFIX: Empty State에서 LastActivityRow 제거 (불필요한 빈 정보)

            // Encouragement message (compact inline)
            EncouragementCard(
              baby: homeProvider.selectedBaby,
              todayActivities: const [],
              isWarmTone: settingsProvider.isWarmTone,
            ),

            // 🆕 울음 분석 카드 (Feature Flag로 제어)
            if (FeatureFlags.enableCryAnalysis) ...[
              const SizedBox(height: LuluSpacing.md),
              CryAnalysisCard(
                onTap: () => _navigateToCryAnalysis(context),
                showNewBadge: true,
              ),
            ],
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
    // Sweet Spot Empty State: no sleep record today
    final hasSleepRecord = homeProvider.lastSleep != null;

    return Consumer3<OngoingSleepProvider, SweetSpotProvider, SettingsProvider>(
      builder: (context, sleepProvider, sweetSpotProvider, settingsProvider, _) {
        // Check if selected baby is sleeping
        final isSleeping = sleepProvider.hasSleepInProgress &&
            sleepProvider.currentBabyId == homeProvider.selectedBabyId;
        final isWarmTone = settingsProvider.isWarmTone;

        return Column(
          children: [
            // 1. Last activity Row (sleep/feeding/diaper)
            LastActivityRow(
              lastSleep: homeProvider.lastSleepTime,
              lastFeeding: homeProvider.lastFeedingTime,
              lastDiaper: homeProvider.lastDiaperTime,
            ),

            const SizedBox(height: LuluSpacing.lg),

            // 2. Sweet Spot card (ongoing sleep + prediction)
            // C-5: pass result + baby index for golden band rendering
            SweetSpotCard(
              state: sweetSpotProvider.sweetSpotState,
              isEmpty: !isSleeping && !homeProvider.hasAnyRecordsEver,
              estimatedTime: _getEstimatedTimeText(sweetSpotProvider),
              onRecordSleep: () => _navigateToRecord(context, 'sleep'),
              isSleeping: isSleeping,
              sleepStartTime: sleepProvider.sleepStartTime,
              sleepType: sleepProvider.ongoingSleep?.sleepType,
              babyName: sleepProvider.ongoingSleep?.babyName ??
                  homeProvider.selectedBaby?.name,
              onEndSleep: () => _showEndSleepDialog(context, sleepProvider),
              progress: sweetSpotProvider.sweetSpotProgress,
              recommendedTime: sweetSpotProvider.recommendedSleepTime,
              isNightTime: sweetSpotProvider.isNightTime,
              hasOtherActivitiesOnly: homeProvider.hasAnyRecordsEver && !hasSleepRecord,
              isNewUser: !homeProvider.hasAnyRecordsEver,
              completedSleepRecords: sweetSpotProvider.sweetSpotResult?.completedSleepRecords,
              calibrationTarget: sweetSpotProvider.sweetSpotResult?.calibrationTarget,
              sweetSpotResult: sweetSpotProvider.sweetSpotResult,
              babyIndex: homeProvider.babies.length > 1
                  ? homeProvider.babies.indexWhere(
                      (b) => b.id == homeProvider.selectedBabyId)
                  : null,
              isWarmTone: isWarmTone,
            ),

            // 3. Encouragement message (compact inline)
            Consumer<BadgeProvider>(
              builder: (context, badgeProvider, _) {
                return EncouragementCard(
                  baby: homeProvider.selectedBaby,
                  todayActivities: homeProvider.todayActivities,
                  recentBadges: badgeProvider.achievements,
                  hasPendingBadgePopup: badgeProvider.currentPopup != null,
                  isWarmTone: isWarmTone,
                );
              },
            ),

            if (FeatureFlags.enableCryAnalysis) ...[
              const SizedBox(height: LuluSpacing.md),
              CryAnalysisCard(
                onTap: () => _navigateToCryAnalysis(context),
                showNewBadge: true,
              ),
            ],
          ],
        );
      },
    );
  }

  /// Sweet Spot estimated time text
  String? _getEstimatedTimeText(SweetSpotProvider sweetSpotProvider) {
    final l10n = S.of(context)!;
    final minutes = sweetSpotProvider.minutesUntilSweetSpot;
    if (minutes <= 0) return null;

    if (minutes < 60) {
      return l10n.sweetSpotEstimateMinutes(minutes);
    } else {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      if (mins == 0) {
        return l10n.sweetSpotEstimateHours(hours);
      }
      return l10n.sweetSpotEstimateHoursMinutes(hours, mins);
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

    // Sprint 21 Phase 3-1: capture l10n + navigator before async gap
    final l10n = S.of(context);
    final navigator = Navigator.of(context);

    Navigator.push<ActivityModel>(
      context,
      MaterialPageRoute(builder: (_) => screen),
    ).then((savedActivity) {
      // 저장된 활동이 있으면 HomeProvider에 추가
      if (savedActivity != null) {
        homeProvider.addActivity(savedActivity);

        // Sprint 21 Phase 3-1: AppToast (global ScaffoldMessenger)
        AppToast.show(
          SnackBar(
            content: Row(
              children: [
                const Icon(LuluIcons.checkCircle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(l10n?.successRecordSaved ?? 'Record saved'),
                ),
              ],
            ),
            action: SnackBarAction(
              label: l10n?.viewRecord ?? 'View Records',
              textColor: Colors.white,
              onPressed: () {
                navigator.push(
                  MaterialPageRoute(
                    builder: (_) => const RecordHistoryScreen(),
                  ),
                );
              },
            ),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  /// 울음 분석 화면으로 네비게이션
  ///
  /// Phase 2: AI 울음 분석 기능
  void _navigateToCryAnalysis(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CryAnalysisScreen(),
      ),
    );
  }

  /// 수면 종료 다이얼로그 (OngoingSleepCard에서 이전)
  ///
  /// Sprint 7 Day 2: SweetSpotCard 통합
  void _showEndSleepDialog(
    BuildContext context,
    OngoingSleepProvider sleepProvider,
  ) {
    final babyName = sleepProvider.ongoingSleep?.babyName ?? S.of(context)!.babyDefault;
    final startTime = sleepProvider.sleepStartTime;

    if (startTime == null) return;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: LuluColors.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LuluRadius.lg),
        ),
        title: Text(
          S.of(context)!.sleepEndConfirmTitle,
          style: LuluTextStyles.titleMedium.copyWith(
            color: LuluTextColors.primary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDialogInfoRow(S.of(context)!.babyDefault, babyName),
            const SizedBox(height: 8),
            _buildDialogInfoRow(
              S.of(context)!.labelStart,
              DateFormat.jm(Localizations.localeOf(context).toString()).format(startTime),
            ),
            const SizedBox(height: 8),
            _buildDialogInfoRow(
              S.of(context)!.labelEnd,
              DateFormat.jm(Localizations.localeOf(context).toString()).format(DateTime.now()),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: LuluActivityColors.sleepBg,
                borderRadius: BorderRadius.circular(LuluRadius.sm),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    LuluIcons.timerOutlined,
                    color: LuluActivityColors.sleep,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${S.of(context)!.sleepTotalDuration}${sleepProvider.formattedElapsedTime}',
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
              S.of(context)!.buttonCancel,
              style: LuluTextStyles.labelLarge.copyWith(
                color: LuluTextColors.secondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final homeProvider = context.read<HomeProvider>();

              final savedActivity = await sleepProvider.endSleep();

              // HomeProvider에 활동 추가하여 UI 갱신
              if (savedActivity != null) {
                homeProvider.addActivity(savedActivity);
              }

              // FIX: Sprint 19 G-R2: toast removed, haptic instead
              HapticFeedback.mediumImpact();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: LuluActivityColors.sleep,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(LuluRadius.sm),
              ),
            ),
            child: Text(S.of(context)!.buttonEnd),
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
