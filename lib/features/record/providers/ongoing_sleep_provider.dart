import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../core/utils/sleep_classifier.dart';
import '../../../data/models/activity_model.dart';
import '../../../data/models/baby_type.dart';
import '../../../data/repositories/activity_repository.dart';
import '../../../l10n/generated/app_localizations.dart' show S;

/// 진행 중인 수면 기록 관리 Provider
///
/// QA-03: 수면 시작 후 종료할 수 있는 기능 제공
/// - 홈 화면에서 진행 중 수면 카드 표시
/// - 수면 화면에서 진행 중 섹션 표시
/// - 앱 재시작 후에도 상태 유지
/// BUG-DATA-01 FIX: Supabase(ActivityRepository)로 데이터 저장
class OngoingSleepProvider extends ChangeNotifier {
  static const String _storageKey = 'ongoing_sleep_v1';
  final ActivityRepository _activityRepository = ActivityRepository();
  final Uuid _uuid = const Uuid();

  Timer? _timer;
  OngoingSleepRecord? _ongoingSleep;

  /// DB-sourced ongoing sleep: true if current ongoing sleep was found from DB
  /// (not started via FAB). Affects endSleep() behavior.
  bool _isDbSourced = false;

  /// 진행 중인 수면 기록
  OngoingSleepRecord? get ongoingSleep => _ongoingSleep;

  /// 진행 중인 수면 여부
  bool get hasSleepInProgress => _ongoingSleep != null;

  /// 현재 수면 중인 아기 ID
  String? get currentBabyId => _ongoingSleep?.babyId;

  /// 수면 시작 시간
  DateTime? get sleepStartTime => _ongoingSleep?.startTime;

  /// 경과 시간
  Duration get elapsedTime {
    if (_ongoingSleep == null) return Duration.zero;
    return DateTime.now().difference(_ongoingSleep!.startTime);
  }

  /// 포맷된 경과 시간 문자열 (i18n 지원)
  String localizedElapsedTime(S? l10n) {
    final d = elapsedTime;
    if (d.inHours > 0) {
      return l10n?.ongoingSleepElapsedHoursMinutes(
            d.inHours, d.inMinutes.remainder(60)) ??
          '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    }
    return l10n?.ongoingSleepElapsedMinutes(d.inMinutes) ??
        '${d.inMinutes}m';
  }

  /// 포맷된 경과 시간 문자열
  String get formattedElapsedTime => localizedElapsedTime(null);

  /// 초기화 - 앱 시작 시 호출
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString != null && jsonString.isNotEmpty) {
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        _ongoingSleep = OngoingSleepRecord.fromJson(json);
        _isDbSourced = false;
        _startTimer();
        debugPrint('[OK] [OngoingSleepProvider] Restored ongoing sleep from SharedPrefs: ${_ongoingSleep?.babyId}');
      }
    } catch (e) {
      debugPrint('[ERR] [OngoingSleepProvider] Init error: $e');
      // 오류 시 상태 초기화
      _ongoingSleep = null;
    }
    notifyListeners();
  }

  /// HF-5: DB에서 활성 수면 조회 (BabyTime import 등 외부 경로 감지)
  /// baby 선택 시 + 홈 화면 진입 시 + 포그라운드 복귀 시 호출
  ///
  /// FIX-4: DB에 active sleep 없으면 SharedPrefs도 정리하여 stale 상태 방지.
  /// 이전: _isDbSourced인 경우만 정리 → SharedPrefs 기반 stale 상태 잔존.
  /// 이후: DB에 없으면 무조건 정리 (DB = single source of truth).
  Future<void> checkDbForActiveSleep(String babyId, String familyId) async {
    try {
      final activeSleep = await _activityRepository.getActiveSleepForBaby(babyId);

      if (activeSleep != null) {
        // DB에 활성 수면 발견 — OngoingSleepRecord로 변환
        // C-0.4 fallback: classify if sleep_type is NULL (legacy records)
        final sleepType = SleepClassifier.effectiveSleepType(activeSleep);
        _ongoingSleep = OngoingSleepRecord(
          id: activeSleep.id,
          babyId: babyId,
          familyId: activeSleep.familyId,
          sleepType: sleepType,
          startTime: activeSleep.startTime,
        );
        _isDbSourced = true;
        _startTimer();
        debugPrint('[OK] [OngoingSleepProvider] Found active sleep from DB: '
            'id=${activeSleep.id}, startTime=${activeSleep.startTime}');
      } else if (_ongoingSleep != null && _ongoingSleep!.babyId == babyId) {
        // FIX-4: DB has no active sleep for this baby — clear all local state
        // Covers both DB-sourced and SharedPrefs-sourced stale records
        _ongoingSleep = null;
        _isDbSourced = false;
        _stopTimer();
        await _clearLocal();
        debugPrint('[INFO] [OngoingSleepProvider] No active sleep in DB for baby: $babyId — cleared local state');
      }
      notifyListeners();
    } catch (e) {
      debugPrint('[ERR] [OngoingSleepProvider] checkDbForActiveSleep error: $e');
    }
  }

  /// 수면 시작
  /// Sprint 20 HF #9: hasSleepInProgress 확인은 UI에서 처리 (확인 다이얼로그)
  /// 같은 아기 수면 중복 시 UI에서 endAndStartSleep() 호출
  Future<void> startSleep({
    required String babyId,
    required String familyId,
    String sleepType = 'nap',
    String? babyName,
    DateTime? startTime,
  }) async {
    // 이미 진행 중인 수면이 있으면 UI에서 처리해야 함
    if (_ongoingSleep != null) {
      debugPrint('[WARN] [OngoingSleepProvider] Sleep already in progress. Use endAndStartSleep() instead.');
      return;
    }

    _ongoingSleep = OngoingSleepRecord(
      id: _uuid.v4(),
      babyId: babyId,
      familyId: familyId,
      babyName: babyName,
      sleepType: sleepType,
      startTime: startTime ?? DateTime.now(),
    );
    _isDbSourced = false;

    await _saveToLocal();
    _startTimer();
    notifyListeners();

    debugPrint('[OK] [OngoingSleepProvider] Sleep started for baby: $babyId');
  }

  /// 수면 종료 및 저장
  /// HF-5: DB-sourced sleep → finishActivity (UPDATE end_time)
  ///        FAB-started sleep → createActivity (INSERT new record)
  /// HF-2b: Reclassify sleep_type at end time with endTime for
  ///         midnight-crossing detection (startTime-only classification
  ///         misses 20:xx→02:xx overnight sleeps)
  Future<ActivityModel?> endSleep() async {
    if (_ongoingSleep == null) {
      debugPrint('[WARN] [OngoingSleepProvider] No ongoing sleep to end');
      return null;
    }

    try {
      final endTime = DateTime.now();

      // HF-2b: Reclassify with endTime for midnight-crossing detection
      final reclassifiedType = await _reclassifySleepType(
        startTime: _ongoingSleep!.startTime,
        endTime: endTime,
        babyId: _ongoingSleep!.babyId,
        familyId: _ongoingSleep!.familyId,
      );

      if (reclassifiedType != _ongoingSleep!.sleepType) {
        debugPrint('[INFO] [OngoingSleepProvider] Sleep reclassified at end: '
            '${_ongoingSleep!.sleepType} -> $reclassifiedType');
      }

      ActivityModel savedActivity;

      if (_isDbSourced) {
        // DB-sourced: UPDATE existing record with end_time
        savedActivity = await _activityRepository.finishActivity(
          _ongoingSleep!.id,
          endTime,
        );
        // B2: Also update sleep_type if reclassified
        await _activityRepository.updateSleepType(
          _ongoingSleep!.id,
          reclassifiedType,
        );
        debugPrint('[OK] [OngoingSleepProvider] DB-sourced sleep finished: ${savedActivity.id}');
      } else {
        // FAB-started: INSERT new record with reclassified type
        final activity = ActivityModel(
          id: _ongoingSleep!.id,
          familyId: _ongoingSleep!.familyId,
          babyIds: [_ongoingSleep!.babyId],
          type: ActivityType.sleep,
          startTime: _ongoingSleep!.startTime,
          endTime: endTime,
          data: {'sleep_type': reclassifiedType},
          createdAt: _ongoingSleep!.startTime,
        );
        savedActivity = await _activityRepository.createActivity(activity);
        debugPrint('[OK] [OngoingSleepProvider] FAB sleep ended and saved: ${savedActivity.id}');
      }

      // 로컬 상태 초기화
      _ongoingSleep = null;
      _isDbSourced = false;
      _stopTimer();
      await _clearLocal();
      notifyListeners();

      return savedActivity;
    } catch (e) {
      debugPrint('[ERR] [OngoingSleepProvider] Error ending sleep: $e');
      rethrow;
    }
  }

  /// Sprint 20 HF #9-B: 이전 수면 종료 + 새 수면 시작 (확인 다이얼로그 후 호출)
  /// 반환값: 종료된 이전 수면 ActivityModel (HomeProvider 갱신용)
  Future<ActivityModel?> endAndStartSleep({
    required String babyId,
    required String familyId,
    String sleepType = 'nap',
    String? babyName,
    DateTime? startTime,
  }) async {
    ActivityModel? endedActivity;

    // 1. 이전 수면 종료
    if (_ongoingSleep != null) {
      try {
        endedActivity = await endSleep();
      } catch (e) {
        debugPrint('[WARN] [OngoingSleepProvider] endAndStartSleep - end failed: $e');
        _ongoingSleep = null;
        _stopTimer();
        await _clearLocal();
      }
    }

    // 2. 새 수면 시작
    await startSleep(
      babyId: babyId,
      familyId: familyId,
      sleepType: sleepType,
      babyName: babyName,
      startTime: startTime,
    );

    return endedActivity;
  }

  /// 수면 취소 (저장하지 않고 삭제)
  Future<void> cancelSleep() async {
    if (_ongoingSleep == null) return;

    _ongoingSleep = null;
    _isDbSourced = false;
    _stopTimer();
    await _clearLocal();
    notifyListeners();

    debugPrint('[OK] [OngoingSleepProvider] Sleep cancelled');
  }

  /// 타이머 시작 (매 분 UI 갱신)
  void _startTimer() {
    _stopTimer();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      notifyListeners();
    });
  }

  /// 타이머 중지
  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  /// HF-2b: Reclassify sleep type at end time with endTime
  /// Fetches recent sleep records for pattern-based classification.
  /// Falls back to cold start (with midnight-crossing) on error.
  Future<String> _reclassifySleepType({
    required DateTime startTime,
    required DateTime endTime,
    required String babyId,
    required String familyId,
  }) async {
    try {
      final recentRecords = await _activityRepository.getActivitiesByDateRange(
        familyId,
        startDate: DateTime.now().subtract(
          Duration(days: SleepClassifier.lookbackDays + 1),
        ),
        endDate: DateTime.now(),
        babyId: babyId,
        type: ActivityType.sleep,
      );

      return SleepClassifier.classify(
        startTime: startTime,
        endTime: endTime,
        recentSleepRecords: recentRecords,
      );
    } catch (e) {
      debugPrint('[WARN] [OngoingSleepProvider] Reclassify failed, using cold start: $e');
      return SleepClassifier.classify(
        startTime: startTime,
        endTime: endTime,
        recentSleepRecords: const [],
      );
    }
  }

  /// 로컬 저장소에 저장
  Future<void> _saveToLocal() async {
    if (_ongoingSleep == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(_ongoingSleep!.toJson());
      await prefs.setString(_storageKey, jsonString);
    } catch (e) {
      debugPrint('[ERR] [OngoingSleepProvider] Save error: $e');
    }
  }

  /// 로컬 저장소 초기화
  Future<void> _clearLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (e) {
      debugPrint('[ERR] [OngoingSleepProvider] Clear error: $e');
    }
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }
}

/// 진행 중인 수면 기록 데이터 클래스
class OngoingSleepRecord {
  final String id;
  final String babyId;
  final String familyId;
  final String? babyName;
  final String sleepType;
  final DateTime startTime;

  const OngoingSleepRecord({
    required this.id,
    required this.babyId,
    required this.familyId,
    this.babyName,
    required this.sleepType,
    required this.startTime,
  });

  factory OngoingSleepRecord.fromJson(Map<String, dynamic> json) {
    return OngoingSleepRecord(
      id: json['id'] as String,
      babyId: json['baby_id'] as String,
      familyId: json['family_id'] as String,
      babyName: json['baby_name'] as String?,
      sleepType: json['sleep_type'] as String? ?? 'nap',
      // FIX: Sprint 19 H-UTC1: .toLocal() added
      startTime: DateTime.parse(json['start_time'] as String).toLocal(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'baby_id': babyId,
      'family_id': familyId,
      if (babyName != null) 'baby_name': babyName,
      'sleep_type': sleepType,
      'start_time': startTime.toIso8601String(),
    };
  }
}
