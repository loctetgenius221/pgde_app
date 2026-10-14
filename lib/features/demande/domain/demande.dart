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

  /// §5.2 — `Homme` / `Femme` sont acceptés puis normalisés côté serveur.
  static Genre? depuis(Object? brut) => switch (brut?.toString()) {
    'Masculin' || 'Homme' => masculin,
    'Feminin' || 'Femme' => feminin,
    _ => null,
  };
}

enum SituationMatrimoniale {
  celibataire('Célibataire'),
  marie('Marié(e)'),
  divorce('Divorcé(e)'),
  veuf('Veuf/Veuve');

  const SituationMatrimoniale(this.wire);

  final String wire;
}

/// Nature d'une pièce jointe — elle décide de la route, des formats admis et
/// du plafond de taille (contrat §6).
enum TypeFichier {
  photo('Photo de profil'),
  diplome('Diplôme'),

  /// §6.2 en prévoit le téléversement, mais le **CV est retiré de la saisie** :
  /// il doit être produit par le serveur à partir du dossier, qui contient
  /// déjà tout. Le type et la route restent en place — la lecture d'un CV
  /// déposé auparavant continue de fonctionner — pour que le rétablir ne
  /// coûte qu'un écran.
  cv('CV');

  const TypeFichier(this.libelle);

  final String libelle;
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

/// Une ligne de la liste dynamique « formations » (contrat §5.3).
@freezed
abstract class Formation with _$Formation {
  const factory Formation({
    required int academicId,
    @Default('') String diplome,
    int? anneeDiplome,
    @Default('') String specialite,
    @Default('') String etablissement,

    /// Justificatif de **cette** formation.
    ///
    /// Chemin serveur (`file_path`) + URL. Le fichier est d'abord
    /// téléversé (§6.4), puis son `file_path` est renvoyé dans
    /// `PUT /candidat/formations` via `diplome_file` (§5.3).
    FichierJoint? justificatif,
  }) = _Formation;

  const Formation._();

  factory Formation.fromJson(Map<String, dynamic> json) =>
      _$FormationFromJson(json);

  /// « Sans diplôme » masque intitulé, année, spécialité et établissement
  /// (§8.9).
  bool get sansDiplome => Academic.estSansDiplome(academicId);
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
    /// Vrai si le serveur détient déjà une fiche `userdata`.
    ///
    /// Les quatre endpoints d'écriture sont des `PUT` idempotents : il n'y a
    /// plus de création à distinguer d'une mise à jour. Ce drapeau ne sert
    /// donc qu'à l'affichage — « dossier enregistré » plutôt que « demande
    /// en préparation ».
    @Default(false) bool deposee,

    /// N° de dossier affiché au candidat (`candidat_number`, §5.1) — celui
    /// que la page web met en avant et qu'il cite à l'administration.
    int? numeroDossier,

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
    // §4 distingue **deux** champs : `handicap` (« 0 » ou « 1 ») et
    // `handicap_id`. Les fondre en un seul rendait « Oui » inexprimable tant
    // qu'aucun type n'était choisi — et donc intapable.
    @Default(false) bool aUnHandicap,
    int? handicapId,

    // --- Étape 2 : formations et justificatifs ---
    //
    // Chaque formation porte le sien (§5.1, §6.4). Il n'y a plus de tableau
    // global de diplômes : c'était l'aveu d'un serveur incapable de dire
    // quel document prouvait quelle formation.
    @Default(<Formation>[]) List<Formation> formations,

    // Les pièces vivent sur le serveur, déposées par des appels dédiés
    // (§6). Elles ne partent donc **pas** dans le corps du formulaire : on
    // les garde ici pour l'affichage et la suppression.
    @Default(<FichierJoint>[]) List<FichierJoint> cv,
    FichierJoint? photo,

    // --- Étape 3 : expériences ---
    // `null` tant que le candidat n'a pas répondu. Un booléen par défaut
    // faisait passer l'étape pour complétée avant même qu'il l'ait ouverte :
    // le dossier affichait une réponse que personne n'avait donnée.
    bool? aDeLExperience,
    @Default(<Experience>[]) List<Experience> experiences,

    // --- Étape 4 : vœux ---
    int? emploi1Id,
    int? emploi2Id,
    @Default(0) int anneesExperience1,
    @Default(0) int anneesExperience2,
    @Default('') String resumeCv,
  }) = _Demande;

  const Demande._();

  factory Demande.fromJson(Map<String, dynamic> json) =>
      _$DemandeFromJson(json);

  bool get existeSurLeServeur => deposee;

  /// Expériences telles que le serveur les conservera (§4, étape 3).
  List<Experience> get experiencesRetenues => aDeLExperience == true
      ? experiences.where((e) => e.estSignificative).toList()
      : const [];

  /// Justificatif de la formation [rang], s'il y en a un.
  FichierJoint? justificatifDe(int rang) =>
      rang < formations.length ? formations[rang].justificatif : null;

  /// Rattache un justificatif à la formation [rang].
  Demande avecJustificatif(int rang, FichierJoint? piece) {
    if (rang >= formations.length) return this;
    final List<Formation> suivantes = <Formation>[...formations];
    suivantes[rang] = suivantes[rang].copyWith(justificatif: piece);
    return copyWith(formations: suivantes);
  }

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
    // Sans réponse, l'étape reste à remplir : « non » est une réponse,
    // pas une absence de réponse.
    EtapeWizard.experiences => switch (aDeLExperience) {
      null => false,
      false => true,
      true => experiencesRetenues.isNotEmpty,
    },
    EtapeWizard.voeux =>
      emploi1Id != null && emploi2Id != null && emploi1Id != emploi2Id,
  };

  List<EtapeWizard> get etapesCompletes =>
      EtapeWizard.values.where(estComplete).toList();

  /// Première étape non complétée — celle que le candidat doit reprendre.
  ///
  /// `null` quand tout est rempli. C'est l'équivalent de
  /// `completion.etape_courante` du §7.6, calculé côté app tant que l'API
  /// n'existe pas.
  EtapeWizard? get etapeCourante {
    for (final EtapeWizard etape in EtapeWizard.values) {
      if (!estComplete(etape)) return etape;
    }
    return null;
  }

  double get progression => etapesCompletes.length / EtapeWizard.values.length;

  /// Les seuls champs réellement obligatoires côté serveur (§4).
  bool get peutEtreEnvoyee =>
      estComplete(EtapeWizard.identite) && estComplete(EtapeWizard.voeux);
}
