class NoteModel {
  final String id;
  final String childId;
  final String subject;
  final double value;
  final double maxNote;
  final String coefficient;
  final String date;
  final String type; // 'devoir', 'interrogation', 'examen'
  final String? comment;
  final int trimestre; // 1, 2, or 3

  NoteModel({
    required this.id,
    required this.childId,
    required this.subject,
    required this.value,
    required this.maxNote,
    required this.coefficient,
    required this.date,
    required this.type,
    this.comment,
    required this.trimestre,
  });

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    return NoteModel(
      id: json['id'] ?? '',
      childId: json['childId'] ?? '',
      subject: json['subject'] ?? '',
      value: (json['value'] ?? 0).toDouble(),
      maxNote: (json['maxNote'] ?? 20).toDouble(),
      coefficient: json['coefficient']?.toString() ?? '1',
      date: json['date'] ?? '',
      type: json['type'] ?? 'devoir',
      comment: json['comment'],
      trimestre: json['trimestre'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'childId': childId,
      'subject': subject,
      'value': value,
      'maxNote': maxNote,
      'coefficient': coefficient,
      'date': date,
      'type': type,
      'comment': comment,
      'trimestre': trimestre,
    };
  }

  double get percentage => (value / maxNote) * 100;
  
  String get formattedValue => '$value/$maxNote';
}
