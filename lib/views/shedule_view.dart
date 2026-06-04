import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/schedule_controller.dart';

class ScheduleView extends StatelessWidget {
  const ScheduleView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ScheduleController());

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 85,
        automaticallyImplyLeading: false,
        title: const SafeArea(
          bottom: false,
          child: Center(
            child: Text(
              'Emploi du temps',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.grey.shade300,
            height: 1,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Obx(() {
          if (controller.isLoading.value && controller.seances.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C5CE7)),
              ),
            );
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
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Obx(() => Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStat('${controller.dayTotalSeances}', 'Séances', const Color(0xFF536DFE)),
                              _buildStat('${controller.dayTotalStudents}', 'Elèves', Colors.green),
                              _buildStat(_dayTotalDuration(controller), 'Durée', Colors.red),
                            ],
                          )),
                    ),
                  const SizedBox(height: 24),
                  Obx(() => Text(
                        '${controller.dayProgramLabel} - PROGRAMME',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5),
                      )),
                  const SizedBox(height: 16),
                  if (controller.error.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(controller.error.value, style: const TextStyle(color: Colors.red)),
                    ),
                  if (controller.seances.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: const Text(
                        'Aucune séance pour cette date.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black54),
                      ),
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
                        status: s['statut'] as String,
                        color: color,
                        isSelected: s['statutRaw'] == 'EN_COURS',
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
      return (h2 * 60 + m2) - (h1 * 60 + m1);
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
        return Colors.green;
      case 'blue':
        return const Color(0xFF536DFE);
      default:
        return Colors.orange;
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
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Icon(icon, size: 16, color: Colors.grey),
      ),
    );
  }

  Widget _buildDayItem(String day, String date, bool isSelected) {
    return Column(
      children: [
        Text(day, style: TextStyle(color: isSelected ? const Color(0xFF6C5CE7) : Colors.grey, fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF6C5CE7) : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Text(date, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 4),
        if (isSelected) Container(width: 4, height: 4, decoration: const BoxDecoration(color: Color(0xFF6C5CE7), shape: BoxShape.circle)),
      ],
    );
  }

  Widget _buildStat(String value, String label, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 20)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildCourseCard({
    required String startTime,
    required String endTime,
    required String subject,
    required String className,
    required String duration,
    required String status,
    required Color color,
    required bool isSelected,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFEDEEFC) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isSelected ? const Color(0xFF6C5CE7).withOpacity(0.3) : Colors.grey.shade200),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(width: 5, decoration: BoxDecoration(color: color, borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)))),
            const SizedBox(width: 12),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  Text(startTime, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(endTime, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(subject, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.people_outline, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(className, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                  const Spacer(),
                  Text(duration, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
