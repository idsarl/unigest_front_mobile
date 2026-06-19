import '../../models/notification_model.dart';
import '../../models/absence_model.dart';
import '../../models/child_model.dart';
import '../../models/note_model.dart';
import 'absences_service.dart';
import 'notes_service.dart';
import 'parent_service.dart';

class NotificationsService {
  static final Set<String> _readIds = <String>{};

  static Future<List<NotificationModel>> getParentNotifications(
      int parentId) async {
    final children = await ParentService.getChildren(parentId);
    final notificationGroups = await Future.wait(
      children.map(_buildChildNotifications),
    );

    final notifications = notificationGroups.expand((items) => items).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return notifications.take(30).toList();
  }

  static Future<List<NotificationModel>> getStudentNotifications(
    int studentId, {
    String? childName,
  }) async {
    final results = await Future.wait([
      NotesService.getNotesByStudentId(studentId),
      AbsencesService.getAbsencesByStudentId(studentId),
    ]);

    final notes = results[0] as List<NoteModel>;
    final absences = results[1] as List<AbsenceModel>;
    final notifications = <NotificationModel>[
      ...notes.map((note) => _noteNotification(note, childName)),
      ...absences.map((absence) => _absenceNotification(absence, childName)),
    ]..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return notifications.take(30).toList();
  }

  static Future<List<NotificationModel>> _buildChildNotifications(
    ChildModel child,
  ) async {
    final childId = int.tryParse(child.id) ?? 0;
    if (childId == 0) return [];

    final results = await Future.wait([
      NotesService.getNotesByStudentId(childId),
      AbsencesService.getAbsencesByStudentId(childId),
    ]);

    final childName = child.fullName;
    final notes = results[0] as List<NoteModel>;
    final absences = results[1] as List<AbsenceModel>;

    return [
      ...notes.map((note) => _noteNotification(note, childName)),
      ...absences.map((absence) => _absenceNotification(absence, childName)),
    ];
  }

  static Future<void> markAsRead(String notificationId) async {
    _readIds.add(notificationId);
  }

  static Future<void> markAllAsRead(int parentId) async {
    final notifications = await getParentNotifications(parentId);
    _readIds.addAll(notifications.map((item) => item.id));
  }

  static NotificationModel _noteNotification(
    NoteModel note,
    String? childName,
  ) {
    final id = 'note-${note.id}';
    return NotificationModel(
      id: id,
      title: 'Nouvelle note',
      message:
          '${note.subject}: ${note.value.toStringAsFixed(1)}/${note.maxNote.toStringAsFixed(0)}',
      timestamp: _parseDate(note.date),
      isRead: _readIds.contains(id),
      type: 'success',
      childId: note.childId,
      childName: childName,
    );
  }

  static NotificationModel _absenceNotification(
    AbsenceModel absence,
    String? childName,
  ) {
    final id = 'absence-${absence.id}';
    final isRetard = absence.type == 'retard';

    return NotificationModel(
      id: id,
      title: isRetard ? 'Retard signalé' : 'Absence signalée',
      message: '${absence.subject}: ${absence.reason}',
      timestamp: _parseDate(absence.date),
      isRead: _readIds.contains(id),
      type: 'warning',
      childId: absence.childId,
      childName: childName,
    );
  }

  static DateTime _parseDate(String value) {
    return DateTime.tryParse(value) ?? DateTime.now();
  }
}
