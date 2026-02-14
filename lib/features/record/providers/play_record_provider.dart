import 'package:flutter/foundation.dart';

import '../../../data/models/models.dart';
import 'record_base_provider.dart';

/// Play Record Provider
///
/// Sprint 21 Phase 2-2: RecordProvider 5-way split
/// Handles play-specific state, setters, save.
/// Includes MB-02 baby-specific caching.
class PlayRecordProvider extends RecordBaseProvider {
  // ========================================
  // Play state
  // ========================================

  /// Play type: tummy_time, bath, outdoor, play, reading, other
  String _playType = 'tummy_time';
  String get playType => _playType;

  /// Play duration (minutes) - optional
  int? _playDuration;
  int? get playDuration => _playDuration;

  // ========================================
  // MB-02: Baby-specific cache
  // ========================================

  final Map<String, _PlayCache> _playCache = {};

  // ========================================
  // Play setters
  // ========================================

  /// setPlayType
  void setPlayType(String type) {
    if (_playType == type) return;
    _playType = type;
    notifyListeners();
  }

  /// setPlayDuration (minutes)
  void setPlayDuration(int? minutes) {
    if (_playDuration == minutes) return;
    _playDuration = minutes;
    notifyListeners();
  }

  // ========================================
  // Save
  // ========================================

  /// Save play record
  Future<ActivityModel?> savePlay() async {
    if (!validateBeforeSave()) return null;

    setLoading(true);
    setError(null);
    notifyListeners();

    try {
      final data = <String, dynamic>{
        'play_type': _playType,
      };

      if (_playDuration != null && _playDuration! > 0) {
        data['duration_minutes'] = _playDuration;
      }

      final activity = ActivityModel(
        id: uuid.v4(),
        familyId: familyId!,
        babyIds: List.from(selectedBabyIds),
        type: ActivityType.play,
        startTime: recordTime,
        endTime: _playDuration != null && _playDuration! > 0
            ? recordTime.add(Duration(minutes: _playDuration!))
            : null,
        data: data,
        notes: notes,
        createdAt: DateTime.now(),
      );

      final savedActivity =
          await activityRepository.createActivity(activity);

      debugPrint(
          '[OK] [PlayRecordProvider] Play saved: ${savedActivity.id}');
      return savedActivity;
    } catch (e) {
      debugPrint('[ERR] [PlayRecordProvider] Error saving play: $e');
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
    _playCache[babyId] = _PlayCache(
      type: _playType,
      duration: _playDuration,
    );
  }

  @override
  void restoreCacheForBaby(String babyId) {
    final cache = _playCache[babyId];
    if (cache != null) {
      _playType = cache.type;
      _playDuration = cache.duration;
    }
  }

  // ========================================
  // Lifecycle
  // ========================================

  @override
  void initializeActivityState() {
    _playType = 'tummy_time';
    _playDuration = null;
  }

  @override
  void resetActivityState() {
    initializeActivityState();
    _playCache.clear();
  }
}

/// Play data cache (MB-02)
class _PlayCache {
  final String type;
  final int? duration;

  _PlayCache({
    required this.type,
    this.duration,
  });
}
