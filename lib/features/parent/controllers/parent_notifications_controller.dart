import 'package:get/get.dart';
import '../../../core/state_management/getx_helpers.dart';
import '../../../core/services/notifications_service.dart';
import '../../../core/utils/error_handler.dart';
import '../../../models/notification_model.dart';
import '../../auth/controllers/auth_controller.dart';

class ParentNotificationsController extends BaseController {
  final RxList<NotificationModel> notifications = <NotificationModel>[].obs;
  final RxString selectedFilter = 'all'.obs;
  final RxBool isSyncingReadState = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    setLoading(true);
    try {
      final authController = Get.find<AuthController>();
      final parentId = authController.userId.value;

      if (parentId == 0) {
        throw AppException(message: 'Parent connecté introuvable');
      }

      notifications.value =
          await NotificationsService.getParentNotifications(parentId);
      clearError();
    } catch (e) {
      final appException = ErrorHandler.handleException(e);
      setError(ErrorHandler.getUserMessage(appException));
      notifications.clear();
    } finally {
      setLoading(false);
    }
  }

  Future<void> markAsRead(String notificationId) async {
    final index = notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      final previous = notifications[index];
      notifications[index] = previous.copyWith(isRead: true);

      try {
        await NotificationsService.markAsRead(notificationId);
        clearError();
      } catch (e) {
        notifications[index] = previous;
        final appException = ErrorHandler.handleException(e);
        setError(ErrorHandler.getUserMessage(appException));
      }
    }
  }

  Future<void> markAllAsRead() async {
    final authController = Get.find<AuthController>();
    final parentId = authController.userId.value;
    final previous = notifications.toList();

    notifications.value =
        notifications.map((n) => n.copyWith(isRead: true)).toList();

    try {
      isSyncingReadState.value = true;
      await NotificationsService.markAllAsRead(parentId);
      clearError();
    } catch (e) {
      notifications.value = previous;
      final appException = ErrorHandler.handleException(e);
      setError(ErrorHandler.getUserMessage(appException));
    } finally {
      isSyncingReadState.value = false;
    }
  }

  void changeFilter(String filter) {
    selectedFilter.value = filter;
  }

  List<NotificationModel> get filteredNotifications {
    switch (selectedFilter.value) {
      case 'unread':
        return notifications.where((n) => !n.isRead).toList();
      case 'warning':
        return notifications.where((n) => n.type == 'warning').toList();
      case 'success':
        return notifications.where((n) => n.type == 'success').toList();
      case 'info':
        return notifications.where((n) => n.type == 'info').toList();
      default:
        return notifications;
    }
  }

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  int get totalCount => notifications.length;

  @override
  Future<void> retry() => loadNotifications();
}
