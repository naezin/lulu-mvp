import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_icons.dart';
import '../../../core/design_system/lulu_spacing.dart';
import '../../../core/design_system/lulu_typography.dart';
import '../../../data/models/activity_model.dart';
import '../../../data/models/baby_model.dart';
import '../../../data/models/baby_type.dart';
import '../../../shared/widgets/baby_tab_bar.dart';
import '../../../shared/widgets/quick_record_button.dart';
import '../providers/record_provider.dart';
import '../widgets/record_time_picker.dart';
import '../widgets/tummy_time_timer.dart';

/// 놀이 기록 화면 (v5.0)
///
/// MVP-F: BabyTabBar + QuickRecordButton UX
/// - "둘 다" 버튼 제거됨
/// - 이전과 같이 버튼으로 원탭 저장 지원
class PlayRecordScreen extends StatefulWidget {
  final String familyId;
  final List<BabyModel> babies;
  final String? preselectedBabyId;
  final ActivityModel? lastPlayRecord;

  const PlayRecordScreen({
    super.key,
    required this.familyId,
    required this.babies,
    this.preselectedBabyId,
    this.lastPlayRecord,
  });

  @override
  State<PlayRecordScreen> createState() => _PlayRecordScreenState();
}

class _PlayRecordScreenState extends State<PlayRecordScreen> {
  final _notesController = TextEditingController();
  final _durationController = TextEditingController();
  bool _isQuickSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecordProvider>().initialize(
            familyId: widget.familyId,
            babies: widget.babies,
            preselectedBabyId: widget.preselectedBabyId,
          );
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LuluColors.midnightNavy,
      appBar: AppBar(
        backgroundColor: LuluColors.midnightNavy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: LuluTextColors.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '놀이 기록',
          style: LuluTextStyles.titleMedium.copyWith(
            color: LuluTextColors.primary,
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<RecordProvider>(
        builder: (context, provider, _) {
          return Column(
            children: [
              // 아기 탭바 (다태아 시 표시)
              if (widget.babies.length > 1)
                BabyTabBar(
                  babies: widget.babies,
                  selectedBabyId: provider.selectedBabyIds.isNotEmpty
                      ? provider.selectedBabyIds.first
                      : null,
                  onBabyChanged: (babyId) {
                    if (babyId != null) {
                      provider.setSelectedBabyIds([babyId]);
                    }
                  },
                ),

              Expanded(
                child: SingleChildScrollView(
                  padding: LuluSpacing.screenPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 마지막 기록 반복 버튼 (MB-03)
                      QuickRecordButton(
                        lastRecord: widget.lastPlayRecord,
                        activityType: ActivityType.play,
                        isLoading: _isQuickSaving,
                        onTap: () => _handleQuickSave(provider),
                        babyName: _getSelectedBabyName(provider),
                      ),

                      if (widget.lastPlayRecord != null) ...[
                        const SizedBox(height: LuluSpacing.lg),

                        // 구분선
                        Row(
                          children: [
                            const Expanded(
                                child: Divider(color: LuluColors.softBlue)),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: LuluSpacing.md,
                              ),
                              child: Text(
                                '또는 상세 입력',
                                style: LuluTextStyles.caption.copyWith(
                                  color: LuluTextColors.tertiary,
                                ),
                              ),
                            ),
                            const Expanded(
                                child: Divider(color: LuluColors.softBlue)),
                          ],
                        ),

                        const SizedBox(height: LuluSpacing.lg),
                      ],

                      // 놀이 유형 선택
                      _buildPlayTypeSelector(provider),

                      const SizedBox(height: LuluSpacing.xxl),

                      // 놀이 시간 입력 (선택)
                      _buildDurationInput(provider),

                      const SizedBox(height: LuluSpacing.xxl),

                      // 시간 선택
                      RecordTimePicker(
                        label: '놀이 시간',
                        time: provider.recordTime,
                        onTimeChanged: provider.setRecordTime,
                      ),

                      const SizedBox(height: LuluSpacing.xxl),

                      // 메모
                      _buildNotesInput(),

                      // 에러 메시지
                      if (provider.errorMessage != null) ...[
                        const SizedBox(height: LuluSpacing.md),
                        _buildErrorMessage(provider.errorMessage!),
                      ],

                      const SizedBox(height: LuluSpacing.xxl),
                    ],
                  ),
                ),
              ),

              // MO-01: 저장 버튼 하단 고정
              SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.all(LuluSpacing.lg),
                  decoration: BoxDecoration(
                    color: LuluColors.midnightNavy,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: _buildSaveButton(provider),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// MB-03: 현재 선택된 아기 이름 반환
  String? _getSelectedBabyName(RecordProvider provider) {
    if (provider.selectedBabyIds.isEmpty) return null;
    final selectedId = provider.selectedBabyIds.first;
    final baby = widget.babies.where((b) => b.id == selectedId).firstOrNull;
    return baby?.name;
  }

  Future<void> _handleQuickSave(RecordProvider provider) async {
    if (_isQuickSaving || widget.lastPlayRecord == null) return;

    setState(() => _isQuickSaving = true);

    try {
      final lastData = widget.lastPlayRecord!.data;
      if (lastData == null) return;

      final playType = lastData['play_type'] as String? ?? 'tummy_time';
      provider.setPlayType(playType);

      final duration = lastData['duration_minutes'] as int?;
      if (duration != null) provider.setPlayDuration(duration);

      provider.setRecordTime(DateTime.now());

      final activity = await provider.savePlay();
      if (activity != null && mounted) {
        Navigator.of(context).pop(activity);
      }
    } finally {
      if (mounted) {
        setState(() => _isQuickSaving = false);
      }
    }
  }

  Widget _buildPlayTypeSelector(RecordProvider provider) {
    // UX-01: 활동 유형 2x3 그리드 레이아웃
    final playTypes = [
      ('tummy_time', '터미타임', LuluIcons.tummyTime),
      ('bath', '목욕', LuluIcons.bath),
      ('outdoor', '외출', LuluIcons.outdoor),
      ('play', '실내놀이', LuluIcons.indoorPlay),
      ('reading', '독서', LuluIcons.reading),
      ('other', '기타', LuluIcons.other),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '활동 유형',
          style: LuluTextStyles.bodyLarge.copyWith(
            color: LuluTextColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: LuluSpacing.md),
        // UX-01: 2x3 그리드 배치
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: LuluSpacing.sm,
            crossAxisSpacing: LuluSpacing.sm,
            childAspectRatio: 1.1,
          ),
          itemCount: playTypes.length,
          itemBuilder: (context, index) {
            final type = playTypes[index];
            return _PlayTypeGridButton(
              type: type.$1,
              label: type.$2,
              icon: type.$3,
              isSelected: provider.playType == type.$1,
              onTap: () => provider.setPlayType(type.$1),
            );
          },
        ),
        // PL-01: 터미타임 선택 시 타이머 표시
        if (provider.playType == 'tummy_time') ...[
          const SizedBox(height: LuluSpacing.md),
          // 권장 시간 안내
          Container(
            padding: const EdgeInsets.all(LuluSpacing.md),
            decoration: BoxDecoration(
              color: LuluStatusColors.infoSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: LuluStatusColors.info,
                  size: 20,
                ),
                const SizedBox(width: LuluSpacing.sm),
                Expanded(
                  child: Text(
                    '교정연령 기준 권장: 하루 3-5분씩 여러 번',
                    style: LuluTextStyles.bodySmall.copyWith(
                      color: LuluStatusColors.info,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: LuluSpacing.md),
          // PL-01: 터미타임 타이머
          TummyTimeTimer(
            recommendedMinutes: 5,
            onComplete: (minutes) {
              provider.setPlayDuration(minutes);
              _durationController.text = minutes.toString();
            },
          ),
        ],
      ],
    );
  }

  Widget _buildDurationInput(RecordProvider provider) {
    // UX-01: 시간 선택 강화 - 터미타임은 짧은 시간, 외출은 긴 시간
    final isShortActivity =
        provider.playType == 'tummy_time' || provider.playType == 'reading';
    final durations = isShortActivity ? [3, 5, 10, 15] : [10, 15, 30, 60];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '활동 시간 (선택)',
          style: LuluTextStyles.bodyLarge.copyWith(
            color: LuluTextColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: LuluSpacing.md),
        // UX-01: 빠른 선택 버튼을 Expanded로 균등 배치
        Row(
          children: durations
              .map(
                (min) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: min != durations.last ? LuluSpacing.sm : 0,
                    ),
                    child: _DurationButton(
                      minutes: min,
                      isSelected: provider.playDuration == min,
                      onTap: () {
                        provider.setPlayDuration(min);
                        _durationController.text = min.toString();
                      },
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: LuluSpacing.md),
        // 직접 입력
        Container(
          padding: LuluSpacing.inputPadding,
          decoration: BoxDecoration(
            color: LuluColors.surfaceElevated,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _durationController,
                  keyboardType: TextInputType.number,
                  style: LuluTextStyles.bodyMedium.copyWith(
                    color: LuluTextColors.primary,
                  ),
                  decoration: InputDecoration(
                    hintText: '직접 입력',
                    hintStyle: LuluTextStyles.bodyMedium.copyWith(
                      color: LuluTextColors.tertiary,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (value) {
                    final minutes = int.tryParse(value);
                    provider.setPlayDuration(minutes);
                  },
                ),
              ),
              Text(
                '분',
                style: LuluTextStyles.bodyMedium.copyWith(
                  color: LuluTextColors.secondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotesInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '메모 (선택)',
          style: LuluTextStyles.bodyLarge.copyWith(
            color: LuluTextColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: LuluSpacing.md),
        Container(
          padding: LuluSpacing.inputPadding,
          decoration: BoxDecoration(
            color: LuluColors.surfaceElevated,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _notesController,
            maxLines: 3,
            style: LuluTextStyles.bodyMedium.copyWith(
              color: LuluTextColors.primary,
            ),
            decoration: InputDecoration(
              hintText: '아기의 반응, 특이사항 등',
              hintStyle: LuluTextStyles.bodyMedium.copyWith(
                color: LuluTextColors.tertiary,
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (value) {
              context.read<RecordProvider>().setNotes(value);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton(RecordProvider provider) {
    final isValid = provider.isSelectionValid;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isValid && !provider.isLoading
            ? () => _handleSave(provider)
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: LuluActivityColors.play,
          foregroundColor: LuluColors.midnightNavy,
          disabledBackgroundColor: LuluColors.surfaceElevated,
          disabledForegroundColor: LuluTextColors.disabled,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: provider.isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: LuluColors.midnightNavy,
                ),
              )
            : Text(
                '저장하기',
                style: LuluTextStyles.labelLarge.copyWith(
                  color: LuluColors.midnightNavy,
                ),
              ),
      ),
    );
  }

  Widget _buildErrorMessage(String message) {
    return Container(
      padding: LuluSpacing.cardPadding,
      decoration: BoxDecoration(
        color: LuluStatusColors.errorSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: LuluStatusColors.error,
            size: 20,
          ),
          const SizedBox(width: LuluSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: LuluTextStyles.bodySmall.copyWith(
                color: LuluStatusColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSave(RecordProvider provider) async {
    final activity = await provider.savePlay();
    if (activity != null && mounted) {
      Navigator.of(context).pop(activity);
    }
  }
}

/// UX-01: 놀이 유형 그리드 버튼 (2x3 배치용)
class _PlayTypeGridButton extends StatelessWidget {
  final String type;
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _PlayTypeGridButton({
    required this.type,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? LuluActivityColors.playBg
              : LuluColors.surfaceElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? LuluActivityColors.play : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 28,
              color: isSelected
                  ? LuluActivityColors.play
                  : LuluTextColors.secondary,
            ),
            const SizedBox(height: LuluSpacing.xs),
            Text(
              label,
              style: LuluTextStyles.labelMedium.copyWith(
                color: isSelected
                    ? LuluActivityColors.play
                    : LuluTextColors.secondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 시간 선택 버튼
class _DurationButton extends StatelessWidget {
  final int minutes;
  final bool isSelected;
  final VoidCallback onTap;

  const _DurationButton({
    required this.minutes,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: LuluSpacing.md,
          vertical: LuluSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? LuluActivityColors.playBg
              : LuluColors.surfaceElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? LuluActivityColors.play
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Text(
          '$minutes분',
          style: LuluTextStyles.labelSmall.copyWith(
            color: isSelected
                ? LuluActivityColors.play
                : LuluTextColors.secondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
