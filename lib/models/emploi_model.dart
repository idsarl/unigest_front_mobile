class EmploiModel {
  final String id;
  final String childId;
  final String dayOfWeek; // 'lundi', 'mardi', etc.
  final String startTime;
  final String endTime;
  final String subject;
  final String teacher;
  final String classroom;
  final String type; // 'cours', 'td', 'tp'

  EmploiModel({
    required this.id,
    required this.childId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.subject,
    required this.teacher,
    required this.classroom,
    required this.type,
  });

  factory EmploiModel.fromJson(Map<String, dynamic> json) {
    return EmploiModel(
      id: json['id'] ?? '',
      childId: json['childId'] ?? '',
      dayOfWeek: json['dayOfWeek'] ?? '',
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      subject: json['subject'] ?? '',
      teacher: json['teacher'] ?? '',
      classroom: json['classroom'] ?? '',
      type: json['type'] ?? 'cours',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'childId': childId,
      'dayOfWeek': dayOfWeek,
      'startTime': startTime,
      'endTime': endTime,
      'subject': subject,
      'teacher': teacher,
      'classroom': classroom,
      'type': type,
    };
  }

  String get formattedTime => '$startTime - $endTime';
  
  String get displayType {
    switch (type) {
      case 'cours':
        return 'Cours';
      case 'td':
        return 'TD';
      case 'tp':
        return 'TP';
      default:
        return 'Cours';
    }
  }
}
