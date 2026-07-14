import 'api_service.dart';
import '../utils/error_handler.dart';
import '../../../models/message_model.dart';

class MessagesService {
  // Récupérer l'historique des messages entre le parent/étudiant connecté et un autre utilisateur (ex: enseignant)
  static Future<List<MessageModel>> getMessages(int user1Id, int user2Id) async {
    try {
      final response = await ApiService.get('/messages/history?user1Id=$user1Id&user2Id=$user2Id');
      final List<dynamic> data = ApiService.decodeJson(response);
      
      return data.map((json) {
        final expediteur = json['expediteur'] ?? {};
        final destinataire = json['destinataire'] ?? {};
        
        final isSenderMe = expediteur['id'] == user1Id;
        
        return MessageModel(
          id: json['id']?.toString() ?? '',
          senderId: isSenderMe ? 'parent' : expediteur['id']?.toString() ?? '',
          receiverId: isSenderMe ? destinataire['id']?.toString() ?? '' : 'parent',
          content: json['contenu'] ?? '',
          timestamp: DateTime.parse(json['dateEnvoi'] ?? DateTime.now().toIso8601String()),
          isRead: true, 
          senderName: isSenderMe ? 'Vous' : '${expediteur['prenom'] ?? ''} ${expediteur['nom'] ?? ''}',
          receiverName: isSenderMe ? '${destinataire['prenom'] ?? ''} ${destinataire['nom'] ?? ''}' : 'Vous',
        );
      }).toList();
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }

  // Envoyer un message
  static Future<MessageModel> sendMessage(int expediteurId, int destinataireId, String content) async {
    try {
      final response = await ApiService.post(
        '/messages?expediteurId=$expediteurId&destinataireId=$destinataireId&contenu=${Uri.encodeQueryComponent(content)}',
      );
      final json = ApiService.decodeJson(response);
      final destinataire = json['destinataire'] ?? {};
      
      return MessageModel(
        id: json['id']?.toString() ?? '',
        senderId: 'parent',
        receiverId: destinataireId.toString(),
        content: json['contenu'] ?? '',
        timestamp: DateTime.parse(json['dateEnvoi'] ?? DateTime.now().toIso8601String()),
        isRead: false,
        senderName: 'Vous',
        receiverName: '${destinataire['prenom'] ?? ''} ${destinataire['nom'] ?? ''}',
      );
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }
}
