import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'parent_view.dart';
import 'shedule_view.dart';
import 'Note_view.dart';
import 'teacher_home_view.dart';
import 'appel_view.dart';
import '../core/session/app_session.dart';
import '../controllers/teacher_home_controller.dart';
import '../controllers/appel_controller.dart';
import '../controllers/note_controller.dart';
import '../controllers/schedule_controller.dart';
import '../controllers/parent_controller.dart';
import 'parent_home_view.dart';
import '../core/theme/app_colors.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;
  final AppSession _session = AppSession.instance;

  bool get isTeacher => _session.role == 'ENSEIGNANT';

  // Liste des pages pour enseignant
  final List<Widget> _teacherPages = [
    const TeacherHomeView(),
    const AppelView(),
    const NoteView(),
    const ScheduleView(),
    const ParentView(),
  ];

  // Liste des pages pour parent
  final List<Widget> _parentPages = [
    const ParentHomeView(),
    const ParentView(),
  ];

  @override
  Widget build(BuildContext context) {
    final pages = isTeacher ? _teacherPages : _parentPages;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: AppColors.divider,
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
            if (isTeacher) {
              if (index == 0) {
                try {
                  if (Get.isRegistered<TeacherHomeController>()) {
                    Get.find<TeacherHomeController>().fetchDashboardData();
                  }
                } catch (_) {}
              } else if (index == 1) {
                try {
                  if (Get.isRegistered<AppelController>()) {
                    Get.find<AppelController>().loadData();
                  }
                } catch (_) {}
              } else if (index == 2) {
                try {
                  if (Get.isRegistered<NoteController>()) {
                    Get.find<NoteController>().loadData();
                  }
                } catch (_) {}
              } else if (index == 3) {
                try {
                  if (Get.isRegistered<ScheduleController>()) {
                    Get.find<ScheduleController>().loadSeances();
                  }
                } catch (_) {}
              } else if (index == 4) {
                try {
                  if (Get.isRegistered<ParentController>()) {
                    Get.find<ParentController>().loadData();
                  }
                } catch (_) {}
              }
            }
          },
          items: isTeacher
              ? const [
                  BottomNavigationBarItem(
                      icon: Icon(Icons.home_outlined),
                      activeIcon: Icon(Icons.home),
                      label: 'Accueil'),
                  BottomNavigationBarItem(
                      icon: Icon(Icons.check_box_outlined), label: 'Appel'),
                  BottomNavigationBarItem(
                      icon: Icon(Icons.insert_chart_outlined), label: 'Notes'),
                  BottomNavigationBarItem(
                      icon: Icon(Icons.calendar_today_outlined),
                      label: 'Emploi'),
                  BottomNavigationBarItem(
                      icon: Icon(Icons.people_outline), label: 'Parents'),
                ]
              : const [
                  BottomNavigationBarItem(
                      icon: Icon(Icons.home_outlined),
                      activeIcon: Icon(Icons.home),
                      label: 'Accueil'),
                  BottomNavigationBarItem(
                      icon: Icon(Icons.chat_outlined), label: 'Messages'),
                ],
        ),
      ),
    );
  }
}
