import 'package:flutter/material.dart' hide ErrorWidget;
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../widgets/common/state_widgets.dart';
import '../controllers/emploi_controller.dart';
import '../../../services/emploi_service.dart';

class EmploiView extends StatelessWidget {
  const EmploiView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<EmploiController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emploi du temps'),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            tooltip: 'Aujourd\'hui',
            onPressed: ctrl.allerAujourdhui,
          ),
        ],
      ),
      body: Column(
        children: [
          // Sélecteur de date
          Obx(() => _DateSelector(
                date: ctrl.selectedDate.value,
                onPrev: ctrl.jourPrecedent,
                onNext: ctrl.jourSuivant,
              )),
          const Divider(height: 1),
          Expanded(
            child: Obx(() {
              if (ctrl.loading.value) {
                return ListView.builder(
                  itemCount: 5,
                  itemBuilder: (_, __) => const Padding(
                    padding: EdgeInsets.all(8),
                    child: SkeletonBox(height: 72),
                  ),
                );
              }
              if (ctrl.error.value != null) {
                return ErrorWidget(
                  message: ctrl.error.value,
                  onRetry: () => ctrl.chargerJour(ctrl.selectedDate.value),
                );
              }
              if (ctrl.emplois.isEmpty) {
                return const EmptyWidget(
                  icon: Icons.event_busy,
                  title: 'Aucun cours ce jour',
                );
              }

              final sorted = [...ctrl.emplois]
                ..sort((a, b) => a.heureDebut.compareTo(b.heureDebut));

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: sorted.length,
                itemBuilder: (ctx, i) => _EmploiCard(emploi: sorted[i]),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _DateSelector extends StatelessWidget {
  final DateTime date;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _DateSelector(
      {required this.date, required this.onPrev, required this.onNext});

  static const _jours = [
    '', 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'
  ];
  static const _mois = [
    '', 'jan', 'fév', 'mar', 'avr', 'mai', 'jun',
    'jul', 'aoû', 'sep', 'oct', 'nov', 'déc'
  ];

  @override
  Widget build(BuildContext context) {
    final label =
        '${_jours[date.weekday]} ${date.day} ${_mois[date.month]} ${date.year}';
    return Row(
      children: [
        IconButton(icon: const Icon(Icons.chevron_left), onPressed: onPrev),
        Expanded(
          child: Text(label,
              textAlign: TextAlign.center,
              style: AppTextStyles.titleMedium),
        ),
        IconButton(icon: const Icon(Icons.chevron_right), onPressed: onNext),
      ],
    );
  }
}

class _EmploiCard extends StatelessWidget {
  final EmploiModel emploi;

  const _EmploiCard({required this.emploi});

  Color _parseColor(String hex) {
    try {
      final c = hex.replaceAll('#', '');
      return Color(int.parse('FF$c', radix: 16));
    } catch (_) {
      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(emploi.couleur);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 6,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(AppRadius.m)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(emploi.matiereNom, style: AppTextStyles.titleMedium),
                    const SizedBox(height: 4),
                    Text(emploi.classeNom, style: AppTextStyles.bodySecondary),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(emploi.heureDebut,
                      style: AppTextStyles.bodyMedium
                          .copyWith(fontWeight: FontWeight.w600)),
                  Text(emploi.heureFin, style: AppTextStyles.caption),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
