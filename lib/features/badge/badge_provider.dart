import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../data/models/activity_model.dart';
import '../../data/models/badge_model.dart';
import '../../data/repositories/badge_repository.dart';
import 'badge_engine.dart';

/// Badge Provider — manages badge state, popup queue, and Supabase sync.
///
/// Performance strategy (#5 approval):
/// - App launch: load all badges + all activities 1 time from Supabase
/// - Memory cache: append new records to cache
/// - Max 2 popups per session
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

  // ============================================================
  // Initialization
  // ============================================================

  /// Initialize badge system — call once at app start.
  ///
  /// Loads all badges + all activities from Supabase.
  Future<void> init({
    required String familyId,
    required List<ActivityModel> activities,
  }) async {
    if (_isLoaded && _familyId == familyId) return;

    _familyId = familyId;
    _isLoading = true;
    notifyListeners();

    try {
      _achievements = await _repository.getBadgesByFamilyId(familyId);
      _existingKeys = BadgeEngine.buildExistingKeys(_achievements);
      _cachedActivities = List.from(activities);
      _isLoaded = true;

      debugPrint('[OK] [BadgeProvider] Loaded ${_achievements.length} badges, '
          '${_cachedActivities.length} activities');
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

  /// Reset (for testing or logout)
  void reset() {
    _achievements = [];
    _cachedActivities = [];
    _existingKeys = {};
    _popupQueue.clear();
    _popupsShownThisSession = 0;
    _currentPopup = null;
    _isLoaded = false;
    _familyId = null;
    notifyListeners();
  }
}
