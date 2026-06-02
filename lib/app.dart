import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'features/parent/views/parent_main_view.dart';
import 'features/parent/views/child_details_view.dart';
import 'features/parent/controllers/child_details_controller.dart';
import 'features/student/views/student_home_view.dart';
import 'features/student/controllers/student_home_controller.dart';
import 'features/auth/views/login_view.dart';
import 'features/auth/controllers/auth_controller.dart';
import 'core/theme/app_theme.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Unigest',
      theme: AppTheme.lightTheme,
      initialRoute: '/auth',
      initialBinding: BindingsBuilder(() {
        Get.put(AuthController(), permanent: true);
      }),
      debugShowCheckedModeBanner: false,
      getPages: [
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
      ],
    );
  }
}
