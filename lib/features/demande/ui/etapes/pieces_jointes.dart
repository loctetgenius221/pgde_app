import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/ui/bordure_pointillee.dart';
import '../../../../core/ui/champs.dart';
import '../../../../core/ui/icone.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../auth/domain/utilisateur.dart';
import '../../application/demande_controller.dart';
import '../../data/selecteur_fichiers.dart';
import '../../domain/demande.dart';
import '../../domain/regles_fichiers.dart';
import '../avatar_candidat.dart';
import '../ligne_compte.dart';

/// Pièces jointes du dossier, réparties sur deux étapes.
///
/// La **photo** ouvre l'étape 1 : c'est une pièce d'identité, elle a sa place
/// avec l'état civil, pas au milieu des diplômes. Les **justificatifs** sont
/// demandés à l'étape 2, chacun dans la carte de la formation qu'il prouve
/// (contrat §6.4).
///
/// Les fichiers choisis sont mis en file et partent à l'enregistrement : un
/// justificatif est d'abord téléversé (§6.4), puis son `file_path` est
/// rattaché à la formation via `PUT /candidat/formations` (§5.3).

/// Mutualise le choix d'un fichier : exécution, validation, message d'échec.
mixin _ChoixDePiece<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  bool occupe = false;

  void annoncer(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> agir(Future<void> Function() action) async {
    if (occupe) return;
    setState(() => occupe = true);
    try {
      await action();
    } on ApiException catch (e) {
      if (mounted) annoncer(e.message);
    } on Object catch (_) {
      if (mounted) annoncer('Impossible d’accéder à ce fichier.');
    } finally {
      if (mounted) setState(() => occupe = false);
    }
  }
}

// ---------------------------------------------------------------------------
// Étape 1 — photo de profil
// ---------------------------------------------------------------------------

class SectionPhoto extends ConsumerStatefulWidget {
  const SectionPhoto({required this.demande, super.key});

  final Demande demande;

  @override
  ConsumerState<SectionPhoto> createState() => _SectionPhotoState();
}

class _SectionPhotoState extends ConsumerState<SectionPhoto>
    with _ChoixDePiece {
  Future<void> _choisir() => agir(() async {
    // Uniquement la photothèque : un portrait d'identité se prépare, il ne
    // s'improvise pas devant l'appareil au milieu d'un formulaire.
    final File? fichier = await ref
        .read(selecteurFichiersProvider)
        .photo(source: SourcePhoto.galerie);
    if (fichier == null) return;

    final String? refus = ReglesFichiers.refus(
      type: TypeFichier.photo,
      nomFichier: fichier.path,
      octets: fichier.lengthSync(),
    );
    if (refus != null) {
      if (mounted) annoncer(refus);
      return;
    }
    ref.read(piecesEnAttenteProvider.notifier).choisirPhoto(fichier);
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final File? enAttente = ref.watch(piecesEnAttenteProvider).photo;
    final FichierJoint? deposee = widget.demande.photo;
    final Utilisateur? utilisateur = ref.watch(utilisateurConnecteProvider);
    final bool aUnePhoto = enAttente != null || deposee != null;

    // Carte d'identité du candidat, de la même famille que l'en-tête de
    // « Mon dossier » : il sait d'emblée pour quel compte il remplit le
    // dossier, et la photo trouve sa place naturelle à côté de son nom.
    return Card(
      clipBehavior: Clip.antiAlias,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: scheme.primary, width: 4)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(Espace.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _Identite(
                utilisateur: utilisateur,
                avatar: AvatarCandidat(
                  photo: deposee,
                  fichierLocal: enAttente,
                  taille: 64,
                  onTap: occupe ? null : _choisir,
                  libelleAction: aUnePhoto
                      ? 'Changer la photo'
                      : 'Ajouter une photo',
                ),
              ),
              const SizedBox(height: Espace.md),
              const Divider(height: 1),
              const SizedBox(height: Espace.sm),
              if (enAttente != null)
                _PhotoPrete(
                  onAnnuler: occupe
                      ? null
                      : () => ref
                            .read(piecesEnAttenteProvider.notifier)
                            .retirerPhoto(),
                )
              else
                // `Wrap` : la mention passe sous le bouton quand la largeur
                // d'un téléphone ne suffit pas à les aligner.
                Wrap(
                  spacing: Espace.sm,
                  runSpacing: Espace.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    OutlinedButton.icon(
                      onPressed: occupe ? null : _choisir,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 42),
                        padding: const EdgeInsets.symmetric(
                          horizontal: Espace.md,
                        ),
                      ),
                      icon: Icone(
                        Icones.photo,
                        taille: 17,
                        couleur: scheme.primary,
                      ),
                      label: Text(
                        aUnePhoto ? 'Changer la photo' : 'Ajouter une photo',
                      ),
                    ),
                    Text(
                      'Facultatif · '
                      '${ReglesFichiers.formatsAdmis(TypeFichier.photo)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11.5,
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

/// Portrait et nom côte à côte, puis pièce d'identité et e-mail sur toute
/// la largeur.
///
/// Serrés à côté du portrait, l'e-mail se coupait en plein mot
/// (« …@gmail.c / om ») : sur toute la largeur, une adresse courante tient
/// sur une ligne.
class _Identite extends StatelessWidget {
  const _Identite({required this.utilisateur, required this.avatar});

  final Utilisateur? utilisateur;
  final Widget avatar;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Utilisateur? compte = utilisateur;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            avatar,
            const SizedBox(width: Espace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'VOTRE COMPTE CANDIDAT',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    compte?.nomComplet ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (compte != null) ...<Widget>[
          const SizedBox(height: Espace.sm),
          if (compte.numberid.isNotEmpty)
            LigneCompte(
              icone: Icones.piece,
              libelle: 'CNI / Passeport',
              valeur: compte.numberid,
            ),
          LigneCompte(
            icone: Icones.email,
            libelle: 'E-mail',
            valeur: compte.email,
          ),
        ],
      ],
    );
  }
}

/// Photo choisie mais pas encore envoyée : on le dit, et on permet de
/// revenir sur ce choix.
class _PhotoPrete extends StatelessWidget {
  const _PhotoPrete({required this.onAnnuler});

  final VoidCallback? onAnnuler;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool clair = theme.brightness == Brightness.light;
    return Row(
      children: <Widget>[
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Espace.sm,
              vertical: Espace.xs,
            ),
            decoration: BoxDecoration(
              color: clair
                  ? AppColors.vertPale.withValues(alpha: 0.6)
                  : scheme.primaryContainer,
              borderRadius: BorderRadius.circular(Rayon.champ),
            ),
            child: Row(
              children: <Widget>[
                Icone(Icones.valide, taille: 16, couleur: scheme.primary),
                const SizedBox(width: Espace.xs),
                Expanded(
                  child: Text(
                    'Photo prête, envoyée à l’enregistrement',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: clair ? scheme.primary : scheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        TextButton(onPressed: onAnnuler, child: const Text('Annuler')),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Étape 2 — un justificatif par formation
// ---------------------------------------------------------------------------

/// Justificatif d'**une** formation.
///
/// Le document est demandé dans la carte de la formation qu'il prouve, et non
/// dans une corbeille commune en bas d'écran : c'est au moment où il vient de
/// saisir « Licence — 2019 » que le candidat sait lequel de ses fichiers
/// joindre. Une liste globale l'oblige à refaire l'association de tête, et
/// l'administration à la deviner.
class JustificatifFormation extends ConsumerStatefulWidget {
  const JustificatifFormation({
    required this.rang,
    required this.depose,
    super.key,
  });

  /// Rang de la formation dans la liste locale.
  final int rang;

  /// Justificatif déjà sur le serveur pour cette formation.
  final FichierJoint? depose;

  @override
  ConsumerState<JustificatifFormation> createState() =>
      _JustificatifFormationState();
}

class _JustificatifFormationState extends ConsumerState<JustificatifFormation>
    with _ChoixDePiece {
  Future<void> _choisir() => agir(() async {
    final List<File> choisis = await ref
        .read(selecteurFichiersProvider)
        .documents();
    if (choisis.isEmpty) return;

    // Une formation, un justificatif : si le sélecteur en rend plusieurs, on
    // retient le premier plutôt que d'en déposer dont plus rien ne dirait à
    // quoi ils se rattachent.
    final File fichier = choisis.first;
    final String? refus = ReglesFichiers.refus(
      type: TypeFichier.diplome,
      nomFichier: fichier.path,
      octets: fichier.lengthSync(),
    );
    if (refus != null) {
      if (mounted) annoncer(refus);
      return;
    }
    ref
        .read(piecesEnAttenteProvider.notifier)
        .choisirJustificatif(widget.rang, fichier);
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final File? enAttente = ref
        .watch(piecesEnAttenteProvider)
        .justificatifs[widget.rang];
    final FichierJoint? depose = widget.depose;

    return ChampLibelle(
      libelle: 'Justificatif',
      facultatif: true,
      child: _contenu(theme, enAttente, depose),
    );
  }

  Widget _contenu(ThemeData theme, File? enAttente, FichierJoint? depose) {
    // Le choix local prime sur la pièce déposée : c'est la dernière intention
    // du candidat, et c'est elle qui partira à l'enregistrement.
    if (enAttente != null) {
      return _Ligne(
        nom: nomDe(enAttente),
        detail: ReglesFichiers.tailleLisible(enAttente.lengthSync()),
        envoyee: false,
        occupe: occupe,
        onRetirer: () => ref
            .read(piecesEnAttenteProvider.notifier)
            .retirerJustificatif(widget.rang),
      );
    }
    if (depose != null) {
      return _Ligne(
        nom: depose.nomAffiche,
        detail: depose.tailleLisible,
        envoyee: true,
        occupe: occupe,
        onRetirer: () => agir(
          () => ref
              .read(demandeControllerProvider.notifier)
              .retirerJustificatif(widget.rang),
        ),
      );
    }

    // Zone pointillée du web : une place à remplir, pas encore une pièce.
    return ZonePointillee(
      onTap: occupe ? null : _choisir,
      padding: const EdgeInsets.symmetric(
        horizontal: Espace.md,
        vertical: Espace.sm,
      ),
      child: Row(
        children: <Widget>[
          occupe
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icone(
                  Icones.televerser,
                  taille: 20,
                  couleur: theme.colorScheme.primary,
                ),
          const SizedBox(width: Espace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Joindre le diplôme',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  // §6.4 accepte les images : le candidat peut photographier
                  // son diplôme, ce que l'ancienne règle refusait.
                  ReglesFichiers.formatsAdmis(TypeFichier.diplome),
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

/// Nom d'un fichier local, quel que soit le séparateur de la plateforme.
String nomDe(File fichier) => fichier.path.split(RegExp(r'[\\/]')).last;

class _Ligne extends StatelessWidget {
  const _Ligne({
    required this.nom,
    required this.detail,
    required this.envoyee,
    required this.occupe,
    required this.onRetirer,
  });

  final String nom;
  final String detail;
  final bool envoyee;
  final bool occupe;
  final VoidCallback onRetirer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: Espace.xs),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.only(left: Espace.md, right: Espace.xs),
          child: Row(
            children: <Widget>[
              Icone(
                envoyee ? Icones.valide : Icones.document,
                taille: 20,
                epaisseur: StyleIcone.traitChamp,
                couleur: envoyee
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              const SizedBox(width: Espace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(top: Espace.sm),
                      child: Text(
                        nom,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: Espace.sm),
                      child: Text(
                        envoyee
                            ? 'Envoyé${detail.isEmpty ? '' : ' · $detail'}'
                            : 'À envoyer${detail.isEmpty ? '' : ' · $detail'}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Retirer',
                onPressed: occupe ? null : onRetirer,
                icon: Icone(
                  Icones.supprimer,
                  taille: 20,
                  epaisseur: StyleIcone.traitChamp,
                  couleur: theme.colorScheme.error,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
