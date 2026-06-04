import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/teacher_home_controller.dart';
import '../core/session/app_session.dart';
import '../features/auth/controllers/auth_controller.dart';

class TeacherHomeView extends StatelessWidget {
  const TeacherHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialisation du contrôleur GetX
    final controller = Get.put(TeacherHomeController());

    return Scaffold(
      // Fond du corps de la page en gris très clair conforme à l'image
      backgroundColor: const Color(0xFFF8F9FA),

      // LE HAUT DE LA PAGE : Fond blanc avec le trait de séparation horizontal
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 85, // Donne de l'espace pour respirer comme sur l'UI
        automaticallyImplyLeading: false,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Bonjour,',
                      style: TextStyle(fontSize: 16, color: Colors.black54, fontWeight: FontWeight.normal)),
                  const SizedBox(height: 2),
                  Obx(() => Text(
                        controller.teacherName.value,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
                      )),
                ],
              ),
              Row(
                children: [
                  Stack(
                    children: [
                      const Icon(Icons.notifications_none_outlined, size: 30, color: Colors.black87),
                      Positioned(
                        right: 3,
                        top: 3,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 15),
                  PopupMenuButton<String>(
                    offset: const Offset(0, 40),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onSelected: (value) {
                      if (value == 'logout') {
                        Get.find<AuthController>().logout();
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'logout',
                        child: Row(
                          children: [
                            Icon(Icons.logout, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Déconnexion'),
                          ],
                        ),
                      ),
                    ],
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: const Color(0xFF6C5CE7),
                      child: Text(
                        _initials(AppSession.instance.teacherName),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // LE TRAIT GRIS : Sépare proprement l'en-tête blanc du corps gris de l'application
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.grey.shade300,
            height: 1,
          ),
        ),
      ),

      // LE CORPS DE LA PAGE (Défilement uniquement ici)
      body: SafeArea(
        child: Obx(() {
          // Affichage d'un indicateur de chargement au tout premier chargement
          if (controller.isLoading.value && controller.seances.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C5CE7)),
              ),
            );
          }

          // Affichage d'une vue d'erreur si la récupération échoue au démarrage
          if (controller.error.isNotEmpty && controller.seances.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 50, color: Colors.redAccent),
                    const SizedBox(height: 15),
                    Text(
                      controller.error.value,
                      style: const TextStyle(fontSize: 15, color: Colors.black87),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 15),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C5CE7),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => controller.fetchDashboardData(),
                      child: const Text('Réessayer', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            color: const Color(0xFF6C5CE7),
            onRefresh: () => controller.fetchDashboardData(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // PROCHAIN COURS CARD DYNAMIQUE
                  _buildProchainCoursCard(controller),
                  const SizedBox(height: 15),

                  // STATS (Cours / Absences) DYNAMIQUES
                  Row(
                    children: [
                      _buildSmallStatCard(
                        '${controller.seances.length}',
                        "Cours Aujourd'hui",
                        Colors.blue,
                      ),
                      const SizedBox(width: 15),
                      _buildSmallStatCard(
                        '${controller.absencesCount.value}',
                        'Absences',
                        Colors.red,
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),

                  const Text('Statistique', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black)),
                  const SizedBox(height: 15),

                  // GRID DYNAMIQUE POUR LES STATISTIQUES DES CLASSES
                  _buildStatsGrid(controller),
                  const SizedBox(height: 25),

                  const Text('AGENDA DU JOUR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                  const SizedBox(height: 15),

                  // AGENDA DYNAMIQUE DU JOUR
                  _buildAgendaList(controller),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  // --- COMPOSANT PROCHAIN COURS ---
  Widget _buildProchainCoursCard(TeacherHomeController controller) {
    final prochaine = controller.prochaineSeance;
    if (prochaine.isEmpty || prochaine['message'] != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Prochain cours', style: TextStyle(color: Colors.black54, fontSize: 13)),
            SizedBox(height: 6),
            Text('Aucun cours restant', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black54)),
            SizedBox(height: 6),
            Text("Bonne fin de journée !", style: TextStyle(color: Colors.black87, fontSize: 14)),
          ],
        ),
      );
    }

    final minutes = prochaine['minutesRestantes'] ?? 0;
    final String timeString = minutes >= 60 
        ? '${(minutes / 60).floor()}h ${minutes % 60} min'
        : '$minutes min';

    final matiere = prochaine['matiere'] ?? 'Cours';
    final classe = prochaine['classe'] ?? '';
    final String label = classe.isNotEmpty ? ' . $classe' : '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Prochain cours dans', style: TextStyle(color: Colors.black54, fontSize: 13)),
          const SizedBox(height: 6),
          Text(timeString, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text('$matiere$label', style: const TextStyle(color: Colors.black87, fontSize: 14)),
        ],
      ),
    );
  }

  // --- COMPOSANT GRILLE DES STATISTIQUES ---
  Widget _buildStatsGrid(TeacherHomeController controller) {
    final moyenneData = controller.moyenneMatiere;
    if (moyenneData.isEmpty || moyenneData['message'] != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Center(
          child: Text(
            'Aucune statistique de note disponible aujourd\'hui.',
            style: TextStyle(color: Colors.black54, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final List<dynamic> classes = moyenneData['moyenneParClasse'] ?? [];
    final double moyenneGenerale = double.tryParse(moyenneData['moyenneGenerale']?.toString() ?? '0') ?? 0.0;
    
    // Calcul du total des étudiants
    int totalEtudiants = 0;
    for (var cl in classes) {
      totalEtudiants += int.tryParse(cl['nombreEtudiants']?.toString() ?? '0') ?? 0;
    }

    // Couleurs prédéfinies pour les cartes
    final List<Color> cardColors = [
      const Color(0xFF536DFE),
      Colors.green,
      Colors.orange,
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: classes.length + 1, // +1 pour la carte générale
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 15,
        crossAxisSpacing: 15,
        childAspectRatio: 1.4,
      ),
      itemBuilder: (context, index) {
        if (index < classes.length) {
          final cl = classes[index];
          final String nomClasse = cl['classeNom'] ?? 'Classe';
          final double moy = double.tryParse(cl['moyenne']?.toString() ?? '0') ?? 0.0;
          final int etudiants = cl['nombreEtudiants'] ?? 0;
          final Color color = cardColors[index % cardColors.length];
          final String noteStr = moy.toStringAsFixed(moy % 1 == 0 ? 0 : 1);

          return _buildClassStatCard(
            nomClasse,
            noteStr,
            '$etudiants etudiants',
            color,
            Icons.bar_chart_outlined,
          );
        } else {
          final String noteStr = moyenneGenerale.toStringAsFixed(moyenneGenerale % 1 == 0 ? 0 : 1);
          return _buildClassStatCard(
            'General',
            noteStr,
            '$totalEtudiants etudiants',
            Colors.red,
            Icons.show_chart,
          );
        }
      },
    );
  }

  // --- COMPOSANT LISTE AGENDA ---
  Widget _buildAgendaList(TeacherHomeController controller) {
    if (controller.seances.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Center(
          child: Text(
            'Aucun cours planifié pour aujourd\'hui.',
            style: TextStyle(color: Colors.black54, fontSize: 13),
          ),
        ),
      );
    }

    final List<Color> agendaColors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: controller.seances.length,
        separatorBuilder: (context, index) => const Divider(height: 1, indent: 20, endIndent: 20),
        itemBuilder: (context, index) {
          final s = controller.seances[index];
          final String hDebut = _formatTime(s['heureDebut'] ?? '');
          final String hFin = _formatTime(s['heureFin'] ?? '');
          final String matiere = s['matiere'] ?? 'Cours';
          final String classe = s['classe'] ?? 'Classe';
          final Color color = agendaColors[index % agendaColors.length];

          return _buildAgendaRow(hDebut, hFin, matiere, classe, color);
        },
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  String _formatTime(String rawTime) {
    if (rawTime.isEmpty) return '--h--';
    final parts = rawTime.split(':');
    if (parts.length >= 2) {
      return '${parts[0]}h${parts[1]}';
    }
    return rawTime;
  }

  // --- METHODES D'ORIGINE POUR LA CONSEVATION VISUELLE DES COMPOSANTS ---
  Widget _buildSmallStatCard(String value, String title, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ],
        ),
      ),
    );
  }

  Widget _buildAgendaRow(String t1, String t2, String subject, String sub, Color color) {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: Row(
        children: [
          Container(width: 4, height: 40, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t1, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              Text(t2, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
          const SizedBox(width: 30),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(subject, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Text(sub, style: const TextStyle(color: Colors.black54, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClassStatCard(String className, String note, String studentCount, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                className,
                style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w500),
              ),
              Icon(icon, color: color, size: 22),
            ],
          ),
          Text(
            note,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
          ),
          Text(
            'sur 20 . $studentCount',
            style: const TextStyle(fontSize: 11, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}