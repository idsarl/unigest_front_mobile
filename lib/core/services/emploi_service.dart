import 'api_service.dart';
import '../utils/error_handler.dart';
import '../../../models/emploi_model.dart';

class EmploiService {
  // Récupérer l'emploi du temps de la classe d'un étudiant
  static Future<List<EmploiModel>> getEmploiDuTemps(
    String className,
    int studentId, {
    int? classId,
  }) async {
    try {
      final List<dynamic> data = await _loadRawSchedule(classId);

      List<EmploiModel> list = [];
      for (var json in data) {
        final affectation = json['affectation'] ?? {};
        final classe = json['classe'] ?? affectation['classe'] ?? {};
        final enseignant =
            json['enseignant'] ?? affectation['enseignant'] ?? {};
        final matiere = json['matiere'];

        // Filtrer par le nom de la classe de l'étudiant
        final sameClass = classId != null && classId > 0
            ? classe['id']?.toString() == classId.toString()
            : classe['nom']?.toString().toLowerCase() ==
                className.toLowerCase();

        if (sameClass) {
          final days = _extractDays(json);

          final teacherName = enseignant['nom'] != null
              ? '${enseignant['prenom'] ?? ''} ${enseignant['nom']}'
              : 'Enseignant';

          for (final dayOfWeek in days) {
            list.add(EmploiModel(
              id: json['id']?.toString() ?? '',
              childId: studentId.toString(),
              dayOfWeek: dayOfWeek,
              startTime: _formatTime(json['heureDebut']),
              endTime: _formatTime(json['heureFin']),
              subject: matiere is Map<String, dynamic>
                  ? matiere['nom']?.toString() ?? 'Cours'
                  : matiere?.toString() ?? 'Cours',
              teacher: teacherName,
              // Le backend ne possede pas encore de champ "salle" dedie.
              // Ne pas inventer une valeur : utiliser celle de l'API si elle
              // existe, sinon laisser le champ vide.
              classroom: json['salle']?.toString() ?? '',
              type: json['type']?.toString().toLowerCase() ?? 'cours',
            ));
          }
        }
      }

      return list;
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }

  static Future<List<dynamic>> _loadRawSchedule(int? classId) async {
    if (classId != null && classId > 0) {
      final emploiResponse =
          await ApiService.get('/emplois-du-temps/classe/$classId');
      final emploiData = ApiService.decodeJson(emploiResponse);
      if (emploiData is List && emploiData.isNotEmpty) {
        return emploiData;
      }
    }

    final seancesResponse = await ApiService.get('/seances');
    final seancesData = ApiService.decodeJson(seancesResponse);
    return seancesData is List ? seancesData : [];
  }

  static List<String> _extractDays(Map<String, dynamic> json) {
    final jours = json['jours'];
    if (jours is List && jours.isNotEmpty) {
      return jours.map((jour) => _formatDay(jour.toString())).toList();
    }

    return [_getDayOfWeek(json['date']?.toString() ?? '')];
  }

  static String _formatDay(String value) {
    final lower = value.toLowerCase();
    return lower.isEmpty
        ? 'Lundi'
        : '${lower[0].toUpperCase()}${lower.substring(1)}';
  }

  static String _getDayOfWeek(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      switch (date.weekday) {
        case 1:
          return 'Lundi';
        case 2:
          return 'Mardi';
        case 3:
          return 'Mercredi';
        case 4:
          return 'Jeudi';
        case 5:
          return 'Vendredi';
        case 6:
          return 'Samedi';
        case 7:
          return 'Dimanche';
        default:
          return 'Lundi';
      }
    } catch (_) {
      return 'Lundi';
    }
  }

  static String _formatTime(dynamic timeVal) {
    if (timeVal == null) return '08:00';
    final str = timeVal.toString();
    if (str.length >= 5) {
      return str.substring(0, 5); // "08:00:00" -> "08:00"
    }
    return str;
  }
}
