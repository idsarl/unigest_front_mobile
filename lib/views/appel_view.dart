import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/appel_controller.dart';

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
    if (status == 'Présent') return Colors.green;
    if (status == 'En retard') return Colors.orange;
    return Colors.red;
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
            color: Colors.white,
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
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: const Color(0xFF536DFE),
                          child: Text(_selectedInitial!,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_selectedName!,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 15)),
                            const SizedBox(height: 2),
                            const Text('3ème IG',
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 13)),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _selectedColor!.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _selectedStatus!,
                        style: TextStyle(
                            color: _selectedColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildInfoRow('Date', _formatToday(), Colors.black),
              const SizedBox(height: 12),
              _buildInfoRow(
                'Sceance',
                '${_controller.matiereLabel} (${_controller.classeLabel})',
                Colors.black,
              ),
              const SizedBox(height: 12),
              _buildInfoRow('Statut actuel', _selectedStatus!, _selectedColor!),
              const SizedBox(height: 20),
              const Text('Motif',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              TextField(
                controller: _motifController,
                maxLines: 4,
                decoration: InputDecoration(
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF6C5CE7)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFF6C5CE7)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Fermer',
                          style: TextStyle(
                              color: Color(0xFF6C5CE7),
                              fontWeight: FontWeight.bold)),
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
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: const Color(0xFF6C5CE7),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Valider',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
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
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontSize: 14)),
        ),
        Expanded(
          child: Text(value,
              style: TextStyle(
                  color: valueColor,
                  fontSize: 14,
                  fontWeight: valueColor != Colors.black
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
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 85,
        automaticallyImplyLeading: false,
        title: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Center(
            child: Text('Appel de la classe',
                style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 20)),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade300, height: 1),
        ),
      ),
      body: Obx(() {
        if (_controller.isLoading.value && _controller.students.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C5CE7)),
            ),
          );
        }
        if (_controller.error.isNotEmpty && _controller.students.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_controller.error.value, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _controller.loadData,
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            ),
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
                                    color: Color(0xFF6C5CE7), size: 20),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      BorderSide(color: Colors.grey.shade200),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      BorderSide(color: Colors.grey.shade200),
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
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13)),
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
                                    color: Color(0xFF6C5CE7), size: 20),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      BorderSide(color: Colors.grey.shade200),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      BorderSide(color: Colors.grey.shade200),
                                ),
                              ),
                              items: List.generate(
                                  _controller.currentMatieres.length, (i) {
                                final m = _controller.currentMatieres[i];
                                final label = m['nom']?.toString() ?? 'Matière';
                                return DropdownMenuItem(
                                  value: i,
                                  child: Text(label,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13),
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
                            color: const Color(0xFFEDEEFC),
                            borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.calendar_today_outlined,
                                    color: Color(0xFF6C5CE7), size: 18),
                                const SizedBox(width: 8),
                                Text(_formatToday(),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 13)),
                              ],
                            ),
                            const Row(
                              children: [
                                Icon(Icons.access_time,
                                    color: Colors.black87, size: 18),
                                SizedBox(width: 8),
                                Text('Aujourd\'hui',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 13)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem(
                                '${resume['effectif'] ?? students.length}',
                                'Effectif',
                                const Color(0xFF536DFE),
                                Icons.people_outline),
                            _buildStatItem(
                                '${resume['present'] ?? 0}',
                                'Presents',
                                Colors.green,
                                Icons.check_circle_outline),
                            _buildStatItem('${resume['retard'] ?? 0}',
                                'Retards', Colors.orange, Icons.access_time),
                            _buildStatItem('${resume['absent'] ?? 0}',
                                'Absents', Colors.red, Icons.cancel_outlined),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        onChanged: (v) => _controller.searchQuery.value = v,
                        decoration: InputDecoration(
                          hintText: 'Rechercher un étudiant...',
                          hintStyle:
                              const TextStyle(color: Colors.grey, fontSize: 14),
                          suffixIcon: const Icon(Icons.search,
                              color: Colors.grey, size: 22),
                          filled: true,
                          fillColor: const Color(0xFFEFEFEF),
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
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            const Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Nom Etudiant',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                          fontSize: 14)),
                                  Text('Statut',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                          fontSize: 14)),
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
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(
                          color: hasSelection
                              ? const Color(0xFF6C5CE7)
                              : Colors.grey.shade300,
                          width: 1.2,
                        ),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        'Justifier',
                        style: TextStyle(
                          color: hasSelection
                              ? const Color(0xFF6C5CE7)
                              : Colors.grey.shade400,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Obx(() => ElevatedButton(
                          onPressed: (_controller.isSaving.value ||
                                  _controller.isAppelSaved.value)
                              ? null
                              : _controller.saveAppels,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: _controller.isAppelSaved.value
                                ? Colors.grey
                                : const Color(0xFF6C5CE7),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _controller.isSaving.value
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : Text(
                                  _controller.isAppelSaved.value
                                      ? 'Enregistré'
                                      : 'Enregistrer',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15)),
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
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 6),
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.black87)),
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
      backgroundColor = const Color(0xFFE8F5E9);
    } else if (status == 'En retard') {
      backgroundColor = const Color(0xFFFFF3E0);
    } else {
      backgroundColor = const Color(0xFFFFEBEE);
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
            ? const Color(0xFF6C5CE7).withOpacity(0.05)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFF536DFE),
                  child: Text(initial,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Text(name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: Colors.black87)),
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
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: baseColor.withOpacity(0.4), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_getStatusIcon(status), color: baseColor, size: 16),
                    const SizedBox(width: 6),
                    Text(status,
                        style: TextStyle(
                            color: baseColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                    const SizedBox(width: 4),
                    Icon(Icons.keyboard_arrow_down, color: baseColor, size: 16),
                  ],
                ),
              ),
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                _buildPopupItem('Présent', Colors.green, Icons.check_circle),
                const PopupMenuDivider(height: 1),
                _buildPopupItem(
                    'En retard', Colors.orange, Icons.access_time_filled),
                const PopupMenuDivider(height: 1),
                _buildPopupItem('Absent', Colors.red, Icons.cancel),
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
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Text(
            value,
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
