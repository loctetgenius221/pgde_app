import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/ui/async_view.dart';
import '../../../core/ui/form_submission.dart';
import '../../../core/ui/icone.dart';
import '../../../core/ui/responsive.dart';
import '../../reference/data/reference_repository.dart';
import '../../reference/domain/referentiel.dart';
import '../application/demande_controller.dart';
import '../domain/demande.dart';
import '../domain/wizard.dart';
import 'etapes/etape_experiences.dart';
import 'etapes/etape_formations.dart';
import 'etapes/etape_identite.dart';
import 'etapes/etape_voeux.dart';
import 'frise_wizard.dart';

/// Le formulaire de demande, en quatre étapes (§4).
///
/// La navigation entre étapes est **libre** : le dossier est un brouillon
/// tant qu'il n'est pas envoyé, et bloquer l'avance sur un champ manquant
/// n'aurait que pour effet de coincer un candidat qui veut y revenir plus
/// tard. Le contrôle des champs obligatoires a lieu à l'enregistrement, et il
/// renvoie sur l'étape fautive.
class WizardPage extends ConsumerStatefulWidget {
  const WizardPage({this.etapeInitiale = EtapeWizard.identite, super.key});

  final EtapeWizard etapeInitiale;

  @override
  ConsumerState<WizardPage> createState() => _WizardPageState();
}

class _WizardPageState extends ConsumerState<WizardPage> {
  late final PageController _pages = PageController(
    initialPage: widget.etapeInitiale.index,
  );
  late EtapeWizard _etape = widget.etapeInitiale;

  ApiException? _erreurs;
  bool _envoiEnCours = false;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _allerA(EtapeWizard etape) {
    _pages.animateToPage(
      etape.index,
      duration: Duree.moyenne,
      curve: Curves.easeOutCubic,
    );
  }

  void _annoncer(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// §8.7 — renvoie sur la première étape citée par un 422.
  EtapeWizard? _premiereEtapeEnErreur(ApiException erreur) {
    final List<EtapeWizard> touchees = erreur.fieldErrors.keys
        .map(EtapeWizard.pourChamp)
        .nonNulls
        .toList();
    if (touchees.isEmpty) return null;
    touchees.sort((a, b) => a.numero.compareTo(b.numero));
    return touchees.first;
  }

  Future<void> _enregistrer(Demande demande) async {
    // Les seuls champs réellement exigés par le serveur (§4, récapitulatif).
    if (!demande.peutEtreEnvoyee) {
      final EtapeWizard manquante = demande.estComplete(EtapeWizard.identite)
          ? EtapeWizard.voeux
          : EtapeWizard.identite;
      _allerA(manquante);
      _annoncer('Complétez l’étape « ${manquante.titre} » avant d’envoyer.');
      return;
    }

    setState(() {
      _envoiEnCours = true;
      _erreurs = null;
    });
    try {
      await ref.read(demandeControllerProvider.notifier).enregistrer();
      if (!mounted) return;
      _annoncer('Demande enregistrée.');
      // Comme sur le web : un enregistrement réussi mène au récapitulatif,
      // où le candidat vérifie ce que le serveur a retenu et relève son
      // n° de dossier. Le formulaire est remplacé, pas empilé : « retour »
      // ramène à l'accueil, pas dans le formulaire qu'il vient de valider.
      context.pushReplacement(Routes.resume);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _erreurs = e);
      final EtapeWizard? fautive = _premiereEtapeEnErreur(e);
      if (fautive != null) _allerA(fautive);
      _annoncer(e.message);
    } finally {
      if (mounted) setState(() => _envoiEnCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<Referentiel> referentiel = ref.watch(referentielProvider);
    final AsyncValue<Demande> dossier = ref.watch(demandeControllerProvider);

    return Scaffold(
      appBar: AppBar(
        // Titre et état sur deux lignes : l'étape et la rassurance « brouillon
        // enregistré » sont lues en haut, d'un coup d'œil, et libèrent la
        // barre du bas, qui ne garde que les actions.
        title: _TitreEtape(etape: _etape),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(context.format.estTablette ? 80 : 68),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
            ),
            // Même largeur que le formulaire en dessous, pour que la frise
            // reste alignée sur les champs.
            child: ConteneurPage(
              largeurMax: LargeurMax.contenu,
              pleineLargeurEnPaysage: true,
              padding: EdgeInsets.zero,
              child: FriseWizard(etape: _etape, onEtape: _allerA),
            ),
          ),
        ),
      ),
      body: AsyncView<Referentiel>(
        value: referentiel,
        onRetry: () => ref.invalidate(referentielProvider),
        builder: (nomenclatures) => AsyncView<Demande>(
          value: dossier,
          onRetry: () => ref.invalidate(demandeControllerProvider),
          builder: (demande) => _Corps(
            demande: demande,
            referentiel: nomenclatures,
            erreurs: _erreurs,
            pages: _pages,
            onEtapeChangee: (e) => setState(() => _etape = e),
            modifier: ref.read(demandeControllerProvider.notifier).modifier,
          ),
        ),
      ),
      bottomNavigationBar: dossier.hasValue
          ? _BarreNavigation(
              etape: _etape,
              envoiEnCours: _envoiEnCours,
              onPrecedent: _etape.index == 0
                  ? null
                  : () => _allerA(EtapeWizard.values[_etape.index - 1]),
              onSuivant: _etape == EtapeWizard.voeux
                  ? null
                  : () => _allerA(EtapeWizard.values[_etape.index + 1]),
              onEnregistrer: () => _enregistrer(dossier.value!),
            )
          : null,
    );
  }
}

class _Corps extends StatelessWidget {
  const _Corps({
    required this.demande,
    required this.referentiel,
    required this.erreurs,
    required this.pages,
    required this.onEtapeChangee,
    required this.modifier,
  });

  final Demande demande;
  final Referentiel referentiel;
  final ApiException? erreurs;
  final PageController pages;
  final ValueChanged<EtapeWizard> onEtapeChangee;
  final void Function(Demande Function(Demande)) modifier;

  @override
  Widget build(BuildContext context) => PageView(
    controller: pages,
    onPageChanged: (i) => onEtapeChangee(EtapeWizard.values[i]),
    children: <Widget>[
      _Defilement(
        child: EtapeIdentite(
          demande: demande,
          referentiel: referentiel,
          erreurs: erreurs,
          modifier: modifier,
        ),
      ),
      _Defilement(
        child: EtapeFormations(
          demande: demande,
          referentiel: referentiel,
          erreurs: erreurs,
          modifier: modifier,
        ),
      ),
      _Defilement(
        child: EtapeExperiences(
          demande: demande,
          erreurs: erreurs,
          modifier: modifier,
        ),
      ),
      _Defilement(
        child: EtapeVoeux(
          demande: demande,
          referentiel: referentiel,
          erreurs: erreurs,
          modifier: modifier,
        ),
      ),
    ],
  );
}

/// Cadre commun à toutes les étapes : défilement, largeur lisible, respiration
/// sous le clavier.
class _Defilement extends StatelessWidget {
  const _Defilement({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.only(top: Espace.sm, bottom: Espace.xxl),
    // Même largeur que l'accueil : à 520 px, les champs paraissaient
    // tassés au milieu d'un écran large.
    child: ConteneurPage(
      largeurMax: LargeurMax.contenu,
      pleineLargeurEnPaysage: true,
      child: child,
    ),
  );
}

/// Titre de l'étape, et en dessous sa position et l'état du brouillon.
class _TitreEtape extends StatelessWidget {
  const _TitreEtape({required this.etape});

  final EtapeWizard etape;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          etape.titre,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(fontSize: 17),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              'Étape ${etape.numero} sur ${EtapeWizard.values.length}',
              style: theme.textTheme.bodySmall,
            ),
            Text('  ·  ', style: theme.textTheme.bodySmall),
            Icone(Icones.valide, taille: 13, couleur: scheme.primary),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                'Brouillon enregistré',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.primary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BarreNavigation extends StatelessWidget {
  const _BarreNavigation({
    required this.etape,
    required this.envoiEnCours,
    required this.onPrecedent,
    required this.onSuivant,
    required this.onEnregistrer,
  });

  final EtapeWizard etape;
  final bool envoiEnCours;
  final VoidCallback? onPrecedent;
  final VoidCallback? onSuivant;
  final VoidCallback onEnregistrer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool derniere = onSuivant == null;

    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          border: Border(
            top: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: Espace.sm),
        child: ConteneurPage(
          largeurMax: LargeurMax.contenu,
          pleineLargeurEnPaysage: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              LayoutBuilder(
                builder: (context, contraintes) {
                  // Sur grand écran, deux boutons étirés sur toute la
                  // largeur deviendraient des bandeaux : comme sur le web,
                  // « Précédent » se range à gauche, l'action à droite.
                  final bool large = contraintes.maxWidth >= 720;
                  Widget place(Widget bouton) => large
                      ? SizedBox(width: 220, child: bouton)
                      : Expanded(child: bouton);

                  return Row(
                    children: <Widget>[
                      if (onPrecedent != null) ...<Widget>[
                        place(
                          OutlinedButton.icon(
                            onPressed: envoiEnCours ? null : onPrecedent,
                            // Marges resserrées : à deux boutons sur une
                            // largeur de téléphone, « Précédent » passait à
                            // la ligne.
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: Espace.xs,
                              ),
                            ),
                            icon: const Icone(Icones.precedent, taille: 18),
                            label: const Text(
                              'Précédent',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        if (large)
                          const Spacer()
                        else
                          const SizedBox(width: Espace.sm),
                      ] else if (large)
                        const Spacer(),
                      // Parts égales sur téléphone : la hiérarchie vient du
                      // remplissage, pas de la largeur.
                      place(
                        FilledButton.icon(
                          onPressed: envoiEnCours
                              ? null
                              : (derniere ? onEnregistrer : onSuivant),
                          // La flèche après le libellé, comme sur le web :
                          // elle montre où l'on va.
                          iconAlignment: IconAlignment.end,
                          icon: envoiEnCours
                              ? const SizedBox.shrink()
                              : Icone(
                                  derniere ? Icones.valide : Icones.suivant,
                                  taille: 20,
                                  couleur: theme.colorScheme.onPrimary,
                                ),
                          label: envoiEnCours
                              ? const IndicateurBouton()
                              : Text(derniere ? 'Enregistrer' : 'Suivant'),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
