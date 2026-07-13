import 'package:flutter/foundation.dart';

/// Application-level constants
class AppConstants {
  /// Application name
  static const String appName = 'unigest_app';

  /// URL du backend Spring local
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5400';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5400'; // IP spéciale pour accéder à l'hôte local depuis l'émulateur Android
    } else {
      return 'http://localhost:5400';
    }
  }
  
  /// Storage keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String themeKey = 'app_theme';
  
  /// Route names
  static const String loginRoute = '/login';
  static const String homeRoute = '/home';
  static const String splashRoute = '/splash';
}
