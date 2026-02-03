/// 가족 멤버 모델
///
/// family_members 테이블의 데이터를 표현합니다.
class FamilyMemberModel {
  final String id;
  final String familyId;
  final String userId;
  final String role; // 'owner' | 'member'
  final DateTime joinedAt;

  // auth.users 조인 데이터 (선택적)
  final String? userEmail;
  final String? userName;

  const FamilyMemberModel({
    required this.id,
    required this.familyId,
    required this.userId,
    required this.role,
    required this.joinedAt,
    this.userEmail,
    this.userName,
  });

  /// 소유자 여부
  bool get isOwner => role == 'owner';

  /// 표시 이름
  String get displayName => userName ?? userEmail?.split('@').first ?? '멤버';

  /// JSON에서 생성
  factory FamilyMemberModel.fromJson(Map<String, dynamic> json) {
    return FamilyMemberModel(
      id: json['id'] as String,
      familyId: json['family_id'] as String,
      userId: json['user_id'] as String,
      role: json['role'] as String? ?? 'member',
      joinedAt: DateTime.parse(json['joined_at'] as String),
      userEmail: json['user_email'] as String?,
      userName: json['user_name'] as String?,
    );
  }

  /// JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'family_id': familyId,
      'user_id': userId,
      'role': role,
      'joined_at': joinedAt.toIso8601String(),
    };
  }

  /// 복사본 생성
  FamilyMemberModel copyWith({
    String? id,
    String? familyId,
    String? userId,
    String? role,
    DateTime? joinedAt,
    String? userEmail,
    String? userName,
  }) {
    return FamilyMemberModel(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
      userEmail: userEmail ?? this.userEmail,
      userName: userName ?? this.userName,
    );
  }

  @override
  String toString() {
    return 'FamilyMemberModel(id: $id, userId: $userId, role: $role)';
  }
}
