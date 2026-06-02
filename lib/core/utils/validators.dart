/// Input validators
/// Fournit des méthodes de validation réutilisables pour les formulaires
class Validators {
  /// Valide un email - retourne true si valide
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  /// Valide un email - retourne un message d'erreur ou null
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'L\'email est requis';
    }
    if (!isValidEmail(value)) {
      return 'Email invalide';
    }
    return null;
  }

  /// Valide un identifiant (email ou téléphone) - retourne un message d'erreur ou null
  static String? validateIdentifier(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'L\'identifiant (email ou téléphone) est requis';
    }
    final trimmed = value.trim();
    if (trimmed.contains('@')) {
      if (!isValidEmail(trimmed)) {
        return 'Email invalide';
      }
    } else {
      if (!isValidPhone(trimmed) && trimmed.length < 3) {
        return 'Identifiant ou numéro de téléphone invalide';
      }
    }
    return null;
  }

  /// Valide un mot de passe - retourne true si valide
  static bool isValidPassword(String password) {
    return password.length >= 6;
  }

  /// Valide un mot de passe - retourne un message d'erreur ou null
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le mot de passe est requis';
    }
    if (!isValidPassword(value)) {
      return 'Le mot de passe doit contenir au moins 6 caractères';
    }
    return null;
  }

  /// Valide un numéro de téléphone - retourne true si valide
  static bool isValidPhone(String phone) {
    final phoneRegex = RegExp(r'^[+]*[(]{0,1}[0-9]{1,4}[)]{0,1}[-\s\./0-9]*$');
    return phoneRegex.hasMatch(phone);
  }

  /// Valide un numéro de téléphone - retourne un message d'erreur ou null
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le numéro de téléphone est requis';
    }
    if (!isValidPhone(value)) {
      return 'Numéro de téléphone invalide';
    }
    return null;
  }

  /// Valide un champ requis - retourne un message d'erreur ou null
  static String? validateRequired(String? value, {String fieldName = 'Ce champ'}) {
    if (value == null || value.isEmpty) {
      return '$fieldName est requis';
    }
    return null;
  }

  /// Valide un nom - retourne un message d'erreur ou null
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le nom est requis';
    }
    if (value.length < 2) {
      return 'Le nom doit contenir au moins 2 caractères';
    }
    return null;
  }

  /// Valide une note (0-20) - retourne un message d'erreur ou null
  static String? validateGrade(String? value) {
    if (value == null || value.isEmpty) {
      return 'La note est requise';
    }
    final grade = double.tryParse(value);
    if (grade == null) {
      return 'La note doit être un nombre';
    }
    if (grade < 0 || grade > 20) {
      return 'La note doit être entre 0 et 20';
    }
    return null;
  }

  /// Valide un coefficient - retourne un message d'erreur ou null
  static String? validateCoefficient(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le coefficient est requis';
    }
    final coeff = double.tryParse(value);
    if (coeff == null) {
      return 'Le coefficient doit être un nombre';
    }
    if (coeff <= 0) {
      return 'Le coefficient doit être positif';
    }
    return null;
  }
}
