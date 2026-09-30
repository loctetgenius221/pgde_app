import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/ui/async_view.dart';
import '../../../core/ui/icone.dart';
import '../../../core/ui/responsive.dart';
import '../../reference/data/reference_repository.dart';
import '../../reference/domain/referentiel.dart';
import '../application/demande_controller.dart';
import '../domain/demande.dart';
import '../domain/telephone.dart';
import '../domain/wizard.dart';

/// Résumé du dossier en lecture seule — équivalent de `userdata.summary`
/// (§3.1, §8.3).
///
/// Il montre ce que le serveur a **réellement** enregistré, libellés résolus :
/// c'est le seul écran où le candidat peut vérifier sa demande sans risquer de
/// la modifier. Chaque section renvoie vers son étape du formulaire.
class ResumePage extends ConsumerWidget {
  const ResumePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Referentiel> referentiel = ref.watch(referentielProvider);
    final AsyncValue<Demande> dossier = ref.watch(demandeControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mon dossier')),
      body: SafeArea(
        child: AsyncView<Referentiel>(
          value: referentiel,
          onRetry: () => ref.invalidate(referentielProvider),
          builder: (nomenclatures) => AsyncView<Demande>(
            value: dossier,
            onRetry: () => ref.invalidate(demandeControllerProvider),
            builder: (demande) =>
                _Contenu(demande: demande, referentiel: nomenclatures),
          ),
        ),
      ),
    );
  }
}

class _Contenu extends StatelessWidget {
  const _Contenu({required this.demande, required this.referentiel});

  final Demande demande;
  final Referentiel referentiel;

  String _region(int? id) =>
      _libelle(referentiel.regions, id, (r) => r.id, (r) => r.libelle);
  String _departement(int? id) =>
      _libelle(referentiel.departements, id, (d) => d.id, (d) => d.libelle);
  String _pays(int? id) =>
      _libelle(referentiel.countries, id, (p) => p.id, (p) => p.name);
  String _handicap(int? id) =>
      _libelle(referentiel.handicaps, id, (h) => h.id, (h) => h.libelle);
  String _niveau(int? id) =>
      _libelle(referentiel.academics, id, (a) => a.id, (a) => a.libelle);

  String _emploi(int? id) {
    if (id == null) return '';
    final Emploi? emploi = referentiel.emploiParId(id);
    if (emploi == null) return '';
    final Secteur? secteur = referentiel.secteurDeLEmploi(id);
    return secteur == null
        ? emploi.libelle
        : '${emploi.libelle} — ${secteur.libelle}';
  }

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

  @override
  Widget build(BuildContext context) {
    final DateFormat format = DateFormat('dd/MM/yyyy', 'fr_FR');

    return ListView(
      padding: const EdgeInsets.only(top: Espace.md, bottom: Espace.xxl),
      children: <Widget>[
        ConteneurPage(
          largeurMax: LargeurMax.contenu,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (demande.photo case final FichierJoint photo)
                Center(
                  child: ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: photo.urlSure,
                      width: 104,
                      height: 104,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
                ),

              _Section(
                etape: EtapeWizard.identite,
                lignes: <(String, String)>[
                  (
                    'Date de naissance',
                    demande.dateNaissance == null
                        ? ''
                        : format.format(demande.dateNaissance!),
                  ),
                  ('Genre', demande.genre?.wire ?? ''),
                  ('Lieu de naissance', demande.lieuNaissance),
                  ('Région de naissance', _region(demande.regionNaissanceId)),
                  (
                    'Département de naissance',
                    _departement(demande.departementNaissanceId),
                  ),
                  ('Lieu de résidence', demande.lieuResidence),
                  ('Région de résidence', _region(demande.regionResidenceId)),
                  if (demande.resideHorsSenegal &&
                      referentiel.countries.isNotEmpty)
                    ('Pays de résidence', _pays(demande.paysId))
                  else
                    (
                      'Département de résidence',
                      _departement(demande.departementResidenceId),
                    ),
                  ('Adresse', demande.adresse),
                  ('Téléphone', Telephone.formater(demande.telephone1)),
                  (
                    'Téléphone secondaire',
                    Telephone.formater(demande.telephone2),
                  ),
                  (
                    'Situation matrimoniale',
                    demande.situationMatrimoniale?.wire ?? '',
                  ),
                  ('Nombre d’enfants', '${demande.nombreEnfants}'),
                  ('Handicap', _handicap(demande.handicapId)),
                ],
              ),

              _Section(
                etape: EtapeWizard.formations,
                vide: demande.formations.isEmpty
                    ? 'Aucune formation enregistrée.'
                    : null,
                lignes: <(String, String)>[
                  for (final Formation f in demande.formations)
                    (
                      _niveau(f.academicId),
                      f.sansDiplome
                          ? 'Sans diplôme'
                          : <String>[
                              f.diplome,
                              f.specialite,
                              f.etablissement,
                              f.anneeDiplome?.toString() ?? '',
                            ].where((t) => t.isNotEmpty).join(' · '),
                    ),
                ],
                supplement: _Pieces(demande: demande),
              ),

              _Section(
                etape: EtapeWizard.experiences,
                vide: demande.experiencesRetenues.isEmpty
                    ? 'Aucune expérience déclarée.'
                    : null,
                lignes: <(String, String)>[
                  for (final Experience e in demande.experiencesRetenues)
                    (
                      e.poste.isEmpty ? 'Expérience' : e.poste,
                      <String>[
                        e.employeur,
                        e.annees == null ? '' : '${e.annees} an(s)',
                        e.description,
                      ].where((t) => t.isNotEmpty).join(' · '),
                    ),
                ],
              ),

              _Section(
                etape: EtapeWizard.voeux,
                lignes: <(String, String)>[
                  ('Premier vœu', _emploi(demande.emploi1Id)),
                  (
                    'Expérience sur ce métier',
                    '${demande.anneesExperience1} an(s)',
                  ),
                  ('Second vœu', _emploi(demande.emploi2Id)),
                  (
                    'Expérience sur ce métier',
                    '${demande.anneesExperience2} an(s)',
                  ),
                  ('Présentation', demande.resumeCv),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.etape,
    required this.lignes,
    this.vide,
    this.supplement,
  });

  final EtapeWizard etape;
  final List<(String, String)> lignes;
  final String? vide;
  final Widget? supplement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Un champ facultatif laissé vide n'a rien à dire : l'afficher vide
    // allongerait le résumé sans rien apprendre.
    final List<(String, String)> visibles = lignes
        .where((l) => l.$2.trim().isNotEmpty)
        .toList();

    return Padding(
      padding: const EdgeInsets.only(top: Espace.lg),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(Espace.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      etape.titre,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => context.push(Routes.wizardEtape(etape)),
                    icon: const Icone(Icones.modifier, taille: 18),
                    label: const Text('Modifier'),
                  ),
                ],
              ),
              const Divider(height: Espace.md),

              if (visibles.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: Espace.xs),
                  child: Text(
                    vide ?? 'Rien à afficher pour le moment.',
                    style: theme.textTheme.bodyMedium,
                  ),
                )
              else
                for (final (String libelle, String valeur) in visibles)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: Espace.xs),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(libelle, style: theme.textTheme.bodySmall),
                        Text(valeur, style: theme.textTheme.bodyLarge),
                      ],
                    ),
                  ),

              ?supplement,
            ],
          ),
        ),
      ),
    );
  }
}

/// Pièces déposées, ouvrables d'un appui.
class _Pieces extends StatelessWidget {
  const _Pieces({required this.demande});

  final Demande demande;

  Future<void> _ouvrir(FichierJoint piece) async {
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
    final theme = Theme.of(context);
    // Chaque justificatif est annoncé par la formation qu'il prouve : c'est
    // l'écran de vérification, et le rattachement est précisément ce qu'il y
    // a à vérifier.
    final List<(String, FichierJoint)> pieces = <(String, FichierJoint)>[
      for (int i = 0; i < demande.formations.length; i++)
        if (demande.formations[i].justificatif case final FichierJoint p)
          ('Formation ${i + 1}', p),
      for (final FichierJoint p in demande.cv) (TypeFichier.cv.libelle, p),
    ];
    if (pieces.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Divider(height: Espace.lg),
        Text('Pièces jointes', style: theme.textTheme.bodySmall),
        for (final (String origine, FichierJoint piece) in pieces)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icone(
              Icones.document,
              couleur: theme.colorScheme.onSurfaceVariant,
            ),
            title: Text(
              piece.nomAffiche,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              <String>[
                origine,
                piece.tailleLisible,
              ].where((t) => t.isNotEmpty).join(' · '),
            ),
            trailing: Icone(
              Icones.suivant,
              taille: 18,
              couleur: theme.colorScheme.onSurfaceVariant,
            ),
            onTap: () => _ouvrir(piece),
          ),
      ],
    );
  }
}
