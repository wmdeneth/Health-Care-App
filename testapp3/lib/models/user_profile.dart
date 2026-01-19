class UserProfile {
  final String nickname;
  final double? heightCm;
  final double? weightKg;
  final String? photoUrl;

  const UserProfile({
    required this.nickname,
    this.heightCm,
    this.weightKg,
    this.photoUrl,
  });

  factory UserProfile.empty() => const UserProfile(nickname: '');

  UserProfile copyWith({
    String? nickname,
    double? heightCm,
    double? weightKg,
    String? photoUrl,
  }) {
    return UserProfile(
      nickname: nickname ?? this.nickname,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nickname': nickname,
      'heightCm': heightCm,
      'weightKg': weightKg,
      'photoUrl': photoUrl,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      nickname: (map['nickname'] ?? '') as String,
      heightCm: (map['heightCm'] as num?)?.toDouble(),
      weightKg: (map['weightKg'] as num?)?.toDouble(),
      photoUrl: map['photoUrl'] as String?,
    );
  }
}
