import '../models/user.dart';
import 'api_service.dart';

/// Authentication service
class AuthService {
  final ApiService apiService;

  AuthService({required this.apiService});

  Future<User> login(String email, String password) async {
    // Implement login logic
    await Future.delayed(const Duration(seconds: 1)); // Simulate API call
    return User(
      id: '1',
      email: email,
      name: 'Test User',
    );
  }

  Future<User> register(String email, String password, String name) async {
    // Implement registration logic
    await Future.delayed(const Duration(seconds: 1)); // Simulate API call
    return User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      email: email,
      name: name,
    );
  }

  Future<void> logout() async {
    // Implement logout logic
    await Future.delayed(const Duration(milliseconds: 500));
  }
}
