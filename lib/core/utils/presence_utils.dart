/// Conversion statuts présence UI ↔ API.
class PresenceUtils {
  static String toApi(String uiStatus) {
    switch (uiStatus) {
      case 'Présent':
        return 'PRESENT';
      case 'En retard':
        return 'RETARD';
      case 'Absent':
        return 'ABSENT';
      default:
        return uiStatus.toUpperCase();
    }
  }

  static String fromApi(String? apiStatus) {
    switch (apiStatus) {
      case 'PRESENT':
        return 'Présent';
      case 'RETARD':
        return 'En retard';
      case 'ABSENT':
        return 'Absent';
      default:
        return 'Présent';
    }
  }

  static String initials(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.length >= 2
          ? parts.first.substring(0, 2).toUpperCase()
          : parts.first.toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  static String fullName(Map<String, dynamic> etudiant) {
    final prenom = etudiant['prenom']?.toString() ?? '';
    final nom = etudiant['nom']?.toString() ?? '';
    return '$prenom $nom'.trim();
  }
}
