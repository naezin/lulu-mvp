import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_spacing.dart';
import '../../../core/design_system/lulu_typography.dart';
import '../../../core/services/export_service.dart';
import '../../home/providers/home_provider.dart';

/// 설정 화면
///
/// MVP-F 기능:
/// - 데이터 내보내기 (CSV)
/// - Phase 3에서 추가 설정 구현 예정
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LuluColors.midnightNavy,
      appBar: AppBar(
        backgroundColor: LuluColors.midnightNavy,
        elevation: 0,
        title: Text(
          '설정',
          style: LuluTextStyles.titleLarge.copyWith(
            color: LuluTextColors.primary,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: LuluSpacing.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 데이터 섹션
            _buildSectionHeader('데이터'),
            const SizedBox(height: LuluSpacing.md),
            _buildExportTile(),

            const SizedBox(height: LuluSpacing.xxxl),

            // 추가 설정 예정
            _buildSectionHeader('앱 정보'),
            const SizedBox(height: LuluSpacing.md),
            _buildInfoTile('버전', '2.0.0'),
            _buildInfoTile('개발', 'LULU Team'),

            const SizedBox(height: LuluSpacing.xxxl),

            // 안내 메시지
            Center(
              child: Text(
                '추가 설정은 Phase 3에서 구현 예정입니다',
                style: LuluTextStyles.caption.copyWith(
                  color: LuluTextColors.tertiary,
                ),
              ),
            ),
          ],
        ),
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

  Widget _buildExportTile() {
    return Container(
      decoration: BoxDecoration(
        color: LuluColors.surfaceCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // CSV 내보내기
          ListTile(
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
              '기록 내보내기',
              style: LuluTextStyles.bodyLarge.copyWith(
                color: LuluTextColors.primary,
              ),
            ),
            subtitle: Text(
              'CSV 파일로 내보내기',
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
          ),
        ],
      ),
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

  Future<void> _handleExport() async {
    final homeProvider = context.read<HomeProvider>();
    final activities = homeProvider.todayActivities;
    final babies = homeProvider.babies;

    if (activities.isEmpty) {
      _showSnackBar('내보낼 기록이 없습니다');
      return;
    }

    setState(() => _isExporting = true);

    try {
      await ExportService.instance.exportToCSV(
        activities: activities,
        babies: babies,
      );
    } catch (e) {
      _showSnackBar('내보내기 실패: $e');
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
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
}
