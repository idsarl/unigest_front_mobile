import 'package:flutter/material.dart';

/// Helper functions for MVC pattern
class Helpers {
  /// Formats date to readable string
  static String formatDate(DateTime date) {
      return '${date.day}/${date.month}/${date.year}';
  }

  /// Capitalizes the first letter of a string
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  /// Shows a snackbar message 
  static void showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// Validates email format
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[w-.]+@([w-]+.)+[w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }
}
