import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

import '../../data/models/models.dart';

/// 활동 기록 내보내기 서비스
///
/// 지원 형식:
/// - CSV: 기본 형식, 모든 스프레드시트 앱에서 열 수 있음
class ExportService {
  static final ExportService _instance = ExportService._internal();
  factory ExportService() => _instance;
  ExportService._internal();

  static ExportService get instance => _instance;

  /// 활동 기록을 CSV로 내보내기
  ///
  /// [activities] 내보낼 활동 목록
  /// [babies] 아기 정보 (이름 표시용)
  /// [dateRange] 날짜 범위 (파일명용)
  Future<void> exportToCSV({
    required List<ActivityModel> activities,
    required List<BabyModel> babies,
    DateTimeRange? dateRange,
  }) async {
    try {
      final csv = _generateCSV(activities, babies);
      final fileName = _generateFileName(dateRange);
      final file = await _saveToFile(csv, fileName);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'LULU 육아 기록',
        text: '육아 기록 데이터입니다.',
      );

      debugPrint('CSV exported: ${file.path}');
    } catch (e) {
      debugPrint('Export error: $e');
      rethrow;
    }
  }

  /// CSV 문자열 생성
  String _generateCSV(List<ActivityModel> activities, List<BabyModel> babies) {
    final buffer = StringBuffer();
    final dateFormat = DateFormat('yyyy-MM-dd');
    final timeFormat = DateFormat('HH:mm');

    // 아기 이름 맵
    final babyNames = {for (final baby in babies) baby.id: baby.name};

    // 헤더
    buffer.writeln('날짜,시간,종료시간,아기,유형,상세,양/시간,메모');

    // 데이터 행
    for (final activity in activities) {
      final date = dateFormat.format(activity.startTime);
      final startTime = timeFormat.format(activity.startTime);
      final endTime = activity.endTime != null
          ? timeFormat.format(activity.endTime!)
          : '';

      // 아기 이름들
      final babyNameList = activity.babyIds
          .map((id) => babyNames[id] ?? '알 수 없음')
          .join(', ');

      // 유형
      final type = _getActivityTypeLabel(activity.type);

      // 상세 정보
      final detail = _getActivityDetail(activity);

      // 양 또는 시간
      final amount = _getActivityAmount(activity);

      // 메모 (CSV 이스케이프)
      final notes = _escapeCSV(activity.notes ?? '');

      buffer.writeln('$date,$startTime,$endTime,$babyNameList,$type,$detail,$amount,$notes');
    }

    return buffer.toString();
  }

  String _getActivityTypeLabel(ActivityType type) {
    return switch (type) {
      ActivityType.feeding => '수유',
      ActivityType.sleep => '수면',
      ActivityType.diaper => '기저귀',
      ActivityType.play => '놀이',
      ActivityType.health => '건강',
    };
  }

  String _getActivityDetail(ActivityModel activity) {
    final data = activity.data;

    return switch (activity.type) {
      ActivityType.feeding => _getFeedingDetail(data),
      ActivityType.sleep => _getSleepDetail(data),
      ActivityType.diaper => _getDiaperDetail(data),
      _ => '',
    };
  }

  String _getFeedingDetail(Map<String, dynamic>? data) {
    if (data == null) return '';

    final type = data['feeding_type'] as String? ?? '';
    final typeLabel = switch (type) {
      'breast' => '모유',
      'bottle' => '젖병',
      'formula' => '분유',
      'solid' => '이유식',
      _ => type,
    };

    // 모유 수유 좌/우
    final side = data['breast_side'] as String?;
    if (side != null && type == 'breast') {
      final sideLabel = switch (side) {
        'left' => '왼쪽',
        'right' => '오른쪽',
        'both' => '양쪽',
        _ => side,
      };
      return '$typeLabel ($sideLabel)';
    }

    return typeLabel;
  }

  String _getSleepDetail(Map<String, dynamic>? data) {
    if (data == null) return '';

    final type = data['sleep_type'] as String? ?? '';
    return switch (type) {
      'nap' => '낮잠',
      'night' => '밤잠',
      _ => type,
    };
  }

  String _getDiaperDetail(Map<String, dynamic>? data) {
    if (data == null) return '';

    final type = data['diaper_type'] as String? ?? '';
    return switch (type) {
      'wet' => '소변',
      'dirty' => '대변',
      'both' => '소변+대변',
      'dry' => '깨끗함',
      _ => type,
    };
  }

  String _getActivityAmount(ActivityModel activity) {
    final data = activity.data;

    return switch (activity.type) {
      ActivityType.feeding => _getFeedingAmount(data),
      ActivityType.sleep => _getSleepDuration(activity),
      _ => '',
    };
  }

  String _getFeedingAmount(Map<String, dynamic>? data) {
    if (data == null) return '';

    // 모유 수유 시간
    final duration = data['duration_minutes'] as int?;
    if (duration != null && duration > 0) {
      return '$duration분';
    }

    // 수유량
    final amount = data['amount_ml'] as num?;
    if (amount != null && amount > 0) {
      return '${amount.toInt()}ml';
    }

    return '';
  }

  /// 수면 시간 (자정 넘김 처리 포함 - QA-01)
  String _getSleepDuration(ActivityModel activity) {
    if (activity.endTime == null) return '진행중';

    // durationMinutes getter 사용 (자정 넘김 처리 포함)
    final totalMins = activity.durationMinutes ?? 0;
    final hours = totalMins ~/ 60;
    final minutes = totalMins % 60;

    if (hours == 0) return '$minutes분';
    if (minutes == 0) return '$hours시간';
    return '$hours시간 $minutes분';
  }

  String _escapeCSV(String value) {
    // CSV 특수문자 처리
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  String _generateFileName(DateTimeRange? dateRange) {
    final now = DateTime.now();
    final dateFormat = DateFormat('yyyyMMdd');

    if (dateRange != null) {
      final start = dateFormat.format(dateRange.start);
      final end = dateFormat.format(dateRange.end);
      return 'lulu_records_${start}_$end.csv';
    }

    final nowFormatted = dateFormat.format(now);
    return 'lulu_records_$nowFormatted.csv';
  }

  Future<File> _saveToFile(String content, String fileName) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$fileName');

    // BOM 추가 (Excel 한글 호환)
    final bom = '\uFEFF';
    await file.writeAsString(bom + content);

    return file;
  }
}
