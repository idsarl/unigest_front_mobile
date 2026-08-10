import 'package:flutter/material.dart' hide ErrorWidget;
import 'package:get/get.dart';
import '../controllers/appel_controller.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_dimens.dart';
import '../widgets/common/state_widgets.dart';

class AppelView extends StatefulWidget {
  const AppelView({super.key});

  @override
  State<AppelView> createState() => _AppelViewState();
}

class _AppelViewState extends State<AppelView> {
  final AppelController _controller = Get.put(AppelController());
  String? _selectedName;
  String? _selectedInitial;
  String? _selectedStatus;
  Color? _selectedColor;
  int? _selectedStudentId;
  final _motifController = TextEditingController();

  String _formatToday() {
    final now = DateTime.now();
    const jours = [
      'Lundi',
      'Mardi',
      'Mercredi',
      'Jeudi',
      'Vendredi',
      'Samedi',
      'Dimanche'
    ];
    const mois = [
      'janvier',
      'février',
      'mars',
      'avril',
      'mai',
      'juin',
      'juillet',
      'août',
      'septembre',
      'octobre',
      'novembre',
      'décembre'
    ];
    return '${jours[now.weekday - 1]} ${now.day} ${mois[now.month - 1]} ${now.year}';
  }

  // Utilitaires pour récupérer la couleur et l'icône selon le statut
  Color _getStatusColor(String status) {
    if (status == 'Présent') return AppColors.success;
    if (status == 'En retard') return AppColors.warning;
    return AppColors.error;
  }

  IconData _getStatusIcon(String status) {
    if (status == 'Présent') return Icons.check_circle;
    if (status == 'En retard') return Icons.access_time_filled;
    return Icons.cancel;
  }

  // FONCTION POUR AFFICHER LE BOTTOM SHEET
  void _showJustifyBottomSheet(BuildContext context) {
    if (_selectedName == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            top: 12,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.m),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.primary,
                          child: Text(_selectedInitial!,
                              style: AppTextStyles.button
                                  .copyWith(fontSize: 14)),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_selectedName!, style: AppTextStyles.titleMedium),
                            const SizedBox(height: 2),
                            const Text('3ème IG', style: AppTextStyles.bodySecondary),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _selectedColor!.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(AppRadius.s),
                      ),
                      child: Text(
                        _selectedStatus!,
                        style: AppTextStyles.label.copyWith(color: _selectedColor),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildInfoRow('Date', _formatToday(), AppColors.textPrimary),
              const SizedBox(height: 12),
              _buildInfoRow(
                'Sceance',
                '${_controller.matiereLabel} (${_controller.classeLabel})',
                AppColors.textPrimary,
              ),
              const SizedBox(height: 12),
              _buildInfoRow('Statut actuel', _selectedStatus!, _selectedColor!),
              const SizedBox(height: 20),
              const Text('Motif', style: AppTextStyles.titleMedium),
              const SizedBox(height: 8),
              TextField(
                controller: _motifController,
                maxLines: 4,
                decoration: InputDecoration(
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.m),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.m),
                    borderSide: BorderSide(color: AppColors.divider),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Fermer'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_selectedStudentId != null) {
                          await _controller.justifyAppel(
                            _selectedStudentId!,
                            _motifController.text,
                          );
                        }
                        if (context.mounted) Navigator.pop(context);
                      },
                      child: const Text('Valider'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value, Color valueColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(label,
              style: AppTextStyles.bodyMedium
                  .copyWith(fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: Text(value,
              style: AppTextStyles.bodyMedium.copyWith(
                  color: valueColor,
                  fontWeight: valueColor != AppColors.textPrimary
                      ? FontWeight.bold
                      : FontWeight.normal)),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _motifController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool hasSelection = _selectedName != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        toolbarHeight: 85,
        automaticallyImplyLeading: false,
        title: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Center(
            child: Text('Appel de la classe', style: AppTextStyles.h3),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.divider, height: 1),
        ),
      ),
      body: Obx(() {
        if (_controller.isLoading.value && _controller.students.isEmpty) {
          return const LoadingWidget();
        }
        if (_controller.error.isNotEmpty && _controller.students.isEmpty) {
          return ErrorWidget(
            message: _controller.error.value,
            onRetry: _controller.loadData,
          );
        }

        final resume = _controller.resume;
        final students = _controller.filteredStudents;

        return Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: _controller.loadData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // Dropdown Classe
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              value: _controller.selectedAffectationIndex.value,
                              isExpanded: true,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.groups_outlined,
                                    color: AppColors.primary, size: AppIconSize.m),
                                filled: true,
                                fillColor: AppColors.surface,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppRadius.m),
                                  borderSide:
                                      BorderSide(color: AppColors.divider),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppRadius.m),
                                  borderSide:
                                      BorderSide(color: AppColors.divider),
                                ),
                              ),
                              items: List.generate(
                                  _controller.affectations.length, (i) {
                                final a = _controller.affectations[i];
                                final label =
                                    a['classe']?['nom']?.toString() ?? 'Classe';
                                return DropdownMenuItem(
                                  value: i,
                                  child: Text(label,
                                      style: AppTextStyles.bodySecondary.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary)),
                                );
                              }),
                              onChanged: (v) {
                                if (v != null) _controller.selectAffectation(v);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Dropdown Matiere
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              value: _controller.selectedMatiereIndex.value,
                              isExpanded: true,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.menu_book_outlined,
                                    color: AppColors.primary, size: AppIconSize.m),
                                filled: true,
                                fillColor: AppColors.surface,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppRadius.m),
                                  borderSide:
                                      BorderSide(color: AppColors.divider),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppRadius.m),
                                  borderSide:
                                      BorderSide(color: AppColors.divider),
                                ),
                              ),
                              items: List.generate(
                                  _controller.currentMatieres.length, (i) {
                                final m = _controller.currentMatieres[i];
                                final label = m['nom']?.toString() ?? 'Matière';
                                return DropdownMenuItem(
                                  value: i,
                                  child: Text(label,
                                      style: AppTextStyles.bodySecondary.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary),
                                      overflow: TextOverflow.ellipsis),
                                );
                              }),
                              onChanged: (v) {
                                if (v != null) _controller.selectMatiere(v);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(AppRadius.m)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.calendar_today_outlined,
                                    color: AppColors.primary, size: AppIconSize.s),
                                const SizedBox(width: 8),
                                Text(_formatToday(),
                                    style: AppTextStyles.bodySecondary
                                        .copyWith(fontWeight: FontWeight.w500)),
                              ],
                            ),
                            Row(
                              children: [
                                const Icon(Icons.access_time,
                                    color: AppColors.textPrimary, size: AppIconSize.s),
                                const SizedBox(width: 8),
                                Text('Aujourd\'hui',
                                    style: AppTextStyles.bodySecondary
                                        .copyWith(fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.m),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem(
                                '${resume['effectif'] ?? students.length}',
                                'Effectif',
                                AppColors.primary,
                                Icons.people_outline),
                            _buildStatItem(
                                '${resume['present'] ?? 0}',
                                'Presents',
                                AppColors.success,
                                Icons.check_circle_outline),
                            _buildStatItem('${resume['retard'] ?? 0}',
                                'Retards', AppColors.warning, Icons.access_time),
                            _buildStatItem('${resume['absent'] ?? 0}',
                                'Absents', AppColors.error, Icons.cancel_outlined),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        onChanged: (v) => _controller.searchQuery.value = v,
                        decoration: InputDecoration(
                          hintText: 'Rechercher un étudiant...',
                          hintStyle: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.textSecondary),
                          suffixIcon: const Icon(Icons.search,
                              color: AppColors.textSecondary, size: AppIconSize.m),
                          filled: true,
                          fillColor: AppColors.accentLight,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 14),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.m),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Nom Etudiant',
                                      style: AppTextStyles.bodyMedium
                                          .copyWith(fontWeight: FontWeight.bold)),
                                  Text('Statut',
                                      style: AppTextStyles.bodyMedium
                                          .copyWith(fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            const Divider(height: 1, indent: 16, endIndent: 16),
                            if (students.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(24),
                                child: Text(
                                    'Aucun étudiant inscrit dans cette classe'),
                              )
                            else
                              ...students.asMap().entries.map((entry) {
                                final student = entry.value;
                                final bool isLast =
                                    entry.key == students.length - 1;
                                return Column(
                                  children: [
                                    _buildStudentRow(student),
                                    if (!isLast)
                                      const Divider(
                                          height: 1, indent: 16, endIndent: 16),
                                  ],
                                );
                              }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: hasSelection
                          ? () => _showJustifyBottomSheet(context)
                          : null,
                      style: hasSelection
                          ? null
                          : OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.divider),
                              foregroundColor: AppColors.textHint,
                            ),
                      child: const Text('Justifier'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Obx(() => ElevatedButton(
                          onPressed: (_controller.isSaving.value ||
                                  _controller.isAppelSaved.value)
                              ? null
                              : _controller.saveAppels,
                          style: _controller.isAppelSaved.value
                              ? ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.textSecondary)
                              : null,
                          child: _controller.isSaving.value
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: AppColors.surface),
                                )
                              : Text(_controller.isAppelSaved.value
                                  ? 'Enregistré'
                                  : 'Enregistrer'),
                        )),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildStatItem(
      String value, String label, Color color, IconData icon) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: AppIconSize.m),
            const SizedBox(width: 6),
            Text(value,
                style: AppTextStyles.titleMedium
                    .copyWith(color: AppColors.textSecondary)),
          ],
        ),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.label.copyWith(color: AppColors.textPrimary)),
      ],
    );
  }

  // Uniquement le PopupMenuButton sur chaque étudiant
  Widget _buildStudentRow(Map<String, dynamic> student) {
    final initial = student['initial'] as String;
    final name = student['name'] as String;
    final status = student['status'] as String;
    final studentId = student['id'] as int;
    Color baseColor = _getStatusColor(status);
    Color backgroundColor;

    if (status == 'Présent') {
      backgroundColor = AppColors.success.withOpacity(0.12);
    } else if (status == 'En retard') {
      backgroundColor = AppColors.warning.withOpacity(0.12);
    } else {
      backgroundColor = AppColors.error.withOpacity(0.12);
    }

    bool isSelected = _selectedName == name;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedName = name;
          _selectedInitial = initial;
          _selectedStatus = status;
          _selectedColor = baseColor;
          _selectedStudentId = studentId;
          _motifController.text = student['motif']?.toString() ?? '';
        });
      },
      child: Container(
        color: isSelected
            ? AppColors.primary.withOpacity(0.05)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primary,
                  child: Text(initial,
                      style: AppTextStyles.label.copyWith(color: AppColors.surface)),
                ),
                const SizedBox(width: 12),
                Text(name,
                    style: AppTextStyles.bodyMedium
                        .copyWith(fontWeight: FontWeight.w500)),
              ],
            ),
            PopupMenuButton<String>(
              tooltip: 'Changer le statut',
              onSelected: (String newStatus) {
                _controller.updateStudentStatus(studentId, newStatus);
                setState(() {
                  _selectedName = name;
                  _selectedInitial = initial;
                  _selectedStatus = newStatus;
                  _selectedColor = _getStatusColor(newStatus);
                  _selectedStudentId = studentId;
                });
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(AppRadius.s),
                  border:
                      Border.all(color: baseColor.withOpacity(0.4), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_getStatusIcon(status), color: baseColor, size: AppIconSize.s),
                    const SizedBox(width: 6),
                    Text(status, style: AppTextStyles.label.copyWith(color: baseColor)),
                    const SizedBox(width: 4),
                    Icon(Icons.keyboard_arrow_down, color: baseColor, size: AppIconSize.s),
                  ],
                ),
              ),
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                _buildPopupItem('Présent', AppColors.success, Icons.check_circle),
                const PopupMenuDivider(height: 1),
                _buildPopupItem(
                    'En retard', AppColors.warning, Icons.access_time_filled),
                const PopupMenuDivider(height: 1),
                _buildPopupItem('Absent', AppColors.error, Icons.cancel),
              ],
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildPopupItem(
      String value, Color color, IconData icon) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: color, size: AppIconSize.s),
          const SizedBox(width: 10),
          Text(
            value,
            style: AppTextStyles.bodySecondary
                .copyWith(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
