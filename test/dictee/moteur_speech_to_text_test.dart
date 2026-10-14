import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pgde_app/core/dictee/dictee.dart';
import 'package:pgde_app/core/dictee/moteur_speech_to_text.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text_platform_interface/speech_to_text_platform_interface.dart';

/// Plateforme de reconnaissance simulée.
///
/// Elle parle à `SpeechToText` exactement comme le code natif : par les mêmes
/// rappels, avec les mêmes JSON. L'adaptateur est donc éprouvé de bout en
/// bout, plugin compris, sans micro.
class _PlateformeSimulee extends SpeechToTextPlatform
    with MockPlatformInterfaceMixin {
  bool initialisationReussie = true;
  bool permissionAccordee = true;
  bool echecEcoute = false;
  List<String> localesDisponibles = <String>['fr_FR:Français (France)'];

  int initialisations = 0;
  int ecoutes = 0;
  int arrets = 0;
  SpeechListenOptions? dernieresOptions;

  @override
  Future<bool> initialize({
    debugLogging = false,
    List<SpeechConfigOption>? options,
  }) async {
    initialisations++;
    return initialisationReussie;
  }

  @override
  Future<bool> hasPermission() async => permissionAccordee;

  @override
  Future<List<dynamic>> locales() async => localesDisponibles;

  @override
  Future<bool> listen({
    String? localeId,
    partialResults = true,
    onDevice = false,
    int listenMode = 0,
    sampleRate = 0,
    SpeechListenOptions? options,
  }) async {
    ecoutes++;
    if (echecEcoute) {
      throw PlatformException(code: 'listenFailed', message: 'micro occupé');
    }
    dernieresOptions = options;
    onStatus?.call(SpeechToText.listeningStatus);
    return true;
  }

  @override
  Future<void> stop() async => arrets++;

  @override
  Future<void> cancel() async {}

  // --- Ce que ferait le code natif ---

  void entendre(String mots, {bool definitif = false}) {
    final SpeechRecognitionResult resultat = SpeechRecognitionResult(
      <SpeechRecognitionWords>[SpeechRecognitionWords(mots, null, 0.9)],
      definitif ? ResultType.finalResult.value : ResultType.partial.value,
    );
    onTextRecognition?.call(jsonEncode(resultat.toJson()));
  }

  void statut(String statut) => onStatus?.call(statut);

  void erreur(String code, {bool permanente = true}) => onError?.call(
    jsonEncode(SpeechRecognitionError(code, permanente).toJson()),
  );
}

/// Ce que reçoit l'écran pendant une session.
class _Journal {
  final List<(String, bool)> textes = <(String, bool)>[];
  final List<ErreurDictee> erreurs = <ErreurDictee>[];
  int fins = 0;

  Future<void> ecouter(MoteurDictee moteur) => moteur.ecouter(
    surTexte: (texte, {required definitif}) => textes.add((texte, definitif)),
    surFin: () => fins++,
    surErreur: erreurs.add,
  );
}

void main() {
  late _PlateformeSimulee plateforme;
  late MoteurSpeechToText moteur;

  setUp(() {
    plateforme = _PlateformeSimulee();
    SpeechToTextPlatform.instance = plateforme;
    // Une instance neuve par test : `SpeechToText()` est un singleton.
    moteur = MoteurSpeechToText(SpeechToText.withMethodChannel());
  });

  group('Préparation', () {
    test('réussie : aucune erreur, et une seule initialisation', () async {
      expect(await moteur.preparer(), isNull);
      expect(await moteur.preparer(), isNull);
      expect(plateforme.initialisations, 1);
    });

    test(
      'micro refusé : on le dit, pour que le candidat sache quoi faire',
      () async {
        plateforme
          ..initialisationReussie = false
          ..permissionAccordee = false;
        expect(await moteur.preparer(), ErreurDictee.permissionRefusee);
      },
    );

    test('micro accordé mais pas de reconnaissance : indisponible', () async {
      plateforme.initialisationReussie = false;
      expect(await moteur.preparer(), ErreurDictee.indisponible);
    });

    test(
      'après un échec, une nouvelle tentative réinterroge le système',
      () async {
        // Le candidat a pu accorder le micro dans les réglages entre-temps.
        plateforme.initialisationReussie = false;
        await moteur.preparer();
        plateforme.initialisationReussie = true;
        expect(await moteur.preparer(), isNull);
        expect(plateforme.initialisations, 2);
      },
    );
  });

  group('Choix de la langue', () {
    Future<String?> localeRetenue(List<String> locales) async {
      plateforme.localesDisponibles = locales;
      await _Journal().ecouter(moteur);
      return plateforme.dernieresOptions?.localeId;
    }

    test('le français du Sénégal passe en premier', () async {
      expect(
        await localeRetenue(<String>[
          'en_US:English',
          'fr_FR:Français (France)',
          'fr_SN:Français (Sénégal)',
        ]),
        'fr_SN',
      );
    });

    test('à défaut, le français de France', () async {
      expect(
        await localeRetenue(<String>['fr_CA:Français (Canada)', 'fr_FR:Fr']),
        'fr_FR',
      );
    });

    test('l’identifiant renvoyé tel quel, même avec un tiret', () async {
      expect(await localeRetenue(<String>['fr-FR:Français']), 'fr-FR');
    });

    test('à défaut, n’importe quelle variante française', () async {
      expect(
        await localeRetenue(<String>['en_US:English', 'fr_CA:Français']),
        'fr_CA',
      );
    });

    test('sans français : la langue du système (aucune imposée)', () async {
      expect(await localeRetenue(<String>['en_US:English']), isNull);
    });
  });

  group('Écoute', () {
    test('réglée pour la dictée de phrases', () async {
      await _Journal().ecouter(moteur);
      final SpeechListenOptions options = plateforme.dernieresOptions!;
      expect(options.listenMode, ListenMode.dictation);
      expect(options.partialResults, isTrue);
      expect(options.cancelOnError, isTrue);
      expect(options.autoPunctuation, isTrue);
      expect(options.pauseFor, MoteurSpeechToText.pauseMax);
      expect(options.listenFor, MoteurSpeechToText.dureeMax);
      // Une minute au plus : la limite de la reconnaissance serveur d'iOS.
      expect(
        MoteurSpeechToText.dureeMax,
        lessThanOrEqualTo(const Duration(minutes: 1)),
      );
    });

    test('le texte arrive au fil de la parole, puis définitif', () async {
      final _Journal journal = _Journal();
      await journal.ecouter(moteur);

      plateforme
        ..entendre('je suis')
        ..entendre('je suis comptable')
        ..entendre('je suis comptable', definitif: true);

      expect(journal.textes, <(String, bool)>[
        ('je suis', false),
        ('je suis comptable', false),
        ('je suis comptable', true),
      ]);
    });

    test('la session se termine au statut « done », une seule fois', () async {
      final _Journal journal = _Journal();
      await journal.ecouter(moteur);

      plateforme
        ..entendre('bonjour', definitif: true)
        ..statut(SpeechToText.doneStatus)
        ..statut(SpeechToText.doneStatus);

      expect(journal.fins, 1);
    });

    test('fin sans rien entendre : la session se termine quand même', () async {
      final _Journal journal = _Journal();
      await journal.ecouter(moteur);

      plateforme.statut('doneNoResult');

      expect(journal.fins, 1);
      expect(journal.textes, isEmpty);
      // Le candidat doit savoir pourquoi rien ne s'est écrit.
      expect(journal.erreurs, <ErreurDictee>[ErreurDictee.rienEntendu]);
    });

    test('ordre réel d’Android : fin, puis erreur « pas de parole »', () async {
      // Constaté sur tablette Android 14 : le plugin annonce la fin avant
      // l'erreur. Un seul message, une seule fin.
      final _Journal journal = _Journal();
      await journal.ecouter(moteur);

      plateforme
        ..statut('doneNoResult')
        ..erreur('error_no_match');

      expect(journal.erreurs, <ErreurDictee>[ErreurDictee.rienEntendu]);
      expect(journal.fins, 1);
    });

    test('du texte entendu : la fin ne signale aucune erreur', () async {
      final _Journal journal = _Journal();
      await journal.ecouter(moteur);

      plateforme
        ..entendre('bonjour', definitif: true)
        ..statut(SpeechToText.doneStatus);

      expect(journal.erreurs, isEmpty);
    });

    test('des résultats vides ne comptent pas comme entendus', () async {
      final _Journal journal = _Journal();
      await journal.ecouter(moteur);

      plateforme
        ..entendre('  ', definitif: true)
        ..statut(SpeechToText.doneStatus);

      expect(journal.erreurs, <ErreurDictee>[ErreurDictee.rienEntendu]);
    });

    test('chaque session repart de zéro', () async {
      // Une première session a entendu des mots…
      final _Journal premiere = _Journal();
      await premiere.ecouter(moteur);
      plateforme
        ..entendre('oui', definitif: true)
        ..statut(SpeechToText.doneStatus);

      // … la suivante, silencieuse, doit quand même le signaler.
      final _Journal seconde = _Journal();
      await seconde.ecouter(moteur);
      plateforme.statut('doneNoResult');

      expect(premiere.erreurs, isEmpty);
      expect(seconde.erreurs, <ErreurDictee>[ErreurDictee.rienEntendu]);
    });

    test('rien n’est transmis après la fin de session', () async {
      final _Journal journal = _Journal();
      await journal.ecouter(moteur);
      plateforme
        ..entendre('fin', definitif: true)
        ..statut(SpeechToText.doneStatus);

      plateforme.erreur('error_no_match');

      expect(journal.erreurs, isEmpty);
      expect(journal.fins, 1);
    });

    test('arrêter demande l’arrêt au système', () async {
      await _Journal().ecouter(moteur);
      await moteur.arreter();
      expect(plateforme.arrets, 1);
    });
  });

  group('Erreurs', () {
    test(
      'une erreur de la plateforme est traduite, puis la session finit',
      () async {
        final _Journal journal = _Journal();
        await journal.ecouter(moteur);

        plateforme.erreur('error_no_match');

        expect(journal.erreurs, <ErreurDictee>[ErreurDictee.rienEntendu]);
        expect(journal.fins, 1);
      },
    );

    test('erreur puis « done » : une seule fin', () async {
      final _Journal journal = _Journal();
      await journal.ecouter(moteur);

      plateforme
        ..erreur('error_network')
        ..statut('doneNoResult');

      expect(journal.erreurs, <ErreurDictee>[ErreurDictee.reseau]);
      expect(journal.fins, 1);
    });

    test(
      'préparation impossible : erreur et fin, sans ouvrir le micro',
      () async {
        plateforme
          ..initialisationReussie = false
          ..permissionAccordee = false;
        final _Journal journal = _Journal();

        await journal.ecouter(moteur);

        expect(journal.erreurs, <ErreurDictee>[ErreurDictee.permissionRefusee]);
        expect(journal.fins, 1);
        expect(plateforme.ecoutes, 0);
      },
    );

    test('le système refuse d’écouter : erreur et fin', () async {
      plateforme.echecEcoute = true;
      final _Journal journal = _Journal();

      await journal.ecouter(moteur);

      expect(journal.erreurs, <ErreurDictee>[ErreurDictee.autre]);
      expect(journal.fins, 1);
    });

    test('codes Android et iOS ramenés à ce que le candidat peut faire', () {
      const Map<String, ErreurDictee> attendus = <String, ErreurDictee>{
        'error_insufficient_permissions': ErreurDictee.permissionRefusee,
        'error_permission': ErreurDictee.permissionRefusee,
        'error_no_match': ErreurDictee.rienEntendu,
        'error_speech_timeout': ErreurDictee.rienEntendu,
        'error_network': ErreurDictee.reseau,
        'error_network_timeout': ErreurDictee.reseau,
        'error_server': ErreurDictee.reseau,
        'error_server_disconnected': ErreurDictee.reseau,
        'error_language_not_supported': ErreurDictee.indisponible,
        'error_language_unavailable': ErreurDictee.indisponible,
        'error_busy': ErreurDictee.autre,
        'error_audio_error': ErreurDictee.autre,
        'error_listen_failed': ErreurDictee.autre,
        'ERROR_NO_MATCH': ErreurDictee.rienEntendu,
      };
      attendus.forEach((code, erreur) {
        expect(MoteurSpeechToText.traduireErreur(code), erreur, reason: code);
      });
    });
  });
}
