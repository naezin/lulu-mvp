import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

/// 인증 서비스
/// Apple Sign In, Email 로그인 지원
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static AuthService get instance => _instance;

  // ========================================
  // Apple Sign In
  // ========================================

  /// Apple Sign In (Native SDK)
  /// iOS에서 Native Apple Sign In을 사용하여 Supabase에 로그인
  Future<AuthResponse> signInWithApple() async {
    try {
      // Generate secure random nonce
      final rawNonce = _generateNonce();
      final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

      // Request Apple credential
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      final idToken = credential.identityToken;
      if (idToken == null) {
        throw AuthException('Apple ID token is null');
      }

      debugPrint('[INFO] AuthService: Apple Sign In - got ID token');

      // Sign in to Supabase with Apple ID token
      final response = await SupabaseService.client.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );

      // Update user metadata with Apple name if available
      if (credential.givenName != null || credential.familyName != null) {
        final fullName = [credential.givenName, credential.familyName]
            .where((s) => s != null && s.isNotEmpty)
            .join(' ');

        if (fullName.isNotEmpty) {
          await SupabaseService.client.auth.updateUser(
            UserAttributes(data: {'full_name': fullName}),
          );
        }
      }

      debugPrint('[OK] AuthService: Apple Sign In success - ${response.user?.id}');
      return response;
    } on SignInWithAppleAuthorizationException catch (e) {
      debugPrint('[ERROR] AuthService.signInWithApple: ${e.code} - ${e.message}');
      if (e.code == AuthorizationErrorCode.canceled) {
        throw AuthException('User canceled sign in.');
      }
      throw AuthException('Apple sign in failed: ${e.message}');
    } on AuthException {
      rethrow;
    } catch (e) {
      debugPrint('[ERROR] AuthService.signInWithApple: $e');
      throw AuthException('An error occurred during Apple sign in.');
    }
  }

  // ========================================
  // Google Sign In
  // ========================================

  /// Google Sign In (OAuth)
  /// Google OAuth를 통해 Supabase에 로그인
  Future<void> signInWithGoogle() async {
    try {
      debugPrint('[INFO] AuthService: Starting Google Sign In');

      await SupabaseService.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'com.lululabs.lulu://login-callback',
        authScreenLaunchMode: LaunchMode.externalApplication,
      );

      debugPrint('[OK] AuthService: Google Sign In initiated');
    } on AuthException {
      rethrow;
    } catch (e) {
      debugPrint('[ERROR] AuthService.signInWithGoogle: $e');
      throw AuthException('An error occurred during Google sign in.');
    }
  }

  // ========================================
  // Email Sign In
  // ========================================

  /// 이메일 회원가입
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    String? nickname,
  }) async {
    try {
      debugPrint('[INFO] AuthService: Email sign up - $email');

      final response = await SupabaseService.client.auth.signUp(
        email: email,
        password: password,
        data: nickname != null ? {'full_name': nickname} : null,
      );

      debugPrint('[OK] AuthService: Email sign up success - ${response.user?.id}');
      return response;
    } on AuthException {
      rethrow;
    } catch (e) {
      debugPrint('[ERROR] AuthService.signUpWithEmail: $e');
      throw AuthException('An error occurred during sign up.');
    }
  }

  /// 이메일 로그인
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('[INFO] AuthService: Email sign in - $email');

      final response = await SupabaseService.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      debugPrint('[OK] AuthService: Email sign in success - ${response.user?.id}');
      return response;
    } on AuthException {
      rethrow;
    } catch (e) {
      debugPrint('[ERROR] AuthService.signInWithEmail: $e');
      throw AuthException('An error occurred during sign in.');
    }
  }

  /// 비밀번호 재설정 이메일 발송
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      debugPrint('[INFO] AuthService: Sending password reset email to $email');

      await SupabaseService.client.auth.resetPasswordForEmail(email);

      debugPrint('[OK] AuthService: Password reset email sent');
    } on AuthException {
      rethrow;
    } catch (e) {
      debugPrint('[ERROR] AuthService.sendPasswordResetEmail: $e');
      throw AuthException('An error occurred while sending password reset email.');
    }
  }

  // ========================================
  // Session Management
  // ========================================

  /// 로그아웃
  Future<void> signOut() async {
    try {
      debugPrint('[INFO] AuthService: Signing out');
      await SupabaseService.client.auth.signOut();
      debugPrint('[OK] AuthService: Sign out success');
    } catch (e) {
      debugPrint('[ERROR] AuthService.signOut: $e');
      throw AuthException('An error occurred during sign out.');
    }
  }

  /// 현재 세션 확인
  Session? get currentSession => SupabaseService.client.auth.currentSession;

  /// 현재 사용자 확인
  User? get currentUser => SupabaseService.currentUser;

  /// 로그인 여부 확인
  bool get isLoggedIn => SupabaseService.isLoggedIn;

  /// 인증 상태 변경 스트림
  Stream<AuthState> get authStateChanges => SupabaseService.authStateChanges;

  // ========================================
  // Helper Methods
  // ========================================

  /// Generate secure random nonce for Apple Sign In
  String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }
}
