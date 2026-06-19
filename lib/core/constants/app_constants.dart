/// Application-level constants
class AppConstants {
  /// Application name
  static const String appName = 'unigest_app';

  /// API endpoints
  static const String baseUrl = String.fromEnvironment(
    'UNIGEST_API_BASE_URL',
    defaultValue: 'http://127.0.0.1:5400/api',
  );

  /// Storage keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String themeKey = 'app_theme';

  /// Route names
  static const String loginRoute = '/login';
  static const String homeRoute = '/home';
  static const String splashRoute = '/splash';
}
