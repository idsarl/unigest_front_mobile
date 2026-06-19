import 'package:get/get.dart';
import '../../../core/state_management/getx_helpers.dart';
import '../../../core/services/notes_service.dart';
import '../../../core/services/api_service.dart';
import '../../../models/note_model.dart';
import '../../../models/emploi_model.dart';
import '../../../models/absence_model.dart';
import '../../../models/notification_model.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../core/services/emploi_service.dart';
import '../../../core/services/absences_service.dart';
import '../../../core/services/notifications_service.dart';
import '../../../services/storage_service.dart';

class StudentHomeController extends BaseController {
  // Observables
  final RxInt currentIndex = 0.obs;
  final RxList<NoteModel> notes = <NoteModel>[].obs;
  final RxList<EmploiModel> emploiDuTemps = <EmploiModel>[].obs;
  final RxList<AbsenceModel> absences = <AbsenceModel>[].obs;
  final RxList<NotificationModel> notifications = <NotificationModel>[].obs;

  final RxDouble moyenneGenerale = 0.0.obs;
  final RxMap<int, double> moyennesParTrimestre =
      <int, double>{1: 0.0, 2: 0.0, 3: 0.0}.obs;
  final RxDouble moyenneRecente = 0.0.obs;
  final RxInt trimestreRecent = 1.obs;
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
      _loadMockData();
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

  void _loadMockData() {
    // Charger les notes simulées
    notes.value = [
      NoteModel(
        id: '1',
        childId: 'student1',
        subject: 'Mathématiques',
        value: 16.5,
        maxNote: 20.0,
        coefficient: '2',
        date: '2024-01-15',
        type: 'devoir',
        comment: 'Très bon travail',
        trimestre: 1,
      ),
      NoteModel(
        id: '2',
        childId: 'student1',
        subject: 'Physique',
        value: 14.0,
        maxNote: 20.0,
        coefficient: '2',
        date: '2024-01-16',
        type: 'interrogation',
        trimestre: 1,
      ),
      NoteModel(
        id: '3',
        childId: 'student1',
        subject: 'Français',
        value: 18.0,
        maxNote: 20.0,
        coefficient: '1',
        date: '2024-01-17',
        type: 'devoir',
        trimestre: 1,
      ),
      NoteModel(
        id: '4',
        childId: 'student1',
        subject: 'Histoire',
        value: 15.5,
        maxNote: 20.0,
        coefficient: '1',
        date: '2024-01-18',
        type: 'examen',
        trimestre: 1,
      ),
      NoteModel(
        id: '5',
        childId: 'student1',
        subject: 'Mathématiques',
        value: 17.0,
        maxNote: 20.0,
        coefficient: '2',
        date: '2024-03-15',
        type: 'devoir',
        trimestre: 2,
      ),
      NoteModel(
        id: '6',
        childId: 'student1',
        subject: 'Physique',
        value: 15.5,
        maxNote: 20.0,
        coefficient: '2',
        date: '2024-03-16',
        type: 'interrogation',
        trimestre: 2,
      ),
    ];

    // Calculer la moyenne générale
    if (notes.isNotEmpty) {
      double total = 0.0;
      double totalCoeff = 0.0;
      for (var note in notes) {
        total += note.value * double.parse(note.coefficient);
        totalCoeff += double.parse(note.coefficient);
      }
      moyenneGenerale.value = totalCoeff > 0 ? total / totalCoeff : 0.0;
    }

    // Calculer les moyennes par trimestre
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

    // Calculer la moyenne la plus récente (trimestre le plus élevé avec des notes)
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
    }

    _loadMockSecondaryData();
  }

  void _loadMockSecondaryData() {
    // Charger l'emploi du temps
    emploiDuTemps.value = [
      EmploiModel(
        id: '1',
        childId: 'student1',
        dayOfWeek: 'Lundi',
        startTime: '08:00',
        endTime: '10:00',
        subject: 'Mathématiques',
        teacher: 'M. Dupont',
        classroom: 'Salle 101',
        type: 'Cours',
      ),
      EmploiModel(
        id: '2',
        childId: 'student1',
        dayOfWeek: 'Lundi',
        startTime: '10:15',
        endTime: '12:15',
        subject: 'Physique',
        teacher: 'Mme. Martin',
        classroom: 'Labo 1',
        type: 'TP',
      ),
      EmploiModel(
        id: '3',
        childId: 'student1',
        dayOfWeek: 'Mardi',
        startTime: '08:00',
        endTime: '10:00',
        subject: 'Français',
        teacher: 'M. Lefebvre',
        classroom: 'Salle 102',
        type: 'Cours',
      ),
      EmploiModel(
        id: '4',
        childId: 'student1',
        dayOfWeek: 'Mardi',
        startTime: '10:15',
        endTime: '12:15',
        subject: 'Histoire',
        teacher: 'Mme. Bernard',
        classroom: 'Salle 103',
        type: 'Cours',
      ),
      EmploiModel(
        id: '5',
        childId: 'student1',
        dayOfWeek: 'Mercredi',
        startTime: '08:00',
        endTime: '10:00',
        subject: 'Anglais',
        teacher: 'M. Smith',
        classroom: 'Salle 104',
        type: 'Cours',
      ),
      EmploiModel(
        id: '6',
        childId: 'student1',
        dayOfWeek: 'Jeudi',
        startTime: '08:00',
        endTime: '10:00',
        subject: 'Mathématiques',
        teacher: 'M. Dupont',
        classroom: 'Salle 101',
        type: 'TD',
      ),
      EmploiModel(
        id: '7',
        childId: 'student1',
        dayOfWeek: 'Vendredi',
        startTime: '08:00',
        endTime: '10:00',
        subject: 'EPS',
        teacher: 'M. Durand',
        classroom: 'Gymnase',
        type: 'Sport',
      ),
    ];

    // Charger les absences
    absences.value = [
      AbsenceModel(
        id: '1',
        childId: 'student1',
        date: '2024-01-20',
        reason: 'Maladie',
        type: 'Maladie',
        justification: 'Certificat médical',
        justified: true,
        subject: 'Mathématiques',
      ),
      AbsenceModel(
        id: '2',
        childId: 'student1',
        date: '2024-02-15',
        reason: 'Raison familiale',
        type: 'Familiale',
        justification: 'Demande des parents',
        justified: true,
        subject: 'Français',
      ),
      AbsenceModel(
        id: '3',
        childId: 'student1',
        date: '2024-03-10',
        reason: 'Non justifié',
        type: 'Non justifiée',
        justification: null,
        justified: false,
        subject: 'Physique',
      ),
    ];

    // Charger les notifications
    notifications.value = [
      NotificationModel(
        id: '1',
        title: 'Nouvelle note ajoutée',
        message: 'Votre note de mathématiques a été ajoutée: 17/20',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        type: 'success',
        isRead: false,
      ),
      NotificationModel(
        id: '2',
        title: 'Rappel de devoir',
        message:
            'N\'oubliez pas de rendre votre devoir de français pour demain',
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        type: 'info',
        isRead: false,
      ),
      NotificationModel(
        id: '3',
        title: 'Absence signalée',
        message: 'Une absence a été signalée pour le cours de physique',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        type: 'warning',
        isRead: true,
      ),
      NotificationModel(
        id: '4',
        title: 'Bulletin disponible',
        message: 'Votre bulletin trimestriel est maintenant disponible',
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
        type: 'success',
        isRead: true,
      ),
    ];

    // Calculer le nombre de notifications non lues
    unreadCount.value = notifications.where((n) => !n.isRead).length;
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

  Future<void> logout() async {
    try {
      await StorageService.logout();
      final authController = Get.find<AuthController>();
      authController.logout();
    } catch (e) {
      Get.offAllNamed('/auth');
    }
  }
}
