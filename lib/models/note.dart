class NoteModel {
  final int id;
  final int etudiantId;
  final double valeur;
  final double coefficient;
  final String type;
  final int periode;
  final String typePeriode;
  final String? dateEvaluation;
  final int matiereId;
  final String matiereNom;

  NoteModel({
    required this.id,
    required this.etudiantId,
    required this.valeur,
    required this.coefficient,
    required this.type,
    required this.periode,
    required this.typePeriode,
    this.dateEvaluation,
    required this.matiereId,
    required this.matiereNom,
  });

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    final etudiant = json['etudiant'] as Map<String, dynamic>?;
    final matiere = json['matiere'] as Map<String, dynamic>?;
    return NoteModel(
      id: json['id'] as int,
      etudiantId: etudiant?['id'] as int? ?? 0,
      valeur: (json['valeur'] as num).toDouble(),
      coefficient: (json['coefficient'] as num).toDouble(),
      type: json['type']?.toString() ?? 'DEVOIR',
      periode: json['periode'] as int? ?? 1,
      typePeriode: json['typePeriode']?.toString() ?? 'SEMESTRE',
      dateEvaluation: json['dateEvaluation']?.toString(),
      matiereId: matiere?['id'] as int? ?? 0,
      matiereNom: matiere?['nom'] as String? ?? '',
    );
  }
}

class NoteBatchItem {
  final int etudiantId;
  final int affectationId;
  final int matiereId;
  final double valeur;
  final String type;
  final int periode;
  final String typePeriode;
  final String dateEvaluation;

  NoteBatchItem({
    required this.etudiantId,
    required this.affectationId,
    required this.matiereId,
    required this.valeur,
    required this.type,
    required this.periode,
    required this.typePeriode,
    required this.dateEvaluation,
  });

  Map<String, dynamic> toJson() => {
        'etudiantId': etudiantId,
        'affectationId': affectationId,
        'matiereId': matiereId,
        'valeur': valeur,
        'type': type,
        'periode': periode,
        'typePeriode': typePeriode,
        'dateEvaluation': dateEvaluation,
      };
}
