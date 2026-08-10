import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/parent_profile_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../models/child_model.dart';
import '../../../widgets/common/state_widgets.dart';

class ParentProfileView extends GetView<ParentProfileController> {
  const ParentProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Obx(() {
        if (controller.isLoading) {
          return const LoadingWidget();
        }

        return RefreshIndicator(
          onRefresh: controller.loadProfile,
          color: AppColors.primary,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildProfileHero()),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildQuickStats(),
                    const SizedBox(height: 18),
                    _buildPersonalInfo(),
                    const SizedBox(height: 18),
                    _buildChildrenSection(),
                    const SizedBox(height: 18),
                    _buildSettingsSection(),
                    const SizedBox(height: 18),
                    _buildLogoutButton(),
                  ]),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildProfileHero() {
    final parent = controller.parent.value;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 62, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.34),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    _getInitials(
                        parent?.firstName ?? '', parent?.lastName ?? ''),
                    style: AppTextStyles.h1.copyWith(
                      color: Colors.white,
                      fontSize: 26,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      parent?.fullName ?? 'Profil parent',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.h1.copyWith(
                        fontSize: 25,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      parent?.email ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white.withValues(alpha: 0.86),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildHeroPill(Icons.verified_user_outlined, 'Compte parent'),
              _buildHeroPill(
                Icons.calendar_today_outlined,
                'Depuis ${_formatJoinDate(parent?.createdAt)}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: AppIconSize.s),
          const SizedBox(width: 7),
          Text(
            text,
            style: AppTextStyles.label.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    final childrenCount = controller.children.length;
    final classes = controller.children
        .map((child) => child.className)
        .where((className) => className.trim().isNotEmpty)
        .toSet()
        .length;

    return Row(
      children: [
        Expanded(
          child: _buildStatTile(
            Icons.family_restroom_outlined,
            '$childrenCount',
            childrenCount > 1 ? 'Enfants suivis' : 'Enfant suivi',
            AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatTile(
            Icons.school_outlined,
            '$classes',
            classes > 1 ? 'Classes' : 'Classe',
            AppColors.info,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatTile(
            Icons.notifications_active_outlined,
            'Actif',
            'Notifications',
            AppColors.success,
          ),
        ),
      ],
    );
  }

  Widget _buildStatTile(
    IconData icon,
    String value,
    String label,
    Color accent,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.l),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppRadius.s + 2),
            ),
            child: Icon(icon, color: accent, size: AppIconSize.s + 2),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.h3.copyWith(fontSize: 19, color: accent),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.label.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfo() {
    final parent = controller.parent.value;

    return _buildSectionCard(
      title: 'Informations personnelles',
      icon: Icons.badge_outlined,
      child: Column(
        children: [
          _buildInfoRow(
            Icons.mail_outline,
            'Email',
            parent?.email ?? 'Non renseigné',
          ),
          _buildDivider(),
          _buildInfoRow(
            Icons.phone_outlined,
            'Téléphone',
            _fallback(parent?.phone),
          ),
          _buildDivider(),
          _buildInfoRow(
            Icons.location_on_outlined,
            'Adresse',
            _fallback(parent?.address),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(AppRadius.m),
            ),
            child: Icon(icon, color: AppColors.primary, size: AppIconSize.s + 4),
          ),
          const SizedBox(width: 12),
          Expanded(
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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChildrenSection() {
    return _buildSectionCard(
      title: 'Mes enfants',
      icon: Icons.groups_2_outlined,
      trailing: Text(
        '${controller.children.length}',
        style: AppTextStyles.titleMedium.copyWith(color: AppColors.primary),
      ),
      child: controller.children.isEmpty
          ? _buildEmptyChildren()
          : Column(
              children: controller.children
                  .map((child) => _buildChildItem(child))
                  .toList(),
            ),
    );
  }

  Widget _buildChildItem(ChildModel child) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.l - 2),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _getInitials(child.firstName, child.lastName),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  child.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleMedium.copyWith(fontSize: 15),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.school_outlined,
                      size: AppIconSize.s - 1,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        _fallback(child.className),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.label,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.s + 2),
              border: Border.all(color: AppColors.divider),
            ),
            child: const Icon(
              Icons.chevron_right,
              color: AppColors.textHint,
              size: AppIconSize.m - 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChildren() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.l - 2),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          const Icon(Icons.school_outlined, color: AppColors.primary, size: AppIconSize.l - 2),
          const SizedBox(height: 10),
          const Text(
            'Aucun enfant rattaché',
            style: AppTextStyles.titleMedium,
          ),
          const SizedBox(height: 5),
          Text(
            'Les enfants associés à ce compte apparaîtront ici.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySecondary.copyWith(fontSize: 13, height: 1.35),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return _buildSectionCard(
      title: 'Paramètres',
      icon: Icons.tune_outlined,
      child: Column(
        children: [
          _buildSettingItem(
            Icons.notifications_none_outlined,
            'Notifications',
            'Alertes scolaires et messages',
          ),
          _buildDivider(),
          _buildSettingItem(
            Icons.language_outlined,
            'Langue',
            'Français',
          ),
          _buildDivider(),
          _buildSettingItem(
            Icons.lock_outline,
            'Sécurité',
            'Mot de passe et accès',
          ),
          _buildDivider(),
          _buildSettingItem(
            Icons.help_outline,
            'Aide',
            'Support et assistance',
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(IconData icon, String title, String subtitle) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(AppRadius.m),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(AppRadius.m),
              ),
              child: Icon(icon, color: AppColors.primary, size: AppIconSize.s + 4),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textHint,
              size: AppIconSize.m - 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.l + 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppRadius.s + 3),
                ),
                child: Icon(icon, color: AppColors.primary, size: AppIconSize.s + 3),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.h3,
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Divider(height: 1, color: AppColors.divider),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          Get.dialog(
            AlertDialog(
              title: const Text('Déconnexion'),
              content:
                  const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
              actions: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: const Text('Annuler'),
                ),
                TextButton(
                  onPressed: () {
                    Get.back();
                    controller.logout();
                  },
                  child: const Text('Déconnexion'),
                ),
              ],
            ),
          );
        },
        icon: const Icon(Icons.logout, size: AppIconSize.s + 4),
        label: const Text('Déconnexion'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.error,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.l - 2),
          ),
        ),
      ),
    );
  }

  String _getInitials(String firstName, String lastName) {
    final first = firstName.trim().isNotEmpty ? firstName.trim()[0] : '';
    final last = lastName.trim().isNotEmpty ? lastName.trim()[0] : '';
    final initials = '$first$last'.toUpperCase();
    return initials.isEmpty ? 'P' : initials;
  }

  String _formatJoinDate(DateTime? date) {
    if (date == null) return 'aujourd’hui';
    final month = date.month.toString().padLeft(2, '0');
    return '$month/${date.year}';
  }

  String _fallback(String? value) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? 'Non renseigné' : text;
  }
}
