import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/design_system/lulu_colors.dart';
import '../../core/design_system/lulu_icons.dart';
import '../../core/design_system/lulu_typography.dart';

/// Error fallback screen displayed when an unrecoverable error occurs.
///
/// Sprint 21 Phase 5-3: Prevents blank screen on crash.
/// Shows a friendly error message with restart button.
class ErrorFallbackScreen extends StatelessWidget {
  final FlutterErrorDetails? errorDetails;

  const ErrorFallbackScreen({super.key, this.errorDetails});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: LuluColors.midnightNavy,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LuluIcons.health,
                  size: 64,
                  color: LuluColors.softBlue,
                ),
                const SizedBox(height: 24),
                Text(
                  'Something went wrong',
                  style: LuluTextStyles.titleLarge.copyWith(
                    color: LuluTextColors.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'An unexpected error occurred.\nPlease restart the app.',
                  style: LuluTextStyles.bodyMedium.copyWith(
                    color: LuluTextColors.secondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => exit(0),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LuluColors.lavenderMist,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Restart App',
                    style: LuluTextStyles.labelLarge.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
