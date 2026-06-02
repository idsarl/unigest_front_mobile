/// Configuration centralisée de l'application
/// Permet de gérer les environnements (dev/prod) facilement
class AppConfig {
  // Environnement
  static const Environment environment = Environment.development;
  
  // Configuration API selon l'environnement
  static String get baseUrl {
    switch (environment) {
      case Environment.development:
        return 'http://localhost:5200/api';
      case Environment.production:
        return 'https://api.unigest.com/api';
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
