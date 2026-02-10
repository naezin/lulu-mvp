import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_radius.dart';
import '../../../core/design_system/lulu_icons.dart';
import '../../../core/utils/app_toast.dart';
import '../../../l10n/generated/app_localizations.dart' show S;

/// 이메일 로그인/회원가입 화면
class EmailLoginScreen extends StatefulWidget {
  final VoidCallback? onLoginSuccess;

  const EmailLoginScreen({
    super.key,
    this.onLoginSuccess,
  });

  @override
  State<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends State<EmailLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nicknameController = TextEditingController();

  bool _isSignUp = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LuluIcons.backIos, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isSignUp
              ? (l10n?.authSignupTitle ?? '')
              : (l10n?.authEmailLoginTitle ?? ''),
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),

                // Email Field
                _buildEmailField(),

                const SizedBox(height: 16),

                // Password Field
                _buildPasswordField(),

                // Nickname Field (Sign Up only)
                if (_isSignUp) ...[
                  const SizedBox(height: 16),
                  _buildNicknameField(),
                ],

                const SizedBox(height: 24),

                // Submit Button
                _buildSubmitButton(),

                const SizedBox(height: 16),

                // Toggle Sign Up / Sign In
                _buildToggleButton(),

                // Forgot Password (Sign In only)
                if (!_isSignUp) ...[
                  const SizedBox(height: 16),
                  _buildForgotPasswordButton(),
                ],

                // Error Message
                Consumer<AuthProvider>(
                  builder: (context, authProvider, _) {
                    if (authProvider.errorMessage != null) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Container(
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
                                  AuthProvider.resolveErrorMessage(S.of(context)!, authProvider.errorMessage),
                                  style: const TextStyle(color: Colors.red, fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    final l10n = S.of(context);
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      autocorrect: false,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: l10n?.authEmailLabel ?? '',
        labelStyle: TextStyle(color: Colors.grey[400]),
        prefixIcon: Icon(LuluIcons.emailOutlined, color: Colors.grey[400]),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(LuluRadius.sm),
          borderSide: BorderSide(color: Colors.grey[600]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(LuluRadius.sm),
          borderSide: const BorderSide(color: Color(0xFF9D8CD6)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(LuluRadius.sm),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(LuluRadius.sm),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return l10n?.authEmailRequired ?? '';
        }
        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
          return l10n?.authEmailInvalid ?? '';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    final l10n = S.of(context);
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: l10n?.authPasswordLabel ?? '',
        labelStyle: TextStyle(color: Colors.grey[400]),
        prefixIcon: Icon(LuluIcons.lockOutlined, color: Colors.grey[400]),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? LuluIcons.visibilityOff : LuluIcons.visibility,
            color: Colors.grey[400],
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(LuluRadius.sm),
          borderSide: BorderSide(color: Colors.grey[600]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(LuluRadius.sm),
          borderSide: const BorderSide(color: Color(0xFF9D8CD6)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(LuluRadius.sm),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(LuluRadius.sm),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return l10n?.authPasswordRequired ?? '';
        }
        if (_isSignUp && value.length < 6) {
          return l10n?.authPasswordMinLength ?? '';
        }
        return null;
      },
    );
  }

  Widget _buildNicknameField() {
    final l10n = S.of(context);
    return TextFormField(
      controller: _nicknameController,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: l10n?.authNicknameLabel ?? '',
        labelStyle: TextStyle(color: Colors.grey[400]),
        prefixIcon: Icon(LuluIcons.personOutlined, color: Colors.grey[400]),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(LuluRadius.sm),
          borderSide: BorderSide(color: Colors.grey[600]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(LuluRadius.sm),
          borderSide: const BorderSide(color: Color(0xFF9D8CD6)),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    final l10n = S.of(context);
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: authProvider.isLoading ? null : _handleSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9D8CD6),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(LuluRadius.sm),
              ),
              disabledBackgroundColor: LuluColors.lavenderMedium,
            ),
            child: authProvider.isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    _isSignUp
                        ? (l10n?.authSignupButton ?? '')
                        : (l10n?.authLoginButton ?? ''),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildToggleButton() {
    final l10n = S.of(context);
    return TextButton(
      onPressed: () {
        setState(() => _isSignUp = !_isSignUp);
        context.read<AuthProvider>().clearError();
      },
      child: Text(
        _isSignUp
            ? (l10n?.authToggleToLogin ?? '')
            : (l10n?.authToggleToSignup ?? ''),
        style: TextStyle(
          color: Colors.grey[400],
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildForgotPasswordButton() {
    final l10n = S.of(context);
    return TextButton(
      onPressed: _handleForgotPassword,
      child: Text(
        l10n?.authForgotPassword ?? '',
        style: TextStyle(
          color: Colors.grey[500],
          fontSize: 14,
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    bool success;

    if (_isSignUp) {
      success = await authProvider.signUpWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        nickname: _nicknameController.text.trim().isNotEmpty
            ? _nicknameController.text.trim()
            : null,
      );
    } else {
      success = await authProvider.signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    }

    if (success && mounted) {
      widget.onLoginSuccess?.call();
      Navigator.pop(context);
    }
  }

  Future<void> _handleForgotPassword() async {
    final l10n = S.of(context);
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      AppToast.showText(l10n?.authEmailRequired ?? '');
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.sendPasswordResetEmail(email);

    if (mounted) {
      final resetL10n = S.of(context);
      AppToast.showText(
        success
            ? (resetL10n?.authPasswordResetSent ?? '')
            : (resetL10n?.authPasswordResetFailed ?? ''),
      );
    }
  }
}
