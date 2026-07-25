class User {
  final String id;
  final String nom;
  final String prenom;
  final String role;
  final String? enseignantId;

  User({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.role,
    this.enseignantId,
  });

  String get fullName => '$prenom $nom';
  bool get isEnseignant => role == 'ENSEIGNANT';
  bool get isAdmin => role == 'ADMIN';
  bool get isComptable => role == 'COMPTABLE';

  factory User.fromLoginResponse(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      role: json['role'] ?? '',
      enseignantId: json['enseignantId']?.toString(),
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      role: json['role'] ?? '',
      enseignantId: json['enseignantId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nom': nom,
        'prenom': prenom,
        'role': role,
        'enseignantId': enseignantId,
      };
}
