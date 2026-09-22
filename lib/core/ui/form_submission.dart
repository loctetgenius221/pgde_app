import 'package:flutter/material.dart';

import '../network/api_exception.dart';
import '../theme/app_dimens.dart';
import 'icone.dart';

/// État partagé par tout formulaire qui appelle l'API : envoi en cours,
/// message d'erreur global, erreurs par champ issues d'un 422 (§7.1).
///
/// Les messages de validation métier sont déjà traduits en français côté
/// serveur : ils sont affichés tels quels (§3.2).
mixin FormSubmission<T extends StatefulWidget> on State<T> {
  bool _envoiEnCours = false;
  ApiException? _erreur;

  bool get envoiEnCours => _envoiEnCours;
  ApiException? get erreur => _erreur;

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
    if (_envoiEnCours) return false;
    setState(() {
      _envoiEnCours = true;
      _erreur = null;
    });
    try {
      await action();
      return true;
    } on ApiException catch (e) {
      if (mounted) setState(() => _erreur = e);
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
