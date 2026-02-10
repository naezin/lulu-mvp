import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_icons.dart';
import '../../../core/design_system/lulu_radius.dart';
import '../../../core/design_system/lulu_shadows.dart';
import '../../../core/design_system/lulu_spacing.dart';
import '../../../core/design_system/lulu_typography.dart';
import '../../../data/models/activity_model.dart';
import '../../../data/models/baby_model.dart';
import '../../../data/models/feeding_type.dart';
import '../../../shared/widgets/baby_tab_bar.dart';
import '../../../l10n/generated/app_localizations.dart' show S;
import '../providers/feeding_record_provider.dart';
import '../widgets/record_time_picker.dart';
import '../widgets/feeding_type_selector.dart';
import '../widgets/breast_feeding_form.dart';
import '../widgets/solid_food_form.dart';
import '../widgets/amount_input.dart';
import '../widgets/recent_feeding_buttons.dart';

/// 수유 기록 화면 (v6.0 - Phase A)
///
/// MVP-F: BabyTabBar + QuickRecordButton UX
/// - "둘 다" 버튼 제거됨
/// - 이전과 같이 버튼으로 원탭 저장 지원
///
/// v6.0 변경사항:
/// - FeedingContentType enum 기반 선택
/// - 모유 선택 시 BreastFeedingForm 표시 (직접/유축 세부 선택)
/// - AmountInput [-10][+10] 빠른 조절 버튼 추가
class FeedingRecordScreen extends StatefulWidget {
  final String familyId;
  final List<BabyModel> babies;
  final String? preselectedBabyId;
  final ActivityModel? lastFeedingRecord;

  const FeedingRecordScreen({
    super.key,
    required this.familyId,
    required this.babies,
    this.preselectedBabyId,
    this.lastFeedingRecord,
  });

  @override
  State<FeedingRecordScreen> createState() => _FeedingRecordScreenState();
}

class _FeedingRecordScreenState extends State<FeedingRecordScreen> {
  final _notesController = TextEditingController();

  // v6.0: enum 기반 상태
  FeedingContentType _contentType = FeedingContentType.breastMilk;
  FeedingMethodType _methodType = FeedingMethodType.direct;
  BreastSide _breastSide = BreastSide.left;
  int _durationMinutes = 10;
  double _expressedAmount = 0;

  // Sprint 8: 이유식 상태
  String _solidFoodName = '';
  bool _solidIsFirstTry = false;
  SolidFoodUnit _solidUnit = SolidFoodUnit.gram;
  double _solidAmount = 0;
  BabyReaction? _solidReaction;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<FeedingRecordProvider>();
      provider.initialize(
        familyId: widget.familyId,
        babies: widget.babies,
        preselectedBabyId: widget.preselectedBabyId,
      );
      // HOTFIX v1.2: 최근 수유 기록 로드
      final babyId = widget.preselectedBabyId ?? widget.babies.first.id;
      provider.loadRecentFeedings(babyId);
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
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
          icon: const Icon(LuluIcons.close, color: LuluTextColors.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          S.of(context)!.recordTitleFeeding,
          style: LuluTextStyles.titleMedium.copyWith(
            color: LuluTextColors.primary,
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<FeedingRecordProvider>(
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
                      // HOTFIX v1.2: 아기 전환 시 최근 기록 새로고침
                      provider.loadRecentFeedings(babyId);
                    }
                  },
                ),

              Expanded(
                child: SingleChildScrollView(
                  padding: LuluSpacing.screenPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // HOTFIX v1.2: 최근 3개 빠른 수유 버튼
                      // Sprint 20 HF #10/#11: onSaveSuccess에서 화면 닫기 + SnackBar 정리
                      RecentFeedingButtons(
                        babyId: provider.selectedBabyId ?? widget.babies.first.id,
                        onEditRequest: _handleEditRequest,
                        onSaveSuccess: () {
                          if (mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                      ),

                      // v6.0: 수유 종류 선택 (enum 기반)
                      FeedingTypeSelector(
                        selectedType: _contentType,
                        onTypeChanged: (type) {
                          setState(() {
                            _contentType = type;
                          });
                          // FeedingRecordProvider와 동기화 (legacy)
                          provider.setFeedingType(type.legacyValue);
                        },
                      ),

                      const SizedBox(height: LuluSpacing.xxl),

                      // 시간 선택
                      RecordTimePicker(
                        label: S.of(context)!.feedingTimeLabel,
                        time: provider.recordTime,
                        onTimeChanged: provider.setRecordTime,
                      ),

                      const SizedBox(height: LuluSpacing.xxl),

                      // v6.0: 모유 선택 시 BreastFeedingForm 표시
                      if (_contentType == FeedingContentType.breastMilk) ...[
                        BreastFeedingForm(
                          methodType: _methodType,
                          breastSide: _breastSide,
                          durationMinutes: _durationMinutes,
                          amountMl: _expressedAmount,
                          onMethodChanged: (method) {
                            setState(() {
                              _methodType = method;
                            });
                          },
                          onSideChanged: (side) {
                            setState(() {
                              _breastSide = side;
                            });
                            provider.setBreastSide(side.name);
                          },
                          onDurationChanged: (duration) {
                            setState(() {
                              _durationMinutes = duration;
                            });
                            provider.setFeedingDuration(duration);
                          },
                          onAmountChanged: (amount) {
                            setState(() {
                              _expressedAmount = amount;
                            });
                            provider.setFeedingAmount(amount);
                          },
                        ),
                      ] else if (_contentType == FeedingContentType.solid) ...[
                        // Sprint 8: 이유식 폼
                        SolidFoodForm(
                          foodName: _solidFoodName,
                          isFirstTry: _solidIsFirstTry,
                          unit: _solidUnit,
                          amount: _solidAmount,
                          reaction: _solidReaction,
                          onFoodNameChanged: (name) {
                            setState(() {
                              _solidFoodName = name;
                            });
                            provider.setSolidFoodName(name);
                          },
                          onFirstTryChanged: (isFirstTry) {
                            setState(() {
                              _solidIsFirstTry = isFirstTry;
                            });
                            provider.setSolidIsFirstTry(isFirstTry);
                          },
                          onUnitChanged: (unit) {
                            setState(() {
                              _solidUnit = unit;
                            });
                            provider.setSolidUnit(unit.value);
                          },
                          onAmountChanged: (amount) {
                            setState(() {
                              _solidAmount = amount;
                            });
                            provider.setSolidAmount(amount);
                          },
                          onReactionChanged: (reaction) {
                            setState(() {
                              _solidReaction = reaction;
                            });
                            provider.setSolidReaction(reaction.value);
                          },
                        ),
                      ] else ...[
                        // 분유: 수유량 입력
                        _buildAmountInput(provider),
                      ],

                      const SizedBox(height: LuluSpacing.xxl),

                      // 메모
                      _buildNotesInput(),

                      // 에러 메시지
                      if (provider.errorMessage != null) ...[
                        const SizedBox(height: LuluSpacing.md),
                        _buildErrorMessage(_localizeError(provider.errorMessage!)),
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
                    boxShadow: LuluShadows.topBar,
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

  /// HOTFIX v1.2: 롱프레스 시 수정 모드 진입
  /// 템플릿 기록을 기반으로 폼을 채움
  void _handleEditRequest(ActivityModel record) {
    final provider = context.read<FeedingRecordProvider>();
    final data = record.data;
    if (data == null) return;

    // FeedingRecordProvider 상태를 템플릿으로 설정
    final feedingType = data['feeding_type'] as String? ?? 'bottle';
    provider.setFeedingType(feedingType);

    // 로컬 상태도 업데이트
    setState(() {
      switch (feedingType) {
        case 'breast':
          _contentType = FeedingContentType.breastMilk;
          final side = data['breast_side'] as String?;
          if (side != null) {
            _breastSide = BreastSide.values.firstWhere(
              (s) => s.name == side,
              orElse: () => BreastSide.left,
            );
            provider.setBreastSide(side);
          }
          final duration = data['duration_minutes'] as int?;
          if (duration != null) {
            _durationMinutes = duration;
            provider.setFeedingDuration(duration);
          }
          break;
        case 'solid':
          _contentType = FeedingContentType.solid;
          break;
        case 'formula':
        case 'bottle':
        default:
          _contentType = FeedingContentType.formula;
          final amount = data['amount_ml'] as num?;
          if (amount != null) {
            provider.setFeedingAmount(amount.toDouble());
          }
          break;
      }
    });
  }

  // v6.0: _buildBreastSideSelector, _buildDurationInput 제거됨
  // BreastFeedingForm으로 통합

  Widget _buildAmountInput(FeedingRecordProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          S.of(context)!.feedingAmount,
          style: LuluTextStyles.bodyLarge.copyWith(
            color: LuluTextColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: LuluSpacing.md),
        AmountInput(
          amount: provider.feedingAmount,
          onAmountChanged: provider.setFeedingAmount,
          unit: 'ml',
          presets: const [60, 90, 120, 150],
        ),
      ],
    );
  }

  Widget _buildNotesInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          S.of(context)!.notesOptionalLabel,
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
            borderRadius: BorderRadius.circular(LuluRadius.sm),
          ),
          child: TextField(
            controller: _notesController,
            maxLines: 3,
            style: LuluTextStyles.bodyMedium.copyWith(
              color: LuluTextColors.primary,
            ),
            decoration: InputDecoration(
              hintText: S.of(context)!.notesPlaceholder,
              hintStyle: LuluTextStyles.bodyMedium.copyWith(
                color: LuluTextColors.tertiary,
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (value) {
              context.read<FeedingRecordProvider>().setNotes(value);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton(FeedingRecordProvider provider) {
    final isValid = provider.isSelectionValid;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isValid && !provider.isLoading
            ? () => _handleSave(provider)
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: LuluActivityColors.feeding,
          foregroundColor: LuluColors.midnightNavy,
          disabledBackgroundColor: LuluColors.surfaceElevated,
          disabledForegroundColor: LuluTextColors.disabled,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(LuluRadius.md),
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
                S.of(context)!.buttonSave,
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
        borderRadius: BorderRadius.circular(LuluRadius.sm),
      ),
      child: Row(
        children: [
          Icon(
            LuluIcons.errorOutline,
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

  String _localizeError(String errorKey) {
    final l10n = S.of(context);
    if (errorKey == 'errorSelectBaby') {
      return l10n?.errorSelectBaby ?? 'Please select a baby';
    } else if (errorKey == 'errorNoFamily') {
      return l10n?.errorNoFamily ?? 'No family information';
    } else if (errorKey.startsWith('errorSaveFailed:')) {
      final detail = errorKey.substring('errorSaveFailed:'.length);
      return l10n?.errorSaveFailed(detail) ?? 'Save failed: $detail';
    }
    return errorKey;
  }

  Future<void> _handleSave(FeedingRecordProvider provider) async {
    final activity = await provider.saveFeeding();
    if (activity != null && mounted) {
      Navigator.of(context).pop(activity);
    }
  }
}

// v6.0: _DurationButton, _BreastSideButton 제거됨
// BreastFeedingForm으로 통합
