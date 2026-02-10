import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/services/supabase_service.dart';
import 'core/services/openai_service.dart';
import 'core/services/onboarding_data_service.dart';
import 'core/services/deep_link_service.dart';
import 'core/services/family_sync_service.dart';
import 'features/family/providers/family_provider.dart';
import 'features/auth/auth.dart';
import 'core/theme/app_theme.dart';
import 'features/onboarding/onboarding.dart';
import 'features/growth/data/growth_data_cache.dart';
import 'features/home/providers/home_provider.dart';
import 'features/home/providers/sweet_spot_provider.dart';
import 'features/record/providers/feeding_record_provider.dart';
import 'features/record/providers/sleep_record_provider.dart';
import 'features/record/providers/diaper_record_provider.dart';
import 'features/record/providers/play_record_provider.dart';
import 'features/record/providers/health_record_provider.dart';
import 'features/record/providers/ongoing_sleep_provider.dart';
import 'features/settings/providers/settings_provider.dart';
import 'features/cry_analysis/providers/cry_analysis_provider.dart';
import 'app/navigation/main_navigation.dart';
import 'data/models/models.dart';
import 'l10n/generated/app_localizations.dart';

/// Global SettingsProvider instance for async init
late SettingsProvider _settingsProvider;

/// Global AuthProvider instance for async init
late AuthProvider _authProvider;

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

  // Initialize AuthProvider (async)
  _authProvider = AuthProvider();
  await _authProvider.init();

  debugPrint('========================================');
  debugPrint('[INFO] Auth Status: ${_authProvider.status}');
  debugPrint('[INFO] Current User: ${SupabaseService.currentUserId}');
  debugPrint('========================================');

  // 로그인 상태면 Family 동기화 (Supabase에 Family 생성/확인)
  if (_authProvider.isAuthenticated) {
    debugPrint('[INFO] Syncing family data...');
    final familyId = await FamilySyncService.instance.ensureFamilyExists();
    debugPrint('[INFO] Family synced: $familyId');
  }

  await OpenAIService.initialize();

  // Initialize growth data cache (오프라인 지원)
  await GrowthDataCache.instance.initialize();

  // Initialize SettingsProvider (async)
  _settingsProvider = SettingsProvider();
  await _settingsProvider.init();

  // Initialize DeepLinkService (Family Sharing v3.2)
  await DeepLinkService().initialize();

  runApp(const LuluApp());
}

class LuluApp extends StatelessWidget {
  const LuluApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Auth Provider (pre-initialized)
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider(create: (_) => SweetSpotProvider()),
        ChangeNotifierProvider(create: (context) {
          final homeProvider = HomeProvider();
          homeProvider.setSweetSpotProvider(context.read<SweetSpotProvider>());
          return homeProvider;
        }),
        ChangeNotifierProvider(create: (_) => FeedingRecordProvider()),
        ChangeNotifierProvider(create: (_) => SleepRecordProvider()),
        ChangeNotifierProvider(create: (_) => DiaperRecordProvider()),
        ChangeNotifierProvider(create: (_) => PlayRecordProvider()),
        ChangeNotifierProvider(create: (_) => HealthRecordProvider()),
        ChangeNotifierProvider(create: (_) {
          final provider = OngoingSleepProvider();
          provider.init(); // 앱 시작 시 진행 중 수면 복원
          return provider;
        }),
        ChangeNotifierProvider.value(value: _settingsProvider),
        // Phase 2: 울음 분석 Provider
        ChangeNotifierProvider(create: (_) => CryAnalysisProvider()),
        // Family Sharing v3.2
        ChangeNotifierProvider(create: (_) => FamilyProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return MaterialApp(
            title: 'Lulu',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.darkTheme,
            // Localization
            localizationsDelegates: const [
              S.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: S.supportedLocales,
            locale: settings.locale,
            home: const _AppRouter(),
          );
        },
      ),
    );
  }
}

/// 앱 라우터
/// 인증 상태에 따라 Login → Onboarding → Main 흐름 제어
class _AppRouter extends StatelessWidget {
  const _AppRouter();

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // 로그인 안 된 경우 → LoginScreen
        if (!authProvider.isAuthenticated) {
          return LoginScreen(
            onLoginSuccess: () {
              // 로그인 성공 시 rebuild됨 (Consumer가 감지)
            },
          );
        }

        // 로그인 된 경우 → OnboardingWrapper로 진행
        return const _OnboardingWrapper();
      },
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

  /// BUG-008 HOTFIX: Supabase 우선 확인 (family_members 테이블 사용)
  /// 1. family_members에서 현재 사용자의 가족 확인
  /// 2. 없으면 families.user_id로 fallback (레거시 호환 + 자동 마이그레이션)
  /// 3. 있으면 families + babies 로드 후 온보딩 스킵
  /// 4. 없으면 로컬 확인 후 온보딩 진행
  Future<void> _checkOnboardingStatus() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      if (userId != null) {
        debugPrint('[CHECK] Checking Supabase for user: $userId');

        String? familyId;

        // ✅ 1. family_members에서 현재 사용자의 가족 확인
        try {
          final memberData = await supabase
              .from('family_members')
              .select('family_id')
              .eq('user_id', userId)
              .maybeSingle();

          if (memberData != null && memberData['family_id'] != null) {
            familyId = memberData['family_id'] as String;
            debugPrint('[OK] Found family via family_members: $familyId');
          }
        } catch (e) {
          // family_members 테이블이 없을 수 있음 (마이그레이션 전)
          debugPrint('[WARN] family_members query failed: $e');
        }

        // ✅ 2. fallback: families.user_id로 확인 (레거시 호환)
        if (familyId == null) {
          final familyData = await supabase
              .from('families')
              .select('id')
              .eq('user_id', userId)
              .maybeSingle();

          if (familyData != null) {
            familyId = familyData['id'] as String;
            debugPrint('[OK] Found family via families.user_id (legacy): $familyId');

            // 자동 마이그레이션: family_members에 owner로 추가
            try {
              await supabase.from('family_members').upsert({
                'family_id': familyId,
                'user_id': userId,
                'role': 'owner',
              });
              debugPrint('[OK] Auto-migrated to family_members');
            } catch (e) {
              debugPrint('[WARN] Auto-migration to family_members failed: $e');
            }
          }
        }

        if (familyId != null) {
          // ✅ 기존 가족 데이터 로드
          final loaded = await _loadExistingFamilyData(familyId, userId);
          if (loaded) {
            setState(() {
              _hasCompletedOnboarding = true;
              _isLoading = false;
            });
            return; // 온보딩 스킵!
          }
        } else {
          debugPrint('[INFO] No family found in Supabase for user');
        }
      }

      // 2. Supabase에 없으면 로컬 확인 (기존 로직)
      final service = OnboardingDataService.instance;
      final isCompleted = await service.isOnboardingCompleted();

      if (isCompleted) {
        final family = await service.loadFamily();
        final babies = await service.loadBabies();

        if (family != null && babies.isNotEmpty) {
          debugPrint('[OK] [OnboardingWrapper] Restored from local: family=${family.id}, babies=${babies.map((b) => b.name).join(", ")}');

          // ✅ RLS FIX: 로컬 복원 시에도 family_members에 현재 사용자 추가
          final currentUserId = Supabase.instance.client.auth.currentUser?.id;
          if (currentUserId != null) {
            try {
              await Supabase.instance.client.from('family_members').upsert({
                'family_id': family.id,
                'user_id': currentUserId,
                'role': 'owner',
              });
              debugPrint('[OK] Ensured user in family_members (local restore)');
            } catch (e) {
              debugPrint('[WARN] family_members upsert failed: $e');
            }
          }

          // Provider에 즉시 데이터 설정 (mounted 체크 후)
          if (mounted) {
            final homeProvider = context.read<HomeProvider>();
            homeProvider.setFamily(family, babies);
            // FIX-C: 오늘 활동 로드 추가
            await homeProvider.loadTodayActivities();
            _providerInitialized = true;
          }

          setState(() {
            _hasCompletedOnboarding = true;
          });
        }
      }

      setState(() => _isLoading = false);

    } catch (e) {
      debugPrint('[ERR] [OnboardingWrapper] Error checking status: $e');
      setState(() => _isLoading = false);
    }
  }

  /// Supabase에서 기존 가족 데이터 로드
  /// 🆕 HOTFIX: fromSupabase 사용 (null 안전)
  Future<bool> _loadExistingFamilyData(String familyId, String userId) async {
    try {
      final supabase = Supabase.instance.client;

      // families 테이블에서 가족 정보
      final familyData = await supabase
          .from('families')
          .select()
          .eq('id', familyId)
          .maybeSingle();

      if (familyData == null) {
        debugPrint('[WARN] Family not found in families table: $familyId');
        return false;
      }

      // babies 테이블에서 아기 정보
      final babiesData = await supabase
          .from('babies')
          .select()
          .eq('family_id', familyId)
          .order('created_at', ascending: true);

      // 🆕 HOTFIX: fromSupabase 사용 (null 안전 + snake_case)
      final babies = (babiesData as List)
          .map((b) => BabyModel.fromSupabase(b as Map<String, dynamic>))
          .toList();

      if (babies.isEmpty) {
        debugPrint('[WARN] No babies found for family: $familyId');
        return false;
      }

      // 🆕 HOTFIX: fromSupabase 사용
      final family = FamilyModel.fromSupabase({
        ...familyData,
        'baby_ids': babies.map((b) => b.id).toList(),
      });

      debugPrint('[OK] Loaded from Supabase: ${babies.length} babies');
      debugPrint('  - Family ID: ${family.id}');
      debugPrint('  - Babies: ${babies.map((b) => b.name).join(", ")}');

      if (mounted) {
        final homeProvider = context.read<HomeProvider>();
        homeProvider.setFamily(family, babies);
        // FIX-C: 오늘 활동 로드 추가
        await homeProvider.loadTodayActivities();
        _providerInitialized = true;

        // 로컬에도 저장 (다음 오프라인 시작용)
        await OnboardingDataService.instance.saveOnboardingData(
          family: family,
          babies: babies,
        );
      }

      return true;
    } catch (e) {
      debugPrint('[ERROR] _loadExistingFamilyData: $e');
      return false;
    }
  }

  void _onOnboardingComplete(FamilyModel family, List<BabyModel> babies) {
    // PA-01: HomeProvider에 데이터 즉시 설정
    final homeProvider = context.read<HomeProvider>();
    homeProvider.setFamily(family, babies);
    // FIX-C: 오늘 활동 로드 추가
    homeProvider.loadTodayActivities();
    _providerInitialized = true;

    // 상태 기반 전환 (Navigator.pushReplacement 대신)
    // 이렇게 하면 Provider 컨텍스트가 유지됨
    setState(() {
      _hasCompletedOnboarding = true;
    });

    debugPrint('[OK] [OnboardingWrapper] Onboarding complete - switching to MainNavigation');
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
