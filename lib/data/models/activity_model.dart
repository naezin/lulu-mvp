import 'baby_type.dart';
import 'feeding_type.dart';

/// 활동 기록 모델
/// MVP-F: 다중 아기 동시 기록 지원
class ActivityModel {
  final String id;
  final String familyId;
  final List<String> babyIds; // 다중 아기 지원
  final ActivityType type;
  final DateTime startTime;
  final DateTime? endTime;
  final Map<String, dynamic>? data; // 활동별 추가 데이터
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ActivityModel({
    required this.id,
    required this.familyId,
    required this.babyIds,
    required this.type,
    required this.startTime,
    this.endTime,
    this.data,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  // ========================================
  // Computed Properties
  // ========================================

  /// 진행 중 여부
  bool get isOngoing => endTime == null;

  /// 지속 시간 (분)
  /// 자정을 넘기는 경우도 정확히 계산 (QA-01 수정)
  int? get durationMinutes {
    if (endTime == null) return null;

    // 종료 시간이 시작 시간보다 이전이면 다음 날로 처리
    DateTime adjustedEnd = endTime!;
    if (endTime!.isBefore(startTime)) {
      // 자정을 넘긴 경우: 다음 날로 조정
      adjustedEnd = endTime!.add(const Duration(days: 1));
    }

    final duration = adjustedEnd.difference(startTime).inMinutes;
    return duration < 0 ? 0 : duration;
  }

  /// 다중 아기 기록 여부
  bool get isMultipleBabyRecord => babyIds.length > 1;

  /// 단일 아기 ID (단일 기록인 경우)
  String? get singleBabyId => babyIds.length == 1 ? babyIds.first : null;

  // ========================================
  // 활동별 데이터 접근자
  // ========================================

  /// 수유량 (ml) - feeding 타입용
  /// 🔧 Sprint 19 E: int/double 모두 처리
  double? get feedingAmountMl {
    final value = data?['amount_ml'];
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return null;
  }

  /// 수유 종류 - feeding 타입용
  String? get feedingType => data?['feeding_type'] as String?;

  /// 기저귀 종류 - diaper 타입용
  String? get diaperType => data?['diaper_type'] as String?;

  /// 체온 - health 타입용
  double? get temperatureCelsius => data?['temperature'] as double?;

  // ========================================
  // 수유 데이터 v2.0 접근자 (Sprint 8)
  // ========================================

  /// 신규 content_type 반환 (마이그레이션 지원)
  FeedingContentType? get feedingContentType {
    if (data == null) return null;

    // 신규 필드 우선
    if (data!.containsKey('content_type')) {
      final contentType = data!['content_type'] as String?;
      return contentType?.toFeedingContentType();
    }

    // 기존 필드 변환
    final oldType = data!['feeding_type'] as String?;
    return oldType?.toContentType();
  }

  /// 신규 method_type 반환 (마이그레이션 지원)
  FeedingMethodType? get feedingMethodType {
    if (data == null) return null;

    // 신규 필드 우선
    if (data!.containsKey('method_type')) {
      final methodType = data!['method_type'] as String?;
      return methodType?.toFeedingMethodType();
    }

    // 기존 필드 변환
    final oldType = data!['feeding_type'] as String?;
    return oldType?.toMethodType();
  }

  /// 수유 좌/우 - breast 타입용
  BreastSide? get breastSide {
    final side = data?['breast_side'] as String?;
    return BreastSideExtension.fromValue(side);
  }

  /// 수유 시간 (분) - breast 타입용
  int? get feedingDurationMinutes => data?['duration_minutes'] as int?;

  // ========================================
  // JSON 변환
  // ========================================

  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    return ActivityModel(
      id: json['id'] as String,
      familyId: json['family_id'] as String,
      babyIds: List<String>.from(json['baby_ids'] as List),
      type: ActivityType.fromValue(json['type'] as String),
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'] as String)
          : null,
      data: json['data'] as Map<String, dynamic>?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'family_id': familyId,
      'baby_ids': babyIds,
      'type': type.value,
      'start_time': startTime.toIso8601String(),
      if (endTime != null) 'end_time': endTime!.toIso8601String(),
      if (data != null) 'data': data,
      if (notes != null) 'notes': notes,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  // ========================================
  // 복사 (불변성 유지)
  // ========================================

  ActivityModel copyWith({
    String? id,
    String? familyId,
    List<String>? babyIds,
    ActivityType? type,
    DateTime? startTime,
    DateTime? endTime,
    Map<String, dynamic>? data,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ActivityModel(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      babyIds: babyIds ?? List.from(this.babyIds),
      type: type ?? this.type,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      data: data ?? (this.data != null ? Map.from(this.data!) : null),
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// 활동 종료 (endTime 설정)
  ActivityModel finish([DateTime? endAt]) {
    return copyWith(
      endTime: endAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ActivityModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ActivityModel(id: $id, type: ${type.value}, babyIds: $babyIds, '
        'startTime: $startTime, isOngoing: $isOngoing)';
  }
}

// ========================================
// 활동 생성 헬퍼
// ========================================

/// 수면 활동 생성
ActivityModel createSleepActivity({
  required String id,
  required String familyId,
  required List<String> babyIds,
  required DateTime startTime,
  DateTime? endTime,
  String? notes,
}) {
  return ActivityModel(
    id: id,
    familyId: familyId,
    babyIds: babyIds,
    type: ActivityType.sleep,
    startTime: startTime,
    endTime: endTime,
    notes: notes,
    createdAt: DateTime.now(),
  );
}

/// 수유 활동 생성
ActivityModel createFeedingActivity({
  required String id,
  required String familyId,
  required List<String> babyIds,
  required DateTime startTime,
  DateTime? endTime,
  double? amountMl,
  String? feedingType, // breast, bottle, formula
  String? notes,
}) {
  return ActivityModel(
    id: id,
    familyId: familyId,
    babyIds: babyIds,
    type: ActivityType.feeding,
    startTime: startTime,
    endTime: endTime,
    data: {
      if (amountMl != null) 'amount_ml': amountMl,
      if (feedingType != null) 'feeding_type': feedingType,
    },
    notes: notes,
    createdAt: DateTime.now(),
  );
}

/// 기저귀 활동 생성
ActivityModel createDiaperActivity({
  required String id,
  required String familyId,
  required List<String> babyIds,
  required DateTime time,
  required String diaperType, // wet, dirty, both, dry
  String? notes,
}) {
  return ActivityModel(
    id: id,
    familyId: familyId,
    babyIds: babyIds,
    type: ActivityType.diaper,
    startTime: time,
    data: {'diaper_type': diaperType},
    notes: notes,
    createdAt: DateTime.now(),
  );
}

/// 건강 기록 생성 (체온 등)
ActivityModel createHealthActivity({
  required String id,
  required String familyId,
  required List<String> babyIds,
  required DateTime time,
  double? temperatureCelsius,
  String? notes,
}) {
  return ActivityModel(
    id: id,
    familyId: familyId,
    babyIds: babyIds,
    type: ActivityType.health,
    startTime: time,
    data: {
      if (temperatureCelsius != null) 'temperature': temperatureCelsius,
    },
    notes: notes,
    createdAt: DateTime.now(),
  );
}
