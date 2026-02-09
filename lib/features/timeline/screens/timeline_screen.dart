import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_radius.dart';
import '../../../core/design_system/lulu_icons.dart';
import '../../../core/design_system/lulu_typography.dart';
import '../../../core/design_system/lulu_spacing.dart';
import '../../../data/models/models.dart';
import '../../../l10n/generated/app_localizations.dart' show S;
import '../../home/providers/home_provider.dart';

/// 기록 히스토리 화면
///
/// 날짜별 활동 기록 목록 표시
/// - 날짜 선택 가능
/// - 기록 유형별 아이콘/색상 구분
/// - 다태아 시 아기 이름 표시
class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LuluColors.midnightNavy,
      appBar: AppBar(
        backgroundColor: LuluColors.midnightNavy,
        elevation: 0,
        title: Text(
          S.of(context)!.screenTitleTimeline,
          style: LuluTextStyles.titleLarge.copyWith(
            color: LuluTextColors.primary,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              LuluIcons.calendar,
              color: LuluColors.lavenderMist,
            ),
            onPressed: _selectDate,
          ),
        ],
      ),
      body: Consumer<HomeProvider>(
        builder: (context, homeProvider, child) {
          // 아기 정보가 없으면 빈 상태
          if (homeProvider.babies.isEmpty) {
            return _buildEmptyBabiesState();
          }

          // 선택된 날짜의 활동 필터링 (BUG-005 FIX: 선택된 아기만)
          final activities = _getActivitiesForDate(
            homeProvider.filteredTodayActivities,
            _selectedDate,
          );

          // 활동이 없으면 빈 상태
          if (activities.isEmpty) {
            return _buildEmptyActivitiesState(homeProvider);
          }

          // 활동 목록
          return _buildActivityList(activities, homeProvider);
        },
      ),
    );
  }

  /// 선택된 날짜의 활동 필터링
  List<ActivityModel> _getActivitiesForDate(
    List<ActivityModel> activities,
    DateTime date,
  ) {
    return activities.where((a) {
      return a.startTime.year == date.year &&
          a.startTime.month == date.month &&
          a.startTime.day == date.day;
    }).toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
  }

  /// 날짜 선택
  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: LuluColors.lavenderMist,
              surface: LuluColors.deepBlue,
              onSurface: LuluTextColors.primary,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: LuluColors.midnightNavy,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  /// 오늘인지 확인
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// 아기 정보 없음 상태
  Widget _buildEmptyBabiesState() {
    final l10n = S.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LuluIcons.baby,
            size: 64,
            color: LuluTextColors.tertiary,
          ),
          const SizedBox(height: LuluSpacing.lg),
          Text(
            l10n.emptyBabyInfoTitle,
            style: LuluTextStyles.titleMedium.copyWith(
              color: LuluTextColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: LuluSpacing.sm),
          Text(
            l10n.emptyBabyInfoHint,
            style: LuluTextStyles.bodyMedium.copyWith(
              color: LuluTextColors.secondary,
            ),
          ),
        ],
      ),
    );
  }

  /// 활동 없음 상태
  Widget _buildEmptyActivitiesState(HomeProvider homeProvider) {
    final l10n = S.of(context)!;
    final dateStr = DateFormat.MMMEd(Localizations.localeOf(context).languageCode).format(_selectedDate);
    final isToday = _isToday(_selectedDate);
    final babyName = homeProvider.selectedBaby?.name ?? l10n.defaultBabyName;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 원형 배경 + 메인 컬러 (홈 화면과 통일)
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: LuluColors.lavenderSelected,
              shape: BoxShape.circle,
            ),
            child: Icon(
              LuluIcons.editCalendar,
              size: 40,
              color: LuluColors.lavenderMist,
            ),
          ),
          const SizedBox(height: LuluSpacing.xl),
          Text(
            isToday
                ? l10n.timelineEmptyTodayTitle(babyName)
                : l10n.timelineEmptyPastTitle(dateStr),
            style: LuluTextStyles.titleMedium.copyWith(
              color: LuluTextColors.primary,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: LuluSpacing.sm),
          Text(
            isToday ? l10n.timelineEmptyTodayHint : l10n.timelineEmptyPastHint,
            style: LuluTextStyles.bodyMedium.copyWith(
              color: LuluTextColors.secondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 활동 목록
  Widget _buildActivityList(
    List<ActivityModel> activities,
    HomeProvider homeProvider,
  ) {
    final l10n = S.of(context)!;
    final dateStr = DateFormat.MMMEd(Localizations.localeOf(context).languageCode).format(_selectedDate);

    return Column(
      children: [
        // 날짜 헤더
        Container(
          padding: const EdgeInsets.all(LuluSpacing.md),
          color: LuluColors.deepBlue,
          child: Row(
            children: [
              Text(
                _isToday(_selectedDate) ? l10n.today : dateStr,
                style: LuluTextStyles.titleSmall.copyWith(
                  color: LuluTextColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                l10n.recordCount(activities.length),
                style: LuluTextStyles.bodySmall.copyWith(
                  color: LuluTextColors.secondary,
                ),
              ),
            ],
          ),
        ),

        // 기록 리스트
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(LuluSpacing.md),
            itemCount: activities.length,
            separatorBuilder: (_, _) => const SizedBox(height: LuluSpacing.sm),
            itemBuilder: (context, index) {
              final activity = activities[index];
              return _buildActivityCard(activity, homeProvider);
            },
          ),
        ),
      ],
    );
  }

  /// 활동 카드
  Widget _buildActivityCard(
    ActivityModel activity,
    HomeProvider homeProvider,
  ) {
    // 아기 이름 찾기
    String babyName = '';
    if (activity.babyIds.isNotEmpty) {
      final baby = homeProvider.babies.where(
        (b) => activity.babyIds.contains(b.id),
      ).firstOrNull;
      babyName = baby?.name ?? '';
    }

    final timeStr = DateFormat('HH:mm').format(activity.startTime);
    final color = _getActivityColor(activity.type);

    return Container(
      padding: const EdgeInsets.all(LuluSpacing.md),
      decoration: BoxDecoration(
        color: LuluColors.surfaceCard,
        borderRadius: BorderRadius.circular(LuluRadius.sm),
      ),
      child: Row(
        children: [
          // 아이콘
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(LuluRadius.sm),
            ),
            child: Center(
              child: Icon(
                _getActivityIcon(activity.type),
                size: 24,
                color: color,
              ),
            ),
          ),

          const SizedBox(width: LuluSpacing.md),

          // 내용
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _getActivityTitle(activity),
                      style: LuluTextStyles.bodyLarge.copyWith(
                        color: LuluTextColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    // 다태아인 경우 아기 이름 표시
                    if (homeProvider.babies.length > 1 &&
                        babyName.isNotEmpty) ...[
                      const SizedBox(width: LuluSpacing.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: LuluColors.lavenderSelected,
                          borderRadius: BorderRadius.circular(LuluRadius.indicator),
                        ),
                        child: Text(
                          babyName,
                          style: LuluTextStyles.caption.copyWith(
                            color: LuluColors.lavenderMist,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _getActivityDetail(activity),
                  style: LuluTextStyles.bodySmall.copyWith(
                    color: LuluTextColors.secondary,
                  ),
                ),
                // BUG-003: 메모 표시 추가
                if (activity.notes != null && activity.notes!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        LuluIcons.note,
                        size: 12,
                        color: LuluTextColors.tertiary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          activity.notes!,
                          style: LuluTextStyles.caption.copyWith(
                            color: LuluTextColors.tertiary,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // 시간
          Text(
            timeStr,
            style: LuluTextStyles.bodyMedium.copyWith(
              color: LuluColors.lavenderMist,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// 활동 유형별 아이콘
  IconData _getActivityIcon(ActivityType type) {
    return switch (type) {
      ActivityType.feeding => LuluIcons.feeding,
      ActivityType.sleep => LuluIcons.sleep,
      ActivityType.diaper => LuluIcons.diaper,
      ActivityType.play => LuluIcons.play,
      ActivityType.health => LuluIcons.health,
    };
  }

  /// 활동 유형별 색상
  Color _getActivityColor(ActivityType type) {
    return switch (type) {
      ActivityType.feeding => LuluActivityColors.feeding,
      ActivityType.sleep => LuluActivityColors.sleep,
      ActivityType.diaper => LuluActivityColors.diaper,
      ActivityType.play => LuluActivityColors.play,
      ActivityType.health => LuluActivityColors.health,
    };
  }

  /// 활동 제목
  String _getActivityTitle(ActivityModel activity) {
    final l10n = S.of(context)!;
    final data = activity.data;

    return switch (activity.type) {
      ActivityType.feeding => _getFeedingTitle(data),
      ActivityType.sleep => _getSleepTitle(data),
      ActivityType.diaper => l10n.diaperChange,
      ActivityType.play => l10n.activityPlay,
      ActivityType.health => l10n.activityTypeHealth,
    };
  }

  String _getFeedingTitle(Map<String, dynamic>? data) {
    final l10n = S.of(context)!;
    if (data == null) return l10n.activityTypeFeeding;

    final feedingType = data['feeding_type'] as String? ?? '';
    return switch (feedingType) {
      'breast' => l10n.feedingBreastfeeding,
      'bottle' => l10n.feedingBottleFeeding,
      'formula' => l10n.feedingTypeFormula,
      'solid' => l10n.feedingTypeSolid,
      _ => l10n.activityTypeFeeding,
    };
  }

  String _getSleepTitle(Map<String, dynamic>? data) {
    final l10n = S.of(context)!;
    if (data == null) return l10n.activityTypeSleep;

    final sleepType = data['sleep_type'] as String? ?? '';
    return switch (sleepType) {
      'nap' => l10n.sleepTypeNap,
      'night' => l10n.sleepTypeNight,
      _ => l10n.activityTypeSleep,
    };
  }

  /// 활동 상세 정보
  String _getActivityDetail(ActivityModel activity) {
    final data = activity.data;

    return switch (activity.type) {
      ActivityType.feeding => _getFeedingDetail(data),
      ActivityType.sleep => _getSleepDetail(activity),
      ActivityType.diaper => _getDiaperDetail(data),
      ActivityType.play => _getPlayDetail(activity),
      ActivityType.health => data?['notes'] as String? ?? '',
    };
  }

  String _getFeedingDetail(Map<String, dynamic>? data) {
    if (data == null) return '';

    final l10n = S.of(context)!;
    final feedingType = data['feeding_type'] as String? ?? '';

    // 모유 수유인 경우
    if (feedingType == 'breast') {
      final duration = data['duration_minutes'] as int? ?? 0;
      final side = data['breast_side'] as String? ?? '';
      final sideStr = switch (side) {
        'left' => l10n.breastSideLeft,
        'right' => l10n.breastSideRight,
        'both' => l10n.breastSideBoth,
        _ => '',
      };
      return sideStr.isNotEmpty
          ? '$sideStr ${l10n.unitMinutes(duration)}'
          : l10n.unitMinutes(duration);
    }

    // 젖병/분유/이유식인 경우
    final amount = data['amount_ml'] as num? ?? 0;
    return amount > 0 ? '${amount.toInt()}ml' : '';
  }

  /// 수면 시간 표시 (자정 넘김 처리 포함 - QA-01)
  String _getSleepDetail(ActivityModel activity) {
    final l10n = S.of(context)!;
    if (activity.endTime == null) return l10n.statusOngoing;

    // durationMinutes getter 사용 (자정 넘김 처리 포함)
    final totalMins = activity.durationMinutes ?? 0;
    final hours = totalMins ~/ 60;
    final mins = totalMins % 60;

    if (hours > 0 && mins > 0) {
      return l10n.durationHoursMinutes(hours, mins);
    } else if (hours > 0) {
      return '$hours${l10n.unitHours}';
    } else {
      return l10n.unitMinutes(mins);
    }
  }

  String _getDiaperDetail(Map<String, dynamic>? data) {
    if (data == null) return '';

    final l10n = S.of(context)!;
    final diaperType = data['diaper_type'] as String? ?? '';
    return switch (diaperType) {
      'wet' => l10n.diaperTypeWet,
      'dirty' => l10n.diaperTypeDirty,
      'both' => l10n.diaperTypeBothDetail,
      'dry' => l10n.diaperTypeDry,
      _ => '',
    };
  }

  /// 놀이 시간 표시 (자정 넘김 처리 포함 - QA-01)
  String _getPlayDetail(ActivityModel activity) {
    final l10n = S.of(context)!;
    if (activity.endTime == null) return l10n.statusOngoing;

    // durationMinutes getter 사용 (자정 넘김 처리 포함)
    final mins = activity.durationMinutes ?? 0;
    return l10n.unitMinutes(mins);
  }
}
