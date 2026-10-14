import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/ui/async_view.dart';
import '../../../core/ui/frise_etapes.dart';
import '../../../core/ui/icone.dart';
import '../../../core/ui/pied_institutionnel.dart';
import '../../../core/ui/responsive.dart';
import '../../assistant/ui/entree_assistant.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/utilisateur.dart';
import '../application/demande_controller.dart';
import '../data/brouillon_store.dart';
import '../domain/demande.dart';
import '../domain/wizard.dart';
import 'frise_wizard.dart';

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
        child: _Contenu(utilisateur: utilisateur, dossier: dossier, ref: ref),
      ),
      // Ndimbal flotte par-dessus le contenu plutôt que d'y prendre place :
      // l'aide doit rester à portée où que le candidat ait fait défiler.
      //
      // L'emplacement du bouton flottant du `Scaffold`, et non une `Stack`
      // maison : il tient la marge réglementaire de 16 px au bord et au bas,
      // respecte la zone de geste système, et **s'écarte tout seul** quand
      // une `SnackBar` apparaît — là où une position figée la recouvrait.
      floatingActionButton: const EntreeAssistant(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

class _Contenu extends StatelessWidget {
  const _Contenu({
    required this.utilisateur,
    required this.dossier,
    required this.ref,
  });

  final Utilisateur? utilisateur;
  final AsyncValue<Demande> dossier;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return AsyncView<Demande>(
      value: dossier,
      onRetry: () => ref.invalidate(demandeControllerProvider),
      // `CustomScrollView` et non `ListView` : la signature doit tomber
      // au bas de l'écran quand le contenu ne le remplit pas, et se
      // laisser pousser vers le bas quand il déborde. C'est exactement ce
      // que fait `SliverFillRemaining` — il occupe la place restante s'il
      // y en a, et se réduit à la hauteur de son enfant s'il n'y en a
      // plus. Une simple marge basse aurait figé le pied de page à une
      // distance fixe, juste sur l'écran qui a servi à la régler.
      builder: (demande) => CustomScrollView(
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: ConteneurPage(
              largeurMax: LargeurMax.contenu,
              pleineLargeurEnPaysage: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _EnTete(utilisateur: utilisateur, ref: ref),
                  const SizedBox(height: Espace.lg),
                  _Disposition(
                    dossier: _CarteDossier(demande: demande),
                    etapes: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Text(
                          'Les étapes de votre dossier',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: Espace.md),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(Espace.md),
                            child: FriseEtapes(
                              elements: <ElementFrise>[
                                for (final EtapeWizard etape
                                    in EtapeWizard.values)
                                  ElementFrise(
                                    numero: etape.numero,
                                    titre: etape.titre,
                                    icone: iconeEtape(etape),
                                    etat: _etatDe(demande, etape),
                                    statut: _statutDe(demande, etape),
                                    onTap: () =>
                                        context.push(Routes.wizardEtape(etape)),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Signature institutionnelle, collée au bas de l'écran.
          // Réduite au seul nom du ministère : le logo et le nom de la
          // plateforme sont déjà portés par l'écran d'ouverture, les
          // répéter ici alourdissait la fin de page sans rien apprendre.
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              // La marge basse réserve la place de Ndimbal, qui flotte dans
              // le coin : en fin de défilement, la signature s'arrête
              // au-dessus de lui au lieu de passer dessous.
              padding: EdgeInsets.only(
                top: Espace.xxl,
                bottom: EntreeAssistant.emprise + Espace.md,
              ),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: PiedInstitutionnel(avecPlateforme: false),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Carte du dossier et frise des étapes : l'une sous l'autre sur téléphone,
/// côte à côte quand l'écran est large — tablette couchée notamment.
class _Disposition extends StatelessWidget {
  const _Disposition({required this.dossier, required this.etapes});

  final Widget dossier;
  final Widget etapes;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, contraintes) => contraintes.maxWidth >= 900
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(child: dossier),
              const SizedBox(width: Espace.lg),
              Expanded(child: etapes),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              dossier,
              const SizedBox(height: Espace.xl),
              etapes,
            ],
          ),
  );
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
                // §2.2 — `recruted` est posé par l'administration. C'est la
                // meilleure nouvelle que puisse recevoir un candidat : elle
                // n'a pas à rester invisible dans la base.
                if (utilisateur?.recruted ?? false)
                  Padding(
                    padding: const EdgeInsets.only(top: Espace.xxs),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Espace.sm,
                        vertical: Espace.xxs,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(Rayon.pilule),
                      ),
                      child: Text(
                        'Recruté',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
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
          PopupMenuButton<_ActionCompte>(
            tooltip: 'Mon compte',
            icon: const Icone(Icones.menu),
            onSelected: (action) => switch (action) {
              _ActionCompte.deconnexion => _seDeconnecter(context, ref),
            },
            itemBuilder: (_) => const <PopupMenuEntry<_ActionCompte>>[
              PopupMenuItem<_ActionCompte>(
                value: _ActionCompte.deconnexion,
                child: Text('Se déconnecter'),
              ),
            ],
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
                  // Le bloc garde la même emprise dans les deux états : seul
                  // son contenu change, pas le rythme de la carte.
                  padding: EdgeInsets.all(depose ? Espace.sm : Espace.xs),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(Rayon.sm),
                  ),
                  child: depose
                      ? Icone(
                          Icones.dossier,
                          couleur: theme.colorScheme.onPrimaryContainer,
                        )
                      // L'illustration porte ses propres couleurs : on ne la
                      // teinte pas, et on lui laisse un peu plus de place
                      // qu'à un trait d'icône, qui se lit de plus loin.
                      : Image.asset(
                          'assets/icone-demande-d-emploi.png',
                          width: 30,
                          height: 30,
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
                  ? 'Modifiable à tout moment.'
                  : 'Quatre étapes, modifiables à tout moment.',
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
              // Un dossier déposé s'ouvre en lecture : on ne met pas un
              // candidat en situation de modifier sans l'avoir voulu.
              onPressed: () =>
                  context.push(depose ? Routes.resume : Routes.wizard),
              child: Text(
                depose
                    ? 'Consulter mon dossier'
                    : completes == 0
                    ? 'Commencer ma demande'
                    : 'Reprendre ma demande',
              ),
            ),
            if (depose) ...<Widget>[
              const SizedBox(height: Espace.xs),
              OutlinedButton(
                onPressed: () => context.push(Routes.wizard),
                child: const Text('Modifier mon dossier'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

enum _ActionCompte { deconnexion }

/// Déconnexion volontaire : le téléphone peut ensuite passer à quelqu'un
/// d'autre. Tout ce que le candidat a laissé sur l'appareil — brouillon,
/// pièces choisies — est effacé **avant** la fermeture de la session.
///
/// Un brouillon non envoyé serait perdu : on prévient d'abord, plutôt que
/// d'effacer en silence des heures de saisie.
Future<void> _seDeconnecter(BuildContext context, WidgetRef ref) async {
  final bool brouillon = ref.read(brouillonStoreProvider).lire() != null;
  if (brouillon) {
    final bool? confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifications non enregistrées'),
        content: const Text(
          'Votre dossier contient des modifications qui n’ont pas été '
          'enregistrées. En vous déconnectant, elles seront effacées de cet '
          'appareil.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
    if (confirme != true) return;
  }

  await ref.read(demandeControllerProvider.notifier).effacerLesDonneesLocales();
  await ref.read(authControllerProvider.notifier).deconnexion();
}

/// Une seule étape est « en cours » : la première non complétée (§7.6,
/// `completion.etape_courante`). Les suivantes restent à venir, même si une
/// étape plus loin se trouve déjà remplie — on décrit un chemin, pas un
/// tableau de bord.
EtatEtape _etatDe(Demande demande, EtapeWizard etape) {
  if (demande.estComplete(etape)) return EtatEtape.franchie;
  return etape == demande.etapeCourante ? EtatEtape.enCours : EtatEtape.aVenir;
}

String? _statutDe(Demande demande, EtapeWizard etape) =>
    switch (_etatDe(demande, etape)) {
      EtatEtape.franchie => 'Complétée',
      EtatEtape.enCours => 'À remplir',
      // Rien pour une étape à venir : « À faire » n'apprendrait rien de plus
      // que sa position dans la frise.
      EtatEtape.aVenir => null,
    };
