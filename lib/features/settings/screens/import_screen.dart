import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_icons.dart';
import '../../../core/design_system/lulu_radius.dart';
import '../../../l10n/generated/app_localizations.dart' show S;
import '../../../data/models/baby_model.dart';
import '../../home/providers/home_provider.dart';
import '../providers/import_provider.dart';

part 'import_widgets.dart';

/// 데이터 가져오기 화면
///
/// 다른 육아 앱에서 내보낸 데이터를 LULU로 가져옵니다.
/// - TXT: 베이비타임
/// - CSV: Huckleberry
class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  String? _selectedBabyId;

  @override
  void initState() {
    super.initState();
    // 아기가 1명이면 자동 선택
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final babies = context.read<HomeProvider>().babies;
      if (babies.length == 1) {
        setState(() => _selectedBabyId = babies.first.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context)!;

    return ChangeNotifierProvider(
      create: (_) => ImportProvider(),
      child: Scaffold(
        backgroundColor: LuluColors.midnightNavy,
        appBar: AppBar(
          backgroundColor: LuluColors.midnightNavy,
          title: Text(l10n.importTitle),
          leading: IconButton(
            icon: const Icon(LuluIcons.back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SafeArea(
          child: Consumer<ImportProvider>(
            builder: (context, provider, _) {
              switch (provider.state) {
                case ImportState.initial:
                  return _buildFileSelection(context, provider, l10n);
                case ImportState.analyzing:
                  return _buildAnalyzing(l10n);
                case ImportState.preview:
                  return _buildPreview(context, provider, l10n);
                case ImportState.importing:
                  return _buildImporting(provider, l10n);
                case ImportState.complete:
                  return _buildComplete(context, provider, l10n);
                case ImportState.error:
                  return _buildError(context, provider, l10n);
              }
            },
          ),
        ),
      ),
    );
  }

  /// 파일 선택 화면
  Widget _buildFileSelection(
    BuildContext context,
    ImportProvider provider,
    S l10n,
  ) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 40),

          // 아이콘
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: LuluColors.surfaceElevated,
              borderRadius: BorderRadius.circular(LuluRadius.lg),
            ),
            child: const Icon(
              LuluIcons.folderOpen,
              size: 40,
              color: LuluColors.lavenderMist,
            ),
          ),

          const SizedBox(height: 24),

          // 타이틀
          Text(
            l10n.importSelectFile,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: LuluTextColors.primary,
            ),
          ),

          const SizedBox(height: 32),

          // TXT 파일 옵션
          _FileTypeCard(
            icon: LuluIcons.description,
            title: l10n.importTxtOption,
            subtitle: l10n.importTxtDesc,
            onTap: () => provider.pickTxtFile(),
          ),

          const SizedBox(height: 12),

          // CSV 파일 옵션
          _FileTypeCard(
            icon: LuluIcons.tableChart,
            title: l10n.importCsvOption,
            subtitle: l10n.importCsvDesc,
            onTap: () => provider.pickCsvFile(),
          ),

          const Spacer(),

          // 힌트
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: LuluColors.surfaceElevated,
              borderRadius: BorderRadius.circular(LuluRadius.sm),
            ),
            child: Row(
              children: [
                const Icon(
                  LuluIcons.tip,
                  color: LuluColors.champagneGold,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.importHint,
                    style: const TextStyle(
                      fontSize: 13,
                      color: LuluTextColors.secondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 분석 중 화면
  Widget _buildAnalyzing(S l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: LuluColors.lavenderMist,
          ),
          const SizedBox(height: 24),
          Text(
            l10n.importAnalyzing,
            style: const TextStyle(
              fontSize: 16,
              color: LuluTextColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  /// 미리보기 화면
  Widget _buildPreview(
    BuildContext context,
    ImportProvider provider,
    S l10n,
  ) {
    final preview = provider.preview!;
    final babies = context.select<HomeProvider, List<BabyModel>>((p) => p.babies);
    final familyId = context.read<HomeProvider>().family?.id ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 분석 완료 헤더
          Row(
            children: [
              const Icon(
                LuluIcons.checkCircle,
                color: LuluStatusColors.success,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.importAnalyzed,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: LuluTextColors.primary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 기록 수 카드
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: LuluColors.surfaceCard,
              borderRadius: BorderRadius.circular(LuluRadius.md),
            ),
            child: Column(
              children: [
                _PreviewRow(
                  icon: LuluIcons.cafe,
                  iconColor: LuluActivityColors.feeding,
                  label: l10n.importFeedingCount,
                  count: preview.feedingCount,
                ),
                const Divider(height: 24, color: LuluColors.surfaceElevated),
                _PreviewRow(
                  icon: LuluIcons.sleep,
                  iconColor: LuluActivityColors.sleep,
                  label: l10n.importSleepCount,
                  count: preview.sleepCount,
                ),
                const Divider(height: 24, color: LuluColors.surfaceElevated),
                _PreviewRow(
                  icon: LuluIcons.diaper,
                  iconColor: LuluActivityColors.diaper,
                  label: l10n.importDiaperCount,
                  count: preview.diaperCount,
                ),
                if (preview.playCount > 0) ...[
                  const Divider(height: 24, color: LuluColors.surfaceElevated),
                  _PreviewRow(
                    icon: LuluIcons.sportsEsports,
                    iconColor: LuluActivityColors.play,
                    label: l10n.importPlayCount,
                    count: preview.playCount,
                  ),
                ],
                const Divider(height: 24, color: LuluColors.surfaceElevated),
                _PreviewRow(
                  icon: LuluIcons.summarize,
                  iconColor: LuluColors.lavenderMist,
                  label: l10n.importTotal,
                  count: preview.totalCount,
                  isBold: true,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 아기 연결 섹션
          Text(
            l10n.importBabyConnect,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: LuluTextColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.importBabyConnectDesc,
            style: const TextStyle(
              fontSize: 13,
              color: LuluTextColors.secondary,
            ),
          ),

          const SizedBox(height: 12),

          // 아기 선택 드롭다운
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: LuluColors.surfaceElevated,
              borderRadius: BorderRadius.circular(LuluRadius.sm),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedBabyId,
                isExpanded: true,
                dropdownColor: LuluColors.surfaceElevated,
                hint: Text(
                  l10n.importBabySelectHint,
                  style: const TextStyle(color: LuluTextColors.secondary),
                ),
                items: babies.map((baby) {
                  return DropdownMenuItem<String>(
                    value: baby.id,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: LuluColors.getBabyColor(
                            babies.indexOf(baby),
                          ),
                          child: Text(
                            baby.name.substring(0, 1),
                            style: const TextStyle(
                              fontSize: 12,
                              color: LuluColors.midnightNavy,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          baby.name,
                          style: const TextStyle(
                            color: LuluTextColors.primary,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedBabyId = value);
                },
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 경고 메시지
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: LuluStatusColors.warningBg,
              borderRadius: BorderRadius.circular(LuluRadius.sm),
              border: Border.all(
                color: LuluStatusColors.warningBorder,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  LuluIcons.infoOutline,
                  color: LuluStatusColors.warning,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.importDuplicateWarning,
                    style: const TextStyle(
                      fontSize: 13,
                      color: LuluStatusColors.warning,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 가져오기 버튼
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedBabyId != null
                  ? () => provider.startImport(
                        babyId: _selectedBabyId!,
                        familyId: familyId,
                      )
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: LuluColors.lavenderMist,
                disabledBackgroundColor: LuluColors.surfaceElevated,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(LuluRadius.sm),
                ),
              ),
              child: Text(
                l10n.importButton(preview.totalCount),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _selectedBabyId != null
                      ? LuluColors.midnightNavy
                      : LuluTextColors.disabled,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 가져오기 중 화면
  Widget _buildImporting(ImportProvider provider, S l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 프로그레스 표시
            SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: provider.progress,
                    strokeWidth: 8,
                    backgroundColor: LuluColors.surfaceElevated,
                    color: LuluColors.lavenderMist,
                  ),
                  Text(
                    '${(provider.progress * 100).toInt()}%',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: LuluTextColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              l10n.importProgress,
              style: const TextStyle(
                fontSize: 16,
                color: LuluTextColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 완료 화면
  Widget _buildComplete(
    BuildContext context,
    ImportProvider provider,
    S l10n,
  ) {
    final result = provider.result!;

    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 성공 아이콘
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: LuluStatusColors.successBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LuluIcons.celebration,
              size: 40,
              color: LuluStatusColors.success,
            ),
          ),

          const SizedBox(height: 24),

          // 완료 텍스트
          Text(
            l10n.importComplete,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: LuluTextColors.primary,
            ),
          ),

          const SizedBox(height: 32),

          // 결과 카드
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: LuluColors.surfaceCard,
              borderRadius: BorderRadius.circular(LuluRadius.md),
            ),
            child: Column(
              children: [
                _ResultRow(
                  icon: LuluIcons.checkCircle,
                  iconColor: LuluStatusColors.success,
                  label: l10n.importSuccess,
                  count: result.successCount,
                ),
                if (result.skipCount > 0) ...[
                  const SizedBox(height: 16),
                  _ResultRow(
                    icon: LuluIcons.skipNext,
                    iconColor: LuluStatusColors.warning,
                    label: l10n.importSkipped,
                    count: result.skipCount,
                  ),
                ],
                // 에러 메시지 표시 (디버깅용)
                if (result.errors.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: LuluStatusColors.errorBg,
                      borderRadius: BorderRadius.circular(LuluRadius.xs),
                    ),
                    child: Text(
                      l10n.importErrorPrefix(result.errors.first),
                      style: const TextStyle(
                        fontSize: 12,
                        color: LuluStatusColors.error,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const Spacer(),

          // 홈으로 버튼
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                // BUG-004 FIX: Refresh HomeProvider after import for Sweet Spot update
                final homeProvider = context.read<HomeProvider>();
                await homeProvider.loadTodayActivities();

                // 홈 화면으로 돌아가기
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: LuluColors.lavenderMist,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(LuluRadius.sm),
                ),
              ),
              child: Text(
                l10n.importGoHome,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: LuluColors.midnightNavy,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 에러 화면
  Widget _buildError(
    BuildContext context,
    ImportProvider provider,
    S l10n,
  ) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 에러 아이콘
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: LuluStatusColors.errorBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LuluIcons.errorOutline,
              size: 40,
              color: LuluStatusColors.error,
            ),
          ),

          const SizedBox(height: 24),

          // 에러 메시지
          Text(
            provider.errorMessage ?? l10n.errorUnknown,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: LuluTextColors.primary,
            ),
          ),

          const SizedBox(height: 32),

          // 다시 시도 버튼
          OutlinedButton(
            onPressed: () => provider.reset(),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: LuluColors.lavenderMist),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(LuluRadius.sm),
              ),
            ),
            child: Text(
              l10n.buttonRetry,
              style: const TextStyle(
                color: LuluColors.lavenderMist,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Private widgets (_FileTypeCard, _PreviewRow, _ResultRow)
// → import_widgets.dart (part file)
