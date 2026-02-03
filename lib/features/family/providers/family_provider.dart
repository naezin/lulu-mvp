import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/family_invite_model.dart';
import '../models/family_member_model.dart';
import '../services/invite_service.dart';

/// 가족 관리 Provider
///
/// 가족 멤버, 초대, 소유권 이전 등을 관리합니다.
class FamilyProvider extends ChangeNotifier {
  final InviteService _inviteService;
  final SupabaseClient _supabase;

  FamilyProvider({
    InviteService? inviteService,
    SupabaseClient? supabase,
  })  : _inviteService = inviteService ?? InviteService(),
        _supabase = supabase ?? Supabase.instance.client;

  // State
  String? _familyId;
  String? _familyName;
  List<FamilyMemberModel> _members = [];
  List<FamilyInviteModel> _pendingInvites = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  String? get familyId => _familyId;
  String? get familyDisplayName => _familyName ?? '우리 가족';
  List<FamilyMemberModel> get members => _members;
  List<FamilyInviteModel> get pendingInvites => _pendingInvites;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool get hasFamily => _familyId != null;
  int get memberCount => _members.length;

  /// 현재 사용자가 소유자인지 확인
  bool get isOwner {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;
    return _members.any((m) => m.userId == userId && m.isOwner);
  }

  /// 현재 사용자 멤버 정보
  FamilyMemberModel? get currentMember {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;
    try {
      return _members.firstWhere((m) => m.userId == userId);
    } catch (_) {
      return null;
    }
  }

  /// 가족 정보 로드
  Future<void> loadFamily(String familyId) async {
    _familyId = familyId;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 병렬로 멤버와 초대 로드
      final results = await Future.wait([
        _inviteService.getFamilyMembers(familyId),
        _inviteService.getPendingInvites(familyId),
      ]);

      _members = results[0] as List<FamilyMemberModel>;
      _pendingInvites = results[1] as List<FamilyInviteModel>;

      debugPrint(
          '✅ [FamilyProvider] Loaded family: ${_members.length} members, ${_pendingInvites.length} pending invites');
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ [FamilyProvider] Load error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 새로고침
  Future<void> refresh() async {
    if (_familyId == null) return;
    await loadFamily(_familyId!);
  }

  /// 초대 생성
  Future<FamilyInviteModel> createInvite() async {
    if (_familyId == null) {
      throw Exception('가족 정보가 없어요');
    }

    final invite = await _inviteService.createInvite(_familyId!);
    _pendingInvites = [invite, ..._pendingInvites];
    notifyListeners();

    return invite;
  }

  /// 이메일 초대 생성
  Future<FamilyInviteModel> createEmailInvite(String email) async {
    if (_familyId == null) {
      throw Exception('가족 정보가 없어요');
    }

    final invite = await _inviteService.createInvite(_familyId!, email: email);
    _pendingInvites = [invite, ..._pendingInvites];
    notifyListeners();

    // TODO: Edge Function으로 이메일 발송
    // await _sendInviteEmail(email, invite.inviteCode);

    return invite;
  }

  /// 초대 취소
  Future<void> cancelInvite(String inviteId) async {
    await _inviteService.cancelInvite(inviteId);
    _pendingInvites = _pendingInvites.where((i) => i.id != inviteId).toList();
    notifyListeners();
  }

  /// 소유권 이전
  Future<void> transferOwnership(String newOwnerId) async {
    if (_familyId == null) {
      throw Exception('가족 정보가 없어요');
    }

    await _inviteService.transferOwnership(_familyId!, newOwnerId);

    // 로컬 상태 업데이트
    final userId = _supabase.auth.currentUser?.id;
    _members = _members.map((m) {
      if (m.userId == userId) {
        return m.copyWith(role: 'member');
      } else if (m.userId == newOwnerId) {
        return m.copyWith(role: 'owner');
      }
      return m;
    }).toList();

    notifyListeners();
  }

  /// 가족 나가기
  Future<bool> leaveFamily() async {
    if (_familyId == null) {
      throw Exception('가족 정보가 없어요');
    }

    final familyDeleted = await _inviteService.leaveFamily(_familyId!);

    // 로컬 상태 초기화
    _familyId = null;
    _familyName = null;
    _members = [];
    _pendingInvites = [];

    notifyListeners();
    return familyDeleted;
  }

  /// 가족 참여 완료 후 호출
  Future<void> onJoinedFamily(String familyId) async {
    await loadFamily(familyId);
  }

  /// 가족 변경 시 호출
  Future<void> onFamilyChanged(String familyId) async {
    await loadFamily(familyId);
  }

  /// 초기화
  void reset() {
    _familyId = null;
    _familyName = null;
    _members = [];
    _pendingInvites = [];
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}
