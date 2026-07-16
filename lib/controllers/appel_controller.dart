import 'package:get/get.dart';
import '../core/utils/presence_utils.dart';
import '../services/teacher_repository.dart';
import 'teacher_home_controller.dart';

class AppelController extends GetxController {
  final TeacherRepository _repo = TeacherRepository.instance;

  final RxBool isLoading = true.obs;
  final RxString error = ''.obs;
  final RxBool isSaving = false.obs;
  final RxBool isAppelSaved = false.obs;

  final RxList<Map<String, dynamic>> affectations =
      <Map<String, dynamic>>[].obs;
  final RxInt selectedAffectationIndex = 0.obs;
  final RxInt selectedMatiereIndex = 0.obs;
  final RxList<Map<String, dynamic>> students = <Map<String, dynamic>>[].obs;
  final RxMap<String, dynamic> resume = <String, dynamic>{}.obs;
  final RxnInt seanceId = RxnInt();
  final RxString searchQuery = ''.obs;

  Map<String, dynamic>? get selectedAffectation {
    if (affectations.isEmpty) return null;
    final i = selectedAffectationIndex.value.clamp(0, affectations.length - 1);
    return affectations[i];
  }

  String get classeLabel =>
      selectedAffectation?['classe']?['nom']?.toString() ?? '—';

  List<dynamic> get currentMatieres {
    final mats = selectedAffectation?['matieres'];
    return mats is List ? mats : [];
  }

  String get matiereLabel {
    final mats = currentMatieres;
    if (mats.isNotEmpty) {
      final i = selectedMatiereIndex.value.clamp(0, mats.length - 1);
      return mats[i]['nom']?.toString() ?? '—';
    }
    return '—';
  }

  int? get classeId {
    final c = selectedAffectation?['classe'];
    if (c is Map) return int.tryParse(c['id']?.toString() ?? '');
    return null;
  }

  List<Map<String, dynamic>> get filteredStudents {
    final q = searchQuery.value.trim().toLowerCase();
    if (q.isEmpty) return students;
    return students
        .where((s) => (s['name'] as String).toLowerCase().contains(q))
        .toList();
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

      // Essayer de trouver la séance actuelle/prochaine via l'emploi du temps
      if (affectations.isNotEmpty) {
        final emploisDuJour =
            await _repo.getEmploisDuTempsParDate(DateTime.now());
        final now = DateTime.now();
        final currentMins = now.hour * 60 + now.minute;

        Map<String, dynamic>? currentEmploi;

        for (final e in emploisDuJour) {
          final map = Map<String, dynamic>.from(e as Map);
          final startStr = map['heureDebut']?.toString();
          final endStr = map['heureFin']?.toString();
          if (startStr != null && endStr != null) {
            try {
              final p1 = startStr.split(':');
              final p2 = endStr.split(':');
              final startMins = int.parse(p1[0]) * 60 + int.parse(p1[1]);
              final endMins = int.parse(p2[0]) * 60 + int.parse(p2[1]);
              if (currentMins >= startMins && currentMins <= endMins) {
                currentEmploi = map;
                break;
              } else if (currentMins < startMins) {
                // Keep the next closest one if we don't have a current one
                if (currentEmploi == null) {
                  currentEmploi = map;
                }
              }
            } catch (_) {}
          }
        }

        if (currentEmploi != null) {
          final classeMap = currentEmploi['classe'] as Map?;
          final matiereMap = currentEmploi['matiere'] as Map?;
          final cId = classeMap?['id']?.toString();
          final matNom = matiereMap?['nom']?.toString();

          if (cId != null) {
            final index = affectations.indexWhere((a) {
              final aC = a['classe'];
              if (aC is Map) {
                return aC['id']?.toString() == cId;
              }
              return false;
            });
            if (index != -1) {
              selectedAffectationIndex.value = index;
              // Selectionner la matiere si possible
              if (matNom != null) {
                final mats = currentMatieres;
                final matIndex =
                    mats.indexWhere((m) => m['nom']?.toString() == matNom);
                if (matIndex != -1) {
                  selectedMatiereIndex.value = matIndex;
                }
              }
            }
          }
        }

        await selectAffectation(selectedAffectationIndex.value);
      }
    } catch (e) {
      error.value = 'Impossible de charger les données : $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> selectMatiere(int index) async {
    selectedMatiereIndex.value = index;
    isAppelSaved.value = false; // Réinitialise le statut d'enregistrement
    await _loadAppelForCurrentSelection();
  }

  Future<void> selectAffectation(int index) async {
    if (affectations.isEmpty) return;
    selectedAffectationIndex.value = index.clamp(0, affectations.length - 1);
    selectedMatiereIndex.value = 0;
    isAppelSaved.value = false; // Réinitialise le statut d'enregistrement
    await _loadAppelForCurrentSelection();
  }

  Future<void> _loadAppelForCurrentSelection() async {
    final aff = selectedAffectation;
    if (aff == null) return;
    final affId = int.tryParse(aff['id']?.toString() ?? '');
    final cId = classeId;
    if (affId == null || cId == null) return;

    isLoading.value = true;
    error.value = '';
    try {
      final matiereNom = matiereLabel == '—' ? '' : matiereLabel;

      var seances =
          await _repo.getSeancesAffectationDate(affId, DateTime.now());
      int? sid;

      final matchingSeance = seances
          .firstWhereOrNull((s) => s is Map && s['matiere'] == matiereNom);

      if (matchingSeance != null) {
        sid = int.tryParse((matchingSeance as Map)['id']?.toString() ?? '');
      } else if (seances.isNotEmpty) {
        sid = int.tryParse((seances.first as Map)['id']?.toString() ?? '');
      } else {
        final created = await _repo.demarrerSeance(affId, matiereNom);
        sid = int.tryParse(created['id']?.toString() ?? '');
      }
      seanceId.value = sid;

      final etudiants = await _repo.getEtudiantsClasse(cId);
      final appels =
          sid != null ? await _repo.getAppelsSeance(sid) : <dynamic>[];

      final appelParEtudiant = <int, Map<String, dynamic>>{};
      for (final a in appels) {
        if (a is! Map) continue;
        final etu = a['etudiant'];
        if (etu is Map) {
          final eid = int.tryParse(etu['id']?.toString() ?? '');
          if (eid != null) appelParEtudiant[eid] = Map<String, dynamic>.from(a);
        }
      }

      students.assignAll(etudiants.map((e) {
        final map = Map<String, dynamic>.from(e as Map);
        final id = int.tryParse(map['id']?.toString() ?? '') ?? 0;
        final name = PresenceUtils.fullName(map);
        final existing = appelParEtudiant[id];
        return {
          'id': id,
          'name': name,
          'initial': PresenceUtils.initials(name),
          'status': existing != null
              ? PresenceUtils.fromApi(existing['statut']?.toString())
              : 'Présent',
          'appelId': existing != null
              ? int.tryParse(existing['id']?.toString() ?? '')
              : null,
          'motif': existing?['motif'],
        };
      }));

      // Vérifie si tous les étudiants ont déjà un appel enregistré
      final allHaveAppelId = students.every((s) => s['appelId'] != null);
      isAppelSaved.value = allHaveAppelId;

      resume.value = await _repo.getResumeClasse(cId, seanceId: sid);
    } catch (e) {
      error.value = 'Erreur chargement appel : $e';
    } finally {
      isLoading.value = false;
    }
  }

  void updateStudentStatus(int studentId, String status) {
    final i = students.indexWhere((s) => s['id'] == studentId);
    if (i >= 0) {
      students[i] = {...students[i], 'status': status};
      students.refresh();
      isAppelSaved.value = false; // Réactive le bouton si le statut change
    }
  }

  Future<void> saveAppels() async {
    final sid = seanceId.value;
    if (sid == null) return;
    isSaving.value = true;
    try {
      await _repo.saveAppels(seanceId: sid, students: students.toList());
      final cId = classeId;
      if (cId != null) {
        resume.value = await _repo.getResumeClasse(cId, seanceId: sid);
        final appels = await _repo.getAppelsSeance(sid);
        for (final s in students) {
          final match = appels.cast<Map?>().firstWhere(
                (a) =>
                    a != null &&
                    (a['etudiant'] as Map?)?['id']?.toString() ==
                        s['id'].toString(),
                orElse: () => null,
              );
          if (match != null) {
            s['appelId'] = int.tryParse(match['id']?.toString() ?? '');
          }
        }
        students.refresh();
      }
      isAppelSaved.value = true; // Marque l'appel comme enregistré
      Get.snackbar('Succès', 'Appel enregistré',
          snackPosition: SnackPosition.BOTTOM);
      try {
        if (Get.isRegistered<TeacherHomeController>()) {
          Get.find<TeacherHomeController>().fetchDashboardData();
        }
      } catch (_) {}
    } catch (e) {
      Get.snackbar('Erreur', '$e', snackPosition: SnackPosition.BOTTOM);
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> justifyAppel(int studentId, String motif) async {
    final s = students.firstWhereOrNull((e) => e['id'] == studentId);
    final appelId = s?['appelId'] as int?;
    if (appelId == null) {
      Get.snackbar('Info', 'Enregistrez d\'abord l\'appel',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    try {
      await _repo.justifierAppel(appelId, motif);
      Get.snackbar('Succès', 'Absence justifiée',
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Erreur', '$e', snackPosition: SnackPosition.BOTTOM);
    }
  }
}
