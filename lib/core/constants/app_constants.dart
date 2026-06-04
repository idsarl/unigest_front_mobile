import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

/// Application-level constants
class AppConstants {
  /// Application name
  static const String appName = 'unigest_app';

  /// URL du backend Spring (port 5200).
  /// Android émulateur : 10.0.2.2 | Windows/Web/iOS simulateur : localhost
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:5200';
    if (Platform.isAndroid) return 'http://10.0.2.2:5200';
    return 'http://localhost:5200';
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
