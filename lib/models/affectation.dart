class MatiereModel {
  final int id;
  final String nom;

  MatiereModel({required this.id, required this.nom});

  factory MatiereModel.fromJson(Map<String, dynamic> json) =>
      MatiereModel(id: json['id'] as int, nom: json['nom'] ?? '');
}

class AffectationModel {
  final int id;
  final int enseignantId;
  final String enseignantNom;
  final int classeId;
  final String classeNom;
  final String filiereNom;
  final List<MatiereModel> matieres;

  AffectationModel({
    required this.id,
    required this.enseignantId,
    required this.enseignantNom,
    required this.classeId,
    required this.classeNom,
    required this.filiereNom,
    required this.matieres,
  });

  String get firstMatiere => matieres.isNotEmpty ? matieres.first.nom : '';
  int get firstMatiereId => matieres.isNotEmpty ? matieres.first.id : 0;

  factory AffectationModel.fromJson(Map<String, dynamic> json) {
    final enseignant = json['enseignant'] as Map<String, dynamic>? ?? {};
    final classe = json['classe'] as Map<String, dynamic>? ?? {};
    final filiere = classe['filiere'] as Map<String, dynamic>? ?? {};
    final matieresList = (json['matieres'] as List<dynamic>? ?? [])
        .map((m) => MatiereModel.fromJson(m as Map<String, dynamic>))
        .toList();

    return AffectationModel(
      id: json['id'] as int,
      enseignantId: enseignant['id'] as int? ?? 0,
      enseignantNom: '${enseignant['prenom'] ?? ''} ${enseignant['nom'] ?? ''}'.trim(),
      classeId: classe['id'] as int? ?? 0,
      classeNom: classe['nom'] as String? ?? '',
      filiereNom: filiere['nom'] as String? ?? '',
      matieres: matieresList,
    );
  }
}

class EnseignantDashboard {
  final int totalAffectations;
  final int seancesEffectuees;
  final int totalSeances;

  EnseignantDashboard({
    required this.totalAffectations,
    required this.seancesEffectuees,
    required this.totalSeances,
  });

  factory EnseignantDashboard.fromJson(Map<String, dynamic> json) =>
      EnseignantDashboard(
        totalAffectations: json['totalAffectations'] as int? ?? 0,
        seancesEffectuees: json['seancesEffectuees'] as int? ?? 0,
        totalSeances: json['totalSeances'] as int? ?? 0,
      );
}
