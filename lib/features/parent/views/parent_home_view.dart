import 'package:flutter/material.dart' hide ErrorWidget;
import 'package:get/get.dart';
import '../controllers/parent_home_controller.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../models/child_model.dart';
import '../../../widgets/common/state_widgets.dart';

class ParentHomeView extends GetView<ParentHomeController> {
  const ParentHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Obx(() {
          if (controller.isLoading && controller.children.isEmpty) {
            return Column(
              children: [
                _buildHeader(),
                const Expanded(
                  child: LoadingWidget(),
                ),
              ],
            );
          }

          if (controller.error != null && controller.children.isEmpty) {
            return Column(
              children: [
                _buildHeader(),
                Expanded(child: _buildErrorState()),
              ],
            );
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: controller.loadChildren,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _buildHeader()),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildWelcomePanel(),
                      const SizedBox(height: 16),
                      _buildOverviewCards(),
                      const SizedBox(height: 24),
                      _buildChildrenTitle(),
                      const SizedBox(height: 12),
                      if (controller.children.isEmpty)
                        _buildEmptyState()
                      else
                        ...controller.children.asMap().entries.map((entry) {
                          return _buildAnimatedChildCard(
                            entry.value,
                            entry.key,
                          );
                        }),
                    ]),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildHeader() {
    final authController = Get.find<AuthController>();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.family_restroom,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Obx(() {
              final name =
                  '${authController.userPrenom.value} ${authController.userName.value}'
                      .trim();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _greeting(),
                    style: AppTextStyles.label,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    name.isNotEmpty ? name : 'Parent',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.h3,
                  ),
                ],
              );
            }),
          ),
          IconButton.filledTonal(
            onPressed: controller.loadChildren,
            tooltip: 'Actualiser',
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              foregroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.m),
              ),
            ),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomePanel() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 18 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppRadius.l),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.25),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadius.s + 2),
              ),
              child: Text(
                'Suivi scolaire',
                style: AppTextStyles.label.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Gardez une vue claire sur la progression de vos enfants.',
              style: AppTextStyles.h2.copyWith(
                color: Colors.white,
                height: 1.18,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _watchMessage(),
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.white.withValues(alpha: 0.82),
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 360;
        return GridView.count(
          crossAxisCount: isCompact ? 1 : 3,
          childAspectRatio: isCompact ? 3.1 : 1.18,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          children: [
            _buildMetricTile(
              icon: Icons.groups_rounded,
              label: 'Enfants',
              value: '${controller.childrenCount}',
              color: AppColors.primary,
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.l - 2),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: AppIconSize.m - 2),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.h2.copyWith(fontSize: 22),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.label,
          ),
        ],
      ),
    );
  }

  Widget _buildChildrenTitle() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Mes enfants',
            style: AppTextStyles.h2,
          ),
        ),
        if (controller.children.isNotEmpty)
          Text(
            '${controller.children.length} profil${controller.children.length > 1 ? 's' : ''}',
            style: AppTextStyles.bodySecondary.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }

  Widget _buildChildCard(ChildModel child) {
    final avatarColor = _avatarColor(child.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.l),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => controller.viewChildDetails(child),
        borderRadius: BorderRadius.circular(AppRadius.l),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAvatar(child, avatarColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          child.fullName.trim().isEmpty
                              ? 'Eleve'
                              : child.fullName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.h3,
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            _buildChip(
                              Icons.school_outlined,
                              child.className.isEmpty
                                  ? 'Classe non renseignee'
                                  : child.className,
                              AppColors.primary,
                            ),
                            _buildChip(
                              Icons.insights_outlined,
                              _studentStatus(child),
                              _statusColor(child),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textHint,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildInlineMetric(
                      'Moyenne',
                      controller.childAverages[child.id]?.toStringAsFixed(1) ??
                          '--',
                      AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildInlineMetric(
                      'Absences',
                      '${controller.childAbsences[child.id] ?? 0}',
                      AppColors.warning,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(ChildModel child, Color color) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: child.photoUrl.isNotEmpty
          ? ClipOval(
              child: Image.network(
                child.photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildAvatarInitials(child);
                },
              ),
            )
          : _buildAvatarInitials(child),
    );
  }

  Widget _buildAvatarInitials(ChildModel child) {
    final initials = [
      if (child.firstName.isNotEmpty) child.firstName[0],
      if (child.lastName.isNotEmpty) child.lastName[0],
    ].join().toUpperCase();

    return Center(
      child: Text(
        initials.isEmpty ? '?' : initials,
        style: AppTextStyles.titleMedium.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 18,
        ),
      ),
    );
  }

  Widget _buildChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.s + 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppIconSize.s - 2, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.label.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInlineMetric(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.m),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.label,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.h3.copyWith(color: color, fontSize: 19),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const EmptyWidget(
      icon: Icons.person_search_rounded,
      title: 'Aucun enfant associe',
      message: 'Contactez l\'administration pour rattacher vos enfants a votre compte.',
    );
  }

  Widget _buildErrorState() {
    return ErrorWidget(
      icon: Icons.cloud_off_rounded,
      title: 'Impossible de charger l\'accueil',
      message: controller.error ?? 'Veuillez verifier votre connexion.',
      onRetry: controller.loadChildren,
    );
  }

  Widget _buildAnimatedChildCard(ChildModel child, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 420 + (index * 90)),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return Transform.translate(
          offset: Offset(24 * (1 - value), 0),
          child: Opacity(
            opacity: value,
            child: _buildChildCard(child),
          ),
        );
      },
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bonjour';
    if (hour < 18) return 'Bon apres-midi';
    return 'Bonsoir';
  }

  String _watchMessage() {
    final child = controller.childToWatch;
    if (child == null) {
      return 'Consultez les moyennes, les absences et les details en un geste.';
    }

    return '${child.firstName} a le plus d\'absences pour le moment. Un suivi rapide peut aider a garder le cap.';
  }

  String _studentStatus(ChildModel child) {
    final average = controller.childAverages[child.id] ?? 0;
    final absences = controller.childAbsences[child.id] ?? 0;

    if (absences >= 3) return 'A surveiller';
    if (average >= 12) return 'En bonne voie';
    if (average > 0) return 'A encourager';
    return 'Nouveau suivi';
  }

  Color _statusColor(ChildModel child) {
    final average = controller.childAverages[child.id] ?? 0;
    final absences = controller.childAbsences[child.id] ?? 0;

    if (absences >= 3) return AppColors.warning;
    if (average >= 12) return AppColors.success;
    if (average > 0) return AppColors.info;
    return AppColors.textSecondary;
  }

  Color _avatarColor(String id) {
    const colors = [
      AppColors.primary,
      AppColors.info,
      AppColors.success,
      AppColors.warning,
    ];
    final index =
        id.codeUnits.fold(0, (sum, value) => sum + value) % colors.length;
    return colors[index];
  }
}
