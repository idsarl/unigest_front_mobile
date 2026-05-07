import 'package:get/get.dart';

/// Base class for all GetX Controllers
abstract class BaseController extends GetxController {
  final RxBool _isLoading = false.obs;
  bool get isLoading => _isLoading.value;

  final RxnString _error = RxnString();
  String? get error => _error.value;

  void setLoading(bool loading) {
    _isLoading.value = loading;
  }

  void setError(String? errorMessage) {
    _error.value = errorMessage;
  }

  void clearError() {
    _error.value = null;
  }

  @override
  void onClose() {
    _isLoading.close();
    _error.close();
    super.onClose();
  }
}
