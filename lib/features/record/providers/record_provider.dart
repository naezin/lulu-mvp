import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../data/models/models.dart';
import '../../../core/services/local_activity_service.dart';

/// 기록 화면 상태 관리 Provider
///
/// MVP-F: 단일 아기 선택만 지원 (동시 기록 제거)
/// MVP-F: 로컬 저장 모드 (Supabase 인증 없이 동작)
class RecordProvider extends ChangeNotifier {
  final LocalActivityService _localActivityService = LocalActivityService.instance;
  final Uuid _uuid = const Uuid();

  // ========================================
  // 공통 상태
  // ========================================

  /// 현재 가족 ID
  String? _familyId;
  String? get familyId => _familyId;

  /// 사용 가능한 아기들
  List<BabyModel> _babies = [];
  List<BabyModel> get babies => List.unmodifiable(_babies);

  /// 선택된 아기 ID들 (MVP-F: 단일 선택만 지원)
  List<String> _selectedBabyIds = [];
  List<String> get selectedBabyIds => List.unmodifiable(_selectedBabyIds);

  /// 선택된 단일 아기 ID
  String? get selectedBabyId => _selectedBabyIds.isNotEmpty ? _selectedBabyIds.first : null;

  /// 기록 시간
  DateTime _recordTime = DateTime.now();
  DateTime get recordTime => _recordTime;

  /// 메모
  String? _notes;
  String? get notes => _notes;

  /// 로딩 상태
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// 에러 메시지
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // ========================================
  // 수유 기록 상태
  // ========================================

  /// 수유 종류: breast, bottle, formula, solid
  String _feedingType = 'breast';
  String get feedingType => _feedingType;

  /// 수유량 (ml) - 단일 아기 또는 동일 양
  double _feedingAmount = 0;
  double get feedingAmount => _feedingAmount;

  /// 아기별 수유량 (다태아 개별 입력용)
  Map<String, double> _feedingAmountByBaby = {};
  Map<String, double> get feedingAmountByBaby =>
      Map.unmodifiable(_feedingAmountByBaby);

  /// 개별 입력 모드 여부
  bool _isIndividualAmount = false;
  bool get isIndividualAmount => _isIndividualAmount;

  /// 수유 시간 (분) - 모유 수유용
  int _feedingDuration = 0;
  int get feedingDuration => _feedingDuration;

  /// 모유 수유 좌/우 선택: left, right, both
  String _breastSide = 'left';
  String get breastSide => _breastSide;

  // ========================================
  // 이유식 기록 상태 (Sprint 8)
  // ========================================

  /// 음식 이름
  String _solidFoodName = '';
  String get solidFoodName => _solidFoodName;

  /// 처음 먹이는 음식 여부
  bool _solidIsFirstTry = false;
  bool get solidIsFirstTry => _solidIsFirstTry;

  /// 양 단위 (gram/spoon/bowl)
  String _solidUnit = 'gram';
  String get solidUnit => _solidUnit;

  /// 양
  double _solidAmount = 0;
  double get solidAmount => _solidAmount;

  /// 아기 반응 (liked/neutral/rejected)
  String? _solidReaction;
  String? get solidReaction => _solidReaction;

  // ========================================
  // 수면 기록 상태
  // ========================================

  /// 수면 시작 시간
  DateTime _sleepStartTime = DateTime.now();
  DateTime get sleepStartTime => _sleepStartTime;

  /// 수면 종료 시간 (null = 진행 중)
  DateTime? _sleepEndTime;
  DateTime? get sleepEndTime => _sleepEndTime;

  /// 수면 진행 중 여부
  bool get isSleepOngoing => _sleepEndTime == null;

  /// 수면 타입: nap (낮잠), night (밤잠)
  String _sleepType = 'nap';
  String get sleepType => _sleepType;

  // ========================================
  // 기저귀 기록 상태
  // ========================================

  /// 기저귀 종류: wet, dirty, both, dry
  String _diaperType = 'wet';
  String get diaperType => _diaperType;

  /// 대변 색상 (dirty/both 선택 시): yellow, brown, green, black, red, white
  String? _stoolColor;
  String? get stoolColor => _stoolColor;

  // ========================================
  // 놀이 기록 상태
  // ========================================

  /// 놀이 종류: tummy_time, bath, outdoor, play, reading, other
  String _playType = 'tummy_time';
  String get playType => _playType;

  /// 놀이 시간 (분) - 선택적
  int? _playDuration;
  int? get playDuration => _playDuration;

  // ========================================
  // 건강 기록 상태
  // ========================================

  /// 건강 기록 종류: temperature, symptom, medication, hospital
  String _healthType = 'temperature';
  String get healthType => _healthType;

  /// 체온 (°C)
  double? _temperature;
  double? get temperature => _temperature;

  /// 증상 목록 (다중 선택)
  List<String> _symptoms = [];
  List<String> get symptoms => List.unmodifiable(_symptoms);

  /// 투약 정보
  String? _medication;
  String? get medication => _medication;

  /// 병원 방문 정보
  String? _hospitalVisit;
  String? get hospitalVisit => _hospitalVisit;

  // ========================================
  // MB-02: 아기별 데이터 캐싱
  // ========================================

  /// 아기별 수유 데이터 캐시
  final Map<String, _FeedingCache> _feedingCache = {};

  /// 아기별 수면 데이터 캐시
  final Map<String, _SleepCache> _sleepCache = {};

  /// 아기별 기저귀 데이터 캐시
  final Map<String, _DiaperCache> _diaperCache = {};

  /// 아기별 놀이 데이터 캐시
  final Map<String, _PlayCache> _playCache = {};

  /// 아기별 건강 데이터 캐시
  final Map<String, _HealthCache> _healthCache = {};

  // ========================================
  // 초기화 메서드
  // ========================================

  /// Provider 초기화
  void initialize({
    required String familyId,
    required List<BabyModel> babies,
    String? preselectedBabyId,
  }) {
    _familyId = familyId;
    _babies = babies;
    _recordTime = DateTime.now();
    _notes = null;
    _errorMessage = null;

    // 기본 선택: 전달된 ID 또는 첫 번째 아기
    if (preselectedBabyId != null) {
      _selectedBabyIds = [preselectedBabyId];
    } else if (babies.isNotEmpty) {
      _selectedBabyIds = [babies.first.id];
    } else {
      _selectedBabyIds = [];
    }

    // 수유 기록 초기화
    _feedingType = 'breast';
    _feedingAmount = 0;
    _feedingAmountByBaby = {};
    _isIndividualAmount = false;
    _feedingDuration = 0;
    _breastSide = 'left';

    // 이유식 기록 초기화
    _solidFoodName = '';
    _solidIsFirstTry = false;
    _solidUnit = 'gram';
    _solidAmount = 0;
    _solidReaction = null;

    // 수면 기록 초기화
    _sleepStartTime = DateTime.now();
    _sleepEndTime = null;
    _sleepType = 'nap';

    // 기저귀 기록 초기화
    _diaperType = 'wet';
    _stoolColor = null;

    // 놀이 기록 초기화
    _playType = 'tummy_time';
    _playDuration = null;

    // 건강 기록 초기화
    _healthType = 'temperature';
    _temperature = null;
    _symptoms = [];
    _medication = null;
    _hospitalVisit = null;

    notifyListeners();
  }

  // ========================================
  // 공통 메서드
  // ========================================

  /// 아기 선택 변경 (MB-02: 데이터 캐싱 포함)
  void setSelectedBabyIds(List<String> babyIds) {
    // 현재 아기 데이터 저장
    final previousBabyId = selectedBabyId;
    if (previousBabyId != null) {
      _saveCacheForBaby(previousBabyId);
    }

    _selectedBabyIds = List.from(babyIds);

    // 새 아기 데이터 복원
    final newBabyId = selectedBabyId;
    if (newBabyId != null) {
      _restoreCacheForBaby(newBabyId);
    }

    notifyListeners();
  }

  /// MB-02: 현재 아기 데이터를 캐시에 저장
  void _saveCacheForBaby(String babyId) {
    // 수유 캐시
    _feedingCache[babyId] = _FeedingCache(
      type: _feedingType,
      amount: _feedingAmount,
      duration: _feedingDuration,
      breastSide: _breastSide,
    );

    // 수면 캐시
    _sleepCache[babyId] = _SleepCache(
      startTime: _sleepStartTime,
      endTime: _sleepEndTime,
      sleepType: _sleepType,
    );

    // 기저귀 캐시
    _diaperCache[babyId] = _DiaperCache(
      type: _diaperType,
      stoolColor: _stoolColor,
    );

    // 놀이 캐시
    _playCache[babyId] = _PlayCache(
      type: _playType,
      duration: _playDuration,
    );

    // 건강 캐시
    _healthCache[babyId] = _HealthCache(
      type: _healthType,
      temperature: _temperature,
      symptoms: List.from(_symptoms),
      medication: _medication,
      hospitalVisit: _hospitalVisit,
    );
  }

  /// MB-02: 캐시에서 아기 데이터 복원
  void _restoreCacheForBaby(String babyId) {
    // 수유 캐시 복원
    final feedingCache = _feedingCache[babyId];
    if (feedingCache != null) {
      _feedingType = feedingCache.type;
      _feedingAmount = feedingCache.amount;
      _feedingDuration = feedingCache.duration;
      _breastSide = feedingCache.breastSide;
    }

    // 수면 캐시 복원
    final sleepCache = _sleepCache[babyId];
    if (sleepCache != null) {
      _sleepStartTime = sleepCache.startTime;
      _sleepEndTime = sleepCache.endTime;
      _sleepType = sleepCache.sleepType;
    }

    // 기저귀 캐시 복원
    final diaperCache = _diaperCache[babyId];
    if (diaperCache != null) {
      _diaperType = diaperCache.type;
      _stoolColor = diaperCache.stoolColor;
    }

    // 놀이 캐시 복원
    final playCache = _playCache[babyId];
    if (playCache != null) {
      _playType = playCache.type;
      _playDuration = playCache.duration;
    }

    // 건강 캐시 복원
    final healthCache = _healthCache[babyId];
    if (healthCache != null) {
      _healthType = healthCache.type;
      _temperature = healthCache.temperature;
      _symptoms = List.from(healthCache.symptoms);
      _medication = healthCache.medication;
      _hospitalVisit = healthCache.hospitalVisit;
    }
  }

  /// 기록 시간 변경
  void setRecordTime(DateTime time) {
    _recordTime = time;
    notifyListeners();
  }

  /// 메모 변경
  void setNotes(String? notes) {
    _notes = notes?.trim().isEmpty == true ? null : notes?.trim();
  }

  /// 선택 유효성 검사
  bool get isSelectionValid => _selectedBabyIds.isNotEmpty;

  // ========================================
  // 수유 기록 메서드
  // ========================================

  /// 수유 종류 변경
  void setFeedingType(String type) {
    _feedingType = type;
    notifyListeners();
  }

  /// 수유량 변경 (공통)
  void setFeedingAmount(double amount) {
    _feedingAmount = amount;
    notifyListeners();
  }

  /// 아기별 수유량 변경
  void setFeedingAmountForBaby(String babyId, double amount) {
    _feedingAmountByBaby = Map.from(_feedingAmountByBaby);
    _feedingAmountByBaby[babyId] = amount;
    notifyListeners();
  }

  /// 개별 입력 모드 토글
  void toggleIndividualAmount() {
    _isIndividualAmount = !_isIndividualAmount;
    if (_isIndividualAmount) {
      // 공통 양을 각 아기에게 복사
      for (final babyId in _selectedBabyIds) {
        _feedingAmountByBaby[babyId] = _feedingAmount;
      }
    }
    notifyListeners();
  }

  /// 수유 시간 변경 (분)
  void setFeedingDuration(int minutes) {
    _feedingDuration = minutes;
    notifyListeners();
  }

  /// 모유 수유 좌/우 변경
  void setBreastSide(String side) {
    _breastSide = side;
    notifyListeners();
  }

  // ========================================
  // 이유식 기록 메서드 (Sprint 8)
  // ========================================

  /// 음식 이름 변경
  void setSolidFoodName(String name) {
    _solidFoodName = name;
    notifyListeners();
  }

  /// 처음 먹이는 음식 체크 변경
  void setSolidIsFirstTry(bool isFirstTry) {
    _solidIsFirstTry = isFirstTry;
    notifyListeners();
  }

  /// 양 단위 변경
  void setSolidUnit(String unit) {
    _solidUnit = unit;
    notifyListeners();
  }

  /// 양 변경
  void setSolidAmount(double amount) {
    _solidAmount = amount;
    notifyListeners();
  }

  /// 아기 반응 변경
  void setSolidReaction(String? reaction) {
    _solidReaction = reaction;
    notifyListeners();
  }

  /// 이유식 데이터 구성 (saveFeeding에서 호출)
  Map<String, dynamic> _buildSolidFoodData() {
    return {
      'content_type': 'solid',
      'food_name': _solidFoodName,
      'is_first_try': _solidIsFirstTry,
      'amount_unit': _solidUnit,
      'amount_value': _solidAmount,
      if (_solidReaction != null) 'baby_reaction': _solidReaction,
    };
  }

  /// 수유 기록 저장
  Future<ActivityModel?> saveFeeding() async {
    if (!isSelectionValid) {
      _errorMessage = '아기를 선택해주세요';
      notifyListeners();
      return null;
    }

    if (_familyId == null) {
      _errorMessage = '가족 정보가 없습니다';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 수유 데이터 구성
      final data = <String, dynamic>{
        'feeding_type': _feedingType,
      };

      // 이유식인 경우 별도 데이터 구조 사용
      if (_feedingType == 'solid') {
        data.addAll(_buildSolidFoodData());
      } else if (_feedingType != 'breast') {
        // 분유 등 양 데이터
        if (_isIndividualAmount && _selectedBabyIds.length > 1) {
          data['amount_by_baby'] = _feedingAmountByBaby;
          // 평균 양 계산
          final totalAmount = _feedingAmountByBaby.values.fold(0.0, (a, b) => a + b);
          data['amount_ml'] = totalAmount / _selectedBabyIds.length;
        } else {
          data['amount_ml'] = _feedingAmount;
        }
      }

      // 모유 수유 시간 및 좌/우
      if (_feedingType == 'breast') {
        data['breast_side'] = _breastSide;
        if (_feedingDuration > 0) {
          data['duration_minutes'] = _feedingDuration;
        }
      }

      final activity = ActivityModel(
        id: _uuid.v4(),
        familyId: _familyId!,
        babyIds: List.from(_selectedBabyIds),
        type: ActivityType.feeding,
        startTime: _recordTime,
        endTime: _feedingType == 'breast' && _feedingDuration > 0
            ? _recordTime.add(Duration(minutes: _feedingDuration))
            : _recordTime,
        data: data,
        notes: _notes,
        createdAt: DateTime.now(),
      );

      final savedActivity = await _localActivityService.saveActivity(activity);

      debugPrint('[OK] [RecordProvider] Feeding saved: ${savedActivity.id}');
      return savedActivity;
    } catch (e) {
      _errorMessage = '저장에 실패했습니다: $e';
      debugPrint('❌ [RecordProvider] Error saving feeding: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========================================
  // 수면 기록 메서드
  // ========================================

  /// 수면 시작 시간 변경
  void setSleepStartTime(DateTime time) {
    _sleepStartTime = time;
    notifyListeners();
  }

  /// 수면 종료 시간 변경
  void setSleepEndTime(DateTime? time) {
    _sleepEndTime = time;
    notifyListeners();
  }

  /// 수면 타입 변경
  void setSleepType(String type) {
    _sleepType = type;
    notifyListeners();
  }

  /// 수면 시간 (분)
  /// 자정을 넘기는 경우도 정확히 계산 (QA-01 수정)
  int get sleepDurationMinutes {
    final end = _sleepEndTime ?? DateTime.now();

    // 종료 시간이 시작 시간보다 이전이면 다음 날로 처리
    DateTime adjustedEnd = end;
    if (end.isBefore(_sleepStartTime)) {
      // 자정을 넘긴 경우: 다음 날로 조정
      adjustedEnd = end.add(const Duration(days: 1));
    }

    final duration = adjustedEnd.difference(_sleepStartTime).inMinutes;
    // 음수 방지 (비정상 케이스)
    return duration < 0 ? 0 : duration;
  }

  /// 수면 기록 저장
  Future<ActivityModel?> saveSleep() async {
    if (!isSelectionValid) {
      _errorMessage = '아기를 선택해주세요';
      notifyListeners();
      return null;
    }

    if (_familyId == null) {
      _errorMessage = '가족 정보가 없습니다';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final activity = ActivityModel(
        id: _uuid.v4(),
        familyId: _familyId!,
        babyIds: List.from(_selectedBabyIds),
        type: ActivityType.sleep,
        startTime: _sleepStartTime,
        endTime: _sleepEndTime,
        data: {'sleep_type': _sleepType},
        notes: _notes,
        createdAt: DateTime.now(),
      );

      final savedActivity = await _localActivityService.saveActivity(activity);

      debugPrint('[OK] [RecordProvider] Sleep saved: ${savedActivity.id}');
      return savedActivity;
    } catch (e) {
      _errorMessage = '저장에 실패했습니다: $e';
      debugPrint('❌ [RecordProvider] Error saving sleep: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========================================
  // 기저귀 기록 메서드
  // ========================================

  /// 기저귀 종류 변경
  void setDiaperType(String type) {
    _diaperType = type;
    // 소변이나 건조 선택 시 색상 초기화
    if (type == 'wet' || type == 'dry') {
      _stoolColor = null;
    }
    notifyListeners();
  }

  /// 대변 색상 변경
  void setStoolColor(String? color) {
    _stoolColor = color;
    notifyListeners();
  }

  // ========================================
  // 놀이 기록 메서드
  // ========================================

  /// 놀이 종류 변경
  void setPlayType(String type) {
    _playType = type;
    notifyListeners();
  }

  /// 놀이 시간 변경 (분)
  void setPlayDuration(int? minutes) {
    _playDuration = minutes;
    notifyListeners();
  }

  /// 놀이 기록 저장
  Future<ActivityModel?> savePlay() async {
    if (!isSelectionValid) {
      _errorMessage = '아기를 선택해주세요';
      notifyListeners();
      return null;
    }

    if (_familyId == null) {
      _errorMessage = '가족 정보가 없습니다';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = <String, dynamic>{
        'play_type': _playType,
      };

      if (_playDuration != null && _playDuration! > 0) {
        data['duration_minutes'] = _playDuration;
      }

      final activity = ActivityModel(
        id: _uuid.v4(),
        familyId: _familyId!,
        babyIds: List.from(_selectedBabyIds),
        type: ActivityType.play,
        startTime: _recordTime,
        endTime: _playDuration != null && _playDuration! > 0
            ? _recordTime.add(Duration(minutes: _playDuration!))
            : null,
        data: data,
        notes: _notes,
        createdAt: DateTime.now(),
      );

      final savedActivity = await _localActivityService.saveActivity(activity);

      debugPrint('[OK] [RecordProvider] Play saved: ${savedActivity.id}');
      return savedActivity;
    } catch (e) {
      _errorMessage = '저장에 실패했습니다: $e';
      debugPrint('❌ [RecordProvider] Error saving play: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========================================
  // 건강 기록 메서드
  // ========================================

  /// 건강 기록 종류 변경
  void setHealthType(String type) {
    _healthType = type;
    notifyListeners();
  }

  /// 체온 변경
  void setTemperature(double? temp) {
    _temperature = temp;
    notifyListeners();
  }

  /// 증상 토글
  void toggleSymptom(String symptom) {
    _symptoms = List.from(_symptoms);
    if (_symptoms.contains(symptom)) {
      _symptoms.remove(symptom);
    } else {
      _symptoms.add(symptom);
    }
    notifyListeners();
  }

  /// 투약 정보 변경
  void setMedication(String? medication) {
    _medication = medication?.trim().isEmpty == true ? null : medication?.trim();
    notifyListeners();
  }

  /// 병원 방문 정보 변경
  void setHospitalVisit(String? visit) {
    _hospitalVisit = visit?.trim().isEmpty == true ? null : visit?.trim();
    notifyListeners();
  }

  /// 건강 기록 저장
  Future<ActivityModel?> saveHealth() async {
    if (!isSelectionValid) {
      _errorMessage = '아기를 선택해주세요';
      notifyListeners();
      return null;
    }

    if (_familyId == null) {
      _errorMessage = '가족 정보가 없습니다';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = <String, dynamic>{
        'health_type': _healthType,
      };

      // 건강 기록 유형별 데이터 추가
      switch (_healthType) {
        case 'temperature':
          if (_temperature != null) {
            data['temperature'] = _temperature;
          }
          break;
        case 'symptom':
          if (_symptoms.isNotEmpty) {
            data['symptoms'] = _symptoms;
          }
          break;
        case 'medication':
          if (_medication != null) {
            data['medication'] = _medication;
          }
          break;
        case 'hospital':
          if (_hospitalVisit != null) {
            data['hospital_visit'] = _hospitalVisit;
          }
          break;
      }

      final activity = ActivityModel(
        id: _uuid.v4(),
        familyId: _familyId!,
        babyIds: List.from(_selectedBabyIds),
        type: ActivityType.health,
        startTime: _recordTime,
        data: data,
        notes: _notes,
        createdAt: DateTime.now(),
      );

      final savedActivity = await _localActivityService.saveActivity(activity);

      debugPrint('[OK] [RecordProvider] Health saved: ${savedActivity.id}');
      return savedActivity;
    } catch (e) {
      _errorMessage = '저장에 실패했습니다: $e';
      debugPrint('❌ [RecordProvider] Error saving health: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 기저귀 기록 저장
  Future<ActivityModel?> saveDiaper() async {
    if (!isSelectionValid) {
      _errorMessage = '아기를 선택해주세요';
      notifyListeners();
      return null;
    }

    if (_familyId == null) {
      _errorMessage = '가족 정보가 없습니다';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = <String, dynamic>{
        'diaper_type': _diaperType,
      };

      // 대변 색상 추가 (dirty/both인 경우)
      if ((_diaperType == 'dirty' || _diaperType == 'both') &&
          _stoolColor != null) {
        data['stool_color'] = _stoolColor;
      }

      final activity = ActivityModel(
        id: _uuid.v4(),
        familyId: _familyId!,
        babyIds: List.from(_selectedBabyIds),
        type: ActivityType.diaper,
        startTime: _recordTime,
        data: data,
        notes: _notes,
        createdAt: DateTime.now(),
      );

      final savedActivity = await _localActivityService.saveActivity(activity);

      debugPrint('[OK] [RecordProvider] Diaper saved: ${savedActivity.id}');
      return savedActivity;
    } catch (e) {
      _errorMessage = '저장에 실패했습니다: $e';
      debugPrint('❌ [RecordProvider] Error saving diaper: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========================================
  // 초기화
  // ========================================

  /// 상태 초기화
  void reset() {
    _familyId = null;
    _babies = [];
    _selectedBabyIds = [];
    _recordTime = DateTime.now();
    _notes = null;
    _isLoading = false;
    _errorMessage = null;

    _feedingType = 'breast';
    _feedingAmount = 0;
    _feedingAmountByBaby = {};
    _isIndividualAmount = false;
    _feedingDuration = 0;
    _breastSide = 'left';

    _solidFoodName = '';
    _solidIsFirstTry = false;
    _solidUnit = 'gram';
    _solidAmount = 0;
    _solidReaction = null;

    _sleepStartTime = DateTime.now();
    _sleepEndTime = null;
    _sleepType = 'nap';

    _diaperType = 'wet';
    _stoolColor = null;

    _playType = 'tummy_time';
    _playDuration = null;

    _healthType = 'temperature';
    _temperature = null;
    _symptoms = [];
    _medication = null;
    _hospitalVisit = null;

    // MB-02: 캐시 초기화
    _feedingCache.clear();
    _sleepCache.clear();
    _diaperCache.clear();
    _playCache.clear();
    _healthCache.clear();

    // HOTFIX v1.2: 빠른 수유 캐시 초기화
    _recentFeedings.clear();
    _lastSavedId = null;

    notifyListeners();
  }

  // ========================================
  // HOTFIX v1.2: 빠른 수유 기록 (최근 3개 버튼)
  // ========================================

  /// 최근 수유 기록 (중복 제거된 3개)
  List<ActivityModel> _recentFeedings = [];
  List<ActivityModel> get recentFeedings => List.unmodifiable(_recentFeedings);

  /// 마지막 저장 ID (취소용)
  String? _lastSavedId;

  /// 연타 방지 타임스탬프
  DateTime? _lastQuickSaveTime;

  /// 최근 수유 기록 로드
  /// 아기별로 최근 수유 기록에서 중복 제거 후 3개 반환
  Future<void> loadRecentFeedings(String babyId) async {
    try {
      // 아기 ID로 모든 활동 가져오기
      final allActivities = await _localActivityService.getActivitiesByBabyId(babyId);

      // 수유 기록만 필터링 + 최신순 정렬 (이미 정렬됨)
      final feedingActivities = allActivities
          .where((a) => a.type == ActivityType.feeding)
          .toList();

      // 중복 제거 (feeding_type + breast_side + amount_ml 조합)
      final seen = <String>{};
      final unique = <ActivityModel>[];

      for (final activity in feedingActivities) {
        final key = _buildFeedingKey(activity);
        if (!seen.contains(key)) {
          seen.add(key);
          unique.add(activity);
        }
        if (unique.length >= 3) break;
      }

      _recentFeedings = unique;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ [RecordProvider] Error loading recent feedings: $e');
      _recentFeedings = [];
      notifyListeners();
    }
  }

  /// 수유 기록 고유 키 생성 (중복 판별용)
  String _buildFeedingKey(ActivityModel activity) {
    final data = activity.data;
    if (data == null) return activity.id;

    final type = data['feeding_type'] as String? ?? 'bottle';
    final side = data['breast_side'] as String? ?? '';
    final amount = data['amount_ml']?.toString() ?? '';
    final duration = data['duration_minutes']?.toString() ?? '';

    return '$type|$side|$amount|$duration';
  }

  /// 빠른 수유 저장
  /// 템플릿 기반으로 현재 시간에 저장
  /// 연타 방지: 1초 이내 중복 저장 차단
  Future<String?> quickSaveFeeding(ActivityModel template) async {
    // 연타 방지 (1초 이내)
    final now = DateTime.now();
    if (_lastQuickSaveTime != null &&
        now.difference(_lastQuickSaveTime!).inMilliseconds < 1000) {
      debugPrint('⚠️ [RecordProvider] Quick save blocked (double tap)');
      return null;
    }
    _lastQuickSaveTime = now;

    if (_familyId == null || selectedBabyId == null) {
      _errorMessage = '아기를 선택해주세요';
      notifyListeners();
      return null;
    }

    try {
      // 새 ID와 현재 시간으로 복사
      final newActivity = template.copyWith(
        id: _uuid.v4(),
        babyIds: [selectedBabyId!],
        startTime: now,
        endTime: now,
        createdAt: now,
      );

      final saved = await _localActivityService.saveActivity(newActivity);
      _lastSavedId = saved.id;

      debugPrint('[OK] [RecordProvider] Quick feeding saved: ${saved.id}');

      // 최근 기록 새로고침
      await loadRecentFeedings(selectedBabyId!);

      return saved.id;
    } catch (e) {
      _errorMessage = '저장에 실패했습니다: $e';
      debugPrint('❌ [RecordProvider] Error quick save feeding: $e');
      notifyListeners();
      return null;
    }
  }

  /// 마지막 저장 취소
  Future<bool> undoLastSave() async {
    if (_lastSavedId == null) return false;

    try {
      await _localActivityService.deleteActivity(_lastSavedId!);
      debugPrint('[OK] [RecordProvider] Undo: $_lastSavedId');

      _lastSavedId = null;

      // 최근 기록 새로고침
      if (selectedBabyId != null) {
        await loadRecentFeedings(selectedBabyId!);
      }

      return true;
    } catch (e) {
      debugPrint('❌ [RecordProvider] Error undo: $e');
      return false;
    }
  }
}

// ========================================
// MB-02: 아기별 데이터 캐시 클래스들
// ========================================

/// 수유 데이터 캐시
class _FeedingCache {
  final String type;
  final double amount;
  final int duration;
  final String breastSide;

  _FeedingCache({
    required this.type,
    required this.amount,
    required this.duration,
    required this.breastSide,
  });
}

/// 수면 데이터 캐시
class _SleepCache {
  final DateTime startTime;
  final DateTime? endTime;
  final String sleepType;

  _SleepCache({
    required this.startTime,
    this.endTime,
    required this.sleepType,
  });
}

/// 기저귀 데이터 캐시
class _DiaperCache {
  final String type;
  final String? stoolColor;

  _DiaperCache({
    required this.type,
    this.stoolColor,
  });
}

/// 놀이 데이터 캐시
class _PlayCache {
  final String type;
  final int? duration;

  _PlayCache({
    required this.type,
    this.duration,
  });
}

/// 건강 데이터 캐시
class _HealthCache {
  final String type;
  final double? temperature;
  final List<String> symptoms;
  final String? medication;
  final String? hospitalVisit;

  _HealthCache({
    required this.type,
    this.temperature,
    required this.symptoms,
    this.medication,
    this.hospitalVisit,
  });
}
