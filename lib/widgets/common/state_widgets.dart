import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/error_handler.dart';

/// Widget pour afficher un état de chargement
class LoadingWidget extends StatelessWidget {
  final String? message;

  const LoadingWidget({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Widget pour afficher un état vide
class EmptyWidget extends StatelessWidget {
  final String? title;
  final String? message;
  final IconData? icon;
  final VoidCallback? onRetry;

  const EmptyWidget({
    super.key,
    this.title,
    this.message,
    this.icon,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon ?? Icons.inbox_outlined,
              size: 64,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 16),
            Text(
              title ?? 'Aucune donnée',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Widget pour afficher un état d'erreur
class ErrorWidget extends StatelessWidget {
  final String? title;
  final String? message;
  final IconData? icon;
  final VoidCallback? onRetry;

  const ErrorWidget({
    super.key,
    this.title,
    this.message,
    this.icon,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon ?? Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              title ?? 'Une erreur est survenue',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Widget pour afficher une erreur basée sur une AppException
class AppErrorWidget extends StatelessWidget {
  final AppException exception;
  final VoidCallback? onRetry;

  const AppErrorWidget({
    super.key,
    required this.exception,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    String title;
    IconData icon;

    if (exception is NetworkException) {
      title = 'Erreur de connexion';
      icon = Icons.wifi_off;
    } else if (exception is TimeoutException) {
      title = 'Délai dépassé';
      icon = Icons.access_time;
    } else if (exception is UnauthorizedException) {
      title = 'Non autorisé';
      icon = Icons.lock;
    } else if (exception is NotFoundException) {
      title = 'Non trouvé';
      icon = Icons.search_off;
    } else if (exception is ServerException) {
      title = 'Erreur serveur';
      icon = Icons.cloud_off;
    } else {
      title = 'Erreur';
      icon = Icons.error_outline;
    }

    return ErrorWidget(
      title: title,
      message: ErrorHandler.getUserMessage(exception),
      icon: icon,
      onRetry: onRetry,
    );
  }
}

/// Widget wrapper qui gère automatiquement les états de chargement, erreur et vide
class StateBuilder<T> extends StatelessWidget {
  final bool isLoading;
  final String? error;
  final T? data;
  final Widget Function(BuildContext context, T data) builder;
  final String? emptyTitle;
  final String? emptyMessage;
  final VoidCallback? onRetry;

  const StateBuilder({
    super.key,
    required this.isLoading,
    required this.error,
    required this.data,
    required this.builder,
    this.emptyTitle,
    this.emptyMessage,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const LoadingWidget();
    }

    if (error != null) {
      return ErrorWidget(
        message: error,
        onRetry: onRetry,
      );
    }

    if (data == null) {
      return EmptyWidget(
        title: emptyTitle,
        message: emptyMessage,
        onRetry: onRetry,
      );
    }

    return builder(context, data!);
  }
}
