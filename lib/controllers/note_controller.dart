import 'package:get/get.dart';
import '../core/utils/presence_utils.dart';
import '../services/teacher_repository.dart';

class NoteController extends GetxController {
  final TeacherRepository _repo = TeacherRepository.instance;

  final RxBool isLoading = true.obs;
  final RxString error = ''.obs;
  final RxBool isSaving = false.obs;

  final RxList<Map<String, dynamic>> affectations = <Map<String, dynamic>>[].obs;
  final RxInt selectedAffectationIndex = 0.obs;
  final RxInt selectedMatiereIndex = 0.obs;
  final RxList<Map<String, dynamic>> evaluations = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> students = <Map<String, dynamic>>[].obs;

  Map<String, dynamic>? get selectedAffectation {
    if (affectations.isEmpty) return null;
    final i = selectedAffectationIndex.value.clamp(0, affectations.length - 1);
    return affectations[i];
  }

  int? get affectationId =>
      int.tryParse(selectedAffectation?['id']?.toString() ?? '');

  List<dynamic> get currentMatieres {
    final mats = selectedAffectation?['matieres'];
    return mats is List ? mats : [];
  }

  int? get matiereId {
    final mats = currentMatieres;
    if (mats.isNotEmpty) {
      final i = selectedMatiereIndex.value.clamp(0, mats.length - 1);
      return int.tryParse(mats[i]['id']?.toString() ?? '');
    }
    return null;
  }

  String get classeLabel =>
      selectedAffectation?['classe']?['nom']?.toString() ?? '—';

  String get matiereLabel {
    final mats = currentMatieres;
    if (mats.isNotEmpty) {
      final i = selectedMatiereIndex.value.clamp(0, mats.length - 1);
      return mats[i]['nom']?.toString() ?? '—';
    }
    return '—';
  }

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  Future<void> loadData() async {
    isLoading.value = true;
    error.value = '';
    try {
      final affs = await _repo.getAffectations();
      affectations.assignAll(
        affs.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList(),
      );
      if (affectations.isNotEmpty) {
        await loadNotes();
      }
    } catch (e) {
      error.value = 'Impossible de charger les notes : $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> selectAffectation(int index) async {
    selectedAffectationIndex.value = index;
    selectedMatiereIndex.value = 0;
    await loadNotes();
  }

  Future<void> selectMatiere(int index) async {
    selectedMatiereIndex.value = index;
    await loadNotes();
  }

  Future<void> loadNotes() async {
    final affId = affectationId;
    final cId = int.tryParse(
        selectedAffectation?['classe']?['id']?.toString() ?? '');
    if (affId == null || cId == null) return;

    isLoading.value = true;
    try {
      final notes = await _repo.getNotesAffectation(affId);
      final grouped = <String, Map<String, dynamic>>{};
      final currentMatId = matiereId;

      for (final n in notes) {
        if (n is! Map) continue;
        
        final mId = n['matiere']?['id']?.toString();
        if (currentMatId != null && mId != null && mId != currentMatId.toString()) {
           continue; 
        }

        final type = n['type']?.toString() ?? 'DEVOIR';
        var date = n['dateEvaluation']?.toString() ?? '';
        if (n['dateEvaluation'] is List) {
          final l = n['dateEvaluation'] as List;
          if (l.length >= 3) {
            date = '${l[0]}-${l[1].toString().padLeft(2, '0')}-${l[2].toString().padLeft(2, '0')}';
          }
        }
        final key = '$type|$date';
        grouped.putIfAbsent(
          key,
          () => {
            'type': type,
            'date': date,
            'dateLabel': _formatDateLabel(date),
            'title': _typeLabel(type),
            'noteMax': '20',
            'notes': <Map<String, dynamic>>[],
          },
        );
        (grouped[key]!['notes'] as List).add(Map<String, dynamic>.from(n));
      }

      evaluations.assignAll(grouped.values.toList()
        ..sort((a, b) => (b['date'] as String).compareTo(a['date'] as String)));

      final etudiants = await _repo.getEtudiantsClasse(cId);
      students.assignAll(etudiants.map((e) {
        final map = Map<String, dynamic>.from(e as Map);
        final name = PresenceUtils.fullName(map);
        return {
          'id': int.tryParse(map['id']?.toString() ?? '') ?? 0,
          'name': name,
          'initial': PresenceUtils.initials(name),
          'note': '',
        };
      }));
    } catch (e) {
      error.value = '$e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> saveEvaluationNotes({
    required String type,
    required String dateIso,
    required double noteMax,
    required List<Map<String, dynamic>> studentNotes,
  }) async {
    final affId = affectationId;
    final matId = matiereId;
    if (affId == null || matId == null) return;

    isSaving.value = true;
    try {
      final batch = <Map<String, dynamic>>[];
      for (final s in studentNotes) {
        final valeur = double.tryParse(s['note']?.toString() ?? '');
        if (valeur == null) continue;
        batch.add({
          'etudiantId': s['id'],
          'affectationId': affId,
          'matiereId': matId,
          'valeur': valeur,
          'type': type,
          'periode': 1,
          'typePeriode': 'SEMESTRE',
          'dateEvaluation': dateIso,
        });
      }
      if (batch.isEmpty) {
        Get.snackbar('Info', 'Aucune note à enregistrer',
            snackPosition: SnackPosition.BOTTOM);
        return;
      }
      await _repo.saveNotesBatch(batch);
      await loadNotes();
      Get.snackbar('Succès', 'Notes publiées',
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Erreur', '$e', snackPosition: SnackPosition.BOTTOM);
    } finally {
      isSaving.value = false;
    }
  }

  List<Map<String, dynamic>> notesForEvaluation(Map<String, dynamic> eval) {
    final notes = eval['notes'] as List? ?? [];
    final byStudent = <int, Map<String, dynamic>>{};
    for (final n in notes) {
      if (n is! Map) continue;
      final etu = n['etudiant'];
      if (etu is Map) {
        final id = int.tryParse(etu['id']?.toString() ?? '');
        if (id != null) byStudent[id] = Map<String, dynamic>.from(n);
      }
    }

    return students.map((s) {
      final existing = byStudent[s['id'] as int];
      return {
        ...s,
        'note': existing != null ? existing['valeur']?.toString() ?? '' : '',
      };
    }).toList();
  }

  String _formatDateLabel(String iso) {
    if (iso.isEmpty) return '';
    try {
      final d = DateTime.parse(iso);
      const mois = [
        'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
        'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
      ];
      return '${d.day} ${mois[d.month - 1]} ${d.year}';
    } catch (_) {
      return iso;
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'DEVOIR':
        return 'Devoir';
      case 'COMPOSITION':
        return 'Composition';
      case 'EXAMEN':
        return 'Examen';
      case 'INTERROGATION':
        return 'Interrogation';
      case 'TP':
        return 'TP';
      case 'PARTICIPATION':
        return 'Participation';
      default:
        return type;
    }
  }
}
