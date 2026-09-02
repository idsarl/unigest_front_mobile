import 'dart:convert';
import 'dart:io';
import 'dart:async' as async;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import '../core/config/server_config_service.dart';
import '../core/session/app_session.dart';
import '../core/storage/hive_service.dart';
import '../core/utils/error_handler.dart';

/// Service HTTP centralisé avec support hors ligne.
class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  final AppSession _session = AppSession.instance;
  final HiveService _hive = HiveService.instance;

  static const Duration _requestTimeout = Duration(seconds: 30);

  Map<String, String> _headers({bool jsonBody = true}) {
    final headers = <String, String>{
      'Accept': 'application/json',
      if (jsonBody) 'Content-Type': 'application/json',
    };
    final token = _session.token;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Uri _uri(String endpoint, [Map<String, String>? query]) {
    return ServerConfigService.instance.resolveApiUri(endpoint, query);
  }

  bool _isNetworkFailure(Object error) =>
      error is SocketException ||
      error is async.TimeoutException ||
      error is http.ClientException;

  Future<Map<String, dynamic>> _queueMutation(
    String method,
    String endpoint, {
    dynamic body,
    Map<String, String>? query,
  }) async {
    final queuedAt = DateTime.now().toUtc().toIso8601String();
    await _hive.addQueuedRequest({
      'method': method,
      'endpoint': endpoint,
      'body': body,
      'query': query,
      'queuedAt': queuedAt,
    });
    return {
      'success': false,
      'queued': true,
      'queuedAt': queuedAt,
      'message':
          'Modification enregistrée hors ligne, en attente de synchronisation.',
    };
  }

  /// Vide le cache Hive et les requêtes en attente lors d'un changement de serveur.
  Future<void> resetForServerChange() => _hive.clearQueuedRequests();

  String _cacheKey(String endpoint, [Map<String, String>? query]) {
    final queryStr =
        query?.entries.map((e) => '${e.key}=${e.value}').join('&') ?? '';
    return '${_session.teacherId}_${endpoint}_$queryStr';
  }

  Future<dynamic> get(String endpoint,
      {Map<String, String>? query, bool useCache = true}) async {
    final cacheKey = _cacheKey(endpoint, query);

    try {
      final response = await http
          .get(_uri(endpoint, query), headers: _headers())
          .timeout(_requestTimeout);
      final data = _handleResponse(response);
      // Sauvegarde dans le cache (TTL de 1 heure par défaut)
      if (useCache) {
        await _hive.saveCache(cacheKey, data, ttl: const Duration(hours: 1));
      }
      return data;
    } catch (e) {
      if (!_isNetworkFailure(e)) rethrow;
      final cachedData = _hive.getCache(cacheKey);
      if (cachedData != null) {
        return cachedData;
      }
      rethrow;
    }
  }

  Future<dynamic> post(
    String endpoint, {
    dynamic body,
    Map<String, String>? query,
    bool queueIfOffline = true,
  }) async {
    try {
      final response = await http
          .post(
            _uri(endpoint, query),
            headers: _headers(),
            body: body == null ? null : json.encode(body),
          )
          .timeout(_requestTimeout);
      return _handleResponse(response);
    } catch (e) {
      if (queueIfOffline && _isNetworkFailure(e)) {
        return _queueMutation('POST', endpoint, body: body, query: query);
      }
      rethrow;
    }
  }

  Future<dynamic> put(
    String endpoint, {
    dynamic body,
    Map<String, String>? query,
    bool queueIfOffline = true,
  }) async {
    try {
      final response = await http
          .put(
            _uri(endpoint, query),
            headers: _headers(),
            body: body == null ? null : json.encode(body),
          )
          .timeout(_requestTimeout);
      return _handleResponse(response);
    } catch (e) {
      if (queueIfOffline && _isNetworkFailure(e)) {
        return _queueMutation('PUT', endpoint, body: body, query: query);
      }
      rethrow;
    }
  }

  Future<dynamic> patch(
    String endpoint, {
    dynamic body,
    Map<String, String>? query,
    bool queueIfOffline = true,
  }) async {
    try {
      final response = await http
          .patch(
            _uri(endpoint, query),
            headers: _headers(),
            body: body == null ? null : json.encode(body),
          )
          .timeout(_requestTimeout);
      return _handleResponse(response);
    } catch (e) {
      if (queueIfOffline && _isNetworkFailure(e)) {
        return _queueMutation('PATCH', endpoint, body: body, query: query);
      }
      rethrow;
    }
  }

  Future<dynamic> delete(String endpoint,
      {Map<String, String>? query, bool queueIfOffline = true}) async {
    try {
      final response = await http
          .delete(_uri(endpoint, query), headers: _headers())
          .timeout(_requestTimeout);
      return _handleResponse(response);
    } catch (e) {
      if (queueIfOffline && _isNetworkFailure(e)) {
        return _queueMutation('DELETE', endpoint, query: query);
      }
      rethrow;
    }
  }

  /// Synchronise les requêtes en attente
  Future<int> syncQueuedRequests() async {
    final requests = _hive.getQueuedRequests();
    var syncedCount = 0;
    for (final req in requests) {
      try {
        final method = req['method'] as String;
        final endpoint = req['endpoint'] as String;
        final body = req['body'];
        final query = req['query'] as Map<String, dynamic>?;
        final queryParams = query?.map((k, v) => MapEntry(k, v.toString()));

        switch (method) {
          case 'POST':
            await post(endpoint,
                body: body, query: queryParams, queueIfOffline: false);
            break;
          case 'PUT':
            await put(endpoint,
                body: body, query: queryParams, queueIfOffline: false);
            break;
          case 'PATCH':
            await patch(endpoint,
                body: body, query: queryParams, queueIfOffline: false);
            break;
          case 'DELETE':
            await delete(endpoint, query: queryParams, queueIfOffline: false);
            break;
        }
        // Supprime la requête de la file une fois traitée
        await _hive.removeQueuedRequest(req['id'] as String);
        syncedCount++;
      } catch (e) {
        // Une requête définitivement invalide ne doit pas bloquer la file.
        if (e is UnauthorizedException ||
            e is ForbiddenException ||
            (e is AppException &&
                e.statusCode != null &&
                e.statusCode! >= 400 &&
                e.statusCode! < 500 &&
                e.statusCode != 408 &&
                e.statusCode != 429)) {
          await _hive.removeQueuedRequest(req['id'] as String);
        }
        if (_isNetworkFailure(e)) break;
      }
    }
    return syncedCount;
  }

  /// Vide la file des requêtes en attente (à appeler à la connexion/déconnexion)
  Future<void> clearQueuedRequests() => _hive.clearQueuedRequests();

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode == 204) return {};
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      return json.decode(utf8.decode(response.bodyBytes));
    }
    final body = utf8.decode(response.bodyBytes);
    switch (response.statusCode) {
      case 401:
        throw ErrorHandler.createUnauthorizedException(body: body);
      case 403:
        throw ErrorHandler.createForbiddenException(body: body);
      case 404:
        throw ErrorHandler.createNotFoundException(body: body);
      default:
        if (response.statusCode >= 500) {
          throw ErrorHandler.createServerException(body: body);
        }
        throw ErrorHandler.createHttpException(response.statusCode, body);
    }
  }

  Future<Map<String, dynamic>> sendMessageWithFiles(
    int destinataireId,
    String contenu,
    List<PlatformFile> files,
  ) async {
    try {
      final uri = _uri('/api/messages');
      final request = http.MultipartRequest('POST', uri);

      final headers = _headers(jsonBody: false);
      request.headers.addAll(headers);

      request.fields['destinataireId'] = destinataireId.toString();
      if (contenu.isNotEmpty) {
        request.fields['contenu'] = contenu;
      }

      for (var file in files) {
        if (file.bytes != null) {
          request.files.add(
            http.MultipartFile.fromBytes(
              'fichiers',
              file.bytes!,
              filename: file.name,
            ),
          );
        } else if (!kIsWeb && file.path != null) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'fichiers',
              file.path!,
              filename: file.name,
            ),
          );
        }
      }

      final response = await request.send();
      final responseBody = await http.Response.fromStream(response);

      return _handleResponse(responseBody) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Send message with files: $e');
    }
  }

  Future<void> downloadFile(String url, String savePath) async {
    try {
      final response = await http
          .get(
            Uri.parse(url),
            headers: _headers(jsonBody: false),
          )
          .timeout(_requestTimeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final file = File(savePath);
        await file.writeAsBytes(response.bodyBytes);
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Download file: $e');
    }
  }
}
