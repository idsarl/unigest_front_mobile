import 'package:get/get.dart';
import '../../../models/affectation.dart';
import '../../../models/etudiant.dart';
import '../../../models/note.dart';
import '../../../services/appel_service.dart';
import '../../../services/note_service.dart';

class NoteEntry {
  final int etudiantId;
  final String etudiantNom;
  double? valeur;
  int? noteId;
  bool hasError = false;

  NoteEntry({required this.etudiantId, required this.etudiantNom});
}

class NoteController extends GetxController {
  final NoteService _noteService;
  final AppelService _appelService;

  NoteController(
      {required NoteService noteService, required AppelService appelService})
      : _noteService = noteService,
        _appelService = appelService;

  final Rx<AffectationModel?> affectation = Rx(null);
  final RxList<NoteEntry> entries = <NoteEntry>[].obs;

  final RxBool loading = true.obs;
  final RxBool submitting = false.obs;
  final RxnString error = RxnString();
  final RxBool dirty = false.obs; // modifications non sauvegardées

  String type = 'DEVOIR';
  int periode = 1;
  String typePeriode = 'SEMESTRE';

  Future<void> init(AffectationModel aff) async {
    affectation.value = aff;
    loading.value = true;
    error.value = null;
    dirty.value = false;
    entries.clear();

    try {
      final [etudiantsList, notesList] = await Future.wait([
        _appelService.getEtudiants(aff.classeId),
        _noteService.getNotesParAffectation(aff.id),
      ]);

      final etds = etudiantsList as List<EtudiantModel>;
      final notes = notesList as List<NoteModel>;

      // Crée une entrée par étudiant
      final ents = <NoteEntry>[];
      for (final e in etds) {
        final entry = NoteEntry(etudiantId: e.id, etudiantNom: e.fullName);
        // Pré-remplit si une note existe déjà
        final existing = notes.where((n) => n.etudiantId == e.id).firstOrNull;
        if (existing != null) {
          entry.valeur = existing.valeur;
          entry.noteId = existing.id;
        }
        ents.add(entry);
      }
      entries.value = ents;
    } catch (e) {
      error.value = e.toString();
    } finally {
      loading.value = false;
    }
  }

  void setValeur(int etudiantId, double? v) {
    final idx = entries.indexWhere((e) => e.etudiantId == etudiantId);
    if (idx >= 0) {
      entries[idx].valeur = v;
      entries[idx].hasError = v != null && (v < 0 || v > 20);
      dirty.value = true;
      entries.refresh();
    }
  }

  Future<void> soumettre() async {
    if (submitting.value || affectation.value == null) return;

    // Validation
    final invalid = entries.where(
        (e) => e.valeur != null && (e.valeur! < 0 || e.valeur! > 20));
    if (invalid.isNotEmpty) {
      Get.snackbar('Erreur', 'Certaines notes sont hors barème (0–20)',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    submitting.value = true;
    error.value = null;

    final today =
        '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}';

    final batch = entries
        .where((e) => e.valeur != null && !e.hasError)
        .map((e) => NoteBatchItem(
              etudiantId: e.etudiantId,
              affectationId: affectation.value!.id,
              matiereId: affectation.value!.firstMatiereId,
              valeur: e.valeur!,
              type: type,
              periode: periode,
              typePeriode: typePeriode,
              dateEvaluation: today,
            ))
        .toList();

    if (batch.isEmpty) {
      submitting.value = false;
      Get.snackbar('Info', 'Aucune note à soumettre',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    try {
      await _noteService.soumettreNotes(batch);
      dirty.value = false;
      Get.snackbar('Succès', '${batch.length} notes enregistrées',
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      error.value = e.toString();
      Get.snackbar('Erreur', e.toString(),
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      submitting.value = false;
    }
  }
}
