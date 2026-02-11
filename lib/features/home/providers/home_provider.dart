import 'package:flutter/material.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/activity_repository.dart';
import '../../../data/repositories/baby_repository.dart';
import '../../../data/repositories/family_repository.dart';
import '../../badge/badge_provider.dart';
import 'sweet_spot_provider.dart';

/// Home screen state management Provider
///
/// Sprint 21 Phase 2-3: SweetSpot extracted to SweetSpotProvider
/// - Family/babies/selection management
/// - Today's activity CRUD + filtered cache
/// - Summary counts (feeding, sleep, diaper)
/// - Single-direction SweetSpot notification via _sweetSpotProvider
///
/// BUG-002 FIX: All activity getters filter by selectedBabyId
class HomeProvider extends ChangeNotifier {
  // ========================================
  // SweetSpotProvider reference (single-direction)
  // ========================================

  SweetSpotProvider? _sweetSpotProvider;
  BadgeProvider? _badgeProvider;

  /// Set SweetSpotProvider reference for single-direction notification
  void setSweetSpotProvider(SweetSpotProvider provider) {
    _sweetSpotProvider = provider;
  }

  /// Set BadgeProvider reference for badge check after activity save
  void setBadgeProvider(BadgeProvider provider) {
    _badgeProvider = provider;
  }

  // ========================================
  // State
  // ========================================

  /// Current family
  FamilyModel? _family;
  FamilyModel? get family => _family;

  /// Current family's babies
  List<BabyModel> _babies = [];
  List<BabyModel> get babies => List.unmodifiable(_babies);

  /// Selected baby ID (null = all)
  String? _selectedBabyId;
  String? get selectedBabyId => _selectedBabyId;

  /// Selected baby (null defaults to first baby)
  BabyModel? get selectedBaby {
    if (_selectedBabyId == null && _babies.isNotEmpty) {
      return _babies.first;
    }
    return _babies.where((b) => b.id == _selectedBabyId).firstOrNull;
  }

  /// All babies selected flag
  bool get isAllSelected => _selectedBabyId == null;

  /// Today's activities (all - internal)
  List<ActivityModel> _todayActivities = [];

  /// Today's activities (all - external access, backward compatibility)
  List<ActivityModel> get todayActivities => List.unmodifiable(_todayActivities);

  // ========================================
  // BUG-002 FIX: Filtered activities by selected baby
  // ========================================

  /// Cached filtered activities (performance optimization)
  List<ActivityModel>? _cachedFilteredActivities;
  String? _cachedFilterBabyId;

  /// Return today's activities filtered by selected baby
  ///
  /// - selectedBabyId null → return all activities
  /// - selectedBabyId set → filter to that baby only
  /// - Same condition → return cached result (performance)
  List<ActivityModel> get filteredTodayActivities {
    if (_cachedFilteredActivities != null &&
        _cachedFilterBabyId == _selectedBabyId) {
      return _cachedFilteredActivities!;
    }

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

  /// Invalidate cache
  void _invalidateCache() {
    _cachedFilteredActivities = null;
    _cachedFilterBabyId = null;
  }

  /// Loading state
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Error message
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Sprint 19: Whether any records exist ever (new user detection)
  bool _hasAnyRecordsEver = true; // default true (prevent flash)
  bool get hasAnyRecordsEver => _hasAnyRecordsEver;

  // ========================================
  // Today summary (BUG-002 FIX: filtered)
  // ========================================

  /// Today's feeding count (selected baby only)
  int get todayFeedingCount {
    return filteredTodayActivities
        .where((a) => a.type == ActivityType.feeding)
        .length;
  }

  /// Today's total sleep minutes (selected baby only)
  /// Handles midnight-crossing sleep correctly (QA-01)
  int get todaySleepMinutes {
    final sleepActivities = filteredTodayActivities.where(
      (a) => a.type == ActivityType.sleep && a.endTime != null,
    );

    int totalMinutes = 0;
    for (final activity in sleepActivities) {
      totalMinutes += activity.durationMinutes ?? 0;
    }
    return totalMinutes;
  }

  /// Today's sleep duration string (e.g. "8h 30m")
  String get todaySleepDuration {
    final hours = todaySleepMinutes ~/ 60;
    final minutes = todaySleepMinutes % 60;
    if (hours == 0) return '${minutes}m';
    if (minutes == 0) return '${hours}h';
    return '${hours}h ${minutes}m';
  }

  /// Today's diaper count (selected baby only)
  int get todayDiaperCount {
    return filteredTodayActivities
        .where((a) => a.type == ActivityType.diaper)
        .length;
  }

  /// Last feeding activity (selected baby only)
  ActivityModel? get lastFeeding {
    final feedings = filteredTodayActivities
        .where((a) => a.type == ActivityType.feeding)
        .toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
    return feedings.firstOrNull;
  }

  /// Last sleep activity (selected baby only)
  ActivityModel? get lastSleep {
    final sleeps = filteredTodayActivities
        .where((a) => a.type == ActivityType.sleep)
        .toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
    return sleeps.firstOrNull;
  }

  /// Last diaper activity (selected baby only)
  ActivityModel? get lastDiaper {
    final diapers = filteredTodayActivities
        .where((a) => a.type == ActivityType.diaper)
        .toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
    return diapers.firstOrNull;
  }

  // ========================================
  // Last activity times (DateTime) - for LastActivityRow
  // ========================================

  /// Last sleep time (DateTime)
  DateTime? get lastSleepTime => lastSleep?.endTime ?? lastSleep?.startTime;

  /// Last feeding time (DateTime)
  DateTime? get lastFeedingTime => lastFeeding?.startTime;

  /// Last diaper time (DateTime)
  DateTime? get lastDiaperTime => lastDiaper?.startTime;

  // ========================================
  // Methods
  // ========================================

  /// Set family and babies (BUG-001 fix)
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

  /// Set babies list (backward compatibility)
  void setBabies(List<BabyModel> babies) {
    _babies = babies;
    if (_selectedBabyId != null && !babies.any((b) => b.id == _selectedBabyId)) {
      _selectedBabyId = null;
    }
    notifyListeners();
  }

  /// Select baby
  ///
  /// BUG-002 NOTE: On baby switch, filteredTodayActivities auto-filters
  /// by the new selectedBabyId
  void selectBaby(String? babyId) {
    if (_selectedBabyId == babyId) return;
    _selectedBabyId = babyId;
    _invalidateCache();
    _notifySweetSpot();
    debugPrint('[OK] [HomeProvider] Baby selected: $babyId, filtered activities: ${filteredTodayActivities.length}');
    notifyListeners();
  }

  /// Set today's activities
  void setTodayActivities(List<ActivityModel> activities) {
    _todayActivities = activities;
    _invalidateCache();
    _notifySweetSpot();
    debugPrint('[OK] [HomeProvider] Activities set: ${activities.length} total, ${filteredTodayActivities.length} for selected baby');
    notifyListeners();
  }

  /// Add activity
  void addActivity(ActivityModel activity) {
    _todayActivities = [..._todayActivities, activity];
    _invalidateCache();
    _notifySweetSpot();
    _notifyBadge(activity);
    debugPrint('[OK] [HomeProvider] Activity added: ${activity.type}, babyIds: ${activity.babyIds}');
    notifyListeners();
  }

  /// Remove activity
  void removeActivity(String activityId) {
    _todayActivities = _todayActivities
        .where((a) => a.id != activityId)
        .toList();
    _invalidateCache();
    _notifySweetSpot();
    notifyListeners();
  }

  /// Update activity
  void updateActivity(ActivityModel updatedActivity) {
    _todayActivities = _todayActivities.map((a) {
      return a.id == updatedActivity.id ? updatedActivity : a;
    }).toList();
    _invalidateCache();
    _notifySweetSpot();
    notifyListeners();
  }

  /// Notify SweetSpotProvider with current data (single-direction flow)
  void _notifySweetSpot() {
    final lastSleepActivity = lastSleep;
    final baby = selectedBaby;

    // Count today's completed sleep records for calibration
    final completedSleepCount = filteredTodayActivities
        .where((a) => a.type == ActivityType.sleep && a.endTime != null)
        .length;

    _sweetSpotProvider?.recalculate(
      lastSleepEndTime: lastSleepActivity?.endTime ?? lastSleepActivity?.startTime,
      babyAgeInMonths: baby?.effectiveAgeInMonths,
      completedSleepRecords: completedSleepCount,
    );
  }

  /// Notify BadgeProvider to check for new badge unlocks
  void _notifyBadge(ActivityModel activity) {
    _badgeProvider?.onActivitySaved(activity);
  }

  /// Refresh data from Supabase
  ///
  /// QA FIX: Real Supabase data loading
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

      final activities = await activityRepo.getTodayActivities(_family!.id);
      _todayActivities = activities;
      _invalidateCache();

      debugPrint('[OK] [HomeProvider] Refreshed: ${activities.length} activities loaded');

      _notifySweetSpot();
    } catch (e) {
      _errorMessage = 'Failed to load data: $e';
      debugPrint('[ERR] [HomeProvider] Refresh error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load today's activities (called after family is set)
  ///
  /// Sprint 19: Also checks hasAnyRecordsEver
  Future<void> loadTodayActivities() async {
    if (_family == null) {
      debugPrint('[WARN] [HomeProvider] Cannot load activities: family not set');
      return;
    }

    try {
      final activityRepo = ActivityRepository();

      // Sprint 19: Check total records existence in parallel
      final results = await Future.wait([
        activityRepo.getTodayActivities(_family!.id),
        activityRepo.hasAnyActivities(_family!.id),
      ]);

      final activities = results[0] as List<ActivityModel>;
      final hasAny = results[1] as bool;

      _todayActivities = activities;
      _hasAnyRecordsEver = hasAny;
      _invalidateCache();
      _notifySweetSpot();

      debugPrint('[OK] [HomeProvider] Today activities loaded: ${activities.length}, hasAnyRecordsEver: $hasAny');
      notifyListeners();
    } catch (e) {
      debugPrint('[ERR] [HomeProvider] Error loading activities: $e');
      _errorMessage = 'Failed to load activity data';
      notifyListeners();
    }
  }

  /// Reset all state
  void reset() {
    _family = null;
    _babies = [];
    _selectedBabyId = null;
    _todayActivities = [];
    _isLoading = false;
    _errorMessage = null;
    _hasAnyRecordsEver = true;
    _invalidateCache();
    _sweetSpotProvider?.reset();
    debugPrint('[OK] [HomeProvider] Reset complete');
    notifyListeners();
  }

  /// Handle family change (Family Sharing)
  ///
  /// Called when joining a new family or family changes.
  /// Reloads family info and activity data.
  Future<void> onFamilyChanged(String newFamilyId) async {
    debugPrint('[INFO] [HomeProvider] Family changed to: $newFamilyId');

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final familyRepo = FamilyRepository();
      final family = await familyRepo.getFamilyById(newFamilyId);

      if (family != null) {
        final babyRepo = BabyRepository();
        final babies = await babyRepo.getBabiesByFamilyId(newFamilyId);
        setFamily(family, babies);
      }

      await refresh();

      debugPrint('[OK] [HomeProvider] Family data reloaded for: $newFamilyId');
    } catch (e) {
      _errorMessage = 'Failed to load family data: $e';
      debugPrint('[ERR] [HomeProvider] Family change error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
