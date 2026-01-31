import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/design_system/lulu_colors.dart';
import '../../core/design_system/lulu_icons.dart';
import '../../core/design_system/lulu_typography.dart';
import '../../shared/widgets/expandable_fab.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/home/providers/home_provider.dart';
import '../../features/timeline/screens/timeline_screen.dart';
import '../../features/growth/screens/growth_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/record/record.dart';

/// 메인 네비게이션 (2단계 UT 검증 완료: 시안 B-4)
///
/// 선정 근거:
/// - SAT: 4.58/5 (최고)
/// - TTC: 3.2초 (3초 Rule 근접)
/// - 핵심 타겟(P2) 만족도: 5.0/5
/// - 확장성: Phase 2/3 수용 가능
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    TimelineScreen(),
    GrowthScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // 온보딩에서 설정된 데이터 확인 로그
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final homeProvider = context.read<HomeProvider>();
      debugPrint('[OK] [MainNavigation] Loaded babies: ${homeProvider.babies.map((b) => b.name).join(", ")}');
    });
  }

  /// 현재 familyId (HomeProvider에서 가져옴)
  String get _currentFamilyId {
    return context.read<HomeProvider>().family?.id ?? 'temp-family-id';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LuluColors.midnightNavy,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      floatingActionButton: LabeledFab(
        onRecord: _handleRecord,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBottomBar() {
    return BottomAppBar(
      color: LuluColors.deepBlue,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      height: 68,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      padding: EdgeInsets.zero,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            icon: LuluIcons.home,
            label: '홈',
            isSelected: _currentIndex == 0,
            onTap: () => _onTabTapped(0),
          ),
          _NavItem(
            icon: LuluIcons.records,
            label: '기록',
            isSelected: _currentIndex == 1,
            onTap: () => _onTabTapped(1),
          ),
          const SizedBox(width: 80), // FAB 공간
          _NavItem(
            icon: LuluIcons.growth,
            label: '성장',
            isSelected: _currentIndex == 2,
            onTap: () => _onTabTapped(2),
          ),
          _NavItem(
            icon: LuluIcons.settings,
            label: '설정',
            isSelected: _currentIndex == 3,
            onTap: () => _onTabTapped(3),
          ),
        ],
      ),
    );
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _handleRecord(String type) {
    debugPrint('Record type: $type');

    final homeProvider = context.read<HomeProvider>();
    final babies = homeProvider.babies;
    final selectedBabyId = homeProvider.selectedBabyId;

    // 온보딩에서 전달받은 familyId 사용
    final familyId = _currentFamilyId;

    if (babies.isEmpty) {
      // 아기 정보가 없으면 안내 메시지
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('아기 정보를 먼저 등록해주세요'),
          backgroundColor: LuluColors.surfaceElevated,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    // 기록 타입에 따라 화면 이동
    Widget? screen;
    switch (type) {
      case 'feeding':
        screen = FeedingRecordScreen(
          familyId: familyId,
          babies: babies,
          preselectedBabyId: selectedBabyId,
        );
        break;
      case 'sleep':
        screen = SleepRecordScreen(
          familyId: familyId,
          babies: babies,
          preselectedBabyId: selectedBabyId,
        );
        break;
      case 'diaper':
        screen = DiaperRecordScreen(
          familyId: familyId,
          babies: babies,
          preselectedBabyId: selectedBabyId,
        );
        break;
      case 'play':
        screen = PlayRecordScreen(
          familyId: familyId,
          babies: babies,
          preselectedBabyId: selectedBabyId,
        );
        break;
      case 'health':
        screen = HealthRecordScreen(
          familyId: familyId,
          babies: babies,
          preselectedBabyId: selectedBabyId,
        );
        break;
    }

    if (screen != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => screen!,
          fullscreenDialog: true,
        ),
      ).then((result) {
        // 기록 저장 후 홈 화면 새로고침
        if (result != null && mounted) {
          homeProvider.addActivity(result);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('기록이 저장되었습니다'),
              backgroundColor: LuluStatusColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      });
    }
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: isSelected ? 24 : 20,
              color: isSelected
                  ? LuluColors.lavenderMist
                  : LuluTextColors.secondary,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: LuluTextStyles.caption.copyWith(
                color: isSelected
                    ? LuluColors.lavenderMist
                    : LuluTextColors.secondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 10,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
