import '../core/session/app_session.dart';
import '../models/user.dart';
import 'api_service.dart';

/// Authentification JWT contre le backend Spring.
class AuthService {
  final ApiService _api = ApiService.instance;
  final AppSession _session = AppSession.instance;

  Future<User> login(String login, String password) async {
    final raw = await _api.post('/api/auth/login',
        body: {'login': login, 'password': password}, queueIfOffline: false);

    if (raw is! Map) {
      throw Exception('Réponse du serveur invalide');
    }
    final data = Map<String, dynamic>.from(raw);

    // Le token peut s'appeler token, accessToken ou jwt selon le backend
    final token = data['token']?.toString() ??
        data['accessToken']?.toString() ??
        data['jwt']?.toString() ??
        '';
    if (token.isEmpty) {
      throw Exception('Token absent de la réponse du serveur');
    }

    final user = User.fromLoginResponse(data);

    final prenom = data['prenom']?.toString() ?? '';
    final nom = data['nom']?.toString() ?? '';
    final role = data['role']?.toString() ?? 'ENSEIGNANT';
    final displayName =
        '$prenom $nom'.trim().isEmpty ? 'Utilisateur' : '$prenom $nom';

    // L'identifiant peut s'appeler id, enseignantId ou etudiantId
    final userId = int.tryParse(data['id']?.toString() ?? '') ??
        int.tryParse(data['enseignantId']?.toString() ?? '') ??
        int.tryParse(data['etudiantId']?.toString() ?? '') ??
        int.tryParse(data['userId']?.toString() ?? '');
    _session.setFromLogin(
      authToken: token,
      id: userId != null && userId > 0 ? userId : _session.teacherId,
      displayName: displayName,
      email: login.trim(),
      userRole: role,
    );

    try {
      await _loadCurrentUser();
    } catch (_) {}

    await _session.persist();

    // Vider les requêtes d'une session précédente pour éviter les 403
    await _api.clearQueuedRequests();

    return user;
  }

  Future<User> register(String email, String password, String name) async {
    throw UnsupportedError(
        'Inscription non exposée par l\'API mobile actuelle');
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
    if (me is! Map) return;
    final meData = Map<String, dynamic>.from(me);

    final id = int.tryParse(meData['id']?.toString() ?? '') ??
        int.tryParse(meData['idUser']?.toString() ?? '') ??
        int.tryParse(meData['etudiantId']?.toString() ?? '') ??
        int.tryParse(meData['enseignantId']?.toString() ?? '');
    if (id != null && id > 0) {
      _session.teacherId = id;
    }
    final email = meData['email']?.toString();
    if (email != null && email.isNotEmpty) {
      _session.teacherEmail = email;
    }
    final role = meData['role']?.toString();
    if (role != null) _session.role = role;
  }

  Future<void> logout() async {
    await _api.clearQueuedRequests();
    await _session.clearStorage();
  }
}
