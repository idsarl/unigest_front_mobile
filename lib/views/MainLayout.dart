import 'package:flutter/material.dart';
import 'package:unigest_app/views/parent_view.dart';
import 'package:unigest_app/views/shedule_view.dart';
import 'Note_view.dart';
import 'teacher_home_view.dart';
import 'appel_view.dart';
import '../core/session/app_session.dart';
import 'parent_home_view.dart';

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
      backgroundColor: const Color(0xFFF8F9FA),
      body: pages[_currentIndex],

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: Colors.grey.shade300,
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          selectedItemColor: const Color(0xFF6C5CE7),
          unselectedItemColor: Colors.grey,
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: isTeacher
              ? const [
                  BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Accueil'),
                  BottomNavigationBarItem(icon: Icon(Icons.check_box_outlined), label: 'Appel'),
                  BottomNavigationBarItem(icon: Icon(Icons.insert_chart_outlined), label: 'Notes'),
                  BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), label: 'Emploi'),
                  BottomNavigationBarItem(icon: Icon(Icons.people_outline), label: 'Parents'),
                ]
              : const [
                  BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Accueil'),
                  BottomNavigationBarItem(icon: Icon(Icons.chat_outlined), label: 'Messages'),
                ],
        ),
      ),
    );
  }
}