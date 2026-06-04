import 'package:get/get.dart';
import '../services/teacher_repository.dart';

class ScheduleController extends GetxController {
  final TeacherRepository _repo = TeacherRepository();

  final RxBool isLoading = true.obs;
  final RxString error = ''.obs;
  final Rx<DateTime> selectedDate = DateTime.now().obs;
  final RxList<Map<String, dynamic>> seances = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> weekSeances = <Map<String, dynamic>>[].obs;
  final RxMap<int, int> classStudentCounts = <int, int>{}.obs;

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  Future<void> loadData() async {
    await loadAffectationsAndClassCounts();
    await loadSeances();
    await loadWeekSeances();
  }

  Future<void> loadAffectationsAndClassCounts() async {
    try {
      final affectations = await _repo.getAffectations();
      for (final aff in affectations) {
        final map = Map<String, dynamic>.from(aff as Map);
        final classeId = int.tryParse(map['classe']?['id']?.toString() ?? '');
        if (classeId != null) {
          final students = await _repo.getEtudiantsClasse(classeId);
          classStudentCounts[classeId] = students.length;
        }
      }
    } catch (_) {}
  }

  Future<void> loadSeances() async {
    isLoading.value = true;
    error.value = '';
    try {
      final date = selectedDate.value;
      final raw = await _repo.getSeancesParDate(date);

      seances.assignAll(raw.map((s) {
        final map = Map<String, dynamic>.from(s as Map);
        final classeId = int.tryParse(map['classeId']?.toString() ?? '');
        return {
          'id': map['id'],
          'matiere': map['matiere']?.toString() ?? 'Cours',
          'classe': map['classe']?.toString() ?? '',
          'classeId': classeId,
          'heureDebut': map['heureDebut']?.toString() ?? '',
          'heureFin': map['heureFin']?.toString() ?? '',
          'statut': _statutLabel(map['statut']?.toString()),
          'statutRaw': map['statut']?.toString(),
          'color': _statutColor(map['statut']?.toString()),
        };
      }).toList()
        ..sort((a, b) =>
            (a['heureDebut'] as String).compareTo(b['heureDebut'] as String)));
    } catch (e) {
      error.value = 'Erreur chargement emploi du temps : $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadWeekSeances() async {
    try {
      final start = selectedDate.value.subtract(Duration(days: selectedDate.value.weekday - 1));
      final List<Map<String, dynamic>> allWeek = [];
      for (int i = 0; i < 7; i++) {
        final day = start.add(Duration(days: i));
        final raw = await _repo.getSeancesParDate(day);
        for (final s in raw) {
          final map = Map<String, dynamic>.from(s as Map);
          final classeId = int.tryParse(map['classeId']?.toString() ?? '');
          allWeek.add({
            'id': map['id'],
            'matiere': map['matiere']?.toString() ?? 'Cours',
            'classe': map['classe']?.toString() ?? '',
            'classeId': classeId,
            'heureDebut': map['heureDebut']?.toString() ?? '',
            'heureFin': map['heureFin']?.toString() ?? '',
            'statut': _statutLabel(map['statut']?.toString()),
            'statutRaw': map['statut']?.toString(),
            'color': _statutColor(map['statut']?.toString()),
          });
        }
      }
      weekSeances.assignAll(allWeek);
    } catch (_) {}
  }

  void selectDate(DateTime date) {
    selectedDate.value = date;
    loadSeances();
  }

  void previousWeek() {
    selectedDate.value = selectedDate.value.subtract(const Duration(days: 7));
    loadData();
  }

  void nextWeek() {
    selectedDate.value = selectedDate.value.add(const Duration(days: 7));
    loadData();
  }

  int get totalStudents {
    int total = 0;
    final processedClasses = <int>{};
    for (final s in weekSeances) {
      final classeId = s['classeId'] as int?;
      if (classeId != null && !processedClasses.contains(classeId)) {
        total += classStudentCounts[classeId] ?? 0;
        processedClasses.add(classeId);
      }
    }
    if (total == 0) {
      for (final s in seances) {
        final classeId = s['classeId'] as int?;
        if (classeId != null && !processedClasses.contains(classeId)) {
          total += classStudentCounts[classeId] ?? 0;
          processedClasses.add(classeId);
        }
      }
    }
    return total;
  }

  int get dayTotalSeances {
    return seances.length;
  }

  int get dayTotalStudents {
    int total = 0;
    final processedClasses = <int>{};
    for (final s in seances) {
      final classeId = s['classeId'] as int?;
      if (classeId != null && !processedClasses.contains(classeId)) {
        total += classStudentCounts[classeId] ?? 0;
        processedClasses.add(classeId);
      }
    }
    return total;
  }

  int get dayTotalDurationMinutes {
    int total = 0;
    for (final s in seances) {
      final start = s['heureDebut'] as String?;
      final end = s['heureFin'] as String?;
      if (start != null && end != null) {
        try {
          final p1 = start.split(':');
          final p2 = end.split(':');
          final h1 = int.parse(p1[0]);
          final m1 = int.parse(p1[1]);
          final h2 = int.parse(p2[0]);
          final m2 = int.parse(p2[1]);
          total += (h2 * 60 + m2) - (h1 * 60 + m1);
        } catch (_) {}
      }
    }
    return total;
  }

  int get totalWeekSeances {
    return weekSeances.length;
  }

  int get totalWeekDurationMinutes {
    int total = 0;
    for (final s in weekSeances) {
      final start = s['heureDebut'] as String?;
      final end = s['heureFin'] as String?;
      if (start != null && end != null) {
        try {
          final p1 = start.split(':');
          final p2 = end.split(':');
          final h1 = int.parse(p1[0]);
          final m1 = int.parse(p1[1]);
          final h2 = int.parse(p2[0]);
          final m2 = int.parse(p2[1]);
          total += (h2 * 60 + m2) - (h1 * 60 + m1);
        } catch (_) {}
      }
    }
    if (total == 0) {
      for (final s in seances) {
        final start = s['heureDebut'] as String?;
        final end = s['heureFin'] as String?;
        if (start != null && end != null) {
          try {
            final p1 = start.split(':');
            final p2 = end.split(':');
            final h1 = int.parse(p1[0]);
            final m1 = int.parse(p1[1]);
            final h2 = int.parse(p2[0]);
            final m2 = int.parse(p2[1]);
            total += (h2 * 60 + m2) - (h1 * 60 + m1);
          } catch (_) {}
        }
      }
    }
    return total;
  }

  String get weekLabel {
    final d = selectedDate.value;
    final start = d.subtract(Duration(days: d.weekday - 1));
    return 'Semaine du ${start.day} ${_monthShort(start.month)}';
  }

  String get dayProgramLabel {
    final d = selectedDate.value;
    const days = ['LUNDI', 'MARDI', 'MERCREDI', 'JEUDI', 'VENDREDI', 'SAMEDI', 'DIMANCHE'];
    return '${days[d.weekday - 1]} ${d.day} ${_monthShort(d.month).toUpperCase()}';
  }

  String _monthShort(int m) {
    const mois = [
      'jan', 'fév', 'mars', 'avr', 'mai', 'juin',
      'juil', 'août', 'sept', 'oct', 'nov', 'déc'
    ];
    return mois[m - 1];
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _statutLabel(String? raw) {
    switch (raw) {
      case 'TERMINEE':
        return 'Terminé';
      case 'EN_COURS':
        return 'En cours';
      case 'PLANIFIEE':
        return 'A venir';
      default:
        return raw ?? '—';
    }
  }

  String _statutColor(String? raw) {
    switch (raw) {
      case 'TERMINEE':
        return 'green';
      case 'EN_COURS':
        return 'blue';
      default:
        return 'orange';
    }
  }
}
