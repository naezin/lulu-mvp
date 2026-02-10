import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../../data/models/baby_type.dart';
import '../../../../data/models/baby_model.dart';
import '../../../../data/models/family_model.dart';
import '../../../../l10n/generated/app_localizations.dart' show S;

/// 온보딩 단계
enum OnboardingStep {
  welcome,
  babyCount,
  babyInfo,
  pretermInfo,
  multipleBirthTip,
  completion,
}

/// 개별 아기 정보 임시 저장용
class BabyFormData {
  String name;
  DateTime? birthDate;
  Gender gender;
  bool isPreterm;
  int? gestationalWeeks;
  int? birthWeightGrams;

  BabyFormData({
    this.name = '',
    this.birthDate,
    this.gender = Gender.unknown,
    this.isPreterm = false,
    this.gestationalWeeks,
    this.birthWeightGrams,
  });

  BabyFormData copyWith({
    String? name,
    DateTime? birthDate,
    Gender? gender,
    bool? isPreterm,
    int? gestationalWeeks,
    int? birthWeightGrams,
  }) {
    return BabyFormData(
      name: name ?? this.name,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      isPreterm: isPreterm ?? this.isPreterm,
      gestationalWeeks: gestationalWeeks ?? this.gestationalWeeks,
      birthWeightGrams: birthWeightGrams ?? this.birthWeightGrams,
    );
  }

  /// SGA-01: 출생체중 필수 조건 추가
  bool get isValid => name.isNotEmpty && birthDate != null && birthWeightGrams != null;

  bool get needsPretermInfo => isPreterm;
}

/// 온보딩 상태 관리 Provider
class OnboardingProvider extends ChangeNotifier {
  final _uuid = const Uuid();

  // 현재 단계
  OnboardingStep _currentStep = OnboardingStep.welcome;
  OnboardingStep get currentStep => _currentStep;

  // 아기 수
  int _babyCount = 1;
  int get babyCount => _babyCount;

  // 현재 입력 중인 아기 인덱스 (0-based)
  int _currentBabyIndex = 0;
  int get currentBabyIndex => _currentBabyIndex;

  // 아기 정보 리스트
  List<BabyFormData> _babies = [BabyFormData()];
  List<BabyFormData> get babies => List.unmodifiable(_babies);

  // 현재 아기 정보
  BabyFormData get currentBaby => _babies[_currentBabyIndex];

  // 동일란/이란 (다태아용)
  Zygosity _zygosity = Zygosity.unknown;
  Zygosity get zygosity => _zygosity;

  // 로딩 상태
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // 에러 메시지
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // ========================================
  // 단계 네비게이션
  // ========================================

  /// 다음 단계로 이동
  void nextStep() {
    final nextStep = _getNextStep();
    if (nextStep != null) {
      _currentStep = nextStep;
      notifyListeners();
    }
  }

  /// 이전 단계로 이동
  void previousStep() {
    final prevStep = _getPreviousStep();
    if (prevStep != null) {
      _currentStep = prevStep;
      notifyListeners();
    }
  }

  /// 특정 단계로 이동
  void goToStep(OnboardingStep step) {
    if (_currentStep == step) return;
    _currentStep = step;
    notifyListeners();
  }

  OnboardingStep? _getNextStep() {
    switch (_currentStep) {
      case OnboardingStep.welcome:
        return OnboardingStep.babyCount;

      case OnboardingStep.babyCount:
        return OnboardingStep.babyInfo;

      case OnboardingStep.babyInfo:
        // 현재 아기가 조산아면 조산아 정보 입력
        if (currentBaby.isPreterm) {
          return OnboardingStep.pretermInfo;
        }
        // 다음 아기가 있으면 다음 아기 정보 입력
        if (_currentBabyIndex < _babyCount - 1) {
          _currentBabyIndex++;
          return OnboardingStep.babyInfo;
        }
        // 다태아면 팁 화면
        if (_babyCount > 1) {
          return OnboardingStep.multipleBirthTip;
        }
        return OnboardingStep.completion;

      case OnboardingStep.pretermInfo:
        // 다음 아기가 있으면 다음 아기 정보 입력
        if (_currentBabyIndex < _babyCount - 1) {
          _currentBabyIndex++;
          return OnboardingStep.babyInfo;
        }
        // 다태아면 팁 화면
        if (_babyCount > 1) {
          return OnboardingStep.multipleBirthTip;
        }
        return OnboardingStep.completion;

      case OnboardingStep.multipleBirthTip:
        return OnboardingStep.completion;

      case OnboardingStep.completion:
        return null;
    }
  }

  OnboardingStep? _getPreviousStep() {
    switch (_currentStep) {
      case OnboardingStep.welcome:
        return null;

      case OnboardingStep.babyCount:
        return OnboardingStep.welcome;

      case OnboardingStep.babyInfo:
        if (_currentBabyIndex > 0) {
          _currentBabyIndex--;
          // 이전 아기가 조산아였다면 조산아 정보로
          if (_babies[_currentBabyIndex].isPreterm) {
            return OnboardingStep.pretermInfo;
          }
          return OnboardingStep.babyInfo;
        }
        return OnboardingStep.babyCount;

      case OnboardingStep.pretermInfo:
        return OnboardingStep.babyInfo;

      case OnboardingStep.multipleBirthTip:
        // 마지막 아기로 돌아감
        _currentBabyIndex = _babyCount - 1;
        if (_babies[_currentBabyIndex].isPreterm) {
          return OnboardingStep.pretermInfo;
        }
        return OnboardingStep.babyInfo;

      case OnboardingStep.completion:
        if (_babyCount > 1) {
          return OnboardingStep.multipleBirthTip;
        }
        _currentBabyIndex = _babyCount - 1;
        if (_babies[_currentBabyIndex].isPreterm) {
          return OnboardingStep.pretermInfo;
        }
        return OnboardingStep.babyInfo;
    }
  }

  // ========================================
  // 아기 수 설정
  // ========================================

  void setBabyCount(int count) {
    if (count < 1 || count > 4) return;
    if (_babyCount == count) return;

    _babyCount = count;
    _currentBabyIndex = 0;

    // 아기 정보 리스트 크기 조정
    if (_babies.length < count) {
      _babies = [
        ..._babies,
        ...List.generate(count - _babies.length, (_) => BabyFormData()),
      ];
    } else if (_babies.length > count) {
      _babies = _babies.sublist(0, count);
    }

    notifyListeners();
  }

  // ========================================
  // 아기 정보 업데이트
  // ========================================

  void updateBabyName(String name) {
    if (currentBaby.name == name) return;
    _babies[_currentBabyIndex] = currentBaby.copyWith(name: name);
    notifyListeners();
  }

  void updateBabyBirthDate(DateTime date) {
    if (currentBaby.birthDate == date) return;
    _babies[_currentBabyIndex] = currentBaby.copyWith(birthDate: date);
    notifyListeners();
  }

  void updateBabyGender(Gender gender) {
    if (currentBaby.gender == gender) return;
    _babies[_currentBabyIndex] = currentBaby.copyWith(gender: gender);
    notifyListeners();
  }

  void updateBabyIsPreterm(bool isPreterm) {
    _babies[_currentBabyIndex] = currentBaby.copyWith(
      isPreterm: isPreterm,
      gestationalWeeks: isPreterm ? currentBaby.gestationalWeeks : null,
      birthWeightGrams: isPreterm ? currentBaby.birthWeightGrams : null,
    );
    notifyListeners();
  }

  void updateGestationalWeeks(int weeks) {
    if (currentBaby.gestationalWeeks == weeks) return;
    _babies[_currentBabyIndex] = currentBaby.copyWith(gestationalWeeks: weeks);
    notifyListeners();
  }

  void updateBirthWeight(int grams) {
    if (currentBaby.birthWeightGrams == grams) return;
    _babies[_currentBabyIndex] = currentBaby.copyWith(birthWeightGrams: grams);
    notifyListeners();
  }

  /// SGA-01: 출생체중 초기화
  void clearBirthWeight() {
    _babies[_currentBabyIndex] = BabyFormData(
      name: currentBaby.name,
      birthDate: currentBaby.birthDate,
      gender: currentBaby.gender,
      isPreterm: currentBaby.isPreterm,
      gestationalWeeks: currentBaby.gestationalWeeks,
      birthWeightGrams: null,
    );
    notifyListeners();
  }

  void updateZygosity(Zygosity zygosity) {
    if (_zygosity == zygosity) return;
    _zygosity = zygosity;
    notifyListeners();
  }

  // ========================================
  // 유효성 검사
  // ========================================

  bool get isCurrentBabyValid => currentBaby.isValid;

  bool get isAllBabiesValid => _babies.every((baby) => baby.isValid);

  bool get canProceed {
    switch (_currentStep) {
      case OnboardingStep.welcome:
        return true;
      case OnboardingStep.babyCount:
        return _babyCount >= 1 && _babyCount <= 4;
      case OnboardingStep.babyInfo:
        return currentBaby.isValid;
      case OnboardingStep.pretermInfo:
        return currentBaby.gestationalWeeks != null;
      case OnboardingStep.multipleBirthTip:
        return true;
      case OnboardingStep.completion:
        return true;
    }
  }

  // ========================================
  // 온보딩 완료 및 데이터 생성
  // ========================================

  /// 온보딩 데이터를 FamilyModel과 BabyModel로 변환
  Future<({FamilyModel family, List<BabyModel> babies})> completeOnboarding() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final now = DateTime.now();
      final familyId = _uuid.v4();
      final userId = _uuid.v4(); // 실제로는 인증된 사용자 ID 사용

      final babyModels = <BabyModel>[];
      final babyIds = <String>[];

      for (int i = 0; i < _babies.length; i++) {
        final babyData = _babies[i];
        final babyId = _uuid.v4();
        babyIds.add(babyId);

        // BUGFIX: 만삭아도 재태주수/출생체중 저장 (SGA 감지용)
        // 기존: 조산아만 gestationalWeeksAtBirth 저장
        // 수정: 모든 아기에게 저장 (만삭아는 40주로 가정)
        final baby = BabyModel(
          id: babyId,
          familyId: familyId,
          name: babyData.name,
          birthDate: babyData.birthDate!,
          gender: babyData.gender,
          gestationalWeeksAtBirth: babyData.gestationalWeeks ?? 40, // 만삭아도 저장
          birthWeightGrams: babyData.birthWeightGrams, // 만삭아도 저장
          multipleBirthType: _babyCount > 1 ? BabyType.fromBabyCount(_babyCount) : BabyType.singleton,
          zygosity: _babyCount > 1 ? _zygosity : null,
          birthOrder: _babyCount > 1 ? i + 1 : null,
          createdAt: now,
        );

        babyModels.add(baby);
      }

      final family = FamilyModel(
        id: familyId,
        userId: userId,
        babyIds: babyIds,
        createdAt: now,
      );

      _isLoading = false;
      notifyListeners();

      return (family: family, babies: babyModels);
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to complete onboarding: $e';
      notifyListeners();
      rethrow;
    }
  }

  // ========================================
  // 리셋
  // ========================================

  void reset() {
    _currentStep = OnboardingStep.welcome;
    _babyCount = 1;
    _currentBabyIndex = 0;
    _babies = [BabyFormData()];
    _zygosity = Zygosity.unknown;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  // ========================================
  // 진행률
  // ========================================

  double get progress {
    // 총 단계 수 계산
    int totalSteps = 3; // welcome, babyCount, completion
    totalSteps += _babyCount; // 각 아기의 기본 정보
    totalSteps += _babies.where((b) => b.isPreterm).length; // 조산아 정보
    if (_babyCount > 1) totalSteps++; // 다태아 팁

    // 현재 진행 단계
    int currentProgress = 0;
    switch (_currentStep) {
      case OnboardingStep.welcome:
        currentProgress = 1;
        break;
      case OnboardingStep.babyCount:
        currentProgress = 2;
        break;
      case OnboardingStep.babyInfo:
        currentProgress = 3 + _currentBabyIndex;
        break;
      case OnboardingStep.pretermInfo:
        currentProgress = 3 + _currentBabyIndex + 1;
        break;
      case OnboardingStep.multipleBirthTip:
        currentProgress = totalSteps - 1;
        break;
      case OnboardingStep.completion:
        currentProgress = totalSteps;
        break;
    }

    return currentProgress / totalSteps;
  }

  /// 현재 아기 라벨 (첫째, 둘째, ...)
  String currentBabyLabel(S l10n) {
    if (_babyCount == 1) return l10n.babyLabelDefault;
    return switch (_currentBabyIndex) {
      0 => l10n.birthOrderFirst,
      1 => l10n.birthOrderSecond,
      2 => l10n.birthOrderThird,
      3 => l10n.birthOrderFourth,
      _ => l10n.babyLabelDefault,
    };
  }
}
