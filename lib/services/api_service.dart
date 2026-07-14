import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../core/constants/app_constants.dart';
import '../core/session/app_session.dart';
import '../core/storage/hive_service.dart';
import '../models/child_model.dart';
import '../models/note_model.dart';
import '../models/absence_model.dart';
import '../models/emploi_model.dart';
import '../core/config/app_config.dart';

/// Service HTTP centralisé avec support hors ligne.
class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  final String baseUrl = AppConstants.baseUrl;
  final AppSession _session = AppSession.instance;
  final HiveService _hive = HiveService.instance;
  final Connectivity _connectivity = Connectivity();

  Future<bool> get isConnected async {
    final results = await _connectivity.checkConnectivity();
    return !results.contains(ConnectivityResult.none);
  }

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
    final path = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    return Uri.parse('$baseUrl$path').replace(queryParameters: query);
  }

  String _cacheKey(String endpoint, [Map<String, String>? query]) {
    final queryStr = query?.entries.map((e) => '${e.key}=${e.value}').join('&') ?? '';
    return '${_session.teacherId}_${endpoint}_$queryStr';
  }

  Future<dynamic> get(String endpoint, {Map<String, String>? query, bool useCache = true}) async {
    final cacheKey = _cacheKey(endpoint, query);
    
    // Vérifie la connexion
    final hasConnection = await isConnected;

    if (!hasConnection) {
      // Hors ligne : essaye de récupérer depuis le cache
      final cachedData = _hive.getCache(cacheKey);
      if (cachedData != null) {
        return cachedData;
      }
      throw Exception('Pas de connexion et pas de données en cache');
    }

    try {
      final response = await http.get(_uri(endpoint, query), headers: _headers());
      final data = _handleResponse(response);
      // Sauvegarde dans le cache (TTL de 1 heure par défaut)
      if (useCache) {
        await _hive.saveCache(cacheKey, data, ttl: const Duration(hours: 1));
      }
      return data;
    } catch (e) {
      // Si erreur réseau, essaye le cache
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
    final hasConnection = await isConnected;

    if (!hasConnection && queueIfOffline) {
      // Ajoute à la file d'attente
      await _hive.addQueuedRequest({
        'method': 'POST',
        'endpoint': endpoint,
        'body': body,
        'query': query,
      });
      // Retourne une réponse simulée pour que l'UI continue
      return {'success': true, 'queued': true};
    }

    try {
      final response = await http.post(
        _uri(endpoint, query),
        headers: _headers(),
        body: body == null ? null : json.encode(body),
      );
      return _handleResponse(response);
    } catch (e) {
      // Si erreur réseau, ajoute à la file d'attente
      if (queueIfOffline) {
        await _hive.addQueuedRequest({
          'method': 'POST',
          'endpoint': endpoint,
          'body': body,
          'query': query,
        });
        return {'success': true, 'queued': true};
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
    final hasConnection = await isConnected;

    if (!hasConnection && queueIfOffline) {
      await _hive.addQueuedRequest({
        'method': 'PUT',
        'endpoint': endpoint,
        'body': body,
        'query': query,
      });
      return {'success': true, 'queued': true};
    }

    try {
      final response = await http.put(
        _uri(endpoint, query),
        headers: _headers(),
        body: body == null ? null : json.encode(body),
      );
      return _handleResponse(response);
    } catch (e) {
      if (queueIfOffline) {
        await _hive.addQueuedRequest({
          'method': 'PUT',
          'endpoint': endpoint,
          'body': body,
          'query': query,
        });
        return {'success': true, 'queued': true};
      }
      rethrow;
    }
  }

  Future<dynamic> delete(String endpoint, {Map<String, String>? query, bool queueIfOffline = true}) async {
    final hasConnection = await isConnected;

    if (!hasConnection && queueIfOffline) {
      await _hive.addQueuedRequest({
        'method': 'DELETE',
        'endpoint': endpoint,
        'query': query,
      });
      return {'success': true, 'queued': true};
    }

    try {
      final response = await http.delete(_uri(endpoint, query), headers: _headers());
      return _handleResponse(response);
    } catch (e) {
      if (queueIfOffline) {
        await _hive.addQueuedRequest({
          'method': 'DELETE',
          'endpoint': endpoint,
          'query': query,
        });
        return {'success': true, 'queued': true};
      }
      rethrow;
    }
  }

  /// Synchronise les requêtes en attente
  Future<void> syncQueuedRequests() async {
    final hasConnection = await isConnected;
    if (!hasConnection) return;

    final requests = _hive.getQueuedRequests();
    for (final req in requests) {
      try {
        final method = req['method'] as String;
        final endpoint = req['endpoint'] as String;
        final body = req['body'];
        final query = req['query'] as Map<String, dynamic>?;
        final queryParams = query?.map((k, v) => MapEntry(k, v.toString()));

        switch (method) {
          case 'POST':
            await post(endpoint, body: body, query: queryParams, queueIfOffline: false);
            break;
          case 'PUT':
            await put(endpoint, body: body, query: queryParams, queueIfOffline: false);
            break;
          case 'DELETE':
            await delete(endpoint, query: queryParams, queueIfOffline: false);
            break;
        }
        // Supprime la requête de la file une fois traitée
        await _hive.removeQueuedRequest(req['id'] as String);
      } catch (e) {
        print('Erreur synchronisation requête ${req['id']}: $e');
        // On continue avec la prochaine requête
      }
    }
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode == 204) return {};
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      return json.decode(utf8.decode(response.bodyBytes));
    }
    throw Exception('HTTP ${response.statusCode}: ${response.body}');
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
      final response = await http.get(
        Uri.parse(url),
        headers: _headers(jsonBody: false),
      );

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

  // --- Méthodes statiques de la branche entrante ---
  static String get staticBaseUrl => AppConfig.baseUrl;

  static Future<List<ChildModel>> getChildren(String parentId) async {
    try {
      final response = await http.get(
        Uri.parse('$staticBaseUrl/parents/$parentId/children'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => ChildModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load children');
      }
    } catch (e) {
      throw Exception('Error fetching children: $e');
    }
  }

  static Future<List<NoteModel>> getNotes(String childId) async {
    try {
      final response = await http.get(
        Uri.parse('$staticBaseUrl/children/$childId/notes'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => NoteModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load notes');
      }
    } catch (e) {
      throw Exception('Error fetching notes: $e');
    }
  }

  static Future<List<AbsenceModel>> getAbsences(String childId) async {
    try {
      final response = await http.get(
        Uri.parse('$staticBaseUrl/children/$childId/absences'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => AbsenceModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load absences');
      }
    } catch (e) {
      throw Exception('Error fetching absences: $e');
    }
  }

  static Future<List<EmploiModel>> getEmploiDuTemps(String childId) async {
    try {
      final response = await http.get(
        Uri.parse('$staticBaseUrl/children/$childId/emploi'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => EmploiModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load emploi du temps');
      }
    } catch (e) {
      throw Exception('Error fetching emploi du temps: $e');
    }
  }
}
