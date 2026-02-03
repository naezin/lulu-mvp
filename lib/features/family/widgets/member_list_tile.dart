import 'package:flutter/material.dart';

import '../../../core/design_system/lulu_colors.dart';
import '../models/family_member_model.dart';

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
            ? LuluColors.lavenderMist.withOpacity(0.15)
            : LuluColors.deepIndigo.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: isMe
            ? Border.all(color: LuluColors.lavenderMist.withOpacity(0.3))
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
                  ? Colors.amber.withOpacity(0.2)
                  : LuluColors.lavenderMist.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
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
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '나',
                          style: TextStyle(
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
                      ? '관리자'
                      : '${member.joinedAt.month}월 ${member.joinedAt.day}일 참여',
                  style: TextStyle(
                    color: LuluTextColors.primary.withOpacity(0.6),
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
