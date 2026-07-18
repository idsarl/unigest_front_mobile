import 'package:get/get.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/user.dart';
import '../../../services/auth_service.dart';

class AuthController extends GetxController {
  final AuthService authService;

  AuthController({required this.authService});

  final RxBool _isLoading = false.obs;
  bool get isLoading => _isLoading.value;

  final RxnString _error = RxnString();
  String? get error => _error.value;

  final Rx<User?> _user = Rx<User?>(null);
  User? get user => _user.value;
  bool get isAuthenticated => _user.value != null;

  @override
  void onInit() {
    super.onInit();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    if (await authService.isLoggedIn()) {
      _user.value = await authService.getSavedUser();
      if (_user.value != null) {
        Get.offAllNamed(AppConstants.homeRoute);
      }
    }
  }

  Future<void> login(String login, String password) async {
    _isLoading.value = true;
    _error.value = null;

    try {
      _user.value = await authService.login(login, password);
      Get.offAllNamed(AppConstants.homeRoute);
    } catch (e) {
      _error.value = e.toString();
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> logout() async {
    await authService.logout();
    _user.value = null;
    Get.offAllNamed(AppConstants.loginRoute);
  }
}
