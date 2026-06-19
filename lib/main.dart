import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'app.dart';
import 'core/storage/hive_service.dart';
import 'core/session/app_session.dart';
import 'services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialise Hive
  await HiveService.instance.init();
  
  // Restaure la session utilisateur
  await AppSession.instance.restore();
  
  // Ecoute les changements de connectivité
  Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
    if (!results.contains(ConnectivityResult.none)) {
      // Lorsque la connexion revient, synchronise les requêtes en attente
      ApiService.instance.syncQueuedRequests();
    }
  });
  
  runApp(const MyApp());
}
