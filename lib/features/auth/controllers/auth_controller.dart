import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/state_management/getx_helpers.dart';
import '../../../core/services/api_service.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/utils/validators.dart';

class AuthController extends BaseController {
  final RxString email = ''.obs;
  final RxString password = ''.obs;
  final RxBool isPasswordVisible = false.obs;
  final RxnString authError = RxnString();
  final RxString userRole = ''.obs;
  final RxInt userId = 0.obs;
  final RxString userName = ''.obs;
  final RxString userPrenom = ''.obs;

  Future<void> login() async {
    // Validation des champs
    final identifierError = Validators.validateIdentifier(email.value);
    final passwordError = Validators.validatePassword(password.value);
    
    if (identifierError != null) {
      authError.value = identifierError;
      return;
    }
    
    if (passwordError != null) {
      authError.value = passwordError;
      return;
    }

    setLoading(true);
    authError.value = null;

    try {
      final response = await ApiService.post('/auth/login', body: {
        'login': email.value,
        'password': password.value,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];
        final role = data['role'];
        final nom = data['nom'] ?? '';
        final prenom = data['prenom'] ?? '';
        
        // Stocker le token et les infos utilisateur
        ApiService.setToken(token);
        userRole.value = role;
        userName.value = nom;
        userPrenom.value = prenom;

        // Récupérer les infos utilisateur complètes pour obtenir l'ID
        await _fetchUserInfo();

        // Redirection selon le rôle
        if (role == 'PARENT') {
          Get.offAllNamed('/parent-home');
        } else if (role == 'ETUDIANT') {
          Get.offAllNamed('/student-home');
        } else {
          authError.value = 'Rôle non reconnu: $role';
        }
      } else {
        authError.value = 'Email ou mot de passe incorrect';
      }
    } catch (e) {
      final appException = ErrorHandler.handleException(e);
      authError.value = ErrorHandler.getUserMessage(appException);
    } finally {
      setLoading(false);
    }
  }

  Future<void> _fetchUserInfo() async {
    try {
      final response = await ApiService.get('/auth/me');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        userId.value = data['id'] ?? 0;
      }
    } catch (e) {
      // Silencer l'erreur pour ne pas bloquer la connexion
      print('Erreur lors de la récupération des infos utilisateur: $e');
    }
  }

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  void logout() {
    ApiService.clearToken();
    userRole.value = '';
    userId.value = 0;
    userName.value = '';
    userPrenom.value = '';
    Get.offAllNamed('/auth');
  }

  @override
  Future<void> retry() async {
    await login();
  }
}
