import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';

/// Gère la persistance sécurisée de l'URL du serveur backend.
/// Doit être initialisé au démarrage via [init()] avant tout appel réseau.
class ServerConfigService {
  ServerConfigService._();
  static final ServerConfigService instance = ServerConfigService._();

  static const String _serverUrlKey = 'server_url';

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  String? _cachedUrl;
  final RxBool _isConfigured = false.obs;

  /// Observable permettant à l'UI de réagir aux changements de configuration.
  RxBool get isConfiguredRx => _isConfigured;

  /// URL actuellement configurée, ou null si aucun serveur n'est défini.
  String? get serverUrl => _cachedUrl;

  /// À appeler dans main() avant runApp().
  Future<void> init() async {
    try {
      _cachedUrl = await _storage.read(key: _serverUrlKey);
    } catch (e) {
      debugPrint('[ServerConfigService] secure storage read failed: $e');
      _cachedUrl = null;
    }
    _isConfigured.value = _cachedUrl != null && _cachedUrl!.isNotEmpty;
  }

  bool hasServerConfigured() => _cachedUrl != null && _cachedUrl!.isNotEmpty;

  Future<void> saveServerUrl(String url) async {
    final normalized = _normalize(url);
    await _storage.write(key: _serverUrlKey, value: normalized);
    _cachedUrl = normalized;
    _isConfigured.value = true;
  }

  /// Efface la configuration serveur (ex: changement d'organisation).
  Future<void> clearServerUrl() async {
    await _storage.delete(key: _serverUrlKey);
    _cachedUrl = null;
    _isConfigured.value = false;
  }

  /// Positionne directement l'URL en mémoire, sans toucher au stockage.
  /// Réservé aux tests unitaires et d'intégration.
  @visibleForTesting
  void setUrlForTesting(String? url) {
    _cachedUrl = url;
    _isConfigured.value = url != null && url.isNotEmpty;
  }

  String _normalize(String url) {
    var result = url.trim();
    while (result.endsWith('/')) {
      result = result.substring(0, result.length - 1);
    }
    return result;
  }
}
