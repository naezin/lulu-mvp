import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../data/repositories/activity_repository.dart';
import '../../data/models/activity_model.dart';
import '../../data/models/baby_type.dart';
import '../../features/timeline/models/daily_pattern.dart';
import 'parsers/babytime_parser.dart';
import 'parsers/huckleberry_parser.dart';
import 'parsers/parsed_activity.dart';

/// 데이터 가져오기 서비스
///
/// 다른 육아 앱에서 내보낸 데이터를 LULU로 가져옵니다.
///
/// 지원 형식:
/// - TXT: 베이비타임 (activity_*.txt)
/// - CSV: Huckleberry
class ImportService {
  static final ImportService _instance = ImportService._internal();
  factory ImportService() => _instance;
  ImportService._internal();

  final ActivityRepository _activityRepository = ActivityRepository();
  final BabytimeParser _babytimeParser = BabytimeParser();
  final HuckleberryParser _huckleberryParser = HuckleberryParser();

  /// 파일 분석 (미리보기용)
  ///
  /// [file] 가져올 파일
  /// Returns ImportPreview (기록 수, 파싱된 활동 목록)
  Future<ImportPreview> analyzeFile(File file) async {
    final extension = file.path.split('.').last.toLowerCase();
    final content = await _readFile(file);

    List<ParsedActivity> activities;

    if (extension == 'txt') {
      activities = await _babytimeParser.parse(content);
    } else if (extension == 'csv') {
      activities = await _huckleberryParser.parse(content);
    } else {
      throw ImportException('Unsupported file format. Only TXT and CSV are supported.');
    }

    if (activities.isEmpty) {
      throw ImportException('No records found in the file.');
    }

    return ImportPreview.fromActivities(activities);
  }

  /// 파일 읽기 (인코딩 자동 감지)
  Future<String> _readFile(File file) async {
    try {
      // UTF-8 먼저 시도
      return await file.readAsString(encoding: utf8);
    } catch (e) {
      // UTF-8 실패 시 Latin1 시도 (EUC-KR 일부 호환)
      try {
        return await file.readAsString(encoding: latin1);
      } catch (e) {
        throw ImportException('Unable to read file. Please check the encoding.');
      }
    }
  }

  /// 가져오기 실행
  ///
  /// [preview] 분석된 미리보기 결과
  /// [babyId] LULU 아기 ID
  /// [familyId] LULU 가족 ID
  /// [onProgress] 진행률 콜백 (0.0 ~ 1.0)
  Future<ImportResult> importActivities({
    required ImportPreview preview,
    required String babyId,
    required String familyId,
    void Function(double progress)? onProgress,
  }) async {
    int successCount = 0;
    int skipCount = 0;
    final List<String> errors = [];

    final total = preview.activities.length;
    final batchSize = 100;

    // 중복 체크용 기존 활동 조회 (가족 전체)
    // babyId 기준 조회 시 Supabase contains 쿼리 문제가 있을 수 있어서 familyId로 조회
    final existingActivities = await _getExistingActivitiesByFamily(familyId);
    final existingKeys = _buildExistingKeys(existingActivities);

    debugPrint('[INFO] [ImportService] Importing to babyId: $babyId, familyId: $familyId');
    debugPrint('[INFO] [ImportService] Existing activities in family: ${existingActivities.length}');
    debugPrint('[INFO] [ImportService] Existing keys count: ${existingKeys.length}');

    // 배치 처리
    for (int i = 0; i < total; i += batchSize) {
      final end = (i + batchSize > total) ? total : i + batchSize;
      final batch = preview.activities.sublist(i, end);

      for (final parsed in batch) {
        try {
          // BUG-001 FIX: babyId 포함하여 중복 체크
          final key = _buildActivityKey(parsed.type, parsed.startTime, babyId: babyId);
          final isDuplicate = existingKeys.contains(key);

          // 첫 번째 항목에 대한 디버그 로그
          if (i == 0 && batch.indexOf(parsed) == 0) {
            debugPrint('[DEBUG] [ImportService] First parsed key: $key');
            debugPrint('[DEBUG] [ImportService] Is duplicate: $isDuplicate');
            if (existingKeys.isNotEmpty) {
              debugPrint('[DEBUG] [ImportService] First existing key: ${existingKeys.first}');
            }
          }

          // BUG-001 FIX: 중복 체크 다시 활성화
          if (isDuplicate) {
            skipCount++;
            continue;
          }

          // ActivityModel로 변환
          var activity = parsed.toActivityModel(
            babyId: babyId,
            familyId: familyId,
          );

          // sleep_type 자동 분류 (import 시 NULL 방지)
          // import/레거시 데이터는 시간 기반 분류 (18~06=night, 그 외=nap)
          if (activity.type == ActivityType.sleep) {
            final existingSleepType =
                activity.data?['sleep_type'] as String?;
            if (existingSleepType == null || existingSleepType.isEmpty) {
              final hour = activity.startTime.toLocal().hour;
              final sleepType =
                  SleepTimeConfig.isNightTime(hour) ? 'night' : 'nap';
              final updatedData = <String, dynamic>{
                ...?activity.data,
                'sleep_type': sleepType,
              };
              activity = activity.copyWith(data: updatedData);
            }
          }

          // 저장
          await _activityRepository.createActivity(activity);
          successCount++;

          // 중복 방지를 위해 키 추가
          existingKeys.add(key);
        } catch (e) {
          debugPrint('[ERROR] [ImportService] Save error: $e');
          errors.add('Failed to save record: ${parsed.startTime} - $e');
          skipCount++;
        }
      }

      // 진행률 업데이트
      if (onProgress != null) {
        onProgress(end / total);
      }
    }

    debugPrint(
        '[OK] [ImportService] Import complete: $successCount success, $skipCount skipped');

    return ImportResult(
      successCount: successCount,
      skipCount: skipCount,
      errors: errors,
    );
  }

  /// 기존 활동 조회 (중복 체크용) - 가족 전체 기록 조회
  Future<List<ActivityModel>> _getExistingActivitiesByFamily(
    String familyId,
  ) async {
    try {
      final activities = await _activityRepository.getActivitiesByFamilyId(
        familyId,
        limit: 10000, // 충분히 큰 수
      );
      debugPrint('[INFO] [ImportService] Fetched ${activities.length} existing activities from family');
      return activities;
    } catch (e) {
      debugPrint('[WARN] [ImportService] Failed to get existing activities: $e');
      return [];
    }
  }

  /// 기존 활동 키 세트 생성
  ///
  /// BUG-001 FIX: babyId 포함하여 각 아기별로 키 생성
  Set<String> _buildExistingKeys(List<ActivityModel> activities) {
    final keys = <String>{};
    for (final activity in activities) {
      // babyIds의 첫 번째 아기 ID 사용 (단일 아기 기록 가정)
      final babyId = activity.babyIds.isNotEmpty ? activity.babyIds.first : null;
      keys.add(_buildActivityKey(activity.type.name, activity.startTime, babyId: babyId));
    }
    return keys;
  }

  /// 활동 키 생성 (중복 체크용)
  /// 같은 babyId + 같은 타입 + 같은 시작시간(분 단위) = 중복
  ///
  /// BUG-001 FIX: babyId 포함하여 다태아 환경에서 중복 체크 정확도 향상
  String _buildActivityKey(String type, DateTime startTime, {String? babyId}) {
    // 분 단위로 반올림 (±1분 오차 허용)
    final rounded = DateTime(
      startTime.year,
      startTime.month,
      startTime.day,
      startTime.hour,
      startTime.minute,
    );
    // babyId 포함: 다태아 환경에서 각 아기별로 별도 키 생성
    final prefix = babyId != null ? '$babyId|' : '';
    return '$prefix$type|${rounded.toIso8601String()}';
  }

  /// 파일 확장자 확인
  bool isValidFile(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    return extension == 'txt' || extension == 'csv';
  }

  /// 파일 유형 이름
  String getFileTypeName(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    switch (extension) {
      case 'txt':
        return 'Text File';
      case 'csv':
        return 'CSV File';
      default:
        return 'Unknown Format';
    }
  }
}
