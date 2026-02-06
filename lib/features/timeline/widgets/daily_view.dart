import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_icons.dart';
import '../../../core/design_system/lulu_typography.dart';
import '../../../core/design_system/lulu_spacing.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/activity_repository.dart';
import '../../../l10n/generated/app_localizations.dart' show S;
import '../../../shared/widgets/undo_delete_mixin.dart';
import '../../home/providers/home_provider.dart';
import 'date_navigator.dart';
import 'timeline_filter_chips.dart';
import 'mini_time_bar.dart';
import 'context_ribbon.dart';
import 'activity_list_item.dart';
import 'edit_activity_sheet.dart';

/// 일간 뷰 (DailyView)
///
/// HF2-3: DailySummaryBanner 제거 (ContextRibbon만 사용)
/// - DateNavigator: 날짜 좌우 탐색
/// - TimelineFilterChips: 활동 유형 필터
/// - MiniTimeBar: 24h 패턴 시각화 (5종 활동 모두)
/// - ContextRibbon: 한 줄 요약
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

  /// 스와이프 힌트 표시 여부 (첫 번째 아이템만)
  bool _showSwipeHint = true;

  /// 초기 로드 완료 여부
  bool _initialLoadDone = false;

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
        _loadActivitiesForDate();
      }
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context)!.recordUpdated),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
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
                    size: 48, color: Colors.red.withValues(alpha: 0.7)),
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
            _dateActivities, homeProvider.selectedBabyId, _activeFilter);

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

              // TimelineFilterChips (활동 필터)
              SliverToBoxAdapter(
                child: TimelineFilterChips(
                  activeFilter: _activeFilter,
                  onFilterChanged: (filter) {
                    setState(() => _activeFilter = filter);
                  },
                ),
              ),

              // MiniTimeBar (활동이 있을 때만)
              if (activities.isNotEmpty)
                SliverToBoxAdapter(
                  child: MiniTimeBar(
                    key: ValueKey(
                        'minibar_${_selectedDate.toIso8601String()}_${homeProvider.selectedBabyId}'),
                    activities: activities,
                    date: _selectedDate,
                  ),
                ),

              // ContextRibbon (한 줄 요약)
              if (activities.isNotEmpty)
                SliverToBoxAdapter(
                  child: ContextRibbon(
                    activities: _dateActivities, // 필터 전 전체 데이터 사용
                  ),
                ),

              // HF2-3: DailySummaryBanner 제거 (ContextRibbon과 중복)

              // 활동 목록 또는 빈 상태
              if (activities.isEmpty)
                SliverFillRemaining(
                  child: _buildEmptyActivitiesState(homeProvider),
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
                          // 스와이프 힌트 숨기기
                          if (_showSwipeHint) {
                            setState(() => _showSwipeHint = false);
                          }
                          // 탭 시 수정 시트 열기
                          _onEditActivity(activity);
                        },
                      );
                    },
                    childCount: activities.length,
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

  /// 활동 없음 상태
  Widget _buildEmptyActivitiesState(HomeProvider homeProvider) {
    final l10n = S.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final dateStr = DateFormat.MMMEd(locale).format(_selectedDate);
    final isToday = _isToday(_selectedDate);
    final babyName = homeProvider.selectedBaby?.name ?? l10n.babyDefault;

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

  /// 오늘인지 확인
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}
