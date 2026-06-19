import 'api_service.dart';
import '../utils/error_handler.dart';
import '../../../models/child_model.dart';
import '../../../models/parent_model.dart';

class ParentService {
  // Récupérer les enfants d'un parent
  static Future<List<ChildModel>> getChildren(int parentId) async {
    try {
      final response =
          await ApiService.get('/utilisateurs/parent/$parentId/enfants');
      final List<dynamic> data = ApiService.decodeJson(response);

      List<ChildModel> children = [];
      for (var json in data) {
        final childId = json['id'];

        // Récupérer la classe de l'étudiant via ses inscriptions
        String className = 'Inconnue';
        String classId = '';
        try {
          final insResponse =
              await ApiService.get('/inscriptions/etudiant/$childId');
          if (insResponse.statusCode == 200) {
            final List<dynamic> insData = ApiService.decodeJson(insResponse);
            if (insData.isNotEmpty) {
              // Trouver une inscription active ou prendre la première
              final classe = insData.first['classe'];
              if (classe is Map<String, dynamic>) {
                className = classe['nom']?.toString() ?? 'Inconnue';
                classId = classe['id']?.toString() ?? '';
              }
            }
          }
        } catch (e) {
          // Silencer l'erreur pour ne pas bloquer le chargement des enfants
          className = 'Inconnue';
        }

        children.add(ChildModel(
          id: childId?.toString() ?? '',
          firstName: json['prenom'] ?? '',
          lastName: json['nom'] ?? '',
          birthDate: json['dateNaissance'] ?? '',
          className: className,
          classId: classId,
          parentIds: [parentId.toString()],
        ));
      }

      return children;
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }

  // Récupérer les informations de profil du parent
  static Future<ParentModel> getParentProfile(int parentId) async {
    try {
      final response = await ApiService.get('/parents/$parentId');
      final json = ApiService.decodeJson(response);
      return ParentModel(
        id: json['id']?.toString() ?? parentId.toString(),
        firstName: json['prenom'] ?? '',
        lastName: json['nom'] ?? '',
        email: json['email'] ?? '',
        phone: json['telephone'] ?? '',
        address: json['adresse'] ?? '',
        createdAt: DateTime.now().subtract(const Duration(days: 365)),
      );
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }
}
