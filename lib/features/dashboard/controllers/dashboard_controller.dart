import 'package:get/get.dart';
import '../../../models/affectation.dart';
import '../../../models/seance.dart';
import '../../../services/dashboard_service.dart';
import '../../auth/controllers/auth_controller.dart';

class DashboardController extends GetxController {
  final DashboardService _service;

  DashboardController({required DashboardService service}) : _service = service;

  // ── Stats ──────────────────────────────────────────────────────────────────
  final Rx<EnseignantDashboard?> stats = Rx(null);
  final RxBool loadingStats = true.obs;
  final RxnString statsError = RxnString();

  // ── Séances du jour ────────────────────────────────────────────────────────
  final RxList<SeanceModel> seancesDuJour = <SeanceModel>[].obs;
  final RxBool loadingSeances = true.obs;
  final RxnString seancesError = RxnString();

  // IDs des séances en cours de mise à jour (désactive le bouton le temps du call)
  final RxSet<int> updatingSeances = <int>{}.obs;

  int get _enseignantId {
    final u = Get.find<AuthController>().user;
    return int.tryParse(u?.enseignantId ?? '') ?? int.tryParse(u?.id ?? '') ?? 0;
  }

  @override
  void onInit() {
    super.onInit();
    loadAll();
  }

  Future<void> loadAll() async {
    await Future.wait([loadStats(), loadSeancesDuJour()]);
  }

  Future<void> loadStats() async {
    loadingStats.value = true;
    statsError.value = null;
    try {
      stats.value = await _service.getEnseignantDashboard(_enseignantId);
    } catch (e) {
      statsError.value = e.toString();
    } finally {
      loadingStats.value = false;
    }
  }

  Future<void> loadSeancesDuJour() async {
    loadingSeances.value = true;
    seancesError.value = null;
    try {
      seancesDuJour.value =
          await _service.getSeancesDuJour(_enseignantId);
    } catch (e) {
      seancesError.value = e.toString();
    } finally {
      loadingSeances.value = false;
    }
  }

  Future<void> demarrerSeance(int seanceId) async {
    if (updatingSeances.contains(seanceId)) return;
    final idx = seancesDuJour.indexWhere((s) => s.id == seanceId);
    if (idx < 0) return;

    // Mise à jour optimiste
    updatingSeances.add(seanceId);
    final ancien = seancesDuJour[idx].statut;
    seancesDuJour[idx] = seancesDuJour[idx].copyWith(statut: 'EN_COURS');
    seancesDuJour.refresh();

    try {
      final updated = await _service.demarrerSeance(seanceId);
      seancesDuJour[idx] = updated;
      seancesDuJour.refresh();
      loadStats(); // rafraîchit les compteurs sans bloquer
    } catch (e) {
      // Rollback
      seancesDuJour[idx] = seancesDuJour[idx].copyWith(statut: ancien);
      seancesDuJour.refresh();
      Get.snackbar('Erreur', e.toString(),
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      updatingSeances.remove(seanceId);
    }
  }

  Future<void> arreterSeance(int seanceId) async {
    if (updatingSeances.contains(seanceId)) return;
    final idx = seancesDuJour.indexWhere((s) => s.id == seanceId);
    if (idx < 0) return;

    // Mise à jour optimiste
    updatingSeances.add(seanceId);
    final ancien = seancesDuJour[idx].statut;
    seancesDuJour[idx] = seancesDuJour[idx].copyWith(statut: 'TERMINEE');
    seancesDuJour.refresh();

    try {
      final updated = await _service.arreterSeance(seanceId);
      seancesDuJour[idx] = updated;
      seancesDuJour.refresh();
      loadStats();
    } catch (e) {
      seancesDuJour[idx] = seancesDuJour[idx].copyWith(statut: ancien);
      seancesDuJour.refresh();
      Get.snackbar('Erreur', e.toString(),
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      updatingSeances.remove(seanceId);
    }
  }
}
