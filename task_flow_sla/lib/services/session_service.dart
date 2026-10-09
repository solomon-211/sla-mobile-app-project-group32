import 'package:shared_preferences/shared_preferences.dart';

/// Small key-value settings stored with SharedPreferences: who is signed in
/// and whether to remember them.
class SessionService {
  static const _userIdKey = 'signed_in_user_id';
  static const _rememberKey = 'remember_me';

  static const _projectNameKey = 'project_name';

  /// The project shown on the dashboard, or [fallback] if never renamed.
  static Future<String> projectName({required String fallback}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_projectNameKey) ?? fallback;
  }

  static Future<void> setProjectName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_projectNameKey, name);
  }

  static Future<void> signIn(int userId, {required bool remember}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_userIdKey, userId);
    await prefs.setBool(_rememberKey, remember);
  }

  /// Changes the signed-in member without touching the "remember me" choice.
  static Future<void> switchUser(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_userIdKey, userId);
  }

  static Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
  }

  static Future<int?> currentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userIdKey);
  }

  /// Called once at app start. Returns true when a remembered user exists.
  /// A user who did not tick "Remember me" is signed out on the next launch.
  static Future<bool> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final remember = prefs.getBool(_rememberKey) ?? false;
    if (!remember) {
      await prefs.remove(_userIdKey);
      return false;
    }
    return prefs.getInt(_userIdKey) != null;
  }
}
