import '../../../core/ui/icone.dart';
import '../domain/message.dart';

/// Icône d'un bouton d'Amath, comme sur le site (contrat chatbot §5).
///
/// Choisie d'après l'**intention** du payload, jamais d'après le libellé :
/// les libellés changent, les intentions restent. Intention inconnue : pas
/// d'icône, et pas d'erreur.
DonneesIcone? iconeDuBouton(BoutonChat bouton) => switch (bouton.intention) {
  'go_back_greet_with_name' => Icones.maison,
  'go_back_ecarriere' ||
  'go_back_pgde' ||
  'retour_menu_utilisateur' => Icones.retour,
  'ask_support' => Icones.telephone,
  'start_account_verification' => Icones.reessayer,
  'confirm_has_account' ||
  'confirm_has_access' ||
  'confirm_password_reset' ||
  'confirm_reset_ecarriere' => Icones.valide,
  'deny_has_account' ||
  'deny_has_access' ||
  'deny_password_reset' ||
  'cancel_reset_ecarriere' => Icones.croix,
  'ask_account_creation' || 'ask_attestation_account' => Icones.ajoutCompte,
  'ask_login' => Icones.connexion,
  'ask_password_reset' || 'reset_password_ecarriere' => Icones.cle,
  'voir_actes' || 'ask_attestation_request' => Icones.document,
  'voir_projets' => Icones.graphique,
  'ask_attestation_info' => Icones.info,
  'ask_attestation_status' => Icones.horloge,
  'choose_platform' => switch (bouton.parametre('platform')) {
    'E-Carrière' => Icones.poste,
    'PGDE' => Icones.identifiant,
    'Attestation' => Icones.document,
    _ => null,
  },
  _ => null,
};
