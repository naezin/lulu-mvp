import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_typography.dart';
import '../../../core/design_system/lulu_spacing.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/activity_repository.dart';
import '../../../l10n/generated/app_localizations.dart' show S;
import '../../../shared/widgets/undo_delete_mixin.dart';
import '../../home/providers/home_provider.dart';
import '../providers/pattern_data_provider.dart';
import 'date_navigator.dart';
import 'daily_grid.dart';
import 'activity_list_item.dart';
import 'edit_activity_sheet.dart';
// Sprint 19: 삭제된 imports (DailyGrid로 통합)
// import 'timeline_filter_chips.dart';
// import 'mini_time_bar.dart';
// import 'context_ribbon.dart';
// import 'last_activity_badges.dart';

/// 일간 뷰 (DailyView)
///
/// Sprint 19: 차트 재설계
/// - DateNavigator: 날짜 좌우 탐색
/// - DailyGrid: 2x2 요약 그리드 (수면/수유/기저귀/놀이)
/// - ActivityListItem: 스와이프 수정/삭제
///
/// 제거됨 (DailyGrid로 통합):
/// - TimelineFilterChips, MiniTimeBar, ContextRibbon, LastActivityBadges
class DailyView extends StatefulWidget {
  const DailyView({super.key});

  @override
  State<DailyView> createState() => _DailyViewState();
}

class _DailyViewState extends State<DailyView> with UndoDeleteMixin {
  /// FIX-B: 오늘 날짜 (시간 정보 제거하여 정확한 날짜 비교)
  late DateTime _selectedDate;

  // Sprint 19: _activeFilter 제거됨 (TimelineFilterChips 제거)

  /// 선택된 날짜의 활동 (Supabase에서 로드)
  List<ActivityModel> _dateActivities = [];
  bool _isLoading = false;
  String? _errorMessage;

  /// 이전 family_id (변경 감지용)
  String? _previousFamilyId;

  /// 스와이프 힌트 표시 여부 (첫 번째 아이템만)
  bool _showSwipeHint = true;

  /// 초기 로드 완료 여부
  bool _initialLoadDone = false;

  /// HF5: 이전 todayActivities 개수 (변경 감지용)
  int _previousActivityCount = -1;

  @override
  void initState() {
    super.initState();
    // FIX-B: 시간 정보 제거한 오늘 날짜
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // family 정보가 있으면 활동 로드
    final homeProvider = context.read<HomeProvider>();
    final currentFamilyId = homeProvider.family?.id;

    // FIX-B: 초기 로드 또는 family 변경 시 로드
    if (currentFamilyId != null && !_isLoading) {
      if (!_initialLoadDone || currentFamilyId != _previousFamilyId) {
        _previousFamilyId = currentFamilyId;
        _initialLoadDone = true;
        // SchedulerBinding으로 빌드 후 실행
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _loadActivitiesForDate();
        });
      }
    }

    // HF5: HomeProvider의 todayActivities 변경 감지 → 오늘 날짜면 리로드
    final todayActivityCount = homeProvider.todayActivities.length;
    if (_previousActivityCount >= 0 &&
        todayActivityCount != _previousActivityCount &&
        _isToday(_selectedDate) &&
        !_isLoading) {
      _previousActivityCount = todayActivityCount;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadActivitiesForDate();
      });
    } else {
      _previousActivityCount = todayActivityCount;
    }
  }

  /// 선택된 날짜의 활동 로드 (Supabase에서)
  Future<void> _loadActivitiesForDate() async {
    final homeProvider = context.read<HomeProvider>();
    final familyId = homeProvider.family?.id;

    if (familyId == null) {
      debugPrint('[WARN] [DailyView] Cannot load activities: family not set');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final activityRepo = ActivityRepository();
      final startOfDay =
          DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final allActivities = await activityRepo.getActivitiesByDateRange(
        familyId,
        startDate: startOfDay,
        endDate: endOfDay,
      );

      if (mounted) {
        setState(() {
          _dateActivities = allActivities;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[ERROR] [DailyView] Error loading activities: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  /// 날짜 변경
  void _onDateChanged(DateTime newDate) {
    setState(() => _selectedDate = newDate);
    _loadActivitiesForDate();
  }

  /// 날짜 선택 (DatePicker)
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

    if (picked != null && picked != _selectedDate) {
      _onDateChanged(picked);
    }
  }

  /// 기록 수정
  Future<void> _onEditActivity(ActivityModel activity) async {
    final result = await EditActivitySheet.show(
      context,
      activity: activity,
    );

    if (result != null && mounted) {
      // 수정 성공 시 로컬 상태 업데이트
      setState(() {
        final index = _dateActivities.indexWhere((a) => a.id == activity.id);
        if (index != -1) {
          _dateActivities[index] = result;
        }
      });

      // HomeProvider 동기화
      context.read<HomeProvider>().updateActivity(result);

      HapticFeedback.lightImpact();
    }
  }

  /// 기록 삭제
  Future<void> _onDeleteActivity(ActivityModel activity) async {
    final homeProvider = context.read<HomeProvider>();

    // Undo 토스트와 함께 삭제
    await deleteActivityWithUndo(
      activity: activity,
      homeProvider: homeProvider,
      context: context,
    );

    // 로컬 상태에서도 제거
    setState(() {
      _dateActivities.removeWhere((a) => a.id == activity.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeProvider>(
      builder: (context, homeProvider, child) {
        // HF3-FIX: family가 로드되었는데 아직 데이터가 없으면 로드
        final currentFamilyId = homeProvider.family?.id;
        if (currentFamilyId != null && !_initialLoadDone && !_isLoading) {
          _previousFamilyId = currentFamilyId;
          _initialLoadDone = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _loadActivitiesForDate();
          });
        }

        // 로딩 중
        if (_isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              color: LuluColors.lavenderMist,
            ),
          );
        }

        // 에러 상태
        if (_errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline,
                    size: 48, color: Colors.red.withValues(alpha: 0.7)),
                const SizedBox(height: 16),
                Text(_errorMessage!,
                    style: LuluTextStyles.bodyMedium
                        .copyWith(color: LuluTextColors.secondary)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadActivitiesForDate,
                  child: const Text('다시 시도'),
                ),
              ],
            ),
          );
        }

        // Sprint 19: 선택된 아기로만 필터링 (활동 유형 필터 제거)
        final babyFilteredActivities =
            _babyFilteredActivities(homeProvider.selectedBabyId);

        // Sprint 19: DailyGrid용 DayTimeline 생성
        final patternProvider = context.read<PatternDataProvider>();
        final dayTimeline = patternProvider.buildDayTimeline(
          _selectedDate,
          babyFilteredActivities,
        );

        // 활동 목록 (시간순 정렬)
        final sortedActivities = List<ActivityModel>.from(babyFilteredActivities)
          ..sort((a, b) => b.startTime.compareTo(a.startTime));

        return RefreshIndicator(
          onRefresh: _loadActivitiesForDate,
          color: LuluColors.lavenderMist,
          backgroundColor: LuluColors.deepBlue,
          child: CustomScrollView(
            slivers: [
              // DateNavigator
              SliverToBoxAdapter(
                child: DateNavigator(
                  selectedDate: _selectedDate,
                  onDateChanged: _onDateChanged,
                  onCalendarTap: _selectDate,
                ),
              ),

              // Sprint 19: DailyGrid (2x2 요약 그리드)
              // MiniTimeBar, ContextRibbon, LastActivityBadges, TimelineFilterChips 대체
              SliverToBoxAdapter(
                child: DailyGrid(
                  key: ValueKey(
                      'dailygrid_${_selectedDate.toIso8601String()}_${homeProvider.selectedBabyId}'),
                  dayTimeline: dayTimeline,
                  selectedDate: _selectedDate,
                ),
              ),

              // 활동 목록 또는 빈 상태
              if (sortedActivities.isEmpty)
                SliverFillRemaining(
                  child: _buildEmptyActivitiesState(homeProvider),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final activity = sortedActivities[index];
                      return ActivityListItem(
                        activity: activity,
                        onEdit: () => _onEditActivity(activity),
                        onDelete: () => _onDeleteActivity(activity),
                        showSwipeHint: _showSwipeHint && index == 0,
                        onTap: () {
                          // 스와이프 힌트 숨기기
                          if (_showSwipeHint) {
                            setState(() => _showSwipeHint = false);
                          }
                          // 탭 시 수정 시트 열기
                          _onEditActivity(activity);
                        },
                      );
                    },
                    childCount: sortedActivities.length,
                  ),
                ),

              // 하단 여백
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 아기 필터만 적용 (DailyGrid, ActivityList용)
  List<ActivityModel> _babyFilteredActivities(String? babyId) {
    if (babyId == null) return _dateActivities;
    return _dateActivities.where((a) => a.babyIds.contains(babyId)).toList();
  }

  // Sprint 19: _filterActivities 제거됨 (활동 유형 필터 제거)

  /// 활동 없음 상태
  Widget _buildEmptyActivitiesState(HomeProvider homeProvider) {
    final l10n = S.of(context)!;
    final dateStr = DateFormat('M월 d일 (E)', 'ko_KR').format(_selectedDate);
    final isToday = _isToday(_selectedDate);
    final babyName = homeProvider.selectedBaby?.name ?? '아기';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 원형 배경 + 메인 컬러
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: LuluColors.lavenderMist.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.edit_calendar,
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

  /// 오늘인지 확인
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}
