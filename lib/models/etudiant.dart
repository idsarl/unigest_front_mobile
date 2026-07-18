class EtudiantModel {
  final int id;
  final String nom;
  final String prenom;
  final String matricule;
  final String? email;
  final String? telephone;

  EtudiantModel({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.matricule,
    this.email,
    this.telephone,
  });

  String get fullName => '$prenom $nom';

  factory EtudiantModel.fromJson(Map<String, dynamic> json) => EtudiantModel(
        id: json['id'] as int,
        nom: json['nom'] ?? '',
        prenom: json['prenom'] ?? '',
        matricule: json['matricule'] ?? '',
        email: json['email'],
        telephone: json['telephone'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nom': nom,
        'prenom': prenom,
        'matricule': matricule,
        'email': email,
        'telephone': telephone,
      };
}
