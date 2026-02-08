import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_icons.dart';
import '../../../core/design_system/lulu_radius.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../providers/family_provider.dart';

/// 관리자 넘기기 화면
///
/// 가족 소유권을 다른 멤버에게 이전합니다.
class TransferOwnerScreen extends StatefulWidget {
  const TransferOwnerScreen({super.key});

  @override
  State<TransferOwnerScreen> createState() => _TransferOwnerScreenState();
}

class _TransferOwnerScreenState extends State<TransferOwnerScreen> {
  String? _selectedId;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context)!;

    return Scaffold(
      backgroundColor: LuluColors.midnightNavy,
      appBar: AppBar(
        backgroundColor: LuluColors.midnightNavy,
        title: Text(l10n.transferOwnership),
      ),
      body: Consumer<FamilyProvider>(
        builder: (context, provider, _) {
          final currentUserId = Supabase.instance.client.auth.currentUser?.id;
          final others =
              provider.members.where((m) => m.userId != currentUserId).toList();

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 헤더
                Text(
                  l10n.transferOwnershipTitle,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: LuluTextColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.transferOwnershipDesc,
                  style: TextStyle(
                    fontSize: 14,
                    color: LuluTextColors.primary.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 32),

                // 멤버 선택
                ...others.map((member) => _buildMemberTile(member)),

                const Spacer(),

                // 이전 버튼
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        _selectedId != null && !_isLoading ? _transfer : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: LuluColors.lavenderMist,
                      disabledBackgroundColor: LuluColors.deepIndigo,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(LuluRadius.sm),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: LuluColors.midnightNavy,
                            ),
                          )
                        : Text(
                            l10n.transferOwnershipButton,
                            style: const TextStyle(
                              color: LuluColors.midnightNavy,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMemberTile(member) {
    final isSelected = _selectedId == member.userId;

    return GestureDetector(
      onTap: () => setState(() => _selectedId = member.userId),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? LuluColors.lavenderMist.withOpacity(0.2)
              : LuluColors.deepIndigo.withOpacity(0.3),
          borderRadius: BorderRadius.circular(LuluRadius.sm),
          border: Border.all(
            color: isSelected
                ? LuluColors.lavenderMist
                : LuluColors.deepIndigo.withOpacity(0.5),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // 라디오 아이콘
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? LuluColors.lavenderMist
                      : LuluColors.lavenderMist.withOpacity(0.5),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Center(
                      child: Icon(
                        LuluIcons.save,
                        size: 16,
                        color: LuluColors.lavenderMist,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),

            // 멤버 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.displayName,
                    style: const TextStyle(
                      color: LuluTextColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  if (member.userEmail != null)
                    Text(
                      member.userEmail!,
                      style: TextStyle(
                        color: LuluTextColors.primary.withOpacity(0.6),
                        fontSize: 14,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _transfer() async {
    if (_selectedId == null) return;

    final l10n = S.of(context)!;

    // 확인 다이얼로그
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: LuluColors.deepIndigo,
        title: Text(l10n.confirmTransfer,
            style: const TextStyle(color: LuluTextColors.primary)),
        content: Text(
          l10n.confirmTransferDesc,
          style: TextStyle(color: LuluTextColors.primary.withOpacity(0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:
                Text(l10n.cancel, style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: LuluColors.lavenderMist),
            child: Text(l10n.confirm,
                style: const TextStyle(color: LuluColors.midnightNavy)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      await context.read<FamilyProvider>().transferOwnership(_selectedId!);

      // 🔧 Sprint 19 G-R6: 토스트 제거 → 햅틱 대체
      if (mounted) {
        HapticFeedback.mediumImpact();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
