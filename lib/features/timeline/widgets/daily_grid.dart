import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_icons.dart';
import '../../../core/design_system/lulu_spacing.dart';
import '../../../l10n/generated/app_localizations.dart' show S;
import '../models/day_timeline.dart';

/// 일간 요약 그리드 (2x2)
///
/// Sprint 19 v4: MiniTimeBar + DailySummaryBanner 대체
/// 카드 디자인 패턴: 배경 10%, 보더 30%, 아이콘 배경 20%
/// - 수면: 총 시간 + 경과 시간
/// - 수유: 횟수 + 경과 시간
/// - 기저귀: 횟수 + 경과 시간
/// - 놀이: 총 시간
class DailyGrid extends StatefulWidget {
  final DayTimeline timeline;
  final bool isToday;

  const DailyGrid({
    super.key,
    required this.timeline,
    this.isToday = false,
  });

  @override
  State<DailyGrid> createState() => _DailyGridState();
}

class _DailyGridState extends State<DailyGrid> {
  Timer? _elapsedTimer;

  @override
  void initState() {
    super.initState();
    if (widget.isToday) {
      // 오늘인 경우 1분마다 경과 시간 갱신
      _elapsedTimer = Timer.periodic(
        const Duration(seconds: 60),
        (_) {
          if (mounted) setState(() {});
        },
      );
    }
  }

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: LuluSpacing.md,
        vertical: LuluSpacing.sm,
      ),
      child: GridView.count(
        crossAxisCount: 2, // 반드시 2x2 (v1의 1x3 버그 방지)
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: LuluSpacing.sm,
        crossAxisSpacing: LuluSpacing.sm,
        childAspectRatio: 1.4, // Sprint 19 v2: 카드 컴팩트화
        children: [
          // 수면
          _buildCell(
            context: context,
            icon: LuluIcons.sleep,
            color: LuluActivityColors.sleep,
            title: l10n?.dailyGridSleep ?? 'Sleep',
            value: _formatDurationValue(widget.timeline.totalDuration('sleep')),
            unit: _formatDurationUnit(widget.timeline.totalDuration('sleep')),
            sub: widget.isToday
                ? _formatElapsed(widget.timeline.lastActivityTime('sleep'))
                : null,
          ),
          // 수유
          _buildCell(
            context: context,
            icon: LuluIcons.feeding,
            color: LuluActivityColors.feeding,
            title: l10n?.dailyGridFeeding ?? 'Feeding',
            value: '${widget.timeline.countDuration('feeding')}',
            unit: l10n?.dailyGridCountUnit ?? 'times',
            sub: widget.isToday
                ? _formatElapsed(widget.timeline.lastActivityTime('feeding'))
                : null,
          ),
          // 기저귀
          _buildCell(
            context: context,
            icon: LuluIcons.diaper,
            color: LuluActivityColors.diaper,
            title: l10n?.dailyGridDiaper ?? 'Diaper',
            value: '${widget.timeline.countInstant('diaper')}',
            unit: l10n?.dailyGridCountUnit ?? 'times',
            sub: widget.isToday
                ? _formatElapsed(widget.timeline.lastActivityTime('diaper'))
                : null,
          ),
          // 놀이
          _buildCell(
            context: context,
            icon: LuluIcons.play,
            color: LuluActivityColors.play,
            title: l10n?.dailyGridPlay ?? 'Play',
            value: _formatDurationValue(widget.timeline.totalDuration('play')),
            unit: _formatDurationUnit(widget.timeline.totalDuration('play')),
            sub: null, // 놀이는 경과 시간 표시 안 함
          ),
        ],
      ),
    );
  }

  /// Sprint 19 v4: 새 카드 디자인 - 배경 10%, 보더 30%, 아이콘 배경 20%
  Widget _buildCell({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String title,
    required String value,
    String? unit,
    String? sub,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),           // v4: 카드 배경 10%
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.3),         // v4: 보더 30%
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 1행: 아이콘(컬러 배경 박스) + 레이블
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),  // v4: 아이콘 배경 20%
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    color: LuluTextColors.primary.withValues(alpha: 0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 2행: 숫자(크게) + 단위(작게) — 폰트 계층 분리
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,  // v4: 24 → 22 (WeeklyGrid와 일관성)
                  fontWeight: FontWeight.w700,
                  color: LuluTextColors.primary,
                ),
              ),
              if (unit != null) ...[
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: const TextStyle(
                    fontSize: 12,  // v4: 14 → 12 (WeeklyGrid와 일관성)
                    fontWeight: FontWeight.w400,
                    color: LuluTextColors.secondary,
                  ),
                ),
              ],
            ],
          ),
          // 3행: 경과 시간 또는 추세 — 항상 고정 높이 유지
          const SizedBox(height: 4),
          SizedBox(
            height: 20,  // 항상 20px 높이 확보 (값 없어도 정렬 유지)
            child: sub != null
                ? Text(
                    sub,
                    style: const TextStyle(
                      fontSize: 11,
                      color: LuluTextColors.tertiary,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  /// 숫자만 반환 (단위 분리)
  String _formatDurationValue(Duration d) {
    if (d.inMinutes == 0) return '-';
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h > 0) {
      // "11.9" 형식 (소수점 1자리)
      final decimal = (m * 10 ~/ 60);
      return '$h.$decimal';
    }
    return '$m';
  }

  /// 단위만 반환 (숫자 분리)
  String? _formatDurationUnit(Duration d) {
    if (d.inMinutes == 0) return null;
    final l10n = S.of(context);
    if (d.inHours > 0) return l10n?.dailyGridUnitHours ?? 'h';
    return l10n?.dailyGridUnitMinutes ?? 'm';
  }

  /// 경과 시간 포맷팅
  String? _formatElapsed(DateTime? lastTime) {
    if (lastTime == null) return null;

    final diff = DateTime.now().difference(lastTime);
    if (diff.isNegative) return null;

    final l10n = S.of(context);
    if (diff.inHours > 0) {
      return l10n?.dailyGridElapsedHours(diff.inHours, diff.inMinutes % 60) ??
          '${diff.inHours}h ${diff.inMinutes % 60}m ago';
    }
    return l10n?.dailyGridElapsedMinutes(diff.inMinutes) ??
        '${diff.inMinutes}m ago';
  }
}
