import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'core/services/supabase_service.dart';
import 'core/services/openai_service.dart';
import 'core/services/onboarding_data_service.dart';
import 'core/theme/app_theme.dart';
import 'features/onboarding/onboarding.dart';
import 'features/growth/data/growth_data_cache.dart';
import 'features/home/providers/home_provider.dart';
import 'features/record/providers/record_provider.dart';
import 'app/navigation/main_navigation.dart';
import 'data/models/models.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize locale data for date formatting (한국어)
  await initializeDateFormatting('ko_KR', null);

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Initialize services
  await SupabaseService.initialize();
  await OpenAIService.initialize();

  // Initialize growth data cache (오프라인 지원)
  await GrowthDataCache.instance.initialize();

  runApp(const LuluApp());
}

class LuluApp extends StatelessWidget {
  const LuluApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HomeProvider()),
        ChangeNotifierProvider(create: (_) => RecordProvider()),
      ],
      child: MaterialApp(
        title: 'Lulu',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const _OnboardingWrapper(),
      ),
    );
  }
}

/// 온보딩 완료 후 네비게이션을 위한 래퍼 (StatefulWidget)
///
/// BUG-001 fix: Navigator.pushReplacement 시 Provider 데이터 유실 방지
/// - initState에서 저장된 온보딩 데이터 확인
/// - 있으면 바로 MainNavigation으로 이동
/// - 없으면 OnboardingScreen 표시
class _OnboardingWrapper extends StatefulWidget {
  const _OnboardingWrapper();

  @override
  State<_OnboardingWrapper> createState() => _OnboardingWrapperState();
}

class _OnboardingWrapperState extends State<_OnboardingWrapper> {
  bool _isLoading = true;
  bool _hasCompletedOnboarding = false;
  bool _providerInitialized = false;

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    final service = OnboardingDataService.instance;
    final isCompleted = await service.isOnboardingCompleted();

    if (isCompleted) {
      final family = await service.loadFamily();
      final babies = await service.loadBabies();

      if (family != null && babies.isNotEmpty) {
        debugPrint('✅ [OnboardingWrapper] Restored: family=${family.id}, babies=${babies.map((b) => b.name).join(", ")}');

        // Provider에 즉시 데이터 설정 (mounted 체크 후)
        if (mounted) {
          context.read<HomeProvider>().setFamily(family, babies);
          _providerInitialized = true;
        }

        setState(() {
          _hasCompletedOnboarding = true;
        });
      }
    }

    setState(() => _isLoading = false);
  }

  void _onOnboardingComplete(FamilyModel family, List<BabyModel> babies) {
    // HomeProvider에 데이터 설정
    context.read<HomeProvider>().setFamily(family, babies);

    // 메인 네비게이션으로 이동
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const MainNavigation(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 로딩 중
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0D1B2A),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF9D8CD6),
          ),
        ),
      );
    }

    // 온보딩 완료된 경우 - MainNavigation 표시
    // Provider는 _checkOnboardingStatus에서 이미 설정됨
    if (_hasCompletedOnboarding && _providerInitialized) {
      return const MainNavigation();
    }

    // 온보딩 미완료 - OnboardingScreen 표시
    return OnboardingScreen(
      onCompleteWithData: _onOnboardingComplete,
    );
  }
}
