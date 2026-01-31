import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../core/services/local_activity_service.dart';
import '../../../data/models/activity_model.dart';
import '../../../data/models/baby_type.dart';

/// 진행 중인 수면 기록 관리 Provider
///
/// QA-03: 수면 시작 후 종료할 수 있는 기능 제공
/// - 홈 화면에서 진행 중 수면 카드 표시
/// - 수면 화면에서 진행 중 섹션 표시
/// - 앱 재시작 후에도 상태 유지
class OngoingSleepProvider extends ChangeNotifier {
  static const String _storageKey = 'ongoing_sleep_v1';
  final LocalActivityService _activityService = LocalActivityService.instance;
  final Uuid _uuid = const Uuid();

  Timer? _timer;
  OngoingSleepRecord? _ongoingSleep;

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

  /// 포맷된 경과 시간 문자열
  String get formattedElapsedTime {
    final d = elapsedTime;
    if (d.inHours > 0) {
      return '${d.inHours}시간 ${d.inMinutes.remainder(60)}분';
    }
    return '${d.inMinutes}분';
  }

  /// 초기화 - 앱 시작 시 호출
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString != null && jsonString.isNotEmpty) {
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        _ongoingSleep = OngoingSleepRecord.fromJson(json);
        _startTimer();
        debugPrint('[OK] [OngoingSleepProvider] Restored ongoing sleep: ${_ongoingSleep?.babyId}');
      }
    } catch (e) {
      debugPrint('❌ [OngoingSleepProvider] Init error: $e');
      // 오류 시 상태 초기화
      _ongoingSleep = null;
    }
    notifyListeners();
  }

  /// 수면 시작
  Future<void> startSleep({
    required String babyId,
    required String familyId,
    String sleepType = 'nap',
    String? babyName,
  }) async {
    // 이미 진행 중인 수면이 있으면 무시
    if (_ongoingSleep != null) {
      debugPrint('[WARN] [OngoingSleepProvider] Sleep already in progress');
      return;
    }

    _ongoingSleep = OngoingSleepRecord(
      id: _uuid.v4(),
      babyId: babyId,
      familyId: familyId,
      babyName: babyName,
      sleepType: sleepType,
      startTime: DateTime.now(),
    );

    await _saveToLocal();
    _startTimer();
    notifyListeners();

    debugPrint('[OK] [OngoingSleepProvider] Sleep started for baby: $babyId');
  }

  /// 수면 종료 및 저장
  Future<ActivityModel?> endSleep() async {
    if (_ongoingSleep == null) {
      debugPrint('[WARN] [OngoingSleepProvider] No ongoing sleep to end');
      return null;
    }

    try {
      final endTime = DateTime.now();

      // ActivityModel 생성 및 저장
      final activity = ActivityModel(
        id: _ongoingSleep!.id,
        familyId: _ongoingSleep!.familyId,
        babyIds: [_ongoingSleep!.babyId],
        type: ActivityType.sleep,
        startTime: _ongoingSleep!.startTime,
        endTime: endTime,
        data: {'sleep_type': _ongoingSleep!.sleepType},
        createdAt: _ongoingSleep!.startTime,
      );

      final savedActivity = await _activityService.saveActivity(activity);

      // 로컬 상태 초기화
      _ongoingSleep = null;
      _stopTimer();
      await _clearLocal();
      notifyListeners();

      debugPrint('[OK] [OngoingSleepProvider] Sleep ended and saved: ${savedActivity.id}');
      return savedActivity;
    } catch (e) {
      debugPrint('❌ [OngoingSleepProvider] Error ending sleep: $e');
      rethrow;
    }
  }

  /// 수면 취소 (저장하지 않고 삭제)
  Future<void> cancelSleep() async {
    if (_ongoingSleep == null) return;

    _ongoingSleep = null;
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

  /// 로컬 저장소에 저장
  Future<void> _saveToLocal() async {
    if (_ongoingSleep == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(_ongoingSleep!.toJson());
      await prefs.setString(_storageKey, jsonString);
    } catch (e) {
      debugPrint('❌ [OngoingSleepProvider] Save error: $e');
    }
  }

  /// 로컬 저장소 초기화
  Future<void> _clearLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (e) {
      debugPrint('❌ [OngoingSleepProvider] Clear error: $e');
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
      startTime: DateTime.parse(json['start_time'] as String),
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
