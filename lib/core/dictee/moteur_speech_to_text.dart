import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'dictee.dart';

/// Moteur de dictée de l'application.
///
/// Surchargé dans les tests par un faux moteur.
final moteurDicteeProvider = Provider<MoteurDictee>(
  (ref) => MoteurSpeechToText(),
);

/// [MoteurDictee] adossé au paquet `speech_to_text`, donc à la
/// reconnaissance vocale du système : `SpeechRecognizer` sur Android, le
/// framework Speech sur iOS. Aucun modèle n'est embarqué dans l'app.
///
/// Seule classe de l'application à connaître ce paquet.
class MoteurSpeechToText implements MoteurDictee {
  /// [reconnaissance] n'est fourni que par les tests : `SpeechToText()` est
  /// un singleton partagé par toute l'application.
  MoteurSpeechToText([SpeechToText? reconnaissance])
    : _stt = reconnaissance ?? SpeechToText();

  final SpeechToText _stt;

  /// Une session dure au plus une minute — la limite de la reconnaissance
  /// par serveur sur iOS. Un candidat dicte de toute façon phrase par phrase.
  static const Duration dureeMax = Duration(seconds: 60);

  /// Silence au-delà duquel la phrase est jugée finie. Android impose déjà
  /// sa propre pause, d'une à trois secondes, que rien ne permet d'allonger.
  static const Duration pauseMax = Duration(seconds: 4);

  Future<bool>? _preparation;
  String? _locale;

  // Session en cours. `initialize` n'enregistre ses écouteurs qu'une fois
  // par vie de l'application : ils aiguillent donc vers la session courante.
  SurTexteDicte? _surTexte;
  VoidCallback? _surFin;
  ValueChanged<ErreurDictee>? _surErreur;

  /// La session a-t-elle entendu des mots ? Sinon, sa fin le dit au
  /// candidat : Android annonce la fin **avant** son erreur « pas de
  /// parole », que l'adaptateur, déjà refermé, ne verrait jamais.
  bool _entendu = false;

  @override
  Future<ErreurDictee?> preparer() async {
    if (await (_preparation ??= _initialiser())) return null;
    // Un échec n'est pas définitif : le candidat peut accorder le micro dans
    // les réglages, puis réessayer.
    _preparation = null;
    return await _stt.hasPermission
        ? ErreurDictee.indisponible
        : ErreurDictee.permissionRefusee;
  }

  Future<bool> _initialiser() async {
    final bool ok = await _stt.initialize(
      onStatus: _surStatut,
      onError: _surErreurPlateforme,
    );
    if (ok) _locale = await _localeFrancaise();
    return ok;
  }

  /// Le français du Sénégal s'il existe, sinon celui de France, sinon une
  /// variante française quelconque. Sans français, la langue du système.
  Future<String?> _localeFrancaise() async {
    final List<String> ids = (await _stt.locales())
        .map((l) => l.localeId)
        .toList();
    String? chercher(bool Function(String id) critere) {
      for (final String id in ids) {
        if (critere(id.replaceAll('-', '_').toLowerCase())) return id;
      }
      return null;
    }

    return chercher((id) => id == 'fr_sn') ??
        chercher((id) => id == 'fr_fr') ??
        chercher((id) => id.startsWith('fr'));
  }

  @override
  Future<void> ecouter({
    required SurTexteDicte surTexte,
    required VoidCallback surFin,
    required ValueChanged<ErreurDictee> surErreur,
  }) async {
    final ErreurDictee? echec = await preparer();
    if (echec != null) {
      surErreur(echec);
      surFin();
      return;
    }
    _surTexte = surTexte;
    _surFin = surFin;
    _surErreur = surErreur;
    _entendu = false;
    try {
      await _stt.listen(
        onResult: _surResultat,
        listenOptions: SpeechListenOptions(
          listenMode: ListenMode.dictation,
          partialResults: true,
          // Une erreur définitive coupe proprement la session.
          cancelOnError: true,
          // iOS uniquement : la ponctuation automatique.
          autoPunctuation: true,
          pauseFor: pauseMax,
          listenFor: dureeMax,
          localeId: _locale,
        ),
      );
    } on Exception {
      _surErreurPlateforme(SpeechRecognitionError('error_listen_failed', true));
    }
  }

  @override
  Future<void> arreter() => _stt.stop();

  void _surResultat(SpeechRecognitionResult resultat) {
    if (resultat.recognizedWords.trim().isNotEmpty) _entendu = true;
    _surTexte?.call(resultat.recognizedWords, definitif: resultat.finalResult);
  }

  void _surStatut(String statut) {
    // `done` n'arrive qu'après le texte définitif, ou quand l'écoute se
    // termine sans rien avoir entendu : c'est la vraie fin de session.
    if (statut != SpeechToText.doneStatus) return;
    if (!_entendu) _surErreur?.call(ErreurDictee.rienEntendu);
    _terminer();
  }

  void _surErreurPlateforme(SpeechRecognitionError erreur) {
    _surErreur?.call(traduireErreur(erreur.errorMsg));
    _terminer();
  }

  /// Ne prévient qu'une fois, même si statut et erreur arrivent tous deux.
  void _terminer() {
    final VoidCallback? fin = _surFin;
    _surTexte = null;
    _surFin = null;
    _surErreur = null;
    fin?.call();
  }

  /// Codes d'erreur des plateformes (Android `SpeechRecognizer`, iOS
  /// `SFSpeechRecognizer`) ramenés à ce que le candidat peut faire.
  @visibleForTesting
  static ErreurDictee traduireErreur(String code) {
    final String c = code.toLowerCase();
    if (c.contains('permission')) return ErreurDictee.permissionRefusee;
    if (c.contains('no_match') || c.contains('speech_timeout')) {
      return ErreurDictee.rienEntendu;
    }
    if (c.contains('network') || c.contains('server')) {
      return ErreurDictee.reseau;
    }
    if (c.contains('language')) return ErreurDictee.indisponible;
    return ErreurDictee.autre;
  }
}
