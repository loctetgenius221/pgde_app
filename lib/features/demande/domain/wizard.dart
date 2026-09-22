/// Les quatre étapes du formulaire de demande (§4).
enum EtapeWizard {
  identite(1, 'Identité et résidence'),
  formations(2, 'Formations et documents'),
  experiences(3, 'Expériences professionnelles'),
  voeux(4, "Vœux d'emploi");

  const EtapeWizard(this.numero, this.titre);

  final int numero;
  final String titre;

  /// §8.7 — aiguille une erreur de validation 422 vers le bon écran.
  ///
  /// Les clés indexées renvoyées par Laravel (`formations.0.academic_id`,
  /// `experiences.1.years`) sont normalisées sur leur racine.
  static EtapeWizard? pourChamp(String champ) => _parChamp[champ.split('.').first];

  static const Map<String, EtapeWizard> _parChamp = <String, EtapeWizard>{
    'datenaiss': identite,
    'lieunaiss': identite,
    'lieuresidence': identite,
    'genre': identite,
    'situationmatrimoniale': identite,
    'nombreenfant': identite,
    'telephone1': identite,
    'telephone2': identite,
    'addresse': identite,
    'country_id': identite,
    'regionnaiss_id': identite,
    'departementnaiss_id': identite,
    'regionresidence_id': identite,
    'departementresidence_id': identite,
    'handicap_id': identite,
    'formations': formations,
    'diplome_file': formations,
    'cv_file': formations,
    'photo_profil': formations,
    'hasExperience': experiences,
    'experiences': experiences,
    'emploi1_id': voeux,
    'emploi2_id': voeux,
    'anneeexperience1': voeux,
    'anneeexperience2': voeux,
    'cv_summary': voeux,
  };
}
