import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import '../core/constants/app_constants.dart';
import '../core/session/app_session.dart';

/// Service HTTP centralisé (GET/POST/PUT/DELETE + JWT).
class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  final String baseUrl = AppConstants.baseUrl;
  final AppSession _session = AppSession.instance;

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

  Future<dynamic> get(String endpoint, {Map<String, String>? query}) async {
    try {
      final response = await http.get(_uri(endpoint, query), headers: _headers());
      return _handleResponse(response);
    } catch (e) {
      throw Exception('GET $endpoint : $e');
    }
  }

  Future<dynamic> post(
    String endpoint, {
    dynamic body,
    Map<String, String>? query,
  }) async {
    try {
      final response = await http.post(
        _uri(endpoint, query),
        headers: _headers(),
        body: body == null ? null : json.encode(body),
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('POST $endpoint : $e');
    }
  }

  Future<dynamic> put(
    String endpoint, {
    dynamic body,
    Map<String, String>? query,
  }) async {
    try {
      final response = await http.put(
        _uri(endpoint, query),
        headers: _headers(),
        body: body == null ? null : json.encode(body),
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('PUT $endpoint : $e');
    }
  }

  Future<dynamic> delete(String endpoint, {Map<String, String>? query}) async {
    try {
      final response = await http.delete(_uri(endpoint, query), headers: _headers());
      return _handleResponse(response);
    } catch (e) {
      throw Exception('DELETE $endpoint : $e');
    }
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode == 204) return null;
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
      print('=== sendMessageWithFiles ===');
      print('DestinataireId: $destinataireId');
      print('Contenu: $contenu');
      print('Files count: ${files.length}');
      for (var file in files) {
        final pathStr = kIsWeb ? 'unavailable on web' : file.path;
        print('File: ${file.name}, bytes: ${file.bytes != null}, path: $pathStr');
      }

      final uri = _uri('/api/messages');
      final request = http.MultipartRequest('POST', uri);

      // Add headers
      final headers = _headers(jsonBody: false);
      request.headers.addAll(headers);
      print('Headers: $headers');

      // Add fields
      request.fields['destinataireId'] = destinataireId.toString();
      if (contenu.isNotEmpty) {
        request.fields['contenu'] = contenu;
      }
      print('Fields: ${request.fields}');

      // Add files - check bytes FIRST (for web compatibility)
      for (var file in files) {
        if (file.bytes != null) {
          print('Adding file with bytes: ${file.name}');
          request.files.add(
            http.MultipartFile.fromBytes(
              'fichiers', // Backend expects "fichiers" (plural)
              file.bytes!,
              filename: file.name,
            ),
          );
        } else if (!kIsWeb && file.path != null) {
          // Only use path on non-web platforms!
          print('Adding file with path: ${file.name}');
          request.files.add(
            await http.MultipartFile.fromPath(
              'fichiers', // Backend expects "fichiers" (plural)
              file.path!,
              filename: file.name,
            ),
          );
        } else {
          print('Warning: Could not add file ${file.name} (no bytes or path available)');
        }
      }
      print('Total files added: ${request.files.length}');

      print('Sending request...');
      final response = await request.send();
      print('Response status: ${response.statusCode}');
      final responseBody = await http.Response.fromStream(response);
      print('Response body: ${responseBody.body}');

      return _handleResponse(responseBody) as Map<String, dynamic>;
    } catch (e) {
      print('Error: $e');
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
}
