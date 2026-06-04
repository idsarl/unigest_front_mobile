import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import 'login_view.dart';
import '../../../views/MainLayout.dart';

/// Affiche login ou app selon l'état d'authentification.
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
        return const MainLayout();
      }

      return const LoginView();
    });
  }
}
