import 'package:flutter_test/flutter_test.dart';
import 'package:pgde_app/features/demande/data/demande_mapper.dart';
import 'package:pgde_app/features/demande/domain/demande.dart';
import 'package:pgde_app/features/demande/domain/regles_fichiers.dart';
import 'package:pgde_app/features/demande/domain/telephone.dart';

void main() {
  group('Règles des pièces jointes (§4, étape 2)', () {
    test('un diplôme photographié est refusé, avec la raison (§6.2 D4)', () {
      final String? refus = ReglesFichiers.refus(
        nomFichier: 'diplome.jpg',
        octets: 100 * 1024,
        estPhoto: false,
      );
      expect(refus, isNotNull);
      // Le message doit dire quoi faire, pas seulement que c'est refusé.
      expect(refus, contains('PDF'));
    });

    test('les formats de document du serveur sont acceptés', () {
      for (final String extension in <String>['pdf', 'doc', 'docx', 'rtf', 'txt']) {
        expect(
          ReglesFichiers.refus(
            nomFichier: 'piece.$extension',
            octets: 1024,
            estPhoto: false,
          ),
          isNull,
          reason: '.$extension est dans la whitelist Laravel',
        );
      }
    });

    test('au-delà de 2 Mo, le fichier est refusé avant l’envoi', () {
      expect(
        ReglesFichiers.refus(
          nomFichier: 'cv.pdf',
          octets: ReglesFichiers.tailleMaxOctets,
          estPhoto: false,
        ),
        isNull,
      );
      final String? refus = ReglesFichiers.refus(
        nomFichier: 'cv.pdf',
        octets: ReglesFichiers.tailleMaxOctets + 1,
        estPhoto: false,
      );
      expect(refus, contains('2 Mo'));
    });

    test('la photo accepte les images, et elles seules', () {
      expect(
        ReglesFichiers.refus(
          nomFichier: 'moi.png',
          octets: 500 * 1024,
          estPhoto: true,
        ),
        isNull,
      );
      expect(
        ReglesFichiers.refus(
          nomFichier: 'moi.pdf',
          octets: 500 * 1024,
          estPhoto: true,
        ),
        isNotNull,
      );
    });
  });

  test('le CV n’est plus proposé à la saisie, mais reste lisible', () {
    // Le serveur doit le produire à partir du dossier. Retirer le type
    // entier casserait la lecture d'un CV déposé auparavant.
    expect(TypeFichier.proposes, <TypeFichier>[TypeFichier.diplome]);
    expect(TypeFichier.values, contains(TypeFichier.cv));

    const dossier = Demande(
      cv: <FichierJoint>[
        FichierJoint(chemin: 'uploads/cv/1_cv.pdf', url: 'http://x/1_cv.pdf'),
      ],
    );
    expect(dossier.fichiersDe(TypeFichier.cv), hasLength(1));
  });

  group('Pièce jointe — lecture (§7.6, §8.9)', () {
    test('le nom perd l’horodatage ajouté par le serveur', () {
      const piece = FichierJoint(
        chemin: 'uploads/cv/1775151073_Acte de reclassement.pdf',
        url: 'http://x/y',
      );
      expect(piece.nomAffiche, 'Acte de reclassement.pdf');
    });

    test('l’URL est encodée : les noms portent espaces et accents', () {
      const piece = FichierJoint(
        chemin: 'uploads/cv/1_Acte de reclassement.pdf',
        url: 'http://serveur/uploads/cv/1_Acte de reclassement.pdf',
      );
      expect(piece.urlSure, isNot(contains(' ')));
      expect(piece.urlSure, contains('%20'));
    });

    test('le bloc fichiers est résolu depuis la réponse', () {
      final Demande demande = DemandeMapper.depuisApi(<String, dynamic>{
        'fichiers': <String, dynamic>{
          'photo_profil': <String, dynamic>{
            'path': 'uploads/photos/1_x.jpg',
            'url': 'http://serveur/uploads/photos/1_x.jpg',
          },
          'diplomes': <dynamic>[
            <String, dynamic>{
              'path': 'uploads/diplome/1_d.pdf',
              'url': 'http://serveur/uploads/diplome/1_d.pdf',
              'nom': 'd.pdf',
              'taille': 184320,
            },
          ],
          'cv': <dynamic>[],
        },
      });

      expect(demande.photo?.chemin, 'uploads/photos/1_x.jpg');
      expect(demande.diplomes, hasLength(1));
      expect(demande.diplomes.single.tailleLisible, '180 Ko');
      expect(demande.cv, isEmpty);
    });

    test('un chemin nu est absolutisé plutôt qu’ignoré (§8.9)', () {
      // La colonne `photo_profil` est un simple varchar : certaines réponses
      // ne donneront qu'un chemin, avec l'un des deux préfixes historiques.
      for (final String chemin in <String>[
        'uploads/photos/1_x.jpg',
        'storage/uploads/1_x.jpg',
      ]) {
        final Demande demande = DemandeMapper.depuisApi(<String, dynamic>{
          'fichiers': <String, dynamic>{'photo_profil': chemin},
        });
        expect(demande.photo, isNotNull);
        expect(demande.photo!.chemin, chemin);
        expect(demande.photo!.url, endsWith(chemin));
      }
    });
  });

  group('Téléphone (§8.9)', () {
    test('accepte les numéros sénégalais, espacés ou non', () {
      for (final String numero in <String>[
        '770000000',
        '77 000 00 00',
        '+221770000000',
        '00221 78 123 45 67',
        '338211234',
      ]) {
        expect(Telephone.refus(numero), isNull, reason: numero);
      }
    });

    test('refuse une longueur ou un préfixe impossibles', () {
      expect(Telephone.refus('7700000'), contains('9 chiffres'));
      expect(Telephone.refus('990000000'), contains('Préfixe'));
    });

    test('accepte un international plausible', () {
      expect(Telephone.refus('+33612345678'), isNull);
      expect(Telephone.refus('+1'), isNotNull);
    });

    test('un champ vide n’est pas une erreur de format', () {
      // Le caractère obligatoire de `telephone1` relève de la complétude du
      // dossier, pas de la validation du format.
      expect(Telephone.refus(''), isNull);
      expect(Telephone.refus('   '), isNull);
    });

    test('met en forme un numéro national pour la lecture', () {
      expect(Telephone.formater('770000000'), '77 000 00 00');
      expect(Telephone.formater('+33612345678'), '+33612345678');
    });
  });
}
