import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/activity_model.dart';
import '../../data/models/baby_model.dart';
import '../../data/models/badge_model.dart';
import '../../data/repositories/badge_repository.dart';
import 'badge_engine.dart';

/// Badge Provider — manages badge state, popup queue, and Supabase sync.
///
/// Performance strategy (#5 approval):
/// - App launch: load all badges + all activities 1 time from Supabase
/// - Memory cache: append new records to cache
/// - Max 2 popups per session
///
/// Badge-1 additions:
/// - Babies cache for time-based + multiples badge checks
/// - Collection UI queries (by category, unseen)
/// - Time-based badge check on init
class BadgeProvider extends ChangeNotifier {
  final BadgeRepository _repository = BadgeRepository();

  // ============================================================
  // State
  // ============================================================

  /// All unlocked badges for this family (cached)
  List<BadgeAchievement> _achievements = [];
  List<BadgeAchievement> get achievements => List.unmodifiable(_achievements);

  /// All activities for this family (cached for badge condition checks)
  List<ActivityModel> _cachedActivities = [];

  /// All babies for this family (cached for time/multiples badge checks)
  List<BabyModel> _cachedBabies = [];
  List<BabyModel> get cachedBabies => List.unmodifiable(_cachedBabies);

  /// Existing badge keys set (for quick lookup)
  Set<String> _existingKeys = {};

  /// Popup queue (max 2 per session, priority: tearful > warm > normal)
  final List<BadgeUnlockCandidate> _popupQueue = [];

  /// Number of popups shown this session
  int _popupsShownThisSession = 0;

  /// Max popups per session
  static const int _maxPopupsPerSession = 2;

  /// Current popup being displayed (null = no popup)
  BadgeUnlockCandidate? _currentPopup;
  BadgeUnlockCandidate? get currentPopup => _currentPopup;

  /// Whether data is loaded
  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  /// Loading state
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Family ID (set during init)
  String? _familyId;

  /// Seen badge keys (persisted via SharedPreferences)
  Set<String> _seenBadgeKeys = {};

  /// SharedPreferences key for seen badges
  static const String _seenBadgesPrefsKey = 'badge_seen_keys';

  // ============================================================
  // Initialization
  // ============================================================

  /// Initialize badge system — call once at app start.
  ///
  /// Loads all badges + all activities from Supabase.
  /// Badge-1: Also accepts babies for time-based + multiples checks.
  Future<void> init({
    required String familyId,
    required List<ActivityModel> activities,
    required List<BabyModel> babies,
  }) async {
    if (_isLoaded && _familyId == familyId) return;

    _familyId = familyId;
    _isLoading = true;
    notifyListeners();

    try {
      _achievements = await _repository.getBadgesByFamilyId(familyId);
      _existingKeys = BadgeEngine.buildExistingKeys(_achievements);
      _cachedActivities = List.from(activities);
      _cachedBabies = List.from(babies);

      // Load seen badge keys from local storage
      await _loadSeenBadgeKeys();

      _isLoaded = true;

      debugPrint('[OK] [BadgeProvider] Loaded ${_achievements.length} badges, '
          '${_cachedActivities.length} activities, '
          '${_cachedBabies.length} babies');

      // Check time-based + multiples badges on init
      await _checkTimeAndMultiplesBadges();
    } catch (e) {
      debugPrint('[ERR] [BadgeProvider] Init failed: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============================================================
  // Activity handling (called from HomeProvider)
  // ============================================================

  /// Check and unlock badges after a new activity is saved.
  ///
  /// Called by HomeProvider.addActivity().
  Future<void> onActivitySaved(ActivityModel activity) async {
    if (!_isLoaded || _familyId == null) return;

    // Append to cache
    _cachedActivities = [..._cachedActivities, activity];

    // Run badge engine
    final candidates = BadgeEngine.check(
      activity: activity,
      allActivities: _cachedActivities,
      existingBadgeKeys: _existingKeys,
    );

    if (candidates.isEmpty) return;

    debugPrint('[INFO] [BadgeProvider] ${candidates.length} badge(s) unlocked');

    // Save to Supabase + update cache
    for (final candidate in candidates) {
      await _saveBadge(candidate, activity.id);
    }

    // Queue popups (with session limit)
    _queuePopups(candidates);
  }

  /// Bulk check after import (silent — no popups).
  Future<void> onBulkImport(List<ActivityModel> importedActivities) async {
    if (!_isLoaded || _familyId == null) return;

    // Append to cache
    _cachedActivities = [..._cachedActivities, ...importedActivities];

    // Run bulk check
    final candidates = BadgeEngine.checkBulk(
      allActivities: _cachedActivities,
      existingBadgeKeys: _existingKeys,
    );

    if (candidates.isEmpty) return;

    debugPrint('[INFO] [BadgeProvider] Bulk import: ${candidates.length} badge(s) unlocked');

    // Save all silently (no popups)
    for (final candidate in candidates) {
      await _saveBadge(candidate, null);
    }
  }

  // ============================================================
  // Time-based + Multiples badge checks (Badge-1)
  // ============================================================

  /// Check time-based and multiples badges.
  ///
  /// Called during init and can be called periodically.
  /// These badges depend on baby metadata, not activity events.
  Future<void> _checkTimeAndMultiplesBadges() async {
    if (_cachedBabies.isEmpty || _familyId == null) return;

    final candidates = BadgeEngine.checkTimeAndMultiples(
      babies: _cachedBabies,
      allActivities: _cachedActivities,
      existingBadgeKeys: _existingKeys,
    );

    if (candidates.isEmpty) return;

    debugPrint(
        '[INFO] [BadgeProvider] Time/multiples: ${candidates.length} badge(s) unlocked');

    for (final candidate in candidates) {
      await _saveBadge(candidate, null);
    }

    // Queue popups for time/multiples badges too
    _queuePopups(candidates);
  }

  // ============================================================
  // Popup management
  // ============================================================

  /// Dismiss current popup and show next in queue.
  void dismissPopup() {
    _currentPopup = null;
    notifyListeners();

    // Show next in queue if available
    _showNextPopup();
  }

  /// Show next popup from queue (if under session limit).
  void _showNextPopup() {
    if (_popupQueue.isEmpty) return;
    if (_popupsShownThisSession >= _maxPopupsPerSession) {
      _popupQueue.clear();
      return;
    }

    _currentPopup = _popupQueue.removeAt(0);
    _popupsShownThisSession++;
    HapticFeedback.mediumImpact();
    notifyListeners();
  }

  /// Queue candidates for popup display.
  void _queuePopups(List<BadgeUnlockCandidate> candidates) {
    if (_popupsShownThisSession >= _maxPopupsPerSession) return;

    // Sort by priority: tearful > warm > normal
    final sorted = List<BadgeUnlockCandidate>.from(candidates)
      ..sort((a, b) => _tierPriority(b.definition.tier)
          .compareTo(_tierPriority(a.definition.tier)));

    _popupQueue.addAll(sorted);

    // If no popup currently showing, start showing
    if (_currentPopup == null) {
      _showNextPopup();
    }
  }

  /// Tier priority for sorting
  static int _tierPriority(BadgeTier tier) {
    switch (tier) {
      case BadgeTier.tearful:
        return 3;
      case BadgeTier.warm:
        return 2;
      case BadgeTier.normal:
        return 1;
    }
  }

  // ============================================================
  // Persistence
  // ============================================================

  /// Save a single badge to Supabase and update local cache.
  Future<void> _saveBadge(
    BadgeUnlockCandidate candidate,
    String? activityId,
  ) async {
    final achievement = BadgeAchievement(
      id: '', // DB generates
      familyId: _familyId!,
      babyId: candidate.babyId,
      badgeKey: candidate.definition.key,
      tier: candidate.definition.tier,
      unlockedAt: DateTime.now().toUtc(),
      activityId: activityId,
      createdAt: DateTime.now().toUtc(),
    );

    try {
      final saved = await _repository.saveBadge(achievement);
      if (saved != null) {
        _achievements = [..._achievements, saved];
        final compositeKey = BadgeEngine.buildExistingKeys([saved]);
        _existingKeys = {..._existingKeys, ...compositeKey};
        debugPrint('[OK] [BadgeProvider] Badge saved: ${candidate.definition.key}');
      }
    } catch (e) {
      debugPrint('[ERR] [BadgeProvider] Failed to save badge: $e');
    }
  }

  // ============================================================
  // Seen/Unseen management (Badge-1)
  // ============================================================

  /// Load seen badge keys from SharedPreferences
  Future<void> _loadSeenBadgeKeys() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getStringList(_seenBadgesPrefsKey);
      if (keys != null) {
        _seenBadgeKeys = keys.toSet();
      }
    } catch (e) {
      debugPrint('[WARN] [BadgeProvider] Failed to load seen keys: $e');
    }
  }

  /// Mark all current badges as seen
  Future<void> markAllBadgesSeen() async {
    final allKeys = _achievements.map((a) {
      return a.babyId != null ? '${a.badgeKey}:${a.babyId}' : a.badgeKey;
    }).toSet();

    _seenBadgeKeys = {..._seenBadgeKeys, ...allKeys};

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_seenBadgesPrefsKey, _seenBadgeKeys.toList());
    } catch (e) {
      debugPrint('[WARN] [BadgeProvider] Failed to save seen keys: $e');
    }

    notifyListeners();
  }

  /// Whether there are unseen badges
  bool get hasUnseenBadges {
    for (final achievement in _achievements) {
      final key = achievement.babyId != null
          ? '${achievement.badgeKey}:${achievement.babyId}'
          : achievement.badgeKey;
      if (!_seenBadgeKeys.contains(key)) return true;
    }
    return false;
  }

  /// Count of unseen badges
  int get unseenBadgeCount {
    int count = 0;
    for (final achievement in _achievements) {
      final key = achievement.babyId != null
          ? '${achievement.badgeKey}:${achievement.babyId}'
          : achievement.badgeKey;
      if (!_seenBadgeKeys.contains(key)) count++;
    }
    return count;
  }

  // ============================================================
  // Queries
  // ============================================================

  /// Check if a specific badge is unlocked
  bool hasBadge(String badgeKey, {String? babyId}) {
    final key = babyId != null ? '$badgeKey:$babyId' : badgeKey;
    return _existingKeys.contains(key);
  }

  /// Get all unlocked badges for a specific baby
  List<BadgeAchievement> getBadgesForBaby(String babyId) {
    return _achievements.where((a) => a.babyId == babyId).toList();
  }

  /// Get all family-level badges
  List<BadgeAchievement> get familyBadges {
    return _achievements.where((a) => a.babyId == null).toList();
  }

  /// Total badge count
  int get totalBadgeCount => _achievements.length;

  /// Get achievements grouped by category
  Map<BadgeCategory, List<BadgeAchievement>> get achievementsByCategory {
    final Map<BadgeCategory, List<BadgeAchievement>> result = {};
    for (final achievement in _achievements) {
      final definition = BadgeEngine.getDefinition(achievement.badgeKey);
      if (definition != null) {
        final category = definition.category;
        result.putIfAbsent(category, () => []);
        result[category]!.add(achievement);
      }
    }
    return result;
  }

  /// Get all badge definitions (for collection UI — shows locked + unlocked)
  List<BadgeDefinition> get allBadgeDefinitions => BadgeEngine.allBadges;

  /// Get total possible badge count
  int get totalPossibleBadgeCount => BadgeEngine.allBadges.length;

  /// Get unlock progress as fraction (0.0 ~ 1.0)
  double get unlockProgress {
    if (BadgeEngine.allBadges.isEmpty) return 0.0;
    // Count unique badge keys (not per-baby duplicates)
    final uniqueUnlockedKeys = _achievements.map((a) => a.badgeKey).toSet();
    return uniqueUnlockedKeys.length / BadgeEngine.allBadges.length;
  }

  /// Reset (for testing or logout)
  void reset() {
    _achievements = [];
    _cachedActivities = [];
    _cachedBabies = [];
    _existingKeys = {};
    _popupQueue.clear();
    _popupsShownThisSession = 0;
    _currentPopup = null;
    _isLoaded = false;
    _familyId = null;
    _seenBadgeKeys = {};
    notifyListeners();
  }
}
