import 'package:flutter/foundation.dart';

import '../../../data/models/models.dart';
import 'record_base_provider.dart';

/// Health Record Provider
///
/// Sprint 21 Phase 2-2: RecordProvider 5-way split
/// Handles health-specific state, setters, save.
/// Includes MB-02 baby-specific caching.
class HealthRecordProvider extends RecordBaseProvider {
  // ========================================
  // Health state
  // ========================================

  /// Health type: temperature, symptom, medication, hospital
  String _healthType = 'temperature';
  String get healthType => _healthType;

  /// Temperature (C)
  double? _temperature;
  double? get temperature => _temperature;

  /// Symptoms list (multi-select)
  List<String> _symptoms = [];
  List<String> get symptoms => List.unmodifiable(_symptoms);

  /// Medication info
  String? _medication;
  String? get medication => _medication;

  /// Hospital visit info
  String? _hospitalVisit;
  String? get hospitalVisit => _hospitalVisit;

  // ========================================
  // MB-02: Baby-specific cache
  // ========================================

  final Map<String, _HealthCache> _healthCache = {};

  // ========================================
  // Health setters
  // ========================================

  /// setHealthType
  void setHealthType(String type) {
    if (_healthType == type) return;
    _healthType = type;
    notifyListeners();
  }

  /// setTemperature
  void setTemperature(double? temp) {
    if (_temperature == temp) return;
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
    final trimmed =
        medication?.trim().isEmpty == true ? null : medication?.trim();
    if (_medication == trimmed) return;
    _medication = trimmed;
    notifyListeners();
  }

  /// setHospitalVisit
  void setHospitalVisit(String? visit) {
    final trimmed =
        visit?.trim().isEmpty == true ? null : visit?.trim();
    if (_hospitalVisit == trimmed) return;
    _hospitalVisit = trimmed;
    notifyListeners();
  }

  // ========================================
  // Save
  // ========================================

  /// Save health record
  Future<ActivityModel?> saveHealth() async {
    if (!validateBeforeSave()) return null;

    setLoading(true);
    setError(null);
    notifyListeners();

    try {
      final data = <String, dynamic>{
        'health_type': _healthType,
      };

      // Type-specific data
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
        id: uuid.v4(),
        familyId: familyId!,
        babyIds: List.from(selectedBabyIds),
        type: ActivityType.health,
        startTime: recordTime,
        data: data,
        notes: notes,
        createdAt: DateTime.now(),
      );

      final savedActivity =
          await activityRepository.createActivity(activity);

      debugPrint(
          '[OK] [HealthRecordProvider] Health saved: ${savedActivity.id}');
      return savedActivity;
    } catch (e) {
      debugPrint('[ERR] [HealthRecordProvider] Error saving health: $e');
      setError('SAVE_FAILED');
      return null;
    } finally {
      setLoading(false);
      notifyListeners();
    }
  }

  // ========================================
  // MB-02: Cache implementation
  // ========================================

  @override
  void saveCacheForBaby(String babyId) {
    _healthCache[babyId] = _HealthCache(
      type: _healthType,
      temperature: _temperature,
      symptoms: List.from(_symptoms),
      medication: _medication,
      hospitalVisit: _hospitalVisit,
    );
  }

  @override
  void restoreCacheForBaby(String babyId) {
    final cache = _healthCache[babyId];
    if (cache != null) {
      _healthType = cache.type;
      _temperature = cache.temperature;
      _symptoms = List.from(cache.symptoms);
      _medication = cache.medication;
      _hospitalVisit = cache.hospitalVisit;
    }
  }

  // ========================================
  // Lifecycle
  // ========================================

  @override
  void initializeActivityState() {
    _healthType = 'temperature';
    _temperature = null;
    _symptoms = [];
    _medication = null;
    _hospitalVisit = null;
  }

  @override
  void resetActivityState() {
    initializeActivityState();
    _healthCache.clear();
  }
}

/// Health data cache (MB-02)
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
