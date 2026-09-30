import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show Ticker;
import 'package:flutter/services.dart' show ByteData, rootBundle;

// --- Matières --------------------------------------------------------------
//
// **Deux matières, pas une.** C'est le point qui sépare un objet d'une
// illustration : une coque laquée très claire, et des pièces de structure en
// graphite mat. Tout peindre dans le même blanc donnait une forme molle, sans
// fabrication lisible.

const Color _coqueVive = Color(0xFFFFFFFF);
const Color _coqueClaire = Color(0xFFF1F4F9);
const Color _coque = Color(0xFFD8E0EA);
const Color _coqueOmbre = Color(0xFFAEBAC9);
const Color _coqueOmbreProfonde = Color(0xFF8593A5);

/// Seconde matière : les pièces de structure — oreilles, col, articulations.
const Color _graphiteClair = Color(0xFF59626F);
const Color _graphite = Color(0xFF343B45);
const Color _graphiteSombre = Color(0xFF1C2128);

const Color _visiereHaut = Color(0xFF34373F);
const Color _visiere = Color(0xFF13201A);
const Color _visiereBas = Color(0xFF041008);

/// Vert de la marque — celui du logo et des boutons.
const Color _vert = Color(0xFF009454);

/// Cœur du trait lumineux.
///
/// Un vert émissif ne se peint pas d'une seule couleur : une diode a un cœur
/// presque blanc entouré d'un halo coloré. Le halo porte le vert de la
/// marque, le cœur l'éclaircit — sans quoi le #009454 sur une visière quasi
/// noire resterait sourd et illisible.
const Color _vertEmissif = Color(0xFF7DFFC4);

/// Jaune du drapeau, en lumière d'appoint seulement — jamais en aplat.
const Color _jaune = Color(0xFFFFCC34);

const Color _ombrePortee = Color(0xFF0B1220);

/// Ce que le personnage montre. Trois poses, pas davantage.
enum PoseNdimbal {
  /// Bouche droite : la machine est en veille, disponible.
  neutre,

  /// Il sourit.
  sourire,

  /// Il sourit et fait signe de la main.
  salut,
}

/// Échelle de représentation.
enum FormeNdimbal {
  /// Le visage seul, pour les vignettes de conversation.
  pastille,

  /// Le personnage entier.
  complet,
}

// --- Logo ------------------------------------------------------------------

/// Le logo du ministère, décodé une fois pour toute l'application.
///
/// Chaque personnage à l'écran partage la même texture : en charger une par
/// instance ferait décoder le PNG autant de fois qu'il y a d'avatars.
ui.Image? _logoMinistere;
Future<ui.Image>? _chargementDuLogo;

Future<ui.Image> _chargerLogo() {
  final Future<ui.Image>? enCours = _chargementDuLogo;
  if (enCours != null) return enCours;

  final Future<ui.Image> futur = () async {
    final ByteData octets = await rootBundle.load('assets/logo_fp.png');
    // Redimensionné au décodage : l'écusson ne dépasse jamais quelques
    // dizaines de pixels, garder la pleine résolution ne servirait à rien.
    final ui.Codec codec = await ui.instantiateImageCodec(
      octets.buffer.asUint8List(),
      targetWidth: 192,
    );
    final ui.FrameInfo image = await codec.getNextFrame();
    return _logoMinistere = image.image;
  }();
  return _chargementDuLogo = futur;
}

/// Ndimbal — l'assistant de la plateforme.
///
/// Peint à la main. Le volume vient de l'éclairage : dégradés orientés,
/// reflet spéculaire dur, lumière rasante sur l'arête opposée, occlusion aux
/// jonctions, ombre et reflet au sol.
///
/// **Deux matières** — coque laquée et pièces de structure en graphite — et
/// un **écusson gravé** portant le logo du ministère. C'est ce qui fait la
/// différence entre une mascotte et un objet de service : une mascotte est
/// d'une seule pièce, un objet se voit fabriqué.
///
/// **Ce qui le rend vivant, c'est le mouvement.** Compression et étirement
/// sur la respiration, retard d'un segment sur le précédent — la tête suit le
/// corps, les bras suivent la tête —, anticipation avant le salut, périodes
/// incommensurables, et surtout des **temps d'arrêt** : le personnage
/// s'immobilise vraiment, par intervalles. Une boucle qui ne s'arrête jamais
/// se lit comme un mécanisme ; c'est l'arrêt qui rend le mouvement
/// intentionnel.
class Ndimbal extends StatefulWidget {
  const Ndimbal({
    required this.taille,
    this.forme = FormeNdimbal.complet,
    this.pose = PoseNdimbal.neutre,
    this.anime = true,
    super.key,
  });

  /// Hauteur occupée. La largeur en découle.
  final double taille;

  final FormeNdimbal forme;
  final PoseNdimbal pose;

  /// Faux pour une vignette décorative : pas d'horloge, pas de repeinture.
  final bool anime;

  static double largeurPour(FormeNdimbal forme) =>
      forme == FormeNdimbal.pastille ? 1 : 1.02;

  @override
  State<Ndimbal> createState() => _NdimbalState();
}

class _NdimbalState extends State<Ndimbal> with TickerProviderStateMixin {
  /// Temps écoulé depuis le premier affichage, en secondes.
  ///
  /// **Strictement croissant, sans boucle.** Un `AnimationController` qui se
  /// répète ramène son temps à zéro à chaque tour : toutes les ondes
  /// sautaient alors d'un coup, jusqu'à 0,99 d'amplitude sur les diodes, une
  /// fois toutes les huit secondes. Une sinusoïde n'est continue au raccord
  /// que si la durée de boucle est un multiple exact de sa période — ce
  /// qu'on ne peut pas obtenir avec sept périodes volontairement
  /// incommensurables entre elles. Le temps ne reboucle donc jamais.
  final ValueNotifier<double> _secondes = ValueNotifier<double>(0);

  /// `Ticker.elapsed` exclut les périodes où l'application est en arrière-plan
  /// : au retour, le mouvement reprend là où il s'était arrêté, sans saut.
  late final Ticker _horloge = createTicker((Duration ecoule) {
    _secondes.value = ecoule.inMicroseconds / 1000000;
  });

  /// Le salut est une **action** — début, milieu, fin. Il se joue une fois.
  late final AnimationController _salut = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );

  /// Passage de la bouche droite au sourire, et retour.
  late final AnimationController _sourire;

  @override
  void initState() {
    super.initState();
    _sourire = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      value: widget.pose == PoseNdimbal.neutre ? 0 : 1,
    );
    if (widget.anime) {
      _horloge.start();
      if (widget.pose == PoseNdimbal.salut) _salut.forward();
    }
    if (widget.forme == FormeNdimbal.complet && _logoMinistere == null) {
      _chargerLogo().then((_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void didUpdateWidget(Ndimbal ancien) {
    super.didUpdateWidget(ancien);
    if (widget.pose == ancien.pose) return;

    widget.pose == PoseNdimbal.neutre ? _sourire.reverse() : _sourire.forward();

    if (widget.anime && widget.pose == PoseNdimbal.salut) {
      _salut.forward(from: 0);
    } else if (ancien.pose == PoseNdimbal.salut) {
      _salut.reverse();
    }
  }

  @override
  void dispose() {
    _horloge.dispose();
    _secondes.dispose();
    _salut.dispose();
    _sourire.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Réglage système « réduire les animations » : le personnage se fige dans
    // une pose lisible plutôt que de s'imposer à qui a demandé le contraire.
    final bool anime = widget.anime && !MediaQuery.disableAnimationsOf(context);
    if (!anime && _horloge.isActive) {
      _horloge.stop();
    } else if (anime && !_horloge.isActive) {
      _horloge.start();
    }

    return RepaintBoundary(
      child: SizedBox(
        height: widget.taille,
        width: widget.taille * Ndimbal.largeurPour(widget.forme),
        child: AnimatedBuilder(
          animation: Listenable.merge(<Listenable>[
            _secondes,
            _salut,
            _sourire,
          ]),
          builder: (context, _) => CustomPaint(
            painter: _PeintreNdimbal(
              secondes: anime ? _secondes.value : 1.6,
              salut: anime ? _salut.value : 0,
              sourire: _sourire.value,
              forme: widget.forme,
              anime: anime,
              logo: _logoMinistere,
            ),
          ),
        ),
      ),
    );
  }
}

class _PeintreNdimbal extends CustomPainter {
  _PeintreNdimbal({
    required this.secondes,
    required this.salut,
    required this.sourire,
    required this.forme,
    required this.anime,
    required this.logo,
  });

  /// Temps de la boucle, en secondes. Travailler en secondes plutôt qu'en
  /// fraction permet d'écrire les périodes telles qu'on les pense.
  final double secondes;

  /// Avancement du salut, de 0 à 1.
  final double salut;

  /// 0 = bouche droite, 1 = sourire.
  final double sourire;

  final FormeNdimbal forme;
  final bool anime;

  /// Le logo du ministère, une fois décodé. Nul tant qu'il ne l'est pas :
  /// l'écusson s'affiche alors vide plutôt que de retarder le premier rendu.
  final ui.Image? logo;

  late double _h;
  late double _cx;

  /// Oscillation de période [periode] secondes, décalée de [phase] tours.
  double _onde(double periode, [double phase = 0]) =>
      math.sin((secondes / periode + phase) * math.pi * 2);

  /// Oscillation **tenue** aux extrêmes.
  ///
  /// Une sinusoïde passe l'essentiel de son temps au milieu de sa course :
  /// le mouvement paraît alors flotter. En redressant la courbe, on fait
  /// séjourner la valeur près de ses bornes — le geste marque ses positions,
  /// comme en animation traditionnelle.
  double _tenue(double periode, [double phase = 0]) {
    final double x = _onde(periode, phase);
    return x.sign * math.pow(x.abs(), 0.62).toDouble();
  }

  /// Coefficient d'activité — il tombe presque à zéro par intervalles.
  ///
  /// C'est le vrai temps d'arrêt : le personnage cesse de bouger pendant une
  /// seconde et demie, puis reprend. Une boucle continue se lit comme un
  /// mécanisme ; l'immobilité tenue rend le mouvement suivant intentionnel.
  double get _activite {
    if (!anime) return 0;
    const double cycle = 9.4;
    const double pause = 1.6;
    final double phase = secondes % cycle;
    if (phase < cycle - pause) return 1;
    final double p = (phase - (cycle - pause)) / pause;
    return 0.12 + 0.88 * (1 - math.sin(p * math.pi));
  }

  /// Demi-tour de tête simulé, de −1 (à gauche) à +1 (à droite).
  double get _rotation => _tenue(3.7) * 0.55;

  @override
  void paint(Canvas canvas, Size size) {
    _h = size.height;
    _cx = size.width / 2;

    if (forme == FormeNdimbal.pastille) {
      _pastille(canvas, size);
      return;
    }

    final double vif = _activite;
    final double respiration = _onde(1.3) * vif;
    final double flottement = _tenue(1.9, 0.2) * vif;
    final double balancement = _tenue(2.6, 0.6) * vif;
    final double elan = math.sin(salut * math.pi);

    canvas.save();
    canvas.translate(
      _cx + balancement * 0.006 * _h,
      flottement * 0.010 * _h - elan * 0.012 * _h,
    );
    canvas.rotate(balancement * 0.010 - elan * 0.024);

    // Compression et étirement : le volume se conserve. Sans la compensation
    // horizontale, la respiration se lit comme un simple zoom.
    final double etirement = 1 + respiration * 0.012;
    canvas.scale(1 / etirement, etirement);
    canvas.translate(-_cx, 0);

    _ancrageAuSol(canvas, elan, flottement);
    // Les bras derrière le corps : seule la part qui dépasse se voit, comme
    // un membre qui sort d'une silhouette.
    _bras(canvas, gauche: true, vif: vif);
    _bras(canvas, gauche: false, vif: vif);
    _corps(canvas, respiration);
    _rotules(canvas);
    _col(canvas);
    _tete(canvas, balancement, vif);

    canvas.restore();
  }

  // ---------------------------------------------------------------------
  // Tête
  // ---------------------------------------------------------------------

  void _tete(Canvas canvas, double balancement, double vif) {
    // Retard du mouvement : la tête suit le corps. C'est ce décalage, et lui
    // seul, qui distingue une créature d'un bloc rigide qui translate.
    final double retard = _tenue(2.6, 0.6 - 0.10) * vif;
    // Micro-action : de loin en loin, la tête s'incline brièvement.
    final double inclinaison = _ponctuel(4.1, 0.9) * 0.040;

    final Offset centre = Offset(_cx, 0.318 * _h);
    final double tour = _rotation;

    canvas.save();
    canvas
      ..translate(centre.dx, centre.dy)
      ..rotate((retard - balancement) * 0.045 + inclinaison)
      ..translate(-centre.dx, -centre.dy);

    _oreille(canvas, centre, gauche: true);
    _oreille(canvas, centre, gauche: false);

    // Le demi-tour écrase la coque horizontalement.
    final double ecrasement = 1 - tour.abs() * 0.055;
    final Rect coque = Rect.fromCenter(
      center: centre.translate(tour * 0.010 * _h, 0),
      width: 0.545 * _h * ecrasement,
      height: 0.520 * _h,
    );
    final RRect coqueArrondie = RRect.fromRectAndRadius(
      coque,
      Radius.circular(0.205 * _h),
    );

    canvas
      // Occlusion sous la coque : sans elle, la tête flotte sans poids.
      ..drawRRect(
        coqueArrondie.shift(Offset(0, 0.013 * _h)),
        Paint()
          ..color = _ombrePortee.withValues(alpha: 0.22)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 0.030 * _h),
      )
      ..drawRRect(
        coqueArrondie,
        Paint()
          ..shader = RadialGradient(
            center: Alignment(-0.55 - tour * 0.25, -0.75),
            radius: 1.25,
            colors: const <Color>[
              _coqueVive,
              _coqueClaire,
              _coque,
              _coqueOmbre,
            ],
            stops: const <double>[0, 0.32, 0.66, 1],
          ).createShader(coque),
      );

    canvas.save();
    canvas.clipRRect(coqueArrondie);
    // Lumière rasante sur l'arête : le contre-jour qui referme le volume.
    canvas.drawRRect(
      coqueArrondie.deflate(0.010 * _h),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.015 * _h
        // Légèrement bleutée : la lumière d'appoint d'une scène réelle vient
        // du ciel, elle n'est jamais d'un blanc pur.
        ..color = const Color(0xFFDCE8F5).withValues(alpha: 0.75)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 0.010 * _h),
    );
    canvas.restore();

    // Rebond chaud sous la mâchoire : une surface claire posée près du sol
    // reçoit toujours un peu de lumière renvoyée. Elle porte ici le jaune du
    // drapeau — présent, jamais nommable.
    canvas.drawOval(
      Rect.fromCenter(
        center: centre.translate(0, 0.212 * _h),
        width: 0.400 * _h,
        height: 0.140 * _h,
      ),
      Paint()
        ..color = _jaune.withValues(alpha: 0.15)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 0.050 * _h),
    );

    _visiereEtVisage(canvas, centre, tour, ecrasement);

    // Reflet spéculaire, par-dessus tout : le point de lumière dure qui fait
    // basculer la surface du côté du plastique laqué.
    canvas.drawOval(
      Rect.fromCenter(
        center: centre.translate((-0.158 + tour * 0.042) * _h, -0.186 * _h),
        width: 0.108 * _h,
        height: 0.060 * _h,
      ),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.75)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 0.015 * _h),
    );

    canvas.restore();
  }

  /// Oreille — pièce de structure en graphite, avec sa diode.
  ///
  /// Fixe : elle ne suit pas le demi-tour de tête. Elle y gagnait en relief
  /// ce qu'elle faisait perdre en calme. La profondeur reste portée par
  /// l'écrasement de la coque et la parallaxe du visage.
  void _oreille(Canvas canvas, Offset centre, {required bool gauche}) {
    final double signe = gauche ? -1 : 1;
    final double largeur = 0.070 * _h;
    final double hauteur = 0.132 * _h;

    final Rect boite = Rect.fromCenter(
      center: centre.translate(signe * 0.280 * _h, 0),
      width: largeur,
      height: hauteur,
    );
    final RRect oreille = RRect.fromRectAndRadius(
      boite,
      Radius.circular(largeur * 0.40),
    );

    canvas
      ..drawRRect(
        oreille.shift(Offset(0, 0.008 * _h)),
        Paint()
          ..color = _ombrePortee.withValues(alpha: 0.22)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 0.018 * _h),
      )
      // Graphite mat : la seconde matière. C'est le contraste avec la coque
      // laquée qui donne au personnage son air d'objet assemblé.
      ..drawRRect(
        oreille,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[_graphiteClair, _graphite, _graphiteSombre],
            stops: <double>[0, 0.5, 1],
          ).createShader(boite),
      );

    // Diode de la marque, en veille — elle respire, elle ne clignote pas.
    final double battement =
        0.55 + 0.45 * (0.5 + 0.5 * _onde(1.1, gauche ? 0 : 0.5));
    final double r = largeur * 0.19;
    canvas
      ..drawCircle(
        boite.center,
        r * 2.4,
        Paint()
          ..color = _vert.withValues(alpha: 0.30 * battement)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 1.1),
      )
      ..drawCircle(
        boite.center,
        r,
        Paint()..color = Color.lerp(_vert, _vertEmissif, battement * 0.5)!,
      );
  }

  /// Col — anneau de graphite entre la tête et le corps.
  ///
  /// Il masque la jonction et donne une articulation là où deux volumes se
  /// rencontraient sans explication.
  void _col(Canvas canvas) {
    final Rect boite = Rect.fromCenter(
      center: Offset(_cx, 0.572 * _h),
      width: 0.175 * _h,
      height: 0.050 * _h,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(boite, Radius.circular(0.028 * _h)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[_graphiteSombre, _graphiteClair, _graphite],
          stops: <double>[0, 0.55, 1],
        ).createShader(boite),
    );
  }

  void _visiereEtVisage(
    Canvas canvas,
    Offset centre,
    double tour,
    double ecrasement,
  ) {
    // La visière se décale **plus** que la coque : c'est cette parallaxe qui
    // creuse la profondeur entre la vitre et le boîtier.
    final Rect boite = Rect.fromCenter(
      center: centre.translate(tour * 0.024 * _h, 0.006 * _h),
      width: 0.420 * _h * ecrasement,
      height: 0.372 * _h,
    );
    final RRect visiere = RRect.fromRectAndRadius(
      boite,
      Radius.circular(0.144 * _h),
    );

    canvas
      // Liseré sombre : la visière est encastrée dans la coque, pas posée.
      ..drawRRect(
        visiere.inflate(0.006 * _h),
        Paint()
          ..color = _graphiteSombre.withValues(alpha: 0.55)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 0.008 * _h),
      )
      ..drawRRect(
        visiere,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[_visiereHaut, _visiere, _visiereBas],
            stops: <double>[0, 0.42, 1],
          ).createShader(boite),
      );

    canvas.save();
    canvas.clipRRect(visiere);

    final Rect voile = Rect.fromCenter(
      center: boite.topCenter.translate(
        -boite.width * 0.14 + tour * 0.03 * _h,
        boite.height * 0.10,
      ),
      width: boite.width * 1.05,
      height: boite.height * 0.55,
    );
    canvas.drawOval(
      voile,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            Colors.white.withValues(alpha: 0.13),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(voile),
    );

    _visage(canvas, boite, tour);
    canvas.restore();
  }

  // ---------------------------------------------------------------------
  // Visage
  // ---------------------------------------------------------------------

  void _visage(Canvas canvas, Rect visiere, double tour) {
    final double u = visiere.width;

    // Le regard dérive, et suit le demi-tour de tête : un visage
    // parfaitement immobile est mort, même quand il sourit.
    final double regard = (_onde(4.1) * 0.018 + tour * 0.045) * u;
    final double ouverture = _ouverture();

    // Halo puis cœur : c'est ainsi qu'une diode se peint.
    void tracer(void Function(Paint) dessin) {
      dessin(
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = u * 0.074
          ..strokeCap = StrokeCap.round
          ..color = _vert.withValues(alpha: 0.28)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, u * 0.030),
      );
      dessin(
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = u * 0.044
          ..strokeCap = StrokeCap.round
          ..color = _vertEmissif,
      );
    }

    // Yeux : deux arcs surbaissés. Moins bombés qu'un sourire d'emoji — le
    // regard doit rester un signal d'appareil, pas une mimique.
    for (final double signe in <double>[-1, 1]) {
      final Rect arc = Rect.fromCenter(
        center: Offset(
          visiere.center.dx + signe * u * 0.200 + regard,
          visiere.center.dy - u * 0.100,
        ),
        width: u * 0.225,
        height: u * 0.125 * ouverture,
      );
      tracer((p) => canvas.drawArc(arc, math.pi, math.pi, false, p));
    }

    // Bouche : un trait au repos, une courbe retenue quand il s'anime.
    final double joie = sourire * (1 + salut * 0.25);
    final double demi = u * 0.135 * (1 + joie * 0.12);
    final double y = visiere.center.dy + u * 0.140;

    if (joie < 0.06) {
      tracer(
        (p) => canvas.drawLine(
          Offset(visiere.center.dx - demi + regard * 0.5, y),
          Offset(visiere.center.dx + demi + regard * 0.5, y),
          p,
        ),
      );
      return;
    }
    final Rect bouche = Rect.fromCenter(
      center: Offset(visiere.center.dx + regard * 0.5, y),
      width: demi * 2,
      height: u * 0.165 * joie,
    );
    tracer((p) => canvas.drawArc(bouche, 0, math.pi, false, p));
  }

  /// 1 = yeux grands ouverts, 0 = fermés.
  ///
  /// Calé sur un cycle propre, et non sur le temps absolu : celui-ci ne
  /// reboucle plus, le personnage n'aurait cligné qu'une fois. Les instants
  /// ne sont pas multiples les uns des autres, et aucune fenêtre ne
  /// chevauche le raccord du cycle — un clignement coupé en deux se verrait.
  double _ouverture() {
    if (!anime) return 1;
    final double phase = secondes % 7.3;
    for (final double instant in const <double>[1.4, 3.3, 5.9]) {
      if ((phase - instant).abs() < 0.09) {
        return ((phase - instant).abs() / 0.09).clamp(0.10, 1);
      }
    }
    return 1;
  }

  /// Impulsion brève et périodique, entre 0 et 1 — support des micro-actions.
  double _ponctuel(double periode, double duree) {
    final double phase = secondes % periode;
    return phase > duree ? 0 : math.sin(phase / duree * math.pi);
  }

  // ---------------------------------------------------------------------
  // Corps
  // ---------------------------------------------------------------------

  void _corps(Canvas canvas, double respiration) {
    final Rect boite = Rect.fromCenter(
      center: Offset(_cx, 0.782 * _h),
      width: 0.415 * _h * (1 - respiration * 0.014),
      height: 0.385 * _h,
    );
    final RRect corps = RRect.fromRectAndCorners(
      boite,
      topLeft: Radius.circular(0.150 * _h),
      topRight: Radius.circular(0.150 * _h),
      bottomLeft: Radius.circular(0.215 * _h),
      bottomRight: Radius.circular(0.215 * _h),
    );

    canvas
      ..drawRRect(
        corps.shift(Offset(0, 0.010 * _h)),
        Paint()
          ..color = _ombrePortee.withValues(alpha: 0.16)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 0.026 * _h),
      )
      ..drawRRect(
        corps,
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(-0.5, -0.7),
            radius: 1.3,
            colors: <Color>[_coqueVive, _coqueClaire, _coque, _coqueOmbre],
            stops: <double>[0, 0.33, 0.68, 1],
          ).createShader(boite),
      );

    canvas.save();
    canvas.clipRRect(corps);
    // Occlusion sous le col : la jonction doit se sentir.
    canvas.drawRect(
      Rect.fromLTRB(boite.left, boite.top, boite.right, boite.top + 0.090 * _h),
      Paint()
        ..shader =
            LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                _coqueOmbreProfonde.withValues(alpha: 0.45),
                _coqueOmbreProfonde.withValues(alpha: 0),
              ],
            ).createShader(
              Rect.fromLTRB(
                boite.left,
                boite.top,
                boite.right,
                boite.top + 0.090 * _h,
              ),
            ),
    );
    canvas.restore();

    _ecusson(canvas, boite);
  }

  /// Écusson de poitrine — le logo du ministère, **gravé** dans la coque.
  ///
  /// Creusé, non collé : une ombre interne en haut, une lumière rasante en
  /// bas, et le logo posé au fond. Un aplat de couleur posé sur un corps
  /// courbe se lit comme un autocollant ; une gravure appartient à l'objet.
  void _ecusson(Canvas canvas, Rect corps) {
    final double cote = corps.width * 0.44;
    final Rect boite = Rect.fromCenter(
      center: corps.center.translate(0, -0.004 * _h),
      width: cote,
      height: cote,
    );
    final RRect plaque = RRect.fromRectAndRadius(
      boite,
      Radius.circular(cote * 0.30),
    );

    canvas
    // Fond du creux, légèrement plus sombre que la coque.
    .drawRRect(
      plaque,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color.lerp(_coque, _coqueOmbre, 0.55)!, _coqueClaire],
        ).createShader(boite),
    );

    canvas.save();
    canvas.clipRRect(plaque);
    canvas
      // Ombre interne en haut : c'est elle qui creuse.
      ..drawRRect(
        plaque.shift(Offset(0, cote * 0.075)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = cote * 0.10
          ..color = _coqueOmbreProfonde.withValues(alpha: 0.45)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, cote * 0.05),
      )
      // Lumière rasante en bas : la lèvre inférieure du creux.
      ..drawRRect(
        plaque.shift(Offset(0, -cote * 0.075)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = cote * 0.07
          ..color = Colors.white.withValues(alpha: 0.65)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, cote * 0.045),
      );

    final ui.Image? image = logo;
    if (image != null) {
      final Rect cible = _contenir(
        Size(image.width.toDouble(), image.height.toDouble()),
        boite.deflate(cote * 0.15),
      );
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        cible,
        Paint()..filterQuality = FilterQuality.high,
      );
    }
    canvas.restore();
  }

  /// Rectangle de destination conservant les proportions, à la façon d'un
  /// `BoxFit.contain`.
  static Rect _contenir(Size source, Rect cadre) {
    final double facteur = math.min(
      cadre.width / source.width,
      cadre.height / source.height,
    );
    final Size finale = source * facteur;
    return Rect.fromCenter(
      center: cadre.center,
      width: finale.width,
      height: finale.height,
    );
  }

  // ---------------------------------------------------------------------
  // Bras
  // ---------------------------------------------------------------------

  /// Un bras, articulé à l'épaule par une rotule de graphite.
  void _bras(Canvas canvas, {required bool gauche, required double vif}) {
    final double signe = gauche ? -1 : 1;
    final Offset epaule = Offset(_cx + signe * 0.196 * _h, 0.700 * _h);

    // Les bras suivent la tête avec un retard plus long encore : dernier
    // maillon de la chaîne, ils arrivent toujours en dernier.
    final double trainee = _tenue(2.6, 0.6 - 0.20) * 0.055 * vif;
    final double haussement = _ponctuel(5.3, 0.7) * 0.070 * signe;

    final double angleSalut = gauche ? 0 : -_gesteDeSalut() * 1.10;
    // Rotation **opposée** au côté : une rotation positive pousse le membre
    // vers la gauche du canevas.
    final double angle =
        -signe * 0.86 - trainee * signe - haussement + angleSalut;

    final double longueur = 0.255 * _h;
    final double largeurBout = 0.098 * _h;
    final double largeurEpaule = 0.052 * _h;

    canvas.save();
    canvas
      ..translate(epaule.dx, epaule.dy)
      ..rotate(angle);

    // Le bout est un **demi-cercle exact**, pas la rencontre de deux courbes.
    // Deux cubiques qui se rejoignent forment une pointe, si légère soit-elle,
    // et c'est cette pointe qui donnait l'effet de nageoire.
    final double rayonMain = largeurBout / 2;
    final double coude = longueur - rayonMain;
    final Path membre = Path()
      ..moveTo(-largeurEpaule / 2, 0)
      ..cubicTo(
        -largeurBout * 0.56,
        longueur * 0.42,
        -rayonMain,
        coude * 0.82,
        -rayonMain,
        coude,
      )
      ..arcToPoint(
        Offset(rayonMain, coude),
        radius: Radius.circular(rayonMain),
        clockwise: false,
      )
      ..cubicTo(
        rayonMain,
        coude * 0.82,
        largeurBout * 0.56,
        longueur * 0.42,
        largeurEpaule / 2,
        0,
      )
      ..close();

    canvas
      ..drawPath(
        membre.shift(Offset(0, 0.008 * _h)),
        Paint()
          ..color = _ombrePortee.withValues(alpha: 0.14)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 0.018 * _h),
      )
      ..drawPath(
        membre,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[_coqueVive, _coque, _coqueOmbre],
            stops: <double>[0, 0.52, 1],
          ).createShader(membre.getBounds()),
      );
    canvas.restore();
  }

  /// Rotules d'épaule, en graphite.
  ///
  /// Dessinées **après le corps** : placées avant, elles disparaissaient
  /// derrière lui et le bras semblait surgir de nulle part. C'est cette
  /// pièce, et elle seule, qui transforme une nageoire collée en un membre
  /// articulé.
  void _rotules(Canvas canvas) {
    for (final double signe in <double>[-1, 1]) {
      final Offset centre = Offset(_cx + signe * 0.196 * _h, 0.700 * _h);
      final double r = 0.040 * _h;
      canvas
        ..drawCircle(
          centre,
          r * 1.25,
          Paint()
            ..color = _ombrePortee.withValues(alpha: 0.18)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.5),
        )
        ..drawCircle(
          centre,
          r,
          Paint()
            ..shader = const RadialGradient(
              center: Alignment(-0.4, -0.5),
              colors: <Color>[_graphiteClair, _graphite, _graphiteSombre],
              stops: <double>[0, 0.6, 1],
            ).createShader(Rect.fromCircle(center: centre, radius: r)),
        );
    }
  }

  /// Courbe du geste, de 0 à 1 puis retour.
  ///
  /// Construit comme une action animée, pas comme une sinusoïde sans fin :
  /// anticipation — le bras descend d'abord —, montée, trois battements,
  /// retour. C'est l'anticipation qui rend le geste crédible.
  double _gesteDeSalut() {
    if (salut <= 0) return 0;
    if (salut < 0.14) return -0.22 * (salut / 0.14);
    if (salut < 0.32) {
      final double p = (salut - 0.14) / 0.18;
      return Curves.easeOutBack.transform(p) * 1.05 - 0.22 * (1 - p);
    }
    if (salut < 0.84) {
      final double p = (salut - 0.32) / 0.52;
      return 1.05 + 0.26 * math.sin(p * math.pi * 6);
    }
    final double p = (salut - 0.84) / 0.16;
    return 1.05 * (1 - Curves.easeInCubic.transform(p));
  }

  // ---------------------------------------------------------------------
  // Sol
  // ---------------------------------------------------------------------

  /// Ombre de contact et reflet — ce qui pose le personnage sur une surface
  /// au lieu de le laisser découpé sur le fond.
  void _ancrageAuSol(Canvas canvas, double elan, double flottement) {
    final double hauteur = flottement;

    // Reflet : une trace claire et très étalée, juste sous lui.
    final Rect reflet = Rect.fromCenter(
      center: Offset(_cx, 0.962 * _h),
      width: 0.40 * _h,
      height: 0.075 * _h,
    );
    canvas.drawOval(
      reflet,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            _vert.withValues(alpha: 0.10),
            _vert.withValues(alpha: 0),
          ],
        ).createShader(reflet),
    );

    // Ombre de contact : serrée et franche, elle dit où il touche. Une ombre
    // large et molle laisse l'objet flotter.
    final Rect contact = Rect.fromCenter(
      center: Offset(_cx, 0.958 * _h),
      width: 0.225 * _h * (1 - hauteur * 0.10 - elan * 0.16),
      height: 0.036 * _h,
    );
    canvas.drawOval(
      contact,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            _ombrePortee.withValues(alpha: 0.34 - elan * 0.10),
            _ombrePortee.withValues(alpha: 0),
          ],
          stops: const <double>[0.35, 1],
        ).createShader(contact),
    );
  }

  // ---------------------------------------------------------------------
  // Vignette
  // ---------------------------------------------------------------------

  /// Le visage seul, dans sa visière — ce que montrent les avatars du fil.
  void _pastille(Canvas canvas, Size size) {
    final double cote = size.shortestSide;
    final Rect boite = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: cote * 0.92,
      height: cote * 0.84,
    );
    final RRect visiere = RRect.fromRectAndRadius(
      boite,
      Radius.circular(cote * 0.32),
    );

    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(
          boite.inflate(cote * 0.04),
          Radius.circular(cote * 0.36),
        ),
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[_coqueVive, _coque],
          ).createShader(boite),
      )
      ..drawRRect(
        visiere,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[_visiereHaut, _visiere, _visiereBas],
          ).createShader(boite),
      );

    canvas.save();
    canvas.clipRRect(visiere);
    _visage(canvas, boite, 0);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PeintreNdimbal ancien) =>
      ancien.secondes != secondes ||
      ancien.salut != salut ||
      ancien.sourire != sourire ||
      ancien.forme != forme ||
      ancien.logo != logo;
}
