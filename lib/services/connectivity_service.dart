import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';
import '../core/db/database_helper.dart';
import 'api_service.dart';

class ConnectivityService extends GetxService {
  final ApiService _api;
  ConnectivityService({required ApiService api}) : _api = api;

  final RxBool isOnline = true.obs;

  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    _checkInitial();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _poll());
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  Future<void> _checkInitial() async {
    isOnline.value = await _hasInternet();
  }

  Future<void> _poll() async {
    final online = await _hasInternet();
    final wasOffline = !isOnline.value;
    isOnline.value = online;
    if (online && wasOffline) {
      _syncPendingActions();
    }
  }

  Future<bool> _hasInternet() async {
    try {
      final result = await InternetAddress.lookup('8.8.8.8')
          .timeout(const Duration(seconds: 3));
      return result.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> _syncPendingActions() async {
    final pending = await DatabaseHelper.getPendingActions();
    if (pending.isEmpty) return;

    int synced = 0;
    for (final action in pending) {
      try {
        final method = action['method'] as String;
        final endpoint = action['endpoint'] as String;
        final payload = action['payload'] as String?;
        final body = payload != null && payload.isNotEmpty
            ? jsonDecode(payload) as Map<String, dynamic>
            : null;

        switch (method) {
          case 'POST':
            await _api.post(endpoint, body: body);
          case 'PATCH':
            await _api.patch(endpoint, body: body);
          case 'PUT':
            await _api.put(endpoint, body: body);
        }
        await DatabaseHelper.markActionSynced(action['id'] as int);
        synced++;
      } catch (_) {
        // keep in queue for next sync attempt
      }
    }

    if (synced > 0) {
      Get.snackbar(
        'Synchronisation',
        '$synced action(s) synchronisée(s)',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    }
  }
}
