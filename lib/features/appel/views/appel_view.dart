import 'package:flutter/material.dart' hide ErrorWidget;
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../models/seance.dart';
import '../../../widgets/common/state_widgets.dart';
import '../controllers/appel_controller.dart';

class AppelView extends StatefulWidget {
  const AppelView({super.key});

  @override
  State<AppelView> createState() => _AppelViewState();
}

class _AppelViewState extends State<AppelView> {
  late final AppelController ctrl;

  @override
  void initState() {
    super.initState();
    ctrl = Get.find<AppelController>();
    final seance = Get.arguments as SeanceModel?;
    if (seance != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => ctrl.init(seance));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final seance = ctrl.seance.value;
      return Scaffold(
        appBar: AppBar(
          title: Text(seance?.matiere ?? 'Appel'),
          bottom: seance == null
              ? null
              : PreferredSize(
                  preferredSize: const Size.fromHeight(32),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Obx(() => Text(
                          '${seance.classe} · ${seance.heureDebut}–${seance.heureFin} · '
                          '${ctrl.etudiants.length} étudiants',
                          style: AppTextStyles.caption,
                        )),
                  ),
                ),
        ),
        body: Obx(() {
          if (ctrl.loading.value) {
            return ListView.builder(
              itemCount: 8,
              itemBuilder: (_, __) => const SkeletonListItem(),
            );
          }
          if (ctrl.error.value != null) {
            return ErrorWidget(
              message: ctrl.error.value,
              onRetry: seance != null ? () => ctrl.init(seance) : null,
            );
          }
          if (ctrl.etudiants.isEmpty) {
            return const EmptyWidget(
              title: 'Aucun étudiant',
              message: 'Aucun étudiant dans cette classe',
            );
          }

          return Column(
            children: [
              // Barre de progression
              Obx(() {
                final done = ctrl.entries.values
                    .where((e) => e.statut != '')
                    .length;
                final total = ctrl.etudiants.length;
                return LinearProgressIndicator(
                  value: total > 0 ? done / total : 0,
                  backgroundColor: AppColors.divider,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.primary),
                );
              }),
              Expanded(
                child: ListView.separated(
                  itemCount: ctrl.etudiants.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final etd = ctrl.etudiants[i];
                    return Obx(() {
                      final entry = ctrl.entries[etd.id];
                      final statut = entry?.statut ?? 'PRESENT';
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _statusColor(statut).withAlpha(40),
                          child: Text(
                            etd.prenom.substring(0, 1).toUpperCase(),
                            style: TextStyle(color: _statusColor(statut)),
                          ),
                        ),
                        title: Text(etd.fullName),
                        subtitle: Text(etd.matricule,
                            style: AppTextStyles.caption),
                        trailing: _StatusToggle(
                          statut: statut,
                          onChanged: (s) => ctrl.setStatut(etd.id, s),
                        ),
                      );
                    });
                  },
                ),
              ),
            ],
          );
        }),
        bottomNavigationBar: Obx(() => SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: FilledButton(
                  onPressed: ctrl.submitting.value ? null : ctrl.soumettre,
                  child: ctrl.submitting.value
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Valider l\'appel'),
                ),
              ),
            )),
      );
    });
  }

  Color _statusColor(String statut) {
    return switch (statut) {
      'ABSENT' => AppColors.error,
      'RETARD' => AppColors.warning,
      _ => AppColors.success,
    };
  }
}

class _StatusToggle extends StatelessWidget {
  final String statut;
  final ValueChanged<String> onChanged;

  const _StatusToggle({required this.statut, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(value: 'PRESENT', label: Text('P')),
        ButtonSegment(value: 'RETARD', label: Text('R')),
        ButtonSegment(value: 'ABSENT', label: Text('A')),
      ],
      selected: {statut},
      onSelectionChanged: (s) => onChanged(s.first),
      style: ButtonStyle(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        textStyle: WidgetStateProperty.all(AppTextStyles.caption),
      ),
    );
  }
}
