import 'dart:async';

import 'package:flutter/material.dart';

import '../network/api_exception.dart';
import '../theme/app_dimens.dart';
import 'icone.dart';

/// État partagé par tout formulaire qui appelle l'API : envoi en cours,
/// message d'erreur global, erreurs par champ issues d'un 422 (§7.1).
///
/// Les messages de validation métier sont déjà traduits en français côté
/// serveur : ils sont affichés tels quels (§3.2).
///
/// **Limitation de débit.** Quand le serveur répond `429` (trop de tentatives
/// de connexion, d'inscription…), le formulaire se bloque pendant le délai
/// `Retry-After` et affiche un compte à rebours. Réessayer plus tôt serait de
/// toute façon refusé, et chaque essai prolongerait souvent le blocage.
mixin FormSubmission<T extends StatefulWidget> on State<T> {
  /// Délai appliqué si le serveur n'envoie pas `Retry-After` : la fenêtre
  /// par défaut du `throttle` de Laravel.
  static const Duration attenteParDefaut = Duration(seconds: 60);

  /// Plafond : un `Retry-After` aberrant ne doit pas figer l'écran.
  static const Duration attenteMax = Duration(minutes: 15);

  bool _envoiEnCours = false;
  ApiException? _erreur;
  int _secondesRestantes = 0;
  Timer? _minuteur;

  bool get envoiEnCours => _envoiEnCours;
  ApiException? get erreur => _erreur;

  /// Secondes restantes avant que le serveur accepte un nouvel essai.
  int get secondesAvantNouvelEssai => _secondesRestantes;

  /// Vrai quand le bouton d'envoi peut être touché.
  bool get envoiPossible => !_envoiEnCours && secondesAvantNouvelEssai == 0;

  /// Contenu du bouton d'envoi : indicateur, compte à rebours ou [libelle].
  Widget contenuBouton(String libelle) {
    if (_envoiEnCours) return const IndicateurBouton();
    final int secondes = secondesAvantNouvelEssai;
    if (secondes > 0) return Text('Réessayez dans ${_duree(secondes)}');
    return Text(libelle);
  }

  static String _duree(int secondes) => secondes < 60
      ? '$secondes s'
      : '${secondes ~/ 60} min ${(secondes % 60).toString().padLeft(2, '0')}';

  void _bloquer(Duration? retryAfter) {
    Duration attente = retryAfter ?? attenteParDefaut;
    if (attente <= Duration.zero) attente = attenteParDefaut;
    if (attente > attenteMax) attente = attenteMax;
    _secondesRestantes = (attente.inMilliseconds / 1000).ceil();
    _minuteur?.cancel();
    _minuteur = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (!mounted) return t.cancel();
      setState(() => _secondesRestantes--);
      if (_secondesRestantes <= 0) t.cancel();
    });
  }

  @override
  void dispose() {
    _minuteur?.cancel();
    super.dispose();
  }

  /// À passer à `InputDecoration.errorText`.
  String? erreurDuChamp(String champ) => _erreur?.errorFor(champ);

  /// Message global : masqué lorsque l'erreur est déjà rendue champ par champ.
  String? get erreurGlobale {
    final e = _erreur;
    if (e == null || e.fieldErrors.isNotEmpty) return null;
    return e.message;
  }

  /// Exécute [action] en tenant l'état d'envoi. Rend `true` en cas de succès.
  Future<bool> soumettre(Future<void> Function() action) async {
    if (!envoiPossible) return false;
    setState(() {
      _envoiEnCours = true;
      _erreur = null;
    });
    try {
      await action();
      return true;
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _erreur = e;
          if (e.statusCode == 429) _bloquer(e.retryAfter);
        });
      }
      return false;
    } finally {
      if (mounted) setState(() => _envoiEnCours = false);
    }
  }
}

/// Bandeau d'erreur non rattachée à un champ.
///
/// Le rouge de la marque ne sert qu'ici et sur les champs en erreur : c'est ce
/// qui lui conserve sa valeur d'alerte.
class BandeauErreur extends StatelessWidget {
  const BandeauErreur(this.message, {super.key});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final texte = message;
    final scheme = Theme.of(context).colorScheme;

    return AnimatedSize(
      duration: Duree.rapide,
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: texte == null
          ? const SizedBox(width: double.infinity)
          : Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: Espace.md),
              padding: const EdgeInsets.all(Espace.sm + 2),
              decoration: BoxDecoration(
                color: scheme.errorContainer,
                borderRadius: BorderRadius.circular(Rayon.md),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icone(
                    Icones.alerte,
                    taille: 20,
                    couleur: scheme.onErrorContainer,
                  ),
                  const SizedBox(width: Espace.xs),
                  Expanded(
                    child: Text(
                      texte,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

/// Indicateur de chargement dimensionné pour tenir dans un bouton sans en
/// changer la hauteur.
class IndicateurBouton extends StatelessWidget {
  const IndicateurBouton({super.key});

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 22,
    child: CircularProgressIndicator(
      strokeWidth: 2.4,
      color: Theme.of(context).colorScheme.onPrimary,
    ),
  );
}
