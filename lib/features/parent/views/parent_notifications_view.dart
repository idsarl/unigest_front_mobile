import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/parent_notifications_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../models/notification_model.dart';
import '../../../widgets/common/state_widgets.dart';

class ParentNotificationsView extends GetView<ParentNotificationsController> {
  const ParentNotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading) {
            return const LoadingWidget();
          }

          return RefreshIndicator(
            onRefresh: controller.loadNotifications,
            color: AppColors.primary,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _buildHeader()),
                if (controller.error != null)
                  SliverToBoxAdapter(child: _buildErrorBanner()),
                SliverToBoxAdapter(child: _buildFilters()),
                if (controller.filteredNotifications.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    sliver: SliverList.separated(
                      itemCount: controller.filteredNotifications.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final notification =
                            controller.filteredNotifications[index];
                        return _buildAnimatedNotificationCard(
                            notification, index);
                      },
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Notifications',
                      style: AppTextStyles.h1,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      controller.unreadCount == 0
                          ? 'Tout est à jour'
                          : '${controller.unreadCount} notification${controller.unreadCount > 1 ? 's' : ''} non lue${controller.unreadCount > 1 ? 's' : ''}',
                      style: AppTextStyles.bodySecondary,
                    ),
                  ],
                ),
              ),
              _buildHeaderIcon(),
            ],
          ),
          const SizedBox(height: 16),
          _buildSummaryBand(),
        ],
      ),
    );
  }

  Widget _buildHeaderIcon() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppRadius.s + 6),
          ),
          child: const Icon(
            Icons.notifications,
            color: AppColors.primary,
            size: AppIconSize.m + 2,
          ),
        ),
        if (controller.unreadCount > 0)
          Positioned(
            right: -4,
            top: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(AppRadius.s + 2),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Text(
                controller.unreadCount.toString(),
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSummaryBand() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.l),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.22),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                _buildSummaryMetric(controller.totalCount.toString(), 'Total'),
                const SizedBox(width: 18),
                _buildSummaryMetric(
                    controller.unreadCount.toString(), 'Non lues'),
              ],
            ),
          ),
          if (controller.unreadCount > 0)
            TextButton.icon(
              onPressed: controller.isSyncingReadState.value
                  ? null
                  : () => controller.markAllAsRead(),
              icon: const Icon(Icons.done_all, size: AppIconSize.s + 2),
              label: const Text('Tout lire'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.white.withOpacity(0.16),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.m),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryMetric(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: AppTextStyles.h2.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTextStyles.label.copyWith(
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    final filters = [
      _NotificationFilter('all', 'Toutes', Icons.inbox),
      _NotificationFilter('unread', 'Non lues', Icons.mark_email_unread),
      _NotificationFilter('warning', 'Absences', Icons.event_busy),
      _NotificationFilter('success', 'Notes', Icons.trending_up),
      _NotificationFilter('info', 'Infos', Icons.campaign),
    ];

    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final selected = controller.selectedFilter.value == filter.id;

          return ChoiceChip(
            selected: selected,
            showCheckmark: false,
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  filter.icon,
                  size: AppIconSize.s,
                  color: selected ? Colors.white : AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(filter.label),
              ],
            ),
            labelStyle: AppTextStyles.bodySecondary.copyWith(
              color: selected ? Colors.white : AppColors.textSecondary,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
            selectedColor: AppColors.primary,
            backgroundColor: Colors.white,
            side: BorderSide(
              color: selected ? AppColors.primary : AppColors.divider,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            onSelected: (_) => controller.changeFilter(filter.id),
          );
        },
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.08),
          borderRadius: BorderRadius.circular(AppRadius.m),
          border: Border.all(color: AppColors.error.withOpacity(0.18)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.error_outline,
              color: AppColors.error,
              size: AppIconSize.s + 4,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                controller.error!,
                style: AppTextStyles.bodySecondary.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(
              onPressed: controller.loadNotifications,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const EmptyWidget(
      icon: Icons.notifications_none,
      title: 'Aucune notification ici',
      message:
          'Les nouvelles alertes liées à vos enfants apparaîtront dans cette liste.',
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    final typeColor = _getTypeColor(notification.type);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.l - 2),
        onTap: notification.isRead
            ? null
            : () => controller.markAsRead(notification.id),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.l - 2),
            border: Border.all(
              color: notification.isRead
                  ? AppColors.divider.withOpacity(0.7)
                  : typeColor.withOpacity(0.45),
              width: notification.isRead ? 1 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black
                    .withOpacity(notification.isRead ? 0.035 : 0.07),
                blurRadius: notification.isRead ? 6 : 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(AppRadius.m),
                    ),
                    child: Icon(
                      _getTypeIcon(notification.type),
                      color: typeColor,
                      size: 23,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                notification.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.titleMedium.copyWith(
                                  fontSize: 15,
                                  fontWeight: notification.isRead
                                      ? FontWeight.w600
                                      : FontWeight.bold,
                                ),
                              ),
                            ),
                            if (!notification.isRead)
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(left: 8),
                                decoration: BoxDecoration(
                                  color: typeColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notification.formattedTime,
                          style: AppTextStyles.caption.copyWith(color: AppColors.textHint),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                notification.message,
                style: AppTextStyles.bodySecondary.copyWith(height: 1.35),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (notification.childName != null)
                    Flexible(
                      child: _buildChip(
                        Icons.person,
                        notification.childName!,
                        AppColors.primary,
                      ),
                    ),
                  const Spacer(),
                  if (!notification.isRead)
                    TextButton.icon(
                      onPressed: () => controller.markAsRead(notification.id),
                      icon: const Icon(Icons.check, size: AppIconSize.s),
                      label: const Text('Lu'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.09),
        borderRadius: BorderRadius.circular(AppRadius.s + 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppIconSize.s - 2, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.label.copyWith(color: color, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedNotificationCard(
      NotificationModel notification, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 260 + (index * 45)),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return Transform.translate(
          offset: Offset(0, 18 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: _buildNotificationCard(notification),
          ),
        );
      },
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'success':
        return AppColors.success;
      case 'warning':
        return AppColors.warning;
      case 'error':
        return AppColors.error;
      case 'info':
      default:
        return AppColors.info;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'success':
        return Icons.trending_up;
      case 'warning':
        return Icons.event_busy;
      case 'error':
        return Icons.error_outline;
      case 'info':
      default:
        return Icons.campaign;
    }
  }
}

class _NotificationFilter {
  final String id;
  final String label;
  final IconData icon;

  const _NotificationFilter(this.id, this.label, this.icon);
}
