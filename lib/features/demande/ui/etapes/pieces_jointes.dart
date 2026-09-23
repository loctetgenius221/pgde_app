import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/ui/champs.dart';
import '../../../../core/ui/icone.dart';
import '../../application/demande_controller.dart';
import '../../data/selecteur_fichiers.dart';
import '../../domain/demande.dart';
import '../../domain/regles_fichiers.dart';

/// Pièces jointes du dossier, réparties sur deux étapes.
///
/// La **photo** ouvre l'étape 1 : c'est une pièce d'identité, elle a sa place
/// avec l'état civil, pas au milieu des diplômes. Les **documents** restent à
/// l'étape 2, où le candidat a ses justificatifs sous la main (§4).
///
/// Les fichiers choisis sont mis en file et partent à l'enregistrement, comme
/// le fait le formulaire web (§7.7b). Les pièces déjà sur le serveur se
/// retirent, elles, immédiatement (§7.5).

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
      nomFichier: fichier.path,
      octets: fichier.lengthSync(),
      estPhoto: true,
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
    final File? enAttente = ref.watch(piecesEnAttenteProvider).photo;
    final FichierJoint? deposee = widget.demande.photo;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const TitreSection(
          'Photo de profil',
          aide:
              'JPG, PNG ou GIF - 2 Mo maximum. '
              'Les images trop lourdes sont compressées automatiquement.',
        ),
        Row(
          children: <Widget>[
            ClipOval(
              child: SizedBox.square(
                dimension: 88,
                child: _apercu(theme, enAttente, deposee),
              ),
            ),
            const SizedBox(width: Espace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  OutlinedButton.icon(
                    onPressed: occupe ? null : _choisir,
                    icon: const Icone(Icones.galerie, taille: 18),
                    label: Text(
                      enAttente == null && deposee == null
                          ? 'Choisir une photo'
                          : 'Changer la photo',
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(46),
                    ),
                  ),
                  if (enAttente != null)
                    TextButton(
                      onPressed: occupe
                          ? null
                          : () => ref
                                .read(piecesEnAttenteProvider.notifier)
                                .retirerPhoto(),
                      child: const Text('Annuler ce choix'),
                    ),
                ],
              ),
            ),
          ],
        ),
        if (enAttente != null)
          Padding(
            padding: const EdgeInsets.only(top: Espace.xs),
            child: Text(
              'Cette photo sera envoyée à l’enregistrement de votre demande.',
              style: theme.textTheme.bodySmall,
            ),
          ),
      ],
    );
  }

  Widget _apercu(ThemeData theme, File? enAttente, FichierJoint? deposee) {
    if (enAttente != null) return Image.file(enAttente, fit: BoxFit.cover);
    if (deposee != null) {
      return CachedNetworkImage(
        // §8.9 : les noms de fichiers du serveur contiennent espaces et
        // accents non assainis — une URL brute échoue.
        imageUrl: deposee.urlSure,
        fit: BoxFit.cover,
        errorWidget: (_, _, _) => _vide(theme),
      );
    }
    return _vide(theme);
  }

  Widget _vide(ThemeData theme) => ColoredBox(
    color: theme.colorScheme.surfaceContainerHighest,
    child: Icone(
      Icones.photo,
      taille: 30,
      epaisseur: StyleIcone.traitChamp,
      couleur: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
    ),
  );
}

// ---------------------------------------------------------------------------
// Étape 2 — documents justificatifs
// ---------------------------------------------------------------------------

class SectionDocuments extends ConsumerStatefulWidget {
  const SectionDocuments({required this.demande, super.key});

  final Demande demande;

  @override
  ConsumerState<SectionDocuments> createState() => _SectionDocumentsState();
}

class _SectionDocumentsState extends ConsumerState<SectionDocuments>
    with _ChoixDePiece {
  Future<void> _ajouter(TypeFichier type) => agir(() async {
    final List<File> choisis = await ref
        .read(selecteurFichiersProvider)
        .documents();
    if (choisis.isEmpty) return;

    final List<File> retenus = <File>[];
    for (final File fichier in choisis) {
      final String? refus = ReglesFichiers.refus(
        nomFichier: fichier.path,
        octets: fichier.lengthSync(),
        estPhoto: false,
      );
      if (refus == null) {
        retenus.add(fichier);
      } else if (mounted) {
        annoncer('${_nomDe(fichier)} : $refus');
      }
    }
    if (retenus.isNotEmpty) {
      ref.read(piecesEnAttenteProvider.notifier).ajouter(type, retenus);
    }
  });

  static String _nomDe(File fichier) =>
      fichier.path.split(RegExp(r'[\\/]')).last;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final PiecesEnAttente attente = ref.watch(piecesEnAttenteProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // §4 propose diplômes **et** CV. Le CV est retiré de la saisie : il
        // doit être produit par le serveur à partir du dossier. Le type et les
        // appels restent en place, prêts si la décision change.
        for (final TypeFichier type in TypeFichier.proposes) ...<Widget>[
          TitreSection(
            type == TypeFichier.diplome ? 'Diplômes et attestations' : 'CV',
            aide: ReglesFichiers.formatsAdmis(type),
          ),
          _Liste(
            deposees: widget.demande.fichiersDe(type),
            enAttente: attente.de(type),
            occupe: occupe,
            onAjouter: () => _ajouter(type),
            onRetirerEnAttente: (f) =>
                ref.read(piecesEnAttenteProvider.notifier).retirer(type, f),
            onRetirerDeposee: (chemin) => agir(
              () => ref
                  .read(demandeControllerProvider.notifier)
                  .retirerPiece(type, chemin),
            ),
          ),
        ],

        if (attente.nombre > 0)
          Padding(
            padding: const EdgeInsets.only(top: Espace.md),
            child: Text(
              attente.nombre == 1
                  ? 'Une pièce sera envoyée à l’enregistrement de votre demande.'
                  : '${attente.nombre} pièces seront envoyées à '
                        'l’enregistrement de votre demande.',
              style: theme.textTheme.bodySmall,
            ),
          ),
      ],
    );
  }
}

class _Liste extends StatelessWidget {
  const _Liste({
    required this.deposees,
    required this.enAttente,
    required this.occupe,
    required this.onAjouter,
    required this.onRetirerEnAttente,
    required this.onRetirerDeposee,
  });

  final List<FichierJoint> deposees;
  final List<File> enAttente;
  final bool occupe;
  final VoidCallback onAjouter;
  final ValueChanged<File> onRetirerEnAttente;
  final ValueChanged<String> onRetirerDeposee;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final FichierJoint piece in deposees)
          _Ligne(
            nom: piece.nomAffiche,
            detail: piece.tailleLisible,
            envoyee: true,
            occupe: occupe,
            onRetirer: () => onRetirerDeposee(piece.chemin),
          ),
        for (final File fichier in enAttente)
          _Ligne(
            nom: fichier.path.split(RegExp(r'[\\/]')).last,
            detail: ReglesFichiers.tailleLisible(fichier.lengthSync()),
            envoyee: false,
            occupe: occupe,
            onRetirer: () => onRetirerEnAttente(fichier),
          ),
        if (deposees.isEmpty && enAttente.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: Espace.xs),
            child: Text(
              'Aucun document pour le moment.',
              style: theme.textTheme.bodyMedium,
            ),
          ),
        const SizedBox(height: Espace.xs),
        OutlinedButton.icon(
          onPressed: occupe ? null : onAjouter,
          icon: const Icone(Icones.ajouter, taille: 20),
          label: const Text('Ajouter un document'),
        ),
      ],
    );
  }
}

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
