import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
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
      _annoncer('Votre demande a bien été enregistrée.');
      Navigator.of(context).pop();
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
        title: Text(_etape.titre),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: _Progression(etape: _etape),
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
    child: ConteneurPage(child: child),
  );
}

class _Progression extends StatelessWidget {
  const _Progression({required this.etape});

  final EtapeWizard etape;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    duration: Duree.moyenne,
    curve: Curves.easeOutCubic,
    tween: Tween<double>(
      begin: 0,
      end: (etape.index + 1) / EtapeWizard.values.length,
    ),
    builder: (context, valeur, _) => LinearProgressIndicator(value: valeur),
  );
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                'Étape ${etape.numero} sur ${EtapeWizard.values.length} · '
                'brouillon conservé sur cet appareil',
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Espace.xs),
              Row(
                children: <Widget>[
                  if (onPrecedent != null) ...<Widget>[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: envoiEnCours ? null : onPrecedent,
                        // Marges resserrées : à deux boutons sur une largeur
                        // de téléphone, « Précédent » passait à la ligne.
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Espace.xs,
                          ),
                        ),
                        child: const Text(
                          'Précédent',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: Espace.sm),
                  ],
                  // Parts égales : la hiérarchie vient du remplissage, pas de
                  // la largeur. Deux tiers pour l'action principale ne lui
                  // apportaient rien et étranglaient l'autre.
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: envoiEnCours
                          ? null
                          : (derniere ? onEnregistrer : onSuivant),
                      icon: envoiEnCours
                          ? const SizedBox.shrink()
                          : Icone(
                              derniere ? Icones.valide : Icones.suivant,
                              taille: 20,
                              couleur: theme.colorScheme.onPrimary,
                            ),
                      label: envoiEnCours
                          ? const IndicateurBouton()
                          : Text(derniere ? 'Enregistrer' : 'Continuer'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
