import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import 'login_view.dart';
import '../../../views/MainLayout.dart';
import '../../../core/session/app_session.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../parent/views/parent_main_view.dart';
import '../../student/views/student_home_view.dart';
import '../../student/controllers/student_home_controller.dart';
import '../../server_config/views/server_config_view.dart';
import '../../../core/config/server_config_service.dart';

/// Affiche login ou l'interface adaptée au rôle selon l'état d'authentification.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.put(AuthController(), permanent: true);

    return Obx(() {
      if (!ServerConfigService.instance.isConfiguredRx.value) {
        return const ServerConfigView();
      }

      if (auth.isCheckingSession.value) {
        return const Scaffold(
          backgroundColor: AppColors.background,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
                SizedBox(height: 16),
                Text('Chargement...', style: AppTextStyles.bodySecondary),
              ],
            ),
          ),
        );
      }

      if (auth.isAuthenticated.value) {
        final role = AppSession.instance.role.toUpperCase();
        if (role == 'PARENT') {
          return const ParentMainView();
        }
        if (role == 'ETUDIANT' || role == 'ELEVE' || role == 'STUDENT') {
          if (!Get.isRegistered<StudentHomeController>()) {
            Get.lazyPut(() => StudentHomeController());
          }
          return const StudentHomeView();
        }
        return const MainLayout();
      }

      return const LoginView();
    });
  }
}
