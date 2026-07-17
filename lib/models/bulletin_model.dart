class LigneBulletinModel {
  final int id;
  final String matiere;
  final double noteClasse;
  final double noteComposition;
  final double quotaClasse;
  final double quotaComposition;
  final double moyenneMatiere;
  final double coefficient;
  final String? appreciation;

  LigneBulletinModel({
    required this.id,
    required this.matiere,
    required this.noteClasse,
    required this.noteComposition,
    required this.quotaClasse,
    required this.quotaComposition,
    required this.moyenneMatiere,
    required this.coefficient,
    this.appreciation,
  });

  factory LigneBulletinModel.fromJson(Map<String, dynamic> json) {
    final matiere = json['matiere'] ?? {};
    return LigneBulletinModel(
      id: json['id'] ?? 0,
      matiere: matiere['nom']?.toString() ??
          matiere['libelle']?.toString() ??
          'Matière',
      noteClasse: (json['noteClasse'] ?? 0).toDouble(),
      noteComposition: (json['noteComposition'] ?? 0).toDouble(),
      quotaClasse: (json['quotaClasse'] ?? 0).toDouble(),
      quotaComposition: (json['quotaComposition'] ?? 0).toDouble(),
      moyenneMatiere: (json['moyenneMatiere'] ?? 0).toDouble(),
      coefficient: (json['coefficient'] ?? 1).toDouble(),
      appreciation: json['appreciation']?.toString(),
    );
  }
}

class BulletinModel {
  final int id;
  final int periode;
  final String typePeriode;
  final double moyenneGenerale;
  final int? rang;
  final String? appreciation;
  final double? noteConduite;
  final String? dateGeneration;
  final String anneeScolaire;
  final List<LigneBulletinModel> lignes;

  BulletinModel({
    required this.id,
    required this.periode,
    required this.typePeriode,
    required this.moyenneGenerale,
    this.rang,
    this.appreciation,
    this.noteConduite,
    this.dateGeneration,
    required this.anneeScolaire,
    required this.lignes,
  });

  factory BulletinModel.fromJson(Map<String, dynamic> json) {
    final annee = json['anneeScolaire'] ?? {};
    final lignesJson = json['lignes'] as List? ?? [];
    return BulletinModel(
      id: json['id'] ?? 0,
      periode: json['periode'] ?? 1,
      typePeriode: json['typePeriode']?.toString() ?? 'TRIMESTRE',
      moyenneGenerale: (json['moyenneGenerale'] ?? 0).toDouble(),
      rang: json['rang'] is int ? json['rang'] as int : null,
      appreciation: json['appreciation']?.toString(),
      noteConduite: json['noteConduite'] != null
          ? (json['noteConduite'] as num).toDouble()
          : null,
      dateGeneration: json['dateGeneration']?.toString(),
      anneeScolaire: annee['libelle']?.toString() ?? '',
      lignes:
          lignesJson.map((l) => LigneBulletinModel.fromJson(l)).toList(),
    );
  }

  String get periodeLabel {
    switch (typePeriode) {
      case 'SEMESTRE':
        return 'Semestre $periode';
      case 'COMPOSITION':
        return 'Composition $periode';
      case 'TRIMESTRE':
      default:
        return 'Trimestre $periode';
    }
  }
}
