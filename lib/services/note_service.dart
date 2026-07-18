import '../models/note.dart';
import 'api_service.dart';

class NoteService {
  final ApiService api;
  NoteService({required this.api});

  Future<List<NoteModel>> getNotesParAffectation(int affectationId) async {
    final data = await api.get('/api/notes/affectation/$affectationId');
    return (data as List<dynamic>)
        .map((e) => NoteModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<NoteModel>> soumettreNotes(List<NoteBatchItem> notes) async {
    final data = await api.post(
      '/api/notes/batch',
      notes.map((n) => n.toJson()).toList(),
    );
    return (data as List<dynamic>)
        .map((e) => NoteModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<NoteModel> modifierNote(int noteId, double valeur, String type) async {
    final data = await api.put('/api/notes/$noteId?valeur=$valeur&type=$type', null);
    return NoteModel.fromJson(data as Map<String, dynamic>);
  }

  Future<double> getMoyenneEtudiant(
      int etudiantId, int periode, String typePeriode) async {
    final data = await api.get(
      '/api/notes/etudiant/$etudiantId/moyenne',
      params: {'periode': periode.toString(), 'typePeriode': typePeriode},
    );
    return (data as num).toDouble();
  }
}
