import 'package:flutter_test/flutter_test.dart';
import 'package:pgde_app/features/demande/data/demande_mapper.dart';
import 'package:pgde_app/features/demande/domain/demande.dart';
import 'package:pgde_app/features/demande/domain/regles_fichiers.dart';
import 'package:pgde_app/features/demande/domain/telephone.dart';

void main() {
  group('Règles des pièces jointes (contrat §6)', () {
    test('chaque nature de pièce a ses propres formats', () {
      // §6.4 : le justificatif de diplôme **accepte les images**. C'était le
      // premier mur que rencontrait un candidat ; le contrat l'a levé.
      expect(
        ReglesFichiers.refus(
          type: TypeFichier.diplome,
          nomFichier: 'diplome.jpg',
          octets: 100 * 1024,
        ),
        isNull,
      );
      // §6.2 : le CV, lui, reste bureautique.
      expect(
        ReglesFichiers.refus(
          type: TypeFichier.cv,
          nomFichier: 'cv.jpg',
          octets: 100 * 1024,
        ),
        isNotNull,
      );
      // §6.1 : la photo n'accepte pas un PDF.
      expect(
        ReglesFichiers.refus(
          type: TypeFichier.photo,
          nomFichier: 'moi.pdf',
          octets: 100 * 1024,
        ),
        isNotNull,
      );
      expect(
        ReglesFichiers.refus(
          type: TypeFichier.photo,
          nomFichier: 'moi.webp',
          octets: 100 * 1024,
        ),
        isNull,
      );
    });

    test('les plafonds diffèrent : 4 Mo pour la photo, 8 Mo sinon', () {
      expect(ReglesFichiers.tailleMaxPhoto, 4 * 1024 * 1024);
      expect(ReglesFichiers.tailleMaxDocument, 8 * 1024 * 1024);

      // 6 Mo : refusé en photo, accepté en justificatif. Une limite unique
      // aurait refusé les deux, ou laissé passer ce que le serveur refuse.
      const int sixMo = 6 * 1024 * 1024;
      expect(
        ReglesFichiers.refus(
          type: TypeFichier.photo,
          nomFichier: 'moi.jpg',
          octets: sixMo,
        ),
        isNotNull,
      );
      expect(
        ReglesFichiers.refus(
          type: TypeFichier.diplome,
          nomFichier: 'd.pdf',
          octets: sixMo,
        ),
        isNull,
      );
    });

    test('un fichier vide est refusé, et le plafond s’annonce rond', () {
      expect(
        ReglesFichiers.refus(
          type: TypeFichier.diplome,
          nomFichier: 'd.pdf',
          octets: 0,
        ),
        contains('vide'),
      );
      // « 8 Mo », pas « 8.0 Mo ».
      expect(ReglesFichiers.tailleLisible(8 * 1024 * 1024), '8 Mo');
      expect(ReglesFichiers.tailleLisible(180 * 1024), '180 Ko');
    });
  });

  test('le CV n’est plus proposé à la saisie, mais reste lisible', () {
    // Le serveur doit le produire à partir du dossier. Retirer le type
    // entier casserait la lecture d'un CV déposé auparavant (§6.2).
    const dossier = Demande(
      cv: <FichierJoint>[
        FichierJoint(chemin: 'uploads/cv/1_cv.pdf', url: 'http://x/1_cv.pdf'),
      ],
    );
    expect(dossier.cv, hasLength(1));
    expect(TypeFichier.values, contains(TypeFichier.cv));
  });

  group('Pièce jointe — lecture (§5.1)', () {
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

    test('un chemin nu est absolutisé plutôt qu’ignoré', () {
      // Le contrat rend des URLs absolues, mais afficher une image vide
      // parce qu'une réponse a livré un chemin relatif serait un mauvais
      // échange.
      final Demande demande = DemandeMapper.depuisApi(<String, dynamic>{
        'identity': <String, dynamic>{
          'photo_profil_url': 'uploads/photos/1_x.jpg',
        },
      });
      expect(demande.photo, isNotNull);
      expect(demande.photo!.url, endsWith('uploads/photos/1_x.jpg'));
      expect(demande.photo!.url, startsWith('http'));
    });
  });

  group('Justificatif rattaché à sa formation (§5.1, §6.4)', () {
    test('le serveur porte le lien : chaque formation a le sien', () {
      const Demande dossier = Demande(
        formations: <Formation>[
          Formation(
            academicId: 4,
            justificatif: FichierJoint(
              chemin: 'uploads/diplomes/1_licence.pdf',
              url: 'http://x/licence.pdf',
              nom: 'licence.pdf',
            ),
          ),
          Formation(academicId: 9),
        ],
      );

      expect(dossier.justificatifDe(0)?.nomAffiche, 'licence.pdf');
      // Une formation sans justificatif n'en emprunte pas un autre.
      expect(dossier.justificatifDe(1), isNull);
      // Hors liste : pas de justificatif, pas d'exception non plus.
      expect(dossier.justificatifDe(7), isNull);
    });

    test('rattacher et détacher n’affectent que la formation visée', () {
      const Demande dossier = Demande(
        formations: <Formation>[Formation(academicId: 4), Formation(academicId: 9)],
      );
      const FichierJoint piece = FichierJoint(
        chemin: 'uploads/diplomes/1_master.pdf',
        url: 'http://x/master.pdf',
      );

      final Demande avec = dossier.avecJustificatif(1, piece);
      expect(avec.justificatifDe(1), piece);
      expect(avec.justificatifDe(0), isNull);

      expect(avec.avecJustificatif(1, null).justificatifDe(1), isNull);
      // Un rang qui n'existe pas ne crée pas de formation fantôme.
      expect(dossier.avecJustificatif(9, piece).formations, hasLength(2));
    });
  });

  group('Téléphone', () {
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
