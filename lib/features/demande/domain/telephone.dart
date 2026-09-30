/// Validation des numéros de téléphone (§8.9).
///
/// La colonne est un `varchar(45)` sans aucune contrainte : le serveur
/// accepterait « bonjour ». C'est donc à l'app de garantir qu'un numéro
/// enregistré est joignable — c'est par lui que le candidat sera rappelé.
abstract final class Telephone {
  /// Préfixes mobiles et fixes en service au Sénégal.
  static const Set<String> _prefixesSenegal = <String>{
    '70', '75', '76', '77', '78', // mobiles
    '33', '32', '34', '35', '36', // fixes
  };

  static const String _indicatifSenegal = '221';

  /// Retire tout ce qui n'est ni un chiffre ni le `+` initial.
  static String normaliser(String brut) {
    final String compact = brut.replaceAll(RegExp(r'[\s.\-()]'), '');
    return compact.startsWith('+')
        ? '+${compact.substring(1).replaceAll(RegExp(r'\D'), '')}'
        : compact.replaceAll(RegExp(r'\D'), '');
  }

  /// Message de refus, ou `null` si le numéro est plausible.
  ///
  /// Un champ vide n'est pas refusé ici : le caractère obligatoire de
  /// `telephone1` relève de la complétude du dossier, pas du format.
  static String? refus(String brut) {
    final String numero = normaliser(brut);
    if (numero.isEmpty) return null;

    if (numero.startsWith('+')) {
      final String chiffres = numero.substring(1);
      if (chiffres.startsWith(_indicatifSenegal)) {
        return _refusNational(chiffres.substring(_indicatifSenegal.length));
      }
      // Format international générique : indicatif + numéro, 8 à 15 chiffres.
      return (chiffres.length >= 8 && chiffres.length <= 15)
          ? null
          : 'Numéro international invalide.';
    }

    // Saisie nationale, avec ou sans le 00221 en tête.
    if (numero.startsWith('00$_indicatifSenegal')) {
      return _refusNational(numero.substring(5));
    }
    return _refusNational(numero);
  }

  static String? _refusNational(String chiffres) {
    if (chiffres.length != 9) {
      return 'Un numéro sénégalais compte 9 chiffres (ex. 77 123 45 67).';
    }
    if (!_prefixesSenegal.contains(chiffres.substring(0, 2))) {
      return 'Préfixe inconnu (70, 75, 76, 77, 78 ou 33).';
    }
    return null;
  }

  /// Mise en forme lisible : `77 123 45 67`, `+33 6 12 34 56 78`.
  static String formater(String brut) {
    final String numero = normaliser(brut);
    if (numero.startsWith('+') || numero.length != 9) return numero;
    return '${numero.substring(0, 2)} ${numero.substring(2, 5)} '
        '${numero.substring(5, 7)} ${numero.substring(7)}';
  }
}
