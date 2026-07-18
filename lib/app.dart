import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'core/constants/app_constants.dart';
import 'features/appel/controllers/appel_controller.dart';
import 'features/appel/views/appel_view.dart';
import 'features/auth/controllers/auth_controller.dart';
import 'features/auth/views/login_view.dart';
import 'features/note/controllers/note_controller.dart';
import 'features/note/views/note_view.dart';
import 'services/api_service.dart';
import 'services/appel_service.dart';
import 'services/auth_service.dart';
import 'services/connectivity_service.dart';
import 'services/note_service.dart';
import 'views/home_view.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: AppConstants.appName,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      initialBinding: BindingsBuilder(() {
        final api = ApiService();
        Get.put(api, permanent: true);
        Get.put(AuthService(apiService: api), permanent: true);
        Get.put(AuthController(authService: Get.find()), permanent: true);

        // Services partagés disponibles dès le départ
        Get.put(AppelService(api: api), permanent: true);
        Get.put(NoteService(api: api), permanent: true);
        Get.put(ConnectivityService(api: api), permanent: true);
      }),
      initialRoute: AppConstants.loginRoute,
      getPages: [
        GetPage(
          name: AppConstants.loginRoute,
          page: () => const LoginView(),
        ),
        GetPage(
          name: AppConstants.homeRoute,
          page: () => const HomeView(),
        ),
        GetPage(
          name: AppConstants.appelRoute,
          page: () => const AppelView(),
          binding: BindingsBuilder(() {
            if (!Get.isRegistered<AppelController>()) {
              Get.put(AppelController(service: Get.find<AppelService>()));
            }
          }),
        ),
        GetPage(
          name: AppConstants.noteRoute,
          page: () => const NoteListView(),
          binding: BindingsBuilder(() {
            if (!Get.isRegistered<NoteController>()) {
              Get.put(NoteController(
                noteService: Get.find<NoteService>(),
                appelService: Get.find<AppelService>(),
              ));
            }
          }),
        ),
      ],
    );
  }
}
