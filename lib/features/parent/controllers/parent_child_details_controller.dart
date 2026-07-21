import 'package:get/get.dart';
import '../../../core/state_management/getx_helpers.dart';
import '../../../models/child_model.dart';
import '../../../models/note_model.dart';
import '../../../models/absence_model.dart';
import '../../../models/emploi_model.dart';
import '../../../models/message_model.dart';

class ParentChildDetailsController extends BaseController {
  final Rx<ChildModel?> child = Rx<ChildModel?>(null);
  final RxList<NoteModel> notes = <NoteModel>[].obs;
  final RxList<AbsenceModel> absences = <AbsenceModel>[].obs;
  final RxList<EmploiModel> emploiDuTemps = <EmploiModel>[].obs;
  final RxList<MessageModel> messages = <MessageModel>[].obs;
  final RxInt selectedTabIndex = 0.obs;
  final RxString selectedQuarter = '1'.obs;

  void setChild(ChildModel childModel) {
    child.value = childModel;
    loadChildData();
  }

  Future<void> loadChildData() async {
    setLoading(true);
    try {
      await Future.delayed(const Duration(seconds: 1));
      
      notes.value = [
        NoteModel(
          id: '1',
          childId: child.value?.id ?? '',
          subject: 'Mathématiques',
          value: 18,
          maxNote: 20,
          coefficient: '2',
          date: '15/05/2026',
          type: 'devoir',
          comment: 'Excellent travail',
          trimestre: 1,
        ),
        NoteModel(
          id: '2',
          childId: child.value?.id ?? '',
          subject: 'Français',
          value: 14,
          maxNote: 20,
          coefficient: '2',
          date: '12/05/2026',
          type: 'interrogation',
          trimestre: 1,
        ),
        NoteModel(
          id: '3',
          childId: child.value?.id ?? '',
          subject: 'Physique',
          value: 16,
          maxNote: 20,
          coefficient: '3',
          date: '10/05/2026',
          type: 'examen',
          trimestre: 1,
        ),
        NoteModel(
          id: '4',
          childId: child.value?.id ?? '',
          subject: 'Histoire-Géo',
          value: 13,
          maxNote: 20,
          coefficient: '1',
          date: '08/05/2026',
          type: 'devoir',
          trimestre: 1,
        ),
      ];
      
      absences.value = [
        AbsenceModel(
          id: '1',
          childId: child.value?.id ?? '',
          date: '12/05/2026',
          reason: 'Maladie',
          type: 'absence',
          justification: 'Certificat médical fourni',
          justified: true,
          subject: 'Mathématiques',
        ),
        AbsenceModel(
          id: '2',
          childId: child.value?.id ?? '',
          date: '05/05/2026',
          reason: 'Retard',
          type: 'retard',
          justification: null,
          justified: false,
          subject: 'Français',
        ),
      ];
      
      emploiDuTemps.value = [
        EmploiModel(
          id: '1',
          childId: child.value?.id ?? '',
          dayOfWeek: 'lundi',
          startTime: '08:00',
          endTime: '10:00',
          subject: 'Mathématiques',
          teacher: 'M. Dupont',
          classroom: 'Salle 101',
          type: 'cours',
        ),
        EmploiModel(
          id: '2',
          childId: child.value?.id ?? '',
          dayOfWeek: 'lundi',
          startTime: '10:15',
          endTime: '12:00',
          subject: 'Français',
          teacher: 'Mme Martin',
          classroom: 'Salle 102',
          type: 'cours',
        ),
        EmploiModel(
          id: '3',
          childId: child.value?.id ?? '',
          dayOfWeek: 'mardi',
          startTime: '08:00',
          endTime: '10:00',
          subject: 'Physique',
          teacher: 'M. Bernard',
          classroom: 'Labo 1',
          type: 'tp',
        ),
      ];
      
      messages.value = [
        MessageModel(
          id: '1',
          senderId: 'teacher1',
          receiverId: child.value?.id ?? '',
          content: 'Bonjour, concernant le devoir de mathématiques...',
          timestamp: DateTime.now().subtract(const Duration(hours: 3)),
          isRead: false,
          senderName: 'M. Dupont',
          receiverName: child.value?.fullName ?? '',
        ),
      ];
      
      clearError();
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  void changeTab(int index) {
    selectedTabIndex.value = index;
  }

  void changeQuarter(String quarter) {
    selectedQuarter.value = quarter;
  }

  double calculateAverage() {
    if (notes.isEmpty) return 0.0;
    double total = 0;
    double totalCoeff = 0;
    for (var note in notes) {
      final coeff = double.tryParse(note.coefficient) ?? 1;
      total += note.value * coeff;
      totalCoeff += coeff;
    }
    return totalCoeff > 0 ? total / totalCoeff : 0.0;
  }

  Map<String, double> calculateSubjectAverages() {
    final Map<String, List<NoteModel>> subjectNotes = {};
    for (var note in notes) {
      if (!subjectNotes.containsKey(note.subject)) {
        subjectNotes[note.subject] = [];
      }
      subjectNotes[note.subject]!.add(note);
    }
    
    final Map<String, double> averages = {};
    for (var entry in subjectNotes.entries) {
      double total = 0;
      double totalCoeff = 0;
      for (var note in entry.value) {
        final coeff = double.tryParse(note.coefficient) ?? 1;
        total += note.value * coeff;
        totalCoeff += coeff;
      }
      averages[entry.key] = totalCoeff > 0 ? total / totalCoeff : 0.0;
    }
    return averages;
  }
}
