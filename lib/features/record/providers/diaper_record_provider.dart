import 'package:flutter/foundation.dart';

import '../../../data/models/models.dart';
import 'record_base_provider.dart';

/// Diaper Record Provider
///
/// Sprint 21 Phase 2-2: RecordProvider 5-way split
/// Handles diaper-specific state, setters, save.
/// Includes MB-02 baby-specific caching.
class DiaperRecordProvider extends RecordBaseProvider {
  // ========================================
  // Diaper state
  // ========================================

  /// Diaper type: wet, dirty, both, dry
  String _diaperType = 'wet';
  String get diaperType => _diaperType;

  /// Stool color (when dirty/both): yellow, brown, green, black, red, white
  String? _stoolColor;
  String? get stoolColor => _stoolColor;

  // ========================================
  // MB-02: Baby-specific cache
  // ========================================

  final Map<String, _DiaperCache> _diaperCache = {};

  // ========================================
  // Diaper setters
  // ========================================

  /// setDiaperType
  void setDiaperType(String type) {
    if (_diaperType == type) return;
    _diaperType = type;
    if (type == 'wet' || type == 'dry') {
      _stoolColor = null;
    }
    notifyListeners();
  }

  /// setStoolColor
  void setStoolColor(String? color) {
    if (_stoolColor == color) return;
    _stoolColor = color;
    notifyListeners();
  }

  // ========================================
  // Save
  // ========================================

  /// Save diaper record
  Future<ActivityModel?> saveDiaper() async {
    if (!validateBeforeSave()) return null;

    setLoading(true);
    setError(null);
    notifyListeners();

    try {
      final data = <String, dynamic>{
        'diaper_type': _diaperType,
      };

      // Add stool color (when dirty/both)
      if ((_diaperType == 'dirty' || _diaperType == 'both') &&
          _stoolColor != null) {
        data['stool_color'] = _stoolColor;
      }

      final activity = ActivityModel(
        id: uuid.v4(),
        familyId: familyId!,
        babyIds: List.from(selectedBabyIds),
        type: ActivityType.diaper,
        startTime: recordTime,
        data: data,
        notes: notes,
        createdAt: DateTime.now(),
      );

      final savedActivity =
          await activityRepository.createActivity(activity);

      debugPrint(
          '[OK] [DiaperRecordProvider] Diaper saved: ${savedActivity.id}');
      return savedActivity;
    } catch (e) {
      debugPrint('[ERR] [DiaperRecordProvider] Error saving diaper: $e');
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
    _diaperCache[babyId] = _DiaperCache(
      type: _diaperType,
      stoolColor: _stoolColor,
    );
  }

  @override
  void restoreCacheForBaby(String babyId) {
    final cache = _diaperCache[babyId];
    if (cache != null) {
      _diaperType = cache.type;
      _stoolColor = cache.stoolColor;
    }
  }

  // ========================================
  // Lifecycle
  // ========================================

  @override
  void initializeActivityState() {
    _diaperType = 'wet';
    _stoolColor = null;
  }

  @override
  void resetActivityState() {
    initializeActivityState();
    _diaperCache.clear();
  }
}

/// Diaper data cache (MB-02)
class _DiaperCache {
  final String type;
  final String? stoolColor;

  _DiaperCache({
    required this.type,
    this.stoolColor,
  });
}
