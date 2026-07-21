import 'api_service.dart';
import '../utils/error_handler.dart';
import '../../../models/message_model.dart';

class MessagesService {
  // Récupérer l'historique des messages entre le parent/étudiant connecté et un autre utilisateur (ex: enseignant)
  static Future<List<MessageModel>> getMessages(
      int user1Id, int user2Id) async {
    try {
      // Le backend identifie l'utilisateur courant depuis le JWT.
      final response = await ApiService.get('/messages/conversation/$user2Id');
      final List<dynamic> data = ApiService.decodeJson(response);

      return data.map((json) {
        final senderId = int.tryParse(json['expediteurId']?.toString() ?? '');
        final receiverId =
            int.tryParse(json['destinataireId']?.toString() ?? '');
        final isSenderMe = json['mine'] == true || senderId == user1Id;

        return MessageModel(
          id: json['id']?.toString() ?? '',
          senderId: senderId?.toString() ?? '',
          receiverId: receiverId?.toString() ?? '',
          content: json['contenu'] ?? '',
          timestamp: DateTime.parse(
              json['dateEnvoi'] ?? DateTime.now().toIso8601String()),
          isRead: true,
          senderName: isSenderMe ? 'Vous' : 'Enseignant',
          receiverName: isSenderMe ? 'Enseignant' : 'Vous',
        );
      }).toList();
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }

  // Envoyer un message
  static Future<MessageModel> sendMessage(
      int expediteurId, int destinataireId, String content) async {
    try {
      final response = await ApiService.postMultipart(
        '/messages',
        fields: {
          'destinataireId': destinataireId.toString(),
          'contenu': content,
        },
      );
      final json = ApiService.decodeJson(response);

      return MessageModel(
        id: json['id']?.toString() ?? '',
        senderId: json['expediteurId']?.toString() ?? expediteurId.toString(),
        receiverId:
            json['destinataireId']?.toString() ?? destinataireId.toString(),
        content: json['contenu'] ?? '',
        timestamp: DateTime.parse(
            json['dateEnvoi'] ?? DateTime.now().toIso8601String()),
        isRead: false,
        senderName: 'Vous',
        receiverName: 'Enseignant',
      );
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }
}
