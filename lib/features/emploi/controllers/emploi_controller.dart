import 'package:get/get.dart';
import '../../../services/emploi_service.dart';
import '../../auth/controllers/auth_controller.dart';

class EmploiController extends GetxController {
  final EmploiService _service;

  EmploiController({required EmploiService service}) : _service = service;

  final RxList<EmploiModel> emplois = <EmploiModel>[].obs;
  final RxBool loading = true.obs;
  final RxnString error = RxnString();
  final Rx<DateTime> selectedDate = DateTime.now().obs;

  int get _enseignantId {
    final u = Get.find<AuthController>().user;
    return int.tryParse(u?.enseignantId ?? '') ?? int.tryParse(u?.id ?? '') ?? 0;
  }

  @override
  void onInit() {
    super.onInit();
    chargerJour(DateTime.now());
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> chargerJour(DateTime date) async {
    selectedDate.value = date;
    loading.value = true;
    error.value = null;
    try {
      emplois.value =
          await _service.getEmploisParDate(_enseignantId, _fmt(date));
    } catch (e) {
      error.value = e.toString();
    } finally {
      loading.value = false;
    }
  }

  void jourPrecedent() => chargerJour(
      selectedDate.value.subtract(const Duration(days: 1)));

  void jourSuivant() =>
      chargerJour(selectedDate.value.add(const Duration(days: 1)));

  void allerAujourdhui() => chargerJour(DateTime.now());
}
