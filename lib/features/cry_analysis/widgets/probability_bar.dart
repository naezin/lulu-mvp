import 'package:flutter/material.dart';

import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_radius.dart';
import '../../../core/design_system/lulu_spacing.dart';
import '../../../core/design_system/lulu_typography.dart';
import '../../../l10n/generated/app_localizations.dart' show S;
import '../models/models.dart';

/// 확률 바 위젯
///
/// Phase 2: AI 울음 분석 기능
/// 각 울음 타입별 확률을 바 형태로 표시
class ProbabilityBar extends StatelessWidget {
  final CryType cryType;
  final double probability;
  final bool isHighlighted;

  const ProbabilityBar({
    super.key,
    required this.cryType,
    required this.probability,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (probability * 100).round();
    final color = isHighlighted ? cryType.color : LuluTextColors.tertiary;

    return Row(
      children: [
        // 아이콘
        Icon(
          cryType.icon,
          size: 18,
          color: color,
        ),
        const SizedBox(width: LuluSpacing.sm),

        // 라벨
        SizedBox(
          width: 72,
          child: Text(
            cryType.localizedLabel(S.of(context)),
            style: LuluTextStyles.caption.copyWith(
              color: isHighlighted ? LuluTextColors.primary : LuluTextColors.secondary,
              fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.normal,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),

        // 바
        Expanded(
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              color: LuluColors.midnightNavy,
              borderRadius: BorderRadius.circular(LuluRadius.indicator),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: probability.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(LuluRadius.indicator),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: LuluSpacing.sm),

        // 퍼센트
        SizedBox(
          width: 40,
          child: Text(
            '$percent%',
            style: LuluTextStyles.caption.copyWith(
              color: isHighlighted ? LuluTextColors.primary : LuluTextColors.tertiary,
              fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.normal,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

/// 확률 분포 전체 위젯
///
/// 모든 울음 타입의 확률을 리스트로 표시
class ProbabilityDistribution extends StatelessWidget {
  final CryAnalysisResult result;
  final int maxItems;

  const ProbabilityDistribution({
    super.key,
    required this.result,
    this.maxItems = 5,
  });

  @override
  Widget build(BuildContext context) {
    final topResults = result.getTopResults(maxItems);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: topResults.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: LuluSpacing.sm),
          child: ProbabilityBar(
            cryType: entry.key,
            probability: entry.value,
            isHighlighted: entry.key == result.cryType,
          ),
        );
      }).toList(),
    );
  }
}
