class NotificationModel {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final String type; // 'info', 'warning', 'success', 'error'
  final String? childId;
  final String? childName;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    required this.type,
    this.childId,
    this.childName,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final rawTimestamp = json['timestamp'] ??
        json['dateCreation'] ??
        json['dateEnvoi'] ??
        json['createdAt'] ??
        json['date'];

    return NotificationModel(
      id: (json['id'] ?? json['notificationId']).toString(),
      title: (json['title'] ?? json['titre'] ?? 'Notification').toString(),
      message: (json['message'] ?? json['contenu'] ?? '').toString(),
      timestamp: rawTimestamp != null
          ? DateTime.parse(rawTimestamp.toString())
          : DateTime.now(),
      isRead: json['isRead'] as bool? ?? json['lu'] as bool? ?? false,
      type: (json['type'] ?? json['categorie'] ?? 'info').toString(),
      childId: json['childId']?.toString() ?? json['etudiantId']?.toString(),
      childName:
          json['childName']?.toString() ?? json['etudiantNom']?.toString(),
    );
  }

  NotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? timestamp,
    bool? isRead,
    String? type,
    String? childId,
    String? childName,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
      childId: childId ?? this.childId,
      childName: childName ?? this.childName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'type': type,
      'childId': childId,
      'childName': childName,
    };
  }

  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours} h';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} j';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  String get formattedDate {
    return '${timestamp.day}/${timestamp.month}/${timestamp.year} à ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}
