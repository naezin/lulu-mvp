import 'package:flutter/material.dart';
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
import 'date_navigator.dart';
import 'mini_time_bar.dart';
import 'daily_summary_banner.dart';
import 'activity_list_item.dart';
import 'edit_activity_sheet.dart';

/// 타임라인 탭 (기록 목록)
///
/// 작업 지시서 v1.1: 개선된 타임라인 탭
/// - DateNavigator: 날짜 좌우 탐색
/// - MiniTimeBar: 24h 패턴 시각화
/// - DailySummaryBanner: 일간 요약
/// - ActivityListItem: 스와이프 수정/삭제
class TimelineTab extends StatefulWidget {
  const TimelineTab({super.key});

  @override
  State<TimelineTab> createState() => _TimelineTabState();
}

class _TimelineTabState extends State<TimelineTab> with UndoDeleteMixin {
  DateTime _selectedDate = DateTime.now();

  /// 선택된 날짜의 활동 (Supabase에서 로드)
  List<ActivityModel> _dateActivities = [];
  bool _isLoading = false;
  String? _errorMessage;

  /// 이전 family_id (변경 감지용)
  String? _previousFamilyId;

  /// 스와이프 힌트 표시 여부 (첫 번째 아이템만)
  bool _showSwipeHint = true;

  @override
  void initState() {
    super.initState();
    // 초기 로드는 build에서 family 정보 확인 후 수행
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // family 정보가 있으면 활동 로드
    final homeProvider = context.read<HomeProvider>();
    final currentFamilyId = homeProvider.family?.id;

    // family가 변경되었거나 처음 로드인 경우
    if (currentFamilyId != null &&
        (currentFamilyId != _previousFamilyId || _dateActivities.isEmpty) &&
        !_isLoading) {
      _previousFamilyId = currentFamilyId;
      _loadActivitiesForDate();
    }
  }

  /// 선택된 날짜의 활동 로드 (Supabase에서)
  Future<void> _loadActivitiesForDate() async {
    final homeProvider = context.read<HomeProvider>();
    final familyId = homeProvider.family?.id;

    if (familyId == null) {
      debugPrint('[WARN] [TimelineTab] Cannot load activities: family not set');
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
          '[OK] [TimelineTab] Loaded ${allActivities.length} activities for selected date');

      setState(() {
        _dateActivities = allActivities;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ [TimelineTab] Error loading activities: $e');
      setState(() {
        _errorMessage = '활동을 불러오는데 실패했습니다: $e';
        _isLoading = false;
      });
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
        const SnackBar(
          content: Text('기록이 수정되었어요'),
          duration: Duration(seconds: 2),
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

        // 선택된 아기로 필터링
        final activities = _filterActivitiesByBaby(
            _dateActivities, homeProvider.selectedBabyId);

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

              // MiniTimeBar (활동이 있을 때만)
              if (activities.isNotEmpty)
                SliverToBoxAdapter(
                  child: MiniTimeBar(
                    activities: activities,
                    date: _selectedDate,
                  ),
                ),

              // DailySummaryBanner (활동이 있을 때만)
              if (activities.isNotEmpty)
                SliverToBoxAdapter(
                  child: DailySummaryBanner(
                    activities: activities,
                  ),
                ),

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

  /// 아기 ID로 활동 필터링
  List<ActivityModel> _filterActivitiesByBaby(
      List<ActivityModel> activities, String? babyId) {
    if (babyId == null) return activities;
    return activities.where((a) => a.babyIds.contains(babyId)).toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
  }

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
