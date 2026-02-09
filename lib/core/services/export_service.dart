import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

import '../../data/models/models.dart';
import '../../data/repositories/activity_repository.dart';
import '../../l10n/generated/app_localizations.dart' show S;

/// 내보내기 기간 옵션
enum ExportPeriod {
  today,
  week,
  month,
  all;

  /// i18n 기반 로컬라이즈된 라벨 반환
  String localizedLabel(S l10n) {
    return switch (this) {
      ExportPeriod.today => l10n.exportPeriodToday,
      ExportPeriod.week => l10n.exportPeriodWeek,
      ExportPeriod.month => l10n.exportPeriodMonth,
      ExportPeriod.all => l10n.exportPeriodAll,
    };
  }

  /// 기간에 해당하는 DateTimeRange 반환
  DateTimeRange? get dateRange {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return switch (this) {
      ExportPeriod.today => DateTimeRange(
          start: today,
          end: today.add(const Duration(days: 1)),
        ),
      ExportPeriod.week => DateTimeRange(
          start: today.subtract(const Duration(days: 6)),
          end: today.add(const Duration(days: 1)),
        ),
      ExportPeriod.month => DateTimeRange(
          start: today.subtract(const Duration(days: 29)),
          end: today.add(const Duration(days: 1)),
        ),
      ExportPeriod.all => null,
    };
  }
}

/// 활동 기록 내보내기 서비스
///
/// 지원 형식:
/// - CSV: 기본 형식, 모든 스프레드시트 앱에서 열 수 있음
///
/// 날짜 범위 선택 지원:
/// - 오늘, 최근 7일, 최근 30일, 전체
class ExportService {
  static final ExportService _instance = ExportService._internal();
  factory ExportService() => _instance;
  ExportService._internal();

  static ExportService get instance => _instance;

  final ActivityRepository _activityRepository = ActivityRepository();

  /// 날짜 범위로 활동 조회 후 CSV 내보내기
  ///
  /// [familyId] 가족 ID
  /// [babies] 아기 정보 (이름 표시용)
  /// [period] 내보내기 기간
  /// [l10n] 로컬라이제이션 객체
  /// [babyId] 특정 아기만 내보내기 (null이면 전체)
  Future<int> exportByPeriod({
    required String familyId,
    required List<BabyModel> babies,
    required ExportPeriod period,
    required S l10n,
    String? babyId,
  }) async {
    try {
      List<ActivityModel> activities;

      if (period == ExportPeriod.all) {
        // 전체 기간
        activities = await _activityRepository.getActivitiesByFamilyId(
          familyId,
          limit: 10000,
        );
      } else {
        // 특정 기간
        final range = period.dateRange!;
        activities = await _activityRepository.getActivitiesByDateRange(
          familyId,
          startDate: range.start,
          endDate: range.end,
          babyId: babyId,
        );
      }

      // 특정 아기 필터링
      if (babyId != null) {
        activities = activities
            .where((a) => a.babyIds.contains(babyId))
            .toList();
      }

      if (activities.isEmpty) {
        return 0;
      }

      // 날짜순 정렬
      activities.sort((a, b) => b.startTime.compareTo(a.startTime));

      await exportToCSV(
        activities: activities,
        babies: babies,
        dateRange: period.dateRange,
        l10n: l10n,
      );

      return activities.length;
    } catch (e) {
      debugPrint('Export by period error: $e');
      rethrow;
    }
  }

  /// 활동 기록을 CSV로 내보내기
  ///
  /// [activities] 내보낼 활동 목록
  /// [babies] 아기 정보 (이름 표시용)
  /// [dateRange] 날짜 범위 (파일명용)
  /// [l10n] 로컬라이제이션 객체
  Future<void> exportToCSV({
    required List<ActivityModel> activities,
    required List<BabyModel> babies,
    required S l10n,
    DateTimeRange? dateRange,
  }) async {
    try {
      final csv = _generateCSV(activities, babies, l10n);
      final fileName = _generateFileName(dateRange);
      final file = await _saveToFile(csv, fileName);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: l10n.exportEmailSubject,
        text: l10n.exportEmailBody,
      );

      debugPrint('CSV exported: ${file.path}');
    } catch (e) {
      debugPrint('Export error: $e');
      rethrow;
    }
  }

  /// CSV 문자열 생성
  String _generateCSV(
    List<ActivityModel> activities,
    List<BabyModel> babies,
    S l10n,
  ) {
    final buffer = StringBuffer();
    final dateFormat = DateFormat('yyyy-MM-dd');
    final timeFormat = DateFormat('HH:mm');

    // 아기 이름 맵
    final babyNames = {for (final baby in babies) baby.id: baby.name};

    // 헤더
    buffer.writeln(
      '${l10n.csvHeaderDate},${l10n.csvHeaderTime},${l10n.csvHeaderEndTime},'
      '${l10n.csvHeaderBaby},${l10n.csvHeaderType},${l10n.csvHeaderDetail},'
      '${l10n.csvHeaderAmountDuration},${l10n.csvHeaderNotes}',
    );

    // 데이터 행
    for (final activity in activities) {
      final date = dateFormat.format(activity.startTime);
      final startTime = timeFormat.format(activity.startTime);
      final endTime = activity.endTime != null
          ? timeFormat.format(activity.endTime!)
          : '';

      // 아기 이름들
      final babyNameList = activity.babyIds
          .map((id) => babyNames[id] ?? l10n.unknownBaby)
          .join(', ');

      // 유형
      final type = _getActivityTypeLabel(activity.type, l10n);

      // 상세 정보
      final detail = _getActivityDetail(activity, l10n);

      // 양 또는 시간
      final amount = _getActivityAmount(activity, l10n);

      // 메모 (CSV 이스케이프)
      final notes = _escapeCSV(activity.notes ?? '');

      buffer.writeln('$date,$startTime,$endTime,$babyNameList,$type,$detail,$amount,$notes');
    }

    return buffer.toString();
  }

  String _getActivityTypeLabel(ActivityType type, S l10n) {
    return switch (type) {
      ActivityType.feeding => l10n.activityTypeFeeding,
      ActivityType.sleep => l10n.activityTypeSleep,
      ActivityType.diaper => l10n.activityTypeDiaper,
      ActivityType.play => l10n.activityTypePlay,
      ActivityType.health => l10n.activityTypeHealth,
    };
  }

  String _getActivityDetail(ActivityModel activity, S l10n) {
    final data = activity.data;

    return switch (activity.type) {
      ActivityType.feeding => _getFeedingDetail(data, l10n),
      ActivityType.sleep => _getSleepDetail(data, l10n),
      ActivityType.diaper => _getDiaperDetail(data, l10n),
      _ => '',
    };
  }

  String _getFeedingDetail(Map<String, dynamic>? data, S l10n) {
    if (data == null) return '';

    final type = data['feeding_type'] as String? ?? '';
    final typeLabel = switch (type) {
      'breast' => l10n.feedingTypeBreast,
      'bottle' => l10n.feedingTypeBottle,
      'formula' => l10n.feedingTypeFormula,
      'solid' => l10n.feedingTypeSolid,
      _ => type,
    };

    // 모유 수유 좌/우
    final side = data['breast_side'] as String?;
    if (side != null && type == 'breast') {
      final sideLabel = switch (side) {
        'left' => l10n.breastSideLeft,
        'right' => l10n.breastSideRight,
        'both' => l10n.breastSideBoth,
        _ => side,
      };
      return '$typeLabel ($sideLabel)';
    }

    return typeLabel;
  }

  String _getSleepDetail(Map<String, dynamic>? data, S l10n) {
    if (data == null) return '';

    final type = data['sleep_type'] as String? ?? '';
    return switch (type) {
      'nap' => l10n.sleepTypeNap,
      'night' => l10n.sleepTypeNight,
      _ => type,
    };
  }

  String _getDiaperDetail(Map<String, dynamic>? data, S l10n) {
    if (data == null) return '';

    final type = data['diaper_type'] as String? ?? '';
    return switch (type) {
      'wet' => l10n.diaperTypeWet,
      'dirty' => l10n.diaperTypeDirty,
      'both' => l10n.diaperTypeBothDetail,
      'dry' => l10n.diaperTypeClean,
      _ => type,
    };
  }

  String _getActivityAmount(ActivityModel activity, S l10n) {
    final data = activity.data;

    return switch (activity.type) {
      ActivityType.feeding => _getFeedingAmount(data, l10n),
      ActivityType.sleep => _getSleepDuration(activity, l10n),
      _ => '',
    };
  }

  String _getFeedingAmount(Map<String, dynamic>? data, S l10n) {
    if (data == null) return '';

    // 모유 수유 시간
    final duration = data['duration_minutes'] as int?;
    if (duration != null && duration > 0) {
      return l10n.durationMinutes(duration);
    }

    // 수유량
    final amount = data['amount_ml'] as num?;
    if (amount != null && amount > 0) {
      return '${amount.toInt()}ml';
    }

    return '';
  }

  /// 수면 시간 (자정 넘김 처리 포함 - QA-01)
  String _getSleepDuration(ActivityModel activity, S l10n) {
    if (activity.endTime == null) return l10n.statusInProgress;

    // durationMinutes getter 사용 (자정 넘김 처리 포함)
    final totalMins = activity.durationMinutes ?? 0;
    final hours = totalMins ~/ 60;
    final minutes = totalMins % 60;

    if (hours == 0) return l10n.durationMinutes(minutes);
    if (minutes == 0) return l10n.durationHours(hours);
    return l10n.durationHoursMinutes(hours, minutes);
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
