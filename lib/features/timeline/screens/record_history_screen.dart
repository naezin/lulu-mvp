import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_icons.dart';
import '../../../core/design_system/lulu_typography.dart';
import '../../../data/models/baby_model.dart';
import '../../../l10n/generated/app_localizations.dart' show S;
import '../../../shared/widgets/baby_tab_bar.dart';
import '../../home/providers/home_provider.dart';
import '../widgets/scope_toggle.dart';
import '../widgets/daily_view.dart';
import '../widgets/weekly_view.dart';

/// 기록 히스토리 화면 (통합)
///
/// Sprint 18-R Hotfix FIX-A: TabBar 완전 제거
/// - ScopeToggle: body 최상단에서 일간/주간 전환
/// - 일간: DailyView (날짜 탐색 + 필터 + 타임라인 + 기록 목록)
/// - 주간: WeeklyView (WeeklyPatternChart + 통계)
class RecordHistoryScreen extends StatefulWidget {
  const RecordHistoryScreen({super.key});

  @override
  State<RecordHistoryScreen> createState() => _RecordHistoryScreenState();
}

class _RecordHistoryScreenState extends State<RecordHistoryScreen> {
  /// 일간/주간 스코프 (false = 일간, true = 주간)
  bool _isWeeklyScope = false;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);

    return Scaffold(
      backgroundColor: LuluColors.midnightNavy,
      appBar: AppBar(
        backgroundColor: LuluColors.midnightNavy,
        elevation: 0,
        title: Text(
          l10n?.recordHistoryTitle ?? '기록',
          style: LuluTextStyles.titleLarge.copyWith(
            color: LuluTextColors.primary,
          ),
        ),
        centerTitle: true,
        // FIX-A: TabBar 완전 제거 - bottom 속성 삭제
      ),
      // Sprint 21 Phase 2-4: Selector for babies + selectedBabyId only
      body: Selector<HomeProvider, ({List<BabyModel> babies, String? selectedBabyId})>(
        selector: (_, p) => (babies: p.babies, selectedBabyId: p.selectedBabyId),
        builder: (context, data, child) {
          // 아기 정보가 없으면 빈 상태
          if (data.babies.isEmpty) {
            return _buildEmptyBabiesState();
          }

          return Column(
            children: [
              // BabyTabBar (아기 2명 이상일 때만 표시)
              if (data.babies.length > 1)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: BabyTabBar(
                    babies: data.babies,
                    selectedBabyId: data.selectedBabyId,
                    onBabyChanged: (babyId) {
                      context.read<HomeProvider>().selectBaby(babyId);
                    },
                  ),
                ),

              // FIX-A: ScopeToggle (body 최상단)
              ScopeToggle(
                isWeeklyScope: _isWeeklyScope,
                onScopeChanged: (isWeekly) {
                  setState(() => _isWeeklyScope = isWeekly);
                },
              ),

              // FIX-A: 스코프에 따라 뷰 전환 (TabBarView 대신)
              Expanded(
                child: _isWeeklyScope
                    ? const WeeklyView()
                    : const DailyView(),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 아기 정보 없음 상태
  Widget _buildEmptyBabiesState() {
    final l10n = S.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LuluIcons.baby,
            size: 64,
            color: LuluTextColors.tertiary,
          ),
          const SizedBox(height: 16),
          Text(
            l10n?.emptyBabiesTitle ?? 'No baby info',
            style: LuluTextStyles.titleMedium.copyWith(
              color: LuluTextColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n?.emptyBabiesHint ?? 'Please complete onboarding',
            style: LuluTextStyles.bodyMedium.copyWith(
              color: LuluTextColors.secondary,
            ),
          ),
        ],
      ),
    );
  }
}
