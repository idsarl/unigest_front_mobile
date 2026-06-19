import '../models/user.dart';
import '../core/services/api_service.dart';

/// Authentication service
class AuthService {
  Future<User> login(String email, String password) async {
    final response = await ApiService.post('/auth/login', body: {
      'login': email,
      'password': password,
    });
    final data = ApiService.decodeJson(response);
    ApiService.setToken(data['token']?.toString());

    return User(
      id: (data['id'] ?? data['idUser'] ?? '').toString(),
      email: email,
      name: [data['prenom'], data['nom']]
          .where((part) => part != null && part.toString().trim().isNotEmpty)
          .join(' '),
    );
  }

  Future<User> register(String email, String password, String name) async {
    throw UnsupportedError('Inscription non exposée par l’API mobile actuelle');
  }

  Future<void> logout() async {
    ApiService.clearToken();
  }
}
