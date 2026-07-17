import '../../models/paiement_model.dart';
import '../utils/error_handler.dart';
import 'api_service.dart';

class PaiementService {
  static Future<List<PaiementModel>> getPaiementsByStudentId(
      int studentId) async {
    try {
      final response = await ApiService.get('/paiements/etudiant/$studentId');
      final List<dynamic> data = ApiService.decodeJson(response);
      return data.map((json) => PaiementModel.fromJson(json)).toList();
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }

  static Future<PaiementResumeModel> getResume(int inscriptionId) async {
    try {
      final response =
          await ApiService.get('/paiements/resume/$inscriptionId');
      final data = ApiService.decodeJson(response) as Map<String, dynamic>;
      return PaiementResumeModel.fromJson(data);
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }
}
