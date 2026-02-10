import 'package:flutter/foundation.dart';

import '../../../data/models/models.dart';
import 'record_base_provider.dart';

/// Feeding Record Provider
///
/// Sprint 21 Phase 2-2: RecordProvider 5-way split
/// Handles feeding-specific state, setters, save, and quick actions.
/// Includes solid food (Sprint 8) and MB-02 baby-specific caching.
class FeedingRecordProvider extends RecordBaseProvider {
  // ========================================
  // Feeding state
  // ========================================

  /// Feeding type: breast, bottle, formula, solid
  String _feedingType = 'breast';
  String get feedingType => _feedingType;

  /// Feeding amount (ml) - single baby or same amount
  double _feedingAmount = 0;
  double get feedingAmount => _feedingAmount;

  /// Per-baby feeding amount (multi-baby individual input)
  Map<String, double> _feedingAmountByBaby = {};
  Map<String, double> get feedingAmountByBaby =>
      Map.unmodifiable(_feedingAmountByBaby);

  /// Individual input mode
  bool _isIndividualAmount = false;
  bool get isIndividualAmount => _isIndividualAmount;

  /// Feeding duration (minutes) - breastfeeding
  int _feedingDuration = 0;
  int get feedingDuration => _feedingDuration;

  /// Breast side: left, right, both
  String _breastSide = 'left';
  String get breastSide => _breastSide;

  // ========================================
  // Solid food state (Sprint 8)
  // ========================================

  /// Food name
  String _solidFoodName = '';
  String get solidFoodName => _solidFoodName;

  /// First try flag
  bool _solidIsFirstTry = false;
  bool get solidIsFirstTry => _solidIsFirstTry;

  /// Amount unit (gram/spoon/bowl)
  String _solidUnit = 'gram';
  String get solidUnit => _solidUnit;

  /// Amount
  double _solidAmount = 0;
  double get solidAmount => _solidAmount;

  /// Baby reaction (liked/neutral/rejected)
  String? _solidReaction;
  String? get solidReaction => _solidReaction;

  // ========================================
  // Quick feeding state (HOTFIX v1.2)
  // ========================================

  /// Recent feeding records (deduplicated, max 3)
  List<ActivityModel> _recentFeedings = [];
  List<ActivityModel> get recentFeedings => List.unmodifiable(_recentFeedings);

  /// Current loading baby ID (race condition prevention)
  String? _currentFeedingBabyId;

  /// Last saved ID (for undo)
  String? _lastSavedId;

  /// Double-tap prevention timestamp
  DateTime? _lastQuickSaveTime;

  // ========================================
  // MB-02: Baby-specific cache
  // ========================================

  final Map<String, _FeedingCache> _feedingCache = {};

  // ========================================
  // Feeding setters
  // ========================================

  /// setFeedingType
  void setFeedingType(String type) {
    if (_feedingType == type) return;
    _feedingType = type;
    notifyListeners();
  }

  /// setFeedingAmount (common)
  void setFeedingAmount(double amount) {
    if (_feedingAmount == amount) return;
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
      for (final babyId in selectedBabyIds) {
        _feedingAmountByBaby[babyId] = _feedingAmount;
      }
    }
    notifyListeners();
  }

  /// setFeedingDuration (minutes)
  void setFeedingDuration(int minutes) {
    if (_feedingDuration == minutes) return;
    _feedingDuration = minutes;
    notifyListeners();
  }

  /// setBreastSide
  void setBreastSide(String side) {
    if (_breastSide == side) return;
    _breastSide = side;
    notifyListeners();
  }

  // ========================================
  // Solid food setters (Sprint 8)
  // ========================================

  /// setSolidFoodName
  void setSolidFoodName(String name) {
    if (_solidFoodName == name) return;
    _solidFoodName = name;
    notifyListeners();
  }

  /// setSolidIsFirstTry
  void setSolidIsFirstTry(bool isFirstTry) {
    if (_solidIsFirstTry == isFirstTry) return;
    _solidIsFirstTry = isFirstTry;
    notifyListeners();
  }

  /// setSolidUnit
  void setSolidUnit(String unit) {
    if (_solidUnit == unit) return;
    _solidUnit = unit;
    notifyListeners();
  }

  /// setSolidAmount
  void setSolidAmount(double amount) {
    if (_solidAmount == amount) return;
    _solidAmount = amount;
    notifyListeners();
  }

  /// setSolidReaction
  void setSolidReaction(String? reaction) {
    if (_solidReaction == reaction) return;
    _solidReaction = reaction;
    notifyListeners();
  }

  // ========================================
  // Save
  // ========================================

  /// Build solid food data
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

  /// Save feeding record
  Future<ActivityModel?> saveFeeding() async {
    if (!validateBeforeSave()) return null;

    setLoading(true);
    setError(null);
    notifyListeners();

    try {
      final data = <String, dynamic>{
        'feeding_type': _feedingType,
      };

      // Solid food uses separate data structure
      if (_feedingType == 'solid') {
        data.addAll(_buildSolidFoodData());
      } else if (_feedingType != 'breast') {
        // Formula etc. amount data
        if (_isIndividualAmount && selectedBabyIds.length > 1) {
          data['amount_by_baby'] = _feedingAmountByBaby;
          final totalAmount =
              _feedingAmountByBaby.values.fold(0.0, (a, b) => a + b);
          data['amount_ml'] = totalAmount / selectedBabyIds.length;
        } else {
          data['amount_ml'] = _feedingAmount;
        }
      }

      // Breastfeeding duration and side
      if (_feedingType == 'breast') {
        data['breast_side'] = _breastSide;
        if (_feedingDuration > 0) {
          data['duration_minutes'] = _feedingDuration;
        }
      }

      final activity = ActivityModel(
        id: uuid.v4(),
        familyId: familyId!,
        babyIds: List.from(selectedBabyIds),
        type: ActivityType.feeding,
        startTime: recordTime,
        endTime: _feedingType == 'breast' && _feedingDuration > 0
            ? recordTime.add(Duration(minutes: _feedingDuration))
            : recordTime,
        data: data,
        notes: notes,
        createdAt: DateTime.now(),
      );

      final savedActivity =
          await activityRepository.createActivity(activity);

      debugPrint(
          '[OK] [FeedingRecordProvider] Feeding saved: ${savedActivity.id}');
      return savedActivity;
    } catch (e) {
      setError('errorSaveFailed:$e');
      debugPrint('[ERR] [FeedingRecordProvider] Error saving feeding: $e');
      return null;
    } finally {
      setLoading(false);
      notifyListeners();
    }
  }

  // ========================================
  // Quick actions (HOTFIX v1.2)
  // ========================================

  /// Load recent feeding records
  /// Returns up to 3 deduplicated recent feedings per baby
  ///
  /// BUGFIX v5.3: Clear immediately on baby tab switch
  Future<void> loadRecentFeedings(String babyId) async {
    // Clear immediately + store babyId for race condition prevention
    _currentFeedingBabyId = babyId;
    _recentFeedings = [];
    notifyListeners();

    debugPrint(
        '[LOAD] loadRecentFeedings started for babyId: $babyId');

    try {
      List<ActivityModel> activities = [];
      try {
        activities = await activityRepository.getActivitiesByBabyId(
          babyId,
          limit: 20,
        );
        debugPrint(
            '[SUPABASE] activities for babyId $babyId: ${activities.length}');
      } catch (e) {
        debugPrint('[WARN] Supabase fetch failed: $e');
      }

      // Race condition check
      if (_currentFeedingBabyId != babyId) {
        debugPrint(
            '[WARN] babyId changed during loading, discarding results');
        return;
      }

      final allActivities = activities
        ..sort((a, b) => b.startTime.compareTo(a.startTime));

      debugPrint(
          '[DATA] Activities for babyId $babyId: ${allActivities.length}');

      // Strict filtering (single baby only)
      final strictFiltered = allActivities.where((a) {
        final isSingleBabyMatch =
            a.babyIds.length == 1 && a.babyIds[0] == babyId;
        return isSingleBabyMatch;
      }).toList();
      debugPrint(
          '[FILTER] Strict filtered for $babyId: ${strictFiltered.length}');

      // Feeding records only
      final feedingActivities = strictFiltered
          .where((a) => a.type == ActivityType.feeding)
          .toList();
      debugPrint(
          '[FEEDING] activities count: ${feedingActivities.length}');

      // Deduplicate (feeding_type + breast_side + amount_ml)
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

      // Final babyId check before state update
      if (_currentFeedingBabyId == babyId) {
        _recentFeedings = unique;
        debugPrint(
            '[OK] Updated _recentFeedings: ${_recentFeedings.length} items');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[ERROR] Error loading recent feedings: $e');
    }
  }

  /// Clear recent feedings (explicit call on baby switch)
  void clearRecentFeedings() {
    _recentFeedings = [];
    _currentFeedingBabyId = null;
    notifyListeners();
  }

  /// Quick save feeding from template
  /// Saves with current time, prevents double-tap (1 second)
  Future<String?> quickSaveFeeding(ActivityModel template) async {
    // Double-tap prevention (1 second)
    final now = DateTime.now();
    if (_lastQuickSaveTime != null &&
        now.difference(_lastQuickSaveTime!).inMilliseconds < 1000) {
      debugPrint(
          '[WARN] [FeedingRecordProvider] Quick save blocked (double tap)');
      return null;
    }
    _lastQuickSaveTime = now;

    if (familyId == null || selectedBabyId == null) {
      setError('errorSelectBaby');
      notifyListeners();
      return null;
    }

    try {
      final newActivity = template.copyWith(
        id: uuid.v4(),
        babyIds: [selectedBabyId!],
        startTime: now,
        endTime: now,
        createdAt: now,
      );

      final saved =
          await activityRepository.createActivity(newActivity);
      _lastSavedId = saved.id;

      debugPrint(
          '[OK] [FeedingRecordProvider] Quick feeding saved: ${saved.id}');

      // Refresh recent records
      await loadRecentFeedings(selectedBabyId!);

      return saved.id;
    } catch (e) {
      setError('errorSaveFailed:$e');
      debugPrint(
          '[ERROR] [FeedingRecordProvider] Error quick save feeding: $e');
      notifyListeners();
      return null;
    }
  }

  /// Undo last save
  Future<bool> undoLastSave() async {
    if (_lastSavedId == null) return false;

    try {
      await activityRepository.deleteActivity(_lastSavedId!);
      debugPrint(
          '[OK] [FeedingRecordProvider] Undo: $_lastSavedId');

      _lastSavedId = null;

      // Refresh recent records
      if (selectedBabyId != null) {
        await loadRecentFeedings(selectedBabyId!);
      }

      return true;
    } catch (e) {
      debugPrint('[ERROR] [FeedingRecordProvider] Error undo: $e');
      return false;
    }
  }

  // ========================================
  // MB-02: Cache implementation
  // ========================================

  @override
  void saveCacheForBaby(String babyId) {
    _feedingCache[babyId] = _FeedingCache(
      type: _feedingType,
      amount: _feedingAmount,
      duration: _feedingDuration,
      breastSide: _breastSide,
    );
  }

  @override
  void restoreCacheForBaby(String babyId) {
    final cache = _feedingCache[babyId];
    if (cache != null) {
      _feedingType = cache.type;
      _feedingAmount = cache.amount;
      _feedingDuration = cache.duration;
      _breastSide = cache.breastSide;
    }
  }

  // ========================================
  // Lifecycle
  // ========================================

  @override
  void initializeActivityState() {
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
  }

  @override
  void resetActivityState() {
    initializeActivityState();

    _feedingCache.clear();
    _recentFeedings.clear();
    _lastSavedId = null;
    _currentFeedingBabyId = null;
    _lastQuickSaveTime = null;
  }

  // ========================================
  // Internal helpers
  // ========================================

  /// Build feeding key for deduplication
  String _buildFeedingKey(ActivityModel activity) {
    final data = activity.data;
    if (data == null) return activity.id;

    final type = data['feeding_type'] as String? ?? 'bottle';
    final side = data['breast_side'] as String? ?? '';
    final amount = data['amount_ml']?.toString() ?? '';
    final duration = data['duration_minutes']?.toString() ?? '';

    return '$type|$side|$amount|$duration';
  }
}

/// Feeding data cache (MB-02)
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
