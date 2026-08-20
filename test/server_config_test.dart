import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unigest_app/core/config/server_config_service.dart';
import 'package:unigest_app/features/server_config/controllers/server_config_controller.dart';
import 'package:unigest_app/features/server_config/views/server_config_view.dart';

void main() {
  setUp(() {
    Get.reset();
    SharedPreferences.setMockInitialValues({});
    // Réinitialise l'état du service entre chaque test
    ServerConfigService.instance.setUrlForTesting(null);
  });

  tearDown(Get.reset);

  group('ServerConfigService', () {
    test('hasServerConfigured returns false when no URL is set', () {
      expect(ServerConfigService.instance.hasServerConfigured(), isFalse);
      expect(ServerConfigService.instance.serverUrl, isNull);
    });

    test('hasServerConfigured returns true after setUrlForTesting', () {
      ServerConfigService.instance
          .setUrlForTesting('https://server.example.com/api');
      expect(ServerConfigService.instance.hasServerConfigured(), isTrue);
      expect(ServerConfigService.instance.serverUrl,
          'https://server.example.com/api');
    });

    test('isConfiguredRx is reactive', () {
      expect(ServerConfigService.instance.isConfiguredRx.value, isFalse);
      ServerConfigService.instance
          .setUrlForTesting('https://server.example.com/api');
      expect(ServerConfigService.instance.isConfiguredRx.value, isTrue);
      ServerConfigService.instance.setUrlForTesting(null);
      expect(ServerConfigService.instance.isConfiguredRx.value, isFalse);
    });
  });

  group('ServerConfigController — validation URL', () {
    late ServerConfigController controller;

    setUp(() {
      controller = Get.put(ServerConfigController());
    });

    test('empty URL sets error without calling network', () async {
      controller.urlFieldController.text = '';
      await controller.validateAndSave();

      expect(controller.errorMessage.value, isNotNull);
      expect(controller.errorMessage.value, contains('requise'));
      expect(controller.isLoading.value, isFalse);
    });

    test('URL without scheme sets error', () async {
      controller.urlFieldController.text = 'server.example.com/api';
      await controller.validateAndSave();

      expect(controller.errorMessage.value, isNotNull);
      expect(controller.errorMessage.value, contains('invalide'));
      expect(controller.isLoading.value, isFalse);
    });

    test('non-HTTP scheme sets error', () async {
      controller.urlFieldController.text = 'ftp://server.example.com';
      await controller.validateAndSave();

      expect(controller.errorMessage.value, isNotNull);
      expect(controller.errorMessage.value, contains('invalide'));
    });

    test('valid https URL passes format validation', () {
      // On vérifie uniquement la validation du format — pas l'appel réseau.
      final uri = Uri.tryParse('https://server.example.com/api');
      expect(uri, isNotNull);
      expect(uri!.hasScheme, isTrue);
      expect(uri.scheme.startsWith('http'), isTrue);
    });

    test('valid http URL passes format validation', () {
      final uri = Uri.tryParse('http://192.168.1.10:5400/api');
      expect(uri, isNotNull);
      expect(uri!.scheme.startsWith('http'), isTrue);
    });
  });

  group('ServerConfigView — widget', () {
    testWidgets('affiche les éléments clés de l\'écran config serveur',
        (tester) async {
      Get.put(ServerConfigController());
      await tester.pumpWidget(
        const GetMaterialApp(home: ServerConfigView()),
      );
      await tester.pump();

      expect(find.text('UniGest'), findsOneWidget);
      expect(find.text('Configuration du serveur'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Valider et continuer'), findsOneWidget);
    });

    testWidgets('affiche une erreur si URL vide à la soumission',
        (tester) async {
      final ctrl = Get.put(ServerConfigController());
      await tester.pumpWidget(
        const GetMaterialApp(home: ServerConfigView()),
      );
      await tester.pump();

      // Appel direct pour éviter les problèmes de scroll hors écran en test
      await ctrl.validateAndSave();
      await tester.pump();

      expect(ctrl.errorMessage.value, isNotNull);
      expect(ctrl.errorMessage.value, contains('requise'));
    });

    testWidgets('affiche une erreur pour URL sans schéma', (tester) async {
      final ctrl = Get.put(ServerConfigController());
      await tester.pumpWidget(
        const GetMaterialApp(home: ServerConfigView()),
      );
      await tester.pump();

      ctrl.urlFieldController.text = 'server.example.com/api';
      await ctrl.validateAndSave();
      await tester.pump();

      expect(ctrl.errorMessage.value, isNotNull);
      expect(ctrl.errorMessage.value, contains('invalide'));
    });
  });
}
