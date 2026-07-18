import '../models/affectation.dart';
import '../models/seance.dart';
import 'api_service.dart';

class DashboardService {
  final ApiService api;
  DashboardService({required this.api});

  Future<EnseignantDashboard> getEnseignantDashboard(int enseignantId) async {
    final data = await api.get('/api/dashboard/enseignant/$enseignantId');
    return EnseignantDashboard.fromJson(data as Map<String, dynamic>);
  }

  Future<List<SeanceModel>> getSeancesDuJour(int enseignantId) async {
    final data = await api.get('/api/seances/enseignant/$enseignantId/jour');
    return (data as List<dynamic>)
        .map((e) => SeanceModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<SeanceModel> demarrerSeance(int seanceId) async {
    final data = await api.patch('/api/seances/$seanceId/demarrer');
    return SeanceModel.fromJson(data as Map<String, dynamic>);
  }

  Future<SeanceModel> arreterSeance(int seanceId) async {
    final data = await api.patch('/api/seances/$seanceId/arreter');
    return SeanceModel.fromJson(data as Map<String, dynamic>);
  }

  Future<List<AffectationModel>> getAffectations(int enseignantId) async {
    final data = await api.get('/api/affectations/enseignant/$enseignantId');
    return (data as List<dynamic>)
        .map((e) => AffectationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
