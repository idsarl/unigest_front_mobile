import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/child_model.dart';
import '../models/note_model.dart';
import '../models/absence_model.dart';
import '../models/emploi_model.dart';
import '../core/config/app_config.dart';

class ApiService {
  static String get baseUrl => AppConfig.baseUrl;

  static Future<List<ChildModel>> getChildren(String parentId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/parents/$parentId/children'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => ChildModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load children');
      }
    } catch (e) {
      throw Exception('Error fetching children: $e');
    }
  }

  static Future<List<NoteModel>> getNotes(String childId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/children/$childId/notes'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => NoteModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load notes');
      }
    } catch (e) {
      throw Exception('Error fetching notes: $e');
    }
  }

  static Future<List<AbsenceModel>> getAbsences(String childId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/children/$childId/absences'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => AbsenceModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load absences');
      }
    } catch (e) {
      throw Exception('Error fetching absences: $e');
    }
  }

  static Future<List<EmploiModel>> getEmploiDuTemps(String childId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/children/$childId/emploi'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => EmploiModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load emploi du temps');
      }
    } catch (e) {
      throw Exception('Error fetching emploi du temps: $e');
    }
  }
}
