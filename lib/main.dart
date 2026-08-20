import 'dart:io';
import 'package:flutter/material.dart';
import 'app.dart';
import 'core/config/server_config_service.dart';
import 'core/storage/hive_service.dart';
import 'core/session/app_session.dart';

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

  try {
    await HiveService.instance.init();
  } catch (e) {
    debugPrint('[main] HiveService.init failed: $e');
  }

  try {
    await ServerConfigService.instance.init();
  } catch (e) {
    debugPrint('[main] ServerConfigService.init failed: $e');
  }

  try {
    await AppSession.instance.restore();
  } catch (e) {
    debugPrint('[main] AppSession.restore failed: $e');
  }

  runApp(const MyApp());
}
