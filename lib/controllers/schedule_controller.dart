import 'package:get/get.dart';
import '../services/teacher_repository.dart';

class ScheduleController extends GetxController {
  final TeacherRepository _repo = TeacherRepository.instance;

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
    await loadSeances();
    await loadWeekSeances();
    await loadClassCountsFromSeances();
  }

  Future<void> loadClassCountsFromSeances() async {
    final classesToFetch = <int>{};
    for (final s in seances) {
      final cId = s['classeId'] as int?;
      if (cId != null) classesToFetch.add(cId);
    }
    for (final s in weekSeances) {
      final cId = s['classeId'] as int?;
      if (cId != null) classesToFetch.add(cId);
    }

    bool added = false;
    for (final classeId in classesToFetch) {
      if (!classStudentCounts.containsKey(classeId)) {
        try {
          final students = await _repo.getEtudiantsClasse(classeId);
          classStudentCounts[classeId] = students.length;
          added = true;
        } catch (_) {}
      }
    }
    
    // Forcer la mise à jour des observateurs si de nouvelles classes ont été chargées
    if (added) {
      classStudentCounts.refresh();
    }
  }

  Future<void> loadSeances() async {
    isLoading.value = true;
    error.value = '';
    try {
      final date = selectedDate.value;
      final raw = await _repo.getEmploisDuTempsParDate(date);

      seances.assignAll(raw.map((s) {
        final map = Map<String, dynamic>.from(s as Map);
        final emploiMap = map['emploiDuTemps'] as Map? ?? map;
        final classeMap = emploiMap['classe'] as Map?;
        final matiereMap = emploiMap['matiere'] as Map?;
        final classeId = classeMap != null ? int.tryParse(classeMap['id']?.toString() ?? '') : null;
        
        final statutLocal = _calculateStatus(date, emploiMap['heureDebut']?.toString(), emploiMap['heureFin']?.toString());

        return {
          'id': emploiMap['id'],
          'matiere': matiereMap != null ? (matiereMap['nom']?.toString() ?? 'Cours') : 'Cours',
          'classe': classeMap != null ? (classeMap['nom']?.toString() ?? '') : '',
          'classeId': classeId,
          'heureDebut': emploiMap['heureDebut']?.toString() ?? '',
          'heureFin': emploiMap['heureFin']?.toString() ?? '',
          'statut': _statutLabel(statutLocal),
          'statutRaw': statutLocal,
          'color': _statutColor(statutLocal),
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
        final raw = await _repo.getEmploisDuTempsParDate(day);
        for (final s in raw) {
          final map = Map<String, dynamic>.from(s as Map);
          final emploiMap = map['emploiDuTemps'] as Map? ?? map;
          final classeMap = emploiMap['classe'] as Map?;
          final matiereMap = emploiMap['matiere'] as Map?;
          final classeId = classeMap != null ? int.tryParse(classeMap['id']?.toString() ?? '') : null;
          
          final statutLocal = _calculateStatus(day, emploiMap['heureDebut']?.toString(), emploiMap['heureFin']?.toString());

          allWeek.add({
            'id': emploiMap['id'],
            'matiere': matiereMap != null ? (matiereMap['nom']?.toString() ?? 'Cours') : 'Cours',
            'classe': classeMap != null ? (classeMap['nom']?.toString() ?? '') : '',
            'classeId': classeId,
            'heureDebut': emploiMap['heureDebut']?.toString() ?? '',
            'heureFin': emploiMap['heureFin']?.toString() ?? '',
            'statut': _statutLabel(statutLocal),
            'statutRaw': statutLocal,
            'color': _statutColor(statutLocal),
          });
        }
      }
      weekSeances.assignAll(allWeek);
    } catch (_) {}
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
