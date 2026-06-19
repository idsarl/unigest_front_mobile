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

  String _calculateStatus(DateTime date, String? startStr, String? endStr) {
    if (startStr == null || endStr == null) return 'PLANIFIEE';
    
    final now = DateTime.now();
    
    // Si le jour est passé
    final startOfDay = DateTime(date.year, date.month, date.day);
    final todayStartOfDay = DateTime(now.year, now.month, now.day);
    
    if (startOfDay.isBefore(todayStartOfDay)) {
      return 'TERMINEE';
    }
    
    // Si le jour est à venir
    if (startOfDay.isAfter(todayStartOfDay)) {
      return 'PLANIFIEE';
    }
    
    // C'est aujourd'hui, on vérifie l'heure
    try {
      final p1 = startStr.split(':');
      final p2 = endStr.split(':');
      final h1 = int.parse(p1[0]);
      final m1 = int.parse(p1[1]);
      final h2 = int.parse(p2[0]);
      final m2 = int.parse(p2[1]);
      
      final currentMins = now.hour * 60 + now.minute;
      final startMins = h1 * 60 + m1;
      final endMins = h2 * 60 + m2;
      
      if (currentMins > endMins) return 'TERMINEE';
      if (currentMins >= startMins && currentMins <= endMins) return 'EN_COURS';
      return 'PLANIFIEE';
    } catch (_) {
      return 'PLANIFIEE';
    }
  }

  /// Récupère toutes les données du tableau de bord en parallèle
  Future<void> fetchDashboardData() async {
    isLoading.value = true;
    error.value = '';
    try {
      teacherName.value = _session.teacherName;

      // 1. Récupération des emplois du temps du jour (pas les séances !)
      final date = DateTime.now();
      final fetchedEmplois = await _repo.getEmploisDuTempsParDate(date);
      if (fetchedEmplois is List) {
        // Transforme les emplois du temps en format compatible avec l'agenda
        final transformedSeances = fetchedEmplois.map((s) {
          final map = Map<String, dynamic>.from(s as Map);
          final classeMap = map['classe'] as Map?;
          final matiereMap = map['matiere'] as Map?;
          final classeId = classeMap != null ? int.tryParse(classeMap['id']?.toString() ?? '') : null;
          
          final statutLocal = _calculateStatus(date, map['heureDebut']?.toString(), map['heureFin']?.toString());

          return {
            'id': map['id'],
            'matiere': matiereMap != null ? (matiereMap['nom']?.toString() ?? 'Cours') : 'Cours',
            'classe': classeMap != null ? (classeMap['nom']?.toString() ?? '') : '',
            'classeId': classeId,
            'heureDebut': map['heureDebut']?.toString() ?? '',
            'heureFin': map['heureFin']?.toString() ?? '',
            'statut': statutLocal,
            // Note: affectationId is not available from emploi_du_temps, but maybe we don't need it for now?
          };
        }).toList()
          ..sort((a, b) => (a['heureDebut'] as String).compareTo(b['heureDebut'] as String));

        seances.assignAll(transformedSeances);
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
      print('=== DEBUG Moyenne Matiere ===');
      print('moyenneData: $moyenneData');
      if (moyenneData != null) {
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

  /// Démarrer une séance
  Future<void> demarrerSeance(int index) async {
    // Pour l'instant, on désactive cette fonctionnalité car on n'a plus affectationId
    Get.snackbar('Info', 'Fonctionnalité en cours de maintenance',
        snackPosition: SnackPosition.BOTTOM);
  }

  /// Terminer une séance
  Future<void> terminerSeance(int index) async {
    // Pour l'instant, on désactive cette fonctionnalité car on n'a plus seanceId
    Get.snackbar('Info', 'Fonctionnalité en cours de maintenance',
        snackPosition: SnackPosition.BOTTOM);
  }
}
