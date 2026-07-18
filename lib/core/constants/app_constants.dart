class AppConstants {
  static const String appName = 'UniGest';

  // Android emulator → http://10.0.2.2:5400
  // iOS simulator / macOS → http://localhost:5400
  // Appareil réel → IP locale de la machine, ex. http://192.168.1.x:5400
  static const String baseUrl = 'http://192.168.1.22:5400';
  // static const String baseUrl = 'http://localhost:5400';

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
