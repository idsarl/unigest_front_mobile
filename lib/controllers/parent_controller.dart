import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';
import '../core/constants/app_constants.dart';
import '../core/session/app_session.dart';
import '../core/utils/presence_utils.dart';
import '../services/teacher_repository.dart';

class ParentController extends GetxController {
  final TeacherRepository _repo = TeacherRepository.instance;
  final AppSession _session = AppSession.instance;

  StompClient? _stompClient;
  bool _isConnected = false;

  final RxBool isLoading = true.obs;
  final RxString error = ''.obs;
  final RxBool isSending = false.obs;

  final RxList<Map<String, dynamic>> affectations = <Map<String, dynamic>>[].obs;
  final RxInt selectedAffectationIndex = 0.obs;
  final RxList<Map<String, dynamic>> students = <Map<String, dynamic>>[].obs;
  final RxString searchQuery = ''.obs;

  final RxList<Map<String, dynamic>> conversations = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> messages = <Map<String, dynamic>>[].obs;
  final Rxn<Map<String, dynamic>> activeContact = Rxn<Map<String, dynamic>>();
  final RxString chatSearch = ''.obs;
  final RxString activeTab = 'Tous'.obs;
  
  // File attachment
  final RxList<PlatformFile> selectedFiles = <PlatformFile>[].obs;

  Map<String, dynamic>? get selectedAffectation {
    if (affectations.isEmpty) return null;
    final i = selectedAffectationIndex.value.clamp(0, affectations.length - 1);
    return affectations[i];
  }

  List<String> get classList => affectations
      .map((a) => a['classe']?['nom']?.toString() ?? '')
      .where((n) => n.isNotEmpty)
      .toSet()
      .toList();

  List<String> get subjectList {
    final aff = selectedAffectation;
    if (aff == null) return [];
    final mats = aff['matieres'] as List?;
    if (mats == null) return [];
    return mats.map((m) => m['nom']?.toString() ?? '')
        .where((n) => n.isNotEmpty)
        .toSet()
        .toList();
  }

  List<Map<String, dynamic>> get filteredStudents {
    final q = searchQuery.value.trim().toLowerCase();
    if (q.isEmpty) return students;
    return students
        .where((s) =>
            (s['name'] as String).toLowerCase().contains(q) ||
            (s['parent'] as String).toLowerCase().contains(q))
        .toList();
  }

  List<Map<String, dynamic>> get filteredConversations {
    var list = conversations.toList();
    final q = chatSearch.value.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where((c) => (c['name'] as String).toLowerCase().contains(q))
          .toList();
    }
    if (activeTab.value == 'Non Lues') {
      list = list.where((c) => (c['unreadCount'] as int) > 0).toList();
    }
    return list;
  }

  int get totalUnread =>
      conversations.fold<int>(0, (sum, c) => sum + (c['unreadCount'] as int? ?? 0));

  @override
  void onInit() {
    super.onInit();
    loadData();
    _connectWebSocket();
  }

  @override
  void onClose() {
    _disconnectWebSocket();
    super.onClose();
  }

  Future<void> _connectWebSocket() async {
    final token = _session.token;
    if (token == null || token.isEmpty) return;

    _stompClient = StompClient(
      config: StompConfig.sockJS(
        url: '${AppConstants.baseUrl}/ws',
        stompConnectHeaders: {
          'Authorization': 'Bearer $token',
        },
        webSocketConnectHeaders: {
          'Authorization': 'Bearer $token',
        },
        onConnect: (StompFrame frame) {
          _isConnected = true;
          _stompClient?.subscribe(
            destination: '/topic/messages/${_session.teacherId}',
            callback: (StompFrame frame) {
              if (frame.body != null) {
                _handleIncomingMessage(frame.body!);
              }
            },
          );
        },
        onWebSocketError: (dynamic error) => print('WebSocket error: $error'),
      ),
    );
    _stompClient?.activate();
  }

  void _disconnectWebSocket() {
    if (_stompClient != null && _isConnected) {
      _stompClient?.deactivate();
      _isConnected = false;
    }
  }

  void _handleIncomingMessage(String body) {
    try {
      final map = json.decode(body) as Map<String, dynamic>;
      final message = {
        'id': map['id'],
        'contenu': map['contenu'],
        'mine': map['mine'] == true,
        'dateEnvoi': map['dateEnvoi'],
        'expediteurId': map['expediteurId'] as int?,
        'destinataireId': map['destinataireId'] as int?,
        'fichiers': map['fichiers'] ?? [],
      };

      // Update messages list if the active chat is with this sender
      if (activeContact.value != null) {
        final contactId = activeContact.value!['contactId'] as int;
        if (contactId == message['expediteurId']) {
          messages.add(message);
        }
      }

      // Refresh conversations list
      loadConversations();
    } catch (e) {
      print('Error parsing message: $e');
    }
  }

  Future<void> loadData() async {
    isLoading.value = true;
    error.value = '';
    try {
      if (_session.role == 'ENSEIGNANT') {
        await Future.wait([loadAffectations(), loadConversations()]);
      } else {
        await loadConversations();
      }
    } catch (e) {
      error.value = 'Impossible de charger les données : $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadAffectations() async {
    final affs = await _repo.getAffectations();
    affectations.assignAll(
      affs.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList(),
    );
    if (affectations.isNotEmpty) {
      await loadStudents();
    }
  }

  Future<void> loadConversations() async {
    final data = await _repo.getConversations();
    conversations.assignAll(data.map((raw) {
      final c = Map<String, dynamic>.from(raw as Map);
      final prenom = c['contactPrenom']?.toString() ?? '';
      final nom = c['contactNom']?.toString() ?? '';
      final name = '$prenom $nom'.trim();
      final colors = _avatarColors(conversations.length);
      return {
        'contactId': int.tryParse(c['contactId']?.toString() ?? '') ?? 0,
        'name': name.isEmpty ? 'Contact' : name,
        'initial': PresenceUtils.initials(name),
        'message': c['lastMessage']?.toString() ?? '',
        'time': _formatTime(c['dateEnvoi']?.toString()),
        'unreadCount': int.tryParse(c['unreadCount']?.toString() ?? '0') ?? 0,
        'studentId': c['studentId'],
        'studentName': c['studentName']?.toString(),
        'bg': Color(colors[0]),
        'txt': Color(colors[1]),
      };
    }));
  }

  Future<void> openConversation(Map<String, dynamic> contact) async {
    activeContact.value = contact;
    messages.clear();
    selectedFiles.clear();
    final contactId = contact['contactId'] as int;
    isLoading.value = true;
    try {
      await _repo.markMessagesAsRead(contactId);
      final data = await _repo.getMessages(contactId);
      messages.assignAll(data.map((raw) {
        final m = Map<String, dynamic>.from(raw as Map);
        return {
          'id': m['id'],
          'contenu': m['contenu']?.toString() ?? '',
          'mine': m['mine'] == true,
          'dateEnvoi': m['dateEnvoi']?.toString(),
          'fichiers': m['fichiers'] ?? [],
        };
      }));
      
      final index = conversations.indexWhere((c) => c['contactId'] == contactId);
      if (index != -1) {
        final updatedContact = Map<String, dynamic>.from(conversations[index]);
        updatedContact['unreadCount'] = 0;
        conversations[index] = updatedContact;
      }
    } catch (e) {
      Get.snackbar('Erreur', '$e', snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  void closeConversation() {
    activeContact.value = null;
    messages.clear();
    selectedFiles.clear();
  }

  Future<void> sendMessage(String contenu) async {
    final contact = activeContact.value;
    if (contact == null || (contenu.trim().isEmpty && selectedFiles.isEmpty)) return;

    isSending.value = true;
    try {
      // Send message and files together in one request
      final sent = await _repo.sendMessageWithFiles(
        contact['contactId'] as int,
        contenu.trim(),
        selectedFiles,
      );

      // Add the message to the local list
      messages.add({
        'id': sent['id'],
        'contenu': sent['contenu']?.toString() ?? '',
        'mine': true,
        'dateEnvoi': sent['dateEnvoi']?.toString(),
        'fichiers': sent['fichiers'] ?? [],
      });

      // Clear selected files and reload conversations
      selectedFiles.clear();
      await loadConversations();
    } catch (e) {
      Get.snackbar('Erreur', '$e', snackPosition: SnackPosition.BOTTOM);
    } finally {
      isSending.value = false;
    }
  }

  Future<void> openConversationWithParent(Map<String, dynamic> student) async {
    final parentId = student['parentId'] as int?;
    if (parentId == null || parentId == 0) {
      Get.snackbar('Info', 'Aucun parent associé', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    var contact = conversations.firstWhereOrNull(
      (c) => c['contactId'] == parentId,
    );

    contact ??= {
      'contactId': parentId,
      'name': student['parent'],
      'initial': PresenceUtils.initials(student['parent'] as String),
      'bg': student['bg'],
      'txt': student['txt'],
    };

    await openConversation(contact);
  }

  // --- File Selection ---
  Future<void> pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: true,
        withData: true,
      );

      if (result != null) {
        selectedFiles.addAll(result.files);
        Get.snackbar(
          'Succès',
          '${result.files.length} fichier(s) sélectionné(s)',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de sélectionner les fichiers: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void removeFile(PlatformFile file) {
    selectedFiles.remove(file);
  }

  Future<void> downloadFile(String url, String savePath) async {
    await _repo.downloadFile(url, savePath);
  }



  Future<void> selectAffectationByClass(String className) async {
    final idx = affectations.indexWhere(
      (a) => a['classe']?['nom']?.toString() == className,
    );
    if (idx >= 0) {
      selectedAffectationIndex.value = idx;
      await loadStudents();
    }
  }

  Future<void> loadStudents() async {
    final cId = int.tryParse(
        selectedAffectation?['classe']?['id']?.toString() ?? '');
    if (cId == null) return;

    isLoading.value = true;
    try {
      final etudiants = await _repo.getEtudiantsClasse(cId);
      students.assignAll(etudiants.asMap().entries.map((entry) {
        final map = Map<String, dynamic>.from(entry.value as Map);
        final name = PresenceUtils.fullName(map);
        final parent = map['parent'];
        String parentName = '—';
        String parentEmail = '—';
        String parentPhone = map['telephone']?.toString() ?? '—';
        int? parentId;
        if (parent is Map) {
          parentId = int.tryParse(parent['id']?.toString() ?? '');
          parentName =
              '${parent['prenom'] ?? ''} ${parent['nom'] ?? ''}'.trim();
          parentEmail = parent['email']?.toString() ?? '—';
          parentPhone = parent['telephone']?.toString() ?? parentPhone;
        }
        final colors = _avatarColors(entry.key);
        return {
          'id': int.tryParse(map['id']?.toString() ?? '') ?? 0,
          'name': name,
          'initial': PresenceUtils.initials(name),
          'class': selectedAffectation?['classe']?['nom']?.toString() ?? '',
          'phone': map['telephone']?.toString() ?? '—',
          'email': map['email']?.toString() ?? '—',
          'dateNaissance': map['dateNaissance']?.toString() ?? '—',
          'parent': parentName,
          'parentId': parentId,
          'parentEmail': parentEmail,
          'parentPhone': parentPhone,
          'bg': Color(colors[0]),
          'txt': Color(colors[1]),
        };
      }));
    } catch (e) {
      error.value = '$e';
    } finally {
      isLoading.value = false;
    }
  }

  String _formatTime(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso);
      final now = DateTime.now();
      if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
        return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      }
      final yesterday = now.subtract(const Duration(days: 1));
      if (dt.year == yesterday.year &&
          dt.month == yesterday.month &&
          dt.day == yesterday.day) {
        return 'Hier';
      }
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  List<int> _avatarColors(int index) {
    const palette = [
      [0xFFE8F5E9, 0xFF2E7D32],
      [0xFFFFF3E0, 0xFFEF6C00],
      [0xFFE8EAF6, 0xFF3F51B5],
    ];
    return palette[index % palette.length];
  }
}
