import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/teacher_profile_controller.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_dimens.dart';

class TeacherProfileView extends StatelessWidget {
  const TeacherProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(TeacherProfileController());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Mon Profil',
          style: AppTextStyles.h2,
        ),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: AppColors.divider,
            height: 1,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.m, vertical: AppSpacing.m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar et informations de base (Joli Card)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.l),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.1),
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
                        border: Border.all(
                            color: AppColors.primary.withOpacity(0.3),
                            width: 3),
                      ),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: AppColors.primary,
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
                          style: AppTextStyles.h2
                              .copyWith(fontWeight: FontWeight.w800),
                        )),
                    const SizedBox(height: 8),
                    Obx(() => Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.email_outlined,
                                size: AppIconSize.s,
                                color: AppColors.textSecondary),
                            const SizedBox(width: 5),
                            Text(
                              controller.teacherEmail.value,
                              style: AppTextStyles.bodyMedium.copyWith(
                                  fontSize: 15, fontWeight: FontWeight.w500),
                            ),
                          ],
                        )),
                    const SizedBox(height: 15),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.school,
                              size: AppIconSize.s, color: AppColors.primary),
                          SizedBox(width: 8),
                          Text(
                            'Enseignant',
                            style: TextStyle(
                              color: AppColors.primary,
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
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.l),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Modifier mon profil',
                            style: AppTextStyles.titleMedium,
                          ),
                          const SizedBox(height: 15),

                          // Champ Prénom
                          _buildTextFieldLabel('Prénom'),
                          const SizedBox(height: 8),
                          _buildTextField(controller.prenomController,
                              'Entrez votre prénom', Icons.person_outline),
                          const SizedBox(height: 15),

                          // Champ Nom
                          _buildTextFieldLabel('Nom'),
                          const SizedBox(height: 8),
                          _buildTextField(controller.nomController,
                              'Entrez votre nom', Icons.person_outline),
                          const SizedBox(height: 15),

                          // Champ Email
                          _buildTextFieldLabel('Email'),
                          const SizedBox(height: 8),
                          _buildTextField(controller.emailController,
                              'Entrez votre email', Icons.email_outlined,
                              isEmail: true),
                          const SizedBox(height: 15),

                          // Champ Nouveau mot de passe
                          _buildTextFieldLabel(
                              'Nouveau mot de passe (optionnel)'),
                          const SizedBox(height: 8),
                          _buildTextField(controller.passwordController,
                              'Nouveau mot de passe', Icons.lock_outline,
                              isPassword: true),
                          const SizedBox(height: 15),

                          // Champ Confirmer mot de passe
                          _buildTextFieldLabel('Confirmer le mot de passe'),
                          const SizedBox(height: 8),
                          _buildTextField(controller.confirmPasswordController,
                              'Confirmer le mot de passe', Icons.lock_outline,
                              isPassword: true),
                          const SizedBox(height: 20),

                          // Message d'erreur
                          if (controller.error.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 15),
                              decoration: BoxDecoration(
                                color: AppColors.error.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(AppRadius.s),
                              ),
                              child: Text(
                                controller.error.value,
                                style: AppTextStyles.bodySecondary
                                    .copyWith(color: AppColors.error),
                              ),
                            ),

                          // Boutons Enregistrer et Annuler
                          Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: controller.isLoading.value
                                      ? null
                                      : controller.toggleEditMode,
                                  child: const Text('Annuler'),
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
                                            prenom: controller
                                                .prenomController.text,
                                            nom: controller.nomController.text,
                                            email:
                                                controller.emailController.text,
                                          );
                                        },
                                  child: controller.isLoading.value
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                      Colors.white)),
                                        )
                                      : const Text('Enregistrer'),
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
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.l),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Actions',
                            style: AppTextStyles.titleMedium,
                          ),
                          const SizedBox(height: 15),

                          // Bouton Modifier
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: controller.toggleEditMode,
                              icon: const Icon(Icons.edit,
                                  color: AppColors.primary),
                              label: Text(
                                'Modifier mon profil',
                                style: AppTextStyles.bodyMedium
                                    .copyWith(color: AppColors.primary),
                              ),
                              style: ButtonStyle(
                                backgroundColor: WidgetStateProperty.all(
                                    AppColors.primary.withOpacity(0.1)),
                                alignment: Alignment.centerLeft,
                                padding: WidgetStateProperty.all(
                                    const EdgeInsets.symmetric(
                                        vertical: 12, horizontal: 16)),
                                shape: WidgetStateProperty.all(
                                    RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(AppRadius.s))),
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
      style: AppTextStyles.label.copyWith(color: AppColors.textPrimary),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String hint, IconData icon,
      {bool isEmail = false, bool isPassword = false}) {
    return TextField(
      controller: controller,
      keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
      obscureText: isPassword,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
      ),
    );
  }
}
