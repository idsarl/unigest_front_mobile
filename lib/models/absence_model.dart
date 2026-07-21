class AbsenceModel {
  final String id;
  final String childId;
  final String date;
  final String reason;
  final String type; // 'absence', 'retard'
  final String? justification;
  final bool justified;
  final String subject;

  AbsenceModel({
    required this.id,
    required this.childId,
    required this.date,
    required this.reason,
    required this.type,
    this.justification,
    this.justified = false,
    required this.subject,
  });

  factory AbsenceModel.fromJson(Map<String, dynamic> json) {
    return AbsenceModel(
      id: json['id'] ?? '',
      childId: json['childId'] ?? '',
      date: json['date'] ?? '',
      reason: json['reason'] ?? '',
      type: json['type'] ?? 'absence',
      justification: json['justification'],
      justified: json['justified'] ?? false,
      subject: json['subject'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'childId': childId,
      'date': date,
      'reason': reason,
      'type': type,
      'justification': justification,
      'justified': justified,
      'subject': subject,
    };
  }

  String get displayType => type == 'absence' ? 'Absence' : 'Retard';
  
  String get status => justified ? 'Justifié' : 'Non justifié';
}
