import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/ui/async_view.dart';
import '../../../core/ui/icone.dart';
import '../../../core/ui/responsive.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/utilisateur.dart';
import '../../reference/data/reference_repository.dart';
import '../../reference/domain/referentiel.dart';
import '../application/demande_controller.dart';
import '../domain/demande.dart';
import '../domain/telephone.dart';
import '../domain/wizard.dart';
import 'avatar_candidat.dart';

/// Récapitulatif du dossier — pendant mobile de la page web
/// `userdata/summary/{id}`.
///
/// Même organisation que sur le site, pour que le candidat s'y retrouve d'un
/// support à l'autre : un en-tête qui l'identifie (nom, emploi visé, n° de
/// dossier à citer), puis ses coordonnées, son état civil et ses vœux d'un
/// côté, son profil, ses formations et ses expériences de l'autre.
///
/// Toutes les données viennent de `GET /candidat/profile` (§5.1) : il n'y a
/// pas de route « résumé » dans l'API, et il n'en faut pas. Les libellés sont
/// résolus avec le référentiel. Chaque rubrique renvoie vers son étape du
/// formulaire.
class ResumePage extends ConsumerWidget {
  const ResumePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Referentiel> referentiel = ref.watch(referentielProvider);
    final AsyncValue<Demande> dossier = ref.watch(demandeControllerProvider);
    final Utilisateur? utilisateur = ref.watch(utilisateurConnecteProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mon dossier')),
      body: SafeArea(
        child: AsyncView<Referentiel>(
          value: referentiel,
          onRetry: () => ref.invalidate(referentielProvider),
          builder: (nomenclatures) => AsyncView<Demande>(
            value: dossier,
            onRetry: () => ref.invalidate(demandeControllerProvider),
            builder: (demande) => _Contenu(
              demande: demande,
              referentiel: nomenclatures,
              utilisateur: utilisateur,
            ),
          ),
        ),
      ),
    );
  }
}

class _Contenu extends StatelessWidget {
  const _Contenu({
    required this.demande,
    required this.referentiel,
    required this.utilisateur,
  });

  final Demande demande;
  final Referentiel referentiel;
  final Utilisateur? utilisateur;

  String _region(int? id) =>
      _libelle(referentiel.regions, id, (r) => r.id, (r) => r.libelle);
  String _departement(int? id) =>
      _libelle(referentiel.departements, id, (d) => d.id, (d) => d.libelle);
  String _pays(int? id) =>
      _libelle(referentiel.countries, id, (p) => p.id, (p) => p.name);
  String _handicap(int? id) =>
      _libelle(referentiel.handicaps, id, (h) => h.id, (h) => h.libelle);
  String _niveau(int id) =>
      id == Academic.sansDiplomeId || id == Academic.sansDiplomeIdContrat
      ? 'Sans diplôme'
      : _libelle(referentiel.academics, id, (a) => a.id, (a) => a.libelle);

  static String _libelle<T>(
    List<T> elements,
    int? id,
    int Function(T) cle,
    String Function(T) nom,
  ) {
    if (id == null) return '';
    for (final T element in elements) {
      if (cle(element) == id) return nom(element);
    }
    return '';
  }

  /// « Dakar, Dakar » comme sur le web : du plus précis au plus large.
  static String _joindre(List<String> parties) =>
      parties.where((p) => p.trim().isNotEmpty).join(', ');

  @override
  Widget build(BuildContext context) {
    final DateFormat format = DateFormat('dd/MM/yyyy', 'fr_FR');

    final String residence = demande.resideHorsSenegal
        ? _joindre(<String>[
            demande.lieuResidence,
            _pays(demande.paysId),
            'Hors Sénégal',
          ])
        : _joindre(<String>[
            _departement(demande.departementResidenceId),
            _region(demande.regionResidenceId),
          ]);

    final List<Widget> gauche = <Widget>[
      // Le profil ouvre le récapitulatif : c'est la présentation que le
      // candidat fait de lui-même, avant les données administratives.
      _Bloc(
        titre: 'Profil',
        icone: Icones.presentation,
        etape: EtapeWizard.voeux,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _Encadre(
              libelle: 'Résumé du profil',
              texte: demande.resumeCv.trim().isEmpty
                  ? 'Aucune présentation pour le moment.'
                  : demande.resumeCv,
            ),
            for (final FichierJoint cv in demande.cv)
              _Piece(piece: cv, origine: 'CV'),
          ],
        ),
      ),
      _Bloc(
        titre: 'Coordonnées',
        icone: Icones.identifiant,
        etape: EtapeWizard.identite,
        child: Column(
          children: <Widget>[
            _Info(
              icone: Icones.email,
              libelle: 'E-mail',
              valeur: utilisateur?.email ?? '',
            ),
            _Info(
              icone: Icones.telephone,
              libelle: 'Téléphone',
              valeur: <String>[
                Telephone.formater(demande.telephone1),
                Telephone.formater(demande.telephone2),
              ].where((t) => t.isNotEmpty).join('\n'),
            ),
            _Info(
              icone: Icones.lieu,
              libelle: 'Résidence',
              valeur: residence.isEmpty ? demande.lieuResidence : residence,
            ),
          ],
        ),
      ),
      _Bloc(
        titre: 'Informations personnelles',
        icone: Icones.etapeIdentite,
        etape: EtapeWizard.identite,
        child: Column(
          children: <Widget>[
            _Info(
              icone: Icones.dateNaissance,
              libelle: 'Date de naissance',
              valeur: demande.dateNaissance == null
                  ? ''
                  : format.format(demande.dateNaissance!),
            ),
            _Info(
              icone: Icones.lieu,
              libelle: 'Lieu de naissance',
              valeur: _joindre(<String>[
                demande.lieuNaissance,
                _region(demande.regionNaissanceId),
              ]),
            ),
            _Info(
              icone: Icones.prenom,
              libelle: 'Genre',
              valeur: switch (demande.genre) {
                Genre.masculin => 'Homme',
                Genre.feminin => 'Femme',
                null => '',
              },
            ),
            _Info(
              icone: Icones.famille,
              libelle: 'Situation familiale',
              valeur: <String>[
                demande.situationMatrimoniale?.wire ?? '',
                '${demande.nombreEnfants} '
                    'enfant${demande.nombreEnfants > 1 ? 's' : ''}',
              ].where((t) => t.isNotEmpty).join(' · '),
            ),
            if (demande.aUnHandicap)
              _Info(
                icone: Icones.handicap,
                libelle: 'Handicap',
                valeur: _handicap(demande.handicapId).isEmpty
                    ? 'Oui'
                    : _handicap(demande.handicapId),
              ),
          ],
        ),
      ),
      _Bloc(
        titre: 'Emplois visés',
        icone: Icones.etapeVoeux,
        etape: EtapeWizard.voeux,
        child: Column(
          children: <Widget>[
            _CarteVoeu(
              rang: 1,
              emploi: _emploi(demande.emploi1Id),
              secteur: _secteur(demande.emploi1Id),
              annees: demande.anneesExperience1,
            ),
            const SizedBox(height: Espace.sm),
            _CarteVoeu(
              rang: 2,
              emploi: _emploi(demande.emploi2Id),
              secteur: _secteur(demande.emploi2Id),
              annees: demande.anneesExperience2,
            ),
          ],
        ),
      ),
    ];

    final List<Widget> droite = <Widget>[
      _Bloc(
        titre: 'Formations & diplômes',
        nombre: demande.formations.length,
        icone: Icones.etapeFormations,
        etape: EtapeWizard.formations,
        child: demande.formations.isEmpty
            ? const _Vide('Aucune formation enregistrée.')
            : Column(
                children: <Widget>[
                  for (final Formation f in demande.formations)
                    _CarteParcours(
                      icone: Icones.etapeFormations,
                      titre: f.sansDiplome || f.diplome.trim().isEmpty
                          ? _niveau(f.academicId)
                          : f.diplome,
                      pastille: f.anneeDiplome?.toString(),
                      iconePastille: Icones.annee,
                      details: <(DonneesIcone, String, String)>[
                        (Icones.niveauEtudes, 'Niveau', _niveau(f.academicId)),
                        (
                          Icones.etablissement,
                          'Établissement',
                          f.etablissement,
                        ),
                        (Icones.diplome, 'Spécialité', f.specialite),
                      ],
                      piece: f.justificatif,
                    ),
                ],
              ),
      ),
      _Bloc(
        titre: 'Expérience professionnelle',
        nombre: demande.experiencesRetenues.length,
        icone: Icones.etapeExperiences,
        etape: EtapeWizard.experiences,
        child: demande.experiencesRetenues.isEmpty
            ? _Vide(
                demande.aDeLExperience == false
                    ? 'Pas encore d’expérience professionnelle.'
                    : 'Aucune expérience déclarée.',
              )
            : Column(
                children: <Widget>[
                  for (final Experience e in demande.experiencesRetenues)
                    _CarteParcours(
                      icone: Icones.etapeExperiences,
                      titre: e.poste.trim().isEmpty ? 'Expérience' : e.poste,
                      pastille: e.annees == null
                          ? null
                          : '${e.annees} an${(e.annees ?? 0) > 1 ? 's' : ''}',
                      iconePastille: Icones.annee,
                      details: <(DonneesIcone, String, String)>[
                        (Icones.employeur, 'Entreprise', e.employeur),
                        (Icones.resume, 'Missions', e.description),
                      ],
                    ),
                ],
              ),
      ),
    ];

    return ListView(
      padding: const EdgeInsets.only(top: Espace.md, bottom: Espace.xxl),
      children: <Widget>[
        ConteneurPage(
          largeurMax: LargeurMax.contenu,
          pleineLargeurEnPaysage: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _EnTete(
                demande: demande,
                utilisateur: utilisateur,
                emploiVise: _emploi(demande.emploi1Id),
              ),
              const SizedBox(height: Espace.md),
              _DeuxColonnes(gauche: gauche, droite: droite),
            ],
          ),
        ),
      ],
    );
  }

  String _emploi(int? id) =>
      id == null ? '' : referentiel.emploiParId(id)?.libelle ?? '';

  String _secteur(int? id) =>
      id == null ? '' : referentiel.secteurDeLEmploi(id)?.libelle ?? '';
}

/// Colonne étroite et colonne large sur grand écran, comme sur le web ; une
/// seule pile sur téléphone.
class _DeuxColonnes extends StatelessWidget {
  const _DeuxColonnes({required this.gauche, required this.droite});

  final List<Widget> gauche;
  final List<Widget> droite;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, contraintes) => contraintes.maxWidth >= 840
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: gauche,
                ),
              ),
              const SizedBox(width: Espace.md),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: droite,
                ),
              ),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[...gauche, ...droite],
          ),
  );
}

/// En-tête : qui est le candidat, ce qu'il vise, et son n° de dossier.
class _EnTete extends StatelessWidget {
  const _EnTete({
    required this.demande,
    required this.utilisateur,
    required this.emploiVise,
  });

  final Demande demande;
  final Utilisateur? utilisateur;
  final String emploiVise;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    final Widget identite = Row(
      children: <Widget>[
        AvatarCandidat(photo: demande.photo),
        const SizedBox(width: Espace.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'CANDIDAT À LA FONCTION PUBLIQUE',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                utilisateur?.nomComplet ?? '',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (emploiVise.isNotEmpty) ...<Widget>[
                const SizedBox(height: Espace.xxs),
                Text.rich(
                  TextSpan(
                    children: <InlineSpan>[
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Icone(
                            Icones.etapeVoeux,
                            taille: 14,
                            couleur: scheme.primary,
                          ),
                        ),
                      ),
                      const TextSpan(text: 'Emploi visé : '),
                      TextSpan(
                        text: emploiVise,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  style: theme.textTheme.bodyMedium,
                ),
              ],
              if (utilisateur?.numberid case final String cni
                  when cni.isNotEmpty) ...<Widget>[
                const SizedBox(height: Espace.xs),
                _Pastille(icone: Icones.piece, texte: 'CNI / Passeport  $cni'),
              ],
            ],
          ),
        ),
      ],
    );

    final Widget actions = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (demande.numeroDossier case final int numero)
          _NumeroDossier(numero: numero),
        const SizedBox(height: Espace.sm),
        FilledButton.icon(
          onPressed: () => context.push(Routes.wizard),
          icon: Icone(Icones.modifier, taille: 18, couleur: scheme.onPrimary),
          label: const Text('Modifier mon dossier'),
        ),
      ],
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: DecoratedBox(
        // Le liseré vert du haut de carte, signature de la page web.
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: scheme.primary, width: 4)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(Espace.lg),
          child: LayoutBuilder(
            builder: (context, contraintes) => contraintes.maxWidth >= 640
                ? Row(
                    children: <Widget>[
                      Expanded(child: identite),
                      const SizedBox(width: Espace.lg),
                      SizedBox(width: 240, child: actions),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      identite,
                      const SizedBox(height: Espace.lg),
                      actions,
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Le n° que le candidat cite à l'administration : en évidence, et copiable
/// d'un appui pour éviter de le recopier chiffre par chiffre.
class _NumeroDossier extends StatelessWidget {
  const _NumeroDossier({required this.numero});

  final int numero;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool clair = theme.brightness == Brightness.light;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        Espace.md,
        Espace.sm,
        Espace.sm,
        Espace.sm,
      ),
      decoration: BoxDecoration(
        color: clair ? AppColors.pisteClaire : AppColors.pisteSombre,
        borderRadius: BorderRadius.circular(Rayon.champ),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'N° DE DOSSIER',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  '$numero',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: '$numero'));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  const SnackBar(content: Text('N° de dossier copié.')),
                );
            },
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 40),
              padding: const EdgeInsets.symmetric(horizontal: Espace.sm),
              backgroundColor: scheme.surface,
            ),
            icon: const Icone(HugeIcons.strokeRoundedCopy01, taille: 16),
            label: const Text('Copier'),
          ),
        ],
      ),
    );
  }
}

/// Rubrique : pictogramme, titre, compteur éventuel et crayon vers l'étape.
class _Bloc extends StatelessWidget {
  const _Bloc({
    required this.titre,
    required this.icone,
    required this.etape,
    required this.child,
    this.nombre,
  });

  final String titre;
  final DonneesIcone icone;
  final EtapeWizard etape;
  final int? nombre;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: Espace.md),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Espace.md,
            Espace.xs,
            Espace.xs,
            Espace.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  _TuileIcone(icone: icone),
                  const SizedBox(width: Espace.sm),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        text: titre,
                        children: <InlineSpan>[
                          if (nombre != null)
                            TextSpan(
                              text: '  ($nombre)',
                              style: theme.textTheme.bodySmall,
                            ),
                        ],
                      ),
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Modifier : ${etape.titre}',
                    onPressed: () => context.push(Routes.wizardEtape(etape)),
                    icon: Icone(
                      Icones.modifier,
                      taille: 18,
                      couleur: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const Divider(height: Espace.md),
              Padding(
                padding: const EdgeInsets.only(right: Espace.xs),
                child: child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TuileIcone extends StatelessWidget {
  const _TuileIcone({required this.icone});

  final DonneesIcone icone;

  static const double taille = 32;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool clair = theme.brightness == Brightness.light;
    return Container(
      width: taille,
      height: taille,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: clair
            ? AppColors.vertPale.withValues(alpha: 0.6)
            : theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(Rayon.sm),
      ),
      child: Icone(
        icone,
        taille: taille * 0.5,
        couleur: theme.colorScheme.primary,
      ),
    );
  }
}

/// Ligne d'information : pictogramme discret, libellé, valeur.
///
/// Une valeur vide n'est pas affichée : un champ facultatif laissé blanc
/// allongerait le récapitulatif sans rien apprendre.
class _Info extends StatelessWidget {
  const _Info({
    required this.icone,
    required this.libelle,
    required this.valeur,
  });

  final DonneesIcone icone;
  final String libelle;
  final String valeur;

  @override
  Widget build(BuildContext context) {
    if (valeur.trim().isEmpty) return const SizedBox.shrink();
    final ThemeData theme = Theme.of(context);
    final bool clair = theme.brightness == Brightness.light;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Espace.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: clair ? AppColors.pisteClaire : AppColors.pisteSombre,
              borderRadius: BorderRadius.circular(Rayon.sm - 2),
            ),
            child: Icone(
              icone,
              taille: 15,
              couleur: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: Espace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  libelle,
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 11.5),
                ),
                Text(
                  valeur,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Pastille extends StatelessWidget {
  const _Pastille({required this.icone, required this.texte});

  final DonneesIcone icone;
  final String texte;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool clair = theme.brightness == Brightness.light;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Espace.sm,
        vertical: Espace.xxs,
      ),
      decoration: BoxDecoration(
        color: clair ? AppColors.pisteClaire : AppColors.pisteSombre,
        borderRadius: BorderRadius.circular(Rayon.pilule),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icone(icone, taille: 13, couleur: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: Espace.xxs + 2),
          Flexible(
            child: Text(
              texte,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CarteVoeu extends StatelessWidget {
  const _CarteVoeu({
    required this.rang,
    required this.emploi,
    required this.secteur,
    required this.annees,
  });

  final int rang;
  final String emploi;
  final String secteur;
  final int annees;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool clair = theme.brightness == Brightness.light;
    final bool prioritaire = rang == 1;

    return Container(
      padding: const EdgeInsets.all(Espace.sm),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Rayon.champ),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: prioritaire
                  ? scheme.primary
                  : (clair ? AppColors.pisteClaire : AppColors.pisteSombre),
              borderRadius: BorderRadius.circular(Rayon.sm),
            ),
            child: Text(
              '$rang',
              style: theme.textTheme.titleMedium?.copyWith(
                color: prioritaire ? scheme.onPrimary : scheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: Espace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  emploi.isEmpty ? 'Non choisi' : emploi,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: emploi.isEmpty
                        ? scheme.onSurfaceVariant
                        : scheme.onSurface,
                  ),
                ),
                if (secteur.isNotEmpty)
                  Text(secteur, style: theme.textTheme.bodySmall),
                if (annees > 0)
                  Text(
                    '$annees an${annees > 1 ? 's' : ''} d’expérience',
                    style: theme.textTheme.bodySmall,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Encadre extends StatelessWidget {
  const _Encadre({required this.libelle, required this.texte});

  final String libelle;
  final String texte;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool clair = theme.brightness == Brightness.light;
    return Container(
      padding: const EdgeInsets.all(Espace.md),
      decoration: BoxDecoration(
        color: clair ? AppColors.pisteClaire : AppColors.pisteSombre,
        borderRadius: BorderRadius.circular(Rayon.champ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            libelle,
            style: theme.textTheme.bodySmall?.copyWith(fontSize: 11.5),
          ),
          const SizedBox(height: Espace.xxs),
          Text(
            texte,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

/// Carte d'une formation ou d'une expérience, comme sur le web : un titre,
/// une pastille (année, durée) et des détails en deux colonnes.
class _CarteParcours extends StatelessWidget {
  const _CarteParcours({
    required this.icone,
    required this.titre,
    required this.details,
    this.pastille,
    this.iconePastille,
    this.piece,
  });

  final DonneesIcone icone;
  final String titre;
  final String? pastille;
  final DonneesIcone? iconePastille;
  final List<(DonneesIcone, String, String)> details;
  final FichierJoint? piece;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<(DonneesIcone, String, String)> visibles = details
        .where((d) => d.$3.trim().isNotEmpty)
        .toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: Espace.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _TuileIcone(icone: icone),
          const SizedBox(width: Espace.sm),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(Espace.md),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Rayon.champ),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          titre,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: 15,
                          ),
                        ),
                      ),
                      if (pastille case final String texte)
                        _Pastille(
                          icone: iconePastille ?? Icones.annee,
                          texte: texte,
                        ),
                    ],
                  ),
                  if (visibles.isNotEmpty) ...<Widget>[
                    const SizedBox(height: Espace.xs),
                    GrilleChamps(
                      children: <Widget>[
                        for (final (DonneesIcone i, String l, String v)
                            in visibles)
                          _Detail(icone: i, libelle: l, valeur: v),
                      ],
                    ),
                  ],
                  if (piece case final FichierJoint p) ...<Widget>[
                    const SizedBox(height: Espace.sm),
                    _Piece(piece: p, origine: 'Justificatif'),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({
    required this.icone,
    required this.libelle,
    required this.valeur,
  });

  final DonneesIcone icone;
  final String libelle;
  final String valeur;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icone(icone, taille: 13, couleur: theme.colorScheme.primary),
            const SizedBox(width: Espace.xxs + 2),
            Text(
              libelle,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          valeur,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _Vide extends StatelessWidget {
  const _Vide(this.texte);

  final String texte;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: Espace.xs),
    child: Text(texte, style: Theme.of(context).textTheme.bodyMedium),
  );
}

/// Pièce déposée, ouvrable d'un appui.
class _Piece extends StatelessWidget {
  const _Piece({required this.piece, required this.origine});

  final FichierJoint piece;
  final String origine;

  Future<void> _ouvrir() async {
    // `open_filex` ne sait ouvrir qu'un fichier local : une pièce distante
    // passe par le navigateur, qui gère le téléchargement et le format.
    final Uri? adresse = Uri.tryParse(piece.urlSure);
    if (adresse == null) return;
    if (!await launchUrl(adresse, mode: LaunchMode.externalApplication)) {
      await OpenFilex.open(piece.chemin);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _ouvrir,
        borderRadius: BorderRadius.circular(Rayon.champ),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Espace.sm,
            vertical: Espace.xs,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Rayon.champ),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Row(
            children: <Widget>[
              Icone(
                Icones.document,
                taille: 18,
                couleur: theme.colorScheme.primary,
              ),
              const SizedBox(width: Espace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      piece.nomAffiche,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      <String>[
                        origine,
                        piece.tailleLisible,
                      ].where((t) => t.isNotEmpty).join(' · '),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Icone(
                Icones.suivant,
                taille: 16,
                couleur: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
