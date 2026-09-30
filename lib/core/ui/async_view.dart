import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_exception.dart';
import '../theme/app_dimens.dart';
import 'icone.dart';
import 'responsive.dart';

/// Rend un [AsyncValue] avec les trois états obligatoires : chargement, erreur
/// réutilisable (message + action « Réessayer »), donnée.
///
/// Évite de réécrire `.when(...)` dans chaque écran.
class AsyncView<T> extends StatelessWidget {
  const AsyncView({
    required this.value,
    required this.builder,
    this.onRetry,
    super.key,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) builder;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => value.when(
    data: builder,
    loading: () => const Center(child: CircularProgressIndicator()),
    error: (error, _) =>
        _VueErreur(message: messageOf(error), onRetry: onRetry),
  );
}

/// Message affichable pour n'importe quelle erreur remontée par la couche data.
String messageOf(Object error) => error is ApiException
    ? error.message
    : 'Une erreur inattendue est survenue.';

class _VueErreur extends StatelessWidget {
  const _VueErreur({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: ConteneurPage(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(Espace.md),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icone(
                Icones.horsLigne,
                taille: 36,
                couleur: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Espace.lg),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            if (onRetry != null) ...<Widget>[
              const SizedBox(height: Espace.lg),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icone(Icones.reessayer, taille: 20),
                label: const Text('Réessayer'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
