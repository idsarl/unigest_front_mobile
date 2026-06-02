import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/parent_home_controller.dart';
import '../controllers/parent_notifications_controller.dart';
import '../controllers/parent_profile_controller.dart';
import 'parent_home_view.dart';
import 'parent_notifications_view.dart';
import 'parent_profile_view.dart';
import '../../../widgets/common/custom_bottom_nav_bar.dart';

class ParentMainView extends StatefulWidget {
  const ParentMainView({super.key});

  @override
  State<ParentMainView> createState() => _ParentMainViewState();
}

class _ParentMainViewState extends State<ParentMainView> {
  final RxInt currentIndex = 0.obs;

  @override
  Widget build(BuildContext context) {
    final homeController = Get.put(ParentHomeController());
    final notificationsController = Get.put(ParentNotificationsController());
    final profileController = Get.put(ParentProfileController());

    return Scaffold(
      body: Obx(() {
        switch (currentIndex.value) {
          case 0:
            return const ParentHomeView();
          case 1:
            return const ParentNotificationsView();
          case 2:
            return const ParentProfileView();
          default:
            return const ParentHomeView();
        }
      }),
      bottomNavigationBar: Obx(() {
        return CustomBottomNavBar(
          currentIndex: currentIndex.value,
          onTap: (index) {
            currentIndex.value = index;
          },
        );
      }),
    );
  }
}
