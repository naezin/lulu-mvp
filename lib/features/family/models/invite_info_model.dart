/// 초대 정보 모델
///
/// get_invite_info RPC 응답을 표현합니다.
/// 비인증 사용자도 조회 가능한 초대 코드 정보입니다.
class InviteInfoModel {
  final bool isValid;
  final String? error;
  final String? familyId;
  final int memberCount;
  final List<InviteBabyInfo> babies;
  final DateTime? expiresAt;

  const InviteInfoModel({
    required this.isValid,
    this.error,
    this.familyId,
    this.memberCount = 0,
    this.babies = const [],
    this.expiresAt,
  });

  /// 남은 일수
  int get daysLeft {
    if (expiresAt == null) return 0;
    final diff = expiresAt!.difference(DateTime.now()).inDays;
    return diff > 0 ? diff : 0;
  }

  /// JSON에서 생성
  factory InviteInfoModel.fromJson(Map<String, dynamic> json) {
    final isValid = json['valid'] as bool? ?? false;

    if (!isValid) {
      return InviteInfoModel(
        isValid: false,
        error: json['error'] as String? ?? 'Invalid invite code',
      );
    }

    final babiesJson = json['babies'] as List<dynamic>? ?? [];

    return InviteInfoModel(
      isValid: true,
      familyId: json['familyId'] as String?,
      memberCount: json['memberCount'] as int? ?? 0,
      babies: babiesJson
          .map((b) => InviteBabyInfo.fromJson(b as Map<String, dynamic>))
          .toList(),
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
    );
  }

  /// 유효하지 않은 응답 생성
  factory InviteInfoModel.invalid(String error) {
    return InviteInfoModel(isValid: false, error: error);
  }

  @override
  String toString() {
    return 'InviteInfoModel(valid: $isValid, members: $memberCount, babies: ${babies.length})';
  }
}

/// 초대 정보 내 아기 정보
class InviteBabyInfo {
  final String id;
  final String name;

  const InviteBabyInfo({
    required this.id,
    required this.name,
  });

  factory InviteBabyInfo.fromJson(Map<String, dynamic> json) {
    return InviteBabyInfo(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

/// 아기 매핑 (기록 마이그레이션용)
class BabyMapping {
  final String fromBabyId;
  final String toBabyId;

  const BabyMapping({
    required this.fromBabyId,
    required this.toBabyId,
  });

  Map<String, dynamic> toJson() {
    return {
      'fromBabyId': fromBabyId,
      'toBabyId': toBabyId,
    };
  }
}

/// 초대 수락 결과
class AcceptInviteResult {
  final bool success;
  final String familyId;
  final int migratedCount;

  const AcceptInviteResult({
    required this.success,
    required this.familyId,
    required this.migratedCount,
  });

  factory AcceptInviteResult.fromJson(Map<String, dynamic> json) {
    return AcceptInviteResult(
      success: json['success'] as bool? ?? false,
      familyId: json['familyId'] as String? ?? '',
      migratedCount: json['migratedCount'] as int? ?? 0,
    );
  }
}
