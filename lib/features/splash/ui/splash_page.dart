import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/ui/async_view.dart';
import '../../../core/ui/responsive.dart';
import '../../auth/application/auth_controller.dart';

/// Vrai une fois l'animation d'ouverture jouée.
///
/// Le routeur attend **deux** conditions avant de quitter le splash : la
/// session restaurée *et* l'animation terminée. Sans la seconde, une session
/// restaurée en 40 ms ferait clignoter l'écran d'accueil.
class SplashController extends Notifier<bool> {
  @override
  bool build() => false;

  void terminer() => state = true;
}

final splashTermineProvider = NotifierProvider<SplashController, bool>(
  SplashController.new,
);

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controleur = AnimationController(
    vsync: this,
    duration: Duree.splash,
  )..forward();

  late final Animation<double> _logo = _intervalle(0, 0.45, Curves.easeOutBack);
  late final Animation<double> _titre = _intervalle(0.32, 0.70);
  late final Animation<double> _sousTitre = _intervalle(0.48, 0.85);
  late final Animation<double> _barre = _intervalle(0.15, 1, Curves.easeInOut);

  Animation<double> _intervalle(
    double debut,
    double fin, [
    Curve courbe = Curves.easeOutCubic,
  ]) => CurvedAnimation(
    parent: _controleur,
    curve: Interval(debut, fin, curve: courbe),
  );

  @override
  void initState() {
    super.initState();
    _controleur.addStatusListener((statut) {
      if (statut == AnimationStatus.completed && mounted) {
        ref.read(splashTermineProvider.notifier).terminer();
      }
    });
  }

  @override
  void dispose() {
    _controleur.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authControllerProvider);
    final texte = Theme.of(context).textTheme;

    // La session n'a pas pu être déterminée (serveur injoignable) : on sort de
    // l'animation pour proposer une reprise plutôt que de tourner dans le vide.
    if (session.hasError) {
      return Scaffold(
        body: AsyncView<Object?>(
          value: session,
          onRetry: () => ref.invalidate(authControllerProvider),
          builder: (_) => const SizedBox.shrink(),
        ),
      );
    }

    final double tailleLogo = context.selonFormat<double>(
      telephone: 116,
      tablette: 160,
      large: 180,
    );

    // Le nom complet de la plateforme tient sur trois lignes de téléphone à
    // cette taille ; en `headlineMedium`, il en prendrait quatre et chasserait
    // le sous-titre hors de l'écran.
    final TextStyle? styleTitre = context.selonFormat<TextStyle?>(
      telephone: texte.headlineSmall,
      tablette: texte.headlineMedium,
    );

    return Scaffold(
      body: Stack(
        children: <Widget>[
          Center(
            // Défilable par sécurité : aux plus grandes tailles de police
            // d'accessibilité, le bloc dépasse la hauteur d'un petit écran.
            child: SingleChildScrollView(
              child: ConteneurPage(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    ScaleTransition(
                      scale: _logo,
                      child: FadeTransition(
                        opacity: _logo,
                        child: Image.asset(
                          'assets/logo_fp.png',
                          width: tailleLogo,
                          height: tailleLogo,
                        ),
                      ),
                    ),
                    const SizedBox(height: Espace.xl),
                    _Apparition(
                      animation: _titre,
                      child: Text(
                        "Plateforme de Gestion des Demandes d'emploi",
                        textAlign: TextAlign.center,
                        style: styleTitre,
                      ),
                    ),
                    const SizedBox(height: Espace.xs),
                    _Apparition(
                      animation: _sousTitre,
                      child: Text(
                        'Ministère de la Fonction publique, du travail '
                        'et de la réforme du service public',
                        textAlign: TextAlign.center,
                        style: texte.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Barre de progression verte qui se remplit pendant le chargement :
          // elle occupe l'attente sans surcharger l'écran.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: Espace.xxl),
                child: Center(
                  child: AnimatedBuilder(
                    animation: _barre,
                    builder: (_, _) =>
                        _BarreProgression(progression: _barre.value),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Fondu + remontée : l'apparition standard de l'écran d'ouverture.
class _Apparition extends StatelessWidget {
  const _Apparition({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: animation,
    child: SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.35),
        end: Offset.zero,
      ).animate(animation),
      child: child,
    ),
  );
}

class _BarreProgression extends StatelessWidget {
  const _BarreProgression({required this.progression});

  final double progression;

  static const double _largeur = 120;
  static const double _epaisseur = 4;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: _largeur,
    height: _epaisseur,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(_epaisseur),
      child: Container(
        color: Theme.of(context).colorScheme.outlineVariant,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: _largeur * progression.clamp(0, 1),
            color: AppColors.vert,
          ),
        ),
      ),
    ),
  );
}
