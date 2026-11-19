import '../utils/json_utils.dart';

/// Dữ liệu tổng quan từ `GET /api/admin/dashboard`.
class AdminDashboard {
  const AdminDashboard({
    this.totalUsers = 0,
    this.totalPosts = 0,
    this.totalMessages = 0,
    this.totalRooms = 0,
    this.totalMessagesToday = 0,
    this.onlineUsers = 0,
    this.isBotEnabled = false,
    this.botTokensUsed = 0,
    this.totalUsageHours,
    this.chart = const <AdminChartPoint>[],
  });

  final int totalUsers;
  final int totalPosts;
  final int totalMessages;
  final int totalRooms;
  final int totalMessagesToday;
  final int onlineUsers;
  final bool isBotEnabled;
  final int botTokensUsed;

  /// Backend chưa lưu phiên làm việc nên trả `null`; UI hiển thị "Chưa có dữ liệu".
  final double? totalUsageHours;

  final List<AdminChartPoint> chart;

  factory AdminDashboard.fromJson(Map<String, dynamic> json) {
    return AdminDashboard(
      totalUsers: asInt(json['totalUsers']),
      totalPosts: asInt(json['totalPosts']),
      totalMessages: asInt(json['totalMessages']),
      totalRooms: asInt(json['totalRooms']),
      totalMessagesToday: asInt(json['totalMessagesToday']),
      onlineUsers: asInt(json['onlineUsers']),
      isBotEnabled: asBool(json['isBotEnabled']),
      botTokensUsed: asInt(json['botTokensUsed']),
      totalUsageHours: _asDouble(json['totalUsageHours']),
      chart: asList(json['chartData'])
          .whereType<Map>()
          .map((dynamic item) => AdminChartPoint.fromJson(asMap(item)))
          .toList(growable: false),
    );
  }

  static double? _asDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return null;
  }
}

/// Một điểm dữ liệu trong biểu đồ 7 ngày.
class AdminChartPoint {
  const AdminChartPoint({required this.date, required this.messages});

  final String date;
  final int messages;

  factory AdminChartPoint.fromJson(Map<String, dynamic> json) {
    return AdminChartPoint(
      date: asString(json['date']) ?? '',
      messages: asInt(json['messages']),
    );
  }
}

/// Người dùng từ `GET /api/admin/users/list`.
class AdminUser {
  const AdminUser({
    required this.id,
    required this.username,
    this.email,
    this.avatarUrl,
    this.role = 'USER',
    this.isOnline = false,
    this.isActive = true,
    this.createdAt,
    this.lastSeen,
  });

  final String id;
  final String username;
  final String? email;
  final String? avatarUrl;
  final String role;
  final bool isOnline;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? lastSeen;

  bool get isAdmin => role.trim().toUpperCase() == 'ADMIN';

  String get displayName => username.trim().isEmpty ? 'Người dùng' : username.trim();

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: asString(json['id']) ?? '',
      username: asString(json['username']) ?? '',
      email: asString(json['email']),
      avatarUrl: asString(json['avatar_url']) ?? asString(json['avatarUrl']),
      role: asString(json['role']) ?? 'USER',
      isOnline: asBool(json['is_online'],
          fallback: asBool(json['_online'], fallback: asBool(json['online']))),
      isActive: asBool(json['is_active'],
          fallback: asBool(json['_active'], fallback: asBool(json['active'], fallback: true))),
      createdAt: parseApiDate(json['created_at']),
      lastSeen: parseApiDate(json['last_seen']),
    );
  }
}

/// Phòng chat từ `GET /api/admin/rooms/list`.
class AdminRoom {
  const AdminRoom({
    required this.id,
    this.type = 'DIRECT',
    this.title,
    this.avatarUrl,
    this.createdBy,
    this.createdAt,
  });

  final String id;
  final String type;
  final String? title;
  final String? avatarUrl;
  final String? createdBy;
  final DateTime? createdAt;

  bool get isGroup => type.trim().toUpperCase() == 'GROUP';

  String get displayName => (title ?? '').trim().isEmpty ? 'Phòng chat' : title!.trim();

  factory AdminRoom.fromJson(Map<String, dynamic> json) {
    return AdminRoom(
      id: asString(json['id']) ?? '',
      type: asString(json['conversation_type']) ??
          asString(json['type']) ??
          'DIRECT',
      title: asString(json['title']),
      avatarUrl: asString(json['avatar_url']) ?? asString(json['avatarUrl']),
      createdBy: asString(json['created_by']) ?? asString(json['createdBy']),
      createdAt: parseApiDate(json['created_at']),
    );
  }
}
