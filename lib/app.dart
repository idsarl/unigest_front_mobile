import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:unigest_app/features/auth/views/auth_wrapper.dart';
import 'features/parent/views/parent_main_view.dart';
import 'features/parent/views/child_details_view.dart';
import 'features/parent/controllers/child_details_controller.dart';
import 'features/server_config/views/server_config_view.dart';
import 'features/server_config/controllers/server_config_controller.dart';
import 'features/student/views/student_home_view.dart';
import 'features/student/controllers/student_home_controller.dart';
import 'features/auth/views/login_view.dart';
import 'core/theme/app_theme.dart';
import 'views/MainLayout.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'UniGest',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,

      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr', 'FR'),
      ],
      locale: const Locale('fr', 'FR'),

      home: const AuthWrapper(),
      getPages: [
        GetPage(
          name: '/server-config',
          page: () => const ServerConfigView(),
          binding: BindingsBuilder(() {
            Get.lazyPut(() => ServerConfigController());
          }),
        ),
        GetPage(
          name: '/auth',
          page: () => const LoginView(),
        ),
        GetPage(
          name: '/parent-home',
          page: () => const ParentMainView(),
        ),
        GetPage(
          name: '/child-details',
          page: () => const ChildDetailsView(),
          binding: BindingsBuilder(() {
            Get.lazyPut(() => ChildDetailsController());
          }),
        ),
        GetPage(
          name: '/student-home',
          page: () => const StudentHomeView(),
          binding: BindingsBuilder(() {
            Get.lazyPut(() => StudentHomeController());
          }),
        ),
        GetPage(
          name: '/teacher-home',
          page: () => const MainLayout(),
        ),
      ],
    );
  }
}
