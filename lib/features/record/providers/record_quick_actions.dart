// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member

part of 'record_provider.dart';

/// RecordProvider - Quick Actions & Cache
///
/// Recent feedings, quick save, undo, and baby-specific
/// data cache classes. Uses `part of` + extension pattern
/// to maintain private field access within the same library.

extension RecordQuickActions on RecordProvider {
  // ========================================
  // HOTFIX v1.2: Quick feeding (recent 3 buttons)
  // ========================================

  /// Load recent feeding records
  /// Returns up to 3 deduplicated recent feedings per baby
  ///
  /// BUGFIX v5.3: Clear immediately on baby tab switch
  /// to prevent stale data display
  Future<void> loadRecentFeedings(String babyId) async {
    // Clear immediately + store babyId for race condition prevention
    _currentFeedingBabyId = babyId;
    _recentFeedings = [];
    notifyListeners();

    debugPrint('[LOAD] loadRecentFeedings started for babyId: $babyId');

    try {
      // BUG-DATA-01 FIX: Supabase only (local storage removed)
      List<ActivityModel> activities = [];
      try {
        activities = await _activityRepository.getActivitiesByBabyId(
          babyId,
          limit: 20,
        );
        debugPrint('[SUPABASE] activities for babyId $babyId: ${activities.length}');
      } catch (e) {
        debugPrint('[WARN] Supabase fetch failed: $e');
      }

      // Race condition check
      if (_currentFeedingBabyId != babyId) {
        debugPrint('[WARN] babyId changed during loading, discarding results');
        return;
      }

      final allActivities = activities
        ..sort((a, b) => b.startTime.compareTo(a.startTime));

      debugPrint('[DATA] Activities for babyId $babyId: ${allActivities.length}');

      // Strict filtering (single baby only)
      final strictFiltered = allActivities.where((a) {
        final isSingleBabyMatch =
            a.babyIds.length == 1 && a.babyIds[0] == babyId;
        return isSingleBabyMatch;
      }).toList();
      debugPrint('[FILTER] Strict filtered for $babyId: ${strictFiltered.length}');

      // Feeding records only
      final feedingActivities = strictFiltered
          .where((a) => a.type == ActivityType.feeding)
          .toList();
      debugPrint('[FEEDING] activities count: ${feedingActivities.length}');

      // Deduplicate (feeding_type + breast_side + amount_ml)
      final seen = <String>{};
      final unique = <ActivityModel>[];

      for (final activity in feedingActivities) {
        final key = _buildFeedingKeyInternal(activity);
        if (!seen.contains(key)) {
          seen.add(key);
          unique.add(activity);
        }
        if (unique.length >= 3) break;
      }

      // Final babyId check before state update
      if (_currentFeedingBabyId == babyId) {
        _recentFeedings = unique;
        debugPrint('[OK] Updated _recentFeedings: ${_recentFeedings.length} items');
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
      debugPrint('[WARN] [RecordProvider] Quick save blocked (double tap)');
      return null;
    }
    _lastQuickSaveTime = now;

    if (_familyId == null || selectedBabyId == null) {
      _errorMessage = 'errorSelectBaby';
      notifyListeners();
      return null;
    }

    try {
      final newActivity = template.copyWith(
        id: _uuid.v4(),
        babyIds: [selectedBabyId!],
        startTime: now,
        endTime: now,
        createdAt: now,
      );

      final saved = await _activityRepository.createActivity(newActivity);
      _lastSavedId = saved.id;

      debugPrint('[OK] [RecordProvider] Quick feeding saved to Supabase: ${saved.id}');

      // Refresh recent records
      await loadRecentFeedings(selectedBabyId!);

      return saved.id;
    } catch (e) {
      _errorMessage = 'errorSaveFailed:$e';
      debugPrint('[ERROR] [RecordProvider] Error quick save feeding: $e');
      notifyListeners();
      return null;
    }
  }

  /// Undo last save
  Future<bool> undoLastSave() async {
    if (_lastSavedId == null) return false;

    try {
      await _activityRepository.deleteActivity(_lastSavedId!);
      debugPrint('[OK] [RecordProvider] Undo from Supabase: $_lastSavedId');

      _lastSavedId = null;

      // Refresh recent records
      if (selectedBabyId != null) {
        await loadRecentFeedings(selectedBabyId!);
      }

      return true;
    } catch (e) {
      debugPrint('[ERROR] [RecordProvider] Error undo: $e');
      return false;
    }
  }
}

// ========================================
// Internal helper (library-private)
// ========================================

/// Build feeding key for deduplication
/// Separate top-level function to avoid extension method name conflicts
String _buildFeedingKeyInternal(ActivityModel activity) {
  final data = activity.data;
  if (data == null) return activity.id;

  final type = data['feeding_type'] as String? ?? 'bottle';
  final side = data['breast_side'] as String? ?? '';
  final amount = data['amount_ml']?.toString() ?? '';
  final duration = data['duration_minutes']?.toString() ?? '';

  return '$type|$side|$amount|$duration';
}

// ========================================
// MB-02: Baby-specific data cache classes
// ========================================

/// Feeding data cache
class RecordFeedingCache {
  final String type;
  final double amount;
  final int duration;
  final String breastSide;

  RecordFeedingCache({
    required this.type,
    required this.amount,
    required this.duration,
    required this.breastSide,
  });
}

/// Sleep data cache
class RecordSleepCache {
  final DateTime startTime;
  final DateTime? endTime;
  final String sleepType;

  RecordSleepCache({
    required this.startTime,
    this.endTime,
    required this.sleepType,
  });
}

/// Diaper data cache
class RecordDiaperCache {
  final String type;
  final String? stoolColor;

  RecordDiaperCache({
    required this.type,
    this.stoolColor,
  });
}

/// Play data cache
class RecordPlayCache {
  final String type;
  final int? duration;

  RecordPlayCache({
    required this.type,
    this.duration,
  });
}

/// Health data cache
class RecordHealthCache {
  final String type;
  final double? temperature;
  final List<String> symptoms;
  final String? medication;
  final String? hospitalVisit;

  RecordHealthCache({
    required this.type,
    this.temperature,
    required this.symptoms,
    this.medication,
    this.hospitalVisit,
  });
}
