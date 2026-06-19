import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/teacher_profile_controller.dart';
import '../core/session/app_session.dart';

class TeacherProfileView extends StatelessWidget {
  const TeacherProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(TeacherProfileController());

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Mon Profil',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.grey.shade300,
            height: 1,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar et informations de base (Joli Card)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C5CE7).withOpacity(0.1),
                      spreadRadius: 5,
                      blurRadius: 20,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF6C5CE7).withOpacity(0.3), width: 3),
                      ),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: const Color(0xFF6C5CE7),
                        child: Obx(() => Text(
                          _initials(controller.teacherName.value),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        )),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Obx(() => Text(
                          controller.teacherName.value,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2D3436),
                          ),
                        )),
                    const SizedBox(height: 8),
                    Obx(() => Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.email_outlined, size: 16, color: Colors.grey),
                            const SizedBox(width: 5),
                            Text(
                              controller.teacherEmail.value,
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.black54,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        )),
                    const SizedBox(height: 15),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6C5CE7).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.school, size: 16, color: Color(0xFF6C5CE7)),
                          SizedBox(width: 8),
                          Text(
                            'Enseignant',
                            style: TextStyle(
                              color: Color(0xFF6C5CE7),
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Obx pour basculer entre mode vue et mode édition
              Obx(() => controller.isEditMode.value
                  ? Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Modifier mon profil',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 15),

                          // Champ Prénom
                          _buildTextFieldLabel('Prénom'),
                          const SizedBox(height: 8),
                          _buildTextField(controller.prenomController, 'Entrez votre prénom', Icons.person_outline),
                          const SizedBox(height: 15),

                          // Champ Nom
                          _buildTextFieldLabel('Nom'),
                          const SizedBox(height: 8),
                          _buildTextField(controller.nomController, 'Entrez votre nom', Icons.person_outline),
                          const SizedBox(height: 15),

                          // Champ Email
                          _buildTextFieldLabel('Email'),
                          const SizedBox(height: 8),
                          _buildTextField(controller.emailController, 'Entrez votre email', Icons.email_outlined, isEmail: true),
                          const SizedBox(height: 15),

                          // Champ Nouveau mot de passe
                          _buildTextFieldLabel('Nouveau mot de passe (optionnel)'),
                          const SizedBox(height: 8),
                          _buildTextField(controller.passwordController, 'Nouveau mot de passe', Icons.lock_outline, isPassword: true),
                          const SizedBox(height: 15),

                          // Champ Confirmer mot de passe
                          _buildTextFieldLabel('Confirmer le mot de passe'),
                          const SizedBox(height: 8),
                          _buildTextField(controller.confirmPasswordController, 'Confirmer le mot de passe', Icons.lock_outline, isPassword: true),
                          const SizedBox(height: 20),

                          // Message d'erreur
                          if (controller.error.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 15),
                              decoration: BoxDecoration(
                                color: Colors.red.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                controller.error.value,
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontSize: 13,
                                ),
                              ),
                            ),

                          // Boutons Enregistrer et Annuler
                          Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: controller.isLoading.value ? null : controller.toggleEditMode,
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                  child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 2,
                                child: ElevatedButton(
                                  onPressed: controller.isLoading.value
                                      ? null
                                      : () {
                                          controller.updateProfile(
                                            prenom: controller.prenomController.text,
                                            nom: controller.nomController.text,
                                            email: controller.emailController.text,
                                          );
                                        },
                                  style: ButtonStyle(
                                    backgroundColor: WidgetStateProperty.all(
                                      controller.isLoading.value ? Colors.grey : const Color(0xFF6C5CE7),
                                    ),
                                    foregroundColor: WidgetStateProperty.all(Colors.white),
                                    padding: WidgetStateProperty.all(const EdgeInsets.symmetric(vertical: 14)),
                                    shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                                  ),
                                  child: controller.isLoading.value
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                                        )
                                      : const Text('Enregistrer', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  : Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Actions',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 15),

                          // Bouton Modifier
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: controller.toggleEditMode,
                              icon: const Icon(Icons.edit, color: Color(0xFF6C5CE7)),
                              label: const Text(
                                'Modifier mon profil',
                                style: TextStyle(color: Color(0xFF6C5CE7), fontSize: 15),
                              ),
                              style: ButtonStyle(
                                backgroundColor: WidgetStateProperty.all(const Color(0xFFE8E6FF)),
                                alignment: Alignment.centerLeft,
                                padding: WidgetStateProperty.all(const EdgeInsets.symmetric(vertical: 12, horizontal: 16)),
                                shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                              ),
                            ),
                          ),

                        ],
                      ),
                    )),
            ],
          ),
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  Widget _buildTextFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {bool isEmail = false, bool isPassword = false}) {
    return TextField(
      controller: controller,
      keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
      obscureText: isPassword,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF6C5CE7)),
        ),
      ),
    );
  }
}
