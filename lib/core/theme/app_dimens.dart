/// Échelle d'espacement, de rayons d'angle et de tailles d'icônes commune
/// à toute l'application. Objectif : remplacer les valeurs "magiques"
/// dispersées dans les vues (8, 10, 12, 15, 16, 20...) par un vocabulaire
/// partagé et cohérent.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double s = 8;
  static const double m = 16;
  static const double l = 24;
  static const double xl = 32;
}

class AppRadius {
  AppRadius._();

  /// Petits éléments : chips, badges, champs de saisie.
  static const double s = 8;

  /// Valeur canonique pour les cartes, boutons et conteneurs standards.
  static const double m = 12;

  /// Grands conteneurs (bannières, feuilles modales, en-têtes).
  static const double l = 16;
}

class AppIconSize {
  AppIconSize._();

  /// Icônes inline (dans du texte, badges).
  static const double s = 16;

  /// Taille par défaut (barres d'action, listes).
  static const double m = 24;

  /// Icônes d'illustration dans les cartes/stat.
  static const double l = 32;

  /// Icônes des états vides / erreurs.
  static const double xl = 64;
}
