import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../data/repositories/activity_repository.dart';
import '../../data/models/activity_model.dart';
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
      throw ImportException('지원하지 않는 파일 형식입니다. (TXT, CSV만 지원)');
    }

    if (activities.isEmpty) {
      throw ImportException('파일에서 기록을 찾을 수 없습니다.');
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
        throw ImportException('파일을 읽을 수 없습니다. 인코딩을 확인해주세요.');
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

    // 중복 체크용 기존 활동 조회
    final existingActivities = await _getExistingActivities(familyId, babyId);
    final existingKeys = _buildExistingKeys(existingActivities);

    // 배치 처리
    for (int i = 0; i < total; i += batchSize) {
      final end = (i + batchSize > total) ? total : i + batchSize;
      final batch = preview.activities.sublist(i, end);

      for (final parsed in batch) {
        try {
          // 중복 체크
          final key = _buildActivityKey(parsed.type, parsed.startTime);
          if (existingKeys.contains(key)) {
            skipCount++;
            continue;
          }

          // ActivityModel로 변환
          final activity = parsed.toActivityModel(
            babyId: babyId,
            familyId: familyId,
          );

          // 저장
          await _activityRepository.createActivity(activity);
          successCount++;

          // 중복 방지를 위해 키 추가
          existingKeys.add(key);
        } catch (e) {
          errors.add('기록 저장 실패: ${parsed.startTime} - $e');
          skipCount++;
        }
      }

      // 진행률 업데이트
      if (onProgress != null) {
        onProgress(end / total);
      }
    }

    debugPrint(
        '✅ [ImportService] Import complete: $successCount success, $skipCount skipped');

    return ImportResult(
      successCount: successCount,
      skipCount: skipCount,
      errors: errors,
    );
  }

  /// 기존 활동 조회 (중복 체크용)
  Future<List<ActivityModel>> _getExistingActivities(
    String familyId,
    String babyId,
  ) async {
    try {
      return await _activityRepository.getActivitiesByBabyId(
        babyId,
        limit: 10000, // 충분히 큰 수
      );
    } catch (e) {
      debugPrint('⚠️ [ImportService] Failed to get existing activities: $e');
      return [];
    }
  }

  /// 기존 활동 키 세트 생성
  Set<String> _buildExistingKeys(List<ActivityModel> activities) {
    final keys = <String>{};
    for (final activity in activities) {
      keys.add(_buildActivityKey(activity.type.name, activity.startTime));
    }
    return keys;
  }

  /// 활동 키 생성 (중복 체크용)
  /// 같은 타입 + 같은 시작시간(분 단위) = 중복
  String _buildActivityKey(String type, DateTime startTime) {
    // 분 단위로 반올림 (±1분 오차 허용)
    final rounded = DateTime(
      startTime.year,
      startTime.month,
      startTime.day,
      startTime.hour,
      startTime.minute,
    );
    return '$type|${rounded.toIso8601String()}';
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
        return '텍스트 파일';
      case 'csv':
        return 'CSV 파일';
      default:
        return '알 수 없는 형식';
    }
  }
}
