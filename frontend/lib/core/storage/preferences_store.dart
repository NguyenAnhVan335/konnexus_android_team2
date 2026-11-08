import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/user_model.dart';
import '../../utils/json_utils.dart';

/// Lưu phiên đăng nhập và tuỳ chọn giao diện trên thiết bị.
///
/// Không lưu mật khẩu. Token JWT là thông tin nhạy cảm nên chỉ lưu cục bộ và
/// được xoá khi đăng xuất.
class PreferencesStore {
  PreferencesStore(this._prefs);

  final SharedPreferences _prefs;

  static const String _tokenKey = 'konnexus.auth.token';
  static const String _userIdKey = 'konnexus.auth.user_id';
  static const String _userKey = 'konnexus.auth.user';
  static const String _addressKey = 'konnexus.profile.address';
  static const String _themeModeKey = 'konnexus.settings.theme_mode';
  static const String _accentKey = 'konnexus.settings.accent';
  static const String _savedSearchKey = 'konnexus.search.saved';

  static Future<PreferencesStore> create() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return PreferencesStore(prefs);
  }

  String? get token => _prefs.getString(_tokenKey);

  String? get userId => _prefs.getString(_userIdKey);

  String? get themeMode => _prefs.getString(_themeModeKey);

  String? get accentKey => _prefs.getString(_accentKey);

  String? get address => _prefs.getString(_addressKey);

  UserModel? get cachedUser {
    final String? raw = _prefs.getString(_userKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      return UserModel.fromJson(asMap(jsonDecode(raw)));
    } on FormatException {
      return null;
    }
  }

  Future<void> saveSession({
    required String token,
    required String userId,
    UserModel? user,
  }) async {
    await _prefs.setString(_tokenKey, token);
    await _prefs.setString(_userIdKey, userId);
    if (user != null) {
      await saveUser(user);
    }
  }

  Future<void> saveUser(UserModel user) async {
    await _prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  Future<void> saveAddress(String? address) async {
    if (address == null || address.trim().isEmpty) {
      await _prefs.remove(_addressKey);
      return;
    }
    await _prefs.setString(_addressKey, address.trim());
  }

  Future<void> saveThemeMode(String value) async {
    await _prefs.setString(_themeModeKey, value);
  }

  /// Từ khoá tìm kiếm đã lưu (tối đa 10, mới nhất trước).
  List<String> get savedSearches {
    return _prefs.getStringList(_savedSearchKey) ?? <String>[];
  }

  Future<void> saveSearch(String value) async {
    final String keyword = value.trim();
    if (keyword.isEmpty) {
      return;
    }
    final List<String> items = savedSearches
      ..removeWhere(
          (String item) => item.toLowerCase() == keyword.toLowerCase())
      ..insert(0, keyword);
    await _prefs.setStringList(
        _savedSearchKey, items.take(10).toList(growable: false));
  }

  Future<void> removeSavedSearch(String value) async {
    final List<String> items = savedSearches
      ..removeWhere((String item) => item == value);
    await _prefs.setStringList(_savedSearchKey, items);
  }

  Future<void> saveAccent(String value) async {
    await _prefs.setString(_accentKey, value);
  }

  Future<void> clearSession() async {
    await _prefs.remove(_tokenKey);
    await _prefs.remove(_userIdKey);
    await _prefs.remove(_userKey);
  }
}
