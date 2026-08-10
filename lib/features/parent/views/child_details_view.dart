import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/child_details_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../models/bulletin_model.dart';
import '../../../models/paiement_model.dart';
import '../../../models/message_model.dart';
import '../../../widgets/common/state_widgets.dart';
import '../../../widgets/parent/note_card.dart';
import '../../../widgets/parent/absence_card.dart';
import '../../../widgets/parent/emploi_card.dart';

class ChildDetailsView extends GetView<ChildDetailsController> {
  const ChildDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Obx(() => Text(
              controller.child.value?.fullName ?? 'Détails',
              style: AppTextStyles.h3.copyWith(color: Colors.white),
            )),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Obx(() {
        if (controller.isLoading) {
          return const LoadingWidget();
        }
        return Column(
          children: [
            _buildInfoSection(),
            _buildTabBar(),
            Expanded(
              child: _buildTabContent(),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildInfoSection() {
    final child = controller.child.value;
    final absenceCount = controller.absences.length;
    final justifiedCount =
        controller.absences.where((absence) => absence.justified).length;

    return Container(
      margin: const EdgeInsets.all(AppSpacing.m),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.l),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.20),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.white.withOpacity(0.35), width: 2),
                ),
                child: Center(
                  child: Text(
                    _getInitials(child?.firstName ?? '', child?.lastName ?? ''),
                    style: AppTextStyles.h2.copyWith(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      child?.fullName ?? 'Enfant',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.h3.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildHeaderPill(Icons.school_outlined,
                            child?.className ?? 'Classe'),
                        _buildHeaderPill(Icons.cake_outlined,
                            child?.birthDate ?? 'Date inconnue'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Moyenne',
                  controller.generalAverage.value.toStringAsFixed(2),
                  '/20',
                  AppColors.success,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricCard(
                  'Absences',
                  '$absenceCount',
                  '$justifiedCount just.',
                  absenceCount == 0 ? AppColors.success : AppColors.warning,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricCard(
                  'Cours',
                  '${controller.emploiDuTemps.length}',
                  'semaine',
                  AppColors.info,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getInitials(String firstName, String lastName) {
    final first = firstName.trim().isNotEmpty ? firstName.trim()[0] : '';
    final last = lastName.trim().isNotEmpty ? lastName.trim()[0] : '';
    final initials = '$first$last'.toUpperCase();
    return initials.isEmpty ? 'E' : initials;
  }

  Widget _buildHeaderPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.90), size: AppIconSize.s),
          const SizedBox(width: 6),
          Text(
            text,
            style: AppTextStyles.label.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
      String label, String value, String hint, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.l),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.label,
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.h2.copyWith(color: accent),
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  hint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textHint,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.10),
            borderRadius: BorderRadius.circular(AppRadius.s),
          ),
          child: Icon(icon, size: AppIconSize.m, color: AppColors.primary),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: AppTextStyles.h3,
        ),
      ],
    );
  }

  Widget _buildEmptyState(IconData icon, String title, String subtitle) {
    return EmptyWidget(
      icon: icon,
      title: title,
      message: subtitle,
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.l),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TabBar(
        controller: controller.tabController,
        onTap: (index) => controller.selectedTab.value = index,
        isScrollable: true,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: AppTextStyles.caption.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: AppTextStyles.label,
        indicator: BoxDecoration(
          color: AppColors.primary.withOpacity(0.10),
          borderRadius: BorderRadius.circular(AppRadius.s + 3),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(icon: Icon(Icons.grade_outlined, size: AppIconSize.s + 2), text: 'Notes'),
          Tab(
              icon: Icon(Icons.event_busy_outlined, size: AppIconSize.s + 2),
              text: 'Absences'),
          Tab(
              icon: Icon(Icons.calendar_month_outlined, size: AppIconSize.s + 2),
              text: 'Emploi'),
          Tab(
              icon: Icon(Icons.chat_bubble_outline, size: AppIconSize.s + 2),
              text: 'Messages'),
          Tab(
              icon: Icon(Icons.description_outlined, size: AppIconSize.s + 2),
              text: 'Bulletin'),
          Tab(
              icon: Icon(Icons.payments_outlined, size: AppIconSize.s + 2),
              text: 'Paiements'),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    switch (controller.selectedTab.value) {
      case 0:
        return _buildNotesTab();
      case 1:
        return _buildAbsencesTab();
      case 2:
        return _buildEmploiTab();
      case 3:
        return _buildMessagesTab();
      case 4:
        return _buildBulletinTab();
      case 5:
        return _buildPaiementsTab();
      default:
        return _buildNotesTab();
    }
  }

  Widget _buildNotesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTrimesterSection(),
          const SizedBox(height: 24),
          _buildSubjectAveragesSection(),
          const SizedBox(height: 24),
          _buildNotesListSection(),
        ],
      ),
    );
  }

  Widget _buildTrimesterSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.l),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Premier trimestre',
                  style: AppTextStyles.label,
                ),
                SizedBox(height: 6),
                Text(
                  'Moyenne générale',
                  style: AppTextStyles.h3,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: _getAverageColor(controller.generalAverage.value)
                  .withOpacity(0.12),
              borderRadius: BorderRadius.circular(AppRadius.l - 2),
            ),
            child: Obx(() => Text(
                  controller.generalAverage.value.toStringAsFixed(2),
                  style: AppTextStyles.h3.copyWith(
                    color: _getAverageColor(controller.generalAverage.value),
                  ),
                )),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectAveragesSection() {
    final subjectAverages = controller.getSubjectAverages();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Moyennes par matière', Icons.analytics_outlined),
        const SizedBox(height: 12),
        if (subjectAverages.isEmpty)
          _buildCompactEmptyState('Aucune moyenne disponible')
        else
          ...subjectAverages.entries.map((entry) {
            return _buildSubjectAverageItem(entry.key, entry.value);
          }).toList(),
      ],
    );
  }

  Widget _buildSubjectAverageItem(String subject, double average) {
    final color = _getAverageColor(average);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.m),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              subject,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.titleMedium.copyWith(fontSize: 14),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.m),
            ),
            child: Text(
              average.toStringAsFixed(2),
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getAverageColor(double average) {
    if (average >= 15) return AppColors.success;
    if (average >= 10) return AppColors.info;
    return AppColors.warning;
  }

  Widget _buildCompactEmptyState(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.m),
        border: Border.all(color: AppColors.divider),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppTextStyles.bodySecondary,
      ),
    );
  }

  Widget _buildNotesListSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Détail des notes', Icons.list_alt_outlined),
        const SizedBox(height: 12),
        if (controller.notes.isEmpty)
          _buildCompactEmptyState('Aucune note enregistrée pour cet enfant')
        else
          ...controller.notes.map((note) => NoteCard(note: note)).toList(),
      ],
    );
  }

  Widget _buildAbsencesTab() {
    return Obx(() {
      if (controller.isLoading) {
        return const LoadingWidget();
      }
      if (controller.absences.isEmpty) {
        return _buildEmptyState(
          Icons.verified_user_outlined,
          'Aucune absence',
          'Tout est en ordre pour le moment.',
        );
      }
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(
                'Historique des absences', Icons.event_busy_outlined),
            const SizedBox(height: 12),
            ...controller.absences
                .map((absence) => AbsenceCard(absence: absence))
                .toList(),
          ],
        ),
      );
    });
  }

  Widget _buildEmploiTab() {
    return Obx(() {
      if (controller.isLoading) {
        return const LoadingWidget();
      }
      if (controller.emploiDuTemps.isEmpty) {
        return _buildEmptyState(
          Icons.calendar_month_outlined,
          'Aucun cours',
          'L’emploi du temps sera affiché ici dès qu’il sera disponible.',
        );
      }
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(
                'Emploi du temps', Icons.calendar_month_outlined),
            const SizedBox(height: 12),
            ...controller.emploiDuTemps
                .map((emploi) => EmploiCard(emploi: emploi))
                .toList(),
          ],
        ),
      );
    });
  }

  Widget _buildMessagesTab() {
    return Column(
      children: [
        _buildTeacherSelector(),
        Expanded(
          child: Obx(() {
            if (controller.isLoading) {
              return const LoadingWidget();
            }
            if (controller.selectedTeacher.value == null) {
              return Center(
                child: Text(
                  'Sélectionnez un enseignant pour commencer',
                  style: AppTextStyles.bodyLarge
                      .copyWith(color: AppColors.textSecondary),
                ),
              );
            }
            if (controller.messages.isEmpty) {
              return Center(
                child: Text(
                  'Aucun message',
                  style: AppTextStyles.h3
                      .copyWith(color: AppColors.textSecondary),
                ),
              );
            }
            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: controller.messages.length,
                    itemBuilder: (context, index) {
                      final message = controller.messages[index];
                      return _buildMessageBubble(message);
                    },
                  ),
                ),
                _buildMessageInput(),
              ],
            );
          }),
        ),
      ],
    );
  }

  Widget _buildTeacherSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Enseignants',
            style: AppTextStyles.titleMedium,
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 80,
            child: Obx(() => ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: controller.teachers.length,
                  itemBuilder: (context, index) {
                    final teacher = controller.teachers[index];
                    final isSelected =
                        controller.selectedTeacher.value?.id == teacher.id;
                    return GestureDetector(
                      onTap: () => controller.selectTeacher(teacher),
                      child: Container(
                        width: 70,
                        margin: const EdgeInsets.only(right: 12),
                        child: Column(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.primary.withOpacity(0.3),
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                Icons.person,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.primary,
                                size: AppIconSize.m,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              teacher.firstName,
                              style: AppTextStyles.caption.copyWith(
                                fontSize: 11,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                )),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel message) {
    final isFromUser = message.senderId == 'parent';

    return Align(
      alignment: isFromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16, left: 8, right: 8),
        constraints: const BoxConstraints(maxWidth: 300),
        child: Column(
          crossAxisAlignment:
              isFromUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isFromUser ? AppColors.primary : AppColors.accentLight,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(AppRadius.l),
                  topRight: const Radius.circular(AppRadius.l),
                  bottomLeft: Radius.circular(isFromUser ? AppRadius.l : 4),
                  bottomRight: Radius.circular(isFromUser ? 4 : AppRadius.l),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.content,
                style: AppTextStyles.bodyLarge.copyWith(
                  fontSize: 15,
                  color: isFromUser ? Colors.white : AppColors.textPrimary,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message.formattedTime,
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 11,
                    color: AppColors.textHint,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isFromUser ? message.senderName : message.senderName,
                  style: AppTextStyles.caption.copyWith(fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              icon: const Icon(Icons.attach_file, size: AppIconSize.m - 4),
              onPressed: () {},
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppRadius.l + 8),
                border: Border.all(color: AppColors.divider, width: 1),
              ),
              child: TextField(
                onChanged: (value) => controller.messageText.value = value,
                decoration: InputDecoration(
                  hintText: 'Écrire un message...',
                  hintStyle: const TextStyle(color: AppColors.textHint),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              icon: const Icon(Icons.mic, size: AppIconSize.m - 4),
              onPressed: () {},
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: AppIconSize.m - 4),
              onPressed: controller.sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletinTab() {
    return Obx(() {
      if (controller.isLoading) {
        return const LoadingWidget();
      }
      if (controller.bulletins.isEmpty) {
        return _buildEmptyState(
          Icons.description_outlined,
          'Aucun bulletin',
          "Aucun bulletin n'a encore été publié pour cet enfant.",
        );
      }
      final sorted = [...controller.bulletins]
        ..sort((a, b) => b.periode.compareTo(a.periode));
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Bulletins', Icons.description_outlined),
            const SizedBox(height: 12),
            ...sorted.map((b) => _buildBulletinCard(b)),
          ],
        ),
      );
    });
  }

  Widget _buildBulletinCard(BulletinModel bulletin) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.m),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bulletin.periodeLabel,
                      style: AppTextStyles.titleMedium,
                    ),
                    if (bulletin.anneeScolaire.isNotEmpty)
                      Text(
                        bulletin.anneeScolaire,
                        style: AppTextStyles.caption,
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    bulletin.moyenneGenerale.toStringAsFixed(2),
                    style: AppTextStyles.h3.copyWith(color: AppColors.primary),
                  ),
                  if (bulletin.rang != null)
                    Text('Rang: ${bulletin.rang}',
                        style: AppTextStyles.caption),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...bulletin.lignes.map((ligne) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                        child: Text(ligne.matiere,
                            style: AppTextStyles.bodySecondary.copyWith(
                              fontSize: 13,
                              color: AppColors.textPrimary,
                            ))),
                    Text(ligne.moyenneMatiere.toStringAsFixed(2),
                        style: AppTextStyles.bodySecondary.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        )),
                  ],
                ),
              )),
          if (bulletin.appreciation != null &&
              bulletin.appreciation!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              bulletin.appreciation!,
              style: AppTextStyles.bodySecondary.copyWith(
                fontStyle: FontStyle.italic,
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Obx(() => TextButton.icon(
                  onPressed: controller.isDownloadingBulletin.value
                      ? null
                      : () => controller.downloadBulletinPdf(bulletin),
                  icon: controller.isDownloadingBulletin.value
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.picture_as_pdf, size: AppIconSize.s + 2),
                  label: const Text('Télécharger le PDF'),
                )),
          ),
        ],
      ),
    );
  }

  Widget _buildPaiementsTab() {
    return Obx(() {
      if (controller.isLoading) {
        return const LoadingWidget();
      }
      final resume = controller.paiementResume.value;
      final paiements = controller.paiements;
      if (resume == null && paiements.isEmpty) {
        return _buildEmptyState(
          Icons.payments_outlined,
          'Aucune information de paiement',
          "Aucun frais de scolarité n'a encore été enregistré pour cet enfant.",
        );
      }
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (resume != null) ...[
              _buildSectionTitle('État des frais de scolarité',
                  Icons.account_balance_wallet_outlined),
              const SizedBox(height: 12),
              _buildPaiementResumeCard(resume),
              const SizedBox(height: 20),
            ],
            _buildSectionTitle('Historique des paiements', Icons.history),
            const SizedBox(height: 12),
            if (paiements.isEmpty)
              _buildEmptyState(
                Icons.receipt_long_outlined,
                'Aucun paiement enregistré',
                "L'historique des paiements apparaîtra ici.",
              )
            else
              ...paiements.map((p) => _buildPaiementCard(p)),
          ],
        ),
      );
    });
  }

  Widget _buildPaiementResumeCard(PaiementResumeModel resume) {
    final Color statutColor = resume.statutPaiement == 'COMPLET'
        ? AppColors.success
        : resume.statutPaiement == 'PARTIEL'
            ? AppColors.warning
            : AppColors.error;
    final String statutLabel = resume.statutPaiement == 'COMPLET'
        ? 'Complet'
        : resume.statutPaiement == 'PARTIEL'
            ? 'Partiel'
            : 'Impayé';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.m),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Statut', style: AppTextStyles.titleMedium),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statutColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statutLabel,
                  style: AppTextStyles.label.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          _buildPaiementResumeLine('Frais total', resume.totalBrut),
          if (resume.reduction > 0)
            _buildPaiementResumeLine('Réduction', -resume.reduction),
          _buildPaiementResumeLine('Net à payer', resume.totalNet),
          _buildPaiementResumeLine('Déjà payé', resume.totalPaye),
          const Divider(height: 24),
          _buildPaiementResumeLine('Reste à payer', resume.resteAPayer,
              emphasize: true),
        ],
      ),
    );
  }

  Widget _buildPaiementResumeLine(String label, double value,
      {bool emphasize = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: AppTextStyles.bodySecondary.copyWith(
                  fontSize: emphasize ? 15 : 13,
                  fontWeight: emphasize ? FontWeight.bold : FontWeight.normal,
                  color: AppColors.textPrimary)),
          Text(
            '${value.toStringAsFixed(0)} FCFA',
            style: AppTextStyles.bodySecondary.copyWith(
              fontSize: emphasize ? 16 : 13,
              fontWeight: emphasize ? FontWeight.bold : FontWeight.w600,
              color: emphasize ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaiementCard(PaiementModel paiement) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.m),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${paiement.montant.toStringAsFixed(0)} FCFA',
                style: AppTextStyles.titleMedium.copyWith(color: AppColors.primary),
              ),
              const SizedBox(height: 4),
              Text(paiement.datePaiement, style: AppTextStyles.caption),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(paiement.modePaiement,
                  style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600)),
              if (paiement.reference != null &&
                  paiement.reference!.isNotEmpty)
                Text('Réf: ${paiement.reference}',
                    style: AppTextStyles.caption.copyWith(fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}
