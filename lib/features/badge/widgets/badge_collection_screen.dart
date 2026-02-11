import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_icons.dart';
import '../../../core/design_system/lulu_typography.dart';
import '../../../data/models/badge_model.dart';
import '../../../l10n/generated/app_localizations.dart' show S;
import '../badge_engine.dart';
import '../badge_provider.dart';
import 'badge_collection_card.dart';
import 'badge_popup.dart';

/// Badge collection screen — shows all badges grouped by category.
///
/// Unlocked badges are colored, locked badges are greyed out.
/// Tapping an unlocked badge shows the replay popup.
/// Progress bar at the top shows overall progress.
class BadgeCollectionScreen extends StatefulWidget {
  const BadgeCollectionScreen({super.key});

  @override
  State<BadgeCollectionScreen> createState() => _BadgeCollectionScreenState();
}

class _BadgeCollectionScreenState extends State<BadgeCollectionScreen> {
  @override
  void initState() {
    super.initState();
    // Mark all badges as seen when entering collection
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BadgeProvider>().markAllBadgesSeen();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final badgeProvider = context.watch<BadgeProvider>();
    final allDefinitions = badgeProvider.allBadgeDefinitions;
    final achievements = badgeProvider.achievements;

    // Build lookup map: badgeKey → achievement (first match per key)
    final Map<String, BadgeAchievement> achievementMap = {};
    for (final a in achievements) {
      final key = a.babyId != null ? '${a.badgeKey}:${a.babyId}' : a.badgeKey;
      achievementMap.putIfAbsent(key, () => a);
      // Also put by badgeKey only for non-per-baby lookup
      achievementMap.putIfAbsent(a.badgeKey, () => a);
    }

    // Group definitions by category
    final grouped = <BadgeCategory, List<BadgeDefinition>>{};
    for (final def in allDefinitions) {
      grouped.putIfAbsent(def.category, () => []);
      grouped[def.category]!.add(def);
    }

    // Calculate progress
    final uniqueUnlockedKeys = achievements.map((a) => a.badgeKey).toSet();
    final totalCount = allDefinitions.length;
    final unlockedCount = uniqueUnlockedKeys.length;

    return Scaffold(
      backgroundColor: LuluColors.midnightNavy,
      appBar: AppBar(
        backgroundColor: LuluColors.midnightNavy,
        title: Text(
          l10n?.badgeCollectionTitle ?? 'Badge Collection',
          style: LuluTextStyles.titleMedium.copyWith(color: Colors.white),
        ),
        leading: IconButton(
          icon: Icon(LuluIcons.back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // Progress header
          _buildProgressHeader(l10n, unlockedCount, totalCount),
          const SizedBox(height: 20),

          // Category sections
          for (final category in BadgeCategory.values)
            if (grouped.containsKey(category)) ...[
              _buildCategorySection(
                context,
                l10n,
                category,
                grouped[category]!,
                achievementMap,
              ),
              const SizedBox(height: 16),
            ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildProgressHeader(S? l10n, int unlocked, int total) {
    final progress = total > 0 ? unlocked / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LuluColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: LuluColors.glassBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(LuluIcons.trophy, color: LuluColors.champagneGold, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n?.badgeCollectionProgress(unlocked, total) ??
                      '$unlocked of $total badges earned',
                  style: LuluTextStyles.bodyLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: LuluColors.surfaceElevated,
              valueColor: AlwaysStoppedAnimation<Color>(
                LuluColors.champagneGold,
              ),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(
    BuildContext context,
    S? l10n,
    BadgeCategory category,
    List<BadgeDefinition> definitions,
    Map<String, BadgeAchievement> achievementMap,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category header
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            _getCategoryName(l10n, category),
            style: LuluTextStyles.titleSmall.copyWith(
              color: LuluColors.lavenderMist,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        // Badge grid (3 columns)
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.85,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: definitions.length,
          itemBuilder: (context, index) {
            final def = definitions[index];
            // Find achievement for this badge
            final achievement = achievementMap[def.key];

            return BadgeCollectionCard(
              definition: def,
              achievement: achievement,
              onTap: achievement != null
                  ? () => _showReplayPopup(context, def, achievement)
                  : null,
            );
          },
        ),
      ],
    );
  }

  String _getCategoryName(S? l10n, BadgeCategory category) {
    if (l10n == null) return category.value;
    switch (category) {
      case BadgeCategory.feeding:
        return l10n.badgeCategoryFeeding;
      case BadgeCategory.sleep:
        return l10n.badgeCategorySleep;
      case BadgeCategory.parenting:
        return l10n.badgeCategoryParenting;
      case BadgeCategory.growth:
        return l10n.badgeCategoryGrowth;
      case BadgeCategory.preemie:
        return l10n.badgeCategoryPreemie;
      case BadgeCategory.multiples:
        return l10n.badgeCategoryMultiples;
    }
  }

  /// Show replay popup using showDialog (not Stack overlay)
  void _showReplayPopup(
    BuildContext context,
    BadgeDefinition definition,
    BadgeAchievement achievement,
  ) {
    final candidate = BadgeUnlockCandidate(
      definition: definition,
      babyId: achievement.babyId,
    );

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: BadgePopup(
            candidate: candidate,
            onDismiss: () => Navigator.of(dialogContext).pop(),
          ),
        );
      },
    );
  }
}
