part of 'import_screen.dart';

/// Import Screen - Private Widget Components
///
/// Extracted from import_screen.dart for file size management.
/// Contains _FileTypeCard, _PreviewRow, _ResultRow.

/// File type selection card
class _FileTypeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _FileTypeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(LuluRadius.md),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: LuluColors.surfaceCard,
          borderRadius: BorderRadius.circular(LuluRadius.md),
          border: Border.all(color: LuluColors.glassBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: LuluColors.surfaceElevated,
                borderRadius: BorderRadius.circular(LuluRadius.sm),
              ),
              child: Icon(
                icon,
                color: LuluColors.lavenderMist,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: LuluTextColors.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: LuluTextColors.secondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              LuluIcons.chevronRight,
              color: LuluTextColors.secondary,
            ),
          ],
        ),
      ),
    );
  }
}

/// Preview row
class _PreviewRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final int count;
  final bool isBold;

  const _PreviewRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.count,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            color: LuluTextColors.primary,
          ),
        ),
        const Spacer(),
        Text(
          S.of(context)!.countItems(count),
          style: TextStyle(
            fontSize: 15,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            color: LuluTextColors.primary,
          ),
        ),
      ],
    );
  }
}

/// Result row
class _ResultRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final int count;

  const _ResultRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            color: LuluTextColors.primary,
          ),
        ),
        const Spacer(),
        Text(
          S.of(context)!.countItems(count),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: LuluTextColors.primary,
          ),
        ),
      ],
    );
  }
}
