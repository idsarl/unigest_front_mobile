import 'package:get/get.dart';
import '../../../core/state_management/getx_helpers.dart';
import '../../../core/services/parent_service.dart';
import '../../../core/services/notes_service.dart';
import '../../../core/services/absences_service.dart';
import '../../../models/child_model.dart';
import '../../../models/note_model.dart';
import '../../../models/absence_model.dart';
import '../../auth/controllers/auth_controller.dart';

class ParentHomeController extends BaseController {
  final RxList<ChildModel> children = <ChildModel>[].obs;
  final RxMap<String, double> childAverages = <String, double>{}.obs;
  final RxMap<String, int> childAbsences = <String, int>{}.obs;

  int get childrenCount => children.length;

  int get totalAbsences =>
      childAbsences.values.fold(0, (sum, value) => sum + value);

  double get globalAverage {
    final averages = childAverages.values.where((value) => value > 0).toList();
    if (averages.isEmpty) return 0.0;
    final total = averages.fold(0.0, (sum, value) => sum + value);
    return double.parse((total / averages.length).toStringAsFixed(2));
  }

  ChildModel? get childToWatch {
    if (children.isEmpty) return null;

    ChildModel? selected;
    int highestAbsences = -1;

    for (final child in children) {
      final absences = childAbsences[child.id] ?? 0;
      if (absences > highestAbsences) {
        highestAbsences = absences;
        selected = child;
      }
    }

    return highestAbsences > 0 ? selected : null;
  }

  @override
  void onInit() {
    super.onInit();
    loadChildren();
  }

  Future<void> loadChildren() async {
    setLoading(true);
    try {
      final authController = Get.find<AuthController>();
      final parentId = authController.userId.value;

      if (parentId != 0) {
        final list = await ParentService.getChildren(parentId);
        children.value = list;

        // Calculer dynamiquement les moyennes et absences réelles pour chaque enfant en parallèle
        final List<Future> calculations = [];

        for (var child in list) {
          final childIdVal = int.tryParse(child.id) ?? 0;
          if (childIdVal != 0) {
            // Calculer la moyenne réelle et les absences en parallèle pour chaque enfant
            calculations.add(_calculateChildStats(childIdVal, child.id));
          }
        }

        // Attendre que tous les calculs soient terminés
        await Future.wait(calculations);
      }
      clearError();
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  Future<void> _calculateChildStats(int childIdVal, String childId) async {
    try {
      // Charger les notes et absences en parallèle
      final results = await Future.wait([
        NotesService.getNotesByStudentId(childIdVal),
        AbsencesService.getAbsencesByStudentId(childIdVal),
      ]);

      final notesList = results[0] as List<NoteModel>;
      final absencesList = results[1] as List<AbsenceModel>;

      // Calculer la moyenne
      if (notesList.isNotEmpty) {
        double total = 0.0;
        double totalCoeff = 0.0;
        for (var note in notesList) {
          final coeff = double.tryParse(note.coefficient) ?? 1.0;
          total += note.value * coeff;
          totalCoeff += coeff;
        }
        childAverages[childId] = totalCoeff > 0
            ? double.parse((total / totalCoeff).toStringAsFixed(2))
            : 0.0;
      } else {
        childAverages[childId] = 0.0;
      }

      // Calculer le nombre d'absences
      childAbsences[childId] =
          absencesList.where((a) => a.type == 'absence').length;
    } catch (e) {
      childAverages[childId] = 0.0;
      childAbsences[childId] = 0;
    }
  }

  void viewChildDetails(ChildModel child) {
    Get.toNamed('/child-details', arguments: child);
  }

  @override
  Future<void> retry() => loadChildren();
}
