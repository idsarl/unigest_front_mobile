import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../../../core/config/server_config_service.dart';

class ServerConfigController extends GetxController {
  final TextEditingController urlFieldController = TextEditingController();
  final RxBool isLoading = false.obs;
  final RxnString errorMessage = RxnString();

  @override
  void onClose() {
    urlFieldController.dispose();
    super.onClose();
  }

  Future<void> validateAndSave() async {
    final rawInput = urlFieldController.text.trim();
    errorMessage.value = null;

    if (rawInput.isEmpty) {
      errorMessage.value = 'L\'adresse du serveur est requise';
      return;
    }

    // Auto-prepend https:// if user entered domain only
    String rawUrl;
    if (rawInput.startsWith('http://') || rawInput.startsWith('https://')) {
      rawUrl = rawInput;
    } else {
      rawUrl = 'https://$rawInput';
    }

    final uri = Uri.tryParse(rawUrl);
    if (uri == null || uri.host.isEmpty) {
      errorMessage.value = 'Domaine invalide. Exemple : api.mon-etablissement.com';
      return;
    }

    isLoading.value = true;

    try {
      final normalized = _stripTrailingSlash(rawUrl);
      await _pingServer(normalized);
      await ServerConfigService.instance.saveServerUrl(normalized);
      Get.offAllNamed('/auth');
    } on TimeoutException {
      errorMessage.value =
          'Délai dépassé. Vérifiez que le serveur est accessible.';
    } on SocketException catch (e) {
      errorMessage.value =
          'Impossible de joindre le serveur : ${e.message.isNotEmpty ? e.message : 'hôte introuvable'}';
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('SocketException') ||
          msg.contains('Failed host lookup') ||
          msg.contains('Connection refused')) {
        errorMessage.value =
            'Impossible de joindre le serveur. Vérifiez l\'URL.';
      } else {
        errorMessage.value = 'Erreur inattendue : $msg';
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// Toute réponse HTTP (même 4xx/5xx) confirme que le serveur est joignable.
  /// Seules les erreurs réseau (SocketException, TimeoutException) signalent
  /// une inaccessibilité réelle.
  Future<void> _pingServer(String baseUrl) async {
    try {
      await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 10));
    } on TimeoutException {
      rethrow;
    } on SocketException {
      rethrow;
    } catch (_) {
      // /health n'existe pas ou erreur HTTP : on essaie l'URL de base
      await http
          .get(Uri.parse(baseUrl))
          .timeout(const Duration(seconds: 10));
    }
  }

  String _stripTrailingSlash(String url) {
    var result = url;
    while (result.endsWith('/')) {
      result = result.substring(0, result.length - 1);
    }
    return result;
  }
}
