import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/services/profile_service.dart';
import '../../../data/models/profile_model.dart';

/// 인증 상태
enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

/// 인증 Provider
/// 로그인/로그아웃 상태 관리
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService.instance;
  final ProfileService _profileService = ProfileService.instance;

  AuthStatus _status = AuthStatus.initial;
  ProfileModel? _profile;
  String? _errorMessage;
  bool _isLoading = false;

  // Getters
  AuthStatus get status => _status;
  ProfileModel? get profile => _profile;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  User? get currentUser => _authService.currentUser;

  /// 초기화 - 현재 세션 확인
  Future<void> init() async {
    debugPrint('[INFO] AuthProvider: Initializing...');

    final session = _authService.currentSession;
    if (session != null) {
      await _loadProfile();
      _status = AuthStatus.authenticated;
    } else {
      _status = AuthStatus.unauthenticated;
    }

    // 인증 상태 변경 리스닝
    _authService.authStateChanges.listen(_onAuthStateChanged);

    notifyListeners();
    debugPrint('[OK] AuthProvider: Initialized - status: $_status');
  }

  /// 인증 상태 변경 핸들러
  void _onAuthStateChanged(AuthState state) {
    debugPrint('[INFO] AuthProvider: Auth state changed - ${state.event}');

    switch (state.event) {
      case AuthChangeEvent.signedIn:
        _handleSignedIn();
        break;
      case AuthChangeEvent.signedOut:
        _handleSignedOut();
        break;
      case AuthChangeEvent.tokenRefreshed:
        // Token refreshed, no action needed
        break;
      case AuthChangeEvent.userUpdated:
        _loadProfile();
        break;
      default:
        break;
    }
  }

  Future<void> _handleSignedIn() async {
    await _loadProfile();
    _status = AuthStatus.authenticated;
    _errorMessage = null;
    notifyListeners();
  }

  void _handleSignedOut() {
    _profile = null;
    _status = AuthStatus.unauthenticated;
    _errorMessage = null;
    notifyListeners();
  }

  /// 프로필 로드
  Future<void> _loadProfile() async {
    _profile = await _profileService.getCurrentProfile();
    debugPrint('[INFO] AuthProvider: Profile loaded - ${_profile?.nickname}');
  }

  // ========================================
  // Sign In Methods
  // ========================================

  /// Apple 로그인
  Future<bool> signInWithApple() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await _authService.signInWithApple();
      await _loadProfile();
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Google 로그인
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await _authService.signInWithGoogle();
      // OAuth는 redirect로 처리되므로 여기서는 true 반환
      // 실제 로그인 완료는 authStateChanges에서 처리
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 이메일 회원가입
  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    String? nickname,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final response = await _authService.signUpWithEmail(
        email: email,
        password: password,
        nickname: nickname,
      );

      if (response.user != null) {
        await _loadProfile();
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      }

      return false;
    } on AuthException catch (e) {
      _errorMessage = _translateAuthError(e.message);
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 이메일 로그인
  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final response = await _authService.signInWithEmail(
        email: email,
        password: password,
      );

      if (response.user != null) {
        await _loadProfile();
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      }

      return false;
    } on AuthException catch (e) {
      _errorMessage = _translateAuthError(e.message);
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 비밀번호 재설정 이메일 발송
  Future<bool> sendPasswordResetEmail(String email) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await _authService.sendPasswordResetEmail(email);
      return true;
    } on AuthException catch (e) {
      _errorMessage = _translateAuthError(e.message);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 로그아웃
  Future<void> signOut() async {
    _setLoading(true);

    try {
      await _authService.signOut();
      _profile = null;
      _status = AuthStatus.unauthenticated;
      _errorMessage = null;
    } catch (e) {
      debugPrint('[ERROR] AuthProvider.signOut: $e');
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  /// 프로필 업데이트
  Future<bool> updateProfile({required String nickname}) async {
    _setLoading(true);

    try {
      final updatedProfile = await _profileService.updateProfile(
        nickname: nickname,
      );

      if (updatedProfile != null) {
        _profile = updatedProfile;
        notifyListeners();
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('[ERROR] AuthProvider.updateProfile: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 에러 클리어
  void clearError() {
    _errorMessage = null;
    if (_status == AuthStatus.error) {
      _status = _authService.isLoggedIn
          ? AuthStatus.authenticated
          : AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  // ========================================
  // Helper Methods
  // ========================================

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Supabase 에러 메시지 한글화
  String _translateAuthError(String message) {
    if (message.contains('Invalid login credentials')) {
      return '이메일 또는 비밀번호가 올바르지 않습니다.';
    }
    if (message.contains('Email not confirmed')) {
      return '이메일 인증이 필요합니다. 메일함을 확인해주세요.';
    }
    if (message.contains('User already registered')) {
      return '이미 가입된 이메일입니다.';
    }
    if (message.contains('Password should be at least')) {
      return '비밀번호는 최소 6자 이상이어야 합니다.';
    }
    if (message.contains('Unable to validate email')) {
      return '유효한 이메일 주소를 입력해주세요.';
    }
    if (message.contains('취소')) {
      return message;
    }
    return '오류가 발생했습니다. 다시 시도해주세요.';
  }
}
