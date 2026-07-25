import 'etudiant.dart';

class AppelModel {
  final int id;
  final int seanceId;
  final EtudiantModel etudiant;
  String statut; // PRESENT | ABSENT | RETARD
  int minutesRetard;
  String? motif;
  final bool justifie;

  AppelModel({
    required this.id,
    required this.seanceId,
    required this.etudiant,
    required this.statut,
    this.minutesRetard = 0,
    this.motif,
    this.justifie = false,
  });

  factory AppelModel.fromJson(Map<String, dynamic> json) => AppelModel(
        id: json['id'] as int,
        seanceId: (json['seance'] as Map<String, dynamic>)['id'] as int,
        etudiant: EtudiantModel.fromJson(json['etudiant'] as Map<String, dynamic>),
        statut: json['statut'] ?? 'PRESENT',
        minutesRetard: json['minutesRetard'] as int? ?? 0,
        motif: json['motif'],
        justifie: json['justifie'] as bool? ?? false,
      );
}

class AppelEntry {
  final int etudiantId;
  String statut;
  int minutesRetard;
  String? motif;

  AppelEntry({
    required this.etudiantId,
    this.statut = 'PRESENT',
    this.minutesRetard = 0,
    this.motif,
  });

  Map<String, dynamic> toJson() => {
        'etudiantId': etudiantId,
        'statut': statut,
        'minutesRetard': minutesRetard,
        'motif': motif,
      };
}
