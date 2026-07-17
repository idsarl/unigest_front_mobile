import 'dart:io';

import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../../models/bulletin_model.dart';
import '../utils/error_handler.dart';
import 'api_service.dart';

class BulletinService {
  static Future<List<BulletinModel>> getBulletinsByStudentId(
      int studentId) async {
    try {
      final response = await ApiService.get('/bulletins/etudiant/$studentId');
      final List<dynamic> data = ApiService.decodeJson(response);
      return data.map((json) => BulletinModel.fromJson(json)).toList();
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }

  /// Télécharge le PDF d'un bulletin et l'ouvre avec le lecteur par défaut.
  static Future<void> downloadAndOpenPdf(int bulletinId, String fileName) async {
    try {
      final response = await ApiService.get('/bulletins/$bulletinId/pdf');
      final directory = await getTemporaryDirectory();
      final savePath = '${directory.path}/$fileName';
      final file = File(savePath);
      await file.writeAsBytes(response.bodyBytes);

      final result = await OpenFilex.open(savePath);
      if (result.type != ResultType.done) {
        throw Exception('Impossible d\'ouvrir le fichier');
      }
    } catch (e) {
      throw ErrorHandler.handleException(e);
    }
  }
}
