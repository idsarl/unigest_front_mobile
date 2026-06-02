import 'dart:convert';
import 'api_service.dart';
import '../utils/error_handler.dart';
import '../../../models/child_model.dart';
import '../../../models/parent_model.dart';

class ParentService {
  // Récupérer les enfants d'un parent
  static Future<List<ChildModel>> getChildren(int parentId) async {
    try {
      final response = await ApiService.get('/utilisateurs/parent/$parentId/enfants');
      final List<dynamic> data = jsonDecode(response.body);
      
      List<ChildModel> children = [];
      for (var json in data) {
        final childId = json['id'];
        
        // Récupérer la classe de l'étudiant via ses inscriptions
        String className = 'Inconnue';
        try {
          final insResponse = await ApiService.get('/inscriptions/etudiant/$childId');
          if (insResponse.statusCode == 200) {
            final List<dynamic> insData = jsonDecode(insResponse.body);
            if (insData.isNotEmpty) {
              // Trouver une inscription active ou prendre la première
              className = insData.first['classe']?['nom'] ?? 'Inconnue';
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
      final json = jsonDecode(response.body);
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
