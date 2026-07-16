import 'dart:io';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'app.dart';
import 'core/storage/hive_service.dart';
import 'core/session/app_session.dart';
import 'services/api_service.dart' as teacher_api;

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
  await HiveService.instance.init();
  await AppSession.instance.restore();
  Connectivity().onConnectivityChanged.listen((results) {
    if (!results.contains(ConnectivityResult.none)) {
      teacher_api.ApiService.instance.syncQueuedRequests();
    }
  });
  runApp(const MyApp());
}
