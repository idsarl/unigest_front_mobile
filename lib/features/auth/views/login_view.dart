import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../../../core/config/server_config_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = Get.find<AuthController>();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
   
    if (!ServerConfigService.instance.isConfiguredRx.value) {
      Get.snackbar(
        'Serveur non configuré',
        'Veuillez d\'abord saisir l\'adresse du serveur de votre établissement.',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(AppSpacing.m),
      );
      await Future.delayed(const Duration(seconds: 1));
      Get.offAllNamed('/server-config');
      return;
    }

    await _auth.login(_emailController.text, _passwordController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.l),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.l),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.l),
                      child: Image.asset(
                        'assets/images/logo.jpeg',
                        width: 100,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.l),
                    const Text(
                      'UniGest',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.h1,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    const Text(
                      'Connexion',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySecondary,
                    ),
                    const SizedBox(height: AppSpacing.xl + AppSpacing.s),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email ou téléphone',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Champ requis'
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.m),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Mot de passe',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Champ requis' : null,
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: AppSpacing.s),
                    Obx(() {
                      final err = _auth.error.value;
                      if (err == null) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
                        child: Text(
                          err,
                          style: AppTextStyles.caption.copyWith(color: AppColors.error),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }),
                    const SizedBox(height: AppSpacing.m),
                    Obx(() => SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _auth.isLoading.value ? null : _submit,
                            child: _auth.isLoading.value
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Se connecter'),
                          ),
                        )), 
                        const SizedBox(height: AppSpacing.l),
                    
                    OutlinedButton.icon(
                      onPressed: () async {
                        await ServerConfigService.instance.clearServerUrl();
                        Get.offAllNamed('/server-config');
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.m,
                          horizontal: AppSpacing.l,
                        ),
                        side: const BorderSide(color: AppColors.textHint),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.m),
                        ),
                      ),
                      icon: const Icon(
                        Icons.dns_outlined,
                        size: AppIconSize.m,
                        color: AppColors.textHint,
                      ),
                      label: Text(
                        'Configurer le serveur de mon établissement',
                        style: AppTextStyles.bodySecondary
                            .copyWith(color: AppColors.textHint),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.l),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
