import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../models/affectation.dart';
import '../controllers/note_controller.dart';

class NoteListView extends StatefulWidget {
  const NoteListView({super.key});

  @override
  State<NoteListView> createState() => _NoteListViewState();
}

class _NoteListViewState extends State<NoteListView> {
  late final NoteController ctrl;

  @override
  void initState() {
    super.initState();
    ctrl = Get.find<NoteController>();
    final aff = Get.arguments as AffectationModel?;
    if (aff != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => ctrl.init(aff));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final aff = ctrl.affectation.value;
      return Scaffold(
        appBar: AppBar(
          title: Text(aff?.firstMatiere ?? 'Notes'),
          bottom: aff == null
              ? null
              : PreferredSize(
                  preferredSize: const Size.fromHeight(28),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                        '${aff.classeNom} · ${aff.filiereNom}',
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ),
                ),
          actions: [
            Obx(() => ctrl.dirty.value
                ? Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Chip(
                        label: const Text('Non enregistré',
                            style: TextStyle(fontSize: 11)),
                        backgroundColor: Colors.orange[100]),
                  )
                : const SizedBox.shrink()),
          ],
        ),
        body: Obx(() {
          if (ctrl.loading.value) {
            return ListView.builder(
              itemCount: 8,
              itemBuilder: (_, __) => const SkeletonListItem(),
            );
          }
          if (ctrl.error.value != null) {
            return Center(child: Text(ctrl.error.value!));
          }
          if (ctrl.entries.isEmpty) {
            return const Center(child: Text('Aucun étudiant'));
          }

          return ListView.separated(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: ctrl.entries.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (ctx, i) {
              final entry = ctrl.entries[i];
              return Obx(() {
                return ListTile(
                  leading: CircleAvatar(
                    child: Text('${i + 1}',
                        style: const TextStyle(fontSize: 12)),
                  ),
                  title: Text(entry.etudiantNom),
                  trailing: SizedBox(
                    width: 90,
                    child: _NoteField(
                      initialValue:
                          entry.valeur?.toStringAsFixed(1),
                      hasError: entry.hasError,
                      onChanged: (v) {
                        final d = double.tryParse(v ?? '');
                        ctrl.setValeur(entry.etudiantId, d);
                      },
                    ),
                  ),
                );
              });
            },
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
                      : const Text('Enregistrer les notes'),
                ),
              ),
            )),
      );
    });
  }
}

class _NoteField extends StatefulWidget {
  final String? initialValue;
  final bool hasError;
  final ValueChanged<String?> onChanged;

  const _NoteField({
    this.initialValue,
    required this.hasError,
    required this.onChanged,
  });

  @override
  State<_NoteField> createState() => _NoteFieldState();
}

class _NoteFieldState extends State<_NoteField> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        hintText: '/20',
        border: const OutlineInputBorder(),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        errorText: widget.hasError ? '0–20' : null,
        isDense: true,
      ),
      onChanged: widget.onChanged,
    );
  }
}
