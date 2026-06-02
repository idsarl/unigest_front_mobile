import 'dart:convert';
import 'api_service.dart';
import '../utils/error_handler.dart';
import '../../../models/emploi_model.dart';

class EmploiService {
  // Récupérer l'emploi du temps de la classe d'un étudiant
  static Future<List<EmploiModel>> getEmploiDuTemps(String className, int studentId) async {
    try {
      final response = await ApiService.get('/seances');
      final List<dynamic> data = jsonDecode(response.body);
      
      List<EmploiModel> list = [];
      for (var json in data) {
        final affectation = json['affectation'] ?? {};
        final classe = affectation['classe'] ?? {};
        final enseignant = affectation['enseignant'] ?? {};
        
        // Filtrer par le nom de la classe de l'étudiant
        if (classe['nom']?.toString().toLowerCase() == className.toLowerCase()) {
          final dateStr = json['date'] ?? '';
          final dayOfWeek = _getDayOfWeek(dateStr);
          
          final teacherName = enseignant['nom'] != null 
              ? '${enseignant['prenom'] ?? ''} ${enseignant['nom']}' 
              : 'Enseignant';
          
          list.add(EmploiModel(
            id: json['id']?.toString() ?? '',
            childId: studentId.toString(),
            dayOfWeek: dayOfWeek,
            startTime: _formatTime(json['heureDebut']),
            endTime: _formatTime(json['heureFin']),
            subject: json['matiere'] ?? 'Cours',
            teacher: teacherName,
            classroom: 'Salle 102', // Valeur par défaut
            type: 'cours',
          ));
        }
      }
      
      return list;
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }

  static String _getDayOfWeek(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      switch (date.weekday) {
        case 1: return 'Lundi';
        case 2: return 'Mardi';
        case 3: return 'Mercredi';
        case 4: return 'Jeudi';
        case 5: return 'Vendredi';
        case 6: return 'Samedi';
        case 7: return 'Dimanche';
        default: return 'Lundi';
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
