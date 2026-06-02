import 'dart:convert';
import 'api_service.dart';
import '../utils/error_handler.dart';
import '../../../models/absence_model.dart';

class AbsencesService {
  // Récupérer les appels (absences et retards) d'un étudiant
  static Future<List<AbsenceModel>> getAbsencesByStudentId(int studentId) async {
    try {
      final response = await ApiService.get('/appels/etudiant/$studentId');
      final List<dynamic> data = jsonDecode(response.body);
      
      // On ne garde que les absences et les retards
      List<AbsenceModel> absences = [];
      for (var json in data) {
        final statut = json['statut']?.toString() ?? 'PRESENT';
        if (statut == 'ABSENT' || statut == 'RETARD') {
          final seance = json['seance'] ?? {};
          
          absences.add(AbsenceModel(
            id: json['id']?.toString() ?? '',
            childId: studentId.toString(),
            date: seance['date'] ?? '',
            reason: json['motif'] ?? (statut == 'ABSENT' ? 'Absence' : 'Retard'),
            type: statut == 'ABSENT' ? 'absence' : 'retard',
            justification: json['justifie'] == true ? (json['motif'] ?? 'Justifié par l\'établissement') : null,
            justified: json['justifie'] ?? false,
            subject: seance['matiere'] ?? 'Matière inconnue',
          ));
        }
      }
      
      return absences;
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }
}
