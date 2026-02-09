import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/family_invite_model.dart';
import '../models/family_member_model.dart';
import '../models/invite_info_model.dart';

/// 초대 서비스
///
/// 가족 초대 코드 생성, 공유, 수락 등을 담당합니다.
class InviteService {
  final SupabaseClient _supabase;

  InviteService([SupabaseClient? supabase])
      : _supabase = supabase ?? Supabase.instance.client;

  /// 초대 코드 생성 (6자리 영숫자)
  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // 혼동 문자 제외 (0,O,1,I)
    final random = Random.secure();
    return List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
  }

  /// 새 초대 생성
  ///
  /// [familyId] 가족 ID
  /// [email] 초대할 이메일 (선택)
  /// Returns 생성된 초대 모델
  Future<FamilyInviteModel> createInvite(
    String familyId, {
    String? email,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Not authenticated');
    }

    final inviteCode = _generateInviteCode();
    final expiresAt = DateTime.now().add(const Duration(days: 7));

    final response = await _supabase.from('family_invites').insert({
      'family_id': familyId,
      'invite_code': inviteCode,
      'invited_email': email,
      'created_by': userId,
      'expires_at': expiresAt.toIso8601String(),
    }).select().single();

    debugPrint('✅ [InviteService] Created invite: $inviteCode');
    return FamilyInviteModel.fromJson(response);
  }

  /// 초대 정보 조회 (비인증 가능)
  ///
  /// [code] 초대 코드
  /// Returns 초대 정보 (가족 멤버 수, 아기 목록 등)
  Future<InviteInfoModel> getInviteInfo(String code) async {
    try {
      // 코드 정규화 (대문자, 하이픈 제거)
      final normalizedCode = code.toUpperCase().replaceAll('-', '');

      final response = await _supabase
          .rpc('get_invite_info', params: {'p_invite_code': normalizedCode});

      return InviteInfoModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      debugPrint('❌ [InviteService] getInviteInfo error: $e');
      return InviteInfoModel.invalid('Could not verify invite code');
    }
  }

  /// 초대 수락
  ///
  /// [code] 초대 코드
  /// [babyMappings] 아기 매핑 (기록 마이그레이션용)
  /// Returns 수락 결과
  Future<AcceptInviteResult> acceptInvite(
    String code,
    List<BabyMapping>? babyMappings,
  ) async {
    try {
      final normalizedCode = code.toUpperCase().replaceAll('-', '');

      final params = <String, dynamic>{
        'p_invite_code': normalizedCode,
      };

      if (babyMappings != null && babyMappings.isNotEmpty) {
        params['p_baby_mappings'] = babyMappings.map((m) => m.toJson()).toList();
      }

      final response = await _supabase.rpc('accept_invite', params: params);

      debugPrint('✅ [InviteService] Invite accepted: $response');
      return AcceptInviteResult.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      debugPrint('❌ [InviteService] acceptInvite error: $e');
      rethrow;
    }
  }

  /// 초대 취소
  Future<void> cancelInvite(String inviteId) async {
    await _supabase.from('family_invites').delete().eq('id', inviteId);
    debugPrint('✅ [InviteService] Invite cancelled: $inviteId');
  }

  /// 대기 중인 초대 목록 조회
  Future<List<FamilyInviteModel>> getPendingInvites(String familyId) async {
    final response = await _supabase
        .from('family_invites')
        .select()
        .eq('family_id', familyId)
        .isFilter('used_at', null)
        .gt('expires_at', DateTime.now().toIso8601String())
        .order('created_at', ascending: false);

    return (response as List)
        .map((e) => FamilyInviteModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 가족 멤버 목록 조회
  Future<List<FamilyMemberModel>> getFamilyMembers(String familyId) async {
    // auth.users 정보와 조인하여 조회
    final response = await _supabase.from('family_members').select('''
          *,
          user:auth.users(email, raw_user_meta_data)
        ''').eq('family_id', familyId).order('joined_at', ascending: true);

    return (response as List).map((e) {
      final json = e as Map<String, dynamic>;
      final user = json['user'] as Map<String, dynamic>?;

      return FamilyMemberModel.fromJson({
        ...json,
        'user_email': user?['email'],
        'user_name': (user?['raw_user_meta_data']
            as Map<String, dynamic>?)?['name'],
      });
    }).toList();
  }

  /// 소유권 이전
  Future<void> transferOwnership(String familyId, String newOwnerId) async {
    final response = await _supabase.rpc('transfer_ownership', params: {
      'p_family_id': familyId,
      'p_new_owner_id': newOwnerId,
    });

    if (response['success'] != true) {
      throw Exception('Ownership transfer failed');
    }

    debugPrint('✅ [InviteService] Ownership transferred to: $newOwnerId');
  }

  /// 가족 나가기
  Future<bool> leaveFamily(String familyId) async {
    final response = await _supabase.rpc('leave_family', params: {
      'p_family_id': familyId,
    });

    final familyDeleted = response['familyDeleted'] as bool? ?? false;
    debugPrint(
        '✅ [InviteService] Left family: $familyId (deleted: $familyDeleted)');
    return familyDeleted;
  }

  /// 초대 링크 공유
  Future<void> shareInvite(String code, String? senderName) async {
    final formattedCode =
        code.length == 6 ? '${code.substring(0, 3)}-${code.substring(3)}' : code;

    final message = senderName != null
        ? '$senderName invited you to LULU family!\n\nInvite code: $formattedCode\n\nOpen the app and tap "Join Family" to enter the code.'
        : 'You are invited to a LULU family!\n\nInvite code: $formattedCode\n\nOpen the app and tap "Join Family" to enter the code.';

    await Share.share(message, subject: 'LULU Family Invite');
  }

  /// 초대 코드 클립보드 복사
  Future<void> copyInviteCode(String code) async {
    final formattedCode =
        code.length == 6 ? '${code.substring(0, 3)}-${code.substring(3)}' : code;
    await Clipboard.setData(ClipboardData(text: formattedCode));
  }
}
