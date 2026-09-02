import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Session utilisateur connecté (JWT + profil enseignant).
class AppSession {
  AppSession._();

  static final AppSession instance = AppSession._();

  static const String _keyToken = 'auth_token';
  static const String _keyTeacherId = 'teacher_id';
  static const String _keyTeacherName = 'teacher_name';
  static const String _keyTeacherEmail = 'teacher_email';
  static const String _keyRole = 'user_role';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  String? token;
  int teacherId = 0;
  String teacherName = '';
  String teacherEmail = '';
  String role = 'ENSEIGNANT';

  bool get isAuthenticated => token != null && token!.isNotEmpty;

  void setFromLogin({
    required String authToken,
    required int id,
    required String displayName,
    required String email,
    String userRole = 'ENSEIGNANT',
  }) {
    token = authToken;
    teacherId = id;
    teacherName = displayName;
    teacherEmail = email;
    role = userRole;
  }

  void clear() {
    token = null;
    teacherId = 0;
    teacherName = '';
    teacherEmail = '';
    role = 'ENSEIGNANT';
  }

  Future<void> persist() async {
    final prefs = await SharedPreferences.getInstance();
    if (token != null) {
      await _secureStorage.write(key: _keyToken, value: token!);
    }
    // Supprime l'ancienne copie non chiffrée après migration.
    await prefs.remove(_keyToken);
    await prefs.setInt(_keyTeacherId, teacherId);
    await prefs.setString(_keyTeacherName, teacherName);
    await prefs.setString(_keyTeacherEmail, teacherEmail);
    await prefs.setString(_keyRole, role);
  }

  Future<bool> restore() async {
    final prefs = await SharedPreferences.getInstance();
    token = await _secureStorage.read(key: _keyToken);
    // Migration transparente des versions qui stockaient le JWT en clair.
    final legacyToken = prefs.getString(_keyToken);
    if ((token == null || token!.isEmpty) &&
        legacyToken != null &&
        legacyToken.isNotEmpty) {
      token = legacyToken;
      await _secureStorage.write(key: _keyToken, value: legacyToken);
    }
    await prefs.remove(_keyToken);
    teacherId = prefs.getInt(_keyTeacherId) ?? 0;
    teacherName = prefs.getString(_keyTeacherName) ?? '';
    teacherEmail = prefs.getString(_keyTeacherEmail) ?? '';
    role = prefs.getString(_keyRole) ?? 'ENSEIGNANT';
    return isAuthenticated;
  }

  Future<void> clearStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await _secureStorage.delete(key: _keyToken);
    await prefs.remove(_keyToken);
    await prefs.remove(_keyTeacherId);
    await prefs.remove(_keyTeacherName);
    await prefs.remove(_keyTeacherEmail);
    await prefs.remove(_keyRole);
    clear();
  }
}
