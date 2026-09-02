import 'dart:async';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../core/config/server_config_service.dart';
import '../core/session/app_session.dart';
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
    if (!Get.testMode) {
      _timer = Timer.periodic(const Duration(seconds: 30), (_) => _poll());
    }
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  Future<void> _checkInitial() async {
    isOnline.value = await _hasInternet();
  }

  Future<void> checkNow() => _poll();

  Future<void> _poll() async {
    final online = await _hasInternet();
    final wasOffline = !isOnline.value;
    isOnline.value = online;
    if (online && wasOffline && AppSession.instance.isAuthenticated) {
      await _syncPendingActions();
    }
  }

  Future<bool> _hasInternet() async {
    if (!ServerConfigService.instance.hasServerConfigured()) return false;
    try {
      // On sonde le serveur réellement utilisé plutôt qu'un DNS public.
      // Tout statut HTTP confirme que le transport jusqu'à l'API fonctionne.
      await http
          .get(ServerConfigService.instance.resolveApiUri('/auth/me'))
          .timeout(const Duration(seconds: 5));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _syncPendingActions() async {
    try {
      final count = await _api.syncQueuedRequests();
      if (count > 0) {
        Get.snackbar(
          'Synchronisation',
          '$count modification(s) hors ligne synchronisée(s).',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (_) {
      // La file Hive est conservée pour la prochaine reconnexion.
    }
  }
}
