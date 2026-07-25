import 'package:get/get.dart';
import '../../../models/appel.dart';
import '../../../models/etudiant.dart';
import '../../../models/seance.dart';
import '../../../services/appel_service.dart';

class AppelController extends GetxController {
  final AppelService _service;

  AppelController({required AppelService service}) : _service = service;

  final Rx<SeanceModel?> seance = Rx(null);

  final RxList<EtudiantModel> etudiants = <EtudiantModel>[].obs;
  // Map etudiantId → AppelEntry (état local de l'appel)
  final RxMap<int, AppelEntry> entries = <int, AppelEntry>{}.obs;

  final RxBool loading = true.obs;
  final RxBool submitting = false.obs;
  final RxnString error = RxnString();
  final RxBool submitted = false.obs;

  int get totalMarques => entries.values.where((e) => e.statut != 'PRESENT').length
      + entries.values.where((e) => e.statut == 'PRESENT').length;
  int get totalEtudiants => etudiants.length;

  Future<void> init(SeanceModel s) async {
    seance.value = s;
    loading.value = true;
    error.value = null;
    submitted.value = false;
    entries.clear();
    etudiants.clear();

    try {
      final [etudiantsList, appelsExistants] = await Future.wait([
        _service.getEtudiants(s.classeId),
        _service.getAppelsParSeance(s.id),
      ]);

      final etds = etudiantsList as List<EtudiantModel>;
      final appels = appelsExistants as List<AppelModel>;

      // Initialise tous les étudiants à PRESENT par défaut
      for (final e in etds) {
        entries[e.id] = AppelEntry(etudiantId: e.id, statut: 'PRESENT');
      }
      // Applique les appels déjà enregistrés
      for (final a in appels) {
        entries[a.etudiant.id] = AppelEntry(
          etudiantId: a.etudiant.id,
          statut: a.statut,
          minutesRetard: a.minutesRetard,
          motif: a.motif,
        );
      }

      etudiants.value = etds;
    } catch (e) {
      error.value = e.toString();
    } finally {
      loading.value = false;
    }
  }

  void setStatut(int etudiantId, String statut) {
    final entry = entries[etudiantId];
    if (entry != null) {
      entries[etudiantId] = AppelEntry(
        etudiantId: etudiantId,
        statut: statut,
        minutesRetard: entry.minutesRetard,
        motif: entry.motif,
      );
    }
  }

  Future<void> soumettre() async {
    if (submitting.value || seance.value == null) return;
    submitting.value = true;
    error.value = null;
    try {
      await _service.soumettreAppels(
          seance.value!.id, entries.values.toList());
      submitted.value = true;
      Get.back();
      Get.snackbar('Succès', 'Appel enregistré',
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
