import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import 'login_view.dart';
import '../../../views/MainLayout.dart';
import '../../../core/session/app_session.dart';
import '../../parent/views/parent_main_view.dart';
import '../../student/views/student_home_view.dart';
import '../../student/controllers/student_home_controller.dart';

/// Affiche login ou l'interface adaptée au rôle selon l'état d'authentification.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.put(AuthController(), permanent: true);

    return Obx(() {
      if (auth.isCheckingSession.value) {
        return const Scaffold(
          backgroundColor: Color(0xFFF8F9FA),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C5CE7)),
                ),
                SizedBox(height: 16),
                Text('Chargement...', style: TextStyle(color: Colors.black54)),
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
