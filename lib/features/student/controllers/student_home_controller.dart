import 'package:get/get.dart';
import '../../../core/state_management/getx_helpers.dart';
import '../../../core/services/notes_service.dart';
import '../../../core/services/api_service.dart';
import '../../../models/note_model.dart';
import '../../../models/emploi_model.dart';
import '../../../models/absence_model.dart';
import '../../../models/notification_model.dart';
import '../../../models/bulletin_model.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../core/services/emploi_service.dart';
import '../../../core/services/absences_service.dart';
import '../../../core/services/notifications_service.dart';
import '../../../core/services/bulletin_service.dart';
import '../../../services/storage_service.dart';

class StudentHomeController extends BaseController {
  // Observables
  final RxInt currentIndex = 0.obs;
  final RxList<NoteModel> notes = <NoteModel>[].obs;
  final RxList<EmploiModel> emploiDuTemps = <EmploiModel>[].obs;
  final RxList<AbsenceModel> absences = <AbsenceModel>[].obs;
  final RxList<NotificationModel> notifications = <NotificationModel>[].obs;
  final RxList<BulletinModel> bulletins = <BulletinModel>[].obs;
  final RxBool isDownloadingBulletin = false.obs;

  final RxDouble moyenneGenerale = 0.0.obs;
  final RxMap<int, double> moyennesParTrimestre =
      <int, double>{1: 0.0, 2: 0.0, 3: 0.0}.obs;
  final RxDouble moyenneRecente = 0.0.obs;
  final RxInt trimestreRecent = 1.obs;
  final RxInt selectedTrimestre = 0.obs; // 0 = tous les trimestres
  final RxInt unreadCount = 0.obs;
  final RxString studentFullName = ''.obs;
  final RxString studentMatricule = ''.obs;
  final RxString studentEmail = ''.obs;
  final RxString studentPhone = ''.obs;
  final RxString studentBirthDate = ''.obs;
  final RxString studentClassName = ''.obs;
  final RxInt studentClassId = 0.obs;
  final RxString studentSchoolYear = ''.obs;
  final RxString studentParentName = ''.obs;
  final RxString studentParentAddress = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  Future<void> loadData() async {
    setLoading(true);
    try {
      final authController = Get.find<AuthController>();
      final studentId = authController.userId.value;

      // Charger les données depuis le backend
      await loadStudentProfile(studentId);
      await _loadDataFromBackend(studentId);

      clearError();
    } catch (e) {
      setError(e.toString());
      // Ne jamais masquer une panne API avec des donnees fictives. L'ecran
      // conserve un etat vide et affiche l'erreur geree par BaseController.
      notes.clear();
      emploiDuTemps.clear();
      absences.clear();
      notifications.clear();
      moyenneGenerale.value = 0;
      moyenneRecente.value = 0;
      moyennesParTrimestre.assignAll({1: 0, 2: 0, 3: 0});
      unreadCount.value = 0;
    } finally {
      setLoading(false);
    }
  }

  Future<void> _loadDataFromBackend(int studentId) async {
    try {
      // Charger les données en parallèle pour optimiser les performances
      final results = await Future.wait([
        NotesService.getNotesByStudentId(studentId),
        EmploiService.getEmploiDuTemps(
          studentClassName.value,
          studentId,
          classId: studentClassId.value,
        ),
        AbsencesService.getAbsencesByStudentId(studentId),
      ]);

      notes.value = results[0] as List<NoteModel>;
      emploiDuTemps.value = results[1] as List<EmploiModel>;
      absences.value = results[2] as List<AbsenceModel>;

      try {
        bulletins.value =
            await BulletinService.getBulletinsByStudentId(studentId);
      } catch (_) {
        // Le bulletin n'est pas critique pour le reste de l'écran : on
        // n'interrompt pas le chargement des notes/emploi/absences si
        // aucun bulletin n'a encore été généré côté admin.
        bulletins.clear();
      }

      notifications.value = await NotificationsService.getStudentNotifications(
        studentId,
        childName: studentFullName.value,
      );
      unreadCount.value = notifications.where((n) => !n.isRead).length;

      // Calculer les moyennes
      if (notes.isNotEmpty) {
        double total = 0.0;
        double totalCoeff = 0.0;
        for (var note in notes) {
          total += note.value * double.parse(note.coefficient);
          totalCoeff += double.parse(note.coefficient);
        }
        moyenneGenerale.value = totalCoeff > 0 ? total / totalCoeff : 0.0;
      }

      for (int t = 1; t <= 3; t++) {
        final notesTrimestre = notes.where((n) => n.trimestre == t).toList();
        if (notesTrimestre.isNotEmpty) {
          double total = 0.0;
          double totalCoeff = 0.0;
          for (var note in notesTrimestre) {
            total += note.value * double.parse(note.coefficient);
            totalCoeff += double.parse(note.coefficient);
          }
          moyennesParTrimestre[t] = totalCoeff > 0 ? total / totalCoeff : 0.0;
        }
      }

      int dernierTrimestre = 0;
      for (int t = 3; t >= 1; t--) {
        if (notes.any((n) => n.trimestre == t)) {
          dernierTrimestre = t;
          break;
        }
      }
      if (dernierTrimestre > 0) {
        trimestreRecent.value = dernierTrimestre;
        moyenneRecente.value = moyennesParTrimestre[dernierTrimestre] ?? 0.0;
        if (selectedTrimestre.value == 0) {
          selectedTrimestre.value = dernierTrimestre;
        }
      }
    } catch (e) {
      throw Exception('Erreur lors du chargement des données: $e');
    }
  }

  Future<void> loadStudentProfile(int studentId) async {
    if (studentId == 0) return;

    try {
      final results = await Future.wait([
        ApiService.get('/etudiants/$studentId'),
        ApiService.get('/inscriptions/etudiant/$studentId'),
      ]);

      final studentJson =
          ApiService.decodeJson(results[0]) as Map<String, dynamic>;
      final inscriptionsJson =
          ApiService.decodeJson(results[1]) as List<dynamic>;

      final firstName = studentJson['prenom']?.toString() ?? '';
      final lastName = studentJson['nom']?.toString() ?? '';
      studentFullName.value = [firstName, lastName]
          .where((part) => part.trim().isNotEmpty)
          .join(' ');
      studentMatricule.value = studentJson['matricule']?.toString() ?? '';
      studentEmail.value = studentJson['email']?.toString() ?? '';
      studentPhone.value = studentJson['telephone']?.toString() ?? '';
      studentBirthDate.value = studentJson['dateNaissance']?.toString() ?? '';

      final parent = studentJson['parent'];
      if (parent is Map<String, dynamic>) {
        final parentFirstName = parent['prenom']?.toString() ?? '';
        final parentLastName = parent['nom']?.toString() ?? '';
        studentParentName.value = [parentFirstName, parentLastName]
            .where((part) => part.trim().isNotEmpty)
            .join(' ');
        studentParentAddress.value = parent['adresse']?.toString() ?? '';
      }

      if (inscriptionsJson.isNotEmpty) {
        final inscription = inscriptionsJson.first as Map<String, dynamic>;
        final classe = inscription['classe'];
        final anneeScolaire = inscription['anneeScolaire'];

        if (classe is Map<String, dynamic>) {
          studentClassName.value = classe['nom']?.toString() ?? '';
          studentClassId.value =
              int.tryParse(classe['id']?.toString() ?? '') ?? 0;
        }

        if (anneeScolaire is Map<String, dynamic>) {
          studentSchoolYear.value = anneeScolaire['libelle']?.toString() ?? '';
        }
      }
    } catch (e) {
      throw Exception('Erreur lors du chargement du profil: $e');
    }
  }

  List<NoteModel> get notesForSelectedTrimestre {
    if (selectedTrimestre.value == 0) return notes;
    return notes.where((n) => n.trimestre == selectedTrimestre.value).toList();
  }

  void selectTrimestre(int trimestre) {
    selectedTrimestre.value =
        selectedTrimestre.value == trimestre ? 0 : trimestre;
  }

  void changeTab(int index) {
    currentIndex.value = index;
  }

  void markAllAsRead() {
    for (var notification in notifications) {
      if (!notification.isRead) {
        notifications[notifications.indexOf(notification)] = NotificationModel(
          id: notification.id,
          title: notification.title,
          message: notification.message,
          timestamp: notification.timestamp,
          type: notification.type,
          isRead: true,
          childId: notification.childId,
          childName: notification.childName,
        );
      }
    }
    unreadCount.value = 0;
  }

  void markNotificationAsRead(String notificationId) {
    final index = notifications.indexWhere((item) => item.id == notificationId);
    if (index == -1 || notifications[index].isRead) return;

    final notification = notifications[index];
    notifications[index] = NotificationModel(
      id: notification.id,
      title: notification.title,
      message: notification.message,
      timestamp: notification.timestamp,
      type: notification.type,
      isRead: true,
      childId: notification.childId,
      childName: notification.childName,
    );
    unreadCount.value = notifications.where((n) => !n.isRead).length;
  }

  Future<void> downloadBulletinPdf(BulletinModel bulletin) async {
    if (isDownloadingBulletin.value) return;
    isDownloadingBulletin.value = true;
    try {
      final fileName =
          'bulletin_${bulletin.periodeLabel.replaceAll(' ', '_')}.pdf';
      await BulletinService.downloadAndOpenPdf(bulletin.id, fileName);
    } catch (e) {
      setError('Impossible de télécharger le bulletin : $e');
    } finally {
      isDownloadingBulletin.value = false;
    }
  }

  Future<void> logout() async {
    try {
      await StorageService.logout();
      final authController = Get.find<AuthController>();
      await authController.logout();
    } catch (e) {
      Get.offAllNamed('/auth');
    }
  }
}
