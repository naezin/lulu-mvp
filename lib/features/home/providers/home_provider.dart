import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/design_system/lulu_icons.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/activity_repository.dart';
import '../../../l10n/generated/app_localizations.dart' show S;

/// 홈 화면 상태 관리 Provider
///
/// 다태아 지원:
/// - 선택된 아기 관리 (null = 모두)
/// - Sweet Spot 계산
/// - 오늘 활동 요약
///
/// BUG-002 수정: 모든 활동 getter에서 selectedBabyId 필터링 적용
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

  /// 오늘 활동들 (전체 - 내부용)
  List<ActivityModel> _todayActivities = [];

  /// 오늘 활동들 (전체 - 외부 접근용, 하위 호환성)
  List<ActivityModel> get todayActivities => List.unmodifiable(_todayActivities);

  // ========================================
  // BUG-002 FIX: 선택된 아기별 필터링된 활동
  // ========================================

  /// 캐싱된 필터링 활동 (성능 최적화)
  List<ActivityModel>? _cachedFilteredActivities;
  String? _cachedFilterBabyId;

  /// 선택된 아기의 오늘 활동만 반환
  ///
  /// - selectedBabyId가 null이면 모든 활동 반환
  /// - selectedBabyId가 있으면 해당 아기의 활동만 필터링
  /// - 동일한 조건이면 캐시된 결과 반환 (성능 최적화)
  List<ActivityModel> get filteredTodayActivities {
    // 캐시 유효성 체크
    if (_cachedFilteredActivities != null &&
        _cachedFilterBabyId == _selectedBabyId) {
      return _cachedFilteredActivities!;
    }

    // 새로 필터링
    if (_selectedBabyId == null) {
      _cachedFilteredActivities = List.unmodifiable(_todayActivities);
    } else {
      _cachedFilteredActivities = List.unmodifiable(
        _todayActivities.where((a) => a.babyIds.contains(_selectedBabyId)).toList(),
      );
    }
    _cachedFilterBabyId = _selectedBabyId;
    return _cachedFilteredActivities!;
  }

  /// 캐시 무효화
  void _invalidateCache() {
    _cachedFilteredActivities = null;
    _cachedFilterBabyId = null;
  }

  /// 로딩 상태
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// 에러 메시지
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Sprint 19 수정 2: 전체 기록 존재 여부 (신규 유저 판별)
  bool _hasAnyRecordsEver = true; // 기본 true (깜빡임 방지)
  bool get hasAnyRecordsEver => _hasAnyRecordsEver;

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

  /// Sweet Spot 진행률 (0.0 ~ 1.2)
  double get sweetSpotProgress {
    if (_sweetSpotState == SweetSpotState.unknown) return 0.0;

    final lastSleepActivity = lastSleep;
    if (lastSleepActivity == null) return 0.0;

    final baby = selectedBaby;
    if (baby == null) return 0.0;

    final lastWakeTime = lastSleepActivity.endTime ?? lastSleepActivity.startTime;
    final recommendedAwakeTime = _getRecommendedAwakeTime(baby.effectiveAgeInMonths);
    final elapsedMinutes = DateTime.now().difference(lastWakeTime).inMinutes;

    return (elapsedMinutes / recommendedAwakeTime).clamp(0.0, 1.2);
  }

  /// 밤잠 여부 (18:00-05:59 → 밤잠)
  bool get isNightTime {
    final hour = DateTime.now().hour;
    return hour >= 18 || hour < 6;
  }

  // ========================================
  // 오늘 요약 (BUG-002 FIX: 필터링 적용)
  // ========================================

  /// 오늘 수유 횟수 (선택된 아기만)
  int get todayFeedingCount {
    return filteredTodayActivities
        .where((a) => a.type == ActivityType.feeding)
        .length;
  }

  /// 오늘 총 수면 시간 (분) - 선택된 아기만
  /// 자정을 넘기는 수면도 정확히 계산 (QA-01)
  int get todaySleepMinutes {
    final sleepActivities = filteredTodayActivities.where(
      (a) => a.type == ActivityType.sleep && a.endTime != null,
    );

    int totalMinutes = 0;
    for (final activity in sleepActivities) {
      // durationMinutes getter 사용 (자정 넘김 처리 포함)
      totalMinutes += activity.durationMinutes ?? 0;
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

  /// 오늘 기저귀 횟수 (선택된 아기만)
  int get todayDiaperCount {
    return filteredTodayActivities
        .where((a) => a.type == ActivityType.diaper)
        .length;
  }

  /// 마지막 수유 활동 (선택된 아기만)
  ActivityModel? get lastFeeding {
    final feedings = filteredTodayActivities
        .where((a) => a.type == ActivityType.feeding)
        .toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
    return feedings.firstOrNull;
  }

  /// 마지막 수면 활동 (선택된 아기만)
  ActivityModel? get lastSleep {
    final sleeps = filteredTodayActivities
        .where((a) => a.type == ActivityType.sleep)
        .toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
    return sleeps.firstOrNull;
  }

  /// 마지막 기저귀 활동 (선택된 아기만)
  ActivityModel? get lastDiaper {
    final diapers = filteredTodayActivities
        .where((a) => a.type == ActivityType.diaper)
        .toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
    return diapers.firstOrNull;
  }

  // ========================================
  // 마지막 활동 시간 (DateTime) - LastActivityRow용
  // ========================================

  /// 마지막 수면 시간 (DateTime)
  DateTime? get lastSleepTime => lastSleep?.endTime ?? lastSleep?.startTime;

  /// 마지막 수유 시간 (DateTime)
  DateTime? get lastFeedingTime => lastFeeding?.startTime;

  /// 마지막 기저귀 시간 (DateTime)
  DateTime? get lastDiaperTime => lastDiaper?.startTime;

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
    debugPrint('[OK] [HomeProvider] Family set: ${family.id}, babies: ${babies.map((b) => b.name).join(", ")}');
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
  ///
  /// BUG-002 NOTE: 아기 전환 시 filteredTodayActivities가 자동으로
  /// 새로운 selectedBabyId를 기준으로 필터링됨
  void selectBaby(String? babyId) {
    _selectedBabyId = babyId;
    _invalidateCache(); // 캐시 무효화
    _calculateSweetSpot();
    debugPrint('[OK] [HomeProvider] Baby selected: $babyId, filtered activities: ${filteredTodayActivities.length}');
    notifyListeners();
  }

  /// 오늘 활동 설정
  void setTodayActivities(List<ActivityModel> activities) {
    _todayActivities = activities;
    _invalidateCache(); // 캐시 무효화
    _calculateSweetSpot();
    debugPrint('[OK] [HomeProvider] Activities set: ${activities.length} total, ${filteredTodayActivities.length} for selected baby');
    notifyListeners();
  }

  /// 활동 추가
  void addActivity(ActivityModel activity) {
    _todayActivities = [..._todayActivities, activity];
    _invalidateCache(); // 캐시 무효화
    _calculateSweetSpot();
    debugPrint('[OK] [HomeProvider] Activity added: ${activity.type}, babyIds: ${activity.babyIds}');
    notifyListeners();
  }

  /// 활동 삭제
  void removeActivity(String activityId) {
    _todayActivities = _todayActivities
        .where((a) => a.id != activityId)
        .toList();
    _invalidateCache(); // 캐시 무효화
    _calculateSweetSpot();
    notifyListeners();
  }

  /// 활동 업데이트
  void updateActivity(ActivityModel updatedActivity) {
    _todayActivities = _todayActivities.map((a) {
      return a.id == updatedActivity.id ? updatedActivity : a;
    }).toList();
    _invalidateCache(); // 캐시 무효화
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

    // 마지막 수면 시간 확인 (BUG-002 FIX: 필터링된 활동 사용)
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
  ///
  /// QA FIX: 실제 Supabase 데이터 로딩 구현
  Future<void> refresh() async {
    if (_family == null) {
      debugPrint('[WARN] [HomeProvider] Cannot refresh: family not set');
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final activityRepo = ActivityRepository();

      // 오늘 활동 조회
      final activities = await activityRepo.getTodayActivities(_family!.id);
      _todayActivities = activities;
      _invalidateCache();

      debugPrint('[OK] [HomeProvider] Refreshed: ${activities.length} activities loaded');

      _calculateSweetSpot();
    } catch (e) {
      _errorMessage = 'Failed to load data: $e';
      debugPrint('[ERROR] [HomeProvider] Refresh error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 초기 데이터 로드 (가족 설정 후 호출)
  ///
  /// 가족과 아기 정보가 설정된 후 오늘 활동을 로드합니다.
  /// Sprint 19: hasAnyRecordsEver도 함께 체크
  Future<void> loadTodayActivities() async {
    if (_family == null) {
      debugPrint('[WARN] [HomeProvider] Cannot load activities: family not set');
      return;
    }

    try {
      final activityRepo = ActivityRepository();

      // Sprint 19 수정 2: 전체 기록 존재 여부 체크 (병렬 실행)
      final results = await Future.wait([
        activityRepo.getTodayActivities(_family!.id),
        activityRepo.hasAnyActivities(_family!.id),
      ]);

      final activities = results[0] as List<ActivityModel>;
      final hasAny = results[1] as bool;

      _todayActivities = activities;
      _hasAnyRecordsEver = hasAny;
      _invalidateCache();
      _calculateSweetSpot();

      debugPrint('[OK] [HomeProvider] Today activities loaded: ${activities.length}, hasAnyRecordsEver: $hasAny');
      notifyListeners();
    } catch (e) {
      debugPrint('[ERROR] [HomeProvider] Error loading activities: $e');
      _errorMessage = 'Failed to load activity data';
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
    _invalidateCache();
    debugPrint('[OK] [HomeProvider] Reset complete');
    notifyListeners();
  }

  // ========================================
  // BUG-009 FIX: 아기 추가 (Supabase + 로컬)
  // ========================================

  /// 아기 추가 (Supabase + 로컬)
  ///
  /// BUG-009 FIX: family 존재 확인 후 아기 추가
  Future<void> addBaby(BabyModel baby) async {
    try {
      // 1. family 존재 확인
      await _ensureFamilyExists(baby.familyId);

      // 2. Supabase에 저장
      await Supabase.instance.client
          .from('babies')
          .insert(baby.toJson());

      // 3. 로컬 상태 업데이트
      _babies = [..._babies, baby];
      if (_selectedBabyId == null) {
        _selectedBabyId = baby.id;
      }

      // family의 babyIds도 업데이트
      if (_family != null) {
        _family = _family!.copyWith(
          babyIds: [..._family!.babyIds, baby.id],
        );
      }

      _invalidateCache();
      notifyListeners();
      debugPrint('[OK] [HomeProvider] Baby added: ${baby.name}');
    } catch (e) {
      debugPrint('[ERROR] [HomeProvider] addBaby failed: $e');
      rethrow;
    }
  }

  /// 아기 삭제
  Future<void> removeBaby(String babyId) async {
    try {
      // Supabase에서 삭제
      await Supabase.instance.client
          .from('babies')
          .delete()
          .eq('id', babyId);

      // 로컬 상태 업데이트
      _babies = _babies.where((b) => b.id != babyId).toList();

      // 삭제한 아기가 선택되어 있었으면 다른 아기 선택
      if (_selectedBabyId == babyId) {
        _selectedBabyId = _babies.isNotEmpty ? _babies.first.id : null;
      }

      // family의 babyIds도 업데이트
      if (_family != null) {
        _family = _family!.copyWith(
          babyIds: _family!.babyIds.where((id) => id != babyId).toList(),
        );
      }

      _invalidateCache();
      notifyListeners();
      debugPrint('[OK] [HomeProvider] Baby removed: $babyId');
    } catch (e) {
      debugPrint('[ERROR] [HomeProvider] removeBaby failed: $e');
      rethrow;
    }
  }

  /// family가 없으면 생성 + family_members에 owner로 추가
  /// Family Sharing v3.2: family_members 테이블 사용
  Future<void> _ensureFamilyExists(String familyId) async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    // 1. families 테이블에 있는지 확인
    final existing = await supabase
        .from('families')
        .select('id')
        .eq('id', familyId)
        .maybeSingle();

    if (existing != null) {
      debugPrint('[OK] [HomeProvider] Family exists: $familyId');

      // family_members에도 있는지 확인하고 없으면 추가
      await _ensureFamilyMember(familyId, userId);
      return;
    }

    // 2. 없으면 생성
    debugPrint('[INFO] [HomeProvider] Creating family: $familyId');

    await supabase.from('families').upsert({
      'id': familyId,
      'user_id': userId,
      'created_by': userId,
      'created_at': DateTime.now().toIso8601String(),
    });

    // 3. family_members에 owner로 추가
    await supabase.from('family_members').upsert({
      'family_id': familyId,
      'user_id': userId,
      'role': 'owner',
    });

    debugPrint('[OK] [HomeProvider] Family created with owner: $familyId');
  }

  /// family_members에 사용자가 없으면 owner로 추가
  Future<void> _ensureFamilyMember(String familyId, String userId) async {
    final supabase = Supabase.instance.client;

    try {
      final memberData = await supabase
          .from('family_members')
          .select('id')
          .eq('family_id', familyId)
          .eq('user_id', userId)
          .maybeSingle();

      if (memberData == null) {
        // 멤버로 등록되어 있지 않으면 owner로 추가
        await supabase.from('family_members').insert({
          'family_id': familyId,
          'user_id': userId,
          'role': 'owner',
        });
        debugPrint('[OK] [HomeProvider] Added user to family_members as owner');
      }
    } catch (e) {
      // family_members 테이블 접근 실패 시 무시 (레거시 호환)
      debugPrint('[WARN] [HomeProvider] family_members check failed: $e');
    }
  }

  /// 가족 변경 시 호출 (Family Sharing)
  ///
  /// 새 가족에 참여하거나 가족이 변경되었을 때 호출됩니다.
  /// 가족 정보와 활동 데이터를 새로 로드합니다.
  Future<void> onFamilyChanged(String newFamilyId) async {
    debugPrint('[INFO] [HomeProvider] Family changed to: $newFamilyId');

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // TODO: Supabase에서 새 가족 정보 로드
      // final familyRepo = FamilyRepository();
      // final family = await familyRepo.getFamily(newFamilyId);
      // final babies = await familyRepo.getBabies(newFamilyId);
      // setFamily(family, babies);

      // 활동 데이터 새로 로드
      await refresh();

      debugPrint('[OK] [HomeProvider] Family data reloaded');
    } catch (e) {
      _errorMessage = 'Failed to load family data: $e';
      debugPrint('[ERROR] [HomeProvider] Family change error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
  /// 표시용 라벨 (기존 - 추후 localizedLabel로 교체)
  String get label {
    return switch (this) {
      SweetSpotState.unknown => '확인 중',
      SweetSpotState.tooEarly => '아직 일찍',
      SweetSpotState.approaching => '곧 수면 시간',
      SweetSpotState.optimal => '지금이 최적!',
      SweetSpotState.overtired => '과로 상태',
    };
  }

  /// 표시용 라벨 (i18n)
  String localizedLabel(S l10n) {
    return switch (this) {
      SweetSpotState.unknown => l10n.sweetSpotStateLabelUnknown,
      SweetSpotState.tooEarly => l10n.sweetSpotStateLabelTooEarly,
      SweetSpotState.approaching => l10n.sweetSpotStateLabelApproaching,
      SweetSpotState.optimal => l10n.sweetSpotStateLabelOptimal,
      SweetSpotState.overtired => l10n.sweetSpotStateLabelOvertired,
    };
  }

  IconData get icon {
    return switch (this) {
      SweetSpotState.unknown => LuluIcons.info,
      SweetSpotState.tooEarly => LuluIcons.sun,
      SweetSpotState.approaching => LuluIcons.sleep,
      SweetSpotState.optimal => LuluIcons.moon,
      SweetSpotState.overtired => LuluIcons.warning,
    };
  }
}
