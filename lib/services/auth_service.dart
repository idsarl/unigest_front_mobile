import '../core/session/app_session.dart';
import '../models/user.dart';
import 'api_service.dart';

/// Authentification JWT contre le backend Spring.
class AuthService {
  final ApiService _api = ApiService.instance;
  final AppSession _session = AppSession.instance;

  Future<User> login(String email, String password) async {
    final data = await _api.post('/api/auth/login', body: {
      'login': email.trim(),
      'password': password,
    }, queueIfOffline: false);

    final token = data['token']?.toString();
    if (token == null || token.isEmpty) {
      throw Exception('Token manquant dans la réponse');
    }

    final prenom = data['prenom']?.toString() ?? '';
    final nom = data['nom']?.toString() ?? '';
    final role = data['role']?.toString() ?? 'ENSEIGNANT';
    final displayName =
        '$prenom $nom'.trim().isEmpty ? 'Utilisateur' : '$prenom $nom';

    final userId = int.tryParse(data['id']?.toString() ?? '') ??
        int.tryParse(data['enseignantId']?.toString() ?? '');
    _session.setFromLogin(
      authToken: token,
      id: userId != null && userId > 0 ? userId : _session.teacherId,
      displayName: displayName,
      email: email.trim(),
      userRole: role,
    );

    try {
      await _loadCurrentUser();
    } catch (_) {
      // /me optionnel si le profil est déjà dans la réponse login
    }

    await _session.persist();

    return User(
      id: _session.teacherId.toString(),
      email: _session.teacherEmail,
      name: _session.teacherName,
    );
  }

  Future<bool> restoreSession() async {
    final restored = await _session.restore();
    if (!restored) return false;

    try {
      await _loadCurrentUser();
      return true;
    } catch (_) {
      await _session.clearStorage();
      return false;
    }
  }

  Future<void> _loadCurrentUser() async {
    final me = await _api.get('/api/auth/me');
    if (me is! Map<String, dynamic>) return;

    final id = int.tryParse(me['id']?.toString() ?? '') ??
        int.tryParse(me['idUser']?.toString() ?? '');
    if (id != null && id > 0) {
      _session.teacherId = id;
    }
    final email = me['email']?.toString();
    if (email != null && email.isNotEmpty) {
      _session.teacherEmail = email;
    }
    final role = me['role']?.toString();
    if (role != null) _session.role = role;
  }

  Future<void> logout() async {
    await _session.clearStorage();
  }
}
