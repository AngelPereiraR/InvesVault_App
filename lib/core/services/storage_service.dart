import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  static const _tokenKey = 'auth_token';
  static const _userIdKey = 'user_id';
  static const _userNameKey = 'user_name';
  static const _userEmailKey = 'user_email';
  static const _userRoleKey = 'user_role';
  static const _notificationsEnabledKey = 'notifications_enabled';
  static const _lastActiveKey = 'last_active';
  static const _welcomeSeenKey = 'welcome_seen';
  static const _themeModeKey = 'theme_mode';

  final FlutterSecureStorage _storage;

  StorageService() : _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // Token
  Future<void> saveToken(String token) => _storage.write(key: _tokenKey, value: token);
  Future<String?> getToken() => _storage.read(key: _tokenKey);
  Future<void> deleteToken() => _storage.delete(key: _tokenKey);

  // User info
  Future<void> saveUser({
    required int id,
    required String name,
    required String email,
    required String role,
  }) async {
    await Future.wait([
      _storage.write(key: _userIdKey, value: id.toString()),
      _storage.write(key: _userNameKey, value: name),
      _storage.write(key: _userEmailKey, value: email),
      _storage.write(key: _userRoleKey, value: role),
    ]);
  }

  Future<int?> getUserId() async {
    final v = await _storage.read(key: _userIdKey);
    return v != null ? int.tryParse(v) : null;
  }

  Future<String?> getUserName() => _storage.read(key: _userNameKey);
  Future<String?> getUserEmail() => _storage.read(key: _userEmailKey);
  Future<String?> getUserRole() => _storage.read(key: _userRoleKey);

  // Last activity
  Future<void> saveLastActive() => _storage.write(
        key: _lastActiveKey,
        value: DateTime.now().millisecondsSinceEpoch.toString(),
      );

  Future<DateTime?> getLastActive() async {
    final v = await _storage.read(key: _lastActiveKey);
    if (v == null) return null;
    final ms = int.tryParse(v);
    return ms != null ? DateTime.fromMillisecondsSinceEpoch(ms) : null;
  }

  // Welcome screen
  Future<void> markWelcomeSeen() =>
      _storage.write(key: _welcomeSeenKey, value: 'true');

  Future<bool> hasSeenWelcome() async {
    final v = await _storage.read(key: _welcomeSeenKey);
    return v == 'true';
  }

  // Notifications toggle
  Future<void> setNotificationsEnabled(bool enabled) =>
      _storage.write(key: _notificationsEnabledKey, value: enabled.toString());

  Future<bool> getNotificationsEnabled() async {
    final v = await _storage.read(key: _notificationsEnabledKey);
    return v != 'false'; // enabled by default
  }

  // Theme preference
  Future<void> setThemeMode(String mode) =>
      _storage.write(key: _themeModeKey, value: mode);

  Future<String> getThemeMode() async {
    final v = await _storage.read(key: _themeModeKey);
    return v ?? 'system';
  }

  // Clear all
  Future<void> clearAll() => _storage.deleteAll();
}
