import 'package:shared_preferences/shared_preferences.dart';

class UserSession {
  static const String _keyUsername = 'username';
  static SharedPreferences? _prefs;
  static String? username;

  /// Initialize Preferences and load existing session
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    username = _prefs?.getString(_keyUsername);
  }

  /// Save username to persistent storage
  static Future<void> saveSession(String user) async {
    username = user;
    await _prefs?.setString(_keyUsername, user);
  }

  /// Clear session from persistent storage
  static Future<void> logout() async {
    username = null;
    await _prefs?.remove(_keyUsername);
  }

  static bool get isLoggedIn => username != null;
}
