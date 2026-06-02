class ChildModel {
  final String id;
  final String firstName;
  final String lastName;
  final String birthDate;
  final String className;
  final String photoUrl;
  final List<String> parentIds;

  ChildModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.birthDate,
    required this.className,
    this.photoUrl = '',
    required this.parentIds,
  });

  factory ChildModel.fromJson(Map<String, dynamic> json) {
    return ChildModel(
      id: json['id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      birthDate: json['birthDate'] ?? '',
      className: json['className'] ?? '',
      photoUrl: json['photoUrl'] ?? '',
      parentIds: List<String>.from(json['parentIds'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'birthDate': birthDate,
      'className': className,
      'photoUrl': photoUrl,
      'parentIds': parentIds,
    };
  }

  String get fullName => '$firstName $lastName';
}
