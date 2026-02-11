import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_icons.dart';
import '../../../core/design_system/lulu_typography.dart';
import '../../../core/design_system/lulu_spacing.dart';
import '../../../core/utils/korean_particle.dart';
import '../../../data/models/activity_model.dart';
import '../../../data/models/baby_model.dart';
import '../../../data/models/badge_model.dart';
import '../../../l10n/generated/app_localizations.dart' show S;
import '../engine/encouragement_engine.dart';
import '../models/encouragement_message.dart';

/// Compact encouragement message card — inline below SweetSpotCard.
///
/// Height: 48-56px. Layout: [icon 16px] [message bodySmall 1-2 lines]
/// Transparent background, horizontal padding 16, vertical 8.
/// No tap action — informational only.
///
/// Message selection: EncouragementEngine handles prioritization.
/// Same-message prevention: last shown key stored in SharedPreferences.
class EncouragementCard extends StatefulWidget {
  final BabyModel? baby;
  final List<ActivityModel> todayActivities;
  final List<BadgeAchievement> recentBadges;
  final bool hasPendingBadgePopup;
  final bool isWarmTone;

  const EncouragementCard({
    super.key,
    required this.baby,
    required this.todayActivities,
    this.recentBadges = const [],
    this.hasPendingBadgePopup = false,
    this.isWarmTone = true,
  });

  @override
  State<EncouragementCard> createState() => _EncouragementCardState();
}

class _EncouragementCardState extends State<EncouragementCard> {
  String? _lastShownKey;
  static const String _lastShownPrefsKey = 'encouragement_last_shown_key';

  @override
  void initState() {
    super.initState();
    _loadLastShownKey();
  }

  Future<void> _loadLastShownKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = prefs.getString(_lastShownPrefsKey);
      if (mounted && key != null) {
        setState(() {
          _lastShownKey = key;
        });
      }
    } catch (e) {
      debugPrint('[WARN] [EncouragementCard] Failed to load last shown key: $e');
    }
  }

  Future<void> _saveLastShownKey(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastShownPrefsKey, key);
    } catch (e) {
      debugPrint('[WARN] [EncouragementCard] Failed to save last shown key: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final baby = widget.baby;
    if (baby == null) return const SizedBox.shrink();

    final message = EncouragementEngine.select(
      baby: baby,
      todayActivities: widget.todayActivities,
      recentBadges: widget.recentBadges,
      hasPendingBadgePopup: widget.hasPendingBadgePopup,
      tone: widget.isWarmTone ? 'warm' : 'plain',
      now: DateTime.now(),
      lastShownMessageKey: _lastShownKey,
    );

    if (message == null) return const SizedBox.shrink();

    // Save last shown key (fire-and-forget)
    if (message.key != _lastShownKey) {
      _lastShownKey = message.key;
      _saveLastShownKey(message.key);
    }

    final displayText = _resolveMessage(context, message);
    if (displayText == null || displayText.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: LuluSpacing.xs,
        vertical: LuluSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              LuluIcons.tips,
              size: 16,
              color: LuluColors.lavenderMist,
            ),
          ),
          const SizedBox(width: LuluSpacing.sm),
          Expanded(
            child: Text(
              displayText,
              style: LuluTextStyles.bodySmall.copyWith(
                color: LuluTextColors.secondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Resolve message key + params → localized display string
  String? _resolveMessage(BuildContext context, EncouragementMessage message) {
    final l10n = S.of(context);
    if (l10n == null) return null;

    final key = message.key;
    final baby = message.params['baby'] ?? '';
    final count = message.params['count'] ?? '0';
    final hours = message.params['hours'] ?? '0';
    final badge = message.params['badge'] ?? '';

    // Compute Korean particle variants for baby name
    final babyIwa = KoreanParticle.iWa(baby);
    final babyIreul = KoreanParticle.iReul(baby);
    final babyIdo = KoreanParticle.iDo(baby);
    final babyIui = KoreanParticle.iUi(baby);
    final babyIga = KoreanParticle.iGaName(baby);

    // Warm tone keys (default)
    switch (key) {
      // Dawn (warm)
      case 'encouragement_dawn_1':
        return l10n.encouragementDawnWarm1;
      case 'encouragement_dawn_2':
        return l10n.encouragementDawnWarm2;
      case 'encouragement_dawn_3':
        return l10n.encouragementDawnWarm3(babyIwa);
      case 'encouragement_dawn_4':
        return l10n.encouragementDawnWarm4;

      // Morning (warm)
      case 'encouragement_morning_1':
        return l10n.encouragementMorningWarm1(babyIwa);
      case 'encouragement_morning_2':
        return l10n.encouragementMorningWarm2(babyIreul);

      // Afternoon (warm)
      case 'encouragement_afternoon_2':
        return l10n.encouragementAfternoonWarm2;
      case 'encouragement_afternoon_3':
        return l10n.encouragementAfternoonWarm3(babyIwa);

      // Evening (warm)
      case 'encouragement_evening_1':
        return l10n.encouragementEveningWarm1(babyIdo);
      case 'encouragement_evening_2':
        return l10n.encouragementEveningWarm2;
      case 'encouragement_evening_3':
        return l10n.encouragementEveningWarm3(babyIreul);

      // General (warm)
      case 'encouragement_general_1':
        return l10n.encouragementGeneralWarm1;
      case 'encouragement_general_2':
        return l10n.encouragementGeneralWarm2(babyIui);
      case 'encouragement_general_3':
        return l10n.encouragementGeneralWarm3;
      case 'encouragement_general_4':
        return l10n.encouragementGeneralWarm4(babyIreul);

      // Data-based
      case 'encouragement_data_badge':
        return l10n.encouragementDataBadgeWarm(badge);
      case 'encouragement_data_sleep':
        return l10n.encouragementDataSleepWarm(babyIga, hours);
      case 'encouragement_data_weekly':
        return l10n.encouragementDataWeeklyWarm(count);

      // Plain tone keys
      case 'encouragement_dawn_plain_1':
        return l10n.encouragementDawnPlain1;
      case 'encouragement_dawn_plain_2':
        return l10n.encouragementDawnPlain2;
      case 'encouragement_dawn_plain_3':
        return l10n.encouragementDawnPlain3(count);
      case 'encouragement_morning_plain_1':
        return l10n.encouragementMorningPlain1;
      case 'encouragement_morning_plain_2':
        return l10n.encouragementMorningPlain2(count);
      case 'encouragement_morning_plain_3':
        return l10n.encouragementMorningPlain3;
      case 'encouragement_afternoon_plain_1':
        return l10n.encouragementAfternoonPlain1;
      case 'encouragement_afternoon_plain_2':
        return l10n.encouragementAfternoonPlain2(count);
      case 'encouragement_evening_plain_1':
        return l10n.encouragementEveningPlain1(count);
      case 'encouragement_evening_plain_2':
        return l10n.encouragementEveningPlain2;
      case 'encouragement_evening_plain_3':
        return l10n.encouragementEveningPlain3;

      default:
        debugPrint('[WARN] [EncouragementCard] Unknown key: $key');
        return null;
    }
  }
}
