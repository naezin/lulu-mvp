import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_icons.dart';
import '../../../core/design_system/lulu_radius.dart';
import '../../../l10n/generated/app_localizations.dart' show S;
import '../providers/auth_provider.dart';
import '../widgets/apple_login_button.dart';
import '../widgets/divider_with_text.dart';
import 'email_login_screen.dart';

/// 로그인 화면
/// Apple, Email 로그인 선택 (Google 제거)
class LoginScreen extends StatelessWidget {
  final VoidCallback? onLoginSuccess;

  const LoginScreen({
    super.key,
    this.onLoginSuccess,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Logo & Title
              _buildHeader(),

              const Spacer(flex: 2),

              // Login Buttons
              _buildLoginButtons(context),

              const SizedBox(height: 32),

              // Terms
              _buildTerms(context),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // LULU Logo (온보딩과 동일 - 부엉이 로고, 배경 없음)
        Image.asset(
          'assets/icon/lulu_logo.png',
          width: 120,
          height: 120,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              LuluIcons.moon,
              size: 60,
              color: LuluColors.lavenderMist,
            );
          },
        ),
        const SizedBox(height: 24),

        // App Name
        const Text(
          'LULU',
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 4,
          ),
        ),
        // 태그라인 제거
      ],
    );
  }

  Widget _buildLoginButtons(BuildContext context) {
    final l10n = S.of(context)!;
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return Column(
          children: [
            // Apple Login
            AppleLoginButton(
              isLoading: authProvider.isLoading,
              onPressed: () => _handleAppleLogin(context),
            ),

            const SizedBox(height: 24),

            // Divider
            DividerWithText(text: l10n.authOrDivider),

            const SizedBox(height: 24),

            // Email Login (ElevatedButton으로 변경)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => _navigateToEmailLogin(context),
                icon: const Icon(LuluIcons.emailOutlined, size: 20),
                label: Text(
                  l10n.authEmailLogin,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: LuluColors.surfaceCard,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(LuluRadius.sm),
                  ),
                ),
              ),
            ),

            // Error Message
            if (authProvider.errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: LuluColors.redBg,
                  borderRadius: BorderRadius.circular(LuluRadius.xs),
                ),
                child: Row(
                  children: [
                    const Icon(LuluIcons.errorOutline, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        AuthProvider.resolveErrorMessage(l10n, authProvider.errorMessage),
                        style: const TextStyle(color: Colors.red, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildTerms(BuildContext context) {
    final l10n = S.of(context)!;
    return Text.rich(
      TextSpan(
        text: l10n.authTermsPrefix,
        style: TextStyle(color: Colors.grey[500], fontSize: 12),
        children: [
          TextSpan(
            text: l10n.authTermsOfService,
            style: const TextStyle(
              decoration: TextDecoration.underline,
            ),
          ),
          TextSpan(text: l10n.authTermsAnd),
          TextSpan(
            text: l10n.authPrivacyPolicy,
            style: const TextStyle(
              decoration: TextDecoration.underline,
            ),
          ),
          TextSpan(text: l10n.authTermsSuffix),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }

  Future<void> _handleAppleLogin(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.signInWithApple();

    if (success && context.mounted) {
      onLoginSuccess?.call();
    }
  }

  void _navigateToEmailLogin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EmailLoginScreen(onLoginSuccess: onLoginSuccess),
      ),
    );
  }
}
