import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_typography.dart';
import '../../../l10n/generated/app_localizations.dart' show S;
import '../../home/providers/home_provider.dart';
import '../widgets/timeline_tab.dart';
import '../widgets/statistics_tab.dart';

/// 기록 히스토리 화면 (통합)
///
/// 작업 지시서 v1.0: TabBar로 [타임라인 | 통계] 통합
/// - 타임라인 탭: 날짜별 기록 목록
/// - 통계 탭: 주간 통계 요약
class RecordHistoryScreen extends StatefulWidget {
  const RecordHistoryScreen({super.key});

  @override
  State<RecordHistoryScreen> createState() => _RecordHistoryScreenState();
}

class _RecordHistoryScreenState extends State<RecordHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: LuluColors.lavenderMist,
          indicatorWeight: 3,
          labelColor: LuluColors.lavenderMist,
          unselectedLabelColor: LuluTextColors.secondary,
          labelStyle: LuluTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: LuluTextStyles.bodyMedium,
          tabs: [
            Tab(text: l10n?.tabTimeline ?? '타임라인'),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bar_chart_rounded, size: 18),
                  const SizedBox(width: 4),
                  Text(l10n?.tabStatistics ?? '통계'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Consumer<HomeProvider>(
        builder: (context, homeProvider, child) {
          // 아기 정보가 없으면 빈 상태
          if (homeProvider.babies.isEmpty) {
            return _buildEmptyBabiesState();
          }

          return TabBarView(
            controller: _tabController,
            children: const [
              TimelineTab(),
              StatisticsTab(),
            ],
          );
        },
      ),
    );
  }

  /// 아기 정보 없음 상태
  Widget _buildEmptyBabiesState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.child_care_rounded,
            size: 64,
            color: LuluTextColors.tertiary,
          ),
          const SizedBox(height: 16),
          Text(
            '아기 정보가 없습니다',
            style: LuluTextStyles.titleMedium.copyWith(
              color: LuluTextColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '온보딩을 완료해주세요',
            style: LuluTextStyles.bodyMedium.copyWith(
              color: LuluTextColors.secondary,
            ),
          ),
        ],
      ),
    );
  }
}
