import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/design_system/lulu_colors.dart';
import '../../core/design_system/lulu_radius.dart';
import '../../core/design_system/lulu_icons.dart';
import '../../core/design_system/lulu_spacing.dart';
import '../../core/design_system/lulu_typography.dart';
import '../../data/models/sweet_spot_result.dart';
import '../../features/home/providers/sweet_spot_provider.dart';
import '../../l10n/generated/app_localizations.dart' show S;
import 'golden_band_bar.dart';

/// Sweet Spot Card (C-5 Smart Band + Hint)
///
/// Sprint 23 C-5: Full rebuild with golden band progress bar.
/// UX Process: 5-proposal → agent debate → virtual UT (SUS 85, TTC 1.9s)
///
/// States:
/// - Sleeping: ongoing sleep timer (unchanged from Sprint 7)
/// - Empty: new user first record (unchanged)
/// - NoSleepGuide: has other activities but no sleep
/// - Calibrating: learning pattern (1-2 records)
/// - Normal: golden band with 4 sub-states
///   - tooEarly (beforeRelaxed)
///   - approaching (beforeSoon)
///   - optimal (inZone)
///   - overtired (afterZone) — grey fade, NO red/escalation
class SweetSpotCard extends StatefulWidget {
  final SweetSpotState state;
  final bool isEmpty;
  final String? estimatedTime;
  final VoidCallback? onRecordSleep;
  final bool isSleeping;
  final DateTime? sleepStartTime;
  final String? sleepType;
  final String? babyName;
  final VoidCallback? onEndSleep;
  final VoidCallback? onCancelSleep;
  final VoidCallback? onFeedingTap;
  final VoidCallback? onSleepTap;
  final VoidCallback? onDiaperTap;
  final double? progress;
  final DateTime? recommendedTime;
  final bool isNightTime;
  final bool hasOtherActivitiesOnly;
  final bool isNewUser;
  final int? completedSleepRecords;
  final int? calibrationTarget;

  /// C-5: SweetSpotResult for golden band rendering
  final SweetSpotResult? sweetSpotResult;

  /// C-5: Baby index for theme color (0-3, -1 or null = singleton default)
  final int? babyIndex;

  /// C-5: Tone setting (true = warm, false = plain)
  final bool isWarmTone;

  const SweetSpotCard({
    super.key,
    required this.state,
    this.isEmpty = false,
    this.estimatedTime,
    this.onRecordSleep,
    this.isSleeping = false,
    this.sleepStartTime,
    this.sleepType,
    this.babyName,
    this.onEndSleep,
    this.onCancelSleep,
    this.onFeedingTap,
    this.onSleepTap,
    this.onDiaperTap,
    this.progress,
    this.recommendedTime,
    this.isNightTime = false,
    this.hasOtherActivitiesOnly = false,
    this.isNewUser = true,
    this.completedSleepRecords,
    this.calibrationTarget,
    this.sweetSpotResult,
    this.babyIndex,
    this.isWarmTone = true,
  });

  @override
  State<SweetSpotCard> createState() => _SweetSpotCardState();
}

class _SweetSpotCardState extends State<SweetSpotCard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.isSleeping) {
      _startTimer();
    }
  }

  @override
  void didUpdateWidget(SweetSpotCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSleeping && !oldWidget.isSleeping) {
      _startTimer();
    } else if (!widget.isSleeping && oldWidget.isSleeping) {
      _stopTimer();
    }
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }

  void _startTimer() {
    _stopTimer();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  // ========================================
  // Theme color helpers
  // ========================================

  Color get _themeColor {
    final idx = widget.babyIndex;
    if (idx == null || idx < 0) return LuluColors.lavenderMist;
    return LuluColors.getBabyColor(idx);
  }

  Color get _themeColorLight {
    final idx = widget.babyIndex;
    if (idx == null || idx < 0) return LuluColors.lavenderLight;
    return LuluColors.getBabyColorLight(idx);
  }

  Color get _themeColorStrong {
    final idx = widget.babyIndex;
    if (idx == null || idx < 0) return LuluColors.lavenderStrong;
    return LuluColors.getBabyColorStrong(idx);
  }

  // ========================================
  // Build
  // ========================================

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context)!;

    if (widget.isSleeping && widget.sleepStartTime != null) {
      return _buildSleepingCard(context);
    }

    if (widget.isEmpty) {
      return _buildEmptyState(context, l10n);
    }

    return _buildNormalState(context, l10n);
  }

  // ========================================
  // Sleeping Card (unchanged from Sprint 7)
  // ========================================

  Widget _buildSleepingCard(BuildContext context) {
    final l10n = S.of(context)!;
    final sleepTypeText = widget.sleepType == 'night'
        ? l10n.sleepTypeNight
        : l10n.sleepTypeNap;
    final babyName = widget.babyName ?? l10n.babyDefault;
    final elapsed = DateTime.now().difference(widget.sleepStartTime!);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            LuluActivityColors.sleepLight,
            LuluActivityColors.sleepSubtle,
          ],
        ),
        borderRadius: BorderRadius.circular(LuluRadius.lg),
        border: Border.all(
          color: LuluActivityColors.sleepCardBorder,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: LuluActivityColors.sleepSelected,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    LuluIcons.sleep,
                    size: 24,
                    color: LuluActivityColors.sleep,
                  ),
                ),
              ),
              const SizedBox(width: LuluSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.sleepOngoingStatus(babyName, sleepTypeText),
                      style: LuluTextStyles.titleSmall.copyWith(
                        color: LuluTextColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDuration(elapsed),
                      style: LuluTextStyles.displaySmall.copyWith(
                        color: LuluActivityColors.sleep,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: LuluSpacing.md),
          _buildInfoRow(
            l10n.sweetSpotSleepStart,
            DateFormat(
              'a h:mm',
              Localizations.localeOf(context).toString(),
            ).format(widget.sleepStartTime!),
          ),
          const SizedBox(height: LuluSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.onEndSleep,
              style: ElevatedButton.styleFrom(
                backgroundColor: LuluActivityColors.sleep,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(LuluRadius.sm),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LuluIcons.sleep, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    l10n.sweetSpotTapToEndSleep,
                    style: LuluTextStyles.labelLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========================================
  // Empty State (unchanged)
  // ========================================

  Widget _buildEmptyState(BuildContext context, S l10n) {
    final babyName = widget.babyName;

    return Container(
      padding: const EdgeInsets.all(LuluSpacing.lg),
      decoration: BoxDecoration(
        color: LuluColors.surfaceCard,
        borderRadius: BorderRadius.circular(LuluRadius.lg),
        border: Border.all(
          color: LuluColors.glassBorder,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LuluIcons.celebration,
            size: 48,
            color: LuluColors.champagneGold,
          ),
          const SizedBox(height: LuluSpacing.md),
          Text(
            widget.isNewUser
                ? (babyName != null
                    ? l10n.sweetSpotEmptyTitleWithName(babyName)
                    : l10n.sweetSpotEmptyTitleDefault)
                : l10n.sweetSpotNoSleepTitle,
            style: LuluTextStyles.titleMedium.copyWith(
              color: LuluTextColors.primary,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: LuluSpacing.sm),
          Text(
            widget.isNewUser
                ? l10n.sweetSpotEmptyActionHint
                : l10n.sweetSpotNoSleepHint,
            style: LuluTextStyles.bodyMedium.copyWith(
              color: LuluTextColors.secondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: LuluSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildQuickRecordButton(
                icon: LuluIcons.feeding,
                label: l10n.activityTypeFeeding,
                color: LuluActivityColors.feeding,
                onTap: widget.onFeedingTap,
              ),
              _buildQuickRecordButton(
                icon: LuluIcons.sleep,
                label: l10n.activityTypeSleep,
                color: LuluActivityColors.sleep,
                onTap: widget.onSleepTap ?? widget.onRecordSleep,
              ),
              _buildQuickRecordButton(
                icon: LuluIcons.diaper,
                label: l10n.activityTypeDiaper,
                color: LuluActivityColors.diaper,
                onTap: widget.onDiaperTap,
              ),
            ],
          ),
          const SizedBox(height: LuluSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                LuluIcons.tip,
                size: 16,
                color: LuluColors.champagneGold,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  l10n.sweetSpotEmptyHint,
                  style: LuluTextStyles.caption.copyWith(
                    color: LuluTextColors.tertiary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickRecordButton({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: LuluSpacing.md),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(LuluRadius.md),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: LuluSpacing.xs),
            Text(
              label,
              style: LuluTextStyles.labelSmall.copyWith(
                color: LuluTextColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========================================
  // Normal State — C-5 Smart Band + Hint
  // ========================================

  Widget _buildNormalState(BuildContext context, S l10n) {
    if (widget.hasOtherActivitiesOnly) {
      return _buildNoSleepGuideCard(context, l10n);
    }

    if (widget.state == SweetSpotState.calibrating) {
      return _buildSmartBandCard(context, l10n);
    }

    if (widget.state == SweetSpotState.unknown) {
      return _buildNoDataCard(context, l10n);
    }

    return _buildSmartBandCard(context, l10n);
  }

  /// C-5 Smart Band Card — the core redesign
  Widget _buildSmartBandCard(BuildContext context, S l10n) {
    final isCalibrating = widget.state == SweetSpotState.calibrating;
    final isAfterZone = widget.state == SweetSpotState.overtired;
    final isInZone = widget.state == SweetSpotState.optimal;

    // Accent line color
    final accentColor = isAfterZone
        ? LuluColors.surfaceElevatedBorder
        : _themeColor;

    // Golden band positions
    final bandStart = _calcBandStart();
    final bandEnd = _calcBandEnd();
    final currentProgress = _calcProgress();

    return Container(
      decoration: BoxDecoration(
        color: LuluColors.surfaceCard,
        borderRadius: BorderRadius.circular(LuluRadius.lg),
        border: Border.all(color: LuluColors.glassBorder),
      ),
      child: Stack(
        children: [
          // Accent line (left 4dp)
          Positioned(
            left: 0,
            top: 8,
            bottom: 8,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOut,
              width: 4,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  bottomLeft: Radius.circular(4),
                ),
              ),
            ),
          ),
          // Card content
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Row 1: Nap label + icon
                Row(
                  children: [
                    Icon(
                      widget.isNightTime
                          ? LuluIcons.moon
                          : LuluIcons.sleep,
                      size: 16,
                      color: isAfterZone
                          ? LuluTextColors.tertiary
                          : _themeColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _getNapLabel(l10n),
                      style: LuluTextStyles.bodySmall.copyWith(
                        color: LuluTextColors.secondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Row 2: Time range or calibrating indicator
                if (isCalibrating)
                  _buildCalibratingTimeRow(l10n)
                else
                  _buildTimeRangeRow(l10n),

                const SizedBox(height: 12),

                // Row 3: Golden Band progress bar
                GoldenBandBar(
                  progress: currentProgress,
                  bandStart: bandStart,
                  bandEnd: bandEnd,
                  themeColor: _themeColor,
                  themeColorLight: _themeColorLight,
                  themeColorStrong: _themeColorStrong,
                  isCalibrating: isCalibrating,
                  isInZone: isInZone,
                  isAfterZone: isAfterZone,
                ),

                const SizedBox(height: 8),

                // Row 4: State message (warm/plain)
                Text(
                  _getStateMessage(l10n),
                  style: LuluTextStyles.bodySmall.copyWith(
                    color: isAfterZone
                        ? LuluTextColors.tertiary
                        : LuluTextColors.secondary,
                  ),
                ),

                // Divider + Next nap hint
                if (_shouldShowNextHint()) ...[
                  const SizedBox(height: 8),
                  Divider(
                    height: 1,
                    thickness: 0.5,
                    color: LuluColors.glassBorder,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: _buildNextNapHint(l10n),
                  ),
                ] else
                  const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========================================
  // Smart Band sub-components
  // ========================================

  Widget _buildTimeRangeRow(S l10n) {
    final result = widget.sweetSpotResult;
    if (result == null) {
      // Fallback: use recommendedTime
      if (widget.recommendedTime != null) {
        final locale = Localizations.localeOf(context).toString();
        final formattedTime = DateFormat('a h:mm', locale)
            .format(widget.recommendedTime!);
        return Text(
          formattedTime,
          style: LuluTextStyles.titleMedium.copyWith(
            color: LuluTextColors.primary,
            fontWeight: FontWeight.bold,
          ),
        );
      }
      return const SizedBox.shrink();
    }

    final locale = Localizations.localeOf(context).toString();
    final minTime = DateFormat('H:mm', locale).format(result.minSleepTime);
    final maxTime = DateFormat('H:mm', locale).format(result.maxSleepTime);

    return Text(
      '$minTime ~ $maxTime',
      style: LuluTextStyles.titleMedium.copyWith(
        color: widget.state == SweetSpotState.overtired
            ? LuluTextColors.tertiary
            : LuluTextColors.primary,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildCalibratingTimeRow(S l10n) {
    final completed = widget.completedSleepRecords ?? 0;
    final day = completed > 0 ? completed : 1;

    return Row(
      children: [
        // Progress dots
        ...List.generate(3, (i) {
          return Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: i < day
                    ? _themeColor
                    : LuluColors.surfaceElevated,
                shape: BoxShape.circle,
              ),
            ),
          );
        }),
        const SizedBox(width: 4),
        Text(
          widget.isWarmTone
              ? l10n.sweetSpotCardCalibratingWarm(day)
              : l10n.sweetSpotCardCalibratingPlain(day),
          style: LuluTextStyles.bodyMedium.copyWith(
            color: LuluTextColors.secondary,
          ),
        ),
      ],
    );
  }

  Widget _buildNextNapHint(S l10n) {
    final result = widget.sweetSpotResult;
    final isLastNap = result != null &&
        result.napNumber >= result.totalExpectedNaps;

    if (isLastNap) {
      return Row(
        children: [
          Text(
            widget.isWarmTone
                ? l10n.sweetSpotCardNextNightWarm
                : l10n.sweetSpotCardNextNightPlain,
            style: LuluTextStyles.bodySmall.copyWith(
              color: LuluTextColors.tertiary,
            ),
          ),
          const Spacer(),
          Icon(
            LuluIcons.chevronRight,
            size: 14,
            color: LuluTextColors.tertiary,
          ),
        ],
      );
    }

    // Next nap time estimate
    if (result != null && result.totalExpectedNaps > result.napNumber) {
      final locale = Localizations.localeOf(context).toString();
      final nextTime = DateFormat('a h:mm', locale)
          .format(result.maxSleepTime.add(
        Duration(minutes: result.wakeWindow.midMinutes),
      ));

      return Row(
        children: [
          Text(
            widget.isWarmTone
                ? l10n.sweetSpotCardNextNapWarm(nextTime)
                : l10n.sweetSpotCardNextNapPlain(nextTime),
            style: LuluTextStyles.bodySmall.copyWith(
              color: LuluTextColors.tertiary,
            ),
          ),
          const Spacer(),
          Icon(
            LuluIcons.chevronRight,
            size: 14,
            color: LuluTextColors.tertiary,
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  // ========================================
  // No Sleep Guide Card (unchanged)
  // ========================================

  Widget _buildNoSleepGuideCard(BuildContext context, S l10n) {
    return Container(
      padding: const EdgeInsets.all(LuluSpacing.lg),
      decoration: BoxDecoration(
        color: LuluColors.surfaceCard,
        borderRadius: BorderRadius.circular(LuluRadius.md),
        border: Border.all(color: LuluColors.glassBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LuluIcons.sleep,
            size: 40,
            color: LuluActivityColors.sleepStrong,
          ),
          const SizedBox(height: LuluSpacing.md),
          Text(
            l10n.sweetSpotNoSleepTitle,
            style: LuluTextStyles.titleSmall.copyWith(
              color: LuluTextColors.primary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: LuluSpacing.sm),
          Text(
            l10n.sweetSpotNoSleepHint,
            style: LuluTextStyles.bodySmall.copyWith(
              color: LuluTextColors.secondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: LuluSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: widget.onRecordSleep ?? widget.onSleepTap,
              icon: const Icon(LuluIcons.sleep, size: 18),
              label: Text(l10n.sweetSpotRecordSleepButton),
              style: OutlinedButton.styleFrom(
                foregroundColor: LuluActivityColors.sleep,
                side: BorderSide(
                  color: LuluActivityColors.sleepMedium,
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(LuluRadius.sm),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========================================
  // No Data Card (unknown state)
  // ========================================

  Widget _buildNoDataCard(BuildContext context, S l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LuluColors.surfaceCard,
        borderRadius: BorderRadius.circular(LuluRadius.md),
        border: Border.all(color: LuluColors.glassBorder),
      ),
      child: Row(
        children: [
          Icon(
            LuluIcons.sleep,
            size: 20,
            color: LuluTextColors.tertiary,
          ),
          const SizedBox(width: 8),
          Text(
            widget.isWarmTone
                ? l10n.sweetSpotCardNoDataWarm
                : l10n.sweetSpotCardNoDataPlain,
            style: LuluTextStyles.bodyMedium.copyWith(
              color: LuluTextColors.secondary,
            ),
          ),
        ],
      ),
    );
  }

  // ========================================
  // Helpers
  // ========================================

  String _formatDuration(Duration duration) {
    final l10n = S.of(context)!;
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return l10n.durationHoursMinutes(hours, minutes);
    }
    return l10n.durationMinutes(minutes);
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: LuluTextStyles.bodyMedium.copyWith(
            color: LuluTextColors.secondary,
          ),
        ),
        Text(
          value,
          style: LuluTextStyles.bodyMedium.copyWith(
            color: LuluTextColors.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// Nap order label (1st, 2nd, 3rd, 4th nap / night sleep)
  String _getNapLabel(S l10n) {
    if (widget.isNightTime) {
      return widget.isWarmTone
          ? l10n.sweetSpotCardNightWarm
          : l10n.sweetSpotCardNightPlain;
    }

    final result = widget.sweetSpotResult;
    final napNum = result?.napNumber ?? 1;

    return switch (napNum) {
      1 => l10n.sweetSpotCardNapLabel1,
      2 => l10n.sweetSpotCardNapLabel2,
      3 => l10n.sweetSpotCardNapLabel3,
      _ => l10n.sweetSpotCardNapLabel4,
    };
  }

  /// State message (warm/plain tone)
  String _getStateMessage(S l10n) {
    if (widget.state == SweetSpotState.calibrating) {
      final completed = widget.completedSleepRecords ?? 0;
      final day = completed > 0 ? completed : 1;
      return widget.isWarmTone
          ? l10n.sweetSpotCardCalibratingWarm(day)
          : l10n.sweetSpotCardCalibratingPlain(day);
    }

    // Wide range message for young babies
    final result = widget.sweetSpotResult;
    if (result != null && result.correctedAgeMonths < 2) {
      final rangeMinutes = result.maxSleepTime
          .difference(result.minSleepTime)
          .inMinutes;
      if (rangeMinutes > 30) {
        return widget.isWarmTone
            ? l10n.sweetSpotCardRangeWideMsgWarm
            : l10n.sweetSpotCardRangeWideMsgPlain;
      }
    }

    return switch (widget.state) {
      SweetSpotState.tooEarly => widget.isWarmTone
          ? l10n.sweetSpotCardBeforeRelaxedWarm
          : l10n.sweetSpotCardBeforeRelaxedPlain,
      SweetSpotState.approaching => widget.isWarmTone
          ? l10n.sweetSpotCardBeforeSoonWarm
          : l10n.sweetSpotCardBeforeSoonPlain,
      SweetSpotState.optimal => widget.isWarmTone
          ? l10n.sweetSpotCardInZoneWarm
          : l10n.sweetSpotCardInZonePlain,
      SweetSpotState.overtired => widget.isWarmTone
          ? l10n.sweetSpotCardAfterZoneWarm
          : l10n.sweetSpotCardAfterZonePlain,
      _ => '',
    };
  }

  /// Calculate golden band start position (0.0 ~ 1.0)
  double _calcBandStart() {
    final result = widget.sweetSpotResult;
    if (result == null || result.lastWakeTime == null) return 0.6;

    final totalRange = result.wakeWindow.maxMinutes.toDouble();
    if (totalRange <= 0) return 0.6;

    final minRange = result.wakeWindow.minMinutes.toDouble();
    return (minRange / totalRange).clamp(0.0, 1.0);
  }

  /// Calculate golden band end position (0.0 ~ 1.0)
  double _calcBandEnd() {
    return 1.0; // Band always ends at the max of wake window
  }

  /// Calculate current progress (0.0 ~ 1.2)
  double _calcProgress() {
    final result = widget.sweetSpotResult;
    if (result != null) {
      return result.calculateProgress(DateTime.now());
    }
    return widget.progress ?? 0.0;
  }

  /// Whether to show next nap hint
  bool _shouldShowNextHint() {
    if (widget.state == SweetSpotState.calibrating) return false;
    if (widget.state == SweetSpotState.unknown) return false;
    final result = widget.sweetSpotResult;
    if (result == null) return false;
    return true;
  }
}
