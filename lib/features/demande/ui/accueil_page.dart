import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/ui/async_view.dart';
import '../../../core/ui/icone.dart';
import '../../../core/ui/responsive.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/utilisateur.dart';
import '../application/demande_controller.dart';
import '../domain/demande.dart';
import '../domain/wizard.dart';

/// Point d'entrée du dossier candidat.
///
/// `utilisateur_id` est UNIQUE en base (§2.1) : il n'y a jamais qu'un dossier,
/// donc jamais de liste. Le parcours est « créer si absent, sinon éditer ».
///
/// L'état affiché vient du dossier lui-même, pas du drapeau `has_demande` du
/// profil : un dossier créé à l'instant serait sinon annoncé absent jusqu'à la
/// prochaine reconnexion.
class AccueilPage extends ConsumerWidget {
  const AccueilPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Utilisateur? utilisateur = ref.watch(utilisateurConnecteProvider);
    final AsyncValue<Demande> dossier = ref.watch(demandeControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: AsyncView<Demande>(
          value: dossier,
          onRetry: () => ref.invalidate(demandeControllerProvider),
          builder: (demande) => ListView(
            padding: const EdgeInsets.only(bottom: Espace.xxl),
            children: <Widget>[
              ConteneurPage(
                largeurMax: LargeurMax.contenu,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _EnTete(utilisateur: utilisateur, ref: ref),
                    const SizedBox(height: Espace.lg),
                    _CarteDossier(demande: demande),
                    const SizedBox(height: Espace.xl),
                    Text(
                      'Les étapes de votre dossier',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: Espace.sm),
                    for (final EtapeWizard etape in EtapeWizard.values) ...[
                      _CarteEtape(
                        etape: etape,
                        complete: demande.estComplete(etape),
                        onTap: () => context.push(Routes.wizardEtape(etape)),
                      ),
                      const SizedBox(height: Espace.xs),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EnTete extends StatelessWidget {
  const _EnTete({required this.utilisateur, required this.ref});

  final Utilisateur? utilisateur;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: Espace.lg),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Bonjour', style: theme.textTheme.bodyMedium),
                Text(
                  utilisateur?.nomComplet ?? '',
                  style: theme.textTheme.headlineSmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: Espace.sm),
          CircleAvatar(
            radius: 24,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Text(
              utilisateur?.initiales ?? '?',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Se déconnecter',
            icon: const Icone(Icones.deconnexion),
            onPressed: () =>
                ref.read(authControllerProvider.notifier).deconnexion(),
          ),
        ],
      ),
    );
  }
}

/// Carte d'état du dossier — l'information la plus attendue à l'ouverture.
class _CarteDossier extends StatelessWidget {
  const _CarteDossier({required this.demande});

  final Demande demande;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool depose = demande.existeSurLeServeur;
    final int completes = demande.etapesCompletes.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Espace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(Espace.sm),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(Rayon.sm),
                  ),
                  child: Icone(
                    depose ? Icones.dossier : Icones.nouveauDossier,
                    couleur: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: Espace.sm),
                Expanded(
                  child: Text(
                    depose ? 'Dossier enregistré' : 'Demande en préparation',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Espace.sm),
            Text(
              depose
                  ? 'Vous pouvez le compléter ou le corriger à tout moment. '
                        'Vos modifications remplacent la version précédente.'
                  : 'Déposez votre demande d’emploi en quatre étapes. Vous '
                        'pourrez la modifier autant de fois que nécessaire.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: Espace.md),

            ClipRRect(
              borderRadius: BorderRadius.circular(Rayon.pilule),
              child: LinearProgressIndicator(value: demande.progression),
            ),
            const SizedBox(height: Espace.xs),
            Text(
              '$completes étape${completes > 1 ? 's' : ''} sur '
              '${EtapeWizard.values.length} complétée'
              '${completes > 1 ? 's' : ''}',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: Espace.lg),

            FilledButton(
              onPressed: () => context.push(Routes.wizard),
              child: Text(
                depose
                    ? 'Ouvrir mon dossier'
                    : completes == 0
                    ? 'Commencer ma demande'
                    : 'Reprendre ma demande',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CarteEtape extends StatelessWidget {
  const _CarteEtape({
    required this.etape,
    required this.complete,
    required this.onTap,
  });

  final EtapeWizard etape;
  final bool complete;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Rayon.lg),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Espace.md,
            vertical: Espace.sm,
          ),
          child: Row(
            children: <Widget>[
              CircleAvatar(
                radius: 18,
                backgroundColor: complete
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainerHighest,
                child: complete
                    ? Icone(
                        Icones.valide,
                        taille: 18,
                        couleur: theme.colorScheme.onPrimary,
                      )
                    : Text(
                        '${etape.numero}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
              ),
              const SizedBox(width: Espace.sm),
              Expanded(
                child: Text(etape.titre, style: theme.textTheme.bodyLarge),
              ),
              Text(
                complete ? 'Complétée' : 'À remplir',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(width: Espace.xxs),
              Icone(
                Icones.suivant,
                taille: 18,
                couleur: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
