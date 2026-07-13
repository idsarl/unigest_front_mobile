import 'package:get/get.dart';
import '../../../services/auth_service.dart';
import '../../../core/constants/app_constants.dart';

class AuthController extends GetxController {
  AuthController({AuthService? authService})
      : authService = authService ?? AuthService();

  final AuthService authService;

  final RxBool isLoading = false.obs;
  final RxBool isCheckingSession = true.obs;
  final RxBool isAuthenticated = false.obs;
  final RxnString error = RxnString();

  @override
  void onInit() {
    super.onInit();
    checkSession();
  }

  Future<void> checkSession() async {
    isCheckingSession.value = true;
    try {
      isAuthenticated.value = await authService.restoreSession();
    } catch (_) {
      isAuthenticated.value = false;
    } finally {
      isCheckingSession.value = false;
    }
  }

  Future<void> login(String email, String password) async {
    isLoading.value = true;
    error.value = null;
    try {
      await authService.login(email, password);
      isAuthenticated.value = true;
    } catch (e) {
      error.value = _formatError(e);
      isAuthenticated.value = false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    await authService.logout();
    isAuthenticated.value = false;
  }

  String _formatError(Object e) {
    final msg = e.toString();
    if (msg.contains('SocketException') ||
        msg.contains('Failed host lookup') ||
        msg.contains('Connection refused')) {
      return 'Impossible de joindre le serveur (${AppConstants.baseUrl}).';
    }
    if (msg.contains('401') || msg.contains('403')) {
      return 'Email ou mot de passe incorrect';
    }
    return 'Connexion impossible : $msg';
  }
}
