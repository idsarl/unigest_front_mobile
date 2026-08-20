import 'package:get/get.dart';
import '../../../core/config/server_config_service.dart';
import '../../../core/utils/error_handler.dart';
import '../../../models/user.dart';
import '../../../services/auth_service.dart';
import '../../../services/api_service.dart';
import '../../../core/session/app_session.dart';

class AuthController extends GetxController {
  AuthController({AuthService? authService})
      : authService = authService ?? AuthService();

  final AuthService authService;

  final RxBool isLoading = false.obs;
  final RxBool isCheckingSession = true.obs;
  final RxBool isAuthenticated = false.obs;
  final RxnString error = RxnString();

  final RxString email = ''.obs;
  final RxString password = ''.obs;
  final RxBool isPasswordVisible = false.obs;
  final RxnString authError = RxnString();
  final RxString userRole = ''.obs;
  final RxInt userId = 0.obs;
  final RxString userName = ''.obs;
  final RxString userPrenom = ''.obs;

  User? get user {
    if (!isAuthenticated.value) return null;
    return User(
      id: userId.value.toString(),
      nom: userName.value,
      prenom: userPrenom.value,
      role: userRole.value,
    );
  }

  @override
  void onInit() {
    super.onInit();
    checkSession();
  }

  Future<void> checkSession() async {
    isCheckingSession.value = true;
    try {
      final active = await authService.restoreSession();
      isAuthenticated.value = active;
      if (active) {
        _syncUserFields();
      }
    } catch (_) {
      isAuthenticated.value = false;
    } finally {
      isCheckingSession.value = false;
    }
  }

  void _syncUserFields() {
    final session = AppSession.instance;
    userRole.value = session.role;
    userId.value = session.teacherId;

    final sessionName = session.teacherName;
    final parts = sessionName.split(' ');
    if (parts.length > 1) {
      userPrenom.value = parts.first;
      userName.value = parts.sublist(1).join(' ');
    } else {
      userPrenom.value = '';
      userName.value = sessionName;
    }
  }

  Future<void> login(String emailVal, String passwordVal) async {
    isLoading.value = true;
    error.value = null;
    authError.value = null;
    try {
      await authService.login(emailVal, passwordVal);
      _syncUserFields();
      isAuthenticated.value = true;
      _navigateAfterLogin();
    } catch (e) {
      error.value = _formatError(e);
      authError.value = error.value;
      isAuthenticated.value = false;
    } finally {
      isLoading.value = false;
    }
  }

  void _navigateAfterLogin() {
    final role = AppSession.instance.role.toUpperCase();
    if (role == 'PARENT') {
      Get.offAllNamed('/parent-home');
    } else if (role == 'ETUDIANT' || role == 'ELEVE' || role == 'STUDENT') {
      Get.offAllNamed('/student-home');
    } else {
      Get.offAllNamed('/teacher-home');
    }
  }

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  Future<void> logout() async {
    await authService.logout();
    userName.value = '';
    userPrenom.value = '';
    userRole.value = '';
    userId.value = 0;
    isAuthenticated.value = false;
    Get.offAllNamed('/auth');
  }

  /// Déconnecte l'utilisateur, réinitialise le client HTTP et redirige vers
  /// l'écran de configuration serveur pour permettre de changer d'organisation.
  Future<void> changeServer() async {
    await authService.logout();
    await ApiService.instance.resetForServerChange();
    userName.value = '';
    userPrenom.value = '';
    userRole.value = '';
    userId.value = 0;
    isAuthenticated.value = false;
    await ServerConfigService.instance.clearServerUrl();
    Get.offAllNamed('/server-config');
  }

  String _formatError(Object e) {
    final msg = e.toString();
    if (msg.contains('SocketException') ||
        msg.contains('Failed host lookup') ||
        msg.contains('Connection refused')) {
      final url = ServerConfigService.instance.serverUrl ?? 'serveur non configuré';
      return 'Impossible de joindre le serveur ($url).';
    }
    if (e is UnauthorizedException || e is ForbiddenException) {
      return 'Email ou mot de passe incorrect';
    }
    return 'Connexion impossible : $msg';
  }
}
