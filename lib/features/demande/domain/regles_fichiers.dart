import 'demande.dart';

/// Contraintes serveur sur les pièces jointes (§4, étape 2).
///
/// Elles sont vérifiées **avant** l'envoi. Laisser le serveur refuser, c'est
/// faire attendre un candidat sur un réseau instable pour lui rendre un 422
/// au bout d'une minute — alors que la règle était connue d'avance.
abstract final class ReglesFichiers {
  /// `max:2048` dans la validation Laravel, exprimé en kilo-octets.
  static const int tailleMaxOctets = 2 * 1024 * 1024;

  /// §4 — les diplômes et CV **n'acceptent aucune image**. Une photo de
  /// diplôme prise au téléphone est donc refusée (§6.2 D4) : c'est le premier
  /// mur que rencontre un candidat, et il faut le lui dire clairement.
  static const Set<String> extensionsDocument = <String>{
    'pdf',
    'doc',
    'docx',
    'rtf',
    'txt',
  };

  static const Set<String> extensionsPhoto = <String>{
    'jpg',
    'jpeg',
    'png',
    'gif',
  };

  static const int nombreMaxParType = 10;

  /// Message de refus, ou `null` si la pièce est acceptable.
  static String? refus({
    required String nomFichier,
    required int octets,
    required bool estPhoto,
  }) {
    final String extension = extensionDe(nomFichier);
    final Set<String> admises = estPhoto ? extensionsPhoto : extensionsDocument;

    if (!admises.contains(extension)) {
      return estPhoto
          ? 'Format non accepté. Choisissez une image JPG, PNG ou GIF.'
          : 'Format non accepté. Le serveur n’accepte que PDF, DOC, DOCX, '
                'RTF et TXT — pas les images. Convertissez votre document '
                'en PDF avant de l’envoyer.';
    }
    if (octets > tailleMaxOctets) {
      return 'Fichier trop volumineux (${tailleLisible(octets)}). '
          'La limite est de 2 Mo par fichier.';
    }
    if (octets == 0) return 'Ce fichier est vide.';
    return null;
  }

  static String extensionDe(String nomFichier) {
    final int point = nomFichier.lastIndexOf('.');
    return point == -1 ? '' : nomFichier.substring(point + 1).toLowerCase();
  }

  static String tailleLisible(int octets) {
    if (octets < 1024) return '$octets o';
    if (octets < 1024 * 1024) return '${(octets / 1024).round()} Ko';
    return '${(octets / (1024 * 1024)).toStringAsFixed(1)} Mo';
  }

  /// Libellé des formats admis, à afficher sous le sélecteur.
  static String formatsAdmis(TypeFichier type) =>
      'PDF, DOC, DOCX, RTF ou TXT — 2 Mo maximum. '
      '${type == TypeFichier.diplome ? 'Vos diplômes et attestations.' : 'Votre curriculum vitæ.'}';
}
