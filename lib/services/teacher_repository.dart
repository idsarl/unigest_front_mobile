import 'package:file_picker/file_picker.dart';
import '../core/session/app_session.dart';
import '../core/utils/presence_utils.dart';
import '../core/storage/hive_service.dart';
import 'api_service.dart';

/// Appels API métier enseignant avec support hors ligne.
class TeacherRepository {
  TeacherRepository._({ApiService? api}) : _api = api ?? ApiService.instance;

  static final TeacherRepository instance = TeacherRepository._();

  final ApiService _api;
  final AppSession _session = AppSession.instance;
  final HiveService _hive = HiveService.instance;

  int get teacherId => _session.teacherId;

  // --- Messages ---
  Future<List<dynamic>> getConversations() async {
    try {
      final data = await _api.get('/api/messages/conversations');
      if (data is List) {
        // Sauvegarde dans le stockage local
        await _hive.saveConversations(data);
        return data;
      }
    } catch (e) {
      // Si erreur, essaye le stockage local
      final localConversations = _hive.getConversations();
      if (localConversations.isNotEmpty) {
        return localConversations;
      }
      rethrow;
    }
    return [];
  }

  Future<List<dynamic>> getMessages(int contactId) async {
    try {
      final response = await _api.get('/api/messages/conversation/$contactId');
      if (response is List) {
        final messages = List<Map<String, dynamic>>.from(response);
        // Sauvegarde dans le stockage local
        await _hive.saveMessages(contactId, messages);
        return messages;
      }
    } catch (e) {
      // Si erreur, essaye le stockage local
      final localMessages = _hive.getMessages(contactId);
      if (localMessages.isNotEmpty) {
        return localMessages;
      }
      rethrow;
    }
    return [];
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
  Future<void> genererSeancesDuJour() async {
    try {
      await _api.post('/api/seances/generer-jour');
    } catch (e) {
      print('Erreur génération séances: $e');
    }
  }

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

  Future<List<dynamic>> getEmploisDuTempsParDate(DateTime date) async {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    try {
      final data = await _api.get(
        '/api/emplois-du-temps/enseignant/$teacherId/date',
        query: {'date': dateStr},
      );
      if (data is List) {
        // Sauvegarde dans le cache
        await _hive.saveEmploiDuTemps(data);
        return data;
      }
    } catch (e) {
      // Si erreur, essaye le cache
      final localData = _hive.getEmploiDuTemps();
      if (localData != null) {
        return localData;
      }
      rethrow;
    }
    return [];
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

  Future<Map<String, dynamic>> terminerSeance(int seanceId) async {
    final data = await _api.put('/api/seances/$seanceId/terminer');
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
    final cacheKey = 'dashboard_absences_$teacherId';
    try {
      final data = await _api.get('/api/seances/enseignant/$teacherId/absences/jour');
      if (data is Map) {
        final result = Map<String, dynamic>.from(data);
        await _hive.saveCache(cacheKey, result);
        return result;
      }
    } catch (_) {
      // Essaie de récupérer depuis le cache
      final cached = _hive.getCache(cacheKey);
      if (cached is Map) {
        return Map<String, dynamic>.from(cached);
      }
    }
    return {};
  }

  Future<Map<String, dynamic>?> getProchaineSeance() async {
    final cacheKey = 'prochaine_seance_$teacherId';
    try {
      final data = await _api.get('/api/seances/enseignant/$teacherId/prochaine');
      if (data is Map) {
        final result = Map<String, dynamic>.from(data);
        await _hive.saveCache(cacheKey, result);
        return result;
      }
    } catch (_) {
      // Essaie de récupérer depuis le cache
      final cached = _hive.getCache(cacheKey);
      if (cached is Map) {
        return Map<String, dynamic>.from(cached);
      }
    }
    return null;
  }

  Future<Map<String, dynamic>?> getMoyenneMatiere() async {
    final cacheKey = 'moyenne_matiere_$teacherId';
    try {
      final data =
          await _api.get('/api/seances/enseignant/$teacherId/moyenne-matiere/encours');
      if (data is Map) {
        final result = Map<String, dynamic>.from(data);
        await _hive.saveCache(cacheKey, result);
        return result;
      }
    } catch (_) {
      // Essaie de récupérer depuis le cache
      final cached = _hive.getCache(cacheKey);
      if (cached is Map) {
        return Map<String, dynamic>.from(cached);
      }
    }
    return null;
  }

  Future<void> updateProfile({
    required String nom,
    required String prenom,
    required String email,
    String? password,
  }) async {
    final queryParams = {
      'nom': nom,
      'prenom': prenom,
      'email': email,
    };
    if (password != null && password.isNotEmpty) {
      queryParams['password'] = password;
    }
    
    await _api.put(
      '/api/utilisateurs/$teacherId',
      query: queryParams,
    );
  }
}
