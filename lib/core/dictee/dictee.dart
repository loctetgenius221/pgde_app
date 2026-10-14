/// Dictée vocale : le contrat, indépendant de toute bibliothèque.
///
/// Les écrans ne connaissent que [MoteurDictee]. Le moteur réel
/// (`MoteurSpeechToText`) s'appuie sur la reconnaissance vocale du système ;
/// les tests en injectent un faux. Changer de moteur — ML Kit le jour où son
/// API sera stable, `SpeechAnalyzer` d'iOS 26 — ne touchera aucun écran.
library;

import 'package:flutter/foundation.dart';

/// Ce qui peut faire échouer une dictée, ramené à ce que le candidat peut
/// comprendre et faire.
enum ErreurDictee {
  /// Pas de reconnaissance vocale sur l'appareil, ou pas pour le français.
  indisponible('La dictée vocale n’est pas disponible sur cet appareil.'),

  /// Le candidat a refusé l'accès au micro.
  permissionRefusee(
    'Autorisez l’accès au micro dans les réglages pour dicter.',
  ),

  /// Rien de compréhensible n'a été entendu.
  rienEntendu('Rien n’a été entendu. Rapprochez-vous du micro et réessayez.'),

  /// La reconnaissance passe par le réseau et il fait défaut.
  reseau('Dictée impossible sans connexion. Vérifiez votre réseau.'),

  /// Tout le reste : le candidat peut simplement réessayer.
  autre('La dictée s’est interrompue. Réessayez.');

  const ErreurDictee(this.message);

  /// Message prêt à afficher.
  final String message;
}

/// Reçoit le texte reconnu au fil de la dictée. [definitif] est vrai pour la
/// dernière transcription de la session.
typedef SurTexteDicte = void Function(String texte, {required bool definitif});

/// Un moteur de reconnaissance vocale.
abstract interface class MoteurDictee {
  /// Prépare le moteur. Au premier appel, le système demande l'accès au
  /// micro. Renvoie `null` si tout est prêt, sinon la raison de l'échec —
  /// micro refusé ou dictée indisponible, qui ne se règlent pas pareil.
  Future<ErreurDictee?> preparer();

  /// Écoute jusqu'à une pause, la durée maximale ou [arreter].
  ///
  /// [surFin] est appelé une fois la session terminée, quelle qu'en soit la
  /// raison — y compris après [surErreur].
  Future<void> ecouter({
    required SurTexteDicte surTexte,
    required VoidCallback surFin,
    required ValueChanged<ErreurDictee> surErreur,
  });

  /// Arrête l'écoute ; le dernier texte entendu est livré comme définitif.
  Future<void> arreter();
}

/// Ajoute [dicte] à la suite de [existant], comme le ferait une saisie au
/// clavier.
///
/// - une espace sépare l'existant du texte dicté, sauf s'il finit déjà par un
///   blanc ;
/// - le texte dicté prend une majuscule en début de champ, après une fin
///   de phrase (`.`, `!`, `?`) ou après un retour à la ligne ;
/// - le résultat ne dépasse jamais [longueurMax], la limite du champ.
String fusionnerDictee(String existant, String dicte, {int? longueurMax}) {
  final String ajout = dicte.trim();
  if (ajout.isEmpty) return existant;

  final String fin = existant.trimRight();
  // Un retour à la ligne ouvre un nouveau paragraphe, donc une phrase.
  final bool debutDePhrase =
      fin.isEmpty ||
      existant.endsWith('\n') ||
      fin.endsWith('.') ||
      fin.endsWith('!') ||
      fin.endsWith('?');
  final String texte = debutDePhrase
      ? ajout[0].toUpperCase() + ajout.substring(1)
      : ajout;
  final bool colle =
      existant.isEmpty || existant.endsWith(' ') || existant.endsWith('\n');

  final String resultat = '$existant${colle ? '' : ' '}$texte';
  return longueurMax != null && resultat.length > longueurMax
      ? resultat.substring(0, longueurMax)
      : resultat;
}
