import 'package:flutter/material.dart';

import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_spacing.dart';
import '../../../core/design_system/lulu_typography.dart';
import '../../../l10n/generated/app_localizations.dart' show S;
import '../models/day_timeline.dart';

/// WeeklyChartFull - 실제 시간 기반 주간 차트
///
/// Sprint 19: 차트 재설계
/// - 7일 x 24시간 레이아웃
/// - DurationBlock을 실제 시간에 맞춰 렌더링 (30분 슬롯 X)
/// - CustomPaint로 직접 그리기
/// - InstantMarker는 작은 점으로 표시
class WeeklyChartFull extends StatelessWidget {
  final List<DayTimeline> weekTimelines;
  final DateTime weekStart;
  final ChartFilter filter;
  final ValueChanged<ChartFilter>? onFilterChanged;

  const WeeklyChartFull({
    super.key,
    required this.weekTimelines,
    required this.weekStart,
    this.filter = ChartFilter.all,
    this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context)!;

    // 데이터 유효성 확인
    final hasData = weekTimelines.any((day) =>
        day.durationBlocks.isNotEmpty || day.instantMarkers.isNotEmpty);

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: LuluSpacing.md,
        vertical: LuluSpacing.sm,
      ),
      padding: const EdgeInsets.all(LuluSpacing.md),
      decoration: BoxDecoration(
        color: LuluColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더 + 필터
          _buildHeader(l10n),

          const SizedBox(height: LuluSpacing.md),

          // 차트 영역
          if (!hasData)
            _buildEmptyState(l10n)
          else
            _buildChart(),

          const SizedBox(height: LuluSpacing.sm),

          // 범례
          if (hasData) _buildLegend(l10n),
        ],
      ),
    );
  }

  /// 헤더 (타이틀 + 필터 칩)
  Widget _buildHeader(S l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.weeklyChartTitle,
          style: LuluTextStyles.titleSmall.copyWith(
            color: LuluTextColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (onFilterChanged != null) ...[
          const SizedBox(height: LuluSpacing.sm),
          _FilterChips(
            selectedFilter: filter,
            onFilterChanged: onFilterChanged!,
          ),
        ],
      ],
    );
  }

  /// 빈 상태
  Widget _buildEmptyState(S l10n) {
    return Container(
      height: 200,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart_rounded,
            size: 48,
            color: LuluTextColors.tertiary,
          ),
          const SizedBox(height: LuluSpacing.sm),
          Text(
            l10n.statisticsEmptyHint,
            style: LuluTextStyles.bodySmall.copyWith(
              color: LuluTextColors.tertiary,
            ),
          ),
        ],
      ),
    );
  }

  /// 차트 영역
  Widget _buildChart() {
    return SizedBox(
      height: 220, // 7일 x 28px + 시간축 24px
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 요일 라벨
          _buildDayLabels(),

          const SizedBox(width: LuluSpacing.xs),

          // 차트 본체
          Expanded(
            child: Column(
              children: [
                // 시간 축
                _buildTimeAxis(),

                const SizedBox(height: 4),

                // 7일 행
                Expanded(
                  child: Column(
                    children: List.generate(7, (dayIndex) {
                      final timeline = dayIndex < weekTimelines.length
                          ? weekTimelines[dayIndex]
                          : null;
                      return Expanded(
                        child: _DayRow(
                          timeline: timeline,
                          filter: filter,
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 요일 라벨 (월~일)
  Widget _buildDayLabels() {
    const days = ['월', '화', '수', '목', '금', '토', '일'];

    return SizedBox(
      width: 20,
      child: Column(
        children: [
          // 시간축 높이만큼 빈 공간
          const SizedBox(height: 20),

          // 요일 라벨
          ...List.generate(7, (index) {
            return Expanded(
              child: Center(
                child: Text(
                  days[index],
                  style: LuluTextStyles.caption.copyWith(
                    color: LuluTextColors.tertiary,
                    fontSize: 10,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  /// 시간 축 (0, 6, 12, 18, 24)
  Widget _buildTimeAxis() {
    return SizedBox(
      height: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _timeLabel('0'),
          _timeLabel('6'),
          _timeLabel('12'),
          _timeLabel('18'),
          _timeLabel('24'),
        ],
      ),
    );
  }

  Widget _timeLabel(String text) {
    return Text(
      text,
      style: LuluTextStyles.caption.copyWith(
        color: LuluTextColors.tertiary,
        fontSize: 9,
      ),
    );
  }

  /// 범례
  Widget _buildLegend(S l10n) {
    return Wrap(
      spacing: LuluSpacing.md,
      runSpacing: LuluSpacing.xs,
      children: [
        _legendItem(LuluPatternColors.nightSleep, l10n.sleepTypeNight),
        _legendItem(LuluPatternColors.daySleep, l10n.sleepTypeNap),
        _legendItem(LuluPatternColors.feeding, l10n.activityTypeFeeding),
        _legendItem(LuluPatternColors.play, l10n.activityTypePlay),
      ],
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: LuluTextStyles.caption.copyWith(
            color: LuluTextColors.secondary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

/// 필터 열거형
enum ChartFilter { all, sleep, feeding, play }

/// 필터 칩
class _FilterChips extends StatelessWidget {
  final ChartFilter selectedFilter;
  final ValueChanged<ChartFilter> onFilterChanged;

  const _FilterChips({
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: LuluSpacing.xs,
      children: ChartFilter.values.map((filter) {
        final isSelected = filter == selectedFilter;
        final label = switch (filter) {
          ChartFilter.all => '전체',
          ChartFilter.sleep => '수면',
          ChartFilter.feeding => '수유',
          ChartFilter.play => '놀이',
        };

        return GestureDetector(
          onTap: () => onFilterChanged(filter),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: LuluSpacing.sm,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? LuluColors.lavenderMist.withValues(alpha: 0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? LuluColors.lavenderMist
                    : LuluTextColors.tertiary.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Text(
              label,
              style: LuluTextStyles.caption.copyWith(
                color: isSelected
                    ? LuluColors.lavenderMist
                    : LuluTextColors.secondary,
                fontSize: 11,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// 하루 행 (CustomPaint)
class _DayRow extends StatelessWidget {
  final DayTimeline? timeline;
  final ChartFilter filter;

  const _DayRow({
    required this.timeline,
    required this.filter,
  });

  @override
  Widget build(BuildContext context) {
    if (timeline == null) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 1),
        decoration: BoxDecoration(
          color: LuluColors.deepIndigo.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(2),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 1),
      child: CustomPaint(
        painter: _DayRowPainter(
          timeline: timeline!,
          filter: filter,
        ),
        size: Size.infinite,
      ),
    );
  }
}

/// 하루 행 페인터 (실제 시간 기반 렌더링)
class _DayRowPainter extends CustomPainter {
  final DayTimeline timeline;
  final ChartFilter filter;

  _DayRowPainter({
    required this.timeline,
    required this.filter,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // 배경
    final bgPaint = Paint()
      ..color = LuluColors.deepIndigo.withValues(alpha: 0.1);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, width, height),
        const Radius.circular(2),
      ),
      bgPaint,
    );

    // DurationBlocks 그리기
    for (final block in timeline.durationBlocks) {
      // 필터 적용
      if (!_shouldShowBlock(block)) continue;

      final startX = (block.startHour / 24.0) * width;
      final endX = (block.endHour / 24.0) * width;
      final blockWidth = endX - startX;

      if (blockWidth < 1) continue; // 너무 작으면 스킵

      final color = _getBlockColor(block.type);
      final paint = Paint()..color = color;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(startX, 1, blockWidth, height - 2),
          const Radius.circular(2),
        ),
        paint,
      );
    }

    // InstantMarkers 그리기 (작은 점)
    for (final marker in timeline.instantMarkers) {
      // 필터 적용
      if (!_shouldShowMarker(marker)) continue;

      final x = (marker.timeHour / 24.0) * width;

      final color = _getMarkerColor(marker.type);
      final paint = Paint()..color = color;

      canvas.drawCircle(
        Offset(x, height / 2),
        2.5,
        paint,
      );
    }
  }

  bool _shouldShowBlock(DurationBlock block) {
    return switch (filter) {
      ChartFilter.all => true,
      ChartFilter.sleep =>
        block.type == 'nightSleep' || block.type == 'daySleep',
      ChartFilter.feeding => false, // 수유는 InstantMarker
      ChartFilter.play => block.type == 'play',
    };
  }

  bool _shouldShowMarker(InstantMarker marker) {
    return switch (filter) {
      ChartFilter.all => true,
      ChartFilter.sleep => false,
      ChartFilter.feeding => marker.type == 'feeding',
      ChartFilter.play => false,
    };
  }

  Color _getBlockColor(String type) {
    return switch (type) {
      'nightSleep' => LuluPatternColors.nightSleep,
      'daySleep' => LuluPatternColors.daySleep,
      'play' => LuluPatternColors.play,
      _ => LuluColors.lavenderMist.withValues(alpha: 0.5),
    };
  }

  Color _getMarkerColor(String type) {
    return switch (type) {
      'feeding' => LuluPatternColors.feeding,
      'diaper' => LuluPatternColors.diaper,
      'health' => LuluPatternColors.health,
      _ => LuluColors.lavenderMist,
    };
  }

  @override
  bool shouldRepaint(covariant _DayRowPainter oldDelegate) {
    return timeline != oldDelegate.timeline || filter != oldDelegate.filter;
  }
}
