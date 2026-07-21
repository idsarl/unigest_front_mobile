import 'package:get/get.dart';
import '../../../core/state_management/getx_helpers.dart';
import '../../../core/services/parent_service.dart';
import '../../../models/parent_model.dart';
import '../../../models/child_model.dart';
import '../../../services/storage_service.dart';
import '../../auth/controllers/auth_controller.dart';

class ParentProfileController extends BaseController {
  final Rx<ParentModel?> parent = Rx<ParentModel?>(null);
  final RxList<ChildModel> children = <ChildModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadProfile();
  }

  Future<void> loadProfile() async {
    setLoading(true);
    try {
      final authController = Get.find<AuthController>();
      final parentId = authController.userId.value;

      if (parentId != 0) {
        parent.value = await ParentService.getParentProfile(parentId);
        children.value = await ParentService.getChildren(parentId);
      }
      clearError();
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  Future<void> logout() async {
    try {
      await StorageService.logout();
      Get.offAllNamed('/auth');
    } catch (e) {
      setError(e.toString());
    }
  }
}

