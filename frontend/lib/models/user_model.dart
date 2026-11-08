import '../utils/formatters.dart';
import '../utils/json_utils.dart';

/// Người dùng theo payload thật của `GET /api/users` (entity `User`).
class UserModel {
  const UserModel({
    required this.id,
    required this.username,
    this.email,
    this.avatarUrl,
    this.isOnline = false,
    this.note,
    this.birthday,
    this.createdAt,
    this.lastSeen,
    this.address,
    this.gender,
  });

  final String id;
  final String username;
  final String? email;
  final String? avatarUrl;
  final bool isOnline;
  final String? note;
  final DateTime? birthday;
  final DateTime? createdAt;
  final DateTime? lastSeen;

  /// Địa chỉ và giới tính chỉ lưu cục bộ trên thiết bị: backend chưa có hai
  /// cột này trong bảng `users`.
  final String? address;
  final String? gender;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: asString(json['id']) ?? '',
      username: asString(json['username']) ?? '',
      email: asString(json['email']),
      avatarUrl: asString(json['avatar_url']) ?? asString(json['avatarUrl']),
      // Lombok sinh getter `is_online()` nên Jackson có thể trả `online`.
      isOnline: asBool(json['is_online'], fallback: asBool(json['online'])),
      note: asString(json['note']),
      birthday: parseApiDate(json['birthday']),
      createdAt: parseApiDate(json['created_at']),
      lastSeen: parseApiDate(json['last_seen']),
      address: asString(json['address']),
      gender: asString(json['gender']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'username': username,
      'email': email,
      'avatar_url': avatarUrl,
      'is_online': isOnline,
      'note': note,
      'birthday': birthday?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'last_seen': lastSeen?.toIso8601String(),
      'address': address,
      'gender': gender,
    };
  }

  UserModel copyWith({
    String? username,
    String? email,
    String? avatarUrl,
    bool? isOnline,
    String? note,
    DateTime? birthday,
    String? address,
    String? gender,
  }) {
    return UserModel(
      id: id,
      username: username ?? this.username,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isOnline: isOnline ?? this.isOnline,
      note: note ?? this.note,
      birthday: birthday ?? this.birthday,
      createdAt: createdAt,
      lastSeen: lastSeen,
      address: address ?? this.address,
      gender: gender ?? this.gender,
    );
  }

  String get displayName {
    final String value = username.trim();
    return value.isEmpty ? 'Người dùng' : value;
  }

  String get initials => initialsOf(displayName);
}
