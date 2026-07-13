import 'dart:async';
import 'package:get/get.dart';
import '../core/session/app_session.dart';
import '../core/storage/hive_service.dart';
import '../services/teacher_repository.dart';
import '../services/api_service.dart';

class TeacherHomeController extends GetxController {
  final TeacherRepository _repo = TeacherRepository.instance;
  final AppSession _session = AppSession.instance;
  final HiveService _hive = HiveService.instance;

  int get teacherId => _session.teacherId;

  final RxBool isLoading = true.obs;
  final RxString error = ''.obs;

  // Variables réactives pour stocker les données de l'API
  final RxList<dynamic> seances = <dynamic>[].obs;
  final RxInt absencesCount = 0.obs;
  final RxMap<String, dynamic> prochaineSeance = <String, dynamic>{}.obs;
  final RxMap<String, dynamic> moyenneMatiere = <String, dynamic>{}.obs;

  final RxString teacherName = AppSession.instance.teacherName.obs;
  Timer? _refreshTimer;

  @override
  void onInit() {
    super.onInit();
    _init();
    // Lance un timer de rafraîchissement toutes les 30 secondes
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      fetchDashboardData();
    });
  }

  @override
  void onClose() {
    _refreshTimer?.cancel();
    super.onClose();
  }

  Future<void> _init() async {
    // D'abord essaye de charger les données locales
    await _loadLocalData();
    // Puis essaye de charger les données depuis l'API et synchroniser
    await fetchDashboardData();
    // Synchronise les requêtes en attente
    await ApiService.instance.syncQueuedRequests();
  }

  Future<void> _loadLocalData() async {
    // Charge l'emploi du temps depuis le cache
    final localEmplois = _hive.getEmploiDuTemps();
    if (localEmplois != null) {
      final date = DateTime.now();
      final transformed = localEmplois.map((s) {
        final map = Map<String, dynamic>.from(s as Map);
        final emploi = map['emploiDuTemps'] as Map? ?? map; // Fallback pour l'ancien format
        final seance = map['seance'] as Map?;
        final classeMap = emploi['classe'] as Map?;
        final matiereMap = emploi['matiere'] as Map?;
        
        String statutLocal;
        if (seance != null && seance['statut'] != null) {
          if (seance['statut'] == 'EN_COURS') {
            statutLocal = 'En cours';
          } else if (seance['statut'] == 'TERMINEE') {
            statutLocal = 'Terminé';
          } else if (seance['statut'] == 'NON_EFFECTUEE') {
            statutLocal = 'Non effectuée';
          } else {
            statutLocal = 'À venir';
          }
        } else {
          final calculated = _calculateStatus(date, emploi['heureDebut']?.toString(), emploi['heureFin']?.toString());
          if (calculated == 'EN_COURS') {
            statutLocal = 'En cours';
          } else if (calculated == 'TERMINEE') {
            statutLocal = 'Terminé';
          } else if (calculated == 'NON_EFFECTUEE') {
            statutLocal = 'Non effectuée';
          } else {
            statutLocal = 'À venir';
          }
        }

        return {
          'id': emploi['id'],
          'emploiDuTemps': emploi,
          'seance': seance,
          'affectationId': map['affectationId'],
          'matiere': matiereMap != null ? (matiereMap['nom']?.toString() ?? 'Cours') : 'Cours',
          'classe': classeMap != null ? (classeMap['nom']?.toString() ?? '') : '',
          'classeId': classeMap != null ? int.tryParse(classeMap['id']?.toString() ?? '') : null,
          'heureDebut': emploi['heureDebut']?.toString() ?? '',
          'heureFin': emploi['heureFin']?.toString() ?? '',
          'statut': statutLocal,
        };
      }).toList()
        ..sort((a, b) => (a['heureDebut'] as String).compareTo(b['heureDebut'] as String));
      seances.assignAll(transformed);
    }

    // Charge les stats depuis le cache
    final cacheKeyAbsences = 'dashboard_absences_${_session.teacherId}';
    final cachedAbsences = _hive.getCache(cacheKeyAbsences);
    if (cachedAbsences != null && cachedAbsences['absences'] != null) {
      absencesCount.value = int.tryParse(cachedAbsences['absences'].toString()) ?? 0;
    }

    final cacheKeyProchaine = 'prochaine_seance_${_session.teacherId}';
    final cachedProchaine = _hive.getCache(cacheKeyProchaine);
    if (cachedProchaine != null) {
      prochaineSeance.value = Map<String, dynamic>.from(cachedProchaine);
    }

    final cacheKeyMoyenne = 'moyenne_matiere_${_session.teacherId}';
    final cachedMoyenne = _hive.getCache(cacheKeyMoyenne);
    if (cachedMoyenne != null) {
      moyenneMatiere.value = Map<String, dynamic>.from(cachedMoyenne);
    }
  }

  String _calculateStatus(DateTime date, String? startStr, String? endStr) {
    if (startStr == null || endStr == null) return 'PLANIFIEE';
    
    final now = DateTime.now();
    
    // Si le jour est passé
    final startOfDay = DateTime(date.year, date.month, date.day);
    final todayStartOfDay = DateTime(now.year, now.month, now.day);
    
    if (startOfDay.isBefore(todayStartOfDay)) {
      return 'NON_EFFECTUEE';
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
      
      if (currentMins > endMins) return 'NON_EFFECTUEE';
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

      // 1. Récupération des emplois du temps du jour avec les séances associées
      final date = DateTime.now();
      final fetchedEmploisAvecSeances = await _repo.getEmploisDuTempsParDate(date);
      if (fetchedEmploisAvecSeances is List) {
        // Transforme les emplois du temps en format compatible avec l'agenda
        final transformedSeances = fetchedEmploisAvecSeances.map((item) {
          final map = Map<String, dynamic>.from(item as Map);
          final emploi = map['emploiDuTemps'] as Map;
          final seance = map['seance'] as Map?;
          final classeMap = emploi['classe'] as Map?;
          final matiereMap = emploi['matiere'] as Map?;
          final classeId = classeMap != null ? int.tryParse(classeMap['id']?.toString() ?? '') : null;
          
          String statut;
          if (seance != null && seance['statut'] != null) {
            if (seance['statut'] == 'EN_COURS') {
              statut = 'En cours';
            } else if (seance['statut'] == 'TERMINEE') {
              statut = 'Terminé';
            } else if (seance['statut'] == 'NON_EFFECTUEE') {
              statut = 'Non effectuée';
            } else {
              statut = 'À venir';
            }
          } else {
            final calculated = _calculateStatus(date, emploi['heureDebut']?.toString(), emploi['heureFin']?.toString());
            if (calculated == 'EN_COURS') {
              statut = 'En cours';
            } else if (calculated == 'TERMINEE') {
              statut = 'Terminé';
            } else if (calculated == 'NON_EFFECTUEE') {
              statut = 'Non effectuée';
            } else {
              statut = 'À venir';
            }
          }

          return {
            'id': emploi['id'],
            'emploiDuTemps': emploi,
            'seance': seance,
            'affectationId': map['affectationId'],
            'matiere': matiereMap != null ? (matiereMap['nom']?.toString() ?? 'Cours') : 'Cours',
            'classe': classeMap != null ? (classeMap['nom']?.toString() ?? '') : '',
            'classeId': classeId,
            'heureDebut': emploi['heureDebut']?.toString() ?? '',
            'heureFin': emploi['heureFin']?.toString() ?? '',
            'statut': statut,
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
    final seanceData = seances[index];
    final affectationId = seanceData['affectationId'] as int?;
    final matiere = seanceData['matiere'] as String;
    if (affectationId == null) {
      Get.snackbar('Erreur', 'Impossible de démarrer la séance : affectation introuvable',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    try {
      final result = await _repo.demarrerSeance(affectationId, matiere);
      if (result != null) {
        await fetchDashboardData();
        Get.snackbar('Succès', 'Séance démarrée !',
            snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible de démarrer la séance : $e',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  /// Terminer une séance
  Future<void> terminerSeance(int index) async {
    final seanceData = seances[index];
    final seance = seanceData['seance'] as Map?;
    final seanceId = seance?['id'] as int?;
    if (seanceId == null) {
      Get.snackbar('Erreur', 'Impossible de terminer la séance : séance introuvable',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    try {
      final result = await _repo.terminerSeance(seanceId);
      if (result != null) {
        await fetchDashboardData();
        Get.snackbar('Succès', 'Séance terminée !',
            snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible de terminer la séance : $e',
          snackPosition: SnackPosition.BOTTOM);
    }
  }
}
