import '../../../core/services/api_service.dart';
import '../../../core/utils/error_handler.dart';
import '../../../models/note_model.dart';

class NotesService {
  // Récupérer toutes les notes d'un étudiant
  static Future<List<NoteModel>> getNotesByStudentId(int studentId) async {
    try {
      final response = await ApiService.get('/notes/etudiant/$studentId');
      final List<dynamic> data = ApiService.decodeJson(response);
      return data.map((json) => _fromJson(json)).toList();
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }

  // Récupérer les notes d'un étudiant par période (trimestre)
  static Future<List<NoteModel>> getNotesByStudentIdAndPeriod(
    int studentId,
    int periode,
  ) async {
    try {
      final response = await ApiService.get(
        '/notes/etudiant/$studentId/periode?periode=$periode&typePeriode=TRIMESTRE',
      );
      final List<dynamic> data = ApiService.decodeJson(response);
      return data.map((json) => _fromJson(json)).toList();
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }

  // Calculer la moyenne d'un étudiant pour une période
  static Future<double> getStudentAverage(int studentId, int periode) async {
    try {
      final response = await ApiService.get(
        '/notes/etudiant/$studentId/moyenne?periode=$periode&typePeriode=TRIMESTRE',
      );
      return ApiService.decodeJson(response);
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }

  // Convertir le JSON du backend en NoteModel
  static NoteModel _fromJson(Map<String, dynamic> json) {
    // Le backend renvoie l'objet matière imbriqué
    final matiere = json['matiere'] ?? {};

    return NoteModel(
      id: json['id']?.toString() ?? '',
      childId: json['etudiant']?['id']?.toString() ?? '',
      subject: matiere['nom'] ?? matiere['libelle'] ?? 'Inconnu',
      value: (json['valeur'] ?? 0.0).toDouble(),
      maxNote: 20.0, // Le backend utilise 20 comme note maximale
      coefficient: json['coefficient']?.toString() ?? '1',
      date: json['dateEvaluation'] ?? '',
      type: _mapTypeNote(json['type']),
      comment: null,
      trimestre: json['periode'] ?? 1,
    );
  }

  // Mapper le type de note du backend vers le frontend
  static String _mapTypeNote(dynamic type) {
    if (type == null) return 'devoir';
    final typeStr = type.toString().toLowerCase();
    if (typeStr.contains('devoir')) return 'devoir';
    if (typeStr.contains('interrogation')) return 'interrogation';
    if (typeStr.contains('examen')) return 'examen';
    return 'devoir';
  }
}
