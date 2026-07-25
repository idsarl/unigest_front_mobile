class SeanceModel {
  final int id;
  final int affectationId;
  final String matiere;
  final String professeur;
  final String classe;
  final int classeId;
  final String filiere;
  final String heureDebut;
  final String heureFin;
  String statut;

  SeanceModel({
    required this.id,
    required this.affectationId,
    required this.matiere,
    required this.professeur,
    required this.classe,
    required this.classeId,
    required this.filiere,
    required this.heureDebut,
    required this.heureFin,
    required this.statut,
  });

  bool get isPlanifiee => statut == 'PLANIFIEE';
  bool get isEnCours => statut == 'EN_COURS';
  bool get isTerminee => statut == 'TERMINEE';

  factory SeanceModel.fromJson(Map<String, dynamic> json) => SeanceModel(
        id: json['id'] as int,
        affectationId: json['affectationId'] as int,
        matiere: json['matiere'] ?? '',
        professeur: json['professeur'] ?? '',
        classe: json['classe'] ?? '',
        classeId: json['classeId'] as int? ?? 0,
        filiere: json['filiere'] ?? '',
        heureDebut: json['heureDebut'] ?? '',
        heureFin: json['heureFin'] ?? '',
        statut: json['statut'] ?? 'PLANIFIEE',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'affectationId': affectationId,
        'matiere': matiere,
        'professeur': professeur,
        'classe': classe,
        'classeId': classeId,
        'filiere': filiere,
        'heureDebut': heureDebut,
        'heureFin': heureFin,
        'statut': statut,
      };

  SeanceModel copyWith({String? statut}) => SeanceModel(
        id: id,
        affectationId: affectationId,
        matiere: matiere,
        professeur: professeur,
        classe: classe,
        classeId: classeId,
        filiere: filiere,
        heureDebut: heureDebut,
        heureFin: heureFin,
        statut: statut ?? this.statut,
      );
}
