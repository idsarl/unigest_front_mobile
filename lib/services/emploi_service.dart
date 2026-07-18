import 'api_service.dart';

class EmploiModel {
  final int id;
  final String matiereNom;
  final String classeNom;
  final String heureDebut;
  final String heureFin;
  final String couleur;
  final List<String> jours;
  final String type;
  final bool actif;

  EmploiModel({
    required this.id,
    required this.matiereNom,
    required this.classeNom,
    required this.heureDebut,
    required this.heureFin,
    required this.couleur,
    required this.jours,
    required this.type,
    required this.actif,
  });

  factory EmploiModel.fromJson(Map<String, dynamic> json) {
    final matiere = json['matiere'] as Map<String, dynamic>? ?? {};
    final classe = json['classe'] as Map<String, dynamic>? ?? {};
    final joursRaw = json['jours'] as List<dynamic>? ?? [];

    String formatTime(dynamic t) {
      if (t == null) return '';
      final s = t.toString();
      if (s.length >= 5) return s.substring(0, 5);
      return s;
    }

    return EmploiModel(
      id: json['id'] as int,
      matiereNom: matiere['nom'] as String? ?? '',
      classeNom: classe['nom'] as String? ?? '',
      heureDebut: formatTime(json['heureDebut']),
      heureFin: formatTime(json['heureFin']),
      couleur: json['couleur'] as String? ?? '#4F46E5',
      jours: joursRaw.map((j) => j.toString()).toList(),
      type: json['type']?.toString() ?? 'COURS',
      actif: json['actif'] as bool? ?? true,
    );
  }
}

class EmploiService {
  final ApiService api;
  EmploiService({required this.api});

  Future<List<EmploiModel>> getEmploisParDate(
      int enseignantId, String date) async {
    final data = await api.get(
      '/api/emplois-du-temps/enseignant/$enseignantId/date',
      params: {'date': date},
    );
    return (data as List<dynamic>)
        .map((e) => EmploiModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<EmploiModel>> getEmploisSemaine(
      int enseignantId, String dateDebut) async {
    // Load 5 days (Mon–Fri) in parallel
    final days = List.generate(5, (i) {
      final d = DateTime.parse(dateDebut).add(Duration(days: i));
      return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    });

    // Get all unique emplois from the week
    final results = await Future.wait(
      days.map((d) => getEmploisParDate(enseignantId, d)),
    );

    // Deduplicate by id
    final seen = <int>{};
    final all = <EmploiModel>[];
    for (final list in results) {
      for (final e in list) {
        if (seen.add(e.id)) all.add(e);
      }
    }
    return all;
  }
}
