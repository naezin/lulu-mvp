/// 가족 초대 모델
///
/// family_invites 테이블의 데이터를 표현합니다.
class FamilyInviteModel {
  final String id;
  final String familyId;
  final String inviteCode;
  final String? invitedEmail;
  final String createdBy;
  final DateTime expiresAt;
  final DateTime? usedAt;
  final String? usedBy;
  final DateTime createdAt;

  const FamilyInviteModel({
    required this.id,
    required this.familyId,
    required this.inviteCode,
    this.invitedEmail,
    required this.createdBy,
    required this.expiresAt,
    this.usedAt,
    this.usedBy,
    required this.createdAt,
  });

  /// 사용됨 여부
  bool get isUsed => usedAt != null;

  /// 만료됨 여부
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// 유효함 여부
  bool get isValid => !isUsed && !isExpired;

  /// 남은 일수
  int get daysLeft {
    if (isExpired) return 0;
    return expiresAt.difference(DateTime.now()).inDays;
  }

  /// 포맷된 초대 코드 (ABC-123 형식)
  String get formattedCode {
    if (inviteCode.length == 6) {
      return '${inviteCode.substring(0, 3)}-${inviteCode.substring(3)}';
    }
    return inviteCode;
  }

  /// JSON에서 생성
  factory FamilyInviteModel.fromJson(Map<String, dynamic> json) {
    return FamilyInviteModel(
      id: json['id'] as String,
      familyId: json['family_id'] as String,
      inviteCode: json['invite_code'] as String,
      invitedEmail: json['invited_email'] as String?,
      createdBy: json['created_by'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      usedAt: json['used_at'] != null
          ? DateTime.parse(json['used_at'] as String)
          : null,
      usedBy: json['used_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'family_id': familyId,
      'invite_code': inviteCode,
      'invited_email': invitedEmail,
      'created_by': createdBy,
      'expires_at': expiresAt.toIso8601String(),
      'used_at': usedAt?.toIso8601String(),
      'used_by': usedBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'FamilyInviteModel(code: $formattedCode, valid: $isValid)';
  }
}
