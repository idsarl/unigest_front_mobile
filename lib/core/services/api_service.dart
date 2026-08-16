import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../utils/error_handler.dart';

class ApiService {
  // Stockage du token JWT
  static String? _token;

  static String? get token => _token;

  static void setToken(String? newToken) {
    _token = newToken;
  }

  static void clearToken() {
    _token = null;
  }

  // Headers par défaut avec authentification
  static Map<String, String> get headers {
    final Map<String, String> defaultHeaders = {
      'Content-Type': 'application/json; charset=UTF-8',
      'Accept': 'application/json',
    };

    if (_token != null) {
      defaultHeaders['Authorization'] = 'Bearer $_token';
    }

    return defaultHeaders;
  }

  static String decodeBody(http.Response response) {
    return utf8.decode(response.bodyBytes);
  }

  static dynamic decodeJson(http.Response response) {
    return jsonDecode(decodeBody(response));
  }

  // Méthode GET avec timeout et gestion d'erreurs
  static Future<http.Response> get(String endpoint) async {
    try {
      final url = Uri.parse('${AppConfig.baseUrl}$endpoint');
      final response = await http
          .get(
        url,
        headers: headers,
      )
          .timeout(
        AppConfig.connectionTimeout,
        onTimeout: () {
          throw ErrorHandler.createTimeoutException();
        },
      );

      return _handleResponse(response);
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }

  // Méthode POST avec timeout et gestion d'erreurs
  static Future<http.Response> post(String endpoint,
      {Map<String, dynamic>? body}) async {
    try {
      final url = Uri.parse('${AppConfig.baseUrl}$endpoint');
      final response = await http
          .post(
        url,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      )
          .timeout(
        AppConfig.connectionTimeout,
        onTimeout: () {
          throw ErrorHandler.createTimeoutException();
        },
      );

      return _handleResponse(response);
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }

  /// Envoie un formulaire multipart. L'API des messages Spring attend ce
  /// format, meme lorsqu'aucun fichier n'est joint.
  static Future<http.Response> postMultipart(
    String endpoint, {
    required Map<String, String> fields,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConfig.baseUrl}$endpoint'),
      );
      request.headers.addAll({
        'Accept': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      });
      request.fields.addAll(fields);

      final streamed = await request.send().timeout(
            AppConfig.connectionTimeout,
            onTimeout: () => throw ErrorHandler.createTimeoutException(),
          );
      final response = await http.Response.fromStream(streamed);
      return _handleResponse(response);
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }

  // Méthode PUT avec timeout et gestion d'erreurs
  static Future<http.Response> put(String endpoint,
      {Map<String, dynamic>? body}) async {
    try {
      final url = Uri.parse('${AppConfig.baseUrl}$endpoint');
      final response = await http
          .put(
        url,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      )
          .timeout(
        AppConfig.connectionTimeout,
        onTimeout: () {
          throw ErrorHandler.createTimeoutException();
        },
      );

      return _handleResponse(response);
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }

  // Méthode DELETE avec timeout et gestion d'erreurs
  static Future<http.Response> delete(String endpoint) async {
    try {
      final url = Uri.parse('${AppConfig.baseUrl}$endpoint');
      final response = await http
          .delete(
        url,
        headers: headers,
      )
          .timeout(
        AppConfig.connectionTimeout,
        onTimeout: () {
          throw ErrorHandler.createTimeoutException();
        },
      );

      return _handleResponse(response);
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }

  // Gestion des réponses HTTP
  static http.Response _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response;
    } else if (response.statusCode == 401) {
      throw ErrorHandler.createUnauthorizedException(body: decodeBody(response));
    } else if (response.statusCode == 403) {
      throw ErrorHandler.createForbiddenException(body: decodeBody(response));
    } else if (response.statusCode == 404) {
      throw ErrorHandler.createNotFoundException(body: decodeBody(response));
    } else if (response.statusCode >= 500) {
      throw ErrorHandler.createServerException(body: decodeBody(response));
    } else {
      throw ErrorHandler.createHttpException(
          response.statusCode, decodeBody(response));
    }
  }
}
