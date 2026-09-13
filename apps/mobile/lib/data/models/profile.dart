class Profile {
  const Profile(
      {required this.id,
      this.email,
      this.displayName,
      this.currencyCode,
      this.avatarPath,
      this.createdAt,
      this.updatedAt});

  final String id;
  final String? email;
  final String? displayName;
  final String? currencyCode;
  final String? avatarPath;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'] as String,
      email: map['email'] as String?,
      displayName: map['display_name'] as String?,
      currencyCode: map['currency_code'] as String?,
      avatarPath: map['avatar_path'] as String?,
      createdAt: _tryParse(map['created_at']),
      updatedAt: _tryParse(map['updated_at']),
    );
  }

  static DateTime? _tryParse(Object? value) {
    if (value is! String) return null;
    return DateTime.tryParse(value);
  }
}
