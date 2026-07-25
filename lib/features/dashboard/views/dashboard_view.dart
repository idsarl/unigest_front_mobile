import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../models/seance.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/dashboard_controller.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<DashboardController>();
    final auth = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      body: RefreshIndicator(
        onRefresh: ctrl.loadAll,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 100,
              floating: true,
              snap: true,
              flexibleSpace: FlexibleSpaceBar(
                title: Obx(() => Text(
                      'Bonjour, ${auth.user?.prenom ?? ''}',
                      style: const TextStyle(fontSize: 16),
                    )),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () => auth.logout(),
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── 3 cartes stats ─────────────────────────────────────────
                  Obx(() {
                    if (ctrl.loadingStats.value) {
                      return Row(children: const [
                        Expanded(child: SkeletonCard()),
                        SizedBox(width: 8),
                        Expanded(child: SkeletonCard()),
                        SizedBox(width: 8),
                        Expanded(child: SkeletonCard()),
                      ]);
                    }
                    if (ctrl.statsError.value != null) {
                      return _ErrorBanner(
                          ctrl.statsError.value!, ctrl.loadStats);
                    }
                    final s = ctrl.stats.value;
                    if (s == null) return const SizedBox.shrink();
                    return Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            label: 'Affectations',
                            value: s.totalAffectations,
                            icon: Icons.school,
                            color: Colors.indigo,
                            onTap: () =>
                                Get.toNamed(AppConstants.affectationsRoute),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _StatCard(
                            label: 'Effectuées',
                            value: s.seancesEffectuees,
                            icon: Icons.check_circle,
                            color: Colors.green,
                            onTap: () =>
                                Get.toNamed(AppConstants.seancesRoute),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _StatCard(
                            label: 'Total séances',
                            value: s.totalSeances,
                            icon: Icons.event,
                            color: Colors.orange,
                            onTap: () =>
                                Get.toNamed(AppConstants.seancesRoute),
                          ),
                        ),
                      ],
                    );
                  }),
                  const SizedBox(height: 24),

                  // ── Emploi du jour ─────────────────────────────────────────
                  Text('Emploi du jour',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  Obx(() {
                    if (ctrl.loadingSeances.value) {
                      return Column(children: List.generate(
                          3, (_) => const Padding(
                                padding: EdgeInsets.only(bottom: 8),
                                child: SkeletonBox(height: 80),
                              )));
                    }
                    if (ctrl.seancesError.value != null) {
                      return _ErrorBanner(
                          ctrl.seancesError.value!, ctrl.loadSeancesDuJour);
                    }
                    if (ctrl.seancesDuJour.isEmpty) {
                      return const _EmptySeances();
                    }
                    return Column(
                      children: ctrl.seancesDuJour
                          .map((s) => _SeanceCard(seance: s, ctrl: ctrl))
                          .toList(),
                    );
                  }),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 8),
              Text(
                '$value',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold, color: color),
              ),
              Text(label,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.grey[600])),
            ],
          ),
        ),
      ),
    );
  }
}

class _SeanceCard extends StatelessWidget {
  final SeanceModel seance;
  final DashboardController ctrl;

  const _SeanceCard({required this.seance, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isUpdating = ctrl.updatingSeances.contains(seance.id);

      Color statusColor;
      switch (seance.statut) {
        case 'EN_COURS':
          statusColor = Colors.green;
        case 'TERMINEE':
          statusColor = Colors.grey;
        default:
          statusColor = Colors.orange;
      }

      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 56,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(seance.matiere,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('${seance.classe} · ${seance.filiere}',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey[600])),
                    Text('${seance.heureDebut} – ${seance.heureFin}',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ),
              _ActionButton(
                  seance: seance,
                  isUpdating: isUpdating,
                  onDemarrer: () => ctrl.demarrerSeance(seance.id),
                  onArreter: () => ctrl.arreterSeance(seance.id),
                  onAppel: () => Get.toNamed(
                      AppConstants.appelRoute,
                      arguments: seance)),
            ],
          ),
        ),
      );
    });
  }
}

class _ActionButton extends StatelessWidget {
  final SeanceModel seance;
  final bool isUpdating;
  final VoidCallback onDemarrer;
  final VoidCallback onArreter;
  final VoidCallback onAppel;

  const _ActionButton({
    required this.seance,
    required this.isUpdating,
    required this.onDemarrer,
    required this.onArreter,
    required this.onAppel,
  });

  @override
  Widget build(BuildContext context) {
    if (isUpdating) {
      return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (seance.isTerminee) {
      return TextButton.icon(
        onPressed: onAppel,
        icon: const Icon(Icons.how_to_reg, size: 16),
        label: const Text('Appel'),
      );
    }
    if (seance.isEnCours) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          OutlinedButton.icon(
            onPressed: onAppel,
            icon: const Icon(Icons.how_to_reg, size: 14),
            label: const Text('Appel'),
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
          ),
          const SizedBox(width: 4),
          FilledButton.tonal(
            onPressed: onArreter,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              backgroundColor: Colors.red[50],
              foregroundColor: Colors.red,
            ),
            child: const Text('Arrêter'),
          ),
        ],
      );
    }
    return FilledButton(
      onPressed: seance.isPlanifiee ? onDemarrer : null,
      style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4)),
      child: const Text('Démarrer'),
    );
  }
}

class _EmptySeances extends StatelessWidget {
  const _EmptySeances();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Icon(Icons.event_available, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text('Aucune séance aujourd\'hui',
                style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBanner(this.message, this.onRetry);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
                child: Text(message,
                    style: TextStyle(
                        color:
                            Theme.of(context).colorScheme.onErrorContainer))),
            TextButton(
                onPressed: onRetry, child: const Text('Réessayer')),
          ],
        ),
      ),
    );
  }
}
