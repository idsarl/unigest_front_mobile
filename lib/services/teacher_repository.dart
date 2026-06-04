import 'package:file_picker/file_picker.dart';
import '../core/session/app_session.dart';
import '../core/utils/presence_utils.dart';
import 'api_service.dart';

/// Appels API métier enseignant (séances, appels, notes, classes).
class TeacherRepository {
  TeacherRepository({ApiService? api}) : _api = api ?? ApiService.instance;

  final ApiService _api;
  final AppSession _session = AppSession.instance;

  int get teacherId => _session.teacherId;

  // --- Messages ---
  Future<List<dynamic>> getConversations() async {
    final data = await _api.get('/api/messages/conversations');
    return data is List ? data : [];
  }

  Future<List<dynamic>> getMessages(int contactId) async {
    final response = await _api.get('/api/messages/conversation/$contactId');
    return response is List ? List<Map<String, dynamic>>.from(response) : [];
  }

  Future<void> markMessagesAsRead(int contactId) async {
    await _api.put('/api/messages/conversation/$contactId/read');
  }

  Future<Map<String, dynamic>> sendMessage(int destinataireId, String contenu) async {
    final data = await _api.post('/api/messages', body: {
      'destinataireId': destinataireId,
      'contenu': contenu,
    });
    return Map<String, dynamic>.from(data as Map);
  }

  Future<Map<String, dynamic>> sendMessageWithFiles(
    int destinataireId,
    String contenu,
    List<PlatformFile> files,
  ) async {
    return await _api.sendMessageWithFiles(destinataireId, contenu, files);
  }

  Future<void> downloadFile(String url, String savePath) async {
    await _api.downloadFile(url, savePath);
  }

  // --- Séances ---
  Future<List<dynamic>> getSeancesDuJour() async {
    final data = await _api.get('/api/seances/enseignant/$teacherId/jour');
    return data is List ? data : [];
  }

  Future<List<dynamic>> getSeancesParDate(DateTime date) async {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final data = await _api.get(
      '/api/seances/enseignant/$teacherId/date',
      query: {'date': dateStr},
    );
    return data is List ? data : [];
  }

  Future<List<dynamic>> getSeancesAffectationDate(
    int affectationId,
    DateTime date,
  ) async {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final data = await _api.get(
      '/api/seances/affectation/$affectationId/date',
      query: {'date': dateStr},
    );
    return data is List ? data : [];
  }

  Future<Map<String, dynamic>> demarrerSeance(
    int affectationId,
    String matiere,
  ) async {
    final data = await _api.post(
      '/api/seances/demarrer',
      query: {
        'affectationId': affectationId.toString(),
        'matiere': matiere,
      },
    );
    return Map<String, dynamic>.from(data as Map);
  }

  // --- Affectations ---
  Future<List<dynamic>> getAffectations() async {
    final data = await _api.get('/api/affectations/enseignant/$teacherId');
    return data is List ? data : [];
  }

  // --- Inscriptions / étudiants ---
  Future<List<dynamic>> getEtudiantsClasse(int classeId) async {
    final data = await _api.get('/api/inscriptions/$classeId/etudiants');
    return data is List ? data : [];
  }

  // --- Appels ---
  Future<List<dynamic>> getAppelsSeance(int seanceId) async {
    final data = await _api.get('/api/appels/seance/$seanceId');
    return data is List ? data : [];
  }

  Future<Map<String, dynamic>> getResumeClasse(
    int classeId, {
    int? seanceId,
  }) async {
    final query = <String, String>{};
    if (seanceId != null) query['seanceId'] = seanceId.toString();
    final data = await _api.get(
      '/api/appels/classe/$classeId/resume',
      query: query.isEmpty ? null : query,
    );
    return Map<String, dynamic>.from(data as Map);
  }

  Future<void> saveAppels({
    required int seanceId,
    required List<Map<String, dynamic>> students,
  }) async {
    final nouveaux = <Map<String, dynamic>>[];
    for (final s in students) {
      final appelId = s['appelId'] as int?;
      final statutApi = PresenceUtils.toApi(s['status'] as String);
      final retard = s['status'] == 'En retard' ? 15 : 0;
      final motif = s['motif']?.toString();

      if (appelId != null) {
        await _api.put(
          '/api/appels/$appelId',
          query: {
            'statut': statutApi,
            'retard': retard.toString(),
            if (motif != null && motif.isNotEmpty) 'motif': motif,
          },
        );
      } else {
        nouveaux.add({
          'etudiantId': s['id'],
          'statut': statutApi,
          'minutesRetard': retard,
          if (motif != null && motif.isNotEmpty) 'motif': motif,
        });
      }
    }

    if (nouveaux.isNotEmpty) {
      await _api.post('/api/appels/batch', body: {
        'seanceId': seanceId,
        'appels': nouveaux,
      });
    }
  }

  Future<void> justifierAppel(int appelId, String motif) async {
    await _api.put(
      '/api/appels/$appelId/justifier',
      query: {'motif': motif},
    );
  }

  // --- Notes ---
  Future<List<dynamic>> getNotesAffectation(int affectationId) async {
    final data = await _api.get('/api/notes/affectation/$affectationId');
    return data is List ? data : [];
  }

  Future<void> saveNotesBatch(List<Map<String, dynamic>> notes) async {
    await _api.post('/api/notes/batch', body: notes);
  }

  Future<Map<String, dynamic>> getDashboardAbsences() async {
    final data = await _api.get('/api/seances/enseignant/$teacherId/absences/jour');
    return data is Map ? Map<String, dynamic>.from(data) : {};
  }

  Future<Map<String, dynamic>?> getProchaineSeance() async {
    try {
      final data = await _api.get('/api/seances/enseignant/$teacherId/prochaine');
      if (data is Map) return Map<String, dynamic>.from(data);
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> getMoyenneMatiere() async {
    try {
      final data =
          await _api.get('/api/seances/enseignant/$teacherId/moyenne-matiere/encours');
      if (data is Map) return Map<String, dynamic>.from(data);
    } catch (_) {}
    return null;
  }
}
