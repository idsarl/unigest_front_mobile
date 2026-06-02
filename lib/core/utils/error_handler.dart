/// Gestionnaire d'erreurs centralisé
/// Permet de normaliser la gestion des erreurs dans toute l'application
class AppException implements Exception {
  final String message;
  final String? details;
  final int? statusCode;

  AppException({
    required this.message,
    this.details,
    this.statusCode,
  });

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  NetworkException({String? message})
      : super(
          message: message ?? 'Erreur de connexion réseau',
          details: 'Vérifiez votre connexion internet',
        );
}

class TimeoutException extends AppException {
  TimeoutException()
      : super(
          message: 'Délai d\'attente dépassé',
          details: 'Le serveur ne répond pas. Veuillez réessayer.',
        );
}

class UnauthorizedException extends AppException {
  UnauthorizedException()
      : super(
          message: 'Non autorisé',
          details: 'Votre session a expiré. Veuillez vous reconnecter.',
          statusCode: 401,
        );
}

class ForbiddenException extends AppException {
  ForbiddenException()
      : super(
          message: 'Accès refusé',
          details: 'Vous n\'avez pas les permissions nécessaires.',
          statusCode: 403,
        );
}

class NotFoundException extends AppException {
  NotFoundException()
      : super(
          message: 'Ressource non trouvée',
          details: 'La ressource demandée n\'existe pas.',
          statusCode: 404,
        );
}

class ServerException extends AppException {
  ServerException({String? message})
      : super(
          message: message ?? 'Erreur serveur',
          details: 'Une erreur est survenue sur le serveur. Veuillez réessayer plus tard.',
          statusCode: 500,
        );
}

class HttpException extends AppException {
  HttpException(int statusCode, String body)
      : super(
          message: 'Erreur HTTP $statusCode',
          details: body,
          statusCode: statusCode,
        );
}

class ValidationException extends AppException {
  ValidationException({String? message})
      : super(
          message: message ?? 'Erreur de validation',
          details: 'Veuillez vérifier les données saisies.',
        );
}

class CacheException extends AppException {
  CacheException({String? message})
      : super(
          message: message ?? 'Erreur de cache',
          details: 'Impossible d\'accéder aux données en cache.',
        );
}

/// Classe utilitaire pour la gestion des erreurs
class ErrorHandler {
  /// Gère n'importe quelle exception et la convertit en AppException
  static AppException handleException(dynamic exception) {
    if (exception is AppException) {
      return exception;
    }

    if (exception is TimeoutException) {
      return createTimeoutException();
    }

    if (exception is NetworkException) {
      return NetworkException();
    }

    // Gérer les exceptions HTTP
    if (exception.toString().contains('SocketException') ||
        exception.toString().contains('Connection refused')) {
      return NetworkException();
    }

    if (exception.toString().contains('TimeoutException')) {
      return createTimeoutException();
    }

    // Exception par défaut
    return AppException(
      message: 'Une erreur inattendue s\'est produite',
      details: exception.toString(),
    );
  }

  /// Crée une exception de timeout
  static TimeoutException createTimeoutException() {
    return TimeoutException();
  }

  /// Crée une exception non autorisée
  static UnauthorizedException createUnauthorizedException() {
    return UnauthorizedException();
  }

  /// Crée une exception accès refusé
  static ForbiddenException createForbiddenException() {
    return ForbiddenException();
  }

  /// Crée une exception non trouvée
  static NotFoundException createNotFoundException() {
    return NotFoundException();
  }

  /// Crée une exception serveur
  static ServerException createServerException() {
    return ServerException();
  }

  /// Crée une exception HTTP personnalisée
  static HttpException createHttpException(int statusCode, String body) {
    return HttpException(statusCode, body);
  }

  /// Retourne un message utilisateur-friendly pour une exception
  static String getUserMessage(AppException exception) {
    return exception.message;
  }

  /// Retourne les détails techniques pour le logging
  static String getDetails(AppException exception) {
    return exception.details ?? 'Aucun détail disponible';
  }
}
