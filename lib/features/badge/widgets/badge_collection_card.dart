import 'package:flutter/material.dart';

import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_icons.dart';
import '../../../core/design_system/lulu_radius.dart';
import '../../../core/design_system/lulu_typography.dart';
import '../../../data/models/badge_model.dart';
import '../../../l10n/generated/app_localizations.dart' show S;

/// Single badge card for collection UI.
///
/// Shows unlocked (colored) or locked (greyed out) state.
/// Tapping an unlocked badge shows the replay popup.
class BadgeCollectionCard extends StatelessWidget {
  final BadgeDefinition definition;
  final BadgeAchievement? achievement;
  final VoidCallback? onTap;

  const BadgeCollectionCard({
    super.key,
    required this.definition,
    this.achievement,
    this.onTap,
  });

  bool get isUnlocked => achievement != null;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);

    return GestureDetector(
      onTap: isUnlocked ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUnlocked
              ? LuluColors.surfaceCard
              : LuluColors.surfaceDark,
          borderRadius: LuluRadius.card,
          border: Border.all(
            color: isUnlocked
                ? _getCategoryColor()
                : LuluColors.glassBorder,
            width: isUnlocked ? 1.5 : 0.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Badge icon
            _buildIcon(),
            const SizedBox(height: 8),
            // Title
            Text(
              _getTitle(l10n),
              style: LuluTextStyles.bodySmall.copyWith(
                color: isUnlocked
                    ? Colors.white
                    : LuluColors.softBlue,
                fontWeight: isUnlocked ? FontWeight.w600 : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // Subtitle (description or locked message)
            Text(
              _getSubtitle(l10n),
              style: LuluTextStyles.labelSmall.copyWith(
                color: LuluColors.softBlue,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    final icon = _getCategoryIcon();
    const size = 32.0;

    if (isUnlocked) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _getCategoryColor(),
        ),
        child: Icon(
          icon,
          size: size,
          color: Colors.white,
        ),
      );
    }

    // Locked state
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: LuluColors.surfaceDark,
        border: Border.all(
          color: LuluColors.glassBorder,
          width: 1,
        ),
      ),
      child: Icon(
        LuluIcons.lockOutlined,
        size: 24,
        color: LuluColors.softBlue,
      ),
    );
  }

  IconData _getCategoryIcon() {
    switch (definition.category) {
      case BadgeCategory.feeding:
        return LuluIcons.feeding;
      case BadgeCategory.sleep:
        return LuluIcons.sleep;
      case BadgeCategory.parenting:
        return LuluIcons.trophy;
      case BadgeCategory.growth:
        return LuluIcons.growth;
      case BadgeCategory.preemie:
        return LuluIcons.health;
      case BadgeCategory.multiples:
        return LuluIcons.baby;
    }
  }

  Color _getCategoryColor() {
    switch (definition.category) {
      case BadgeCategory.feeding:
        return LuluActivityColors.feeding;
      case BadgeCategory.sleep:
        return LuluActivityColors.sleep;
      case BadgeCategory.parenting:
        return LuluColors.champagneGold;
      case BadgeCategory.growth:
        return LuluActivityColors.play;
      case BadgeCategory.preemie:
        return LuluActivityColors.health;
      case BadgeCategory.multiples:
        return LuluActivityColors.diaper;
    }
  }

  String _getTitle(S? l10n) {
    if (l10n == null) return definition.key;
    return _resolveKey(l10n, definition.titleKey) ?? definition.key;
  }

  String _getSubtitle(S? l10n) {
    if (!isUnlocked) {
      return l10n?.badgeLocked ?? '';
    }
    return _resolveKey(l10n, definition.descriptionKey) ?? '';
  }

  /// Static i18n key resolver for badge titles and descriptions.
  static String? _resolveKey(S? l10n, String key) {
    if (l10n == null) return null;
    switch (key) {
      // --- Feeding ---
      case 'badgeFirstFeedingTitle': return l10n.badgeFirstFeedingTitle;
      case 'badgeFirstFeedingDesc': return l10n.badgeFirstFeedingDesc;
      case 'badgeFeeding10Title': return l10n.badgeFeeding10Title;
      case 'badgeFeeding10Desc': return l10n.badgeFeeding10Desc;
      case 'badgeFeeding50Title': return l10n.badgeFeeding50Title;
      case 'badgeFeeding50Desc': return l10n.badgeFeeding50Desc;
      case 'badgeMilk1LTitle': return l10n.badgeMilk1LTitle;
      case 'badgeMilk1LDesc': return l10n.badgeMilk1LDesc;
      case 'badgeNightFeedingTitle': return l10n.badgeNightFeedingTitle;
      case 'badgeNightFeedingDesc': return l10n.badgeNightFeedingDesc;

      // --- Sleep ---
      case 'badgeFirstSleepTitle': return l10n.badgeFirstSleepTitle;
      case 'badgeFirstSleepDesc': return l10n.badgeFirstSleepDesc;
      case 'badgeSleep10Title': return l10n.badgeSleep10Title;
      case 'badgeSleep10Desc': return l10n.badgeSleep10Desc;
      case 'badgeSleepThroughTitle': return l10n.badgeSleepThroughTitle;
      case 'badgeSleepThroughDesc': return l10n.badgeSleepThroughDesc;
      case 'badgeSleepRoutineTitle': return l10n.badgeSleepRoutineTitle;
      case 'badgeSleepRoutineDesc': return l10n.badgeSleepRoutineDesc;
      case 'badgeSleepWeekTitle': return l10n.badgeSleepWeekTitle;
      case 'badgeSleepWeekDesc': return l10n.badgeSleepWeekDesc;

      // --- Parenting ---
      case 'badgeFirstRecordTitle': return l10n.badgeFirstRecordTitle;
      case 'badgeFirstRecordDesc': return l10n.badgeFirstRecordDesc;
      case 'badge3DayStreakTitle': return l10n.badge3DayStreakTitle;
      case 'badge3DayStreakDesc': return l10n.badge3DayStreakDesc;
      case 'badge7DayStreakTitle': return l10n.badge7DayStreakTitle;
      case 'badge7DayStreakDesc': return l10n.badge7DayStreakDesc;

      // --- Growth (Badge-1) ---
      case 'badgeDay7Title': return l10n.badgeDay7Title;
      case 'badgeDay7Desc': return l10n.badgeDay7Desc;
      case 'badgeDay100Title': return l10n.badgeDay100Title;
      case 'badgeDay100Desc': return l10n.badgeDay100Desc;
      case 'badgeMonth1Title': return l10n.badgeMonth1Title;
      case 'badgeMonth1Desc': return l10n.badgeMonth1Desc;

      // --- Preemie (Badge-1) ---
      case 'badgeCorrectedTermTitle': return l10n.badgeCorrectedTermTitle;
      case 'badgeCorrectedTermDesc': return l10n.badgeCorrectedTermDesc;

      // --- Multiples (Badge-1) ---
      case 'badgeMultiplesFirstRecordTitle': return l10n.badgeMultiplesFirstRecordTitle;
      case 'badgeMultiplesFirstRecordDesc': return l10n.badgeMultiplesFirstRecordDesc;
      case 'badgeMultiplesAllFedTitle': return l10n.badgeMultiplesAllFedTitle;
      case 'badgeMultiplesAllFedDesc': return l10n.badgeMultiplesAllFedDesc;
      case 'badgeMultiplesAllSleptTitle': return l10n.badgeMultiplesAllSleptTitle;
      case 'badgeMultiplesAllSleptDesc': return l10n.badgeMultiplesAllSleptDesc;

      default: return null;
    }
  }
}
