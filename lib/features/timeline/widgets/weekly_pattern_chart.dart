import 'package:flutter/material.dart';

import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_typography.dart';
import '../models/daily_pattern.dart';

/// 주간 패턴 히트맵 차트
///
/// 작업 지시서 v1.1: WeeklyPatternChart
/// - 7일 x 48슬롯 히트맵
/// - 밤잠/낮잠 색상 구분
/// - 수유 마커 오버레이
/// - 필터 칩 (수면/수유/전체)
/// - 주간 네비게이션 (이전/다음 주)
class WeeklyPatternChart extends StatelessWidget {
  final WeeklyPattern weeklyPattern;
  final PatternFilter filter;
  final ValueChanged<PatternFilter>? onFilterChanged;
  final ValueChanged<TimeSlot>? onSlotTap;
  final VoidCallback? onPreviousWeek;
  final VoidCallback? onNextWeek;
  final bool canGoNext;

  const WeeklyPatternChart({
    super.key,
    required this.weeklyPattern,
    this.filter = PatternFilter.all,
    this.onFilterChanged,
    this.onSlotTap,
    this.onPreviousWeek,
    this.onNextWeek,
    this.canGoNext = true,
  });

  @override
  Widget build(BuildContext context) {
    final hasData = weeklyPattern.hasEnoughData;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LuluColors.deepIndigo.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더 + 필터 칩
          _buildHeader(),

          const SizedBox(height: 16),

          // 데이터가 부족한 경우 안내 메시지
          if (!hasData) ...[
            _buildEmptyState(),
          ] else ...[
            // 시간 축 라벨
            _buildTimeAxisLabels(),

            const SizedBox(height: 8),

            // 히트맵 그리드
            _buildHeatmapGrid(),

            const SizedBox(height: 12),

            // 범례
            _buildLegend(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 타이틀
        Text(
          '주간 패턴',
          style: LuluTextStyles.titleSmall.copyWith(
            color: LuluTextColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        // HF3-FIX: 필터 칩을 별도 줄로 분리
        if (onFilterChanged != null) ...[
          const SizedBox(height: 10),
          _PatternFilterChips(
            selectedFilter: filter,
            onFilterChanged: onFilterChanged!,
          ),
        ],
        // 주간 네비게이션
        if (onPreviousWeek != null || onNextWeek != null) ...[
          const SizedBox(height: 12),
          _WeekNavigator(
            weeklyPattern: weeklyPattern,
            onPreviousWeek: onPreviousWeek,
            onNextWeek: onNextWeek,
            canGoNext: canGoNext,
          ),
        ],
      ],
    );
  }

  Widget _buildTimeAxisLabels() {
    return Row(
      children: [
        // 요일 라벨 공간
        const SizedBox(width: 32),
        // 시간 라벨
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [0, 6, 12, 18, 24].map((h) {
              return Text(
                h.toString().padLeft(2, '0'),
                style: TextStyle(
                  color: LuluTextColors.tertiary,
                  fontSize: 10,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildHeatmapGrid() {
    return Column(
      children: weeklyPattern.days.map((day) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              // 요일 라벨
              SizedBox(
                width: 32,
                child: Text(
                  '${day.weekdayString}\n${day.date.day}',
                  style: TextStyle(
                    color: LuluTextColors.secondary,
                    fontSize: 10,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              // 48개 슬롯
              Expanded(
                child: SizedBox(
                  height: 20,
                  child: Row(
                    children: day.slots.map((slot) {
                      return Expanded(
                        child: _PatternCell(
                          slot: slot,
                          filter: filter,
                          onTap: onSlotTap != null
                              ? () => onSlotTap!(slot)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLegend() {
    return _PatternLegend(filter: filter);
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 48,
              color: LuluTextColors.tertiary,
            ),
            const SizedBox(height: 12),
            Text(
              '아직 패턴을 분석하기엔\n데이터가 부족해요',
              style: LuluTextStyles.bodyMedium.copyWith(
                color: LuluTextColors.secondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '3일 이상 기록하면 패턴이 나타나요',
              style: LuluTextStyles.caption.copyWith(
                color: LuluTextColors.tertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 주간 네비게이터
class _WeekNavigator extends StatelessWidget {
  final WeeklyPattern weeklyPattern;
  final VoidCallback? onPreviousWeek;
  final VoidCallback? onNextWeek;
  final bool canGoNext;

  const _WeekNavigator({
    required this.weeklyPattern,
    this.onPreviousWeek,
    this.onNextWeek,
    this.canGoNext = true,
  });

  @override
  Widget build(BuildContext context) {
    final startDate = weeklyPattern.days.first.date;
    final endDate = weeklyPattern.days.last.date;
    final dateRangeText =
        '${startDate.month}/${startDate.day} - ${endDate.month}/${endDate.day}';

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 이전 주 버튼
        GestureDetector(
          onTap: onPreviousWeek,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: LuluColors.surfaceElevated,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.chevron_left_rounded,
              size: 20,
              color: onPreviousWeek != null
                  ? LuluTextColors.primary
                  : LuluTextColors.tertiary,
            ),
          ),
        ),
        const SizedBox(width: 16),
        // 날짜 범위 표시
        Text(
          dateRangeText,
          style: LuluTextStyles.bodyMedium.copyWith(
            color: LuluTextColors.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 16),
        // 다음 주 버튼
        GestureDetector(
          onTap: canGoNext ? onNextWeek : null,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: LuluColors.surfaceElevated,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: canGoNext && onNextWeek != null
                  ? LuluTextColors.primary
                  : LuluTextColors.tertiary,
            ),
          ),
        ),
      ],
    );
  }
}

/// 패턴 필터 칩
/// HF3-FIX: 일간 필터 칩 스타일과 통일 (아이콘 + 전체 맨 앞)
class _PatternFilterChips extends StatelessWidget {
  final PatternFilter selectedFilter;
  final ValueChanged<PatternFilter> onFilterChanged;

  const _PatternFilterChips({
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    // HF3-FIX: "전체"를 맨 앞으로, 순서: 전체 → 수유 → 수면 → 기저귀 → 놀이 (건강 제외)
    final filters = [
      _FilterData(PatternFilter.all, '전체', Icons.apps_rounded, null),
      _FilterData(PatternFilter.feeding, '수유', Icons.local_cafe_rounded, LuluActivityColors.feeding),
      _FilterData(PatternFilter.sleep, '수면', Icons.bedtime_rounded, LuluActivityColors.sleep),
      _FilterData(PatternFilter.diaper, '기저귀', Icons.baby_changing_station_rounded, LuluActivityColors.diaper),
      _FilterData(PatternFilter.play, '놀이', Icons.toys_rounded, LuluActivityColors.play),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: filters.map((data) {
          final isSelected = selectedFilter == data.filter;
          final chipColor = data.color ?? LuluColors.lavenderMist;

          return Padding(
            padding: const EdgeInsets.only(left: 6),
            child: GestureDetector(
              onTap: () => onFilterChanged(data.filter),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? chipColor.withValues(alpha: 0.2)
                      : LuluColors.deepBlue,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? chipColor : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      data.icon,
                      size: 14,
                      color: isSelected ? chipColor : LuluTextColors.secondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      data.label,
                      style: TextStyle(
                        color: isSelected ? chipColor : LuluTextColors.secondary,
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// 필터 데이터 클래스
class _FilterData {
  final PatternFilter filter;
  final String label;
  final IconData icon;
  final Color? color;

  const _FilterData(this.filter, this.label, this.icon, this.color);
}

/// 개별 패턴 셀
/// FIX-F: 모든 활동을 색상 막대로 표시 (아이콘 제거)
class _PatternCell extends StatelessWidget {
  final TimeSlot slot;
  final PatternFilter filter;
  final VoidCallback? onTap;

  const _PatternCell({
    required this.slot,
    required this.filter,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final shouldShow = _shouldShowActivity();
    final color = shouldShow ? _getActivityColor() : Colors.transparent;

    // FIX-F: 아이콘 대신 색상 막대만 사용
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 0.5),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  bool _shouldShowActivity() {
    if (slot.activity == PatternActivityType.empty) return false;

    switch (filter) {
      case PatternFilter.sleep:
        return slot.activity == PatternActivityType.nightSleep ||
            slot.activity == PatternActivityType.daySleep;
      case PatternFilter.feeding:
        return slot.activity == PatternActivityType.feeding;
      case PatternFilter.diaper:
        return slot.activity == PatternActivityType.diaper;
      case PatternFilter.play:
        return slot.activity == PatternActivityType.play;
      case PatternFilter.health:
        return slot.activity == PatternActivityType.health;
      case PatternFilter.all:
        return true;
    }
  }

  Color _getActivityColor() {
    switch (slot.activity) {
      case PatternActivityType.nightSleep:
        return LuluPatternColors.nightSleep;
      case PatternActivityType.daySleep:
        return LuluPatternColors.daySleep;
      case PatternActivityType.feeding:
        return LuluPatternColors.feeding.withValues(alpha: 0.8);
      case PatternActivityType.diaper:
        return LuluPatternColors.diaper.withValues(alpha: 0.8);
      case PatternActivityType.play:
        return LuluPatternColors.play.withValues(alpha: 0.8);
      case PatternActivityType.health:
        return LuluPatternColors.health.withValues(alpha: 0.8);
      case PatternActivityType.empty:
        return Colors.transparent;
    }
  }
}

/// 패턴 범례
/// FIX-G: 기저귀/놀이/건강 추가 + 색상 막대 통일
class _PatternLegend extends StatelessWidget {
  final PatternFilter filter;

  const _PatternLegend({required this.filter});

  @override
  Widget build(BuildContext context) {
    // FIX-G: filter == all일 때 모든 활동 범례 표시
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        // 수면
        if (filter == PatternFilter.sleep || filter == PatternFilter.all) ...[
          _legendItem(LuluPatternColors.nightSleep, '밤잠'),
          _legendItem(LuluPatternColors.daySleep, '낮잠'),
        ],
        // 수유 - LuluPatternColors 사용 (= LuluActivityColors.feeding)
        if (filter == PatternFilter.feeding || filter == PatternFilter.all)
          _legendItem(LuluPatternColors.feeding, '수유'),
        // 기저귀 - LuluPatternColors 사용 (= LuluActivityColors.diaper)
        if (filter == PatternFilter.diaper || filter == PatternFilter.all)
          _legendItem(LuluPatternColors.diaper, '기저귀'),
        // 놀이 - LuluPatternColors 사용 (= LuluActivityColors.play)
        if (filter == PatternFilter.play || filter == PatternFilter.all)
          _legendItem(LuluPatternColors.play, '놀이'),
        // 건강 - LuluPatternColors 사용 (= LuluActivityColors.health)
        if (filter == PatternFilter.health || filter == PatternFilter.all)
          _legendItem(LuluPatternColors.health, '건강'),
      ],
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: LuluTextColors.secondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

/// 다태아 함께 보기 버튼
class TogetherViewButton extends StatelessWidget {
  final bool isEnabled;
  final VoidCallback? onTap;

  const TogetherViewButton({
    super.key,
    required this.isEnabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: isEnabled
              ? LuluColors.lavenderMist.withValues(alpha: 0.2)
              : LuluColors.surfaceElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isEnabled
                ? LuluColors.lavenderMist
                : LuluColors.glassBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.compare_arrows_rounded,
              size: 16,
              color: isEnabled
                  ? LuluColors.lavenderMist
                  : LuluTextColors.secondary,
            ),
            const SizedBox(width: 4),
            Text(
              '함께 보기',
              style: TextStyle(
                color: isEnabled
                    ? LuluColors.lavenderMist
                    : LuluTextColors.secondary,
                fontSize: 12,
                fontWeight: isEnabled ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 주간 패턴 차트 로딩 스켈레톤
class WeeklyPatternChartSkeleton extends StatelessWidget {
  const WeeklyPatternChartSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LuluColors.deepIndigo.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더 스켈레톤
          Row(
            children: [
              _SkeletonBox(width: 80, height: 20),
              const Spacer(),
              _SkeletonBox(width: 120, height: 24),
            ],
          ),
          const SizedBox(height: 16),
          // 시간 축 스켈레톤
          Row(
            children: [
              const SizedBox(width: 32),
              Expanded(child: _SkeletonBox(width: double.infinity, height: 12)),
            ],
          ),
          const SizedBox(height: 8),
          // 7일 그리드 스켈레톤
          ...List.generate(
            7,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  _SkeletonBox(width: 32, height: 24),
                  const SizedBox(width: 4),
                  Expanded(child: _SkeletonBox(width: double.infinity, height: 20)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // 범례 스켈레톤
          Center(child: _SkeletonBox(width: 160, height: 16)),
        ],
      ),
    );
  }
}

/// 스켈레톤 박스 (shimmer 효과)
class _SkeletonBox extends StatefulWidget {
  final double width;
  final double height;

  const _SkeletonBox({required this.width, required this.height});

  @override
  State<_SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<_SkeletonBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: 0.3, end: 0.6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: LuluColors.surfaceElevated.withValues(alpha: _animation.value),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      },
    );
  }
}
