import 'package:flutter_test/flutter_test.dart';
import 'package:pgde_app/core/dictee/dictee.dart';

void main() {
  group('fusionnerDictee — ajout à la suite du texte existant', () {
    test('champ vide : le texte dicté devient le contenu, avec majuscule', () {
      expect(fusionnerDictee('', 'je suis comptable'), 'Je suis comptable');
    });

    test('une espace sépare l’existant du texte dicté', () {
      expect(
        fusionnerDictee('Je suis', 'comptable depuis cinq ans'),
        'Je suis comptable depuis cinq ans',
      );
    });

    test('pas d’espace doublée si l’existant finit déjà par un blanc', () {
      expect(fusionnerDictee('Je suis ', 'comptable'), 'Je suis comptable');
    });

    test('après un retour à la ligne : nouveau paragraphe, majuscule', () {
      expect(fusionnerDictee('Ligne 1\n', 'ligne 2'), 'Ligne 1\nLigne 2');
    });

    test('majuscule après une fin de phrase, quelle qu’elle soit', () {
      expect(fusionnerDictee('Fin.', 'suite'), 'Fin. Suite');
      expect(fusionnerDictee('Vraiment !', 'oui'), 'Vraiment ! Oui');
      expect(
        fusionnerDictee('Pourquoi ?', 'parce que'),
        'Pourquoi ? Parce que',
      );
      // Même si un blanc suit le point.
      expect(fusionnerDictee('Fin.  ', 'suite'), 'Fin.  Suite');
    });

    test('pas de majuscule au milieu d’une phrase', () {
      expect(fusionnerDictee('J’ai géré', 'la paie'), 'J’ai géré la paie');
      expect(fusionnerDictee('Missions,', 'accueil'), 'Missions, accueil');
    });

    test('la majuscule gère les lettres accentuées', () {
      expect(fusionnerDictee('', 'été 2020 à Dakar'), 'Été 2020 à Dakar');
    });

    test('les blancs autour du texte dicté sont retirés', () {
      expect(
        fusionnerDictee('Bonjour', '  je suis là  '),
        'Bonjour je suis là',
      );
    });

    test('une dictée vide ne change rien, pas même les blancs', () {
      expect(fusionnerDictee('Bonjour ', ''), 'Bonjour ');
      expect(fusionnerDictee('Bonjour', '   '), 'Bonjour');
      expect(fusionnerDictee('', ''), '');
    });
  });

  group('fusionnerDictee — limite du champ', () {
    test('le résultat est tronqué à la longueur maximale', () {
      final String r = fusionnerDictee('abcde', 'fghij', longueurMax: 8);
      expect(r, 'abcde fg');
      expect(r.length, 8);
    });

    test('sous la limite, rien n’est coupé', () {
      expect(
        fusionnerDictee('Bonjour', 'à tous', longueurMax: 1000),
        'Bonjour à tous',
      );
    });

    test('un champ déjà plein le reste, sans débordement', () {
      final String plein = 'x' * 10;
      expect(fusionnerDictee(plein, 'encore', longueurMax: 10), plein);
    });

    test('sans limite, aucune troncature', () {
      final String long = 'mot ' * 500;
      expect(fusionnerDictee('', long).length, long.trim().length);
    });
  });

  group('ErreurDictee', () {
    test('chaque erreur a un message destiné au candidat', () {
      for (final ErreurDictee e in ErreurDictee.values) {
        expect(e.message.trim(), isNotEmpty, reason: '$e sans message');
        // Pas de jargon technique dans ce que lit le candidat.
        expect(e.message, isNot(contains('error_')));
      }
    });

    test('les messages sont tous différents', () {
      final Set<String> messages = ErreurDictee.values
          .map((e) => e.message)
          .toSet();
      expect(messages.length, ErreurDictee.values.length);
    });
  });
}
