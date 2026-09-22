import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

/// Jeu d'icônes de l'application — Hugeicons, style *stroke rounded*.
///
/// Le trait arrondi est le pendant graphique des formes de l'interface
/// (champs et boutons en pilule, cartes à grands rayons). Les icônes Material,
/// plus anguleuses, juraient avec.
typedef DonneesIcone = List<List<dynamic>>;

/// Icône qui se comporte comme un `Icon` Material : elle hérite de
/// l'`IconTheme` ambiant.
///
/// `HugeIcon` exige sinon une couleur et une taille explicites à chaque appel —
/// ce qui reviendrait à recopier la couleur du thème dans chaque écran, et à
/// casser silencieusement le mode sombre le jour où l'une est oubliée.
class Icone extends StatelessWidget {
  const Icone(this.icone, {this.taille, this.couleur, super.key});

  final DonneesIcone icone;
  final double? taille;
  final Color? couleur;

  @override
  Widget build(BuildContext context) {
    final IconThemeData ambiant = IconTheme.of(context);
    return HugeIcon(
      icon: icone,
      size: taille ?? ambiant.size ?? 22,
      color: couleur ?? ambiant.color ?? Theme.of(context).colorScheme.onSurface,
      strokeWidth: 1.8,
    );
  }
}

/// Icône placée en tête d'un champ de saisie.
///
/// Les champs sont en pilule : une icône collée au bord entrerait dans la
/// courbe. Ce décalage la replace sur la partie droite du rayon.
class PrefixeChamp extends StatelessWidget {
  const PrefixeChamp(this.icone, {super.key});

  final DonneesIcone icone;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 18, right: 10),
    child: Icone(
      icone,
      taille: 20,
      couleur: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
  );
}

/// Les icônes utilisées dans l'application, nommées par intention.
///
/// Un seul endroit à relire pour vérifier la cohérence du jeu, et un seul à
/// modifier si une icône change.
abstract final class Icones {
  static const DonneesIcone prenom = HugeIcons.strokeRoundedUser03;
  static const DonneesIcone nom = HugeIcons.strokeRoundedUserAccount;
  static const DonneesIcone identifiant = HugeIcons.strokeRoundedUser;
  static const DonneesIcone piece = HugeIcons.strokeRoundedIdentityCard;
  static const DonneesIcone email = HugeIcons.strokeRoundedMail01;
  static const DonneesIcone emailConfirmation =
      HugeIcons.strokeRoundedMailValidation01;
  static const DonneesIcone emailAttente = HugeIcons.strokeRoundedMailOpen01;
  static const DonneesIcone motDePasse = HugeIcons.strokeRoundedLockPassword;
  static const DonneesIcone motDePasseConfirmation =
      HugeIcons.strokeRoundedSquareLock01;
  static const DonneesIcone afficher = HugeIcons.strokeRoundedView;
  static const DonneesIcone masquer = HugeIcons.strokeRoundedViewOff;
  static const DonneesIcone deconnexion = HugeIcons.strokeRoundedLogout01;
  static const DonneesIcone reessayer = HugeIcons.strokeRoundedRefresh;
  static const DonneesIcone horsLigne =
      HugeIcons.strokeRoundedWifiDisconnected01;
  static const DonneesIcone alerte = HugeIcons.strokeRoundedAlert02;
  static const DonneesIcone dossier = HugeIcons.strokeRoundedFolder02;
  static const DonneesIcone nouveauDossier = HugeIcons.strokeRoundedTaskAdd01;

  // --- Wizard ---
  static const DonneesIcone dateNaissance = HugeIcons.strokeRoundedCalendar03;
  static const DonneesIcone lieu = HugeIcons.strokeRoundedLocation01;
  static const DonneesIcone region = HugeIcons.strokeRoundedGlobal;
  static const DonneesIcone adresse = HugeIcons.strokeRoundedBuilding01;
  static const DonneesIcone telephone = HugeIcons.strokeRoundedCall02;
  static const DonneesIcone famille = HugeIcons.strokeRoundedUserGroup;
  static const DonneesIcone enfants = HugeIcons.strokeRoundedBaby01;
  static const DonneesIcone handicap = HugeIcons.strokeRoundedWheelchair;
  static const DonneesIcone niveauEtudes = HugeIcons.strokeRoundedMortarboard01;
  static const DonneesIcone diplome = HugeIcons.strokeRoundedGraduateMale;
  static const DonneesIcone etablissement = HugeIcons.strokeRoundedBuilding02;
  static const DonneesIcone annee = HugeIcons.strokeRoundedCalendar03;
  static const DonneesIcone poste = HugeIcons.strokeRoundedBriefcase01;
  static const DonneesIcone employeur = HugeIcons.strokeRoundedBuilding01;
  static const DonneesIcone voeu = HugeIcons.strokeRoundedFavourite;
  static const DonneesIcone secteur = HugeIcons.strokeRoundedBriefcase02;
  static const DonneesIcone resume = HugeIcons.strokeRoundedNoteEdit;
  static const DonneesIcone ajouter = HugeIcons.strokeRoundedAdd01;
  static const DonneesIcone supprimer = HugeIcons.strokeRoundedDelete02;
  static const DonneesIcone precedent = HugeIcons.strokeRoundedArrowLeft01;
  static const DonneesIcone suivant = HugeIcons.strokeRoundedArrowRight01;
  static const DonneesIcone valide = HugeIcons.strokeRoundedTick02;
}
