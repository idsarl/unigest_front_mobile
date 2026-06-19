import 'package:flutter/foundation.dart';

/// Configuration centralisée de l'application
/// Permet de gérer les environnements (dev/prod) facilement
class AppConfig {
  // Environnement
  static const Environment environment = Environment.development;
  static const int _devApiPort = 5400;

  // Configuration API selon l'environnement
  static String get baseUrl {
    switch (environment) {
      case Environment.development:
        return 'http://$_devApiHost:$_devApiPort/api';
      case Environment.production:
        return 'https://api.unigest.com/api';
    }
  }

  static String get _devApiHost {
    if (kIsWeb) return 'localhost';

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return '10.0.2.2';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return '127.0.0.1';
      case TargetPlatform.fuchsia:
        return 'localhost';
    }
  }

  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  // Configuration JWT
  static const Duration tokenExpiration = Duration(hours: 24);
  static const Duration tokenRefreshThreshold = Duration(hours: 1);

  // Pagination
  static const int defaultPageSize = 20;

  // Cache
  static const Duration cacheDuration = Duration(hours: 1);
}

enum Environment {
  development,
  production,
}
