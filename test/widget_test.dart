import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unigest_app/app.dart';
import 'package:unigest_app/core/config/server_config_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Premier lancement : affiche l\'écran de configuration serveur',
      (tester) async {
    // Aucun serveur configuré → écran de config
    ServerConfigService.instance.setUrlForTesting(null);

    await tester.pumpWidget(const MyApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Configuration du serveur'), findsOneWidget);
    expect(find.text('Valider et continuer'), findsOneWidget);
  });

  testWidgets('Serveur déjà configuré : affiche le formulaire de connexion',
      (tester) async {
    ServerConfigService.instance
        .setUrlForTesting('https://server.example.com/api');

    await tester.pumpWidget(const MyApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Connexion'), findsWidgets);
    expect(find.byType(EditableText), findsNWidgets(2));

    // Nettoyage
    ServerConfigService.instance.setUrlForTesting(null);
  });
}
