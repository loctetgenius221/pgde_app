import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../dictee/dictee.dart';
import '../dictee/moteur_speech_to_text.dart';
import '../theme/app_dimens.dart';
import 'icone.dart';

/// Bouton micro à poser en fin de champ texte.
///
/// Un appui démarre la dictée, un second l'arrête. Le texte reconnu
/// s'affiche dans le champ **au fil de la parole**, à la suite de ce qui était
/// déjà écrit, et reste modifiable au clavier. Le bouton ne connaît pas le
/// champ : il lit son contenu par [texteActuel] et le remplace par [onTexte].
class BoutonDictee extends ConsumerStatefulWidget {
  const BoutonDictee({
    required this.texteActuel,
    required this.onTexte,
    this.longueurMax,
    super.key,
  });

  /// Contenu du champ au moment où la dictée commence.
  final String Function() texteActuel;

  /// Nouveau contenu du champ, à chaque mot reconnu.
  final ValueChanged<String> onTexte;

  /// Limite du champ, que la dictée ne doit pas dépasser.
  final int? longueurMax;

  @override
  ConsumerState<BoutonDictee> createState() => _BoutonDicteeState();
}

class _BoutonDicteeState extends ConsumerState<BoutonDictee> {
  bool _ecoute = false;
  bool _preparation = false;

  /// Contenu du champ avant la dictée : chaque transcription partielle s'y
  /// ajoute, au lieu de s'empiler sur la précédente.
  String _base = '';

  MoteurDictee? _moteur;

  Future<void> _basculer() async {
    final MoteurDictee moteur = ref.read(moteurDicteeProvider);
    if (_ecoute) {
      // La fin de session (`surFin`) remettra le bouton au repos.
      await moteur.arreter();
      return;
    }

    setState(() => _preparation = true);
    final ErreurDictee? echec = await moteur.preparer();
    if (!mounted) return;
    setState(() => _preparation = false);
    if (echec != null) {
      _annoncer(echec);
      return;
    }

    _moteur = moteur;
    _base = widget.texteActuel();
    setState(() => _ecoute = true);
    await moteur.ecouter(
      surTexte: (texte, {required definitif}) {
        if (!mounted) return;
        widget.onTexte(
          fusionnerDictee(_base, texte, longueurMax: widget.longueurMax),
        );
      },
      surFin: () {
        if (mounted) setState(() => _ecoute = false);
      },
      surErreur: _annoncer,
    );
  }

  void _annoncer(ErreurDictee erreur) {
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(erreur.message)));
  }

  @override
  void dispose() {
    // Quitter l'écran en pleine dictée ne doit pas laisser le micro ouvert.
    if (_ecoute) _moteur?.arreter();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final String libelle = _ecoute ? 'Arrêter la dictée' : 'Dicter le texte';

    return Padding(
      padding: const EdgeInsets.only(right: Espace.xxs),
      child: IconButton(
        tooltip: libelle,
        onPressed: _preparation ? null : _basculer,
        // Pendant l'écoute, une pastille verte pleine : l'état se voit d'un
        // coup d'œil, sans dépendre d'une animation (réglage « réduire les
        // animations » respecté d'office).
        style: IconButton.styleFrom(
          backgroundColor: _ecoute ? scheme.primary : Colors.transparent,
        ),
        icon: Icone(
          _ecoute ? Icones.arreter : Icones.micro,
          taille: 20,
          couleur: _ecoute ? scheme.onPrimary : scheme.primary,
        ),
      ),
    );
  }
}
