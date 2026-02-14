import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/design_system/lulu_colors.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/design_system/lulu_icons.dart';
import '../../../core/design_system/lulu_radius.dart';
import '../../../core/utils/app_toast.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../models/family_invite_model.dart';
import '../providers/family_provider.dart';
import '../services/invite_service.dart';

/// 초대 바텀시트
///
/// 초대 코드를 생성하고 공유합니다.
class InviteBottomSheet extends StatefulWidget {
  const InviteBottomSheet({super.key});

  @override
  State<InviteBottomSheet> createState() => _InviteBottomSheetState();
}

class _InviteBottomSheetState extends State<InviteBottomSheet> {
  final _emailController = TextEditingController();
  final _inviteService = InviteService();

  FamilyInviteModel? _invite;
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _createInvite();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _createInvite() async {
    try {
      final invite = await context.read<FamilyProvider>().createInvite();
      setState(() {
        _invite = invite;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('[ERR] [InviteBottomSheet] Create invite failed: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        AppToast.showText(S.of(context)?.errorOccurred ?? 'Something went wrong');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context)!;

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 핸들
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: LuluTextColors.primaryHint,
              borderRadius: BorderRadius.circular(LuluRadius.xxs),
            ),
          ),
          const SizedBox(height: 24),

          // 헤더
          Row(
            children: [
              const Icon(LuluIcons.people, color: LuluColors.lavenderMist, size: 28),
              const SizedBox(width: 12),
              Text(
                l10n.inviteFamily,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: LuluTextColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(color: LuluColors.lavenderMist),
            )
          else if (_invite != null) ...[
            // 초대 코드
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: LuluColors.deepIndigoMedium,
                borderRadius: BorderRadius.circular(LuluRadius.sm),
              ),
              child: Column(
                children: [
                  Text(
                    _invite!.formattedCode,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: LuluTextColors.primary,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.inviteValidDays(_invite!.daysLeft.toString()),
                    style: TextStyle(
                      color: LuluTextColors.primarySoft,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 이메일 입력 (선택적)
            TextField(
              controller: _emailController,
              style: const TextStyle(color: LuluTextColors.primary),
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: l10n.inviteByEmail,
                labelStyle: TextStyle(
                  color: LuluTextColors.primarySoft,
                ),
                filled: true,
                fillColor: LuluColors.deepIndigoBorder,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(LuluRadius.sm),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  onPressed: _isSending ? null : _sendEmail,
                  icon: _isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: LuluColors.lavenderMist,
                          ),
                        )
                      : const Icon(LuluIcons.send, color: LuluColors.lavenderMist),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 공유 버튼들
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _shareKakao,
                    icon:
                        const Icon(LuluIcons.chat, color: LuluColors.lavenderMist),
                    label: Text(
                      l10n.shareKakao,
                      style: const TextStyle(color: LuluColors.lavenderMist),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: LuluColors.lavenderMist),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _copyCode,
                    icon: const Icon(LuluIcons.copy, color: LuluColors.lavenderMist),
                    label: Text(
                      l10n.copyCode,
                      style: const TextStyle(color: LuluColors.lavenderMist),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: LuluColors.lavenderMist),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _sendEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    // 간단한 이메일 검증
    if (!email.contains('@')) {
      AppToast.showText(S.of(context)!.invalidEmail);
      return;
    }

    setState(() => _isSending = true);

    try {
      await context.read<FamilyProvider>().createEmailInvite(email);
      _emailController.clear();

      if (mounted) {
        AppToast.showText(S.of(context)!.inviteEmailSent);
      }
    } catch (e) {
      debugPrint('[ERR] [InviteBottomSheet] Send email invite failed: $e');
      if (mounted) {
        AppToast.showText(S.of(context)?.errorOccurred ?? 'Something went wrong');
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _shareKakao() async {
    if (_invite == null) return;

    final userName =
        SupabaseService.currentUser?.userMetadata?['name'];

    // Sprint 20 HF #5: iPad sharePositionOrigin
    final box = context.findRenderObject() as RenderBox?;
    final shareOrigin = box != null
        ? box.localToGlobal(Offset.zero) & box.size
        : null;
    await _inviteService.shareInvite(_invite!.inviteCode, userName as String?, sharePositionOrigin: shareOrigin);
  }

  Future<void> _copyCode() async {
    if (_invite == null) return;

    await Clipboard.setData(ClipboardData(text: _invite!.formattedCode));

    if (mounted) {
      AppToast.showText(S.of(context)!.codeCopied);
    }
  }
}
