import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Service de stockage local avec Hive pour le support hors ligne.
class HiveService {
  HiveService._();

  static final HiveService instance = HiveService._();

  static const String _boxCache = 'cache';
  static const String _boxQueuedRequests = 'queued_requests';
  static const String _boxConversations = 'conversations';
  static const String _boxMessages = 'messages';

  /// Initialise Hive
  Future<void> init() async {
    await Hive.initFlutter();
    
    // Ouvre les boxes
    await Hive.openBox(_boxCache);
    await Hive.openBox(_boxQueuedRequests);
    await Hive.openBox(_boxConversations);
    await Hive.openBox(_boxMessages);
  }

  // --- Cache pour les requêtes GET ---

  /// Sauvegarde une réponse de requête GET dans le cache
  Future<void> saveCache(String key, dynamic data, {Duration? ttl}) async {
    final box = Hive.box(_boxCache);
    final cacheEntry = {
      'data': jsonEncode(data),
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'ttl': ttl?.inMilliseconds,
    };
    await box.put(key, cacheEntry);
  }

  /// Récupère une réponse depuis le cache
  dynamic getCache(String key) {
    final box = Hive.box(_boxCache);
    final entry = box.get(key);
    if (entry == null) return null;

    final Map<String, dynamic> cacheEntry = Map<String, dynamic>.from(entry);
    final timestamp = cacheEntry['timestamp'] as int;
    final ttl = cacheEntry['ttl'] as int?;

    // Vérifie si le cache a expiré
    if (ttl != null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - timestamp > ttl) {
        return null;
      }
    }

    try {
      return jsonDecode(cacheEntry['data'] as String);
    } catch (_) {
      return null;
    }
  }

  /// Supprime une clé du cache
  Future<void> deleteCache(String key) async {
    final box = Hive.box(_boxCache);
    await box.delete(key);
  }

  // --- Requêtes en attente pour la synchronisation ---

  /// Ajoute une requête à la file d'attente
  Future<void> addQueuedRequest(Map<String, dynamic> request) async {
    final box = Hive.box(_boxQueuedRequests);
    // Génère un ID unique pour la requête
    final requestId = DateTime.now().millisecondsSinceEpoch.toString();
    await box.put(requestId, request);
  }

  /// Récupère toutes les requêtes en attente
  List<Map<String, dynamic>> getQueuedRequests() {
    final box = Hive.box(_boxQueuedRequests);
    final List<Map<String, dynamic>> requests = [];
    for (final key in box.keys) {
      final value = box.get(key);
      if (value is Map) {
        requests.add({
          'id': key,
          ...Map<String, dynamic>.from(value),
        });
      }
    }
    // Trie par timestamp (plus vieux d'abord)
    requests.sort((a, b) {
      final idA = a['id'] as String;
      final idB = b['id'] as String;
      return idA.compareTo(idB);
    });
    return requests;
  }

  /// Supprime une requête de la file d'attente
  Future<void> removeQueuedRequest(String requestId) async {
    final box = Hive.box(_boxQueuedRequests);
    await box.delete(requestId);
  }

  // --- Conversations et messages ---

  /// Sauvegarde une conversation
  Future<void> saveConversation(Map<String, dynamic> conversation) async {
    final box = Hive.box(_boxConversations);
    final id = conversation['id'].toString();
    await box.put(id, conversation);
  }

  /// Sauvegarde plusieurs conversations
  Future<void> saveConversations(List<dynamic> conversations) async {
    final box = Hive.box(_boxConversations);
    for (final conv in conversations) {
      if (conv is Map) {
        final id = conv['id'].toString();
        await box.put(id, conv);
      }
    }
  }

  /// Récupère toutes les conversations
  List<Map<String, dynamic>> getConversations() {
    final box = Hive.box(_boxConversations);
    final List<Map<String, dynamic>> list = [];
    for (final key in box.keys) {
      final value = box.get(key);
      if (value is Map) {
        list.add(Map<String, dynamic>.from(value));
      }
    }
    return list;
  }

  /// Sauvegarde un message
  Future<void> saveMessage(int conversationId, Map<String, dynamic> message) async {
    final box = Hive.box(_boxMessages);
    final key = '$conversationId-${message['id']}';
    await box.put(key, message);
  }

  /// Sauvegarde plusieurs messages pour une conversation
  Future<void> saveMessages(int conversationId, List<dynamic> messages) async {
    final box = Hive.box(_boxMessages);
    for (final msg in messages) {
      if (msg is Map) {
        final key = '$conversationId-${msg['id']}';
        await box.put(key, msg);
      }
    }
  }

  /// Récupère les messages pour une conversation
  List<Map<String, dynamic>> getMessages(int conversationId) {
    final box = Hive.box(_boxMessages);
    final List<Map<String, dynamic>> list = [];
    final prefix = '$conversationId-';
    for (final key in box.keys) {
      if (key is String && key.startsWith(prefix)) {
        final value = box.get(key);
        if (value is Map) {
          list.add(Map<String, dynamic>.from(value));
        }
      }
    }
    // Trie les messages par ID
    list.sort((a, b) => (a['id'] as int).compareTo(b['id'] as int));
    return list;
  }

  // --- Emploi du temps ---

  static const String _keyEmploiDuTemps = 'emploi_du_temps';

  Future<void> saveEmploiDuTemps(List<dynamic> emplois) async {
    await saveCache(_keyEmploiDuTemps, emplois, ttl: const Duration(days: 7));
  }

  List<dynamic>? getEmploiDuTemps() {
    return getCache(_keyEmploiDuTemps);
  }
}
