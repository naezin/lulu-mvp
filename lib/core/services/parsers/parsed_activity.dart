import 'package:uuid/uuid.dart';

import '../../../data/models/activity_model.dart';
import '../../../data/models/baby_type.dart';

/// 파싱된 활동 데이터 (앱 간 공통 형식)
///
/// 베이비타임, Huckleberry 등 다양한 앱에서 파싱된 데이터를
/// LULU ActivityModel로 변환하기 위한 중간 형식
class ParsedActivity {
  /// 활동 유형 (feeding, sleep, diaper, play, health)
  final String type;

  /// 시작 시간
  final DateTime startTime;

  /// 종료 시간 (수면 등 시간 범위 기록)
  final DateTime? endTime;

  /// 상세 데이터 (유형별)
  /// - feeding: feedingType, formulaType, amount_ml, duration_minutes, breastSide
  /// - sleep: sleepType (nap/night)
  /// - diaper: wet, dirty, stoolColor
  /// - play: playType
  final Map<String, dynamic> data;

  /// 메모
  final String? notes;

  /// 원본 데이터 소스 (babytime, huckleberry)
  final String source;

  ParsedActivity({
    required this.type,
    required this.startTime,
    this.endTime,
    Map<String, dynamic>? data,
    this.notes,
    required this.source,
  }) : data = data ?? {};

  /// LULU ActivityModel로 변환
  ActivityModel toActivityModel({
    required String babyId,
    required String familyId,
  }) {
    return ActivityModel(
      id: const Uuid().v4(),
      familyId: familyId,
      babyIds: [babyId],
      type: _mapActivityType(type),
      startTime: startTime,
      endTime: endTime,
      data: _buildActivityData(),
      notes: notes,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  ActivityType _mapActivityType(String type) {
    switch (type) {
      case 'feeding':
        return ActivityType.feeding;
      case 'sleep':
        return ActivityType.sleep;
      case 'diaper':
        return ActivityType.diaper;
      case 'play':
        return ActivityType.play;
      case 'health':
        return ActivityType.health;
      default:
        return ActivityType.feeding;
    }
  }

  Map<String, dynamic> _buildActivityData() {
    final result = <String, dynamic>{...data};

    // 소스 정보 추가 (나중에 Import된 데이터 식별용)
    result['importedFrom'] = source;
    result['importedAt'] = DateTime.now().toIso8601String();

    return result;
  }

  @override
  String toString() {
    return 'ParsedActivity(type: $type, startTime: $startTime, endTime: $endTime, source: $source)';
  }
}

/// Import 미리보기 결과
class ImportPreview {
  final int feedingCount;
  final int sleepCount;
  final int diaperCount;
  final int playCount;
  final int healthCount;
  final int totalCount;

  /// 파싱된 활동 목록
  final List<ParsedActivity> activities;

  ImportPreview({
    required this.feedingCount,
    required this.sleepCount,
    required this.diaperCount,
    required this.playCount,
    required this.healthCount,
    required this.activities,
  }) : totalCount =
            feedingCount + sleepCount + diaperCount + playCount + healthCount;

  factory ImportPreview.fromActivities(List<ParsedActivity> activities) {
    int feeding = 0;
    int sleep = 0;
    int diaper = 0;
    int play = 0;
    int health = 0;

    for (final activity in activities) {
      switch (activity.type) {
        case 'feeding':
          feeding++;
          break;
        case 'sleep':
          sleep++;
          break;
        case 'diaper':
          diaper++;
          break;
        case 'play':
          play++;
          break;
        case 'health':
          health++;
          break;
      }
    }

    return ImportPreview(
      feedingCount: feeding,
      sleepCount: sleep,
      diaperCount: diaper,
      playCount: play,
      healthCount: health,
      activities: activities,
    );
  }
}

/// Import 결과
class ImportResult {
  final int successCount;
  final int skipCount;
  final List<String> errors;

  ImportResult({
    required this.successCount,
    required this.skipCount,
    List<String>? errors,
  }) : errors = errors ?? [];

  bool get hasErrors => errors.isNotEmpty;
}

/// Import 예외
class ImportException implements Exception {
  final String message;

  ImportException(this.message);

  @override
  String toString() => message;
}
