import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/json/converters.dart';
import '../../reference/domain/referentiel.dart';
import 'wizard.dart';

part 'demande.freezed.dart';
part 'demande.g.dart';

/// §4 — valeurs libres en base mais **non contraintes** : une chaîne hors de
/// cette liste rend le candidat invisible aux filtres de l'administration.
/// L'énumération garantit qu'on n'envoie jamais autre chose.
enum Genre {
  masculin('Masculin'),
  feminin('Feminin'); // sans accent, tel qu'attendu par le backend

  const Genre(this.wire);

  final String wire;
}

enum SituationMatrimoniale {
  celibataire('Célibataire'),
  marie('Marié(e)'),
  divorce('Divorcé(e)'),
  veuf('Veuf/Veuve');

  const SituationMatrimoniale(this.wire);

  final String wire;
}

/// Nature d'une pièce jointe — elle décide de l'endpoint et des formats admis.
enum TypeFichier {
  diplome('diplome', 'Diplôme'),
  cv('cv', 'CV');

  const TypeFichier(this.wire, this.libelle);

  final String wire;
  final String libelle;

  /// Types réellement proposés à la saisie aujourd'hui.
  ///
  /// §4 en prévoit deux, mais le **CV est retiré du formulaire** : il doit
  /// être produit par le serveur à partir des informations du dossier, qui les
  /// contient toutes. Le type et les appels restent en place — la lecture d'un
  /// CV déposé auparavant continue de fonctionner — pour que le rétablir ne
  /// coûte qu'une ligne.
  static const List<TypeFichier> proposes = <TypeFichier>[TypeFichier.diplome];
}

/// Un fichier déposé sur le serveur (§7.6, bloc `fichiers`).
///
/// [chemin] est conservé en plus de [url] : c'est **lui** que le serveur
/// attend pour une suppression, jamais l'URL absolue.
@freezed
abstract class FichierJoint with _$FichierJoint {
  const factory FichierJoint({
    required String chemin,
    required String url,
    @Default('') String nom,
    int? taille,
  }) = _FichierJoint;

  const FichierJoint._();

  factory FichierJoint.fromJson(Map<String, dynamic> json) =>
      _$FichierJointFromJson(json);

  /// §8.9 — les noms de fichiers du serveur contiennent espaces et accents
  /// non assainis : une URL brute casse le téléchargement et l'affichage.
  String get urlSure => Uri.encodeFull(url);

  /// Nom lisible, déduit du chemin quand le serveur n'en fournit pas.
  String get nomAffiche {
    if (nom.isNotEmpty) return nom;
    final String dernier = chemin.split('/').last;
    // Le serveur préfixe par `time() . '_'` (§4) : on retire cet horodatage.
    final int separateur = dernier.indexOf('_');
    return separateur == -1 ? dernier : dernier.substring(separateur + 1);
  }

  String get tailleLisible {
    final int? octets = taille;
    if (octets == null) return '';
    if (octets < 1024) return '$octets o';
    if (octets < 1024 * 1024) return '${(octets / 1024).round()} Ko';
    return '${(octets / (1024 * 1024)).toStringAsFixed(1)} Mo';
  }
}

/// Une ligne de la liste dynamique « formations » (§4, étape 2).
@freezed
abstract class Formation with _$Formation {
  const factory Formation({
    required int academicId,
    @Default('') String diplome,
    int? anneeDiplome,
    @Default('') String specialite,
    @Default('') String etablissement,
  }) = _Formation;

  const Formation._();

  factory Formation.fromJson(Map<String, dynamic> json) =>
      _$FormationFromJson(json);

  /// « Sans diplôme » masque intitulé, année, spécialité et établissement
  /// (§8.9).
  bool get sansDiplome => academicId == Academic.sansDiplomeId;
}

/// Une ligne de la liste dynamique « expériences » (§4, étape 3).
@freezed
abstract class Experience with _$Experience {
  const factory Experience({
    @Default('') String poste,
    @Default('') String employeur,
    @Default('') String description,
    int? annees,
  }) = _Experience;

  const Experience._();

  factory Experience.fromJson(Map<String, dynamic> json) =>
      _$ExperienceFromJson(json);

  /// Le serveur ne conserve une expérience que si au moins un de ces trois
  /// champs est rempli (§4, étape 3). On applique la même règle avant envoi
  /// pour que l'écran reflète exactement ce qui sera enregistré.
  bool get estSignificative =>
      poste.trim().isNotEmpty ||
      employeur.trim().isNotEmpty ||
      description.trim().isNotEmpty;
}

/// Le dossier du candidat — table `userdata`.
///
/// **Un seul par compte** : `utilisateur_id` porte une contrainte UNIQUE
/// (§2.1). Le parcours est donc « créer si absent, sinon éditer » ; il
/// n'existe pas de « nouvelle demande ».
///
/// **Agrégat complet, toujours.** Un `PUT` partiel efface côté serveur les
/// formations et expériences absentes de la requête (§6.2 D1). L'app détient
/// donc l'intégralité du dossier en mémoire et le renvoie entier à chaque
/// enregistrement. C'est la raison d'être de ce modèle unique et immuable.
///
/// La sérialisation générée ici sert **au brouillon local uniquement** : elle
/// fait un aller-retour avec elle-même. La correspondance avec l'API — dont
/// la lecture (§7.6, imbriquée) et l'écriture (§7.7, à plat) n'ont pas la
/// même forme — est explicite, dans la couche `data`.
@freezed
abstract class Demande with _$Demande {
  const factory Demande({
    int? id,

    // --- Étape 1 : identité et résidence ---
    @DateOnlyConverter() DateTime? dateNaissance,
    @Default('') String lieuNaissance,
    @Default('') String lieuResidence,
    @Default('') String adresse,
    Genre? genre,
    SituationMatrimoniale? situationMatrimoniale,
    @Default('') String telephone1,
    @Default('') String telephone2,
    @Default(0) int nombreEnfants,
    int? paysId,
    int? regionNaissanceId,
    int? departementNaissanceId,
    int? regionResidenceId,
    int? departementResidenceId,
    int? handicapId,

    // --- Étape 2 : formations et pièces jointes ---
    @Default(<Formation>[]) List<Formation> formations,

    // Les pièces vivent sur le serveur, déposées par des appels dédiés
    // (§7.5). Elles ne partent donc **pas** dans le corps du formulaire : on
    // les garde ici pour l'affichage et la suppression.
    @Default(<FichierJoint>[]) List<FichierJoint> diplomes,
    @Default(<FichierJoint>[]) List<FichierJoint> cv,
    FichierJoint? photo,

    // --- Étape 3 : expériences ---
    @Default(false) bool aDeLExperience,
    @Default(<Experience>[]) List<Experience> experiences,

    // --- Étape 4 : vœux ---
    int? emploi1Id,
    int? emploi2Id,
    @Default(0) int anneesExperience1,
    @Default(0) int anneesExperience2,
    @Default('') String resumeCv,
  }) = _Demande;

  const Demande._();

  factory Demande.fromJson(Map<String, dynamic> json) => _$DemandeFromJson(json);

  bool get existeSurLeServeur => id != null;

  /// Expériences telles que le serveur les conservera (§4, étape 3).
  List<Experience> get experiencesRetenues =>
      aDeLExperience ? experiences.where((e) => e.estSignificative).toList() : const [];

  List<FichierJoint> fichiersDe(TypeFichier type) =>
      type == TypeFichier.diplome ? diplomes : cv;

  Demande avecFichiers(TypeFichier type, List<FichierJoint> fichiers) =>
      type == TypeFichier.diplome
      ? copyWith(diplomes: fichiers)
      : copyWith(cv: fichiers);

  /// §5.1 — hors Sénégal : on demande le pays et on masque le département.
  bool get resideHorsSenegal => regionResidenceId == Region.horsSenegalId;

  /// Une étape est complète quand tous ses champs obligatoires à la création
  /// sont renseignés (§4, récapitulatif).
  bool estComplete(EtapeWizard etape) => switch (etape) {
    EtapeWizard.identite =>
      dateNaissance != null &&
          genre != null &&
          lieuNaissance.trim().isNotEmpty &&
          lieuResidence.trim().isNotEmpty &&
          telephone1.trim().isNotEmpty,
    // Aucun champ obligatoire côté serveur, mais un dossier sans formation
    // n'a pas de sens : on le signale sans bloquer.
    EtapeWizard.formations => formations.isNotEmpty,
    EtapeWizard.experiences => !aDeLExperience || experiencesRetenues.isNotEmpty,
    EtapeWizard.voeux =>
      emploi1Id != null && emploi2Id != null && emploi1Id != emploi2Id,
  };

  List<EtapeWizard> get etapesCompletes =>
      EtapeWizard.values.where(estComplete).toList();

  double get progression => etapesCompletes.length / EtapeWizard.values.length;

  /// Les seuls champs réellement obligatoires côté serveur (§4).
  bool get peutEtreEnvoyee =>
      estComplete(EtapeWizard.identite) && estComplete(EtapeWizard.voeux);
}
