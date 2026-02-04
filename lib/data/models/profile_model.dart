/// 사용자 프로필 모델
/// profiles 테이블과 매핑
class ProfileModel {
  final String id;
  final String nickname;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProfileModel({
    required this.id,
    required this.nickname,
    this.avatarUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Supabase JSON에서 생성
  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      nickname: json['nickname'] as String? ?? 'User',
      avatarUrl: json['avatar_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Supabase JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nickname': nickname,
      'avatar_url': avatarUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// 업데이트용 JSON (id, created_at 제외)
  Map<String, dynamic> toUpdateJson() {
    return {
      'nickname': nickname,
      'avatar_url': avatarUrl,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  /// copyWith
  ProfileModel copyWith({
    String? id,
    String? nickname,
    String? avatarUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      nickname: nickname ?? this.nickname,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'ProfileModel(id: $id, nickname: $nickname)';
  }
}
