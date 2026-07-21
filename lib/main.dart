import 'dart:io';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'app.dart';
import 'core/storage/hive_service.dart';
import 'core/session/app_session.dart';
import 'services/api_service.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}



Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();

  // Initialise Hive
  await HiveService.instance.init();

  // Restaure la session utilisateur
  await AppSession.instance.restore();

  // Ecoute les changements de connectivité
  Connectivity().onConnectivityChanged.listen((dynamic result) {
    final connected = result is List
        ? !result.contains(ConnectivityResult.none)
        : result != ConnectivityResult.none;
    if (connected) {
      ApiService.instance.syncQueuedRequests();
    }
  });

  runApp(const MyApp());
}
