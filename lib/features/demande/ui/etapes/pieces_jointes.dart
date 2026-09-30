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
/// avec l'état civil, pas au milieu des diplômes. Les **justificatifs** sont
/// demandés à l'étape 2, chacun dans la carte de la formation qu'il prouve
/// (contrat §6.4).
///
/// Les fichiers choisis sont mis en file et partent à l'enregistrement : un
/// justificatif est déposé avec un `formation_index`, et ce rang n'existe
/// côté serveur qu'une fois les formations enregistrées.

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
    final File? enAttente = ref.watch(piecesEnAttenteProvider).photo;
    final FichierJoint? deposee = widget.demande.photo;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        TitreSection(
          'Photo de profil',
          aide: ReglesFichiers.formatsAdmis(TypeFichier.photo),
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
              'Sera envoyée à l’enregistrement.',
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

  /// Rang de la formation dans la liste. C'est le `formation_index` du
  /// contrat §6.4 : le serveur s'en sert pour rattacher le document.
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        OutlinedButton.icon(
          onPressed: occupe ? null : _choisir,
          icon: const Icone(Icones.ajouter, taille: 20),
          label: const Text('Joindre le justificatif'),
        ),
        Padding(
          padding: const EdgeInsets.only(top: Espace.xxs),
          child: Text(
            // §6.4 accepte les images : le candidat peut photographier son
            // diplôme, ce que l'ancienne règle refusait.
            ReglesFichiers.formatsAdmis(TypeFichier.diplome),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
        ),
      ],
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
