import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/design_system/lulu_colors.dart';
import '../../core/design_system/lulu_icons.dart';
import '../../core/design_system/lulu_typography.dart';
import '../../core/utils/app_toast.dart';
import '../../shared/widgets/expandable_fab.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/home/providers/home_provider.dart';
import '../../features/badge/badge_provider.dart';
import '../../features/badge/widgets/badge_popup.dart';
import '../../features/timeline/screens/record_history_screen.dart';
import '../../features/growth/screens/growth_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../data/models/activity_model.dart';
import '../../data/models/baby_type.dart';
import '../../features/record/record.dart';
import '../../l10n/generated/app_localizations.dart' show S;

/// 메인 네비게이션 (2단계 UT 검증 완료: 시안 B-4)
///
/// 선정 근거:
/// - SAT: 4.58/5 (최고)
/// - TTC: 3.2초 (3초 Rule 근접)
/// - 핵심 타겟(P2) 만족도: 5.0/5
/// - 확장성: Phase 2/3 수용 가능
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    RecordHistoryScreen(),
    GrowthScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // 온보딩에서 설정된 데이터 확인 로그
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final homeProvider = context.read<HomeProvider>();
      debugPrint('[OK] [MainNavigation] Loaded babies: ${homeProvider.babies.map((b) => b.name).join(", ")}');
    });
  }

  /// 현재 familyId (HomeProvider에서 가져옴)
  String get _currentFamilyId {
    return context.read<HomeProvider>().family?.id ?? 'temp-family-id';
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: LuluColors.midnightNavy,
          body: IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          floatingActionButton: LabeledFab(
            onRecord: _handleRecord,
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
          bottomNavigationBar: _buildBottomBar(),
        ),
        // Badge popup overlay
        Consumer<BadgeProvider>(
          builder: (context, badgeProvider, _) {
            final popup = badgeProvider.currentPopup;
            if (popup == null) return const SizedBox.shrink();

            return BadgePopup(
              candidate: popup,
              onDismiss: () => badgeProvider.dismissPopup(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return BottomAppBar(
      color: LuluColors.deepBlue,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      height: 68,
      elevation: 8,
      shadowColor: LuluColors.shadowBlack,
      padding: EdgeInsets.zero,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            icon: LuluIcons.home,
            label: S.of(context)?.navHome ?? 'Home',
            isSelected: _currentIndex == 0,
            onTap: () => _onTabTapped(0),
          ),
          _NavItem(
            icon: LuluIcons.records,
            label: S.of(context)?.navRecords ?? 'Records',
            isSelected: _currentIndex == 1,
            onTap: () => _onTabTapped(1),
          ),
          const SizedBox(width: 80), // FAB 공간
          _NavItem(
            icon: LuluIcons.growth,
            label: S.of(context)?.navGrowth ?? 'Growth',
            isSelected: _currentIndex == 2,
            onTap: () => _onTabTapped(2),
          ),
          _NavItem(
            icon: LuluIcons.settings,
            label: S.of(context)?.navSettings ?? 'Settings',
            isSelected: _currentIndex == 3,
            onTap: () => _onTabTapped(3),
          ),
        ],
      ),
    );
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _handleRecord(String type) {
    debugPrint('Record type: $type');

    final homeProvider = context.read<HomeProvider>();
    final babies = homeProvider.babies;
    final selectedBabyId = homeProvider.selectedBabyId;

    // 온보딩에서 전달받은 familyId 사용
    final familyId = _currentFamilyId;

    if (babies.isEmpty) {
      // 아기 정보가 없으면 안내 메시지
      AppToast.showText(S.of(context)?.registerBabyFirst ?? 'Please register baby info first');
      return;
    }

    // 기록 타입에 따라 화면 이동
    Widget? screen;
    switch (type) {
      case 'feeding':
        screen = FeedingRecordScreen(
          familyId: familyId,
          babies: babies,
          preselectedBabyId: selectedBabyId,
        );
        break;
      case 'sleep':
        screen = SleepRecordScreen(
          familyId: familyId,
          babies: babies,
          preselectedBabyId: selectedBabyId,
        );
        break;
      case 'diaper':
        screen = DiaperRecordScreen(
          familyId: familyId,
          babies: babies,
          preselectedBabyId: selectedBabyId,
        );
        break;
      case 'play':
        screen = PlayRecordScreen(
          familyId: familyId,
          babies: babies,
          preselectedBabyId: selectedBabyId,
        );
        break;
      case 'health':
        screen = HealthRecordScreen(
          familyId: familyId,
          babies: babies,
          preselectedBabyId: selectedBabyId,
        );
        break;
    }

    if (screen != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => screen!,
          fullscreenDialog: true,
        ),
      ).then((result) {
        if (result != null && mounted) {
          final activity = result as ActivityModel;
          homeProvider.addActivity(activity);
          HapticFeedback.mediumImpact();

          final l10n = S.of(context);
          final summary = _buildActivitySummary(activity, l10n);
          AppToast.showActivity(
            activity.type,
            l10n?.toastActivitySaved(summary) ?? '$summary saved',
          );
        }
      });
    }
  }

  /// Build activity-specific summary for toast message
  String _buildActivitySummary(ActivityModel activity, S? l10n) {
    final data = activity.data;

    switch (activity.type) {
      case ActivityType.feeding:
        return _buildFeedingSummary(data, l10n);
      case ActivityType.sleep:
        return _buildSleepSummary(activity, data, l10n);
      case ActivityType.diaper:
        return _buildDiaperSummary(data, l10n);
      case ActivityType.play:
        return _buildPlaySummary(activity, l10n);
      case ActivityType.health:
        return _buildHealthSummary(data, l10n);
    }
  }

  String _buildFeedingSummary(Map<String, dynamic>? data, S? l10n) {
    if (data == null) return l10n?.toastMixedFeedingSaved ?? 'Mixed feeding';

    final type = data['feeding_type'] as String? ?? 'bottle';
    final side = data['breast_side'] as String?;
    final amountMl = data['amount_ml'];
    final durationMinutes = data['duration_minutes'];

    switch (type) {
      case 'breast':
        final sideLabel = side == 'left'
            ? (l10n?.feedingSideLeft ?? 'left')
            : side == 'right'
                ? (l10n?.feedingSideRight ?? 'right')
                : (l10n?.feedingSideBoth ?? 'both');
        final detail = durationMinutes != null
            ? (l10n?.unitMinutes(durationMinutes as int) ?? '${durationMinutes}min')
            : amountMl != null
                ? '${(amountMl as num).toInt()}ml'
                : '';
        return l10n?.toastBreastMilkSaved(sideLabel, detail) ??
            'Breast milk ($sideLabel) $detail';
      case 'formula':
      case 'bottle':
        if (amountMl != null) {
          return l10n?.toastFormulaSaved('${(amountMl as num).toInt()}') ??
              'Formula ${(amountMl as num).toInt()}ml';
        }
        return l10n?.toastFormulaSaved('') ?? 'Formula';
      case 'solid':
        return l10n?.toastSolidFoodSaved ?? 'Solid food';
      default:
        return l10n?.toastMixedFeedingSaved ?? 'Mixed feeding';
    }
  }

  String _buildSleepSummary(
      ActivityModel activity, Map<String, dynamic>? data, S? l10n) {
    final sleepType = data?['sleep_type'] as String? ?? 'nap';
    final minutes = activity.durationMinutes;

    if (minutes != null && minutes > 0) {
      final duration = _formatDuration(minutes, l10n);
      if (sleepType == 'nap') {
        return l10n?.toastNapDurationSaved(duration) ?? 'Nap $duration';
      }
      return l10n?.toastSleepDurationSaved(duration) ?? 'Sleep $duration';
    }
    return l10n?.toastSleepSaved ?? 'Sleep';
  }

  String _buildDiaperSummary(Map<String, dynamic>? data, S? l10n) {
    final type = data?['diaper_type'] as String? ?? 'wet';
    switch (type) {
      case 'wet':
        return l10n?.toastWetDiaperSaved ?? 'Wet diaper';
      case 'dirty':
        return l10n?.toastDirtyDiaperSaved ?? 'Dirty diaper';
      case 'both':
        return l10n?.toastMixedDiaperSaved ?? 'Mixed diaper';
      case 'dry':
        return l10n?.toastDryDiaperSaved ?? 'Dry diaper';
      default:
        return l10n?.toastWetDiaperSaved ?? 'Wet diaper';
    }
  }

  String _buildPlaySummary(ActivityModel activity, S? l10n) {
    final playType = activity.data?['play_type'] as String? ?? 'play';
    final minutes = activity.durationMinutes;
    final hasDuration = minutes != null && minutes > 0;
    final duration = hasDuration ? _formatDuration(minutes, l10n) : '';

    switch (playType) {
      case 'tummy_time':
        return hasDuration
            ? (l10n?.toastTummyTimeDurationSaved(duration) ?? 'Tummy time $duration')
            : (l10n?.toastTummyTimeSaved ?? 'Tummy time');
      case 'bath':
        return hasDuration
            ? (l10n?.toastBathDurationSaved(duration) ?? 'Bath $duration')
            : (l10n?.toastBathSaved ?? 'Bath');
      case 'outdoor':
        return hasDuration
            ? (l10n?.toastOutingDurationSaved(duration) ?? 'Outing $duration')
            : (l10n?.toastOutingSaved ?? 'Outing');
      case 'play':
        return hasDuration
            ? (l10n?.toastIndoorPlayDurationSaved(duration) ?? 'Indoor play $duration')
            : (l10n?.toastIndoorPlaySaved ?? 'Indoor play');
      case 'reading':
        return hasDuration
            ? (l10n?.toastReadingDurationSaved(duration) ?? 'Reading $duration')
            : (l10n?.toastReadingSaved ?? 'Reading');
      default:
        return hasDuration
            ? (l10n?.toastPlayDurationSaved(duration) ?? 'Play $duration')
            : (l10n?.toastPlaySaved ?? 'Play');
    }
  }

  String _buildHealthSummary(Map<String, dynamic>? data, S? l10n) {
    final type = data?['health_type'] as String? ?? 'temperature';
    switch (type) {
      case 'temperature':
        final temp = data?['temperature'];
        if (temp != null) {
          return l10n?.toastTemperatureSaved('$temp\u00B0C') ??
              'Temperature $temp\u00B0C';
        }
        return l10n?.toastTemperatureSaved('') ?? 'Temperature';
      case 'medication':
        return l10n?.toastMedicationSaved ?? 'Medication';
      case 'hospital':
        return l10n?.toastHospitalVisitSaved ?? 'Hospital visit';
      case 'symptom':
        return l10n?.toastSymptomsSaved ?? 'Symptoms';
      default:
        return l10n?.toastHealthSaved ?? 'Health record';
    }
  }

  String _formatDuration(int totalMinutes, S? l10n) {
    final hours = totalMinutes ~/ 60;
    final mins = totalMinutes % 60;
    if (hours > 0 && mins > 0) {
      return '${hours}h ${mins}min';
    } else if (hours > 0) {
      return '${hours}h';
    }
    return l10n?.unitMinutes(mins) ?? '${mins}min';
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: isSelected ? 24 : 20,
              color: isSelected
                  ? LuluColors.lavenderMist
                  : LuluTextColors.secondary,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: LuluTextStyles.caption.copyWith(
                color: isSelected
                    ? LuluColors.lavenderMist
                    : LuluTextColors.secondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 10,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
