import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/connectivity_service.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<ConnectivityService>()) {
      return const SizedBox.shrink();
    }
    final svc = Get.find<ConnectivityService>();
    return Obx(() {
      if (svc.isOnline.value) return const SizedBox.shrink();
      return const Material(
        color: Color(0xFFEF6C00),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 6, horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.wifi_off, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Mode hors-ligne — les modifications seront synchronisées à la reconnexion',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
