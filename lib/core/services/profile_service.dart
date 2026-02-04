import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/profile_model.dart';
import 'supabase_service.dart';

/// 프로필 관리 서비스
/// profiles 테이블 CRUD
class ProfileService {
  static final ProfileService _instance = ProfileService._internal();
  factory ProfileService() => _instance;
  ProfileService._internal();

  static ProfileService get instance => _instance;

  /// 현재 사용자 프로필 조회
  Future<ProfileModel?> getCurrentProfile() async {
    try {
      final userId = SupabaseService.currentUserId;
      if (userId == null) {
        debugPrint('[WARN] ProfileService: No current user');
        return null;
      }

      final response = await SupabaseService.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) {
        debugPrint('[WARN] ProfileService: Profile not found for $userId');
        return null;
      }

      return ProfileModel.fromJson(response);
    } on PostgrestException catch (e) {
      debugPrint('[ERROR] ProfileService.getCurrentProfile: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('[ERROR] ProfileService.getCurrentProfile: $e');
      return null;
    }
  }

  /// 프로필 조회 (by ID)
  Future<ProfileModel?> getProfile(String userId) async {
    try {
      final response = await SupabaseService.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) return null;

      return ProfileModel.fromJson(response);
    } on PostgrestException catch (e) {
      debugPrint('[ERROR] ProfileService.getProfile: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('[ERROR] ProfileService.getProfile: $e');
      return null;
    }
  }

  /// 프로필 업데이트
  Future<ProfileModel?> updateProfile({
    required String nickname,
    String? avatarUrl,
  }) async {
    try {
      final userId = SupabaseService.currentUserId;
      if (userId == null) {
        debugPrint('[ERROR] ProfileService.updateProfile: No current user');
        return null;
      }

      final response = await SupabaseService.client
          .from('profiles')
          .update({
            'nickname': nickname,
            'avatar_url': avatarUrl,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId)
          .select()
          .single();

      debugPrint('[OK] ProfileService: Profile updated');
      return ProfileModel.fromJson(response);
    } on PostgrestException catch (e) {
      debugPrint('[ERROR] ProfileService.updateProfile: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('[ERROR] ProfileService.updateProfile: $e');
      return null;
    }
  }

  /// 닉네임만 업데이트
  Future<bool> updateNickname(String nickname) async {
    final profile = await updateProfile(nickname: nickname);
    return profile != null;
  }
}
