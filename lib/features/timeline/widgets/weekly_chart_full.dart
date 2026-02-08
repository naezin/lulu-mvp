import 'package:flutter/material.dart';

import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_icons.dart';
import '../../../core/design_system/lulu_typography.dart';
import '../../../l10n/generated/app_localizations.dart' show S;
import '../models/day_timeline.dart';

/// Sprint 19 v2: 주간 패턴 차트 (실시간 렌더링)
///
/// 핵심 변경: 30분 슬롯 폐기 → DayTimeline(DurationBlock + InstantMarker) 기반
/// - 7일 x 24시간 CustomPaint 렌더링
/// - 실제 시간 위치에 비례한 픽셀 렌더링
/// - 5색상: sleep(purple), feeding(orange), diaper(blue), play(green), health(red)
class WeeklyChartFull extends StatelessWidget {
  /// 7일간의 DayTimeline 데이터
  final List<DayTimeline> weekTimelines;

  /// 활동 유형 필터 (null = 전체)
  final String? filter;
  final ValueChanged<String?>? onFilterChanged;

  /// 주 시작일
  final DateTime weekStartDate;

  const WeeklyChartFull({
    super.key,
    required this.weekTimelines,
    required this.weekStartDate,
    this.filter,
    this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hasData = weekTimelines.any((t) => t.hasData);
    final l10n = S.of(context);

    return Container(
      decoration: BoxDecoration(
        color: LuluColors.chartContainerBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: LuluColors.chartContainerBorder,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더 + 필터 칩
          _buildHeader(context, l10n),

          const SizedBox(height: 16),

          if (!hasData) ...[
            _buildEmptyState(context, l10n),
          ] else ...[
            // 시간 축 라벨
            _buildTimeAxisLabels(context),

            const SizedBox(height: 8),

            // 7일 CustomPaint 그리드 (단일 CustomPaint로 7행 직접 그림)
            _buildWeeklyGrid(context, l10n),

            const SizedBox(height: 12),

            // 범례
            _buildLegend(context, l10n),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, S? l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 제목
        Text(
          l10n?.weeklyChartTitle ?? 'Weekly Pattern',
          style: LuluTextStyles.titleSmall.copyWith(
            color: LuluTextColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        // 필터 칩 (스크롤 가능)
        if (onFilterChanged != null) ...[
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: _ChartFilterChipsV4(
              selectedFilter: filter,
              onFilterChanged: onFilterChanged!,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTimeAxisLabels(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: _calculateLabelWidth(context)), // 날짜 라벨 공간
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

  double _calculateLabelWidth(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context);
    final painter = TextPainter(
      text: const TextSpan(
        text: '31',
        style: TextStyle(fontSize: 10),
      ),
      textDirection: TextDirection.ltr,
      textScaler: scale,
    )..layout();
    return painter.width + 8;
  }

  Widget _buildWeeklyGrid(BuildContext context, S? l10n) {
    // 7일 보장 (부족하면 빈 타임라인으로 채움)
    final timelines = List<DayTimeline>.generate(7, (i) {
      final targetDate = weekStartDate.add(Duration(days: i));
      return weekTimelines.firstWhere(
        (t) => _isSameDay(t.date, targetDate),
        orElse: () => DayTimeline.empty(targetDate),
      );
    });

    final labelWidth = _calculateLabelWidth(context);
    final labels = timelines.map((t) {
      return '${t.date.day}';
    }).toList();

    // 단일 CustomPaint로 7행 전부 그림 (Flutter intrinsic height 우회)
    const double rowHeight = 28.0;
    const double totalHeight = 7 * rowHeight;

    return CustomPaint(
      painter: _WeeklyGridPainter(
        timelines: timelines,
        labels: labels,
        labelWidth: labelWidth,
        rowHeight: rowHeight,
        filter: filter,
        labelColor: LuluTextColors.secondary,
      ),
      size: Size(double.infinity, totalHeight),
    );
  }

  Widget _buildLegend(BuildContext context, S? l10n) {
    return _ChartLegendV4(filter: filter, l10n: l10n);
  }

  Widget _buildEmptyState(BuildContext context, S? l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          children: [
            Icon(
              LuluIcons.statusStat,
              size: 48,
              color: LuluTextColors.tertiary,
            ),
            const SizedBox(height: 12),
            Text(
              l10n?.weeklyChartEmptyTitle ?? 'Not enough data\nto analyze patterns yet',
              style: LuluTextStyles.bodyMedium.copyWith(
                color: LuluTextColors.secondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n?.weeklyChartEmptyHint ?? 'Patterns will appear after 3+ days of records',
              style: LuluTextStyles.caption.copyWith(
                color: LuluTextColors.tertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

}

/// Sprint 19 v7: 단일 CustomPaint로 7행 전부 그리는 _WeeklyGridPainter
///
/// Flutter의 Column/Row/Expanded 중첩이 CustomPaint의 intrinsic height를
/// 계산 못하는 문제를 우회. 하나의 CustomPaint가 라벨 + 타임라인 바를 직접 그림.
class _WeeklyGridPainter extends CustomPainter {
  final List<DayTimeline> timelines;
  final List<String> labels;
  final double labelWidth;
  final double rowHeight;
  final String? filter;
  final Color labelColor;

  _WeeklyGridPainter({
    required this.timelines,
    required this.labels,
    required this.labelWidth,
    required this.rowHeight,
    this.filter,
    required this.labelColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final barAreaWidth = size.width - labelWidth;
    const double barHeightRatio = 0.78; // 행 높이 대비 바 높이 비율
    final barHeight = rowHeight * barHeightRatio;

    for (var i = 0; i < timelines.length; i++) {
      final y = i * rowHeight;
      final barY = y + (rowHeight - barHeight) / 2;

      // ── 라벨 텍스트 ──
      final labelSpan = TextSpan(
        text: labels[i],
        style: TextStyle(color: labelColor, fontSize: 10),
      );
      final labelPainter = TextPainter(
        text: labelSpan,
        textDirection: TextDirection.ltr,
      )..layout();
      labelPainter.paint(
        canvas,
        Offset(
          (labelWidth - labelPainter.width) / 2,
          y + (rowHeight - labelPainter.height) / 2,
        ),
      );

      // ── 배경 바 ──
      final bgPaint = Paint()..color = LuluColors.chartBarBg;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(labelWidth, barY, barAreaWidth, barHeight),
          const Radius.circular(4),
        ),
        bgPaint,
      );

      // ── 활동 블록 ──
      final timeline = timelines[i];
      final blocks = timeline.allBlocks
          .where((b) => filter == null || b.type == filter)
          .toList()
        ..sort((a, b) => b.duration.compareTo(a.duration));

      for (final block in blocks) {
        final startX = _timeToX(block.startTime, barAreaWidth, timeline.date);
        final endX = _timeToX(block.endTime, barAreaWidth, timeline.date);
        final color = _getTypeColor(block.type, block.subType);
        final remaining = barAreaWidth - startX;
        if (remaining <= 0) continue;
        final raw = (endX - startX).abs();
        final blockWidth = raw < 3.0 ? 3.0.clamp(0.0, remaining) : raw.clamp(0.0, remaining);

        canvas.drawRect(
          Rect.fromLTWH(
            labelWidth + startX,
            barY + (barHeight - barHeight * 0.8) / 2,
            blockWidth,
            barHeight * 0.8,
          ),
          Paint()..color = color,
        );
      }
    }
  }

  double _timeToX(DateTime time, double width, DateTime date) {
    final hourFraction = time.hour + time.minute / 60.0;
    if (hourFraction == 0 && _isEndOfDay(time, date)) {
      return width;
    }
    return hourFraction * (width / 24);
  }

  bool _isEndOfDay(DateTime time, DateTime date) {
    final nextDay = DateTime(date.year, date.month, date.day + 1);
    return time.year == nextDay.year &&
        time.month == nextDay.month &&
        time.day == nextDay.day &&
        time.hour == 0 &&
        time.minute == 0;
  }

  Color _getTypeColor(String type, String? subType) {
    switch (type) {
      case 'sleep':
        if (subType == 'night') {
          return LuluColors.legendNightSleep;
        }
        return LuluColors.legendDaySleep;
      case 'feeding':
        return LuluActivityColors.feeding;
      case 'diaper':
        return LuluActivityColors.diaper;
      case 'play':
        return LuluActivityColors.play;
      case 'health':
        return LuluActivityColors.health;
      default:
        return LuluColors.legendDaySleep;
    }
  }

  @override
  bool shouldRepaint(covariant _WeeklyGridPainter oldDelegate) {
    return oldDelegate.timelines != timelines ||
        oldDelegate.filter != filter ||
        oldDelegate.labels != labels;
  }
}

/// 필터 칩 v4
class _ChartFilterChipsV4 extends StatelessWidget {
  final String? selectedFilter;
  final ValueChanged<String?> onFilterChanged;

  const _ChartFilterChipsV4({
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  static Color _getChipSelectedBg(String? filterValue) {
    switch (filterValue) {
      case 'sleep':
        return LuluColors.chipSleepBg;
      case 'feeding':
        return LuluColors.chipFeedingBg;
      case 'diaper':
        return LuluColors.chipDiaperBg;
      case 'play':
        return LuluColors.chipPlayBg;
      case 'health':
        return LuluColors.chipHealthBg;
      default:
        return LuluColors.chartChipSelectedBg;
    }
  }

  static Color _getChipSelectedBorder(String? filterValue) {
    switch (filterValue) {
      case 'sleep':
        return LuluColors.chipSleepBorder;
      case 'feeding':
        return LuluColors.chipFeedingBorder;
      case 'diaper':
        return LuluColors.chipDiaperBorder;
      case 'play':
        return LuluColors.chipPlayBorder;
      case 'health':
        return LuluColors.chipHealthBorder;
      default:
        return LuluColors.chartChipSelectedBorder;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);

    final filters = [
      (null, l10n?.chartFilterAll ?? 'All', LuluColors.lavenderMist),
      ('sleep', l10n?.chartFilterSleep ?? 'Sleep', LuluActivityColors.sleep),
      ('feeding', l10n?.chartFilterFeeding ?? 'Feeding', LuluActivityColors.feeding),
      ('diaper', l10n?.chartFilterDiaper ?? 'Diaper', LuluActivityColors.diaper),
      ('play', l10n?.chartFilterPlay ?? 'Play', LuluActivityColors.play),
      ('health', l10n?.chartFilterHealth ?? 'Health', LuluActivityColors.health),
    ];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: filters.map((f) {
        final (filterValue, label, color) = f;
        final isSelected = selectedFilter == filterValue;

        return Padding(
          padding: const EdgeInsets.only(left: 4),
          child: GestureDetector(
            onTap: () => onFilterChanged(filterValue),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? _getChipSelectedBg(filterValue)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? _getChipSelectedBorder(filterValue)
                      : LuluColors.glassBorder,
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? color : LuluTextColors.secondary,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// 범례 v4
class _ChartLegendV4 extends StatelessWidget {
  final String? filter;
  final S? l10n;

  const _ChartLegendV4({this.filter, this.l10n});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        if (filter == null || filter == 'sleep') ...[
          _legendItem(
            LuluColors.legendNightSleep,
            l10n?.chartLegendNightSleep ?? 'Night',
          ),
          _legendItem(
            LuluColors.legendDaySleep,
            l10n?.chartLegendDaySleep ?? 'Nap',
          ),
        ],
        if (filter == null || filter == 'feeding')
          _legendItem(
            LuluActivityColors.feeding,
            l10n?.chartLegendFeeding ?? 'Feeding',
          ),
        if (filter == null || filter == 'diaper')
          _legendItem(
            LuluActivityColors.diaper,
            l10n?.chartLegendDiaper ?? 'Diaper',
          ),
        if (filter == null || filter == 'play')
          _legendItem(
            LuluActivityColors.play,
            l10n?.chartLegendPlay ?? 'Play',
          ),
        if (filter == null || filter == 'health')
          _legendItem(
            LuluActivityColors.health,
            l10n?.chartLegendHealth ?? 'Health',
          ),
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

/// Sprint 19 v2: 함께 보기 버튼 (다태아용)
///
/// i18n: statisticsTogetherView
/// LuluIcons: switchBaby (swap_horiz_rounded)
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
    final l10n = S.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: isEnabled
              ? const Color(0x33B8A9E8)
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
              LuluIcons.switchBaby,
              size: 16,
              color: isEnabled
                  ? LuluColors.lavenderMist
                  : LuluTextColors.secondary,
            ),
            const SizedBox(width: 4),
            Text(
              l10n?.statisticsTogetherView ?? 'Together',
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
