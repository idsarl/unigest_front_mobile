import 'package:get/get.dart';
import '../utils/error_handler.dart';

/// Base class for all GetX Controllers
/// Fournit des fonctionnalités communes pour tous les contrôleurs
abstract class BaseController extends GetxController {
  final RxBool _isLoading = false.obs;
  bool get isLoading => _isLoading.value;

  final RxnString _error = RxnString();
  String? get error => _error.value;

  /// Nombre maximum de tentatives de retry
  static const int maxRetryAttempts = 3;

  /// Définit l'état de chargement
  void setLoading(bool loading) {
    _isLoading.value = loading;
  }

  /// Définit un message d'erreur
  void setError(String? errorMessage) {
    _error.value = errorMessage;
  }

  /// Efface l'erreur
  void clearError() {
    _error.value = null;
  }

  /// Exécute une fonction avec gestion automatique du loading et des erreurs
  Future<T> executeWithErrorHandling<T>(
    Future<T> Function() operation, {
    String? loadingMessage,
    bool showError = true,
  }) async {
    try {
      setLoading(true);
      clearError();
      final result = await operation();
      return result;
    } catch (e) {
      final appException = ErrorHandler.handleException(e);
      if (showError) {
        setError(ErrorHandler.getUserMessage(appException));
      }
      rethrow;
    } finally {
      setLoading(false);
    }
  }

  /// Exécute une fonction avec logique de retry automatique
  Future<T> executeWithRetry<T>(
    Future<T> Function() operation, {
    int maxAttempts = maxRetryAttempts,
    Duration delay = const Duration(seconds: 1),
    bool showError = true,
  }) async {
    int attempts = 0;
    
    while (attempts < maxAttempts) {
      try {
        setLoading(true);
        clearError();
        final result = await operation();
        return result;
      } catch (e) {
        attempts++;
        
        if (attempts >= maxAttempts) {
          final appException = ErrorHandler.handleException(e);
          if (showError) {
            setError(ErrorHandler.getUserMessage(appException));
          }
          rethrow;
        }
        
        // Attendre avant de réessayer
        await Future.delayed(delay * attempts);
      } finally {
        setLoading(false);
      }
    }
    
    throw Exception('Retry failed after $maxAttempts attempts');
  }

  /// Réessaie la dernière opération
  /// À redéfinir dans les contrôleurs enfants si nécessaire
  Future<void> retry() async {
    clearError();
    // Les contrôleurs enfants doivent redéfinir cette méthode
  }

  @override
  void onClose() {
    _isLoading.close();
    _error.close();
    super.onClose();
  }
}
