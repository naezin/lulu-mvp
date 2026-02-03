import 'package:csv/csv.dart';
import 'package:intl/intl.dart';

import 'parsed_activity.dart';

/// Huckleberry CSV 파일 파서
///
/// Huckleberry 앱에서 내보낸 CSV 파일을 파싱합니다.
///
/// 지원하는 기록 종류:
/// - Sleep → sleep
/// - Feed → feeding
/// - Diaper → diaper
/// - Growth → growth (건너뜀)
/// - Pump → (건너뜀)
///
/// CSV 형식:
/// ```
/// "Type","Start","End","Duration","Start Condition","Start Location","End Condition","Notes"
/// "Sleep","2026-01-06 01:40","2026-01-06 06:13","04:33",,,,
/// "Feed","2026-01-06 06:13",,,"Formula","Bottle",,
/// "Diaper","2026-01-06 05:50",,,,,,"Pee:large"
/// ```
class HuckleberryParser {
  // 24시간제 날짜 형식
  static final _dateFormat = DateFormat('yyyy-MM-dd HH:mm');

  // 대체 날짜 형식들
  static final _altDateFormats = [
    DateFormat('yyyy-MM-dd HH:mm:ss'),
    DateFormat('MM/dd/yyyy HH:mm'),
    DateFormat('M/d/yyyy H:mm'),
  ];

  /// CSV 파일 내용 파싱
  ///
  /// [content] CSV 파일 내용
  /// Returns 파싱된 활동 목록
  Future<List<ParsedActivity>> parse(String content) async {
    final activities = <ParsedActivity>[];

    // CSV 파싱
    final rows = const CsvToListConverter(
      eol: '\n',
      shouldParseNumbers: false,
    ).convert(content);

    if (rows.isEmpty) return activities;

    // 헤더 분석
    final header = rows.first.map((e) => e.toString().trim()).toList();

    // 필요한 컬럼 인덱스 찾기
    final typeIdx = _findColumnIndex(header, ['Type', 'type']);
    final startIdx = _findColumnIndex(header, ['Start', 'start', 'Start Time']);
    final endIdx = _findColumnIndex(header, ['End', 'end', 'End Time']);
    final durationIdx = _findColumnIndex(header, ['Duration', 'duration']);
    final startCondIdx =
        _findColumnIndex(header, ['Start Condition', 'Condition']);
    final startLocIdx =
        _findColumnIndex(header, ['Start Location', 'Location']);
    final endCondIdx = _findColumnIndex(header, ['End Condition']);
    final notesIdx = _findColumnIndex(header, ['Notes', 'Note', 'notes']);

    // 데이터 행 파싱
    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];

      try {
        final type = _getString(row, typeIdx);
        final startStr = _getString(row, startIdx);

        if (type.isEmpty || startStr.isEmpty) continue;

        // 시간 파싱
        final startTime = _parseTime(startStr);
        if (startTime == null) continue;

        DateTime? endTime;
        final endStr = _getString(row, endIdx);
        if (endStr.isNotEmpty) {
          endTime = _parseTime(endStr);
        }

        // 타입 매핑
        final activityType = _mapActivityType(type);
        if (activityType == null) continue;

        // 상세 데이터 파싱
        final data = <String, dynamic>{};
        String? notes = _getString(row, notesIdx);
        if (notes.isEmpty) notes = null;

        switch (type.toLowerCase()) {
          case 'feed':
            _parseFeedData(
              data,
              _getString(row, startCondIdx),
              _getString(row, startLocIdx),
            );
            break;

          case 'sleep':
            _parseSleepData(data, endTime ?? startTime);
            // Duration 파싱
            final durationStr = _getString(row, durationIdx);
            if (durationStr.isNotEmpty) {
              data['duration_minutes'] = _parseDuration(durationStr);
            }
            break;

          case 'diaper':
            _parseDiaperData(data, _getString(row, endCondIdx), notes);
            break;
        }

        activities.add(ParsedActivity(
          type: activityType,
          startTime: startTime,
          endTime: endTime,
          data: data,
          notes: notes,
          source: 'huckleberry',
        ));
      } catch (e) {
        // 파싱 실패한 행은 건너뜀
        continue;
      }
    }

    return activities;
  }

  /// 컬럼 인덱스 찾기
  int _findColumnIndex(List<String> header, List<String> candidates) {
    for (final candidate in candidates) {
      final index =
          header.indexWhere((h) => h.toLowerCase() == candidate.toLowerCase());
      if (index >= 0) return index;
    }
    return -1;
  }

  /// 셀 값 가져오기
  String _getString(List<dynamic> row, int index) {
    if (index < 0 || index >= row.length) return '';
    final value = row[index];
    if (value == null) return '';
    return value.toString().trim();
  }

  /// 시간 문자열 파싱
  DateTime? _parseTime(String timeStr) {
    if (timeStr.isEmpty) return null;

    // 기본 형식 시도
    try {
      return _dateFormat.parse(timeStr);
    } catch (_) {}

    // 대체 형식들 시도
    for (final format in _altDateFormats) {
      try {
        return format.parse(timeStr);
      } catch (_) {}
    }

    // ISO 형식 시도
    return DateTime.tryParse(timeStr);
  }

  /// Duration 문자열 파싱 (HH:mm 또는 H:mm 형식)
  int? _parseDuration(String durationStr) {
    try {
      final parts = durationStr.split(':');
      if (parts.length >= 2) {
        final hours = int.parse(parts[0]);
        final minutes = int.parse(parts[1]);
        return hours * 60 + minutes;
      }
    } catch (_) {}
    return null;
  }

  /// 수유 데이터 파싱
  void _parseFeedData(
    Map<String, dynamic> data,
    String condition,
    String location,
  ) {
    final condLower = condition.toLowerCase();
    final locLower = location.toLowerCase();

    if (condLower.contains('formula')) {
      data['feedingType'] = 'bottle';
      data['formulaType'] = 'formula';
    } else if (condLower.contains('breast')) {
      data['feedingType'] = 'breast';

      // 좌/우 구분
      if (locLower.contains('left')) {
        data['breastSide'] = 'left';
      } else if (locLower.contains('right')) {
        data['breastSide'] = 'right';
      } else if (locLower.contains('both')) {
        data['breastSide'] = 'both';
      }
    } else if (condLower.contains('bottle') || locLower.contains('bottle')) {
      data['feedingType'] = 'bottle';
    } else {
      // 기본값
      data['feedingType'] = 'bottle';
    }
  }

  /// 수면 데이터 파싱
  void _parseSleepData(Map<String, dynamic> data, DateTime time) {
    // 시간대로 낮잠/밤잠 구분
    // 19:00 ~ 07:00 = 밤잠, 그 외 = 낮잠
    final hour = time.hour;
    data['sleepType'] = (hour >= 19 || hour < 7) ? 'night' : 'nap';
  }

  /// 기저귀 데이터 파싱
  void _parseDiaperData(
    Map<String, dynamic> data,
    String endCondition,
    String? notes,
  ) {
    final lower = endCondition.toLowerCase();
    final notesLower = notes?.toLowerCase() ?? '';

    // Pee/Poo 체크
    data['wet'] = lower.contains('pee') ||
        lower.contains('wet') ||
        notesLower.contains('pee');
    data['dirty'] = lower.contains('poo') ||
        lower.contains('dirty') ||
        notesLower.contains('poo');

    // 둘 다 없으면 기본값 wet
    if (data['wet'] != true && data['dirty'] != true) {
      data['wet'] = true;
    }
  }

  /// Type → LULU ActivityType 매핑
  String? _mapActivityType(String type) {
    switch (type.toLowerCase()) {
      case 'feed':
      case 'feeding':
      case 'bottle':
      case 'breast':
        return 'feeding';
      case 'sleep':
      case 'nap':
        return 'sleep';
      case 'diaper':
        return 'diaper';
      case 'growth':
        return 'growth';
      case 'pump':
      case 'pumping':
        // 유축은 건너뜀 (LULU에서 별도 기록 없음)
        return null;
      default:
        return null;
    }
  }
}
