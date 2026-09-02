import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../../../core/config/server_config_service.dart';
import '../../../services/connectivity_service.dart';

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

    if (rawInput.contains('://') &&
        !rawInput.startsWith('http://') &&
        !rawInput.startsWith('https://')) {
      errorMessage.value =
          'Domaine invalide. Seules les adresses HTTP(S) sont acceptées.';
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
    if (uri == null ||
        uri.host.isEmpty ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      errorMessage.value =
          'Domaine invalide. Exemple : api.mon-etablissement.com';
      return;
    }

    if (uri.scheme == 'http' && !_isLocalAddress(uri.host)) {
      errorMessage.value =
          'HTTPS est obligatoire, sauf pour un serveur local de développement.';
      return;
    }

    isLoading.value = true;

    try {
      final normalized = _stripTrailingSlash(rawUrl);
      await _pingServer(normalized);
      await ServerConfigService.instance.saveServerUrl(normalized);
      if (Get.isRegistered<ConnectivityService>()) {
        await Get.find<ConnectivityService>().checkNow();
      }
      if (!Get.testMode) {
        Get.offAllNamed('/auth');
      }
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

  Future<void> _pingServer(String baseUrl) async {
    final uri = Uri.parse(baseUrl);
    var rootPath = uri.path.replaceFirst(RegExp(r'/+$'), '');
    if (rootPath.endsWith('/api')) {
      rootPath = rootPath.substring(0, rootPath.length - 4);
    }
    final healthUri = uri.replace(path: '$rootPath/actuator/health');
    final response =
        await http.get(healthUri).timeout(const Duration(seconds: 10));
    // Une réponse HTTP prouve la connectivité. On rejette néanmoins un proxy
    // ou domaine inexistant qui répondrait par une page 404 générique.
    if (response.statusCode == 404) {
      final apiProbe = uri.replace(path: '$rootPath/api/auth/me');
      await http.get(apiProbe).timeout(const Duration(seconds: 10));
    }
  }

  bool _isLocalAddress(String host) {
    final normalized = host.toLowerCase();
    if (normalized == 'localhost' ||
        normalized == '127.0.0.1' ||
        normalized == '::1') {
      return true;
    }
    final parts = normalized.split('.').map(int.tryParse).toList();
    if (parts.length != 4 || parts.any((part) => part == null)) return false;
    final first = parts[0]!;
    final second = parts[1]!;
    return first == 10 ||
        first == 127 ||
        (first == 192 && second == 168) ||
        (first == 172 && second >= 16 && second <= 31);
  }

  String _stripTrailingSlash(String url) {
    var result = url;
    while (result.endsWith('/')) {
      result = result.substring(0, result.length - 1);
    }
    return result;
  }
}
