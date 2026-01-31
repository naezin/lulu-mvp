import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase 초기화 및 클라이언트 관리 서비스
class SupabaseService {
  static SupabaseClient? _client;

  /// Supabase 클라이언트 인스턴스
  static SupabaseClient get client {
    if (_client == null) {
      throw StateError(
        'Supabase가 초기화되지 않았습니다. SupabaseService.initialize()를 먼저 호출하세요.',
      );
    }
    return _client!;
  }

  /// 초기화 여부 확인
  static bool get isInitialized => _client != null;

  /// Supabase 초기화
  /// main.dart에서 앱 시작 시 호출
  static Future<void> initialize() async {
    if (_client != null) {
      debugPrint('[WARN] Supabase already initialized');
      return;
    }

    final url = dotenv.env['SUPABASE_URL'];
    final anonKey = dotenv.env['SUPABASE_ANON_KEY'];

    if (url == null || url.isEmpty) {
      throw StateError('SUPABASE_URL이 .env 파일에 설정되지 않았습니다.');
    }

    if (anonKey == null || anonKey.isEmpty) {
      throw StateError('SUPABASE_ANON_KEY가 .env 파일에 설정되지 않았습니다.');
    }

    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
      debug: kDebugMode,
    );

    _client = Supabase.instance.client;
    debugPrint('[OK] Supabase initialized successfully');
  }

  /// 현재 인증된 사용자
  static User? get currentUser => _client?.auth.currentUser;

  /// 현재 사용자 ID
  static String? get currentUserId => currentUser?.id;

  /// 로그인 여부 확인
  static bool get isLoggedIn => currentUser != null;

  /// 인증 상태 변경 스트림
  static Stream<AuthState> get authStateChanges =>
      client.auth.onAuthStateChange;

  // ========================================
  // 테이블 참조 헬퍼
  // ========================================

  /// families 테이블
  static SupabaseQueryBuilder get families => client.from('families');

  /// babies 테이블
  static SupabaseQueryBuilder get babies => client.from('babies');

  /// activities 테이블
  static SupabaseQueryBuilder get activities => client.from('activities');
}
