import 'package:flutter/foundation.dart';

import '../../core/services/supabase_service.dart';
import '../models/badge_model.dart';

/// Badge data repository — Supabase badges table CRUD.
///
/// Follows same pattern as ActivityRepository.
class BadgeRepository {
  /// Get all badges for a family
  Future<List<BadgeAchievement>> getBadgesByFamilyId(String familyId) async {
    try {
      final response = await SupabaseService.badges
          .select()
          .eq('family_id', familyId)
          .order('unlocked_at', ascending: false);

      return (response as List)
          .map((data) => BadgeAchievement.fromJson(data as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[ERR] [BadgeRepository] Error getting badges: $e');
      rethrow;
    }
  }

  /// Get badges for a specific baby
  Future<List<BadgeAchievement>> getBadgesByBabyId(
    String familyId,
    String babyId,
  ) async {
    try {
      final response = await SupabaseService.badges
          .select()
          .eq('family_id', familyId)
          .eq('baby_id', babyId)
          .order('unlocked_at', ascending: false);

      return (response as List)
          .map((data) => BadgeAchievement.fromJson(data as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[ERR] [BadgeRepository] Error getting baby badges: $e');
      rethrow;
    }
  }

  /// Check if a badge already exists (prevents duplicates)
  Future<bool> hasBadge({
    required String familyId,
    required String badgeKey,
    String? babyId,
  }) async {
    try {
      var query = SupabaseService.badges
          .select('id')
          .eq('family_id', familyId)
          .eq('badge_key', badgeKey);

      if (babyId != null) {
        query = query.eq('baby_id', babyId);
      } else {
        query = query.isFilter('baby_id', null);
      }

      final response = await query.maybeSingle();
      return response != null;
    } catch (e) {
      debugPrint('[ERR] [BadgeRepository] Error checking badge: $e');
      return false;
    }
  }

  /// Save a new badge achievement
  ///
  /// Returns null if badge already exists (upsert-safe).
  Future<BadgeAchievement?> saveBadge(BadgeAchievement badge) async {
    try {
      // Check duplicate first (partial unique index may not cover all cases)
      final exists = await hasBadge(
        familyId: badge.familyId,
        badgeKey: badge.badgeKey,
        babyId: badge.babyId,
      );

      if (exists) {
        debugPrint('[INFO] [BadgeRepository] Badge already exists: ${badge.badgeKey}');
        return null;
      }

      final response = await SupabaseService.badges
          .insert(badge.toInsertJson())
          .select()
          .single();

      debugPrint('[OK] [BadgeRepository] Badge saved: ${response['badge_key']}');
      return BadgeAchievement.fromJson(response);
    } catch (e) {
      debugPrint('[ERR] [BadgeRepository] Error saving badge: $e');
      rethrow;
    }
  }

  /// Save multiple badges at once (for import bulk check)
  ///
  /// Skips duplicates silently.
  Future<List<BadgeAchievement>> saveBadges(List<BadgeAchievement> badges) async {
    final List<BadgeAchievement> saved = [];

    for (final badge in badges) {
      try {
        final result = await saveBadge(badge);
        if (result != null) {
          saved.add(result);
        }
      } catch (e) {
        debugPrint('[WARN] [BadgeRepository] Skip badge ${badge.badgeKey}: $e');
      }
    }

    return saved;
  }

  /// Delete a badge (admin use only)
  Future<void> deleteBadge(String badgeId) async {
    try {
      await SupabaseService.badges.delete().eq('id', badgeId);
      debugPrint('[OK] [BadgeRepository] Badge deleted: $badgeId');
    } catch (e) {
      debugPrint('[ERR] [BadgeRepository] Error deleting badge: $e');
      rethrow;
    }
  }
}
