import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/utils/app_toast.dart';

import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_radius.dart';
import '../../../core/design_system/lulu_icons.dart';
import '../../../core/design_system/lulu_typography.dart';
import '../../../core/design_system/lulu_spacing.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/activity_repository.dart';
import '../../../l10n/generated/app_localizations.dart' show S;
import '../../../shared/widgets/undo_delete_mixin.dart';
import '../../home/providers/home_provider.dart';
import '../providers/pattern_data_provider.dart';
import 'date_navigator.dart';
import 'timeline_filter_chips.dart';
import 'daily_grid.dart';
import 'activity_list_item.dart';
import 'edit_activity_sheet.dart';

/// 일간 뷰 (DailyView)
///
/// Sprint 19: MiniTimeBar + ContextRibbon → DailyGrid (2x2) 교체
/// - DateNavigator: 날짜 좌우 탐색
/// - TimelineFilterChips: 활동 유형 필터
/// - DailyGrid: 2x2 요약 그리드 (수면/수유/기저귀/놀이)
/// - ActivityListItem: 스와이프 수정/삭제
class DailyView extends StatefulWidget {
  const DailyView({super.key});

  @override
  State<DailyView> createState() => _DailyViewState();
}

class _DailyViewState extends State<DailyView> with UndoDeleteMixin {
  /// FIX-B: 오늘 날짜 (시간 정보 제거하여 정확한 날짜 비교)
  late DateTime _selectedDate;

  /// 활동 유형 필터 (null = 전체)
  String? _activeFilter;

  /// 선택된 날짜의 활동 (Supabase에서 로드)
  List<ActivityModel> _dateActivities = [];
  bool _isLoading = false;
  String? _errorMessage;

  /// 이전 family_id (변경 감지용)
  String? _previousFamilyId;

  /// Sprint 20 HF U2: 스와이프 힌트 3회만 표시 (SharedPreferences 기반)
  static const String _swipeHintCountKey = 'swipe_hint_shown_count';
  static const int _maxSwipeHintCount = 3;
  bool _showSwipeHint = false;

  /// 초기 로드 완료 여부
  bool _initialLoadDone = false;

  /// Sprint 19: DayTimeline 생성용 Provider
  final PatternDataProvider _patternProvider = PatternDataProvider();

  /// 수정 D: HomeProvider 변경 감지용
  int _lastActivitiesLength = 0;


  @override
  void initState() {
    super.initState();
    // FIX-B: 시간 정보 제거한 오늘 날짜
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    // Sprint 20 HF U2: 스와이프 힌트 카운트 로드
    _loadSwipeHintCount();
  }

  /// Sprint 20 HF U2: SharedPreferences에서 힌트 표시 횟수 로드
  Future<void> _loadSwipeHintCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final count = prefs.getInt(_swipeHintCountKey) ?? 0;
      if (count < _maxSwipeHintCount && mounted) {
        setState(() => _showSwipeHint = true);
      }
    } catch (e) {
      debugPrint('[WARN] [DailyView] Failed to load swipe hint count: $e');
    }
  }

  /// Sprint 20 HF U2: 힌트 숨김 + 카운트 증가
  Future<void> _dismissSwipeHint() async {
    if (!_showSwipeHint) return;
    setState(() => _showSwipeHint = false);
    try {
      final prefs = await SharedPreferences.getInstance();
      final count = prefs.getInt(_swipeHintCountKey) ?? 0;
      await prefs.setInt(_swipeHintCountKey, count + 1);
    } catch (e) {
      debugPrint('[WARN] [DailyView] Failed to save swipe hint count: $e');
    }
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
        _loadActivitiesForDate();
      }
    }
  }

  /// Sprint 20 HF #15: 탭 복귀 시 데이터 갱신
  /// RecordHistoryScreen이 Consumer로 rebuild되면
  /// DailyView도 rebuild됨. 오늘 날짜이고 HomeProvider의 활동 수가
  /// 로컬 캐시와 다르면 리로드.
  ///
  /// Sprint 21 HF #1: _reloadScheduled 플래그로 중복 리로드 방지
  /// 삭제 시 연쇄 rebuild → SnackBar 무한 재생성 → 토스트 안 사라짐 문제 해결
  bool _reloadScheduled = false;

  /// Sprint 21 Phase 2-4: decoupled from HomeProvider reference
  void _checkAndReloadIfStale(int todayActivitiesCount) {
    if (!_isToday(_selectedDate) || _isLoading || _reloadScheduled) return;

    final currentLength = todayActivitiesCount;
    // Sprint 21 HF #14: _lastActivitiesLength > 0 조건 제거
    // QuickRecord/FAB 후 Records 탭에서도 갱신되도록
    if (currentLength != _lastActivitiesLength && _initialLoadDone) {
      _reloadScheduled = true;
      _lastActivitiesLength = currentLength;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _reloadScheduled = false;
        if (mounted) {
          _loadActivitiesForDate();
        }
      });
    } else {
      _lastActivitiesLength = currentLength;
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

      debugPrint(
          '[OK] [DailyView] Loaded ${allActivities.length} activities for ${_selectedDate.toIso8601String().substring(0, 10)}');

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

  /// 날짜 선택 (커스텀 바텀시트)
  void _selectDate() {
    showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => _DayCalendarPickerSheet(
        selectedDate: _selectedDate,
      ),
    ).then((picked) {
      if (picked != null && picked != _selectedDate) {
        _onDateChanged(picked);
      }
    });
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

      // Sprint 21 Phase 3-1: AppToast for cross-tab reliability
      AppToast.showText(S.of(context)!.recordUpdated);
    }
  }

  /// 기록 삭제 (확인 다이얼로그 → 삭제 → 토스트)
  Future<void> _onDeleteActivity(ActivityModel activity) async {
    final homeProvider = context.read<HomeProvider>();

    final deleted = await deleteActivityWithConfirm(
      activity: activity,
      homeProvider: homeProvider,
      context: context,
    );

    if (deleted && mounted) {
      _lastActivitiesLength = homeProvider.todayActivities.length;
      setState(() {
        _dateActivities.removeWhere((a) => a.id == activity.id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sprint 21 Phase 2-4: Selector for selectedBabyId + todayActivities count
    return Selector<HomeProvider, ({String? selectedBabyId, int todayActivitiesCount})>(
      selector: (_, p) => (selectedBabyId: p.selectedBabyId, todayActivitiesCount: p.todayActivities.length),
      builder: (context, data, child) {
        // Sprint 20 HF #4/#15: HomeProvider 변경 감지 → 자동 리로드
        _checkAndReloadIfStale(data.todayActivitiesCount);

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
                Icon(LuluIcons.errorOutline,
                    size: 48, color: const Color(0xB3FF0000)),
                const SizedBox(height: 16),
                Text(_errorMessage!,
                    style: LuluTextStyles.bodyMedium
                        .copyWith(color: LuluTextColors.secondary)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadActivitiesForDate,
                  child: Text(S.of(context)!.retry),
                ),
              ],
            ),
          );
        }

        // 선택된 아기 + 활동 유형으로 필터링
        final activities = _filterActivities(
            _dateActivities, data.selectedBabyId, _activeFilter);

        // 빈 상태 판별: 아기별 필터링된 전체 활동 (유형 필터 무관)
        final babyActivities = _filterActivitiesByBaby(
            _dateActivities, data.selectedBabyId);
        final isEmpty = babyActivities.isEmpty;

        return RefreshIndicator(
          onRefresh: _loadActivitiesForDate,
          color: LuluColors.lavenderMist,
          backgroundColor: LuluColors.deepBlue,
          child: CustomScrollView(
            slivers: [
              // DateNavigator (항상 표시)
              SliverToBoxAdapter(
                child: DateNavigator(
                  selectedDate: _selectedDate,
                  onDateChanged: _onDateChanged,
                  onCalendarTap: _selectDate,
                ),
              ),

              // 빈 상태: DailyGrid + FilterChips 숨김 → 빈 상태 컴포넌트
              if (isEmpty)
                SliverToBoxAdapter(
                  child: _buildDailyEmptyContent(),
                )
              else ...[
                // TimelineFilterChips (활동 필터)
                SliverToBoxAdapter(
                  child: TimelineFilterChips(
                    activeFilter: _activeFilter,
                    onFilterChanged: (filter) {
                      setState(() => _activeFilter = filter);
                    },
                  ),
                ),

                // Sprint 19: DailyGrid (2x2) - MiniTimeBar + ContextRibbon 대체
                SliverToBoxAdapter(
                  child: Builder(
                    builder: (context) {
                      final filteredActivities = _filterActivitiesByBaby(
                          _dateActivities, data.selectedBabyId);
                      final timeline = _patternProvider.buildDayTimeline(
                          _selectedDate, filteredActivities);
                      debugPrint(
                          '[DEBUG] [DailyView→DailyGrid] _dateActivities=${_dateActivities.length}, '
                          'filtered=${filteredActivities.length}, '
                          'babyId=${data.selectedBabyId}, '
                          'timeline.durationBlocks=${timeline.durationBlocks.length}, '
                          'timeline.instantMarkers=${timeline.instantMarkers.length}');
                      return DailyGrid(
                        key: ValueKey(
                            'dailygrid_${_selectedDate.toIso8601String()}_${data.selectedBabyId}'),
                        timeline: timeline,
                        isToday: _isToday(_selectedDate),
                      );
                    },
                  ),
                ),

                // 활동 목록
                if (activities.isEmpty)
                  // 유형 필터 적용 후 빈 상태 (전체 기록은 있으나 해당 유형 없음)
                  SliverToBoxAdapter(
                    child: _buildNoRecordsTodayHint(),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final activity = activities[index];
                        return ActivityListItem(
                          activity: activity,
                          onEdit: () => _onEditActivity(activity),
                          onDelete: () => _onDeleteActivity(activity),
                          showSwipeHint: _showSwipeHint && index == 0,
                          onTap: () {
                            _dismissSwipeHint();
                            _onEditActivity(activity);
                          },
                        );
                      },
                      childCount: activities.length,
                    ),
                  ),
              ],

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

  /// 아기 ID로만 필터링 (DailyGrid용)
  List<ActivityModel> _filterActivitiesByBaby(
      List<ActivityModel> activities, String? babyId) {
    if (babyId == null) return activities;
    return activities.where((a) => a.babyIds.contains(babyId)).toList();
  }

  /// 아기 ID + 활동 유형으로 필터링
  List<ActivityModel> _filterActivities(
      List<ActivityModel> activities, String? babyId, String? typeFilter) {
    var filtered = activities;

    // 아기 필터
    if (babyId != null) {
      filtered = filtered.where((a) => a.babyIds.contains(babyId)).toList();
    }

    // 활동 유형 필터
    if (typeFilter != null) {
      filtered = filtered.where((a) => a.type.name == typeFilter).toList();
    }

    // 시간순 정렬 (최신 먼저)
    filtered.sort((a, b) => b.startTime.compareTo(a.startTime));

    return filtered;
  }

  /// 빈 상태 컴포넌트 (주간 뷰와 동일 패턴)
  Widget _buildDailyEmptyContent() {
    final l10n = S.of(context);
    final isToday = _isToday(_selectedDate);

    return SizedBox(
      height: 300,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: LuluColors.surfaceElevated,
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
                  ? (l10n?.dailyEmptyToday ?? 'Start your first record today')
                  : (l10n?.dailyEmptyPastDay ?? 'No records for this day'),
              style: LuluTextStyles.titleMedium.copyWith(
                color: LuluTextColors.primary,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// 유형 필터 적용 후 해당 유형 기록 없음 안내
  Widget _buildNoRecordsTodayHint() {
    final l10n = S.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final dateStr = DateFormat.MMMEd(locale).format(_selectedDate);
    final isToday = _isToday(_selectedDate);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: LuluSpacing.lg,
        vertical: LuluSpacing.xl,
      ),
      child: Center(
        child: Text(
          isToday
              ? l10n.dailyViewNoRecordsToday
              : l10n.dailyViewNoRecordsDate(dateStr),
          style: LuluTextStyles.bodyMedium.copyWith(
            color: LuluTextColors.tertiary,
          ),
          textAlign: TextAlign.center,
        ),
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

/// 일간 캘린더 피커 (BottomSheet)
///
/// Sprint 19 Phase 5: 주간 피커(_WeekCalendarPickerSheet)와 통일된 스타일.
/// 월간 달력에서 개별 날짜를 탭하면 해당 날짜 반환.
/// 미래 날짜는 선택 불가. 월요일 시작.
class _DayCalendarPickerSheet extends StatefulWidget {
  final DateTime selectedDate;

  const _DayCalendarPickerSheet({
    required this.selectedDate,
  });

  @override
  State<_DayCalendarPickerSheet> createState() =>
      _DayCalendarPickerSheetState();
}

class _DayCalendarPickerSheetState extends State<_DayCalendarPickerSheet> {
  late DateTime _displayMonth;

  @override
  void initState() {
    super.initState();
    _displayMonth = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
    );
  }

  /// Navigate months
  void _goToPreviousMonth() {
    setState(() {
      _displayMonth = DateTime(_displayMonth.year, _displayMonth.month - 1);
    });
  }

  void _goToNextMonth() {
    final now = DateTime.now();
    final nextMonth = DateTime(_displayMonth.year, _displayMonth.month + 1);
    if (nextMonth.isAfter(DateTime(now.year, now.month + 1))) return;
    setState(() {
      _displayMonth = nextMonth;
    });
  }

  /// Jump to today
  void _goToToday() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    Navigator.of(context).pop(today);
  }

  /// Build the calendar grid weeks
  List<List<DateTime>> _buildCalendarWeeks() {
    final firstDayOfMonth = DateTime(_displayMonth.year, _displayMonth.month);
    final lastDayOfMonth =
        DateTime(_displayMonth.year, _displayMonth.month + 1, 0);

    // Start from the Monday on or before the 1st
    final calendarStart =
        firstDayOfMonth.subtract(Duration(days: firstDayOfMonth.weekday - 1));

    final weeks = <List<DateTime>>[];
    var current = calendarStart;

    while (current.isBefore(lastDayOfMonth) ||
        current.month == _displayMonth.month ||
        weeks.length < 5) {
      final week = List.generate(7, (i) => current.add(Duration(days: i)));
      weeks.add(week);
      current = current.add(const Duration(days: 7));
      if (weeks.length >= 6) break;
    }

    return weeks;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isDayToday(DateTime date) {
    final now = DateTime.now();
    return _isSameDay(date, now);
  }

  bool _isFutureDay(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    return target.isAfter(today);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final weeks = _buildCalendarWeeks();

    return Container(
      decoration: const BoxDecoration(
        color: LuluColors.surfaceCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: LuluSpacing.lg,
        vertical: LuluSpacing.md,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: LuluSpacing.md),
              decoration: BoxDecoration(
                color: LuluColors.glassBorder,
                borderRadius: BorderRadius.circular(LuluRadius.xxs),
              ),
            ),

            // Title + Today button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n?.dayPickerTitle ?? 'Select Date',
                  style: LuluTextStyles.titleSmall.copyWith(
                    color: LuluTextColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                GestureDetector(
                  onTap: _goToToday,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: LuluSpacing.sm,
                      vertical: LuluSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: LuluColors.navButtonBg,
                      borderRadius: BorderRadius.circular(LuluRadius.xs),
                    ),
                    child: Text(
                      l10n?.dayPickerToday ?? 'Today',
                      style: LuluTextStyles.caption.copyWith(
                        color: LuluColors.lavenderMist,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: LuluSpacing.md),

            // Month navigator
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: _goToPreviousMonth,
                  child: Padding(
                    padding: const EdgeInsets.all(LuluSpacing.xs),
                    child: Icon(
                      LuluIcons.chevronLeft,
                      size: 20,
                      color: LuluTextColors.primary,
                    ),
                  ),
                ),
                Text(
                  _formatMonthYear(_displayMonth),
                  style: LuluTextStyles.bodyMedium.copyWith(
                    color: LuluTextColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                GestureDetector(
                  onTap: _goToNextMonth,
                  child: Padding(
                    padding: const EdgeInsets.all(LuluSpacing.xs),
                    child: Icon(
                      LuluIcons.chevronRight,
                      size: 20,
                      color: LuluTextColors.primary,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: LuluSpacing.sm),

            // Weekday headers (Mon ~ Sun)
            _buildWeekdayHeaders(l10n),

            const SizedBox(height: LuluSpacing.xs),

            // Calendar weeks (tappable individual days)
            ...weeks.map((week) => _buildWeekRow(week)),

            const SizedBox(height: LuluSpacing.md),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekdayHeaders(S? l10n) {
    final headers = [
      l10n?.weekdayMon ?? 'Mon',
      l10n?.weekdayTue ?? 'Tue',
      l10n?.weekdayWed ?? 'Wed',
      l10n?.weekdayThu ?? 'Thu',
      l10n?.weekdayFri ?? 'Fri',
      l10n?.weekdaySat ?? 'Sat',
      l10n?.weekdaySun ?? 'Sun',
    ];

    return Row(
      children: headers
          .map(
            (h) => Expanded(
              child: Center(
                child: Text(
                  h,
                  style: LuluTextStyles.caption.copyWith(
                    color: LuluTextColors.tertiary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildWeekRow(List<DateTime> week) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: week.map((date) {
          final isCurrentMonth = date.month == _displayMonth.month;
          final today = _isDayToday(date);
          final isFuture = _isFutureDay(date);
          final isSelected = _isSameDay(date, widget.selectedDate);

          return Expanded(
            child: GestureDetector(
              onTap: isFuture
                  ? null
                  : () {
                      HapticFeedback.selectionClick();
                      Navigator.of(context).pop(date);
                    },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: LuluSpacing.sm),
                child: Center(
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: today
                        ? BoxDecoration(
                            shape: BoxShape.circle,
                            color: LuluColors.lavenderMist,
                          )
                        : isSelected
                            ? BoxDecoration(
                                shape: BoxShape.circle,
                                color: LuluColors.weekPickerSelected,
                              )
                            : null,
                    alignment: Alignment.center,
                    child: Text(
                      '${date.day}',
                      style: LuluTextStyles.bodySmall.copyWith(
                        color: isFuture
                            ? LuluTextColors.tertiary
                            : today
                                ? LuluColors.midnightNavy
                                : isCurrentMonth
                                    ? LuluTextColors.primary
                                    : LuluTextColors.tertiary,
                        fontWeight:
                            (today || isSelected) ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _formatMonthYear(DateTime date) {
    final locale = Localizations.localeOf(context).languageCode;
    if (locale == 'ko') {
      return '${date.year}.${date.month}';
    }
    return DateFormat.yMMMM(locale).format(date);
  }
}
