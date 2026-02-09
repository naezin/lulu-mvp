import 'package:flutter/material.dart';

import '../../../core/design_system/lulu_colors.dart';
import '../../../core/design_system/lulu_radius.dart';
import '../models/family_member_model.dart';
import '../../../l10n/generated/app_localizations.dart' show S;

/// 멤버 목록 타일
///
/// 가족 멤버 한 명을 표시합니다.
class MemberListTile extends StatelessWidget {
  final FamilyMemberModel member;
  final bool isMe;

  const MemberListTile({
    super.key,
    required this.member,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMe
            ? LuluColors.lavenderLight
            : LuluColors.deepIndigoBorder,
        borderRadius: BorderRadius.circular(LuluRadius.sm),
        border: isMe
            ? Border.all(color: LuluColors.lavenderBorder)
            : null,
      ),
      child: Row(
        children: [
          // 아이콘
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: member.isOwner
                  ? Colors.amber.withValues(alpha: 0.2)
                  : LuluColors.lavenderSelected,
              borderRadius: BorderRadius.circular(LuluRadius.section),
            ),
            child: Center(
              child: Text(
                member.isOwner ? '👑' : '👤',
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      member.displayName,
                      style: const TextStyle(
                        color: LuluTextColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: LuluColors.lavenderMist,
                          borderRadius: BorderRadius.circular(LuluRadius.indicator),
                        ),
                        child: Text(
                          S.of(context)!.memberBadgeMe,
                          style: const TextStyle(
                            color: LuluColors.midnightNavy,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  member.isOwner
                      ? S.of(context)!.memberRoleOwner
                      : S.of(context)!.memberJoinedDate(member.joinedAt.month, member.joinedAt.day),
                  style: TextStyle(
                    color: LuluTextColors.primarySoft,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
