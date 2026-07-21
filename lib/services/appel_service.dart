import '../models/appel.dart';
import '../models/etudiant.dart';
import 'api_service.dart';

class AppelService {
  final ApiService api;
  AppelService({required this.api});

  Future<List<EtudiantModel>> getEtudiants(int classeId) async {
    final data = await api.get('/api/etudiants/classe/$classeId');
    return (data as List<dynamic>)
        .map((e) => EtudiantModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<AppelModel>> getAppelsParSeance(int seanceId) async {
    final data = await api.get('/api/appels/seance/$seanceId');
    return (data as List<dynamic>)
        .map((e) => AppelModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> soumettreAppels(int seanceId, List<AppelEntry> appels) async {
    await api.post('/api/appels/batch', body: {
      'seanceId': seanceId,
      'appels': appels.map((a) => a.toJson()).toList(),
    });
  }

  Future<void> modifierAppel(int appelId, String statut,
      {int retard = 0, String? motif}) async {
    await api.put('/api/appels/$appelId', body: {
      'statut': statut,
      'retard': retard,
      if (motif != null) 'motif': motif,
    });
  }
}
