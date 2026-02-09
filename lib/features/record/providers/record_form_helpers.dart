// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member

part of 'record_provider.dart';

/// RecordProvider - Form Helper Methods
///
/// Activity-type specific setters extracted from RecordProvider
/// for file size management. Uses `part of` + extension pattern
/// to maintain private field access within the same library.

extension RecordFormHelpers on RecordProvider {
  // ========================================
  // Feeding setters
  // ========================================

  /// setFeedingType
  void setFeedingType(String type) {
    _feedingType = type;
    notifyListeners();
  }

  /// setFeedingAmount (common)
  void setFeedingAmount(double amount) {
    _feedingAmount = amount;
    notifyListeners();
  }

  /// setFeedingAmountForBaby
  void setFeedingAmountForBaby(String babyId, double amount) {
    _feedingAmountByBaby = Map.from(_feedingAmountByBaby);
    _feedingAmountByBaby[babyId] = amount;
    notifyListeners();
  }

  /// toggleIndividualAmount
  void toggleIndividualAmount() {
    _isIndividualAmount = !_isIndividualAmount;
    if (_isIndividualAmount) {
      for (final babyId in _selectedBabyIds) {
        _feedingAmountByBaby[babyId] = _feedingAmount;
      }
    }
    notifyListeners();
  }

  /// setFeedingDuration (minutes)
  void setFeedingDuration(int minutes) {
    _feedingDuration = minutes;
    notifyListeners();
  }

  /// setBreastSide
  void setBreastSide(String side) {
    _breastSide = side;
    notifyListeners();
  }

  // ========================================
  // Solid food setters (Sprint 8)
  // ========================================

  /// setSolidFoodName
  void setSolidFoodName(String name) {
    _solidFoodName = name;
    notifyListeners();
  }

  /// setSolidIsFirstTry
  void setSolidIsFirstTry(bool isFirstTry) {
    _solidIsFirstTry = isFirstTry;
    notifyListeners();
  }

  /// setSolidUnit
  void setSolidUnit(String unit) {
    _solidUnit = unit;
    notifyListeners();
  }

  /// setSolidAmount
  void setSolidAmount(double amount) {
    _solidAmount = amount;
    notifyListeners();
  }

  /// setSolidReaction
  void setSolidReaction(String? reaction) {
    _solidReaction = reaction;
    notifyListeners();
  }

  // ========================================
  // Sleep setters
  // ========================================

  /// setSleepStartTime
  void setSleepStartTime(DateTime time) {
    _sleepStartTime = time;
    notifyListeners();
  }

  /// setSleepEndTime
  void setSleepEndTime(DateTime? time) {
    _sleepEndTime = time;
    notifyListeners();
  }

  /// setSleepType
  void setSleepType(String type) {
    _sleepType = type;
    notifyListeners();
  }

  // ========================================
  // Diaper setters
  // ========================================

  /// setDiaperType
  void setDiaperType(String type) {
    _diaperType = type;
    if (type == 'wet' || type == 'dry') {
      _stoolColor = null;
    }
    notifyListeners();
  }

  /// setStoolColor
  void setStoolColor(String? color) {
    _stoolColor = color;
    notifyListeners();
  }

  // ========================================
  // Play setters
  // ========================================

  /// setPlayType
  void setPlayType(String type) {
    _playType = type;
    notifyListeners();
  }

  /// setPlayDuration (minutes)
  void setPlayDuration(int? minutes) {
    _playDuration = minutes;
    notifyListeners();
  }

  // ========================================
  // Health setters
  // ========================================

  /// setHealthType
  void setHealthType(String type) {
    _healthType = type;
    notifyListeners();
  }

  /// setTemperature
  void setTemperature(double? temp) {
    _temperature = temp;
    notifyListeners();
  }

  /// toggleSymptom
  void toggleSymptom(String symptom) {
    _symptoms = List.from(_symptoms);
    if (_symptoms.contains(symptom)) {
      _symptoms.remove(symptom);
    } else {
      _symptoms.add(symptom);
    }
    notifyListeners();
  }

  /// setMedication
  void setMedication(String? medication) {
    _medication = medication?.trim().isEmpty == true ? null : medication?.trim();
    notifyListeners();
  }

  /// setHospitalVisit
  void setHospitalVisit(String? visit) {
    _hospitalVisit = visit?.trim().isEmpty == true ? null : visit?.trim();
    notifyListeners();
  }
}
