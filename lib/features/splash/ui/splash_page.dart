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

/// Écran d'ouverture.
///
/// Le sigle **PGDE** arrive par la droite et vient se poser à côté du logo,
/// les deux finissant alignés sur une seule ligne. Le nom complet du ministère
/// descend en pied de page : long de quatorze mots, il écrasait la marque
/// quand il tenait la place du titre.
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with SingleTickerProviderStateMixin {
  /// Écart entre le logo et le sigle, une fois assemblés.
  static const double _ecart = Espace.md;

  late final AnimationController _controleur = AnimationController(
    vsync: this,
    duration: Duree.splash,
  )..forward();

  /// Le logo se pose en premier, seul et centré.
  late final Animation<double> _logo = _intervalle(0, 0.42, Curves.easeOutBack);

  /// Puis le sigle entre par la droite, et le logo lui fait place.
  late final Animation<double> _assemblage = _intervalle(0.34, 0.82);

  /// Le pied de page arrive une fois la marque en place.
  late final Animation<double> _pied = _intervalle(0.68, 1);

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

  /// Largeur que prendra le sigle une fois posé.
  ///
  /// Elle sert à savoir de combien décaler le logo : au départ il est centré
  /// seul, à l'arrivée il a cédé la moitié de l'ensemble au sigle.
  double _largeurDuSigle(TextStyle style) => (TextPainter(
    text: TextSpan(text: 'PGDE', style: style),
    textDirection: TextDirection.ltr,
    textScaler: MediaQuery.textScalerOf(context),
  )..layout()).width;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authControllerProvider);
    final theme = Theme.of(context);

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
      telephone: 84,
      tablette: 108,
      large: 120,
    );
    final TextStyle styleSigle = TextStyle(
      fontSize: context.selonFormat<double>(
        telephone: 46,
        tablette: 58,
        large: 64,
      ),
      fontWeight: FontWeight.w700,
      letterSpacing: -1.5,
      height: 1,
      color: theme.colorScheme.onSurface,
    );

    final double largeurSigle = _largeurDuSigle(styleSigle);
    // Position de départ du logo : centré seul. Il glisse ensuite vers la
    // gauche de la moitié de ce que le sigle et son écart occuperont.
    final double decalageLogo = (largeurSigle + _ecart) / 2;
    // D'où vient le sigle : hors du cadre, à droite.
    final double entreeSigle = MediaQuery.sizeOf(context).width * 0.55;

    return Scaffold(
      body: Stack(
        children: <Widget>[
          Center(
            child: AnimatedBuilder(
              animation: _controleur,
              builder: (context, _) {
                final double t = _assemblage.value;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Transform.translate(
                      offset: Offset(decalageLogo * (1 - t), 0),
                      child: Transform.scale(
                        scale: _logo.value,
                        child: Opacity(
                          opacity: _logo.value.clamp(0, 1),
                          child: Image.asset(
                            'assets/logo_fp.png',
                            width: tailleLogo,
                            height: tailleLogo,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: _ecart),
                    Transform.translate(
                      offset: Offset(entreeSigle * (1 - t), 0),
                      child: Opacity(
                        opacity: t.clamp(0, 1),
                        child: Text('PGDE', style: styleSigle),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: Espace.xl),
                child: ConteneurPage(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      AnimatedBuilder(
                        animation: _barre,
                        builder: (_, _) =>
                            _BarreProgression(progression: _barre.value),
                      ),
                      const SizedBox(height: Espace.lg),
                      FadeTransition(
                        opacity: _pied,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.6),
                            end: Offset.zero,
                          ).animate(_pied),
                          child: Text(
                            'Plateforme de Gestion des Demandes d’emploi',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              letterSpacing: 0.4,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: Espace.xxs),
                      FadeTransition(
                        opacity: _pied,
                        child: Text(
                          'Ministère de la Fonction publique, du travail '
                          'et de la réforme du service public',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            height: 1.35,
                            // Très discret : c'est une mention d'autorité, pas
                            // un titre.
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    ],
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
