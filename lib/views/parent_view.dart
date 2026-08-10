import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';
import '../controllers/parent_controller.dart';
import '../core/session/app_session.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_dimens.dart';
import '../widgets/common/state_widgets.dart';

class ParentView extends StatefulWidget {
  const ParentView({super.key});

  @override
  State<ParentView> createState() => _ParentViewState();
}

class _ParentViewState extends State<ParentView>
    with SingleTickerProviderStateMixin {
  final ParentController _apiController = Get.put(ParentController());
  final _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isViewingStudents = false;
  Map<String, dynamic>? _selectedStudent;

  String _currentClass = '';
  String _currentSubject = '';

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 100,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentClass.isEmpty && _apiController.classList.isNotEmpty) {
      _currentClass = _apiController.classList.first;
      _currentSubject = _apiController.subjectList.isNotEmpty
          ? _apiController.subjectList.first
          : '';
    }
    return Obx(() {
      if (_apiController.activeContact.value != null)
        return _buildChatRoomView();

      if (_selectedStudent != null) return _buildStudentInfoView();
      if (_isViewingStudents) return _buildStudentListView();

      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildSimpleAppBar('Communication', showBack: false),
        body: SafeArea(
          top: false,
          child: Obx(() {
            if (_apiController.isLoading.value &&
                _apiController.conversations.isEmpty) {
              return const LoadingWidget();
            }
            final isTeacher = AppSession.instance.role == 'ENSEIGNANT';
            return Stack(
              children: [
                RefreshIndicator(
                  onRefresh: _apiController.loadConversations,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        TextField(
                          onChanged: (v) => _apiController.chatSearch.value = v,
                          decoration: InputDecoration(
                            hintText: isTeacher
                                ? 'Rechercher un parent...'
                                : 'Rechercher un enseignant...',
                            hintStyle: AppTextStyles.bodyMedium
                                .copyWith(color: AppColors.textHint),
                            suffixIcon: Icon(Icons.search,
                                color: AppColors.textSecondary, size: AppIconSize.m),
                            filled: true,
                            fillColor: AppColors.surface,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.m),
                              borderSide:
                                  BorderSide(color: AppColors.divider),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(AppRadius.m)),
                              borderSide: BorderSide(color: AppColors.primary),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildChatTabs(),
                        const SizedBox(height: 16),
                        _buildChatList(),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
                if (isTeacher) _buildFAB(),
              ],
            );
          }),
        ),
      );
    });
  }

  // ÉTAPE 2 : LISTE DES ÉTUDIANTS
  Widget _buildStudentListView() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildSimpleAppBar('Liste des Etudiants', onBack: () {
        setState(() => _isViewingStudents = false);
      }),
      body: SafeArea(
        top: false,
        child: Obx(() {
          if (_apiController.isLoading.value &&
              _apiController.students.isEmpty) {
            return const LoadingWidget();
          }
          final students = _apiController.filteredStudents;
          final classList = _apiController.classList;
          final subjectList = _apiController.subjectList;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (classList.isNotEmpty)
                  Row(
                    children: [
                      _buildDropdownSelector(
                        icon: Icons.groups_outlined,
                        selectedValue: _currentClass.isEmpty
                            ? classList.first
                            : _currentClass,
                        items: classList,
                        onChanged: (newValue) async {
                          setState(() => _currentClass = newValue!);
                          await _apiController
                              .selectAffectationByClass(newValue!);
                          if (_apiController.subjectList.isNotEmpty) {
                            setState(() => _currentSubject =
                                _apiController.subjectList.first);
                          }
                        },
                      ),
                      const SizedBox(width: 12),
                      if (subjectList.isNotEmpty)
                        _buildDropdownSelector(
                          icon: Icons.menu_book_outlined,
                          selectedValue: _currentSubject.isEmpty
                              ? subjectList.first
                              : _currentSubject,
                          items: subjectList,
                          onChanged: (newValue) =>
                              setState(() => _currentSubject = newValue!),
                        ),
                    ],
                  ),
                const SizedBox(height: 16),
                TextField(
                  onChanged: (v) => _apiController.searchQuery.value = v,
                  decoration: InputDecoration(
                    hintText: 'Rechercher un étudiant ou parent...',
                    hintStyle: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textHint),
                    suffixIcon: Icon(Icons.search,
                        color: AppColors.textSecondary, size: AppIconSize.m),
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.m),
                        borderSide: BorderSide(color: AppColors.divider)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.m),
                        borderSide: const BorderSide(color: AppColors.primary)),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.m),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: students.isEmpty
                      ? const EmptyWidget(
                          title: 'Aucun étudiant trouvé',
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: students.length,
                          separatorBuilder: (context, index) => Divider(
                              height: 1,
                              color: AppColors.divider,
                              indent: 70),
                          itemBuilder: (context, index) {
                            final student = students[index];
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 6),
                              leading: CircleAvatar(
                                radius: 24,
                                backgroundColor: student['bg'] as Color,
                                child: Text(student['initial'],
                                    style: AppTextStyles.titleMedium
                                        .copyWith(color: student['txt'] as Color)),
                              ),
                              title: Text(student['name'],
                                  style: AppTextStyles.titleMedium),
                              onTap: () =>
                                  setState(() => _selectedStudent = student),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // --- NOUVELLE VUE : PAGE DE DISCUSSION DIRECTE (Fidèle à l'image) ---
  Widget _buildChatRoomView() {
    final contact = _apiController.activeContact.value!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        toolbarHeight: 85,
        automaticallyImplyLeading: false,
        title: SafeArea(
          child: Row(
            children: [
              IconButton(
                onPressed: () {
                  _apiController.closeConversation();
                  _messageController.clear();
                },
                icon: const Icon(Icons.arrow_back_ios,
                    size: AppIconSize.s, color: AppColors.textPrimary),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 18,
                backgroundColor:
                    contact['bg'] as Color? ?? AppColors.success.withOpacity(0.12),
                child: Text(
                  contact['initial']?.toString() ?? '?',
                  style: AppTextStyles.label
                      .copyWith(color: contact['txt'] as Color? ?? AppColors.success),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                contact['name']?.toString() ?? 'Contact',
                style: AppTextStyles.titleMedium.copyWith(fontSize: 16),
              ),
            ],
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.divider, height: 1),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Zone des messages
            Expanded(
              child: Obx(() {
                final msgs = _apiController.messages;
                if (_apiController.isLoading.value && msgs.isEmpty) {
                  return const LoadingWidget();
                }
                if (msgs.isEmpty) {
                  return const EmptyWidget(
                    title: 'Aucun message',
                    message: 'Envoyez le premier !',
                  );
                }

                WidgetsBinding.instance
                    .addPostFrameCallback((_) => _scrollToBottom());

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: msgs.length,
                  itemBuilder: (context, index) {
                    final m = msgs[index];
                    final mine = m['mine'] == true;
                    final fichiers = m['fichiers'] as List? ?? [];
                    return Align(
                      alignment: mine ? Alignment.topRight : Alignment.topLeft,
                      child: Container(
                        margin: EdgeInsets.only(
                          left: mine ? 40 : 0,
                          right: mine ? 0 : 40,
                          bottom: 16,
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: mine ? AppColors.primaryLight : AppColors.surface,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(AppRadius.l),
                            topRight: const Radius.circular(AppRadius.l),
                            bottomLeft: Radius.circular(mine ? AppRadius.l : 0),
                            bottomRight: Radius.circular(mine ? 0 : AppRadius.l),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if ((m['contenu']?.toString() ?? '').isNotEmpty)
                              Text(
                                m['contenu']?.toString() ?? '',
                                style: AppTextStyles.bodySecondary
                                    .copyWith(color: AppColors.textPrimary, height: 1.4),
                              ),
                            if (fichiers.isNotEmpty) ...[
                              if ((m['contenu']?.toString() ?? '').isNotEmpty)
                                const SizedBox(height: 8),
                              ...fichiers.map((fileUrl) {
                                return _buildFileItem(fileUrl.toString());
                              }).toList(),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                );
              }),
            ),

            // Zone des fichiers sélectionnés
            Obx(() {
              if (_apiController.selectedFiles.isEmpty)
                return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 8),
                child: SizedBox(
                  height: 48,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _apiController.selectedFiles.length,
                    itemBuilder: (context, index) {
                      final file = _apiController.selectedFiles[index];
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppColors.divider),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.textPrimary.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_getFileIcon(file.extension),
                                color: _getFileColor(file.extension), size: AppIconSize.m),
                            const SizedBox(width: 8),
                            Text(
                              file.name.length > 15
                                  ? '${file.name.substring(0, 12)}...'
                                  : file.name,
                              style: AppTextStyles.bodySecondary
                                  .copyWith(fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () => _apiController.removeFile(file),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppColors.divider,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close,
                                    color: AppColors.textSecondary, size: AppIconSize.s),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              );
            }),

            // Barre de saisie inférieure (Message + Icônes)
            Padding(
              padding: const EdgeInsets.only(
                  left: 16, right: 16, bottom: 16, top: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.attach_file,
                                    color: AppColors.textPrimary, size: AppIconSize.m),
                                onPressed: () => _apiController.pickFiles(),
                              ),
                              Expanded(
                                child: TextField(
                                  controller: _messageController,
                                  decoration: InputDecoration(
                                    hintText: 'Message',
                                    hintStyle: AppTextStyles.bodyMedium
                                        .copyWith(color: AppColors.textSecondary),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding:
                                        const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                  onSubmitted: (_) => _sendChatMessage(),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    height: 50,
                    width: 50,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Obx(() => IconButton(
                          icon: _apiController.isSending.value
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.send_outlined,
                                  color: AppColors.primary, size: AppIconSize.m),
                          onPressed: _apiController.isSending.value
                              ? null
                              : _sendChatMessage,
                        )),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS AUXILIAIRES ---
  Widget _buildDropdownSelector({
    required IconData icon,
    required String selectedValue,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        height: 46,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.m),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: AppIconSize.s),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedValue,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down,
                      color: AppColors.textSecondary, size: AppIconSize.m),
                  dropdownColor: AppColors.surface,
                  style: AppTextStyles.bodySecondary.copyWith(
                      fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  items: items
                      .map((String val) => DropdownMenuItem<String>(
                          value: val, child: Text(val)))
                      .toList(),
                  onChanged: onChanged,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildSimpleAppBar(String title,
      {bool showBack = true, VoidCallback? onBack}) {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      toolbarHeight: 85,
      automaticallyImplyLeading: false,
      title: SafeArea(
        child: Row(
          children: [
            if (showBack)
              IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_ios,
                    size: AppIconSize.s, color: AppColors.textPrimary),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            if (showBack) const SizedBox(width: 12),
            Expanded(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.only(right: showBack ? 30 : 0),
                  child: Text(title, style: AppTextStyles.h3),
                ),
              ),
            ),
          ],
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: AppColors.divider, height: 1),
      ),
    );
  }

  Widget _buildSearchField(String hint) {
    return TextField(
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
        suffixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: AppIconSize.m),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.m),
            borderSide: BorderSide(color: AppColors.divider)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.m),
            borderSide: const BorderSide(color: AppColors.primary)),
      ),
    );
  }

  Future<void> _sendChatMessage() async {
    final text = _messageController.text;
    if (text.trim().isEmpty && _apiController.selectedFiles.isEmpty) return;
    await _apiController.sendMessage(text);
    _messageController.clear();
  }

  IconData _getFileIcon(String? extension) {
    switch (extension?.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      default:
        return Icons.attach_file;
    }
  }

  Widget _buildFileItem(String fileUrl) {
    // Try multiple ways to extract the filename
    String fileName = "Document";
    String extension = "";

    try {
      // Decode URL in case it's encoded
      final decodedUrl = Uri.decodeFull(fileUrl);

      // Try to find filename in various parts of the URL
      final parts = decodedUrl.split('/');

      // Start from the end and find the first part that has a dot (likely the filename)
      for (int i = parts.length - 1; i >= 0; i--) {
        if (parts[i].contains('.')) {
          fileName = parts[i].split('?').first; // Remove query params
          break;
        }
      }

      // If still just "Document", check if the URL has a file extension
      if (fileName == "Document" && decodedUrl.contains('.')) {
        // Fallback: extract extension from URL and use generic name
        extension = decodedUrl.split('.').last.toLowerCase();
        extension = extension.split('?').first;
        fileName = "Document.$extension";
      } else {
        // Extract extension from filename
        if (fileName.contains('.')) {
          extension = fileName.split('.').last.toLowerCase();
        }
      }

      // Clean extension
      extension = extension.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    } catch (e) {
      // ignore
    }

    // Format file size (we'll use placeholder for now)
    const fileSize = "14 Ko";

    return InkWell(
      onTap: () => _downloadAndOpenFile(fileUrl, fileName),
      child: Container(
        margin: const EdgeInsets.only(top: 4, bottom: 4),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.textPrimary.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // File icon with colored background
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _getFileColor(extension).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadius.s),
              ),
              child: Center(
                child: Icon(
                  _getFileIcon(extension),
                  color: _getFileColor(extension),
                  size: AppIconSize.m,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // File name and info
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    fileName,
                    style: AppTextStyles.bodyMedium
                        .copyWith(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${extension.toUpperCase()} • $fileSize",
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getFileColor(String? extension) {
    switch (extension?.toLowerCase()) {
      case 'pdf':
        return AppColors.error; // Red for PDF
      case 'doc':
      case 'docx':
        return AppColors.info; // Blue for Word
      case 'xls':
      case 'xlsx':
        return AppColors.success; // Green for Excel
      case 'ppt':
      case 'pptx':
        return AppColors.warning; // Orange for PowerPoint
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return AppColors.secondary; // Purple for Images
      default:
        return AppColors.textSecondary; // Gray for others
    }
  }

  Future<void> _downloadAndOpenFile(String fileUrl, String fileName) async {
    try {
      Get.snackbar(
        'Téléchargement',
        'Téléchargement de $fileName en cours...',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );

      // For web: open the URL in a new tab
      if (kIsWeb) {
        final uri = Uri.parse(fileUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          Get.snackbar(
            'Erreur',
            'Impossible d\'ouvrir le fichier',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppColors.error,
            colorText: AppColors.surface,
          );
        }
      } else {
        // For mobile: download and open
        final directory = await getTemporaryDirectory();
        final savePath = '${directory.path}/$fileName';

        // Download the file
        await _apiController.downloadFile(fileUrl, savePath);

        // Open the file
        final result = await OpenFilex.open(savePath);

        if (result.type != ResultType.done) {
          Get.snackbar('Erreur', 'Impossible d\'ouvrir le fichier',
              snackPosition: SnackPosition.BOTTOM);
        }
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur lors du téléchargement: $e',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Widget _buildChatTabs() {
    return Obx(() => Container(
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              _buildTabItem('Tous'),
              _buildTabItem('Non Lues',
                  showBadge: _apiController.totalUnread > 0),
            ],
          ),
        ));
  }

  Widget _buildTabItem(String label, {bool showBadge = false}) {
    final isActive = _apiController.activeTab.value == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => _apiController.activeTab.value = label,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
            border: isActive
                ? const Border(
                    bottom: BorderSide(color: AppColors.primary, width: 2))
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: AppTextStyles.bodySecondary.copyWith(
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
                ),
              ),
              if (showBadge && label == 'Non Lues') ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(
                      color: AppColors.error, shape: BoxShape.circle),
                  child: Text(
                    '${_apiController.totalUnread}',
                    style: AppTextStyles.label
                        .copyWith(color: AppColors.surface, fontSize: 10),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatList() {
    return Obx(() {
      final chats = _apiController.filteredConversations;
      if (chats.isEmpty) {
        return const EmptyWidget(
          title: 'Aucune conversation',
          message: 'Utilisez + pour contacter un parent.',
        );
      }
      return Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.m),
          border: Border.all(color: AppColors.divider),
        ),
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: chats.length,
          separatorBuilder: (context, index) =>
              Divider(height: 1, color: AppColors.divider, indent: 70),
          itemBuilder: (context, index) {
            final chat = chats[index];
            return ListTile(
              leading: CircleAvatar(
                radius: 24,
                backgroundColor: chat['bg'] as Color,
                child: Text(
                  chat['initial'],
                  style: AppTextStyles.titleMedium
                      .copyWith(color: chat['txt'] as Color),
                ),
              ),
              title: Text(chat['name'],
                  style: AppTextStyles.titleMedium
                      .copyWith(fontWeight: FontWeight.bold)),
              subtitle: Text(
                chat['message'],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySecondary,
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(chat['time'], style: AppTextStyles.caption),
                  if ((chat['unreadCount'] as int) > 0)
                    const SizedBox(height: 4),
                  if ((chat['unreadCount'] as int) > 0)
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${chat['unreadCount']}',
                        style: AppTextStyles.label
                            .copyWith(color: AppColors.surface, fontSize: 10),
                      ),
                    ),
                ],
              ),
              onTap: () async {
                _messageController.clear();
                await _apiController.openConversation(chat);
              },
            );
          },
        ),
      );
    });
  }

  Widget _buildFAB() {
    return Positioned(
      bottom: 16,
      right: 16,
      child: FloatingActionButton(
        onPressed: () async {
          setState(() => _isViewingStudents = true);
          await _apiController.loadStudents();
        },
        backgroundColor: AppColors.primary,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: AppColors.surface, size: AppIconSize.l),
      ),
    );
  }

  // Fiche Info Étudiant
  Widget _buildStudentInfoView() {
    final student = _selectedStudent!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildSimpleAppBar('Info Etudiant',
          onBack: () => setState(() => _selectedStudent = null)),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                color: AppColors.surface,
                padding: const EdgeInsets.only(bottom: 24, top: 24),
                child: Column(
                  children: [
                    CircleAvatar(
                        radius: 43,
                        backgroundColor: student['bg'],
                        child: Text(student['initial'],
                            style: AppTextStyles.h2.copyWith(color: student['txt']))),
                    const SizedBox(height: 14),
                    Text(student['name'], style: AppTextStyles.h2.copyWith(fontSize: 22)),
                    const SizedBox(height: 10),
                    Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20)),
                        child: Text(student['class'],
                            style: AppTextStyles.label
                                .copyWith(color: AppColors.success))),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.m),
                      border: Border.all(color: AppColors.divider)),
                  child: Column(
                    children: [
                      _buildInfoRow(
                          Icons.calendar_today_outlined,
                          'Date de naissance',
                          student['dateNaissance']?.toString() ?? '—'),
                      const Divider(height: 1, indent: 45),
                      _buildInfoRow(
                          Icons.phone_outlined, 'Téléphone', student['phone']),
                      const Divider(height: 1, indent: 45),
                      _buildInfoRow(
                          Icons.mail_outline, 'Email', student['email']),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildParentContactCard(student),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildParentContactCard(Map<String, dynamic> student) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.m),
            border: Border.all(color: AppColors.divider)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('PARENT / TUTEUR',
                style: AppTextStyles.label.copyWith(color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    children: [
                      const Icon(Icons.person_outline,
                          size: AppIconSize.s, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(student['parent'],
                          style: AppTextStyles.bodySecondary.copyWith(
                              fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ],
                  ),
                ),
                const Spacer(),
                _buildCircularAction(Icons.phone_outlined,
                    AppColors.primary.withOpacity(0.08), AppColors.primary),
                const SizedBox(width: 12),
                _buildCircularAction(Icons.mail_outline,
                    AppColors.success.withOpacity(0.1), AppColors.success),
              ],
            ),
            const SizedBox(height: 20),
            _buildContactLine(Icons.phone_outlined, student['phone']),
            const SizedBox(height: 14),
            _buildContactLine(Icons.mail_outline, student['parentEmail']),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                // --- ACTION MODIFIÉE ICI ---
                onPressed: () async {
                  setState(() {
                    _selectedStudent = null;
                    _isViewingStudents = false;
                  });
                  await _apiController.openConversationWithParent(student);
                },
                icon: const Icon(Icons.chat_bubble_outline, size: AppIconSize.s),
                label: const Text('Envoyer un message'),
                style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary, width: 1.2)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(children: [
        Icon(icon, size: AppIconSize.s, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Text(label, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500)),
        const Spacer(),
        Text(value, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold))
      ]),
    );
  }

  Widget _buildCircularAction(IconData icon, Color bg, Color iconColor) {
    return Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: Icon(icon, color: iconColor, size: AppIconSize.s));
  }

  Widget _buildContactLine(IconData icon, String text) {
    return Row(children: [
      Icon(icon, size: AppIconSize.s, color: AppColors.textSecondary),
      const SizedBox(width: 12),
      Text(text, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500))
    ]);
  }
}
