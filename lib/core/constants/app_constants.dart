/// Application-level constants
class AppConstants {
  /// Application name
  static const String appName = 'unigest_app';

  /// URL du backend Spring en ligne, utilisée par le module enseignant
  /// (notes, appels, emploi du temps, messagerie/websocket).
  static const String baseUrl = 'https://api.lyuni-gest.com';


  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String themeKey = 'app_theme';

  static const String loginRoute = '/login';
  static const String homeRoute = '/home';
  static const String splashRoute = '/splash';

  static const String appelRoute = '/appel';
  static const String noteRoute = '/notes';
  static const String emploiRoute = '/emploi';
  static const String affectationsRoute = '/affectations';
  static const String seancesRoute = '/seances';
}
