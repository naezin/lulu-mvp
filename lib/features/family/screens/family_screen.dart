import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/design_system/lulu_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../providers/family_provider.dart';
import '../widgets/invite_bottom_sheet.dart';
import '../widgets/member_list_tile.dart';
import 'join_family_screen.dart';
import 'transfer_owner_screen.dart';

/// 가족 관리 화면
///
/// 가족 멤버 목록, 초대, 소유권 이전 등을 관리합니다.
class FamilyScreen extends StatefulWidget {
  const FamilyScreen({super.key});

  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FamilyProvider>().refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context)!;

    return Scaffold(
      backgroundColor: LuluColors.midnightNavy,
      appBar: AppBar(
        backgroundColor: LuluColors.midnightNavy,
        title: Text(l10n.familyManagement),
      ),
      body: Consumer<FamilyProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: LuluColors.lavenderMist),
            );
          }

          return RefreshIndicator(
            onRefresh: provider.refresh,
            color: LuluColors.lavenderMist,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 가족 헤더
                _buildFamilyHeader(context, provider),
                const SizedBox(height: 24),

                // 멤버 목록
                _buildMemberSection(context, provider, l10n),
                const SizedBox(height: 24),

                // 대기 초대 (owner만)
                if (provider.isOwner && provider.pendingInvites.isNotEmpty)
                  _buildPendingInvites(context, provider, l10n),

                // 초대 버튼 (owner만)
                if (provider.isOwner) _buildInviteButton(context, l10n),

                const SizedBox(height: 32),
                const Divider(color: LuluColors.deepIndigo),
                const SizedBox(height: 16),

                // 설정 섹션
                _buildSettingsSection(context, provider, l10n),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFamilyHeader(BuildContext context, FamilyProvider provider) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: LuluColors.lavenderMist.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Text('👨‍👩‍👧', style: TextStyle(fontSize: 24)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                provider.familyDisplayName ?? '우리 가족',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: LuluTextColors.primary,
                ),
              ),
              Text(
                '${provider.memberCount}명의 가족',
                style: TextStyle(
                  fontSize: 14,
                  color: LuluTextColors.primary.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMemberSection(
    BuildContext context,
    FamilyProvider provider,
    S l10n,
  ) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.familyMembers,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: LuluTextColors.primary,
          ),
        ),
        const SizedBox(height: 12),
        ...provider.members.map((member) => MemberListTile(
              member: member,
              isMe: member.userId == currentUserId,
            )),
      ],
    );
  }

  Widget _buildPendingInvites(
    BuildContext context,
    FamilyProvider provider,
    S l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.pendingInvites,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: LuluTextColors.primary,
          ),
        ),
        const SizedBox(height: 12),
        ...provider.pendingInvites.map((invite) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: LuluColors.deepIndigo.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.mail_outline,
                      color: LuluColors.lavenderMist, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          invite.invitedEmail ?? invite.formattedCode,
                          style: const TextStyle(
                            color: LuluTextColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${invite.daysLeft}일 남음',
                          style: TextStyle(
                            fontSize: 12,
                            color: LuluTextColors.primary.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => provider.cancelInvite(invite.id),
                    child: Text(
                      l10n.cancel,
                      style: TextStyle(color: Colors.red[300]),
                    ),
                  ),
                ],
              ),
            )),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildInviteButton(BuildContext context, S l10n) {
    return OutlinedButton.icon(
      onPressed: () => showModalBottomSheet(
        context: context,
        backgroundColor: LuluColors.midnightNavy,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => ChangeNotifierProvider.value(
          value: context.read<FamilyProvider>(),
          child: const InviteBottomSheet(),
        ),
      ),
      icon: const Icon(Icons.person_add, color: LuluColors.lavenderMist),
      label: Text(
        l10n.inviteFamily,
        style: const TextStyle(color: LuluColors.lavenderMist),
      ),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: LuluColors.lavenderMist),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      ),
    );
  }

  Widget _buildSettingsSection(
    BuildContext context,
    FamilyProvider provider,
    S l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.familySettings,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: LuluTextColors.primary,
          ),
        ),
        const SizedBox(height: 12),

        // 관리자 넘기기 (owner이고 다른 멤버가 있을 때만)
        if (provider.isOwner && provider.memberCount > 1)
          _buildSettingTile(
            icon: Icons.swap_horiz,
            title: l10n.transferOwnership,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TransferOwnerScreen()),
            ),
          ),

        // 다른 가족 참여
        _buildSettingTile(
          icon: Icons.group_add,
          title: l10n.joinOtherFamily,
          onTap: () => _showJoinOtherDialog(context, l10n),
        ),

        // 가족 나가기
        _buildSettingTile(
          icon: Icons.exit_to_app,
          title: l10n.leaveFamily,
          color: Colors.red[300],
          onTap: () => _showLeaveDialog(context, provider, l10n),
        ),
      ],
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    Color? color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? LuluTextColors.primary),
      title: Text(
        title,
        style: TextStyle(color: color ?? LuluTextColors.primary),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: color ?? LuluTextColors.primary.withOpacity(0.5),
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  void _showJoinOtherDialog(BuildContext context, S l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: LuluColors.deepIndigo,
        title: Text(l10n.joinOtherFamily,
            style: const TextStyle(color: LuluTextColors.primary)),
        content: Text(
          l10n.joinOtherFamilyDesc,
          style: TextStyle(color: LuluTextColors.primary.withOpacity(0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                Text(l10n.cancel, style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const JoinFamilyScreen()),
              );
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: LuluColors.lavenderMist),
            child: Text(l10n.continueButton,
                style: const TextStyle(color: LuluColors.midnightNavy)),
          ),
        ],
      ),
    );
  }

  void _showLeaveDialog(
      BuildContext context, FamilyProvider provider, S l10n) {
    // 소유자이고 다른 멤버가 있으면 나갈 수 없음
    if (provider.isOwner && provider.memberCount > 1) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: LuluColors.deepIndigo,
          title: Text(l10n.cannotLeave,
              style: const TextStyle(color: LuluTextColors.primary)),
          content: Text(
            l10n.transferOwnershipFirst,
            style: TextStyle(color: LuluTextColors.primary.withOpacity(0.8)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.confirm,
                  style: const TextStyle(color: LuluColors.lavenderMist)),
            ),
          ],
        ),
      );
      return;
    }

    final isLastMember = provider.memberCount == 1;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: LuluColors.deepIndigo,
        title: Text(
          isLastMember ? l10n.deleteFamily : l10n.leaveFamily,
          style: const TextStyle(color: LuluTextColors.primary),
        ),
        content: Text(
          isLastMember ? l10n.deleteFamilyDesc : l10n.leaveFamilyDesc,
          style: TextStyle(color: LuluTextColors.primary.withOpacity(0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                Text(l10n.cancel, style: const TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await provider.leaveFamily();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                    context, '/home', (r) => false);
              }
            },
            child: Text(l10n.leave, style: TextStyle(color: Colors.red[300])),
          ),
        ],
      ),
    );
  }
}
