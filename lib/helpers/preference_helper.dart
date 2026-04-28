import 'package:shared_preferences/shared_preferences.dart';

class PreferenceHelper {
  static const String userToken = 'userToken';
  static const String refreshToken = 'refreshToken';
  static const String role = 'role';
  // ignore: non_constant_identifier_names
  static get UserToken => PreferenceHelper().getUserToken();

  SharedPreferences? _preferences;

  Future<void> initialize() async {
    _preferences ??= await SharedPreferences.getInstance();
  }

  Future<SharedPreferences> get _prefs async {
    await initialize();
    return _preferences!;
  }

  Future<bool> setRole(String value) async {
    final prefs = await _prefs;
    return await prefs.setString(role, value);
  }

  Future<String> getRole() async {
    final prefs = await _prefs;
    return prefs.getString(role) ?? '';
  }

  Future<bool> removeRole() async {
    final prefs = await _prefs;
    return await prefs.remove(role);
  }

  Future<bool> removeUserToken() async {
    final prefs = await _prefs;
    return await prefs.remove(userToken);
  }

  Future<bool> removeRefreshToken() async {
    final prefs = await _prefs;
    return await prefs.remove(refreshToken);
  }

  Future<bool> setUserToken(String value) async {
    final prefs = await _prefs;
    return await prefs.setString(userToken, value);
  }

  Future<String> getUserToken() async {
    final prefs = await _prefs;
    return prefs.getString(userToken) ?? '';
  }

  Future<bool> setRefreshToken(String value) async {
    final prefs = await _prefs;
    return await prefs.setString(refreshToken, value);
  }

  Future<String> getRefreshToken() async {
    final prefs = await _prefs;
    return prefs.getString(refreshToken) ?? '';
  }

  Future<void> clearAll() async {
    final prefs = await _prefs;
    await prefs.clear();
  }
}
