import 'dart:async';
import 'dart:math' show sin, pi;
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

/// Sweet Spot Card — C-5.2 Living Breath
///
/// Sprint 26 C-5.2: State-based gradient + breathing pulse system.
/// UX Process: 5-proposal → agent debate → P1+P5 combine → virtual UT (SUS 90, TTC 0.46s)
///
/// States:
/// - Sleeping: ongoing sleep timer (unchanged)
/// - Empty: new user first record (unchanged)
/// - NoSleepGuide: has other activities but no sleep (unchanged)
/// - Calibrating: stripe + slow pulse
/// - Living Breath (normal): state-based gradient + pulse
///   - tooEarly: lavender, 4s pulse
///   - approaching: amber, 3s pulse
///   - optimal: gold, 2s pulse + glow
///   - overtired: lavender reset, 4s pulse
///   - night: nightBlue, 3.5s pulse
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

class _SweetSpotCardState extends State<SweetSpotCard>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  late AnimationController _breathController;

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _getPulseMs()),
    );
    if (widget.isSleeping) {
      _startTimer();
    } else {
      _breathController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(SweetSpotCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Timer: sleeping elapsed display
    if (widget.isSleeping && !oldWidget.isSleeping) {
      _startTimer();
      _breathController.stop();
    } else if (!widget.isSleeping && oldWidget.isSleeping) {
      _stopTimer();
      _breathController.repeat(reverse: true);
    }
    // Pulse: update duration if state changed
    final newPulseMs = _getPulseMs();
    if (_breathController.duration?.inMilliseconds != newPulseMs) {
      _breathController.duration = Duration(milliseconds: newPulseMs);
      if (!widget.isSleeping) {
        _breathController.repeat(reverse: true);
      }
    }
  }

  @override
  void dispose() {
    _stopTimer();
    _breathController.dispose();
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

  /// Pulse period in milliseconds per state
  /// Night overrides underlying state (3500ms regardless of tooEarly/approaching/etc.)
  int _getPulseMs() {
    final isNight = widget.isNightTime ||
        (widget.sweetSpotResult?.isNightTime ?? false);
    if (isNight) return 3500;
    return switch (widget.state) {
      SweetSpotState.tooEarly => 4000,
      SweetSpotState.approaching => 3000,
      SweetSpotState.optimal => 2000,
      SweetSpotState.overtired => 4000,
      SweetSpotState.calibrating => 5000,
      _ => 4000,
    };
  }

  /// Breath value 0.0 ~ 1.0 (sine curve via AnimationController)
  double get _breath {
    final t = _breathController.value;
    return (sin(t * pi) + 1) / 2;
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

  /// C-5.2 Living Breath Card — state-based gradient + breathing pulse
  Widget _buildSmartBandCard(BuildContext context, S l10n) {
    final isCalibrating = widget.state == SweetSpotState.calibrating;
    // C-5.2 Phase 3: When transitioned to next nap, card resets to "fresh" look
    final isTransitioned = _isOverdueTransitioned();
    final isAfterZone = widget.state == SweetSpotState.overtired && !isTransitioned;
    final isInZone = widget.state == SweetSpotState.optimal;
    final isNight = widget.isNightTime ||
        (widget.sweetSpotResult?.isNightTime ?? false);

    // Golden band positions
    final bandStart = _calcBandStart();
    final bandEnd = _calcBandEnd();
    final currentProgress = _calcProgress();

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _breathController,
        builder: (context, child) {
          final breath = _breath;
          final bgColors = _breathBgColors(breath, isNight);
          final borderColor = _breathBorderColor(breath, isNight);
          final boxShadows = _breathBoxShadow(breath, isInZone);
          final timeColor = _breathTimeColor(isInZone, isAfterZone);
          final msgColor = _breathMsgColor(breath, isInZone, isAfterZone);

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: bgColors,
              ),
              borderRadius: BorderRadius.circular(LuluRadius.lg),
              border: Border.all(color: borderColor, width: 1),
              boxShadow: boxShadows,
            ),
            child: Stack(
              children: [
                // Radial glow overlay (optimal only)
                if (isInZone && !isAfterZone)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(LuluRadius.lg),
                        gradient: RadialGradient(
                          center: Alignment.center,
                          radius: 0.8,
                          colors: [
                            Color.lerp(
                              LuluSweetSpotColors.goldGlow06,
                              LuluSweetSpotColors.goldGlow07,
                              breath,
                            )!,
                            const Color(0x00000000),
                          ],
                        ),
                      ),
                    ),
                  ),
                // Content
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Row 1: Nap label + icon
                      Row(
                        children: [
                          Icon(
                            isNight ? LuluIcons.moon : LuluIcons.sleep,
                            size: 16,
                            color: isAfterZone
                                ? LuluTextColors.tertiary
                                : _breathIconColor(isInZone, isNight),
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
                      const SizedBox(height: 14),

                      // Row 2: Hero time range (28px)
                      if (isCalibrating)
                        _buildCalibratingTimeRow(l10n)
                      else
                        _buildHeroTimeRange(l10n, timeColor),

                      // Row 2.5: Wake elapsed + ref range
                      if (!isCalibrating) _buildWakeElapsedRow(l10n),

                      const SizedBox(height: 8),

                      // Row 3: State message
                      Text(
                        _getStateMessage(l10n),
                        style: LuluTextStyles.bodyMedium.copyWith(
                          color: msgColor,
                          fontWeight: isInZone ? FontWeight.w500 : FontWeight.w400,
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Row 4: Golden Band progress bar
                      if (!_isOverdueTransitioned())
                        GoldenBandBar(
                          progress: _clampedProgress(currentProgress),
                          bandStart: bandStart,
                          bandEnd: bandEnd,
                          themeColor: _themeColor,
                          themeColorLight: _themeColorLight,
                          themeColorStrong: _themeColorStrong,
                          isCalibrating: isCalibrating,
                          isInZone: isInZone,
                          isAfterZone: isAfterZone && !_isOverdueTransitioned(),
                          breath: breath,
                        ),

                      // Divider + Next nap hint
                      if (_shouldShowNextHint()) ...[
                        const SizedBox(height: 14),
                        Container(
                          height: 1,
                          color: LuluSweetSpotColors.calibratingBorder,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: _buildNextNapHint(l10n),
                        ),
                      ] else
                        const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ========================================
  // Living Breath color helpers
  // ========================================

  /// Background gradient colors (pulse-interpolated)
  List<Color> _breathBgColors(double breath, bool isNight) {
    if (widget.state == SweetSpotState.calibrating) {
      return [
        Color.lerp(
          LuluSweetSpotColors.calibratingBg04,
          LuluSweetSpotColors.calibratingBg06,
          breath,
        )!,
        LuluSweetSpotColors.calibratingBg04,
      ];
    }
    if (isNight) {
      return [
        Color.lerp(
          LuluSweetSpotColors.nightBg06,
          LuluSweetSpotColors.nightBg09,
          breath,
        )!,
        LuluSweetSpotColors.nightBg06,
      ];
    }
    return switch (widget.state) {
      SweetSpotState.tooEarly || SweetSpotState.overtired => [
          Color.lerp(
            LuluSweetSpotColors.lavenderBg06,
            LuluSweetSpotColors.lavenderBg09,
            breath,
          )!,
          LuluSweetSpotColors.lavenderBg06,
        ],
      SweetSpotState.approaching => [
          Color.lerp(
            LuluSweetSpotColors.amberBg06,
            LuluSweetSpotColors.amberBg09,
            breath,
          )!,
          LuluSweetSpotColors.amberBg06,
        ],
      SweetSpotState.optimal => [
          Color.lerp(
            LuluSweetSpotColors.goldBg10,
            LuluSweetSpotColors.goldBg15,
            breath,
          )!,
          LuluSweetSpotColors.goldBg10,
        ],
      _ => [LuluSweetSpotColors.lavenderBg06, LuluSweetSpotColors.lavenderBg06],
    };
  }

  /// Border color (pulse-interpolated for optimal only)
  Color _breathBorderColor(double breath, bool isNight) {
    if (widget.state == SweetSpotState.calibrating) {
      return LuluSweetSpotColors.calibratingBorder;
    }
    if (isNight) return LuluSweetSpotColors.nightBorder;
    return switch (widget.state) {
      SweetSpotState.tooEarly || SweetSpotState.overtired =>
        LuluSweetSpotColors.lavenderBorder,
      SweetSpotState.approaching => LuluSweetSpotColors.amberBorder,
      SweetSpotState.optimal => Color.lerp(
          LuluSweetSpotColors.goldBorder30,
          LuluSweetSpotColors.goldBorder42,
          breath,
        )!,
      _ => LuluSweetSpotColors.lavenderBorder,
    };
  }

  /// Box shadow (optimal glow only)
  List<BoxShadow> _breathBoxShadow(double breath, bool isInZone) {
    if (!isInZone) return const [];
    return [
      BoxShadow(
        color: LuluSweetSpotColors.goldGlow06,
        blurRadius: 30 + breath * 20,
        spreadRadius: 0,
      ),
    ];
  }

  /// Hero time color
  Color _breathTimeColor(bool isInZone, bool isAfterZone) {
    if (isAfterZone) return LuluTextColors.tertiary;
    if (isInZone) return LuluSweetSpotColors.goldText;
    return LuluTextColors.primary;
  }

  /// State message color (pulse for optimal)
  Color _breathMsgColor(double breath, bool isInZone, bool isAfterZone) {
    if (isAfterZone) return LuluTextColors.tertiary;
    if (isInZone) {
      return Color.lerp(
        LuluSweetSpotColors.goldMsgBase,
        LuluSweetSpotColors.goldMsgPeak,
        breath,
      )!;
    }
    return LuluTextColors.secondary;
  }

  /// Icon color by state
  Color _breathIconColor(bool isInZone, bool isNight) {
    if (isNight) return LuluSweetSpotColors.nightBlue;
    if (isInZone) return LuluSweetSpotColors.goldAccent;
    if (widget.state == SweetSpotState.approaching) {
      return LuluSweetSpotColors.amberAccent;
    }
    return LuluSweetSpotColors.lavenderAccent;
  }

  /// Hero time range with 28px bold styling
  Widget _buildHeroTimeRange(S l10n, Color timeColor) {
    final result = widget.sweetSpotResult;

    // C-5.2 Phase 3: Stage B — show next nap time range
    if (_isOverdueTransitioned()) {
      final nextRange = _nextNapTimeRange();
      if (nextRange != null) {
        final locale = Localizations.localeOf(context).toString();
        final minTime = DateFormat('H:mm', locale).format(nextRange.min);
        final maxTime = DateFormat('H:mm', locale).format(nextRange.max);
        return Text(
          '$minTime ~ $maxTime',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: LuluTextColors.primary,
          ),
        );
      }
      // Next nap unpredictable — hide time
      return const SizedBox.shrink();
    }

    if (result == null) {
      if (widget.recommendedTime != null) {
        final locale = Localizations.localeOf(context).toString();
        final formattedTime = DateFormat('a h:mm', locale)
            .format(widget.recommendedTime!);
        return Text(
          formattedTime,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: LuluTextColors.primary,
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
      style: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: timeColor,
      ),
    );
  }

  // ========================================
  // Smart Band sub-components
  // ========================================

  Widget _buildCalibratingTimeRow(S l10n) {
    final completed = widget.completedSleepRecords ?? 0;
    final count = completed > 0 ? completed : 1;

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
                color: i < count
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
              ? l10n.sweetSpotCardCalibratingWarm(count)
              : l10n.sweetSpotCardCalibratingPlain(count),
          style: LuluTextStyles.bodyMedium.copyWith(
            color: LuluTextColors.secondary,
          ),
        ),
      ],
    );
  }

  /// C-5.1: Wake elapsed time + reference range row
  ///
  /// Displayed between time range and golden band bar.
  /// Shows: "깨시 47분" (colored by position) + "참고: 60~90분" (tertiary)
  /// Hidden when sleeping or when no result available.
  Widget _buildWakeElapsedRow(S l10n) {
    final result = widget.sweetSpotResult;
    if (result == null) return const SizedBox.shrink();

    final now = DateTime.now();
    final elapsed = result.wakeElapsedMinutes(now);
    if (elapsed == null) return const SizedBox.shrink();

    final position = result.wakePosition(now);
    if (position == WakeWindowPosition.sleeping) {
      return const SizedBox.shrink();
    }

    final elapsedText = _formatWakeElapsed(elapsed, l10n);
    final elapsedColor = _wakePositionColor(position);
    final refText = _formatWakeRefRange(result, l10n);

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            LuluIcons.wakeWindow,
            size: 14,
            color: elapsedColor,
          ),
          const SizedBox(width: 4),
          Text(
            elapsedText,
            style: LuluTextStyles.bodySmall.copyWith(
              color: elapsedColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (refText != null) ...[
            const SizedBox(width: 8),
            Text(
              refText,
              style: LuluTextStyles.caption.copyWith(
                color: LuluTextColors.tertiary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Format wake elapsed minutes to localized string
  String _formatWakeElapsed(int minutes, S l10n) {
    if (minutes >= 60) {
      return l10n.wakeWindowCardElapsedHours(minutes ~/ 60, minutes % 60);
    }
    return l10n.wakeWindowCardElapsed(minutes);
  }

  /// Format reference range to compact localized string
  String? _formatWakeRefRange(SweetSpotResult result, S l10n) {
    final minMin = result.wakeRangeMinMinutes;
    final maxMin = result.wakeRangeMaxMinutes;
    if (minMin <= 0 && maxMin <= 0) return null;

    if (maxMin >= 60) {
      return l10n.wakeWindowCardRefHours(
        minMin ~/ 60, minMin % 60,
        maxMin ~/ 60, maxMin % 60,
      );
    }
    return l10n.wakeWindowCardRef(minMin, maxMin);
  }

  /// Map wake position to display color
  ///
  /// Neutral coloring — NO red for afterRange (medical ethics).
  /// afterRange uses tertiary grey, matching overtired band fade.
  Color _wakePositionColor(WakeWindowPosition position) {
    return switch (position) {
      WakeWindowPosition.sleeping => LuluTextColors.tertiary,
      WakeWindowPosition.beforeRange => LuluTextColors.secondary,
      WakeWindowPosition.inRange => _themeColor,
      WakeWindowPosition.afterRange => LuluTextColors.tertiary,
    };
  }

  Widget _buildNextNapHint(S l10n) {
    final result = widget.sweetSpotResult;

    // If engine determined night time, show night label (not "next nap")
    if (widget.isNightTime || (result != null && result.isNightTime)) {
      return Text(
        widget.isWarmTone
            ? l10n.sweetSpotCardNextNightWarm
            : l10n.sweetSpotCardNextNightPlain,
        style: LuluTextStyles.bodySmall.copyWith(
          color: LuluTextColors.tertiary,
        ),
      );
    }

    final isLastNap = result != null &&
        result.napNumber >= result.totalExpectedNaps;

    if (isLastNap) {
      return Text(
        widget.isWarmTone
            ? l10n.sweetSpotCardNextNightWarm
            : l10n.sweetSpotCardNextNightPlain,
        style: LuluTextStyles.bodySmall.copyWith(
          color: LuluTextColors.tertiary,
        ),
      );
    }

    // Next nap time estimate
    if (result != null && result.totalExpectedNaps > result.napNumber) {
      final locale = Localizations.localeOf(context).toString();
      final nextTime = DateFormat('a h:mm', locale)
          .format(result.maxSleepTime.add(
        Duration(minutes: result.wakeWindow.midMinutes),
      ));

      return Text(
        widget.isWarmTone
            ? l10n.sweetSpotCardNextNapWarm(nextTime)
            : l10n.sweetSpotCardNextNapPlain(nextTime),
        style: LuluTextStyles.bodySmall.copyWith(
          color: LuluTextColors.tertiary,
        ),
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

    // C-5.2 Phase 3: Stage B — show next nap number
    final napNum = _isOverdueTransitioned()
        ? _nextNapNumber()
        : (result?.napNumber ?? 1);

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
      final count = completed > 0 ? completed : 1;
      return widget.isWarmTone
          ? l10n.sweetSpotCardCalibratingWarm(count)
          : l10n.sweetSpotCardCalibratingPlain(count);
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

    // C-5.2 Phase 3: Overdue transition messages
    if (widget.state == SweetSpotState.overtired) {
      if (_isOverdueTransitioned()) {
        // Stage B: Auto-transitioned to next nap
        final nextRange = _nextNapTimeRange();
        if (nextRange != null) {
          return widget.isWarmTone
              ? l10n.sweetSpotOverdueNextNapWarm
              : l10n.sweetSpotOverdueNextNapPlain;
        }
        // Next nap unpredictable (last nap or night)
        return widget.isWarmTone
            ? l10n.sweetSpotOverdueCueWatchWarm
            : l10n.sweetSpotOverdueCueWatchPlain;
      }
      if (_isOverdueStageA()) {
        // Stage A: Record nudge
        return l10n.sweetSpotOverdueRecordNudge;
      }
      // Default overtired message (before zone end)
      return widget.isWarmTone
          ? l10n.sweetSpotCardAfterZoneWarm
          : l10n.sweetSpotCardAfterZonePlain;
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
    // Hide hint when transitioned to next nap (card already shows next nap info)
    if (_isOverdueTransitioned()) return false;
    final result = widget.sweetSpotResult;
    if (result == null) return false;
    return true;
  }

  // ========================================
  // C-5.2 Phase 3: Overdue → Next Nap Transition
  // ========================================

  /// Minutes past Sweet Spot zone end (maxSleepTime)
  /// Returns null if not in overtired state or no result.
  int? _minutesPastZoneEnd() {
    if (widget.state != SweetSpotState.overtired) return null;
    final result = widget.sweetSpotResult;
    if (result == null) return null;
    final now = DateTime.now();
    final minutesPast = now.difference(result.maxSleepTime).inMinutes;
    return minutesPast > 0 ? minutesPast : null;
  }

  /// Stage A: Sweet Spot ended but < 15 min → show record nudge
  bool _isOverdueStageA() {
    final minutesPast = _minutesPastZoneEnd();
    if (minutesPast == null) return false;
    return minutesPast < 15;
  }

  /// Stage B: 15+ min past Sweet Spot → auto-transition to next nap
  bool _isOverdueTransitioned() {
    final minutesPast = _minutesPastZoneEnd();
    if (minutesPast == null) return false;
    return minutesPast >= 15;
  }

  /// Clamp progress to 1.0 max when in overdue stage A (no overflow)
  double _clampedProgress(double rawProgress) {
    if (_isOverdueStageA()) return rawProgress.clamp(0.0, 1.0);
    return rawProgress;
  }

  /// Next nap predicted time range (for Stage B display)
  /// Uses maxSleepTime + midMinutes to estimate next nap start.
  /// Returns (minTime, maxTime) or null if not predictable.
  ({DateTime min, DateTime max})? _nextNapTimeRange() {
    final result = widget.sweetSpotResult;
    if (result == null) return null;
    // Cannot predict if this is the last nap or night
    if (result.napNumber >= result.totalExpectedNaps) return null;
    if (result.isNightTime) return null;

    final nextWakeEstimate = result.maxSleepTime.add(
      Duration(minutes: result.wakeWindow.midMinutes),
    );
    // Next nap's sweet spot: nextWake + next wake window range
    final nextMin = nextWakeEstimate.add(
      Duration(minutes: result.wakeWindow.minMinutes),
    );
    final nextMax = nextWakeEstimate.add(
      Duration(minutes: result.wakeWindow.maxMinutes),
    );
    return (min: nextMin, max: nextMax);
  }

  /// Next nap number (current + 1)
  int _nextNapNumber() {
    final result = widget.sweetSpotResult;
    if (result == null) return 2;
    return result.napNumber + 1;
  }
}
