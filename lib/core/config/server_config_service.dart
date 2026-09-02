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

  /// Construit une URI API sans produire `/api/api` lorsque l'adresse
  /// enregistrée contient déjà le préfixe `/api`.
  Uri resolveApiUri(String endpoint, [Map<String, String>? query]) {
    final configured = _cachedUrl;
    if (configured == null || configured.isEmpty) {
      throw StateError('Aucun serveur configuré.');
    }

    final server = Uri.parse(configured);
    final serverPath = server.path.replaceFirst(RegExp(r'/+$'), '');
    final originPath = serverPath.endsWith('/api')
        ? serverPath.substring(0, serverPath.length - 4)
        : serverPath;
    final endpointPath = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    final apiPath = endpointPath == '/api' || endpointPath.startsWith('/api/')
        ? endpointPath
        : '/api$endpointPath';

    return server.replace(
      path: '$originPath$apiPath'.replaceAll(RegExp(r'/{2,}'), '/'),
      queryParameters: query?.isEmpty == true ? null : query,
      fragment: null,
    );
  }

  /// URI située à la racine du serveur, utile pour Actuator et les sondes.
  Uri resolveServerUri(String path) {
    final configured = _cachedUrl;
    if (configured == null || configured.isEmpty) {
      throw StateError('Aucun serveur configuré.');
    }
    final server = Uri.parse(configured);
    var basePath = server.path.replaceFirst(RegExp(r'/+$'), '');
    if (basePath.endsWith('/api')) {
      basePath = basePath.substring(0, basePath.length - 4);
    }
    final suffix = path.startsWith('/') ? path : '/$path';
    return server.replace(
        path: '$basePath$suffix', query: null, fragment: null);
  }

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
