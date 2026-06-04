import 'package:get/get.dart';
import '../core/session/app_session.dart';
import '../services/teacher_repository.dart';

class TeacherHomeController extends GetxController {
  final TeacherRepository _repo = TeacherRepository();
  final AppSession _session = AppSession.instance;

  int get teacherId => _session.teacherId;

  final RxBool isLoading = true.obs;
  final RxString error = ''.obs;

  // Variables réactives pour stocker les données de l'API
  final RxList<dynamic> seances = <dynamic>[].obs;
  final RxInt absencesCount = 0.obs;
  final RxMap<String, dynamic> prochaineSeance = <String, dynamic>{}.obs;
  final RxMap<String, dynamic> moyenneMatiere = <String, dynamic>{}.obs;

  final RxString teacherName = AppSession.instance.teacherName.obs;

  @override
  void onInit() {
    super.onInit();
    fetchDashboardData();
  }

  /// Récupère toutes les données du tableau de bord en parallèle
  Future<void> fetchDashboardData() async {
    isLoading.value = true;
    error.value = '';
    try {
      teacherName.value = _session.teacherName;

      // 1. Récupération des séances du jour
      final fetchedSeances = await _repo.getSeancesDuJour();
      if (fetchedSeances is List) {
        seances.assignAll(fetchedSeances);
        
        // Extraction du nom de l'enseignant s'il est présent dans l'agenda
        if (fetchedSeances.isNotEmpty) {
          final firstSeance = fetchedSeances.first;
          if (firstSeance['professeur'] != null && firstSeance['professeur'].toString().isNotEmpty) {
            teacherName.value = firstSeance['professeur'].toString();
          }
        }
      } else {
        seances.clear();
      }

      // 2. Récupération des absences du jour pour cet enseignant
      final absencesData = await _repo.getDashboardAbsences();
      if (absencesData != null && absencesData['absences'] != null) {
        absencesCount.value = int.tryParse(absencesData['absences'].toString()) ?? 0;
      } else {
        absencesCount.value = 0;
      }

      // 3. Prochain cours
      final prochaineData = await _repo.getProchaineSeance();
      if (prochaineData != null && prochaineData['message'] == null) {
        prochaineSeance.value = prochaineData;
      } else {
        prochaineSeance.clear();
      }

      // 4. Moyennes matière en cours
      final moyenneData = await _repo.getMoyenneMatiere();
      if (moyenneData != null && moyenneData['message'] == null) {
        moyenneMatiere.value = moyenneData;
      } else {
        moyenneMatiere.clear();
      }

    } catch (e) {
      error.value = 'Erreur lors du chargement des données : $e';
    } finally {
      isLoading.value = false;
    }
  }
}
