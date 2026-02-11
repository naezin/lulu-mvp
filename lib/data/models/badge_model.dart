import 'package:flutter/foundation.dart';

// ============================================
// Badge Enums
// ============================================

/// Badge emotion tier — determines popup style
enum BadgeTier {
  /// Bottom slide-up, 3s auto-dismiss
  normal('normal'),

  /// Center modal, manual dismiss
  warm('warm'),

  /// Fullscreen, forces warm tone
  tearful('tearful');

  final String value;
  const BadgeTier(this.value);

  static BadgeTier fromValue(String value) {
    return BadgeTier.values.firstWhere(
      (e) => e.value == value,
      orElse: () => BadgeTier.normal,
    );
  }
}

/// Badge category for grouping
enum BadgeCategory {
  feeding('feeding'),
  sleep('sleep'),
  parenting('parenting'),
  growth('growth'),
  preemie('preemie'),
  multiples('multiples');

  final String value;
  const BadgeCategory(this.value);

  static BadgeCategory fromValue(String value) {
    return BadgeCategory.values.firstWhere(
      (e) => e.value == value,
      orElse: () => BadgeCategory.parenting,
    );
  }
}

// ============================================
// Badge Definition (static, in-memory)
// ============================================

/// Static badge definition — not stored in DB.
/// Contains metadata for condition checking and display.
@immutable
class BadgeDefinition {
  /// Unique key (e.g. 'first_feeding')
  final String key;

  /// Display name i18n key
  final String titleKey;

  /// Description i18n key
  final String descriptionKey;

  /// Category for grouping
  final BadgeCategory category;

  /// Emotion tier (determines popup style)
  final BadgeTier tier;

  /// Whether this badge is per-baby (true) or per-family (false)
  final bool perBaby;

  /// Sort order for display
  final int sortOrder;

  const BadgeDefinition({
    required this.key,
    required this.titleKey,
    required this.descriptionKey,
    required this.category,
    required this.tier,
    this.perBaby = true,
    this.sortOrder = 0,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BadgeDefinition &&
          runtimeType == other.runtimeType &&
          key == other.key;

  @override
  int get hashCode => key.hashCode;

  @override
  String toString() => 'BadgeDefinition(key: $key, tier: ${tier.value})';
}

// ============================================
// Badge Achievement (DB record)
// ============================================

/// A badge unlocked by a user — stored in Supabase badges table.
@immutable
class BadgeAchievement {
  final String id;
  final String familyId;
  final String? babyId;
  final String badgeKey;
  final BadgeTier tier;
  final DateTime unlockedAt;
  final String? activityId;
  final Map<String, dynamic>? data;
  final DateTime createdAt;

  const BadgeAchievement({
    required this.id,
    required this.familyId,
    this.babyId,
    required this.badgeKey,
    required this.tier,
    required this.unlockedAt,
    this.activityId,
    this.data,
    required this.createdAt,
  });

  factory BadgeAchievement.fromJson(Map<String, dynamic> json) {
    return BadgeAchievement(
      id: json['id'] as String,
      familyId: json['family_id'] as String,
      babyId: json['baby_id'] as String?,
      badgeKey: json['badge_key'] as String,
      tier: BadgeTier.fromValue(json['tier'] as String? ?? 'normal'),
      unlockedAt: DateTime.parse(json['unlocked_at'] as String),
      activityId: json['activity_id'] as String?,
      data: json['data'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'family_id': familyId,
      if (babyId != null) 'baby_id': babyId,
      'badge_key': badgeKey,
      'tier': tier.value,
      'unlocked_at': unlockedAt.toIso8601String(),
      if (activityId != null) 'activity_id': activityId,
      if (data != null) 'data': data,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Create insert payload (no id, no created_at — DB generates)
  Map<String, dynamic> toInsertJson() {
    return {
      'family_id': familyId,
      if (babyId != null) 'baby_id': babyId,
      'badge_key': badgeKey,
      'tier': tier.value,
      'unlocked_at': unlockedAt.toIso8601String(),
      if (activityId != null) 'activity_id': activityId,
      if (data != null) 'data': data,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BadgeAchievement &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'BadgeAchievement(id: $id, key: $badgeKey, baby: $babyId)';
}
