import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_icons.dart';
import '../../../core/design_system/lulu_radius.dart';
import '../../../core/design_system/lulu_spacing.dart';
import '../../../core/design_system/lulu_typography.dart';
import '../../../core/services/export_service.dart';
import '../../../data/models/baby_model.dart';
import '../../../data/repositories/baby_repository.dart';
import '../../../data/repositories/activity_repository.dart';
import '../../../l10n/generated/app_localizations.dart' show S;
import '../../home/providers/home_provider.dart';
import '../../family/providers/family_provider.dart';
import '../../family/screens/family_screen.dart';
import '../providers/settings_provider.dart';
import '../widgets/add_baby_dialog.dart';
import '../widgets/delete_baby_dialog.dart';
import 'import_screen.dart';

/// 설정 화면
///
/// MVP-F 기능:
/// - 데이터 내보내기 (CSV) - 날짜 범위 선택 지원
/// - 아기 추가/삭제
/// - 앱 정보
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isExporting = false;
  ExportPeriod _selectedPeriod = ExportPeriod.week;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context)!;

    return Scaffold(
      backgroundColor: LuluColors.midnightNavy,
      appBar: AppBar(
        backgroundColor: LuluColors.midnightNavy,
        elevation: 0,
        title: Text(
          l10n.screenTitleSettings,
          style: LuluTextStyles.titleLarge.copyWith(
            color: LuluTextColors.primary,
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<HomeProvider>(
        builder: (context, homeProvider, child) {
          return SingleChildScrollView(
            padding: LuluSpacing.screenPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 아기 관리 섹션
                _buildSectionHeader(l10n.sectionBabyManagement),
                const SizedBox(height: LuluSpacing.md),
                _buildBabyManagementSection(homeProvider),

                const SizedBox(height: LuluSpacing.xxxl),

                // 가족 관리 섹션
                _buildSectionHeader(l10n.familyManagement),
                const SizedBox(height: LuluSpacing.md),
                _buildFamilyTile(context, homeProvider),

                const SizedBox(height: LuluSpacing.xxxl),

                // 데이터 섹션
                _buildSectionHeader(l10n.sectionData),
                const SizedBox(height: LuluSpacing.md),
                _buildExportSection(),

                const SizedBox(height: LuluSpacing.xxxl),

                // 언어 섹션
                _buildSectionHeader(l10n.sectionLanguage),
                const SizedBox(height: LuluSpacing.md),
                _buildLanguageSection(),

                const SizedBox(height: LuluSpacing.xxxl),

                // 앱 정보 섹션
                _buildSectionHeader(l10n.sectionAppInfo),
                const SizedBox(height: LuluSpacing.md),
                _buildInfoTile(l10n.infoVersion, '2.2.2'),
                _buildInfoTile(l10n.infoDeveloper, l10n.infoTeamName),

                const SizedBox(height: LuluSpacing.xxxl),

                // 위험 영역 섹션
                _buildSectionHeader(l10n.sectionDangerZone),
                const SizedBox(height: LuluSpacing.md),
                _buildResetDataTile(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: LuluTextStyles.titleSmall.copyWith(
        color: LuluColors.lavenderMist,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  // ========================================
  // 아기 관리 섹션
  // ========================================

  Widget _buildBabyManagementSection(HomeProvider homeProvider) {
    final babies = homeProvider.babies;

    return Container(
      decoration: BoxDecoration(
        color: LuluColors.surfaceCard,
        borderRadius: BorderRadius.circular(LuluRadius.sm),
      ),
      child: Column(
        children: [
          // 등록된 아기 목록
          ...babies.asMap().entries.map((entry) {
            final index = entry.key;
            final baby = entry.value;
            return Column(
              children: [
                _buildBabyTile(baby, babies.length),
                if (index < babies.length - 1)
                  Divider(
                    height: 1,
                    color: LuluColors.glassBorder,
                    indent: 72,
                  ),
              ],
            );
          }),

          // 아기 추가 버튼 (최대 4명)
          if (babies.length < 4) ...[
            if (babies.isNotEmpty)
              Divider(
                height: 1,
                color: LuluColors.glassBorder,
              ),
            _buildAddBabyTile(homeProvider),
          ],
        ],
      ),
    );
  }

  Widget _buildBabyTile(BabyModel baby, int totalBabies) {
    final ageText = _formatAge(baby);
    final l10n = S.of(context)!;
    final statusText = baby.isPreterm ? l10n.statusPreterm : l10n.statusFullTerm;

    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: _getBabyColor(baby.birthOrder ?? 1).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(LuluRadius.sm),
        ),
        child: Center(
          child: Text(
            baby.name.isNotEmpty ? baby.name[0] : '?',
            style: LuluTextStyles.titleMedium.copyWith(
              color: _getBabyColor(baby.birthOrder ?? 1),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      title: Row(
        children: [
          Text(
            baby.name,
            style: LuluTextStyles.bodyLarge.copyWith(
              color: LuluTextColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: LuluSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: baby.isPreterm
                  ? LuluStatusColors.warningSoft
                  : LuluStatusColors.successSoft,
              borderRadius: BorderRadius.circular(LuluRadius.indicator),
            ),
            child: Text(
              statusText,
              style: LuluTextStyles.caption.copyWith(
                color: baby.isPreterm
                    ? LuluStatusColors.warning
                    : LuluStatusColors.success,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
      subtitle: Text(
        ageText,
        style: LuluTextStyles.caption.copyWith(
          color: LuluTextColors.secondary,
        ),
      ),
      trailing: totalBabies > 1
          ? IconButton(
              icon: Icon(
                LuluIcons.delete,
                color: LuluStatusColors.errorStrong,
                size: 22,
              ),
              onPressed: () => _showDeleteBabyDialog(baby),
            )
          : null,
    );
  }

  Widget _buildAddBabyTile(HomeProvider homeProvider) {
    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: LuluColors.lavenderBg,
          borderRadius: BorderRadius.circular(LuluRadius.sm),
          border: Border.all(
            color: LuluColors.lavenderBorder,
            width: 1.5,
          ),
        ),
        child: const Icon(
          LuluIcons.add,
          color: LuluColors.lavenderMist,
          size: 24,
        ),
      ),
      title: Text(
        S.of(context)!.addBabyTitle,
        style: LuluTextStyles.bodyLarge.copyWith(
          color: LuluColors.lavenderMist,
        ),
      ),
      subtitle: Text(
        S.of(context)!.addBabyMaxHint,
        style: LuluTextStyles.caption.copyWith(
          color: LuluTextColors.tertiary,
        ),
      ),
      onTap: () => _showAddBabyDialog(homeProvider),
    );
  }

  String _formatAge(BabyModel baby) {
    final l10n = S.of(context)!;
    final now = DateTime.now();
    final days = now.difference(baby.birthDate).inDays;

    if (days < 7) {
      return l10n.ageDays(days);
    } else if (days < 30) {
      return l10n.ageWeeks(days ~/ 7);
    } else {
      final months = days ~/ 30;
      if (baby.isPreterm && baby.correctedAgeInMonths != null) {
        return l10n.ageCorrectedMonths(baby.correctedAgeInMonths!, months);
      }
      return l10n.ageMonths(months);
    }
  }

  Color _getBabyColor(int birthOrder) {
    return switch (birthOrder) {
      1 => LuluColors.lavenderMist,
      2 => LuluActivityColors.sleep,
      3 => LuluActivityColors.play,
      4 => LuluActivityColors.health,
      _ => LuluColors.lavenderMist,
    };
  }

  // ========================================
  // 가족 관리 섹션
  // ========================================

  Widget _buildFamilyTile(BuildContext context, HomeProvider homeProvider) {
    final l10n = S.of(context)!;

    return Consumer<FamilyProvider>(
      builder: (context, familyProvider, _) {
        // FamilyProvider 초기화 (가족 ID가 있는 경우)
        if (homeProvider.family != null &&
            familyProvider.familyId != homeProvider.family!.id) {
          // 가족 데이터 로드
          WidgetsBinding.instance.addPostFrameCallback((_) {
            familyProvider.loadFamily(homeProvider.family!.id);
          });
        }

        return Container(
          decoration: BoxDecoration(
            color: LuluColors.surfaceCard,
            borderRadius: BorderRadius.circular(LuluRadius.sm),
          ),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: LuluColors.lavenderLight,
                borderRadius: BorderRadius.circular(LuluRadius.section),
              ),
              child: const Icon(
                LuluIcons.family,
                color: LuluColors.lavenderMist,
                size: 22,
              ),
            ),
            title: Text(
              l10n.familyManagement,
              style: LuluTextStyles.bodyLarge.copyWith(
                color: LuluTextColors.primary,
              ),
            ),
            subtitle: Text(
              familyProvider.memberCount > 0
                  ? l10n.memberCount(familyProvider.memberCount.toString())
                  : l10n.familyInviteHint,
              style: LuluTextStyles.caption.copyWith(
                color: LuluTextColors.secondary,
              ),
            ),
            trailing: const Icon(
              LuluIcons.chevronRight,
              color: LuluTextColors.secondary,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FamilyScreen()),
              );
            },
          ),
        );
      },
    );
  }

  // ========================================
  // 언어 섹션
  // ========================================

  Widget _buildLanguageSection() {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, _) {
        final currentOption = SettingsProvider.supportedLanguages
            .firstWhere((opt) => opt.code == settingsProvider.languageCode);

        return Container(
          decoration: BoxDecoration(
            color: LuluColors.surfaceCard,
            borderRadius: BorderRadius.circular(LuluRadius.sm),
          ),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: LuluColors.lavenderLight,
                borderRadius: BorderRadius.circular(LuluRadius.section),
              ),
              child: const Icon(
                LuluIcons.language,
                color: LuluColors.lavenderMist,
                size: 22,
              ),
            ),
            title: Text(
              currentOption.label,
              style: LuluTextStyles.bodyLarge.copyWith(
                color: LuluTextColors.primary,
              ),
            ),
            trailing: const Icon(
              LuluIcons.chevronRight,
              color: LuluTextColors.secondary,
            ),
            onTap: () => _showLanguageDialog(settingsProvider),
          ),
        );
      },
    );
  }

  void _showLanguageDialog(SettingsProvider settingsProvider) {
    final l10n = S.of(context)!;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: LuluColors.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LuluRadius.md),
        ),
        title: Text(
          l10n.languageChangeConfirm,
          style: LuluTextStyles.titleMedium.copyWith(
            color: LuluTextColors.primary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: SettingsProvider.supportedLanguages.map((option) {
            return RadioListTile<String>(
              value: option.code,
              groupValue: settingsProvider.languageCode,
              title: Text(
                option.label,
                style: LuluTextStyles.bodyLarge.copyWith(
                  color: LuluTextColors.primary,
                ),
              ),
              activeColor: LuluColors.lavenderMist,
              onChanged: (value) async {
                if (value != null) {
                  Navigator.pop(dialogContext);
                  await settingsProvider.setLocale(value);
                }
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              l10n.buttonCancel,
              style: LuluTextStyles.labelLarge.copyWith(
                color: LuluTextColors.secondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========================================
  // 내보내기 섹션
  // ========================================

  Widget _buildExportSection() {
    return Container(
      decoration: BoxDecoration(
        color: LuluColors.surfaceCard,
        borderRadius: BorderRadius.circular(LuluRadius.sm),
      ),
      child: Column(
        children: [
          // 기간 선택
          _buildPeriodSelector(),
          Divider(height: 1, color: LuluColors.glassBorder),
          // CSV 내보내기 버튼
          _buildExportTile(),
          Divider(height: 1, color: LuluColors.glassBorder),
          // 가져오기 버튼
          _buildImportTile(),
        ],
      ),
    );
  }

  Widget _buildImportTile() {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: LuluColors.lavenderLight,
          borderRadius: BorderRadius.circular(LuluRadius.section),
        ),
        child: const Icon(
          LuluIcons.fileUpload,
          color: LuluColors.lavenderMist,
          size: 22,
        ),
      ),
      title: Text(
        S.of(context)!.importRecordsTitle,
        style: LuluTextStyles.bodyLarge.copyWith(
          color: LuluTextColors.primary,
        ),
      ),
      subtitle: Text(
        S.of(context)!.importRecordsHint,
        style: LuluTextStyles.caption.copyWith(
          color: LuluTextColors.secondary,
        ),
      ),
      trailing: const Icon(
        LuluIcons.chevronRight,
        color: LuluTextColors.secondary,
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ImportScreen()),
        );
      },
    );
  }

  Widget _buildPeriodSelector() {
    return Padding(
      padding: const EdgeInsets.all(LuluSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            S.of(context)!.labelExportPeriod,
            style: LuluTextStyles.labelMedium.copyWith(
              color: LuluTextColors.secondary,
            ),
          ),
          const SizedBox(height: LuluSpacing.sm),
          Wrap(
            spacing: LuluSpacing.sm,
            children: ExportPeriod.values.map((period) {
              final isSelected = period == _selectedPeriod;
              return ChoiceChip(
                label: Text(period.localizedLabel(S.of(context)!)),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedPeriod = period);
                  }
                },
                labelStyle: LuluTextStyles.labelMedium.copyWith(
                  color: isSelected
                      ? LuluColors.midnightNavy
                      : LuluTextColors.secondary,
                ),
                selectedColor: LuluColors.lavenderMist,
                backgroundColor: LuluColors.surfaceElevated,
                side: BorderSide(
                  color: isSelected
                      ? LuluColors.lavenderMist
                      : LuluColors.glassBorder,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildExportTile() {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: LuluColors.lavenderLight,
          borderRadius: BorderRadius.circular(LuluRadius.section),
        ),
        child: const Icon(
          LuluIcons.fileDownload,
          color: LuluColors.lavenderMist,
          size: 22,
        ),
      ),
      title: Text(
        S.of(context)!.exportCSVTitle,
        style: LuluTextStyles.bodyLarge.copyWith(
          color: LuluTextColors.primary,
        ),
      ),
      subtitle: Text(
        S.of(context)!.exportToFile(_selectedPeriod.localizedLabel(S.of(context)!)),
        style: LuluTextStyles.caption.copyWith(
          color: LuluTextColors.secondary,
        ),
      ),
      trailing: _isExporting
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: LuluColors.lavenderMist,
              ),
            )
          : const Icon(
              LuluIcons.chevronRight,
              color: LuluTextColors.secondary,
            ),
      onTap: _isExporting ? null : _handleExport,
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Container(
      decoration: BoxDecoration(
        color: LuluColors.surfaceCard,
        borderRadius: BorderRadius.circular(LuluRadius.sm),
      ),
      margin: const EdgeInsets.only(bottom: LuluSpacing.sm),
      child: ListTile(
        title: Text(
          label,
          style: LuluTextStyles.bodyLarge.copyWith(
            color: LuluTextColors.primary,
          ),
        ),
        trailing: Text(
          value,
          style: LuluTextStyles.bodyMedium.copyWith(
            color: LuluTextColors.secondary,
          ),
        ),
      ),
    );
  }

  // ========================================
  // 액션 핸들러
  // ========================================

  Future<void> _handleExport() async {
    final homeProvider = context.read<HomeProvider>();
    final family = homeProvider.family;
    final babies = homeProvider.babies;

    final l10n = S.of(context)!;

    if (family == null) {
      _showSnackBar(l10n.errorNoFamily);
      return;
    }

    setState(() => _isExporting = true);

    try {
      final count = await ExportService.instance.exportByPeriod(
        familyId: family.id,
        babies: babies,
        period: _selectedPeriod,
        l10n: l10n,
      );

      if (count == 0) {
        _showSnackBar(l10n.errorNoRecords);
      }
    } catch (e) {
      _showSnackBar(l10n.errorExportFailed(e.toString()));
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  void _showAddBabyDialog(HomeProvider homeProvider) {
    showDialog(
      context: context,
      builder: (context) => AddBabyDialog(
        familyId: homeProvider.family?.id ?? '',
        existingBabies: homeProvider.babies,
        onBabyAdded: (baby) {
          // HomeProvider 업데이트
          final updatedBabies = [...homeProvider.babies, baby];
          if (homeProvider.family != null) {
            homeProvider.setFamily(
              homeProvider.family!.addBaby(baby.id),
              updatedBabies,
            );
          }
          // 🔧 Sprint 19 G-R4: 토스트 제거 → 햅틱 대체
          HapticFeedback.mediumImpact();
        },
      ),
    );
  }

  void _showDeleteBabyDialog(BabyModel baby) {
    final homeProvider = context.read<HomeProvider>();

    showDialog(
      context: context,
      builder: (context) => DeleteBabyDialog(
        baby: baby,
        onConfirm: () async {
          try {
            // 활동 삭제 + 아기 삭제
            final activityRepo = ActivityRepository();
            final babyRepo = BabyRepository();

            // 해당 아기의 활동 삭제
            final activities = await activityRepo.getActivitiesByBabyId(baby.id);
            for (final activity in activities) {
              await activityRepo.deleteActivity(activity.id);
            }

            // 아기 삭제
            await babyRepo.deleteBaby(baby.id);

            // HomeProvider 업데이트
            if (homeProvider.family != null) {
              final updatedBabies = homeProvider.babies
                  .where((b) => b.id != baby.id)
                  .toList();
              homeProvider.setFamily(
                homeProvider.family!.removeBaby(baby.id),
                updatedBabies,
              );
            }

            // 🔧 Sprint 19 G-R5: 토스트 제거 → 햅틱 대체
            if (mounted) {
              HapticFeedback.mediumImpact();
            }
          } catch (e) {
            if (mounted) {
              _showSnackBar(S.of(context)!.errorDeleteFailed(e.toString()));
            }
          }
        },
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: LuluColors.surfaceElevated,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LuluRadius.sm),
        ),
      ),
    );
  }

  // ========================================
  // 데이터 초기화 섹션
  // ========================================

  Widget _buildResetDataTile() {
    return Container(
      decoration: BoxDecoration(
        color: LuluColors.surfaceCard,
        borderRadius: BorderRadius.circular(LuluRadius.sm),
        border: Border.all(
          color: LuluStatusColors.errorBorder,
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: LuluStatusColors.errorLight,
            borderRadius: BorderRadius.circular(LuluRadius.section),
          ),
          child: Icon(
            LuluIcons.deleteForever,
            color: LuluStatusColors.error,
            size: 22,
          ),
        ),
        title: Text(
          S.of(context)!.resetDataTitle,
          style: LuluTextStyles.bodyLarge.copyWith(
            color: LuluStatusColors.error,
          ),
        ),
        subtitle: Text(
          S.of(context)!.resetDataHint,
          style: LuluTextStyles.caption.copyWith(
            color: LuluTextColors.secondary,
          ),
        ),
        trailing: Icon(
          LuluIcons.chevronRight,
          color: LuluStatusColors.errorStrong,
        ),
        onTap: () => _showResetConfirmDialog(),
      ),
    );
  }

  Future<void> _showResetConfirmDialog() async {
    final l10n = S.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: LuluColors.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LuluRadius.md),
        ),
        title: Row(
          children: [
            Icon(LuluIcons.statusWarn, color: LuluStatusColors.error),
            const SizedBox(width: 8),
            Text(
              l10n.resetDataTitle,
              style: LuluTextStyles.titleMedium.copyWith(
                color: LuluTextColors.primary,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.resetDataConfirm,
              style: LuluTextStyles.bodyLarge.copyWith(
                color: LuluTextColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: LuluStatusColors.errorBg,
                borderRadius: BorderRadius.circular(LuluRadius.xs),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWarningItem(l10n.resetWarningRecords),
                  _buildWarningItem(l10n.resetWarningBabies),
                  _buildWarningItem(l10n.resetWarningIrreversible),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              l10n.buttonCancel,
              style: LuluTextStyles.labelLarge.copyWith(
                color: LuluTextColors.secondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(
              foregroundColor: LuluStatusColors.error,
            ),
            child: Text(
              l10n.buttonDelete,
              style: LuluTextStyles.labelLarge.copyWith(
                color: LuluStatusColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _resetAllData();
    }
  }

  Widget _buildWarningItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            LuluIcons.removeCircleOutline,
            size: 16,
            color: LuluStatusColors.error,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: LuluTextStyles.bodySmall.copyWith(
              color: LuluTextColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _resetAllData() async {
    // 로딩 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(
          color: LuluColors.lavenderMist,
        ),
      ),
    );

    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) {
        throw Exception('Not authenticated');
      }

      // 1. 현재 사용자의 family_id 찾기 (family_members 우선, families fallback)
      String? familyId;

      // 1-1. family_members에서 찾기
      try {
        final memberData = await supabase
            .from('family_members')
            .select('family_id')
            .eq('user_id', userId)
            .maybeSingle();

        if (memberData != null) {
          familyId = memberData['family_id'] as String?;
          debugPrint('[OK] Found family via family_members: $familyId');
        }
      } catch (e) {
        debugPrint('[WARN] family_members query failed: $e');
      }

      // 1-2. fallback: families.user_id로 찾기
      if (familyId == null) {
        final familyData = await supabase
            .from('families')
            .select('id')
            .eq('user_id', userId)
            .maybeSingle();

        if (familyData != null) {
          familyId = familyData['id'] as String?;
          debugPrint('[OK] Found family via families.user_id: $familyId');
        }
      }

      if (familyId != null) {
        debugPrint('[INFO] Deleting all data for family: $familyId');

        // 2. activities 삭제
        await supabase
            .from('activities')
            .delete()
            .eq('family_id', familyId);
        debugPrint('[OK] Activities deleted');

        // 3. babies 삭제
        await supabase
            .from('babies')
            .delete()
            .eq('family_id', familyId);
        debugPrint('[OK] Babies deleted');

        // 4. family_invites 삭제 (Family Sharing v3.2)
        try {
          await supabase
              .from('family_invites')
              .delete()
              .eq('family_id', familyId);
          debugPrint('[OK] Family invites deleted');
        } catch (e) {
          debugPrint('[WARN] family_invites deletion failed: $e');
        }

        // 5. family_members 삭제 (Family Sharing v3.2)
        try {
          await supabase
              .from('family_members')
              .delete()
              .eq('family_id', familyId);
          debugPrint('[OK] Family members deleted');
        } catch (e) {
          debugPrint('[WARN] family_members deletion failed: $e');
        }

        // 6. families 삭제
        await supabase
            .from('families')
            .delete()
            .eq('id', familyId);
        debugPrint('[OK] Family deleted');
      }

      // 7. 로컬 데이터 삭제
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      debugPrint('[OK] Local data cleared');

      // 8. Provider 초기화
      if (mounted) {
        context.read<HomeProvider>().reset();
      }

      // 로딩 닫기
      if (mounted) {
        Navigator.pop(context);
      }

      debugPrint('[OK] All data reset complete');

      // 9. 앱 재시작 (온보딩 다시 시작)
      if (mounted) {
        _showSnackBar(S.of(context)!.resetCompleteMessage);
        // 로그아웃 처리
        await supabase.auth.signOut();
      }
    } catch (e) {
      // 로딩 닫기
      if (mounted) {
        Navigator.pop(context);
      }

      debugPrint('[ERROR] _resetAllData: $e');

      if (mounted) {
        _showSnackBar(S.of(context)!.errorResetFailed(e.toString()));
      }
    }
  }
}
