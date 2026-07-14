import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/state_management/getx_helpers.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/notes_service.dart';
import '../../../core/services/absences_service.dart';
import '../../../core/services/emploi_service.dart';
import '../../../core/services/messages_service.dart';
import '../../../models/child_model.dart';
import '../../../models/note_model.dart';
import '../../../models/absence_model.dart';
import '../../../models/emploi_model.dart';
import '../../../models/message_model.dart';
import '../../../models/teacher_model.dart';
import '../../auth/controllers/auth_controller.dart';

class ChildDetailsController extends BaseController
    with GetTickerProviderStateMixin {
  final Rx<ChildModel?> child = Rx<ChildModel?>(null);
  final RxInt selectedTab = 0.obs;
  final RxList<NoteModel> notes = <NoteModel>[].obs;
  final RxDouble generalAverage = 0.0.obs;
  final RxList<AbsenceModel> absences = <AbsenceModel>[].obs;
  final RxList<EmploiModel> emploiDuTemps = <EmploiModel>[].obs;
  final RxList<MessageModel> messages = <MessageModel>[].obs;
  final RxList<TeacherModel> teachers = <TeacherModel>[].obs;
  final Rx<TeacherModel?> selectedTeacher = Rx<TeacherModel?>(null);
  final RxString messageText = ''.obs;
  late TabController tabController;

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 4, vsync: this);
    if (Get.arguments != null) {
      child.value = Get.arguments as ChildModel;
      loadAllData();
    }
  }

  Future<void> loadAllData() async {
    setLoading(true);
    try {
      final childIdVal = int.tryParse(child.value?.id ?? '') ?? 0;
      final className = child.value?.className ?? '';
      final classId = int.tryParse(child.value?.classId ?? '');

      if (childIdVal != 0 && className.isNotEmpty) {
        // Charger les données en parallèle
        final results = await Future.wait([
          NotesService.getNotesByStudentId(childIdVal),
          AbsencesService.getAbsencesByStudentId(childIdVal),
          EmploiService.getEmploiDuTemps(
            className,
            childIdVal,
            classId: classId,
          ),
        ]);

        notes.value = results[0] as List<NoteModel>;
        absences.value = results[1] as List<AbsenceModel>;
        emploiDuTemps.value = results[2] as List<EmploiModel>;

        // Calculer la moyenne générale
        if (notes.isNotEmpty) {
          double total = 0.0;
          double totalCoeff = 0.0;
          for (var note in notes) {
            final coeff = double.tryParse(note.coefficient) ?? 1.0;
            total += note.value * coeff;
            totalCoeff += coeff;
          }
          generalAverage.value = totalCoeff > 0
              ? double.parse((total / totalCoeff).toStringAsFixed(2))
              : 0.0;
        } else {
          generalAverage.value = 0.0;
        }
      }

      // Charger les enseignants séparément
      loadTeachers();

      clearError();
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  @override
  void onClose() {
    tabController.dispose();
    super.onClose();
  }

  Future<void> loadNotes() async {
    setLoading(true);
    try {
      final childIdVal = int.tryParse(child.value?.id ?? '') ?? 0;
      if (childIdVal != 0) {
        final list = await NotesService.getNotesByStudentId(childIdVal);
        notes.value = list;

        // Calculer la moyenne générale réelle
        if (list.isNotEmpty) {
          double total = 0.0;
          double totalCoeff = 0.0;
          for (var note in list) {
            final coeff = double.tryParse(note.coefficient) ?? 1.0;
            total += note.value * coeff;
            totalCoeff += coeff;
          }
          generalAverage.value = totalCoeff > 0
              ? double.parse((total / totalCoeff).toStringAsFixed(2))
              : 0.0;
        } else {
          generalAverage.value = 0.0;
        }
      }
      clearError();
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  Map<String, double> getSubjectAverages() {
    final Map<String, List<double>> subjectNotes = {};

    for (var note in notes) {
      if (!subjectNotes.containsKey(note.subject)) {
        subjectNotes[note.subject] = [];
      }
      subjectNotes[note.subject]!.add(note.value);
    }

    final Map<String, double> averages = {};
    subjectNotes.forEach((subject, values) {
      final sum = values.reduce((a, b) => a + b);
      averages[subject] =
          double.parse((sum / values.length).toStringAsFixed(2));
    });

    return averages;
  }

  Future<void> loadAbsences() async {
    setLoading(true);
    try {
      final childIdVal = int.tryParse(child.value?.id ?? '') ?? 0;
      if (childIdVal != 0) {
        absences.value =
            await AbsencesService.getAbsencesByStudentId(childIdVal);
      }
      clearError();
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  Future<void> loadEmploiDuTemps() async {
    setLoading(true);
    try {
      final childIdVal = int.tryParse(child.value?.id ?? '') ?? 0;
      final className = child.value?.className ?? '';
      final classId = int.tryParse(child.value?.classId ?? '');
      if (childIdVal != 0 && className.isNotEmpty) {
        emploiDuTemps.value = await EmploiService.getEmploiDuTemps(
          className,
          childIdVal,
          classId: classId,
        );
      }
      clearError();
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  Future<void> loadTeachers() async {
    setLoading(true);
    try {
      final response = await ApiService.get('/enseignants');
      if (response.statusCode == 200) {
        final List<dynamic> data = ApiService.decodeJson(response);
        teachers.value = data
            .map((json) => TeacherModel(
                  id: json['id']?.toString() ?? '',
                  firstName: json['prenom'] ?? '',
                  lastName: json['nom'] ?? '',
                  subject: json['specialite'] ?? 'Matière',
                  email: json['email'] ?? '',
                ))
            .toList();
      }
      clearError();
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  Future<void> loadMessages() async {
    setLoading(true);
    try {
      final authController = Get.find<AuthController>();
      final parentId = authController.userId.value;
      final teacherIdVal = int.tryParse(selectedTeacher.value?.id ?? '') ?? 0;

      if (parentId != 0 && teacherIdVal != 0) {
        messages.value =
            await MessagesService.getMessages(parentId, teacherIdVal);
      }
      clearError();
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  void selectTeacher(TeacherModel? teacher) {
    selectedTeacher.value = teacher;
    if (teacher != null) {
      loadMessages();
    }
  }

  Future<void> sendMessage() async {
    if (messageText.value.trim().isEmpty || selectedTeacher.value == null) {
      return;
    }

    try {
      final authController = Get.find<AuthController>();
      final parentId = authController.userId.value;
      final teacherIdVal = int.tryParse(selectedTeacher.value?.id ?? '') ?? 0;
      final content = messageText.value.trim();

      if (parentId != 0 && teacherIdVal != 0) {
        final sentMessage =
            await MessagesService.sendMessage(parentId, teacherIdVal, content);
        messages.add(sentMessage);
        messageText.value = '';
      }
    } catch (e) {
      setError(e.toString());
    }
  }
}
