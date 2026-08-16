import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/schedule_controller.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_dimens.dart';
import '../widgets/common/state_widgets.dart';

class ScheduleView extends StatelessWidget {
  const ScheduleView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ScheduleController());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        toolbarHeight: 85,
        automaticallyImplyLeading: false,
        title: const SafeArea(
          bottom: false,
          child: Center(
            child: Text('Emploi du temps', style: AppTextStyles.h3),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: AppColors.divider,
            height: 1,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Obx(() {
          if (controller.isLoading.value && controller.seances.isEmpty) {
            return const LoadingWidget();
          }

          return RefreshIndicator(
            onRefresh: controller.loadSeances,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildIconButton(Icons.arrow_back_ios, controller.previousWeek),
                      Obx(() => Text(
                            controller.weekLabel,
                            style: AppTextStyles.titleMedium,
                          )),
                      _buildIconButton(Icons.arrow_forward_ios, controller.nextWeek),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildWeekDays(controller),
                  const SizedBox(height: 24),
                  Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.l),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Obx(() => Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStat('${controller.dayTotalSeances}', 'Séances', AppColors.primary),
                              _buildStat('${controller.dayTotalStudents}', 'Elèves', AppColors.success),
                              _buildStat(_dayTotalDuration(controller), 'Durée', AppColors.error),
                            ],
                          )),
                    ),
                  const SizedBox(height: 24),
                  Obx(() => Text(
                        '${controller.dayProgramLabel} - PROGRAMME',
                        style: AppTextStyles.titleMedium.copyWith(letterSpacing: 0.5),
                      )),
                  const SizedBox(height: 16),
                  if (controller.error.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(controller.error.value, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error)),
                    ),
                  if (controller.seances.isEmpty)
                    const EmptyWidget(
                      title: 'Aucune séance',
                      message: 'Aucune séance pour cette date.',
                      icon: Icons.event_busy_outlined,
                    )
                  else
                    ...controller.seances.asMap().entries.map((entry) {
                      final s = entry.value;
                      final color = _colorFromKey(s['color'] as String);
                      return _buildCourseCard(
                        startTime: _formatTime(s['heureDebut'] as String),
                        endTime: _formatTime(s['heureFin'] as String),
                        subject: s['matiere'] as String,
                        className: s['classe'] as String,
                        duration: _durationLabel(s['heureDebut'] as String, s['heureFin'] as String),
                      );
                    }),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  String _totalDuration(ScheduleController c) {
    final minutes = c.totalWeekDurationMinutes;
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final rest = minutes % 60;
      return rest > 0 ? '${hours}h${rest}' : '${hours}h';
    }
    return '${minutes}min';
  }

  String _dayTotalDuration(ScheduleController c) {
    final minutes = c.dayTotalDurationMinutes;
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final rest = minutes % 60;
      return rest > 0 ? '${hours}h${rest}' : '${hours}h';
    }
    return '${minutes}min';
  }

  int _durationMinutes(String start, String end) {
    try {
      final p1 = start.split(':');
      final p2 = end.split(':');
      final h1 = int.parse(p1[0]);
      final m1 = int.parse(p1[1]);
      final h2 = int.parse(p2[0]);
      final m2 = int.parse(p2[1]);
      var diff = (h2 * 60 + m2) - (h1 * 60 + m1);
      if (diff < 0) diff += 24 * 60;
      return diff;
    } catch (_) {
      return 60;
    }
  }

  String _durationLabel(String start, String end) {
    final m = _durationMinutes(start, end);
    if (m >= 60) return '${m ~/ 60}h';
    return '${m}min';
  }

  String _formatTime(String raw) {
    if (raw.isEmpty) return '--h--';
    final parts = raw.split(':');
    if (parts.length >= 2) return '${parts[0]}h${parts[1]}';
    return raw;
  }

  Color _colorFromKey(String key) {
    switch (key) {
      case 'green':
        return AppColors.success;
      case 'blue':
        return AppColors.primary;
      default:
        return AppColors.warning;
    }
  }

  Widget _buildWeekDays(ScheduleController controller) {
    final selected = controller.selectedDate.value;
    final start = selected.subtract(Duration(days: selected.weekday - 1));
    const labels = ['LUN', 'MAR', 'MER', 'JEU', 'VEN', 'SAM', 'DIM'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(7, (i) {
        final day = start.add(Duration(days: i));
        final isSelected = day.year == selected.year &&
            day.month == selected.month &&
            day.day == selected.day;
        return GestureDetector(
          onTap: () => controller.selectDate(day),
          child: _buildDayItem(labels[i], '${day.day}', isSelected),
        );
      }),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.divider),
        ),
        child: Icon(icon, size: AppIconSize.s, color: AppColors.textSecondary),
      ),
    );
  }

  Widget _buildDayItem(String day, String date, bool isSelected) {
    return Column(
      children: [
        Text(day,
            style: AppTextStyles.bodySecondary.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Text(date,
              style: AppTextStyles.bodyMedium.copyWith(
                  color: isSelected ? AppColors.surface : AppColors.textPrimary,
                  fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 4),
        if (isSelected) Container(width: 4, height: 4, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
      ],
    );
  }

  Widget _buildStat(String value, String label, Color color) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.h3.copyWith(color: color)),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.label),
      ],
    );
  }

  Widget _buildCourseCard({
    required String startTime,
    required String endTime,
    required String subject,
    required String className,
    required String duration,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.m),
        border: Border.all(color: AppColors.divider),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(width: 5, decoration: const BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.only(topLeft: Radius.circular(AppRadius.m), bottomLeft: Radius.circular(AppRadius.m)))),
            const SizedBox(width: 12),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  Text(startTime, style: AppTextStyles.bodySecondary.copyWith(fontWeight: FontWeight.bold)),
                  Text(endTime, style: AppTextStyles.bodySecondary),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(subject, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.people_outline, size: AppIconSize.s, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(className, style: AppTextStyles.label),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(duration, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
