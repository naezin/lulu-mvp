import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/feeding_type.dart';
import '../utils/sleep_classifier.dart';
import '../../data/models/activity_model.dart';
import '../../data/models/baby_type.dart';

/// 데이터 마이그레이션 서비스
///
/// v0.9.x → v1.0.0 마이그레이션:
/// - feeding_type → content_type + method_type
///
/// 마이그레이션 전략:
/// 1. 기존 데이터 읽기
/// 2. 신규 필드 추가 (기존 필드 유지)
/// 3. 실패 시 롤백 지원
class MigrationService {
  final SupabaseClient _supabase;

  MigrationService(this._supabase);

  /// 마이그레이션 필요 여부 확인
  ///
  /// content_type이 없고 feeding_type이 있는 수유 기록이 있으면 true
  Future<bool> needsMigration(String familyId) async {
    try {
      // feeding_type은 있지만 content_type은 없는 기록 조회
      final result = await _supabase
          .from('activities')
          .select('id, data')
          .eq('family_id', familyId)
          .eq('type', 'feeding')
          .limit(100);

      final activities = result as List;
      for (final activity in activities) {
        final data = activity['data'] as Map<String, dynamic>?;
        if (data == null) continue;

        // 기존 feeding_type이 있고 신규 content_type이 없으면 마이그레이션 필요
        if (data.containsKey('feeding_type') &&
            !data.containsKey('content_type')) {
          return true;
        }
      }

      return false;
    } catch (e) {
      // 에러 시 마이그레이션 불필요로 처리 (안전)
      return false;
    }
  }

  /// 수유 데이터 마이그레이션 실행
  ///
  /// 기존 feeding_type → content_type + method_type 변환
  Future<MigrationResult> migrateFeedingData(String familyId) async {
    int migratedCount = 0;
    int errorCount = 0;
    final errors = <String>[];
    final migratedIds = <String>[]; // 롤백용

    try {
      // 수유 기록 조회
      final result = await _supabase
          .from('activities')
          .select()
          .eq('family_id', familyId)
          .eq('type', 'feeding');

      final activities = result as List;

      for (final activity in activities) {
        try {
          final data = Map<String, dynamic>.from(activity['data'] ?? {});
          final oldType = data['feeding_type'] as String?;

          // 기존 타입이 없거나 이미 마이그레이션됨
          if (oldType == null) continue;
          if (data.containsKey('content_type')) continue;

          // 신규 필드 추가
          data['content_type'] = oldType.toContentType().name;
          final methodType = oldType.toMethodType();
          if (methodType != null) {
            data['method_type'] = methodType.name;
          }

          // 업데이트
          await _supabase
              .from('activities')
              .update({'data': data}).eq('id', activity['id']);

          migratedCount++;
          migratedIds.add(activity['id'] as String);
        } catch (e) {
          errorCount++;
          errors.add('Activity ${activity['id']}: $e');
        }
      }

      return MigrationResult(
        success: errorCount == 0,
        migratedCount: migratedCount,
        errorCount: errorCount,
        errors: errors,
        migratedIds: migratedIds,
      );
    } catch (e) {
      return MigrationResult(
        success: false,
        migratedCount: 0,
        errorCount: 1,
        errors: ['Migration failed: $e'],
        migratedIds: [],
      );
    }
  }

  /// 마이그레이션 롤백 (신규 필드 제거)
  ///
  /// 마이그레이션 실패 시 또는 문제 발생 시 호출
  Future<RollbackResult> rollbackMigration(
    String familyId,
    List<String> activityIds,
  ) async {
    int rolledBackCount = 0;
    int errorCount = 0;
    final errors = <String>[];

    try {
      for (final activityId in activityIds) {
        try {
          final result = await _supabase
              .from('activities')
              .select('data')
              .eq('id', activityId)
              .single();

          final data = Map<String, dynamic>.from(result['data'] ?? {});

          // 신규 필드 제거 (기존 feeding_type은 유지)
          data.remove('content_type');
          data.remove('method_type');

          await _supabase
              .from('activities')
              .update({'data': data}).eq('id', activityId);

          rolledBackCount++;
        } catch (e) {
          errorCount++;
          errors.add('Rollback Activity $activityId: $e');
        }
      }

      return RollbackResult(
        success: errorCount == 0,
        rolledBackCount: rolledBackCount,
        errorCount: errorCount,
        errors: errors,
      );
    } catch (e) {
      return RollbackResult(
        success: false,
        rolledBackCount: 0,
        errorCount: 1,
        errors: ['Rollback failed: $e'],
      );
    }
  }

  /// sleep_type NULL 마이그레이션 필요 여부
  Future<bool> needsSleepTypeMigration(String familyId) async {
    try {
      final result = await _supabase
          .from('activities')
          .select('id')
          .eq('family_id', familyId)
          .eq('type', 'sleep')
          .or('data->>sleep_type.is.null,data->>sleep_type.eq.')
          .limit(1);

      return (result as List).isNotEmpty;
    } catch (e) {
      debugPrint('[WARN] [MigrationService] needsSleepTypeMigration check failed: $e');
      return false;
    }
  }

  /// sleep_type NULL → SleepClassifier 일괄 분류
  ///
  /// 일회성 마이그레이션: NULL이 0건이면 즉시 리턴.
  /// 패턴 기반 분류를 위해 최근 30일 수면 기록을 참조.
  Future<MigrationResult> migrateSleepTypes(String familyId) async {
    int migratedCount = 0;
    int errorCount = 0;
    final errors = <String>[];
    final migratedIds = <String>[];

    try {
      // 1. sleep_type이 NULL이거나 빈 문자열인 수면 기록 조회
      final result = await _supabase
          .from('activities')
          .select()
          .eq('family_id', familyId)
          .eq('type', 'sleep')
          .or('data->>sleep_type.is.null,data->>sleep_type.eq.');

      final nullRecords = result as List;
      if (nullRecords.isEmpty) {
        debugPrint('[OK] [MigrationService] No NULL sleep_type records');
        return const MigrationResult(
          success: true,
          migratedCount: 0,
          errorCount: 0,
          errors: [],
          migratedIds: [],
        );
      }

      debugPrint('[INFO] [MigrationService] Found ${nullRecords.length} NULL sleep_type records');

      // 2. 최근 30일 수면 기록 조회 (패턴 추출용)
      final thirtyDaysAgo = DateTime.now()
          .subtract(const Duration(days: 30))
          .toUtc()
          .toIso8601String();
      final recentResult = await _supabase
          .from('activities')
          .select()
          .eq('family_id', familyId)
          .eq('type', 'sleep')
          .gte('start_time', thirtyDaysAgo)
          .order('start_time', ascending: false);

      final recentSleepRecords = (recentResult as List)
          .map((data) => ActivityModel(
                id: data['id'] as String,
                familyId: data['family_id'] as String,
                babyIds: List<String>.from(data['baby_ids'] as List),
                type: ActivityType.sleep,
                startTime: DateTime.parse(data['start_time'] as String).toLocal(),
                endTime: data['end_time'] != null
                    ? DateTime.parse(data['end_time'] as String).toLocal()
                    : null,
                data: data['data'] as Map<String, dynamic>?,
                createdAt: DateTime.parse(data['created_at'] as String).toLocal(),
              ))
          .toList();

      // 3. 각 NULL 레코드에 SleepClassifier 적용
      for (final record in nullRecords) {
        try {
          final startTime =
              DateTime.parse(record['start_time'] as String).toLocal();
          final endTimeStr = record['end_time'] as String?;
          final endTime = endTimeStr != null
              ? DateTime.parse(endTimeStr).toLocal()
              : null;

          final classified = SleepClassifier.classify(
            startTime: startTime,
            endTime: endTime,
            recentSleepRecords: recentSleepRecords,
          );

          final currentData = Map<String, dynamic>.from(
              (record['data'] as Map<String, dynamic>?) ?? {});
          currentData['sleep_type'] = classified;

          await _supabase
              .from('activities')
              .update({'data': currentData})
              .eq('id', record['id']);

          migratedCount++;
          migratedIds.add(record['id'] as String);
        } catch (e) {
          errorCount++;
          errors.add('Activity ${record['id']}: $e');
        }
      }

      debugPrint(
          '[OK] [MigrationService] Sleep type migration: $migratedCount migrated, $errorCount errors');

      return MigrationResult(
        success: errorCount == 0,
        migratedCount: migratedCount,
        errorCount: errorCount,
        errors: errors,
        migratedIds: migratedIds,
      );
    } catch (e) {
      debugPrint('[ERR] [MigrationService] Sleep type migration failed: $e');
      return MigrationResult(
        success: false,
        migratedCount: 0,
        errorCount: 1,
        errors: ['Sleep type migration failed: $e'],
        migratedIds: [],
      );
    }
  }

  /// 전체 롤백 (familyId 기준)
  Future<RollbackResult> rollbackAllMigration(String familyId) async {
    try {
      // content_type이 있는 모든 수유 기록 조회
      final result = await _supabase
          .from('activities')
          .select('id, data')
          .eq('family_id', familyId)
          .eq('type', 'feeding');

      final activities = result as List;
      final activityIds = <String>[];

      for (final activity in activities) {
        final data = activity['data'] as Map<String, dynamic>?;
        if (data != null && data.containsKey('content_type')) {
          activityIds.add(activity['id'] as String);
        }
      }

      if (activityIds.isEmpty) {
        return const RollbackResult(
          success: true,
          rolledBackCount: 0,
          errorCount: 0,
          errors: [],
        );
      }

      return rollbackMigration(familyId, activityIds);
    } catch (e) {
      return RollbackResult(
        success: false,
        rolledBackCount: 0,
        errorCount: 1,
        errors: ['Rollback query failed: $e'],
      );
    }
  }
}

/// 마이그레이션 결과
class MigrationResult {
  final bool success;
  final int migratedCount;
  final int errorCount;
  final List<String> errors;
  final List<String> migratedIds; // 롤백용

  const MigrationResult({
    required this.success,
    required this.migratedCount,
    required this.errorCount,
    required this.errors,
    required this.migratedIds,
  });

  @override
  String toString() {
    return 'MigrationResult(success: $success, migrated: $migratedCount, errors: $errorCount)';
  }
}

/// 롤백 결과
class RollbackResult {
  final bool success;
  final int rolledBackCount;
  final int errorCount;
  final List<String> errors;

  const RollbackResult({
    required this.success,
    required this.rolledBackCount,
    required this.errorCount,
    required this.errors,
  });

  @override
  String toString() {
    return 'RollbackResult(success: $success, rolledBack: $rolledBackCount, errors: $errorCount)';
  }
}
