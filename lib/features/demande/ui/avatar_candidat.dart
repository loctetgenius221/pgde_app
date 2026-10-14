import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/ui/icone.dart';
import '../domain/demande.dart';

/// Portrait rond du candidat, partagé par l'étape Identité et « Mon dossier »
/// pour qu'il ait partout la même allure.
///
/// Sans photo, une silhouette : un appareil photo gris laissait croire à une
/// image cassée. Avec [onTap], la pastille verte d'appareil photo en bas à
/// droite signale que le portrait se modifie — le repère que les candidats
/// connaissent des autres applications.
class AvatarCandidat extends StatelessWidget {
  const AvatarCandidat({
    this.photo,
    this.fichierLocal,
    this.taille = 80,
    this.onTap,
    this.libelleAction,
    super.key,
  });

  /// Photo déjà déposée sur le serveur.
  final FichierJoint? photo;

  /// Photo choisie sur l'appareil, pas encore envoyée. Elle prime sur [photo] :
  /// c'est la dernière intention du candidat.
  final File? fichierLocal;

  final double taille;

  /// Rend le portrait actionnable et affiche la pastille appareil photo.
  final VoidCallback? onTap;

  /// Annonce des lecteurs d'écran quand le portrait est actionnable.
  final String? libelleAction;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Widget silhouette = ColoredBox(
      color: scheme.surface,
      child: Icone(
        Icones.etapeIdentite,
        taille: taille / 2,
        couleur: scheme.onSurface,
      ),
    );

    final Widget image = switch ((fichierLocal, photo)) {
      (final File local, _) => Image.file(local, fit: BoxFit.cover),
      (null, final FichierJoint depose) => CachedNetworkImage(
        // §8.9 : les noms de fichiers du serveur contiennent espaces et
        // accents non assainis — une URL brute échoue.
        imageUrl: depose.urlSure,
        fit: BoxFit.cover,
        errorWidget: (_, _, _) => silhouette,
      ),
      _ => silhouette,
    };

    final Widget portrait = Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: scheme.surface,
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipOval(
        child: SizedBox.square(dimension: taille, child: image),
      ),
    );

    if (onTap == null) return portrait;

    final double pastille = taille * 0.34;
    return Semantics(
      button: true,
      label: libelleAction,
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            portrait,
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: pastille,
                height: pastille,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  shape: BoxShape.circle,
                  // Le liseré de la couleur du fond détache la pastille du
                  // portrait, quelle que soit la photo dessous.
                  border: Border.all(color: scheme.surface, width: 2.5),
                ),
                child: Icone(
                  Icones.photo,
                  taille: pastille * 0.5,
                  couleur: scheme.onPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
