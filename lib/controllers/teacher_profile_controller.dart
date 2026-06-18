import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/session/app_session.dart';
import '../services/teacher_repository.dart';

class TeacherProfileController extends GetxController {
  final TeacherRepository _repo = TeacherRepository();
  final AppSession _session = AppSession.instance;

  int get teacherId => _session.teacherId;

  final RxString teacherName = ''.obs;
  final RxString teacherEmail = ''.obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxBool isEditMode = false.obs;

  final prenomController = TextEditingController();
  final nomController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    loadProfileData();
  }

  void loadProfileData() {
    teacherName.value = _session.teacherName;
    teacherEmail.value = _session.teacherEmail;
    emailController.text = _session.teacherEmail;

    String prenom = '';
    String nom = '';
    final parts = _session.teacherName.trim().split(RegExp(r'\s+'));
    if (parts.isNotEmpty) {
      prenom = parts.first;
      if (parts.length > 1) {
        nom = parts.sublist(1).join(' ');
      }
    }
    prenomController.text = prenom;
    nomController.text = nom;
    
    passwordController.clear();
    confirmPasswordController.clear();
  }

  void toggleEditMode() {
    if (!isEditMode.value) {
      loadProfileData(); // Reset fields when entering edit mode
      error.value = '';
    }
    isEditMode.value = !isEditMode.value;
  }

  Future<void> updateProfile({
    required String prenom,
    required String nom,
    required String email,
  }) async {
    if (prenom.isEmpty || nom.isEmpty || email.isEmpty) {
      error.value = 'Le prénom, nom et email sont obligatoires';
      return;
    }

    final pass = passwordController.text;
    final confirm = confirmPasswordController.text;

    if (pass.isNotEmpty || confirm.isNotEmpty) {
      if (pass != confirm) {
        error.value = 'Les mots de passe ne correspondent pas';
        return;
      }
      if (pass.length < 6) {
        error.value = 'Le mot de passe doit contenir au moins 6 caractères';
        return;
      }
    }

    isLoading.value = true;
    error.value = '';

    try {
      await _repo.updateProfile(
        nom: nom,
        prenom: prenom,
        email: email,
        password: pass.isNotEmpty ? pass : null,
      );

      final newFullName = '$prenom $nom'.trim();
      _session.teacherName = newFullName;
      _session.teacherEmail = email;
      await _session.persist();
      
      teacherName.value = newFullName;
      teacherEmail.value = email;
      
      isEditMode.value = false; // Sortir du mode édition

      Get.snackbar(
        'Succès',
        'Profil mis à jour avec succès !',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      error.value = 'Erreur lors de la mise à jour : $e';
      Get.snackbar(
        'Erreur',
        'Impossible de mettre à jour le profil : $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    _session.clear();
    await _session.clearStorage();
    Get.offAllNamed('/login');
  }

  @override
  void onClose() {
    prenomController.dispose();
    nomController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}
