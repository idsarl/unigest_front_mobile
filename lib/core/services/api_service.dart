import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../config/server_config_service.dart';
import '../session/app_session.dart';
import '../utils/error_handler.dart';

class ApiService {
  // Stockage du token JWT
  static String? get token => AppSession.instance.token;

  static void setToken(String? newToken) {
    AppSession.instance.token = newToken;
  }

  static void clearToken() {
    AppSession.instance.token = null;
  }

  // Headers par défaut avec authentification
  static Map<String, String> get headers {
    final Map<String, String> defaultHeaders = {
      'Content-Type': 'application/json; charset=UTF-8',
      'Accept': 'application/json',
    };

    if (token != null && token!.isNotEmpty) {
      defaultHeaders['Authorization'] = 'Bearer $token';
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
      final url = ServerConfigService.instance.resolveApiUri(endpoint);
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
      final url = ServerConfigService.instance.resolveApiUri(endpoint);
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
        ServerConfigService.instance.resolveApiUri(endpoint),
      );
      request.headers.addAll({
        'Accept': 'application/json',
        if (token != null && token!.isNotEmpty)
          'Authorization': 'Bearer $token',
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
      final url = ServerConfigService.instance.resolveApiUri(endpoint);
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
      final url = ServerConfigService.instance.resolveApiUri(endpoint);
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
      throw ErrorHandler.createUnauthorizedException(
          body: decodeBody(response));
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
