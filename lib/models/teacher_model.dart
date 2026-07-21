class TeacherModel {
  final String id;
  final String firstName;
  final String lastName;
  final String subject;
  final String email;
  final String? photoUrl;

  TeacherModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.subject,
    required this.email,
    this.photoUrl,
  });

  factory TeacherModel.fromJson(Map<String, dynamic> json) {
    return TeacherModel(
      id: json['id'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      subject: json['subject'] as String,
      email: json['email'] as String,
      photoUrl: json['photoUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'subject': subject,
      'email': email,
      'photoUrl': photoUrl,
    };
  }

  String get fullName => '$firstName $lastName';
}
