import 'package:flutter/material.dart';

/// Application theme configuration
class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    primarySwatch: Colors.blue,
    brightness: Brightness.light,
    useMaterial3: true,
    fontFamily: 'Roboto',
  );

  static final ThemeData darkTheme = ThemeData(
    primarySwatch: Colors.blue,
    brightness: Brightness.dark,
    useMaterial3: true,
    fontFamily: 'Roboto',
  );
}
