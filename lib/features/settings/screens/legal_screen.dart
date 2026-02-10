import 'package:flutter/material.dart';

import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_typography.dart';
import '../../../l10n/generated/app_localizations.dart' show S;

/// Legal document display screen (Privacy Policy / Terms of Service)
///
/// Sprint 21 Phase 5-2: App Store requirement.
/// Displays in-app markdown-style text for privacy policy and terms.
class LegalScreen extends StatelessWidget {
  final LegalDocType docType;

  const LegalScreen({super.key, required this.docType});

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context)!;

    return Scaffold(
      backgroundColor: LuluColors.midnightNavy,
      appBar: AppBar(
        backgroundColor: LuluColors.midnightNavy,
        elevation: 0,
        title: Text(
          docType == LegalDocType.privacyPolicy
              ? l10n.authPrivacyPolicy
              : l10n.authTermsOfService,
          style: LuluTextStyles.titleLarge.copyWith(
            color: LuluTextColors.primary,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: LuluTextColors.primary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Text(
          docType == LegalDocType.privacyPolicy
              ? _getPrivacyPolicyText(l10n)
              : _getTermsOfServiceText(l10n),
          style: LuluTextStyles.bodyMedium.copyWith(
            color: LuluTextColors.secondary,
            height: 1.6,
          ),
        ),
      ),
    );
  }

  String _getPrivacyPolicyText(S l10n) {
    return l10n.privacyPolicyFullText;
  }

  String _getTermsOfServiceText(S l10n) {
    return l10n.termsOfServiceFullText;
  }
}

/// Legal document type
enum LegalDocType {
  privacyPolicy,
  termsOfService,
}
