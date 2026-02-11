import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_icons.dart';
import '../../../core/design_system/lulu_typography.dart';
import '../../../data/models/badge_model.dart';
import '../../../l10n/generated/app_localizations.dart' show S;
import '../badge_engine.dart';

/// Badge popup overlay — 3 tiers of presentation.
///
/// - normal: bottom slide-up, 3s auto-dismiss
/// - warm: center modal, manual dismiss
/// - tearful: fullscreen, forces warm tone
class BadgePopup extends StatefulWidget {
  final BadgeUnlockCandidate candidate;
  final VoidCallback onDismiss;

  const BadgePopup({
    super.key,
    required this.candidate,
    required this.onDismiss,
  });

  @override
  State<BadgePopup> createState() => _BadgePopupState();
}

class _BadgePopupState extends State<BadgePopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  Timer? _autoDismissTimer;

  BadgeTier get _tier => widget.candidate.definition.tier;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: _tier == BadgeTier.normal
          ? const Offset(0, 1) // slide up from bottom
          : const Offset(0, 0.1), // slight slide for center/fullscreen
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _controller.forward();

    // Auto-dismiss for normal tier only
    if (_tier == BadgeTier.normal) {
      _autoDismissTimer = Timer(const Duration(seconds: 3), _dismiss);
    }
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() {
    _controller.reverse().then((_) {
      if (mounted) {
        widget.onDismiss();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (_tier) {
      case BadgeTier.normal:
        return _buildNormalPopup(context);
      case BadgeTier.warm:
        return _buildWarmPopup(context);
      case BadgeTier.tearful:
        return _buildTearfulPopup(context);
    }
  }

  // ============================================================
  // Normal: bottom slide-up, 3s auto-dismiss
  // ============================================================

  Widget _buildNormalPopup(BuildContext context) {
    final l10n = S.of(context);
    final definition = widget.candidate.definition;

    return Positioned(
      left: 16,
      right: 16,
      bottom: MediaQuery.of(context).padding.bottom + 80,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: _dismiss,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: LuluColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: LuluColors.champagneGold),
                  boxShadow: const [
                    BoxShadow(
                      color: LuluColors.shadowBlack,
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    _buildBadgeIcon(36),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l10n?.badgeUnlocked ?? 'Badge Unlocked!',
                            style: LuluTextStyles.caption.copyWith(
                              color: LuluColors.champagneGold,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _getTitle(l10n, definition),
                            style: LuluTextStyles.bodyMedium.copyWith(
                              color: LuluTextColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      LuluIcons.trophy,
                      color: LuluColors.champagneGold,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // Warm: center modal, manual dismiss
  // ============================================================

  Widget _buildWarmPopup(BuildContext context) {
    final l10n = S.of(context);
    final definition = widget.candidate.definition;

    return Center(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: LuluColors.surfaceCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: LuluColors.champagneGold,
                  width: 1.5,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: LuluColors.shadowBlack,
                    blurRadius: 24,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildBadgeIcon(56),
                  const SizedBox(height: 16),
                  Text(
                    l10n?.badgeUnlocked ?? 'Badge Unlocked!',
                    style: LuluTextStyles.caption.copyWith(
                      color: LuluColors.champagneGold,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getTitle(l10n, definition),
                    style: LuluTextStyles.titleMedium.copyWith(
                      color: LuluTextColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getDescription(l10n, definition),
                    style: LuluTextStyles.bodyMedium.copyWith(
                      color: LuluTextColors.secondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: _dismiss,
                      style: TextButton.styleFrom(
                        backgroundColor: LuluColors.champagneGoldLight,
                        foregroundColor: LuluColors.champagneGold,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        l10n?.badgeDismiss ?? 'OK',
                        style: LuluTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // Tearful: fullscreen, forces warm tone
  // ============================================================

  Widget _buildTearfulPopup(BuildContext context) {
    final l10n = S.of(context);
    final definition = widget.candidate.definition;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Material(
        color: LuluColors.midnightNavy,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                _buildBadgeIcon(80),
                const SizedBox(height: 24),
                Text(
                  l10n?.badgeUnlocked ?? 'Badge Unlocked!',
                  style: LuluTextStyles.caption.copyWith(
                    color: LuluColors.champagneGold,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _getTitle(l10n, definition),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: LuluTextColors.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                // Tearful always uses warm tone message
                Text(
                  _getWarmMessage(l10n, definition),
                  style: LuluTextStyles.bodyLarge.copyWith(
                    color: LuluTextColors.secondary,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _dismiss,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: LuluColors.champagneGold,
                      foregroundColor: LuluColors.midnightNavy,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      l10n?.badgeDismiss ?? 'OK',
                      style: LuluTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: LuluColors.midnightNavy,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // Shared helpers
  // ============================================================

  Widget _buildBadgeIcon(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: LuluColors.champagneGoldLight,
        border: Border.all(
          color: LuluColors.champagneGold,
          width: 2,
        ),
      ),
      child: Icon(
        _getCategoryIcon(),
        size: size * 0.45,
        color: LuluColors.champagneGold,
      ),
    );
  }

  IconData _getCategoryIcon() {
    switch (widget.candidate.definition.category) {
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

  /// Get localized title from definition's titleKey
  String _getTitle(S? l10n, BadgeDefinition definition) {
    if (l10n == null) return definition.key;
    return _resolveI18nKey(l10n, definition.titleKey) ?? definition.key;
  }

  /// Get localized description from definition's descriptionKey
  String _getDescription(S? l10n, BadgeDefinition definition) {
    if (l10n == null) return '';
    return _resolveI18nKey(l10n, definition.descriptionKey) ?? '';
  }

  /// Get warm tone message (for tearful tier)
  String _getWarmMessage(S? l10n, BadgeDefinition definition) {
    if (l10n == null) return '';
    // Map badge key → warm i18n key
    final warmKey = '${definition.titleKey.replaceAll('Title', '')}Warm';
    return _resolveI18nKey(l10n, warmKey) ?? _getDescription(l10n, definition);
  }

  /// Resolve i18n key dynamically.
  ///
  /// Since Dart ARB doesn't support dynamic key lookup natively,
  /// we use a switch-based approach for the 13 badges.
  String? _resolveI18nKey(S l10n, String key) {
    switch (key) {
      // Common
      case 'badgeUnlocked':
        return l10n.badgeUnlocked;
      case 'badgeDismiss':
        return l10n.badgeDismiss;

      // First Feeding
      case 'badgeFirstFeedingTitle':
        return l10n.badgeFirstFeedingTitle;
      case 'badgeFirstFeedingDesc':
        return l10n.badgeFirstFeedingDesc;
      case 'badgeFirstFeedingWarm':
        return l10n.badgeFirstFeedingWarm;
      case 'badgeFirstFeedingHumor':
        return l10n.badgeFirstFeedingHumor;

      // Feeding 10
      case 'badgeFeeding10Title':
        return l10n.badgeFeeding10Title;
      case 'badgeFeeding10Desc':
        return l10n.badgeFeeding10Desc;
      case 'badgeFeeding10Warm':
        return l10n.badgeFeeding10Warm;
      case 'badgeFeeding10Humor':
        return l10n.badgeFeeding10Humor;

      // Feeding 50
      case 'badgeFeeding50Title':
        return l10n.badgeFeeding50Title;
      case 'badgeFeeding50Desc':
        return l10n.badgeFeeding50Desc;
      case 'badgeFeeding50Warm':
        return l10n.badgeFeeding50Warm;
      case 'badgeFeeding50Humor':
        return l10n.badgeFeeding50Humor;

      // Milk 1L
      case 'badgeMilk1LTitle':
        return l10n.badgeMilk1LTitle;
      case 'badgeMilk1LDesc':
        return l10n.badgeMilk1LDesc;
      case 'badgeMilk1LWarm':
        return l10n.badgeMilk1LWarm;
      case 'badgeMilk1LHumor':
        return l10n.badgeMilk1LHumor;

      // Night Feeding
      case 'badgeNightFeedingTitle':
        return l10n.badgeNightFeedingTitle;
      case 'badgeNightFeedingDesc':
        return l10n.badgeNightFeedingDesc;
      case 'badgeNightFeedingWarm':
        return l10n.badgeNightFeedingWarm;
      case 'badgeNightFeedingHumor':
        return l10n.badgeNightFeedingHumor;

      // First Sleep
      case 'badgeFirstSleepTitle':
        return l10n.badgeFirstSleepTitle;
      case 'badgeFirstSleepDesc':
        return l10n.badgeFirstSleepDesc;
      case 'badgeFirstSleepWarm':
        return l10n.badgeFirstSleepWarm;
      case 'badgeFirstSleepHumor':
        return l10n.badgeFirstSleepHumor;

      // Sleep 10
      case 'badgeSleep10Title':
        return l10n.badgeSleep10Title;
      case 'badgeSleep10Desc':
        return l10n.badgeSleep10Desc;
      case 'badgeSleep10Warm':
        return l10n.badgeSleep10Warm;
      case 'badgeSleep10Humor':
        return l10n.badgeSleep10Humor;

      // Sleep Through
      case 'badgeSleepThroughTitle':
        return l10n.badgeSleepThroughTitle;
      case 'badgeSleepThroughDesc':
        return l10n.badgeSleepThroughDesc;
      case 'badgeSleepThroughWarm':
        return l10n.badgeSleepThroughWarm;
      case 'badgeSleepThroughHumor':
        return l10n.badgeSleepThroughHumor;

      // Sleep Routine 3d
      case 'badgeSleepRoutineTitle':
        return l10n.badgeSleepRoutineTitle;
      case 'badgeSleepRoutineDesc':
        return l10n.badgeSleepRoutineDesc;
      case 'badgeSleepRoutineWarm':
        return l10n.badgeSleepRoutineWarm;
      case 'badgeSleepRoutineHumor':
        return l10n.badgeSleepRoutineHumor;

      // Sleep Week 7d
      case 'badgeSleepWeekTitle':
        return l10n.badgeSleepWeekTitle;
      case 'badgeSleepWeekDesc':
        return l10n.badgeSleepWeekDesc;
      case 'badgeSleepWeekWarm':
        return l10n.badgeSleepWeekWarm;
      case 'badgeSleepWeekHumor':
        return l10n.badgeSleepWeekHumor;

      // First Record
      case 'badgeFirstRecordTitle':
        return l10n.badgeFirstRecordTitle;
      case 'badgeFirstRecordDesc':
        return l10n.badgeFirstRecordDesc;
      case 'badgeFirstRecordWarm':
        return l10n.badgeFirstRecordWarm;
      case 'badgeFirstRecordHumor':
        return l10n.badgeFirstRecordHumor;

      // 3-Day Streak
      case 'badge3DayStreakTitle':
        return l10n.badge3DayStreakTitle;
      case 'badge3DayStreakDesc':
        return l10n.badge3DayStreakDesc;
      case 'badge3DayStreakWarm':
        return l10n.badge3DayStreakWarm;
      case 'badge3DayStreakHumor':
        return l10n.badge3DayStreakHumor;

      // 7-Day Streak
      case 'badge7DayStreakTitle':
        return l10n.badge7DayStreakTitle;
      case 'badge7DayStreakDesc':
        return l10n.badge7DayStreakDesc;
      case 'badge7DayStreakWarm':
        return l10n.badge7DayStreakWarm;
      case 'badge7DayStreakHumor':
        return l10n.badge7DayStreakHumor;

      // --- Badge-1: Growth / Time-based ---

      // Day 7
      case 'badgeDay7Title':
        return l10n.badgeDay7Title;
      case 'badgeDay7Desc':
        return l10n.badgeDay7Desc;
      case 'badgeDay7Warm':
        return l10n.badgeDay7Warm;
      case 'badgeDay7Humor':
        return l10n.badgeDay7Humor;

      // Day 100
      case 'badgeDay100Title':
        return l10n.badgeDay100Title;
      case 'badgeDay100Desc':
        return l10n.badgeDay100Desc;
      case 'badgeDay100Warm':
        return l10n.badgeDay100Warm;
      case 'badgeDay100Humor':
        return l10n.badgeDay100Humor;

      // Month 1
      case 'badgeMonth1Title':
        return l10n.badgeMonth1Title;
      case 'badgeMonth1Desc':
        return l10n.badgeMonth1Desc;
      case 'badgeMonth1Warm':
        return l10n.badgeMonth1Warm;
      case 'badgeMonth1Humor':
        return l10n.badgeMonth1Humor;

      // Corrected Term
      case 'badgeCorrectedTermTitle':
        return l10n.badgeCorrectedTermTitle;
      case 'badgeCorrectedTermDesc':
        return l10n.badgeCorrectedTermDesc;
      case 'badgeCorrectedTermWarm':
        return l10n.badgeCorrectedTermWarm;
      case 'badgeCorrectedTermHumor':
        return l10n.badgeCorrectedTermHumor;

      // --- Badge-1: Multiples ---

      // Multiples First Record
      case 'badgeMultiplesFirstRecordTitle':
        return l10n.badgeMultiplesFirstRecordTitle;
      case 'badgeMultiplesFirstRecordDesc':
        return l10n.badgeMultiplesFirstRecordDesc;
      case 'badgeMultiplesFirstRecordWarm':
        return l10n.badgeMultiplesFirstRecordWarm;
      case 'badgeMultiplesFirstRecordHumor':
        return l10n.badgeMultiplesFirstRecordHumor;

      // Multiples All Fed
      case 'badgeMultiplesAllFedTitle':
        return l10n.badgeMultiplesAllFedTitle;
      case 'badgeMultiplesAllFedDesc':
        return l10n.badgeMultiplesAllFedDesc;
      case 'badgeMultiplesAllFedWarm':
        return l10n.badgeMultiplesAllFedWarm;
      case 'badgeMultiplesAllFedHumor':
        return l10n.badgeMultiplesAllFedHumor;

      // Multiples All Slept
      case 'badgeMultiplesAllSleptTitle':
        return l10n.badgeMultiplesAllSleptTitle;
      case 'badgeMultiplesAllSleptDesc':
        return l10n.badgeMultiplesAllSleptDesc;
      case 'badgeMultiplesAllSleptWarm':
        return l10n.badgeMultiplesAllSleptWarm;
      case 'badgeMultiplesAllSleptHumor':
        return l10n.badgeMultiplesAllSleptHumor;

      default:
        return null;
    }
  }
}
