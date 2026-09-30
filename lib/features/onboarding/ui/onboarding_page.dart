import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_dimens.dart';
import '../../../core/ui/illustrations.dart';
import '../../../core/ui/responsive.dart';
import '../application/onboarding_controller.dart';

/// Les trois écrans d'accueil.
///
/// Chacun désamorce une cause réelle d'abandon, relevée dans le cadrage — ce
/// n'est pas du remplissage :
/// 1. le modèle mental « une seule demande, modifiable » (§2.1, contrainte
///    UNIQUE) : sans quoi le candidat cherche un bouton « nouvelle demande » ;
/// 2. les pièces à préparer (§4, étape 2) : formats et poids sont **refusés
///    par le serveur**, et c'est le premier mur rencontré ;
/// 3. la longueur du formulaire et la sauvegarde du brouillon (§8.8) : trente
///    champs sur un réseau instable, il faut rassurer avant de commencer.
enum _Etape {
  service(
    titre: 'Une demande, un dossier',
    texte:
        'Vous ne remplissez qu’une seule demande. '
        'Elle reste modifiable à tout moment.',
  ),
  pieces(
    titre: 'Préparez vos pièces',
    texte:
        'Pièce d’identité, photo et diplômes en PDF, 2 Mo maximum. '
        'Votre CV sera établi à partir de votre dossier.',
  ),
  etapes(
    titre: 'Quatre étapes, à votre rythme',
    texte:
        'Identité, formations, expériences, vœux. '
        'Votre saisie est conservée, même hors connexion.',
  );

  const _Etape({required this.titre, required this.texte});

  final String titre;
  final String texte;

  Widget illustration({required double taille, required bool actif}) =>
      switch (this) {
        _Etape.service => Illustration.dossierUnique(
          taille: taille,
          actif: actif,
        ),
        _Etape.pieces => Illustration.pieces(taille: taille, actif: actif),
        _Etape.etapes => Illustration.etapes(taille: taille, actif: actif),
      };
}

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final PageController _pages = PageController();
  int _index = 0;

  static const List<_Etape> _etapes = _Etape.values;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  bool get _derniere => _index == _etapes.length - 1;

  void _suivant() {
    if (_derniere) {
      // Le routeur bascule seul vers la connexion dès que le drapeau change.
      unawaited(ref.read(onboardingVuProvider.notifier).marquerCommeVu());
      return;
    }
    _pages.nextPage(duration: Duree.moyenne, curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    final double tailleIllustration = context.selonFormat<double>(
      telephone: 230,
      tablette: 300,
      large: 340,
    );

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // « Passer » reste accessible sur tous les écrans : imposer trois
            // pages à quelqu'un qui revient installer l'app serait hostile.
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: context.margeLaterale - Espace.sm,
                  vertical: Espace.xs,
                ),
                child: TextButton(
                  onPressed: () =>
                      ref.read(onboardingVuProvider.notifier).marquerCommeVu(),
                  child: const Text('Passer'),
                ),
              ),
            ),

            Expanded(
              child: PageView.builder(
                controller: _pages,
                itemCount: _etapes.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) => _Diapositive(
                  etape: _etapes[i],
                  tailleIllustration: tailleIllustration,
                  // L'animation de l'illustration se rejoue à chaque fois que
                  // la diapositive revient à l'écran.
                  actif: i == _index,
                ),
              ),
            ),

            ConteneurPage(
              child: Padding(
                padding: const EdgeInsets.only(
                  top: Espace.lg,
                  bottom: Espace.lg,
                ),
                child: Column(
                  children: <Widget>[
                    _Pastilles(total: _etapes.length, actif: _index),
                    const SizedBox(height: Espace.lg),
                    FilledButton(
                      onPressed: _suivant,
                      child: Text(_derniere ? 'Commencer' : 'Continuer'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Diapositive extends StatelessWidget {
  const _Diapositive({
    required this.etape,
    required this.tailleIllustration,
    required this.actif,
  });

  final _Etape etape;
  final double tailleIllustration;
  final bool actif;

  @override
  Widget build(BuildContext context) {
    final texte = Theme.of(context).textTheme;

    return Center(
      child: ConteneurPage(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const SizedBox(height: Espace.lg),
              etape.illustration(taille: tailleIllustration, actif: actif),
              const SizedBox(height: Espace.xxl),
              Text(
                etape.titre,
                textAlign: TextAlign.center,
                style: texte.headlineMedium,
              ),
              const SizedBox(height: Espace.sm),
              Text(
                etape.texte,
                textAlign: TextAlign.center,
                style: texte.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Indicateur de page : la pastille active s'étire en barre.
class _Pastilles extends StatelessWidget {
  const _Pastilles({required this.total, required this.actif});

  final int total;
  final int actif;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        for (int i = 0; i < total; i++)
          AnimatedContainer(
            duration: Duree.moyenne,
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: Espace.xxs),
            height: 8,
            width: i == actif ? 26 : 8,
            decoration: BoxDecoration(
              color: i == actif ? scheme.primary : scheme.outlineVariant,
              borderRadius: BorderRadius.circular(Rayon.pilule),
            ),
          ),
      ],
    );
  }
}
