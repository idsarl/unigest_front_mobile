import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import '../core/db/database_helper.dart';
import 'api_service.dart';

class ConnectivityService extends GetxService {
  final ApiService _api;
  ConnectivityService({required ApiService api}) : _api = api;

  final RxBool isOnline = true.obs;

  StreamSubscription? _sub;

  @override
  void onInit() {
    super.onInit();
    _sub = Connectivity().onConnectivityChanged.listen(_handleChange);
    _checkInitial();
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }

  Future<void> _checkInitial() async {
    final result = await Connectivity().checkConnectivity();
    isOnline.value = _isConnected(result);
  }

  bool _isConnected(dynamic result) {
    if (result is List) {
      return result.any((r) => r != ConnectivityResult.none);
    }
    return result != ConnectivityResult.none;
  }

  void _handleChange(dynamic result) {
    final online = _isConnected(result);
    final wasOffline = !isOnline.value;
    isOnline.value = online;
    if (online && wasOffline) {
      _syncPendingActions();
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
