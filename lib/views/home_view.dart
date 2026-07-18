import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/widgets/offline_banner.dart';
import '../features/dashboard/views/dashboard_view.dart';
import '../features/emploi/views/emploi_view.dart';
import '../features/dashboard/controllers/dashboard_controller.dart';
import '../features/emploi/controllers/emploi_controller.dart';
import '../services/api_service.dart';
import '../services/dashboard_service.dart';
import '../services/emploi_service.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _ensureControllers();
  }

  void _ensureControllers() {
    if (!Get.isRegistered<DashboardService>()) {
      Get.put(DashboardService(api: Get.find<ApiService>()));
    }
    if (!Get.isRegistered<DashboardController>()) {
      Get.put(DashboardController(service: Get.find<DashboardService>()));
    }
    if (!Get.isRegistered<EmploiService>()) {
      Get.put(EmploiService(api: Get.find<ApiService>()));
    }
    if (!Get.isRegistered<EmploiController>()) {
      Get.put(EmploiController(service: Get.find<EmploiService>()));
    }
  }

  static const _tabs = [
    _TabItem(icon: Icons.dashboard, label: 'Accueil'),
    _TabItem(icon: Icons.calendar_month, label: 'Emploi'),
  ];

  final _pages = const [
    DashboardView(),
    EmploiView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: IndexedStack(
              index: _tabIndex,
              children: _pages,
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        destinations: _tabs
            .map((t) => NavigationDestination(
                  icon: Icon(t.icon),
                  label: t.label,
                ))
            .toList(),
      ),
    );
  }
}

class _TabItem {
  final IconData icon;
  final String label;
  const _TabItem({required this.icon, required this.label});
}
