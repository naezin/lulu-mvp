import 'package:flutter/foundation.dart';
import '../../../data/models/models.dart';

/// 홈 화면 상태 관리 Provider
///
/// 다태아 지원:
/// - 선택된 아기 관리 (null = 모두)
/// - Sweet Spot 계산
/// - 오늘 활동 요약
class HomeProvider extends ChangeNotifier {
  // ========================================
  // 상태
  // ========================================

  /// 현재 가족
  FamilyModel? _family;
  FamilyModel? get family => _family;

  /// 현재 가족의 아기들
  List<BabyModel> _babies = [];
  List<BabyModel> get babies => List.unmodifiable(_babies);

  /// 선택된 아기 ID (null = 모두)
  String? _selectedBabyId;
  String? get selectedBabyId => _selectedBabyId;

  /// 선택된 아기 (null이면 첫번째 아기)
  BabyModel? get selectedBaby {
    if (_selectedBabyId == null && _babies.isNotEmpty) {
      return _babies.first;
    }
    return _babies.where((b) => b.id == _selectedBabyId).firstOrNull;
  }

  /// 모든 아기 선택 여부
  bool get isAllSelected => _selectedBabyId == null;

  /// 오늘 활동들
  List<ActivityModel> _todayActivities = [];
  List<ActivityModel> get todayActivities => List.unmodifiable(_todayActivities);

  /// 로딩 상태
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// 에러 메시지
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // ========================================
  // Sweet Spot 관련
  // ========================================

  /// Sweet Spot 상태
  SweetSpotState _sweetSpotState = SweetSpotState.unknown;
  SweetSpotState get sweetSpotState => _sweetSpotState;

  /// Sweet Spot까지 남은 분
  int _minutesUntilSweetSpot = 0;
  int get minutesUntilSweetSpot => _minutesUntilSweetSpot;

  /// 추천 수면 시간
  DateTime? _recommendedSleepTime;
  DateTime? get recommendedSleepTime => _recommendedSleepTime;

  /// Sweet Spot 진행률 (0.0 ~ 1.0)
  double get sweetSpotProgress {
    if (_sweetSpotState == SweetSpotState.unknown) return 0.0;
    // 간단한 계산: 마지막 수면 후 경과 시간 / 권장 활동 시간
    return 0.6; // 임시값
  }

  // ========================================
  // 오늘 요약
  // ========================================

  /// 오늘 수유 횟수
  int get todayFeedingCount {
    return _todayActivities.where((a) => a.type == ActivityType.feeding).length;
  }

  /// 오늘 총 수면 시간 (분)
  int get todaySleepMinutes {
    final sleepActivities = _todayActivities.where(
      (a) => a.type == ActivityType.sleep && a.endTime != null,
    );

    int totalMinutes = 0;
    for (final activity in sleepActivities) {
      totalMinutes += activity.endTime!.difference(activity.startTime).inMinutes;
    }
    return totalMinutes;
  }

  /// 오늘 수면 시간 문자열 (예: "8h 30m")
  String get todaySleepDuration {
    final hours = todaySleepMinutes ~/ 60;
    final minutes = todaySleepMinutes % 60;
    if (hours == 0) return '${minutes}m';
    if (minutes == 0) return '${hours}h';
    return '${hours}h ${minutes}m';
  }

  /// 오늘 기저귀 횟수
  int get todayDiaperCount {
    return _todayActivities.where((a) => a.type == ActivityType.diaper).length;
  }

  /// 마지막 수유 활동
  ActivityModel? get lastFeeding {
    final feedings = _todayActivities
        .where((a) => a.type == ActivityType.feeding)
        .toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
    return feedings.firstOrNull;
  }

  /// 마지막 수면 활동
  ActivityModel? get lastSleep {
    final sleeps = _todayActivities
        .where((a) => a.type == ActivityType.sleep)
        .toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
    return sleeps.firstOrNull;
  }

  // ========================================
  // 메서드
  // ========================================

  /// 가족 및 아기 목록 설정 (BUG-001 fix)
  void setFamily(FamilyModel family, List<BabyModel> babies) {
    _family = family;
    _babies = babies;
    if (_selectedBabyId != null && !babies.any((b) => b.id == _selectedBabyId)) {
      _selectedBabyId = null;
    }
    if (_babies.isNotEmpty && _selectedBabyId == null) {
      _selectedBabyId = _babies.first.id;
    }
    debugPrint('✅ [HomeProvider] Family set: ${family.id}, babies: ${babies.map((b) => b.name).join(", ")}');
    notifyListeners();
  }

  /// 아기 목록 설정 (하위 호환성)
  void setBabies(List<BabyModel> babies) {
    _babies = babies;
    if (_selectedBabyId != null && !babies.any((b) => b.id == _selectedBabyId)) {
      _selectedBabyId = null;
    }
    notifyListeners();
  }

  /// 아기 선택
  void selectBaby(String? babyId) {
    _selectedBabyId = babyId;
    _calculateSweetSpot();
    notifyListeners();
  }

  /// 오늘 활동 설정
  void setTodayActivities(List<ActivityModel> activities) {
    _todayActivities = activities;
    _calculateSweetSpot();
    notifyListeners();
  }

  /// 활동 추가
  void addActivity(ActivityModel activity) {
    _todayActivities = [..._todayActivities, activity];
    _calculateSweetSpot();
    notifyListeners();
  }

  /// Sweet Spot 계산
  void _calculateSweetSpot() {
    final baby = selectedBaby;
    if (baby == null) {
      _sweetSpotState = SweetSpotState.unknown;
      return;
    }

    // 마지막 수면 시간 확인
    final lastSleepActivity = lastSleep;
    if (lastSleepActivity == null) {
      _sweetSpotState = SweetSpotState.unknown;
      return;
    }

    // 적용할 연령 (교정연령 또는 실제연령)
    final ageInMonths = baby.effectiveAgeInMonths;

    // 연령별 권장 활동 시간 (분)
    final recommendedAwakeTime = _getRecommendedAwakeTime(ageInMonths);

    // 마지막 수면 종료 시간
    final lastWakeTime = lastSleepActivity.endTime ?? lastSleepActivity.startTime;

    // 경과 시간
    final elapsedMinutes = DateTime.now().difference(lastWakeTime).inMinutes;

    // Sweet Spot 계산
    _minutesUntilSweetSpot = recommendedAwakeTime - elapsedMinutes;
    _recommendedSleepTime = lastWakeTime.add(Duration(minutes: recommendedAwakeTime));

    // 상태 결정
    if (_minutesUntilSweetSpot > 30) {
      _sweetSpotState = SweetSpotState.tooEarly;
    } else if (_minutesUntilSweetSpot > 0) {
      _sweetSpotState = SweetSpotState.approaching;
    } else if (_minutesUntilSweetSpot > -15) {
      _sweetSpotState = SweetSpotState.optimal;
    } else {
      _sweetSpotState = SweetSpotState.overtired;
    }
  }

  /// 연령별 권장 활동 시간 (분)
  int _getRecommendedAwakeTime(int ageInMonths) {
    // 연령별 권장 활동 시간 (교정연령 기준)
    if (ageInMonths < 1) return 45; // 신생아: 45분
    if (ageInMonths < 2) return 60; // 1개월: 1시간
    if (ageInMonths < 3) return 75; // 2개월: 1시간 15분
    if (ageInMonths < 4) return 90; // 3개월: 1시간 30분
    if (ageInMonths < 6) return 120; // 4-5개월: 2시간
    if (ageInMonths < 9) return 150; // 6-8개월: 2시간 30분
    if (ageInMonths < 12) return 180; // 9-11개월: 3시간
    return 210; // 12개월+: 3시간 30분
  }

  /// 데이터 새로고침
  Future<void> refresh() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // TODO: 실제 데이터 로딩 구현
      await Future.delayed(const Duration(milliseconds: 500));

      _calculateSweetSpot();
    } catch (e) {
      _errorMessage = '데이터를 불러오는데 실패했습니다: $e';
      debugPrint('❌ [HomeProvider] Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 테스트용 더미 데이터 초기화
  /// TODO: 실제 구현 시 온보딩 완료 후 Supabase에서 데이터 로드
  void initializeWithDummyData() {
    final now = DateTime.now();

    _babies = [
      BabyModel(
        id: 'baby-1',
        familyId: 'family-1',
        name: '서준이',
        birthDate: now.subtract(const Duration(days: 60)),
        gender: Gender.male,
        gestationalWeeksAtBirth: 34,
        birthWeightGrams: 2100,
        multipleBirthType: BabyType.twin,
        birthOrder: 1,
        createdAt: now,
      ),
      BabyModel(
        id: 'baby-2',
        familyId: 'family-1',
        name: '서윤이',
        birthDate: now.subtract(const Duration(days: 60)),
        gender: Gender.female,
        gestationalWeeksAtBirth: 34,
        birthWeightGrams: 1950,
        multipleBirthType: BabyType.twin,
        birthOrder: 2,
        createdAt: now,
      ),
    ];

    _selectedBabyId = _babies.first.id;
    notifyListeners();
  }

  /// 상태 초기화
  void reset() {
    _family = null;
    _babies = [];
    _selectedBabyId = null;
    _todayActivities = [];
    _sweetSpotState = SweetSpotState.unknown;
    _minutesUntilSweetSpot = 0;
    _recommendedSleepTime = null;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}

/// Sweet Spot 상태
enum SweetSpotState {
  /// 알 수 없음
  unknown,

  /// 아직 피곤하지 않음
  tooEarly,

  /// 곧 적정 시간에 접근
  approaching,

  /// 지금이 최적 시간
  optimal,

  /// 과로 상태
  overtired,
}

extension SweetSpotStateExtension on SweetSpotState {
  String get label {
    return switch (this) {
      SweetSpotState.unknown => '확인 중',
      SweetSpotState.tooEarly => '아직 일찍',
      SweetSpotState.approaching => '곧 수면 시간',
      SweetSpotState.optimal => '지금이 최적!',
      SweetSpotState.overtired => '과로 상태',
    };
  }

  String get emoji {
    return switch (this) {
      SweetSpotState.unknown => '❓',
      SweetSpotState.tooEarly => '😊',
      SweetSpotState.approaching => '😴',
      SweetSpotState.optimal => '🌙',
      SweetSpotState.overtired => '😫',
    };
  }
}
