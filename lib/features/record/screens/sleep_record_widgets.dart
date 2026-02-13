part of 'sleep_record_screen.dart';

/// Sleep Record - Private Widget Components
///
/// Extracted from sleep_record_screen.dart for file size management.
/// Contains _ModeButton, _IntegratedTimeButton.
/// C-0.4: _SleepTypeButton removed (auto-classified by SleepClassifier).

class _ModeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? LuluActivityColors.sleepBg
              : LuluColors.surfaceElevated,
          borderRadius: BorderRadius.circular(LuluRadius.sm),
          border: Border.all(
            color: isSelected
                ? LuluActivityColors.sleep
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? LuluActivityColors.sleep
                  : LuluTextColors.secondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: LuluTextStyles.labelMedium.copyWith(
                color: isSelected
                    ? LuluActivityColors.sleep
                    : LuluTextColors.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// HOTFIX v1.1: Integrated date/time button
class _IntegratedTimeButton extends StatelessWidget {
  final DateTime time;
  final VoidCallback onTap;

  const _IntegratedTimeButton({
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: S.of(context)!.labelTimeSelect,
      child: Material(
        color: LuluColors.surfaceElevated,
        borderRadius: BorderRadius.circular(LuluRadius.sm),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(LuluRadius.sm),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: LuluSpacing.lg,
              vertical: LuluSpacing.md,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LuluIcons.time,
                  size: 20,
                  color: LuluActivityColors.sleep,
                ),
                const SizedBox(width: LuluSpacing.sm),
                Text(
                  DateFormat('MMM d (E) a h:mm', Localizations.localeOf(context).languageCode).format(time),
                  style: LuluTextStyles.bodyMedium.copyWith(
                    color: LuluTextColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: LuluSpacing.sm),
                Icon(
                  LuluIcons.chevronDown,
                  size: 20,
                  color: LuluTextColors.tertiary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// C-0.4: _SleepTypeButton removed — sleep type auto-classified by SleepClassifier
