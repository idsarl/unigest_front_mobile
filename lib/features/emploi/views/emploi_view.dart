import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/widgets/skeleton_loader.dart';
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
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(ctrl.error.value!),
                      const SizedBox(height: 12),
                      FilledButton(
                          onPressed: () =>
                              ctrl.chargerJour(ctrl.selectedDate.value),
                          child: const Text('Réessayer')),
                    ],
                  ),
                );
              }
              if (ctrl.emplois.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.event_busy, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      const Text('Aucun cours ce jour'),
                    ],
                  ),
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
              style: const TextStyle(fontWeight: FontWeight.w600)),
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
      return Colors.indigo;
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
                    left: Radius.circular(12)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(emploi.matiereNom,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text(emploi.classeNom,
                        style:
                            TextStyle(fontSize: 13, color: Colors.grey[600])),
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
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                  Text(emploi.heureFin,
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey[500])),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
