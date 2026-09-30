import 'demande.dart';

/// Contraintes serveur sur les pièces jointes (contrat §6).
///
/// Elles sont vérifiées **avant** l'envoi. Laisser le serveur refuser, c'est
/// faire attendre un candidat sur un réseau instable pour lui rendre un 422
/// au bout d'une minute — alors que la règle était connue d'avance.
///
/// Les trois natures de pièce n'ont ni les mêmes formats ni le même plafond :
/// une seule règle commune obligerait à retenir la plus sévère des trois, et
/// refuserait des fichiers que le serveur accepte.
abstract final class ReglesFichiers {
  /// §6.1 — la photo de profil.
  static const int tailleMaxPhoto = 4 * 1024 * 1024;

  /// §6.2 et §6.4 — les documents.
  static const int tailleMaxDocument = 8 * 1024 * 1024;

  static const Set<String> _photo = <String>{'jpg', 'jpeg', 'png', 'webp'};

  /// §6.4 — le justificatif de diplôme **accepte les images** : le candidat
  /// qui photographie son diplôme n'est plus bloqué.
  static const Set<String> _diplome = <String>{
    'pdf',
    'jpg',
    'jpeg',
    'png',
    'docx',
  };

  /// §6.2 — le CV, lui, reste un document bureautique.
  static const Set<String> _cv = <String>{'pdf', 'doc', 'docx'};

  static Set<String> extensionsAdmises(TypeFichier type) => switch (type) {
    TypeFichier.photo => _photo,
    TypeFichier.diplome => _diplome,
    TypeFichier.cv => _cv,
  };

  static int tailleMax(TypeFichier type) =>
      type == TypeFichier.photo ? tailleMaxPhoto : tailleMaxDocument;

  /// Message de refus, ou `null` si la pièce est acceptable.
  static String? refus({
    required TypeFichier type,
    required String nomFichier,
    required int octets,
  }) {
    final String extension = extensionDe(nomFichier);
    if (!extensionsAdmises(type).contains(extension)) {
      return 'Format refusé. ${formatsAdmis(type)}';
    }
    final int plafond = tailleMax(type);
    if (octets > plafond) {
      return 'Trop volumineux (${tailleLisible(octets)}). '
          'Maximum ${tailleLisible(plafond)}.';
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
    final double mo = octets / (1024 * 1024);
    // Un plafond rond se dit « 8 Mo », pas « 8.0 Mo ».
    return mo == mo.roundToDouble()
        ? '${mo.round()} Mo'
        : '${mo.toStringAsFixed(1)} Mo';
  }

  /// Libellé des formats admis, à afficher sous le sélecteur.
  static String formatsAdmis(TypeFichier type) => switch (type) {
    TypeFichier.photo => 'JPG, PNG ou WEBP · 4 Mo maximum',
    TypeFichier.diplome => 'PDF, image ou DOCX · 8 Mo maximum',
    TypeFichier.cv => 'PDF, DOC ou DOCX · 8 Mo maximum',
  };
}
