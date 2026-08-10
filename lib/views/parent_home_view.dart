import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/session/app_session.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_dimens.dart';
import 'parent_view.dart';

class ParentHomeView extends StatelessWidget {
  const ParentHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final session = AppSession.instance;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bonjour,',
                        style: AppTextStyles.bodyLarge
                            .copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(session.teacherName, style: AppTextStyles.h1.copyWith(fontSize: 24)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(AppRadius.l),
                    ),
                    child: const Icon(Icons.person_outline,
                        color: AppColors.surface, size: AppIconSize.l),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              const Text('Que voulez-vous faire ?', style: AppTextStyles.h2),
              const SizedBox(height: 24),
              _MenuCard(
                icon: Icons.chat_outlined,
                title: 'Messages',
                subtitle: 'Contacter les enseignants',
                color: AppColors.primary,
                onTap: () {
                  Get.to(() => const ParentView());
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.m),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.m),
                ),
                child: Icon(icon, color: color, size: AppIconSize.l),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.titleMedium.copyWith(fontSize: 17)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: AppTextStyles.bodySecondary),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios,
                  color: AppColors.textHint, size: AppIconSize.s),
            ],
          ),
        ),
      ),
    );
  }
}
