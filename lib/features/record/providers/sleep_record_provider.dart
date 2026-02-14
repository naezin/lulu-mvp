import 'package:flutter/foundation.dart';

import '../../../core/utils/sleep_classifier.dart';
import '../../../data/models/models.dart';
import 'record_base_provider.dart';

/// Sleep Record Provider
///
/// Sprint 21 Phase 2-2: RecordProvider 5-way split
/// Handles sleep-specific state, setters, save, and overlap check.
/// Includes MB-02 baby-specific caching.
class SleepRecordProvider extends RecordBaseProvider {
  // ========================================
  // Sleep state
  // ========================================

  /// Sleep start time
  DateTime _sleepStartTime = DateTime.now();
  DateTime get sleepStartTime => _sleepStartTime;

  /// Sleep end time (null = ongoing)
  DateTime? _sleepEndTime;
  DateTime? get sleepEndTime => _sleepEndTime;

  /// Sleep ongoing check
  bool get isSleepOngoing => _sleepEndTime == null;

  /// Sleep type: nap, night
  String _sleepType = 'nap';
  String get sleepType => _sleepType;

  /// Sprint 20 HF #9-C: Sleep overlap warning flag
  bool _sleepOverlapWarning = false;
  bool get sleepOverlapWarning => _sleepOverlapWarning;

  // ========================================
  // MB-02: Baby-specific cache
  // ========================================

  final Map<String, _SleepCache> _sleepCache = {};

  // ========================================
  // Sleep setters
  // ========================================

  /// setSleepStartTime
  void setSleepStartTime(DateTime time) {
    if (_sleepStartTime == time) return;
    _sleepStartTime = time;
    notifyListeners();
  }

  /// setSleepEndTime
  void setSleepEndTime(DateTime? time) {
    if (_sleepEndTime == time) return;
    _sleepEndTime = time;
    notifyListeners();
  }

  /// setSleepType
  void setSleepType(String type) {
    if (_sleepType == type) return;
    _sleepType = type;
    notifyListeners();
  }

  // ========================================
  // Computed properties
  // ========================================

  /// Sleep duration (minutes)
  /// Handles midnight crossing correctly (QA-01)
  int get sleepDurationMinutes {
    final end = _sleepEndTime ?? DateTime.now();

    // If end is before start, treat as next day
    DateTime adjustedEnd = end;
    if (end.isBefore(_sleepStartTime)) {
      adjustedEnd = end.add(const Duration(days: 1));
    }

    final duration = adjustedEnd.difference(_sleepStartTime).inMinutes;
    // Prevent negative (abnormal case)
    return duration < 0 ? 0 : duration;
  }

  // ========================================
  // Save
  // ========================================

  /// Save sleep record
  /// C-0.4: Auto-classify sleep type (nap/night) before save
  /// Sprint 20 HF #9-C: Overlap check for past sleep records
  Future<ActivityModel?> saveSleep() async {
    if (!validateBeforeSave()) return null;

    setLoading(true);
    setError(null);
    _sleepOverlapWarning = false;
    notifyListeners();

    try {
      // C-0.4: Auto-classify sleep type using recent patterns
      await _autoClassifySleepType();

      // Sprint 20 HF #9-C: Overlap check (past records with both start/end)
      if (_sleepEndTime != null && selectedBabyIds.isNotEmpty) {
        try {
          final existingActivities = await activityRepository
              .getActivitiesByDateRange(
            familyId!,
            startDate:
                _sleepStartTime.subtract(const Duration(hours: 24)),
            endDate: _sleepEndTime!.add(const Duration(hours: 24)),
            babyId: selectedBabyIds.first,
          );

          final overlapping = existingActivities.where((a) {
            if (a.type != ActivityType.sleep) return false;
            if (a.endTime == null) return false;
            // Time overlap: A.start < B.end && A.end > B.start
            return a.startTime.isBefore(_sleepEndTime!) &&
                a.endTime!.isAfter(_sleepStartTime);
          });

          if (overlapping.isNotEmpty) {
            _sleepOverlapWarning = true;
          }
        } catch (e) {
          debugPrint(
              '[WARN] [SleepRecordProvider] Overlap check failed: $e');
          // Proceed with save even if overlap check fails
        }
      }

      final activity = ActivityModel(
        id: uuid.v4(),
        familyId: familyId!,
        babyIds: List.from(selectedBabyIds),
        type: ActivityType.sleep,
        startTime: _sleepStartTime,
        endTime: _sleepEndTime,
        data: {'sleep_type': _sleepType},
        notes: notes,
        createdAt: DateTime.now(),
      );

      final savedActivity =
          await activityRepository.createActivity(activity);

      debugPrint(
          '[OK] [SleepRecordProvider] Sleep saved: ${savedActivity.id}');
      return savedActivity;
    } catch (e) {
      debugPrint('[ERR] [SleepRecordProvider] Error saving sleep: $e');
      setError('SAVE_FAILED');
      return null;
    } finally {
      setLoading(false);
      notifyListeners();
    }
  }

  // ========================================
  // C-0.4: Auto classification
  // ========================================

  /// Auto-classify sleep type using SleepClassifier
  ///
  /// Fetches recent sleep records and runs pattern-based classification.
  /// Falls back to cold start (21:00~06:00) if insufficient data.
  /// Sets _sleepType internally — no UI interaction needed.
  Future<void> _autoClassifySleepType() async {
    if (familyId == null || selectedBabyIds.isEmpty) return;

    try {
      final recentRecords = await activityRepository.getActivitiesByDateRange(
        familyId!,
        startDate: DateTime.now().subtract(
          Duration(days: SleepClassifier.lookbackDays + 1),
        ),
        endDate: DateTime.now(),
        babyId: selectedBabyIds.first,
        type: ActivityType.sleep,
      );

      _sleepType = SleepClassifier.classify(
        startTime: _sleepStartTime,
        endTime: _sleepEndTime,
        recentSleepRecords: recentRecords,
      );

      debugPrint('[OK] [SleepRecordProvider] Auto-classified sleep type: '
          '$_sleepType (records: ${recentRecords.length})');
    } catch (e) {
      // Fallback to cold start on error
      _sleepType = SleepClassifier.classify(
        startTime: _sleepStartTime,
        endTime: _sleepEndTime,
        recentSleepRecords: const [],
      );
      debugPrint('[WARN] [SleepRecordProvider] Auto-classify failed, '
          'using cold start: $_sleepType ($e)');
    }
  }

  /// Public method for "sleep now" mode — classify before startSleep call
  ///
  /// Called from sleep_record_screen._handleSave() to get classified type
  /// before passing to OngoingSleepProvider.startSleep().
  Future<String> classifySleepType({
    required DateTime startTime,
  }) async {
    if (familyId == null || selectedBabyIds.isEmpty) {
      return SleepClassifier.classify(
        startTime: startTime,
        recentSleepRecords: const [],
      );
    }

    try {
      final recentRecords = await activityRepository.getActivitiesByDateRange(
        familyId!,
        startDate: DateTime.now().subtract(
          Duration(days: SleepClassifier.lookbackDays + 1),
        ),
        endDate: DateTime.now(),
        babyId: selectedBabyIds.first,
        type: ActivityType.sleep,
      );

      final classified = SleepClassifier.classify(
        startTime: startTime,
        recentSleepRecords: recentRecords,
      );

      debugPrint('[OK] [SleepRecordProvider] classifySleepType: '
          '$classified (records: ${recentRecords.length})');
      return classified;
    } catch (e) {
      debugPrint('[WARN] [SleepRecordProvider] classifySleepType failed: $e');
      return SleepClassifier.classify(
        startTime: startTime,
        recentSleepRecords: const [],
      );
    }
  }

  // ========================================
  // MB-02: Cache implementation
  // ========================================

  @override
  void saveCacheForBaby(String babyId) {
    _sleepCache[babyId] = _SleepCache(
      startTime: _sleepStartTime,
      endTime: _sleepEndTime,
      sleepType: _sleepType,
    );
  }

  @override
  void restoreCacheForBaby(String babyId) {
    final cache = _sleepCache[babyId];
    if (cache != null) {
      _sleepStartTime = cache.startTime;
      _sleepEndTime = cache.endTime;
      _sleepType = cache.sleepType;
    }
  }

  // ========================================
  // Lifecycle
  // ========================================

  @override
  void initializeActivityState() {
    _sleepStartTime = DateTime.now();
    _sleepEndTime = null;
    _sleepType = 'nap';
    _sleepOverlapWarning = false;
  }

  @override
  void resetActivityState() {
    initializeActivityState();
    _sleepCache.clear();
  }
}

/// Sleep data cache (MB-02)
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
