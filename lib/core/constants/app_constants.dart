import 'package:flutter/foundation.dart';

class AppConstants {
  static const String appName = 'unigest_app';

  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5400';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return 'https://api.unigest.com/api';
      // return 'http://192.168.1.29:5400';
    } else {
      return 'http://localhost:5400';
    }
  }

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
