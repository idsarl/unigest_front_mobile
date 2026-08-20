import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/server_config_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';

class ServerConfigView extends StatelessWidget {
  const ServerConfigView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ServerConfigController());

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.l),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
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
                    'Configuration du serveur',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySecondary,
                  ),
                  const SizedBox(height: AppSpacing.s),
                  const Text(
                    'Pour vous connecter, cette application a besoin de connaître '
                    'l\'adresse du serveur de votre établissement. '
                    'Cette information vous est fournie par votre administrateur.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySecondary,
                  ),
                  const SizedBox(height: AppSpacing.m),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.m),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppRadius.m),
                      border: Border.all(
                        color: AppColors.info.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: AppColors.info,
                          size: AppIconSize.m,
                        ),
                        const SizedBox(width: AppSpacing.s),
                        Expanded(
                          child: Text(
                            'Saisissez uniquement le nom de domaine du serveur, '
                            'sans "https://".\n'
                            'Exemple : api.lyuni-gest.com',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.info,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.l),
                  TextField(
                    controller: controller.urlFieldController,
                    keyboardType: TextInputType.url,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: const InputDecoration(
                      labelText: 'Adresse du serveur',
                      hintText: 'api.mon-etablissement.com',
                      prefixIcon: Icon(Icons.dns_outlined),
                      // prefixText: 'https://',
                    ),
                    onSubmitted: (_) => controller.validateAndSave(),
                  ),
                  const SizedBox(height: AppSpacing.s),
                  Obx(() {
                    final err = controller.errorMessage.value;
                    if (err == null) return const SizedBox.shrink();
                    return Padding(
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.s),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: AppColors.error,
                            size: AppIconSize.s,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              err,
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.error),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: AppSpacing.m),
                  Obx(() => SizedBox(
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: controller.isLoading.value
                              ? null
                              : controller.validateAndSave,
                          icon: controller.isLoading.value
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.wifi_tethering),
                          label: Text(
                            controller.isLoading.value
                                ? 'Vérification...'
                                : 'Valider et continuer',
                          ),
                        ),
                      )),
                  const SizedBox(height: AppSpacing.l),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
