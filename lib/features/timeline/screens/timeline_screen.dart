import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_typography.dart';
import '../../../core/design_system/lulu_spacing.dart';
import '../../../data/models/models.dart';
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
          '기록 히스토리',
          style: LuluTextStyles.titleLarge.copyWith(
            color: LuluTextColors.primary,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.calendar_today,
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

          // 선택된 날짜의 활동 필터링
          final activities = _getActivitiesForDate(
            homeProvider.todayActivities,
            _selectedDate,
          );

          // 활동이 없으면 빈 상태
          if (activities.isEmpty) {
            return _buildEmptyActivitiesState();
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('👶', style: TextStyle(fontSize: 64)),
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

  /// 활동 없음 상태
  Widget _buildEmptyActivitiesState() {
    final dateStr = DateFormat('M월 d일 (E)', 'ko_KR').format(_selectedDate);
    final isToday = _isToday(_selectedDate);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📝', style: TextStyle(fontSize: 64)),
          const SizedBox(height: LuluSpacing.lg),
          Text(
            isToday ? '오늘의 기록이 없습니다' : '$dateStr 기록이 없습니다',
            style: LuluTextStyles.titleMedium.copyWith(
              color: LuluTextColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: LuluSpacing.sm),
          Text(
            isToday ? '+ 버튼을 눌러 첫 기록을 시작하세요' : '다른 날짜를 선택해보세요',
            style: LuluTextStyles.bodyMedium.copyWith(
              color: LuluTextColors.secondary,
            ),
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
    final dateStr = DateFormat('M월 d일 (E)', 'ko_KR').format(_selectedDate);

    return Column(
      children: [
        // 날짜 헤더
        Container(
          padding: const EdgeInsets.all(LuluSpacing.md),
          color: LuluColors.deepBlue,
          child: Row(
            children: [
              Text(
                _isToday(_selectedDate) ? '오늘' : dateStr,
                style: LuluTextStyles.titleSmall.copyWith(
                  color: LuluTextColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${activities.length}개 기록',
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
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // 아이콘
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                _getActivityEmoji(activity.type),
                style: const TextStyle(fontSize: 24),
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
                          color: LuluColors.lavenderMist.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
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

  /// 활동 유형별 이모지
  String _getActivityEmoji(ActivityType type) {
    return switch (type) {
      ActivityType.feeding => '🍼',
      ActivityType.sleep => '😴',
      ActivityType.diaper => '🧷',
      ActivityType.play => '🎮',
      ActivityType.health => '💊',
    };
  }

  /// 활동 유형별 색상
  Color _getActivityColor(ActivityType type) {
    return switch (type) {
      ActivityType.feeding => Colors.orange,
      ActivityType.sleep => Colors.purple,
      ActivityType.diaper => Colors.blue,
      ActivityType.play => Colors.green,
      ActivityType.health => Colors.red,
    };
  }

  /// 활동 제목
  String _getActivityTitle(ActivityModel activity) {
    final data = activity.data;

    return switch (activity.type) {
      ActivityType.feeding => _getFeedingTitle(data),
      ActivityType.sleep => _getSleepTitle(data),
      ActivityType.diaper => '기저귀 교체',
      ActivityType.play => '놀이',
      ActivityType.health => '건강',
    };
  }

  String _getFeedingTitle(Map<String, dynamic>? data) {
    if (data == null) return '수유';

    final feedingType = data['feeding_type'] as String? ?? '';
    return switch (feedingType) {
      'breast' => '모유 수유',
      'bottle' => '젖병 수유',
      'formula' => '분유',
      'solid' => '이유식',
      _ => '수유',
    };
  }

  String _getSleepTitle(Map<String, dynamic>? data) {
    if (data == null) return '수면';

    final sleepType = data['sleep_type'] as String? ?? '';
    return switch (sleepType) {
      'nap' => '낮잠',
      'night' => '밤잠',
      _ => '수면',
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

    final feedingType = data['feeding_type'] as String? ?? '';

    // 모유 수유인 경우
    if (feedingType == 'breast') {
      final duration = data['duration_minutes'] as int? ?? 0;
      final side = data['breast_side'] as String? ?? '';
      final sideStr = switch (side) {
        'left' => '왼쪽',
        'right' => '오른쪽',
        'both' => '양쪽',
        _ => '',
      };
      return sideStr.isNotEmpty ? '$sideStr $duration분' : '$duration분';
    }

    // 젖병/분유/이유식인 경우
    final amount = data['amount_ml'] as num? ?? 0;
    return amount > 0 ? '${amount.toInt()}ml' : '';
  }

  /// 수면 시간 표시 (자정 넘김 처리 포함 - QA-01)
  String _getSleepDetail(ActivityModel activity) {
    if (activity.endTime == null) return '진행 중';

    // durationMinutes getter 사용 (자정 넘김 처리 포함)
    final totalMins = activity.durationMinutes ?? 0;
    final hours = totalMins ~/ 60;
    final mins = totalMins % 60;

    if (hours > 0 && mins > 0) {
      return '$hours시간 $mins분';
    } else if (hours > 0) {
      return '$hours시간';
    } else {
      return '$mins분';
    }
  }

  String _getDiaperDetail(Map<String, dynamic>? data) {
    if (data == null) return '';

    final diaperType = data['diaper_type'] as String? ?? '';
    return switch (diaperType) {
      'wet' => '소변',
      'dirty' => '대변',
      'both' => '소변+대변',
      'dry' => '건조',
      _ => '',
    };
  }

  /// 놀이 시간 표시 (자정 넘김 처리 포함 - QA-01)
  String _getPlayDetail(ActivityModel activity) {
    if (activity.endTime == null) return '진행 중';

    // durationMinutes getter 사용 (자정 넘김 처리 포함)
    final mins = activity.durationMinutes ?? 0;
    return '$mins분';
  }
}
