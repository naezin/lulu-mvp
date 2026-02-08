import 'package:intl/intl.dart';

import 'parsed_activity.dart';

/// 베이비타임 activity TXT 파일 파서
///
/// 베이비타임 앱에서 내보낸 activity_*.txt 파일을 파싱합니다.
///
/// 지원하는 기록 종류:
/// - 분유, 모유, 유축수유 → feeding
/// - 낮잠, 밤잠 → sleep
/// - 기저귀 → diaper
/// - 놀이, 터미타임, 목욕, 외출 → play
/// - 체온, 투약 → health
///
/// 파일 형식 예시:
/// ```
/// 2026-01-06 06:14 AM
/// 기록 종류: 분유
/// 분유 총 양(ml): 100 (ml)
/// ====================
/// ```
class BabytimeParser {
  // 블록 구분자 (=====)
  static final _blockSeparator = RegExp(r'={10,}');

  // 시간 범위 패턴 (수면 등)
  // 예: 2026-01-06 01:40 AM ~ 2026-01-06 06:14 AM
  static final _timeRangePattern = RegExp(
    r'(\d{4}-\d{2}-\d{2}\s+\d{1,2}:\d{2}\s*[AP]M)\s*~\s*(\d{4}-\d{2}-\d{2}\s+\d{1,2}:\d{2}\s*[AP]M)',
    caseSensitive: false,
  );

  // 단일 시간 패턴
  // 예: 2026-01-06 06:14 AM
  static final _singleTimePattern = RegExp(
    r'^(\d{4}-\d{2}-\d{2}\s+\d{1,2}:\d{2}\s*[AP]M)\s*$',
    caseSensitive: false,
  );

  // 날짜 형식 (AM/PM)
  static final _dateFormat = DateFormat('yyyy-MM-dd hh:mm a');
  static final _dateFormatNoSpace = DateFormat('yyyy-MM-dd h:mm a');

  /// TXT 파일 내용 파싱
  ///
  /// [content] TXT 파일 내용
  /// Returns 파싱된 활동 목록
  Future<List<ParsedActivity>> parse(String content) async {
    final activities = <ParsedActivity>[];

    // 블록 단위로 분리
    final blocks = content.split(_blockSeparator);

    for (final block in blocks) {
      final trimmed = block.trim();
      if (trimmed.isEmpty) continue;

      try {
        final activity = _parseBlock(trimmed);
        if (activity != null) {
          activities.add(activity);
        }
      } catch (e) {
        // 파싱 실패한 블록은 건너뜀
        continue;
      }
    }

    return activities;
  }

  /// 단일 블록 파싱
  ParsedActivity? _parseBlock(String block) {
    final lines =
        block.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    if (lines.isEmpty) return null;

    // 1. 시간 파싱 (첫 줄)
    DateTime? startTime;
    DateTime? endTime;

    final firstLine = lines[0];

    // 시간 범위 체크 (수면 등)
    final timeRangeMatch = _timeRangePattern.firstMatch(firstLine);
    if (timeRangeMatch != null) {
      startTime = _parseTime(timeRangeMatch.group(1)!);
      endTime = _parseTime(timeRangeMatch.group(2)!);
    } else {
      // 단일 시간 체크
      final singleTimeMatch = _singleTimePattern.firstMatch(firstLine);
      if (singleTimeMatch != null) {
        startTime = _parseTime(singleTimeMatch.group(1)!);
      }
    }

    if (startTime == null) return null;

    // 2. 기록 종류 파싱
    String? recordType;
    for (final line in lines) {
      if (line.startsWith('기록 종류:') || line.startsWith('기록종류:')) {
        recordType = line.replaceFirst(RegExp(r'기록\s*종류:'), '').trim();
        break;
      }
    }

    if (recordType == null) return null;

    // 3. LULU ActivityType 매핑
    final activityType = _mapActivityType(recordType);
    if (activityType == null) return null;

    // 4. 상세 정보 파싱
    final data = <String, dynamic>{};
    String? notes;

    for (final line in lines) {
      // 분유 양
      if (line.contains('분유') && line.contains('ml')) {
        final match = RegExp(r'(\d+)').firstMatch(line);
        if (match != null) {
          data['amount_ml'] = int.parse(match.group(1)!);
          data['feedingType'] = 'bottle';
          data['formulaType'] = 'formula';
        }
      }
      // 모유 시간
      else if (line.contains('모유') &&
          (line.contains('시간') || line.contains('분'))) {
        final match = RegExp(r'(\d+)').firstMatch(line);
        if (match != null) {
          data['duration_minutes'] = int.parse(match.group(1)!);
          data['feedingType'] = 'breast';
        }
      }
      // 유축 양
      else if (line.contains('유축') && line.contains('ml')) {
        final match = RegExp(r'(\d+)').firstMatch(line);
        if (match != null) {
          data['amount_ml'] = int.parse(match.group(1)!);
          data['feedingType'] = 'bottle';
          data['formulaType'] = 'pumped';
        }
      }
      // 배변 형태
      else if (line.startsWith('배변 형태:') || line.startsWith('배변형태:')) {
        final type = line.replaceFirst(RegExp(r'배변\s*형태:'), '').trim();
        data['wet'] = type.contains('소변');
        data['dirty'] = type.contains('대변');
      }
      // 배변색 (HEX 코드)
      else if (line.startsWith('배변색:')) {
        final color = line.replaceFirst('배변색:', '').trim();
        if (color.isNotEmpty) {
          data['stoolColor'] = color;
        }
      }
      // 소요시간 (수면)
      else if (line.startsWith('소요시간:') || line.contains('소요시간')) {
        final match = RegExp(r'(\d+)').firstMatch(line);
        if (match != null) {
          data['duration_minutes'] = int.parse(match.group(1)!);
        }
      }
      // 메모
      else if (line.startsWith('메모:')) {
        notes = line.replaceFirst('메모:', '').trim();
        if (notes.isEmpty) notes = null;
      }
    }

    // 5. 수면 타입 결정 (낮잠/밤잠)
    if (activityType == 'sleep') {
      data['sleepType'] = recordType == '밤잠' ? 'night' : 'nap';
    }

    // 6. 놀이 타입 결정
    if (activityType == 'play') {
      if (recordType == '터미타임') {
        data['playType'] = 'tummyTime';
      } else if (recordType == '목욕') {
        data['playType'] = 'bath';
      } else if (recordType == '외출') {
        data['playType'] = 'outdoor';
      } else {
        data['playType'] = 'play';
      }
    }

    // 7. 건강 타입 결정
    if (activityType == 'health') {
      // 체온/투약 등
    }

    return ParsedActivity(
      type: activityType,
      startTime: startTime,
      endTime: endTime,
      data: data,
      notes: notes,
      source: 'babytime',
    );
  }

  /// 시간 문자열 파싱
  DateTime? _parseTime(String timeStr) {
    try {
      // 공백 정규화
      final normalized = timeStr.replaceAll(RegExp(r'\s+'), ' ').trim();

      // AM/PM 형식 파싱 시도
      try {
        return _dateFormat.parse(normalized);
      } catch (_) {}

      // 다른 형식 시도
      try {
        return _dateFormatNoSpace.parse(normalized);
      } catch (_) {}

      // ISO 형식 시도
      return DateTime.tryParse(normalized);
    } catch (e) {
      return null;
    }
  }

  /// 기록 종류 → LULU ActivityType 매핑
  String? _mapActivityType(String recordType) {
    switch (recordType) {
      case '분유':
      case '모유':
      case '유축수유':
      case '유축':
      case '수유':
        return 'feeding';
      case '낮잠':
      case '밤잠':
      case '수면':
        return 'sleep';
      case '기저귀':
      case '배변':
        return 'diaper';
      case '놀이':
      case '터미타임':
      case '외출':
      case '목욕':
        return 'play';
      case '체온':
      case '투약':
        return 'health';
      default:
        // 기록A, 기록B 등 커스텀 기록은 건너뜀
        return null;
    }
  }
}
