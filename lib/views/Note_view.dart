import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/note_controller.dart';

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
  final TextEditingController _noteMaxController = TextEditingController(text: '20');
  final Map<int, TextEditingController> _noteControllers = {};

  String _selectedType = 'DEVOIR';

  final List<String> _typeEvaluationList = [
    'DEVOIR',
    'COMPOSITION',
    'EXAMEN',
    'INTERROGATION',
    'TP',
    'PARTICIPATION'
  ];

  List<Map<String, dynamic>> get _displayStudents {
    if (_currentEvaluation != null && _isReadOnly) {
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
              primary: Color(0xFF6C5CE7),
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: const Color(0xFF6C5CE7)),
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
          'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
          'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
        ];
        _dateController.text = "${picked.day} ${mois[picked.month - 1]} ${picked.year}";
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
      backgroundColor: const Color(0xFFF8F9FA),

      // L'EN-TÊTE DE LA LISTE PRINCIPALE
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 85,
        automaticallyImplyLeading: false,
        title: const SafeArea(
          bottom: false,
          child: Center(
            child: Text(
              'Évaluations',
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
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Obx(() {
                    if (_controller.isLoading.value && _controller.evaluations.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    return Column(
                      children: [
                        Row(
                          children: [
                            // Dropdown Classe
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                value: _controller.selectedAffectationIndex.value,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.groups_outlined, color: Color(0xFF6C5CE7), size: 20),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey.shade200),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey.shade200),
                                  ),
                                ),
                                items: List.generate(_controller.affectations.length, (i) {
                                  final a = _controller.affectations[i];
                                  final label = a['classe']?['nom']?.toString() ?? 'Classe';
                                  return DropdownMenuItem(
                                    value: i, 
                                    child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
                                  prefixIcon: const Icon(Icons.menu_book_outlined, color: Color(0xFF6C5CE7), size: 20),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey.shade200),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey.shade200),
                                  ),
                                ),
                                items: List.generate(_controller.currentMatieres.length, (i) {
                                  final m = _controller.currentMatieres[i];
                                  final label = m['nom']?.toString() ?? 'Matière';
                                  return DropdownMenuItem(
                                    value: i, 
                                    child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis),
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
                  color: Colors.black.withOpacity(0.5),
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
      backgroundColor: const Color(0xFFF8F9FA),

      // L'EN-TÊTE DE LA VUE ÉTUDIANTS (Avec bouton retour à gauche)
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 85,
        automaticallyImplyLeading: false,
        title: SafeArea(
          bottom: false,
          child: Row(
            children: [
              IconButton(
                onPressed: () => setState(() => _isViewingStudents = false),
                icon: const Icon(Icons.arrow_back_ios, size: 18, color: Colors.black),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const Expanded(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.only(right: 24), // Compense la flèche retour pour centrer le texte
                    child: Text(
                      'Évaluations',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
            ],
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _titreController.text.isNotEmpty ? _titreController.text : 'Nouvelle évaluation',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEDEEFC),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '/${_noteMaxController.text.isNotEmpty ? _noteMaxController.text : '20'}',
                                style: const TextStyle(color: Color(0xFF6C5CE7), fontWeight: FontWeight.bold),
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
                                const Icon(Icons.menu_book_outlined, color: Color(0xFF6C5CE7), size: 18),
                                const SizedBox(width: 6),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_controller.matiereLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    Text(_controller.classeLabel, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                  ],
                                )
                              ],
                            ),
                            Row(
                              children: [
                                Icon(Icons.calendar_today_outlined, color: Colors.grey.shade600, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  _dateController.text.isNotEmpty ? _dateController.text : 'Date non spécifiée',
                                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
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
                      hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                      suffixIcon: const Icon(Icons.search, color: Colors.grey, size: 22),
                      filled: true,
                      fillColor: const Color(0xFFEFEFEF),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Etudiant', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 14)),
                              Text('Note /${_noteMaxController.text.isNotEmpty ? _noteMaxController.text : '20'}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 14)),
                            ],
                          ),
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16),

                        ..._displayStudents.map((student) {
                          final bool isLast = _displayStudents.last == student;
                          final studentId = student['id'] as int;
                          final studentNoteController = _noteControllerFor(
                            studentId,
                            _isReadOnly ? student['note']?.toString() ?? '' : '',
                          );

                          return Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 18,
                                          backgroundColor: const Color(0xFF536DFE),
                                          child: Text(student['initial'], style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(student['name'], style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
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
                                          fillColor: _isReadOnly ? Colors.grey.shade100 : Colors.white,
                                          filled: _isReadOnly,
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide(color: _isReadOnly ? Colors.grey.shade300 : Colors.grey.shade400),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide(color: _isReadOnly ? Colors.grey.shade300 : const Color(0xFF6C5CE7)),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (!isLast) const Divider(height: 1, indent: 16, endIndent: 16),
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
                              if (noteText != null && noteText.trim().isNotEmpty) {
                                hasNotes = true;
                                break;
                              }
                            }
                            if (!hasNotes) {
                              Get.snackbar('Info', 'Veuillez saisir au moins une note',
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
                            final d = _selectedDateObj ?? DateTime.now();
                            await _controller.saveEvaluationNotes(
                              type: _selectedType,
                              dateIso: d.toIso8601String().split('T').first,
                              noteMax: double.tryParse(_noteMaxController.text) ?? 20,
                              studentNotes: notes,
                            );
                            if (!_controller.isSaving.value && _controller.error.isEmpty) {
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
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
                      backgroundColor: const Color(0xFF6C5CE7),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _controller.isSaving.value
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Publier les notes',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
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
                icon: const Icon(Icons.arrow_back_ios, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              const Text(
                'Nouvelle évaluation',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
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
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Color(0xFF6C5CE7)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Annuler', style: TextStyle(color: Color(0xFF6C5CE7), fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // Validation des champs
                    if (_titreController.text.trim().isEmpty) {
                      Get.snackbar('Erreur', 'Veuillez saisir un titre', snackPosition: SnackPosition.BOTTOM);
                      return;
                    }
                    if (_dateController.text.trim().isEmpty || _selectedDateObj == null) {
                      Get.snackbar('Erreur', 'Veuillez sélectionner une date', snackPosition: SnackPosition.BOTTOM);
                      return;
                    }
                    if (_noteMaxController.text.trim().isEmpty || double.tryParse(_noteMaxController.text) == null) {
                      Get.snackbar('Erreur', 'Veuillez saisir une note maximale valide', snackPosition: SnackPosition.BOTTOM);
                      return;
                    }
                    
                    setState(() {
                      _isAdding = false;
                      _isReadOnly = false;
                      _isViewingStudents = true;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: const Color(0xFF6C5CE7),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Continuer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87)),
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
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        suffixIcon: suffixIcon != null ? Icon(suffixIcon, size: 18, color: Colors.grey) : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF6C5CE7))),
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
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(currentValue) ? currentValue : items.first,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
          isExpanded: true,
          items: items.map((String val) {
            return DropdownMenuItem<String>(
              value: val,
              child: Text(val, style: const TextStyle(color: Colors.black87, fontSize: 14)),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildEvaluationList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ElevatedButton.icon(
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
          icon: const Icon(Icons.add, color: Colors.white, size: 18),
          label: const Text('Nouvelle évaluation', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6C5CE7),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
        ),
        const SizedBox(height: 24),
        if (_controller.evaluations.isEmpty)
          const Text('Aucune évaluation enregistrée pour cette classe.', style: TextStyle(color: Colors.black54))
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



  Widget _buildEvaluationCard(String title, String date, String noteMax, [Map<String, dynamic>? eval]) {
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 8),
                Text(date, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
              ],
            ),
            Row(
              children: [
                Text('/$noteMax', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(width: 12),
                const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 14),
              ],
            ),
          ],
        ),
      ),
    );
  }
}