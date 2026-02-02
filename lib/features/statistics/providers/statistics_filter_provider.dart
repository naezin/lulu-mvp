import 'package:flutter/foundation.dart';

/// 통계 필터 상태 Provider
///
/// 작업 지시서 v1.2.1: 아기/기간 필터 상태 관리
/// Provider 분리: 필터 변경 시 → 탭만 리빌드
class StatisticsFilterProvider extends ChangeNotifier {
  /// 선택된 아기 인덱스
  /// -1: 함께 보기, 0: 전체, 1~n: 개별 아기
  int _selectedBabyIndex = 0;

  /// 선택된 기간
  DateRangeType _selectedDateRange = DateRangeType.thisWeek;

  /// 함께 보기 안내 표시 여부
  bool _hasShownTogetherGuide = false;

  // Getters
  int get selectedBabyIndex => _selectedBabyIndex;
  DateRangeType get selectedDateRange => _selectedDateRange;
  bool get hasShownTogetherGuide => _hasShownTogetherGuide;

  /// 전체 선택 여부
  bool get isAllSelected => _selectedBabyIndex == 0;

  /// 함께 보기 선택 여부
  bool get isTogetherViewSelected => _selectedBabyIndex == -1;

  /// 개별 아기 선택 여부
  bool get isIndividualSelected => _selectedBabyIndex > 0;

  /// 아기 선택 변경
  void selectBaby(int index) {
    if (_selectedBabyIndex != index) {
      _selectedBabyIndex = index;
      notifyListeners();
    }
  }

  /// 기간 선택 변경
  void selectDateRange(DateRangeType range) {
    if (_selectedDateRange != range) {
      _selectedDateRange = range;
      notifyListeners();
    }
  }

  /// 함께 보기 안내 표시 완료
  void markTogetherGuideShown() {
    _hasShownTogetherGuide = true;
    // 이 상태는 UI 변경이 필요 없으므로 notifyListeners 호출 안 함
  }

  /// 필터 초기화
  void reset() {
    _selectedBabyIndex = 0;
    _selectedDateRange = DateRangeType.thisWeek;
    notifyListeners();
  }

  /// 현재 기간의 시작/종료일 계산
  DateRange getDateRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (_selectedDateRange) {
      case DateRangeType.thisWeek:
        // 이번 주 월요일부터 오늘까지
        final monday = today.subtract(Duration(days: today.weekday - 1));
        return DateRange(start: monday, end: today);

      case DateRangeType.lastWeek:
        // 지난 주 월요일부터 일요일까지
        final thisMonday = today.subtract(Duration(days: today.weekday - 1));
        final lastMonday = thisMonday.subtract(const Duration(days: 7));
        final lastSunday = thisMonday.subtract(const Duration(days: 1));
        return DateRange(start: lastMonday, end: lastSunday);

      case DateRangeType.thisMonth:
        // 이번 달 1일부터 오늘까지
        final firstDay = DateTime(today.year, today.month, 1);
        return DateRange(start: firstDay, end: today);
    }
  }
}

/// 기간 유형
enum DateRangeType {
  thisWeek,
  lastWeek,
  thisMonth,
}

/// 날짜 범위
class DateRange {
  final DateTime start;
  final DateTime end;

  const DateRange({
    required this.start,
    required this.end,
  });

  /// 범위 내 일수
  int get dayCount => end.difference(start).inDays + 1;
}
