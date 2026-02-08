import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/design_system/lulu_colors.dart';
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
                _buildSectionHeader('위험 영역'),
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
        borderRadius: BorderRadius.circular(12),
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
    final statusText = baby.isPreterm ? '조산아' : '만삭';

    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: _getBabyColor(baby.birthOrder ?? 1).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
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
              borderRadius: BorderRadius.circular(4),
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
                Icons.delete_outline_rounded,
                color: LuluStatusColors.error.withValues(alpha: 0.7),
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
          color: LuluColors.lavenderMist.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: LuluColors.lavenderMist.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: const Icon(
          Icons.add_rounded,
          color: LuluColors.lavenderMist,
          size: 24,
        ),
      ),
      title: Text(
        '아기 추가',
        style: LuluTextStyles.bodyLarge.copyWith(
          color: LuluColors.lavenderMist,
        ),
      ),
      subtitle: Text(
        '최대 4명까지 등록 가능',
        style: LuluTextStyles.caption.copyWith(
          color: LuluTextColors.tertiary,
        ),
      ),
      onTap: () => _showAddBabyDialog(homeProvider),
    );
  }

  String _formatAge(BabyModel baby) {
    final now = DateTime.now();
    final days = now.difference(baby.birthDate).inDays;

    if (days < 7) {
      return '출생 $days일';
    } else if (days < 30) {
      return '출생 ${days ~/ 7}주';
    } else {
      final months = days ~/ 30;
      if (baby.isPreterm && baby.correctedAgeInMonths != null) {
        return '교정 ${baby.correctedAgeInMonths}개월 (실제 $months개월)';
      }
      return '$months개월';
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
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: LuluColors.lavenderMist.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.family_restroom,
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
                  ? '${familyProvider.memberCount}명의 가족'
                  : '가족 멤버 초대하기',
              style: LuluTextStyles.caption.copyWith(
                color: LuluTextColors.secondary,
              ),
            ),
            trailing: const Icon(
              Icons.chevron_right_rounded,
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
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: LuluColors.lavenderMist.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.language_rounded,
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
              Icons.chevron_right_rounded,
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
          borderRadius: BorderRadius.circular(16),
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
        borderRadius: BorderRadius.circular(12),
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
          color: LuluColors.lavenderMist.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(
          Icons.file_upload_outlined,
          color: LuluColors.lavenderMist,
          size: 22,
        ),
      ),
      title: Text(
        '기존 기록 가져오기',
        style: LuluTextStyles.bodyLarge.copyWith(
          color: LuluTextColors.primary,
        ),
      ),
      subtitle: Text(
        '다른 앱에서 기록 이전',
        style: LuluTextStyles.caption.copyWith(
          color: LuluTextColors.secondary,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
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
            '내보내기 기간',
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
                label: Text(period.label),
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
          color: LuluColors.lavenderMist.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(
          Icons.file_download_outlined,
          color: LuluColors.lavenderMist,
          size: 22,
        ),
      ),
      title: Text(
        'CSV로 내보내기',
        style: LuluTextStyles.bodyLarge.copyWith(
          color: LuluTextColors.primary,
        ),
      ),
      subtitle: Text(
        '${_selectedPeriod.label} 기록을 파일로 저장',
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
              Icons.chevron_right_rounded,
              color: LuluTextColors.secondary,
            ),
      onTap: _isExporting ? null : _handleExport,
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Container(
      decoration: BoxDecoration(
        color: LuluColors.surfaceCard,
        borderRadius: BorderRadius.circular(12),
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

    if (family == null) {
      _showSnackBar('가족 정보가 없습니다');
      return;
    }

    setState(() => _isExporting = true);

    try {
      final count = await ExportService.instance.exportByPeriod(
        familyId: family.id,
        babies: babies,
        period: _selectedPeriod,
      );

      if (count == 0) {
        _showSnackBar('내보낼 기록이 없습니다');
      }
    } catch (e) {
      _showSnackBar('내보내기 실패: $e');
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
              _showSnackBar('삭제 실패: $e');
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
          borderRadius: BorderRadius.circular(12),
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: LuluStatusColors.error.withValues(alpha: 0.3),
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: LuluStatusColors.error.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.delete_forever_rounded,
            color: LuluStatusColors.error,
            size: 22,
          ),
        ),
        title: Text(
          '데이터 초기화',
          style: LuluTextStyles.bodyLarge.copyWith(
            color: LuluStatusColors.error,
          ),
        ),
        subtitle: Text(
          '모든 데이터를 삭제하고 처음부터 시작',
          style: LuluTextStyles.caption.copyWith(
            color: LuluTextColors.secondary,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: LuluStatusColors.error.withValues(alpha: 0.7),
        ),
        onTap: () => _showResetConfirmDialog(),
      ),
    );
  }

  Future<void> _showResetConfirmDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: LuluColors.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: LuluStatusColors.error),
            const SizedBox(width: 8),
            Text(
              '데이터 초기화',
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
              '정말 모든 데이터를 삭제하시겠어요?',
              style: LuluTextStyles.bodyLarge.copyWith(
                color: LuluTextColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: LuluStatusColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWarningItem('모든 기록이 삭제됩니다'),
                  _buildWarningItem('아기 정보가 삭제됩니다'),
                  _buildWarningItem('이 작업은 되돌릴 수 없습니다'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              '취소',
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
              '삭제',
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
            Icons.remove_circle_outline,
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
        _showSnackBar('초기화 완료! 앱을 다시 시작해주세요.');
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
        _showSnackBar('초기화 실패: $e');
      }
    }
  }
}
