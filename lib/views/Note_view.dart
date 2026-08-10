import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/note_controller.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_dimens.dart';
import '../widgets/common/state_widgets.dart';

class NoteView extends StatefulWidget {
  const NoteView({super.key});

  @override
  State<NoteView> createState() => _NoteViewState();
}

class _NoteViewState extends State<NoteView> {
  final NoteController _controller = Get.put(NoteController());
  bool _isAdding = false;
  bool _isViewingStudents = false;
  bool _isReadOnly = false;
  Map<String, dynamic>? _currentEvaluation;

  final TextEditingController _titreController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _noteMaxController =
      TextEditingController(text: '20');
  final Map<int, TextEditingController> _noteControllers = {};

  String _selectedType = 'DEVOIR';

  final List<String> _typeEvaluationList = [
    'DEVOIR',
    'EXAMEN',
    'INTERROGATION',
    'PARTICIPATION'
  ];

  List<Map<String, dynamic>> get _displayStudents {
    if (_currentEvaluation != null) {
      return _controller.notesForEvaluation(_currentEvaluation!);
    }
    return _controller.students;
  }

  @override
  void dispose() {
    _titreController.dispose();
    _dateController.dispose();
    _noteMaxController.dispose();
    for (final c in _noteControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _noteControllerFor(int studentId, String initialValue) {
    return _noteControllers.putIfAbsent(
      studentId,
      () => TextEditingController(text: initialValue),
    );
  }

  Future<void> _confirmDeleteNote(int noteId, String studentName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer cette note ?'),
        content: Text(
            'La note de $studentName pour cette évaluation sera définitivement supprimée.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await _controller.deleteNote(noteId);
    if (mounted) {
      setState(() {
        _currentEvaluation = null;
        _isViewingStudents = false;
        _isReadOnly = false;
      });
    }
  }

  DateTime? _selectedDateObj;

  // Fonction de sélection graphique de la date via Get.context!
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: Get.context!,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('fr', 'FR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDateObj = picked;
        const mois = [
          'Janvier',
          'Février',
          'Mars',
          'Avril',
          'Mai',
          'Juin',
          'Juillet',
          'Août',
          'Septembre',
          'Octobre',
          'Novembre',
          'Décembre'
        ];
        _dateController.text =
            "${picked.day} ${mois[picked.month - 1]} ${picked.year}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Si on regarde le détail des notes d'une évaluation
    if (_isViewingStudents) {
      return _buildStudentNotesView();
    }

    // Vue principale : Liste des évaluations
    return Scaffold(
      backgroundColor: AppColors.background,

      // L'EN-TÊTE DE LA LISTE PRINCIPALE
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        toolbarHeight: 85,
        automaticallyImplyLeading: false,
        title: const SafeArea(
          bottom: false,
          child: Center(
            child: Text('Évaluations', style: AppTextStyles.h3),
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
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Obx(() {
                    if (_controller.isLoading.value &&
                        _controller.evaluations.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(40),
                        child: LoadingWidget(),
                      );
                    }
                    return Column(
                      children: [
                        Row(
                          children: [
                            // Dropdown Classe
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                value:
                                    _controller.selectedAffectationIndex.value,
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
                                      a['classe']?['nom']?.toString() ??
                                          'Classe';
                                  return DropdownMenuItem(
                                    value: i,
                                    child: Text(label,
                                        style: AppTextStyles.bodySecondary.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary)),
                                  );
                                }),
                                onChanged: (v) {
                                  if (v != null)
                                    _controller.selectAffectation(v);
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
                                  prefixIcon: const Icon(
                                      Icons.menu_book_outlined,
                                      color: AppColors.primary,
                                      size: AppIconSize.m),
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
                                  final label =
                                      m['nom']?.toString() ?? 'Matière';
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
                        const SizedBox(height: 24),
                        _buildEvaluationList(),
                      ],
                    );
                  }),
                ],
              ),
            ),

            // Arrière-plan sombre si le formulaire pop-up est ouvert
            if (_isAdding)
              GestureDetector(
                onTap: () => setState(() => _isAdding = false),
                child: Container(
                  color: AppColors.textPrimary.withOpacity(0.5),
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),

            // Le formulaire Pop-up au centre
            if (_isAdding)
              Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildAddEvaluationForm(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // INTERFACE 2 : Saisie ou Consultation des notes par étudiant
  Widget _buildStudentNotesView() {
    return Scaffold(
      backgroundColor: AppColors.background,

      // L'EN-TÊTE DE LA VUE ÉTUDIANTS (Avec bouton retour à gauche)
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        toolbarHeight: 85,
        automaticallyImplyLeading: false,
        title: SafeArea(
          bottom: false,
          child: Row(
            children: [
              IconButton(
                onPressed: () => setState(() => _isViewingStudents = false),
                icon: const Icon(Icons.arrow_back_ios,
                    size: AppIconSize.s, color: AppColors.textPrimary),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const Expanded(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.only(
                        right:
                            24), // Compense la flèche retour pour centrer le texte
                    child: Text('Évaluations', style: AppTextStyles.h3),
                  ),
                ),
              ),
              if (_isReadOnly && _currentEvaluation != null)
                IconButton(
                  onPressed: () => setState(() => _isReadOnly = false),
                  icon: const Icon(Icons.edit, size: AppIconSize.m, color: AppColors.primary),
                  tooltip: 'Modifier les notes',
                ),
            ],
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

      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.m),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _titreController.text.isNotEmpty
                                  ? _titreController.text
                                  : 'Nouvelle évaluation',
                              style: AppTextStyles.h3,
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(AppRadius.s),
                              ),
                              child: Text(
                                '/${_noteMaxController.text.isNotEmpty ? _noteMaxController.text : '20'}',
                                style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.menu_book_outlined,
                                    color: AppColors.primary, size: AppIconSize.s),
                                const SizedBox(width: 6),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_controller.matiereLabel,
                                        style: AppTextStyles.bodySecondary.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary)),
                                    Text(_controller.classeLabel,
                                        style: AppTextStyles.caption),
                                  ],
                                )
                              ],
                            ),
                            Row(
                              children: [
                                Icon(Icons.calendar_today_outlined,
                                    color: AppColors.textSecondary, size: AppIconSize.s),
                                const SizedBox(width: 6),
                                Text(
                                  _dateController.text.isNotEmpty
                                      ? _dateController.text
                                      : 'Date non spécifiée',
                                  style: AppTextStyles.bodySecondary
                                      .copyWith(fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Etudiant',
                                  style: AppTextStyles.bodyMedium
                                      .copyWith(fontWeight: FontWeight.bold)),
                              Text(
                                  'Note /${_noteMaxController.text.isNotEmpty ? _noteMaxController.text : '20'}',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        ..._displayStudents.map((student) {
                          final bool isLast = _displayStudents.last == student;
                          final studentId = student['id'] as int;
                          final studentNoteController = _noteControllerFor(
                            studentId,
                            _isReadOnly
                                ? student['note']?.toString() ?? ''
                                : '',
                          );

                          return Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 18,
                                          backgroundColor:
                                              AppColors.primary,
                                          child: Text(student['initial'],
                                              style: AppTextStyles.label
                                                  .copyWith(color: AppColors.surface)),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(student['name'],
                                            style: AppTextStyles.bodyMedium
                                                .copyWith(fontWeight: FontWeight.w500)),
                                      ],
                                    ),
                                    SizedBox(
                                      width: 65,
                                      height: 38,
                                      child: TextField(
                                        controller: studentNoteController,
                                        keyboardType: TextInputType.number,
                                        textAlign: TextAlign.center,
                                        readOnly: _isReadOnly,
                                        decoration: InputDecoration(
                                          contentPadding: EdgeInsets.zero,
                                          fillColor: _isReadOnly
                                              ? AppColors.divider
                                              : AppColors.surface,
                                          filled: _isReadOnly,
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(AppRadius.s),
                                            borderSide: BorderSide(
                                                color: _isReadOnly
                                                    ? AppColors.divider
                                                    : AppColors.textHint),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(AppRadius.s),
                                            borderSide: BorderSide(
                                                color: _isReadOnly
                                                    ? AppColors.divider
                                                    : AppColors.primary),
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (!_isReadOnly &&
                                        _currentEvaluation != null &&
                                        student['noteId'] != null)
                                      IconButton(
                                        onPressed: () => _confirmDeleteNote(
                                            student['noteId'] as int,
                                            student['name']?.toString() ?? ''),
                                        icon: const Icon(Icons.delete_outline,
                                            color: AppColors.error, size: AppIconSize.m),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        tooltip: 'Supprimer cette note',
                                      ),
                                  ],
                                ),
                              ),
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
          if (!_isReadOnly)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Obx(() => ElevatedButton(
                    onPressed: _controller.isSaving.value
                        ? null
                        : () async {
                            // Valider qu'au moins une note a été saisie
                            bool hasNotes = false;
                            for (var s in _displayStudents) {
                              final noteText = _noteControllers[s['id']]?.text;
                              if (noteText != null &&
                                  noteText.trim().isNotEmpty) {
                                hasNotes = true;
                                break;
                              }
                            }
                            if (!hasNotes) {
                              Get.snackbar(
                                  'Info', 'Veuillez saisir au moins une note',
                                  snackPosition: SnackPosition.BOTTOM);
                              return;
                            }

                            final notes = _displayStudents.map((s) {
                              final id = s['id'] as int;
                              return {
                                'id': id,
                                'note': _noteControllers[id]?.text,
                              };
                            }).toList();

                            if (_currentEvaluation != null) {
                              await _controller.updateEvaluationNotes(
                                eval: _currentEvaluation!,
                                studentNotes: notes,
                              );
                            } else {
                              final d = _selectedDateObj ?? DateTime.now();
                              await _controller.saveEvaluationNotes(
                                title: _titreController.text.trim(),
                                type: _selectedType,
                                dateIso: d.toIso8601String().split('T').first,
                                noteMax: double.tryParse(
                                        _noteMaxController.text) ??
                                    20,
                                studentNotes: notes,
                              );
                            }
                            if (!_controller.isSaving.value &&
                                _controller.error.isEmpty) {
                              // Réinitialiser les contrôleurs
                              _titreController.clear();
                              _dateController.clear();
                              _selectedDateObj = null;
                              _noteMaxController.text = '20';
                              _noteControllers.clear();
                              _currentEvaluation = null;
                              setState(() {
                                _isViewingStudents = false;
                              });
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 28),
                    ),
                    child: _controller.isSaving.value
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.surface,
                            ),
                          )
                        : Text(_currentEvaluation != null
                            ? 'Enregistrer les modifications'
                            : 'Publier les notes'),
                  )),
            ),
        ],
      ),
    );
  }

  // --- WIDGETS DE CONSTRUCTIONS DU FORMULAIRE ET FILTRES ---

  Widget _buildAddEvaluationForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 5,
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => setState(() => _isAdding = false),
                icon: const Icon(Icons.arrow_back_ios, size: AppIconSize.s),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              const Text('Nouvelle évaluation', style: AppTextStyles.h3),
            ],
          ),
          const SizedBox(height: 10),
          _buildFieldLabel("Titre de l'évaluation"),
          _buildTextField(controller: _titreController, hint: "Ex: Devoir n°3"),
          _buildFieldLabel("Type de l'évaluation"),
          _buildDropdownField(
            currentValue: _selectedType,
            items: _typeEvaluationList,
            onChanged: (val) => setState(() => _selectedType = val!),
          ),
          _buildFieldLabel("Date de l'évaluation"),
          _buildTextField(
            controller: _dateController,
            suffixIcon: Icons.calendar_today_outlined,
            hint: "Sélectionner une date",
            readOnly: true,
            onTap: _selectDate,
          ),
          _buildFieldLabel("Note maximale"),
          _buildTextField(
            controller: _noteMaxController,
            hint: "Ex: 20",
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 30),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _isAdding = false),
                  child: const Text('Annuler'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // Validation des champs
                    if (_titreController.text.trim().isEmpty) {
                      Get.snackbar('Erreur', 'Veuillez saisir un titre',
                          snackPosition: SnackPosition.BOTTOM);
                      return;
                    }
                    if (_dateController.text.trim().isEmpty ||
                        _selectedDateObj == null) {
                      Get.snackbar('Erreur', 'Veuillez sélectionner une date',
                          snackPosition: SnackPosition.BOTTOM);
                      return;
                    }
                    if (_noteMaxController.text.trim().isEmpty ||
                        double.tryParse(_noteMaxController.text) == null) {
                      Get.snackbar(
                          'Erreur', 'Veuillez saisir une note maximale valide',
                          snackPosition: SnackPosition.BOTTOM);
                      return;
                    }

                    setState(() {
                      _isAdding = false;
                      _isReadOnly = false;
                      _isViewingStudents = true;
                    });
                  },
                  child: const Text('Continuer'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(label, style: AppTextStyles.titleMedium.copyWith(fontSize: 13)),
    );
  }

  Widget _buildTextField({
    TextEditingController? controller,
    IconData? suffixIcon,
    String? hint,
    bool readOnly = false,
    VoidCallback? onTap,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
        suffixIcon: suffixIcon != null
            ? Icon(suffixIcon, size: AppIconSize.s, color: AppColors.textSecondary)
            : null,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.s),
            borderSide: BorderSide(color: AppColors.divider)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.s),
            borderSide: const BorderSide(color: AppColors.primary)),
      ),
    );
  }

  Widget _buildDropdownField({
    required String currentValue,
    required List<String> items,
    required ValueChanged<String?>? onChanged,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.s),
        border: Border.all(color: AppColors.divider),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(currentValue) ? currentValue : items.first,
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
          isExpanded: true,
          items: items.map((String val) {
            return DropdownMenuItem<String>(
              value: val,
              child: Text(val, style: AppTextStyles.bodyMedium),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildEvaluationList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _titreController.clear();
                _dateController.clear();
                _selectedDateObj = null;
                _noteMaxController.text = '20';
                _noteControllers.clear();
                _currentEvaluation = null;
                _isAdding = true;
              });
            },
            icon: const Icon(Icons.add, size: AppIconSize.s),
            label: const Text('Nouvelle évaluation'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 24),
        if (_controller.evaluations.isEmpty)
          const Text('Aucune évaluation enregistrée pour cette classe.',
              style: AppTextStyles.bodySecondary)
        else
          ..._controller.evaluations.map((eval) => _buildEvaluationCard(
                eval['title']?.toString() ?? 'Évaluation',
                eval['dateLabel']?.toString() ?? '',
                eval['noteMax']?.toString() ?? '20',
                eval,
              )),
      ],
    );
  }

  Widget _buildEvaluationCard(String title, String date, String noteMax,
      [Map<String, dynamic>? eval]) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _titreController.text = title;
          _dateController.text = date;
          _noteMaxController.text = noteMax;
          _currentEvaluation = eval;
          _selectedType = eval?['type']?.toString() ?? 'DEVOIR';
          _isReadOnly = true;
          _isViewingStudents = true;
          _noteControllers.clear();
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.m),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTextStyles.titleMedium.copyWith(fontSize: 15)),
                const SizedBox(height: 8),
                Text(date, style: AppTextStyles.bodySecondary),
              ],
            ),
            Row(
              children: [
                Text('/$noteMax',
                    style: AppTextStyles.h3),
                const SizedBox(width: 12),
                const Icon(Icons.arrow_forward_ios,
                    color: AppColors.textSecondary, size: AppIconSize.s),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
