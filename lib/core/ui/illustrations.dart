import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';

/// Illustrations de l'onboarding, dessinées et animées en Flutter.
///
/// Aucun fichier image : net à toute résolution, taille nulle dans l'APK, et
/// les couleurs viennent de la marque. Toutes les coordonnées sont exprimées
/// dans un carré de référence 100×100, mis à l'échelle au rendu : une
/// illustration se comporte donc identiquement sur téléphone et sur tablette.
///
/// Chaque dessin se construit devant l'utilisateur, élément par élément. Le
/// montage n'est pas décoratif : il **raconte** le propos de l'écran — le
/// dossier s'ouvre, la pièce est validée, les étapes s'enchaînent.
typedef _Fabrique = CustomPainter Function(double progression);

class Illustration extends StatefulWidget {
  /// Un dossier unique, dont sort une seule fiche.
  const Illustration.dossierUnique({
    required this.taille,
    this.actif = true,
    super.key,
  }) : _fabrique = _dossier;

  /// Des pièces justificatives empilées et validées.
  const Illustration.pieces({
    required this.taille,
    this.actif = true,
    super.key,
  }) : _fabrique = _pieces;

  /// Quatre étapes reliées, deux franchies, la troisième en cours.
  const Illustration.etapes({
    required this.taille,
    this.actif = true,
    super.key,
  }) : _fabrique = _etapes;

  final double taille;

  /// L'animation se rejoue à chaque fois que la diapositive redevient active.
  final bool actif;

  final _Fabrique _fabrique;

  @override
  State<Illustration> createState() => _IllustrationState();
}

class _IllustrationState extends State<Illustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controleur = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
    value: widget.actif ? 0 : 1,
  );

  @override
  void initState() {
    super.initState();
    if (widget.actif) _controleur.forward();
  }

  @override
  void didUpdateWidget(Illustration oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Revenir sur une diapositive rejoue son montage : c'est ce qui donne à
    // l'onboarding sa sensation de réactivité au balayage.
    if (widget.actif && !oldWidget.actif) _controleur.forward(from: 0);
  }

  @override
  void dispose() {
    _controleur.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: widget.taille,
    child: AnimatedBuilder(
      animation: _controleur,
      builder: (_, _) =>
          CustomPaint(painter: widget._fabrique(_controleur.value)),
    ),
  );
}

// ---------------------------------------------------------------------------
// Outils de montage
// ---------------------------------------------------------------------------

/// Avancement d'un élément entre [debut] et [fin] de la progression globale.
double _phase(
  double p,
  double debut,
  double fin, [
  Curve courbe = Curves.easeOutCubic,
]) => courbe.transform((((p - debut) / (fin - debut)).clamp(0.0, 1.0)));

/// Portion initiale d'un tracé, pour le faire « s'écrire ».
Path _traceProgressif(Path complet, double avancement) {
  if (avancement >= 1) return complet;
  final Path partiel = Path();
  for (final PathMetric metrique in complet.computeMetrics()) {
    partiel.addPath(
      metrique.extractPath(0, metrique.length * avancement.clamp(0.0, 1.0)),
      Offset.zero,
    );
  }
  return partiel;
}

/// Applique un fondu et une remontée à ce qui est dessiné dans [dessin].
void _apparaitre(
  Canvas canvas,
  Size size,
  double avancement, {
  required double remontee,
  required VoidCallback dessin,
}) {
  if (avancement <= 0) return;
  canvas
    ..saveLayer(
      Offset.zero & size,
      Paint()..color = Colors.white.withValues(alpha: avancement.clamp(0.0, 1.0)),
    )
    ..translate(0, remontee * (1 - avancement));
  dessin();
  canvas.restore();
}

void _texte(
  Canvas canvas,
  String contenu,
  Offset centre,
  double taille,
  Color couleur,
) {
  final TextPainter peintre = TextPainter(
    text: TextSpan(
      text: contenu,
      style: TextStyle(
        color: couleur,
        fontSize: taille,
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w700,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  peintre.paint(
    canvas,
    centre - Offset(peintre.width / 2, peintre.height / 2),
  );
}

// ---------------------------------------------------------------------------
// 1 — Un dossier unique
// ---------------------------------------------------------------------------

CustomPainter _dossier(double progression) => _PeintreDossier(progression);

class _PeintreDossier extends CustomPainter {
  const _PeintreDossier(this.p);

  final double p;

  @override
  void paint(Canvas canvas, Size size) {
    final double u = size.width / 100;

    final double vChemise = _phase(p, 0, 0.35);
    final double vFiche = _phase(p, 0.28, 0.62);
    final double vLignes = _phase(p, 0.52, 0.80, Curves.easeInOut);
    final double vBadge = _phase(p, 0.74, 1, Curves.easeOutBack);

    // --- Dos de la chemise, avec son onglet ---
    _apparaitre(
      canvas,
      size,
      vChemise,
      remontee: 14 * u,
      dessin: () {
        final Path dos = Path()
          ..addRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(14 * u, 28 * u, 72 * u, 52 * u),
              Radius.circular(7 * u),
            ),
          )
          ..addRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(14 * u, 21 * u, 30 * u, 14 * u),
              Radius.circular(4 * u),
            ),
          );
        canvas.drawPath(
          dos,
          Paint()..color = AppColors.vert.withValues(alpha: 0.55),
        );
      },
    );

    // --- La fiche, qui sort de la chemise ---
    _apparaitre(
      canvas,
      size,
      vFiche,
      remontee: 22 * u,
      dessin: () {
        final RRect fiche = RRect.fromRectAndRadius(
          Rect.fromLTWH(26 * u, 18 * u, 48 * u, 46 * u),
          Radius.circular(5 * u),
        );
        canvas
          ..drawRRect(fiche, Paint()..color = Colors.white)
          ..drawRRect(
            fiche,
            Paint()
              ..color = AppColors.anthracite
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.4 * u,
          );
      },
    );

    // --- Lignes de texte, qui s'écrivent ---
    if (vLignes > 0) {
      final Paint ligne = Paint()
        ..color = AppColors.anthracite.withValues(alpha: 0.3)
        ..strokeWidth = 3 * u
        ..strokeCap = StrokeCap.round;
      const List<(double, double)> lignes = <(double, double)>[
        (29, 26),
        (37, 32),
        (45, 20),
      ];
      for (int i = 0; i < lignes.length; i++) {
        final (double y, double largeur) = lignes[i];
        // Chaque ligne démarre après la précédente : on lit une écriture.
        final double t = _phase(vLignes, i * 0.22, i * 0.22 + 0.56);
        if (t <= 0) continue;
        canvas.drawLine(
          Offset(33 * u, y * u),
          Offset((33 + largeur * t) * u, y * u),
          ligne,
        );
      }
    }

    // --- Devant de la chemise, qui referme le tout ---
    _apparaitre(
      canvas,
      size,
      vChemise,
      remontee: 14 * u,
      dessin: () => canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(14 * u, 46 * u, 72 * u, 36 * u),
          Radius.circular(7 * u),
        ),
        Paint()..color = AppColors.vert,
      ),
    );

    // --- Pastille « 1 » : une demande, une seule ---
    if (vBadge > 0) {
      final Offset centre = Offset(76 * u, 26 * u);
      final double r = 13 * u * vBadge;
      canvas
        ..drawCircle(centre, r, Paint()..color = AppColors.jaune)
        ..save()
        ..translate(centre.dx, centre.dy)
        ..scale(vBadge)
        ..translate(-centre.dx, -centre.dy);
      _texte(canvas, '1', centre, 15 * u, AppColors.anthracite);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _PeintreDossier ancien) => ancien.p != p;
}

// ---------------------------------------------------------------------------
// 2 — Les pièces justificatives
// ---------------------------------------------------------------------------

CustomPainter _pieces(double progression) => _PeintrePieces(progression);

class _PeintrePieces extends CustomPainter {
  const _PeintrePieces(this.p);

  final double p;

  @override
  void paint(Canvas canvas, Size size) {
    final double u = size.width / 100;

    final double vArriere = _phase(p, 0, 0.38);
    final double vPrincipale = _phase(p, 0.22, 0.55);
    final double vLignes = _phase(p, 0.45, 0.74, Curves.easeInOut);
    final double vPastille = _phase(p, 0.66, 0.88, Curves.easeOutBack);
    final double vCoche = _phase(p, 0.82, 1, Curves.easeInOut);

    // Les feuilles du fond se déploient en éventail depuis la principale.
    _feuille(
      canvas,
      u,
      ancrage: Offset(22 * u, 20 * u),
      angle: -0.16 * vArriere,
      decalage: Offset(-9 * u * vArriere, 3 * u * vArriere),
      couleur: AppColors.jaune.withValues(alpha: 0.55 * vArriere),
    );
    _feuille(
      canvas,
      u,
      ancrage: Offset(22 * u, 20 * u),
      angle: 0.11 * vArriere,
      decalage: Offset(4 * u * vArriere, -2 * u * vArriere),
      couleur: AppColors.rouge.withValues(alpha: 0.4 * vArriere),
    );

    // Feuille principale.
    _apparaitre(
      canvas,
      size,
      vPrincipale,
      remontee: 16 * u,
      dessin: () {
        final RRect cadre = RRect.fromRectAndRadius(
          Rect.fromLTWH(22 * u, 20 * u, 52 * u, 62 * u),
          Radius.circular(6 * u),
        );
        canvas
          ..drawRRect(cadre, Paint()..color = Colors.white)
          ..drawRRect(
            cadre,
            Paint()
              ..color = AppColors.anthracite
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.4 * u,
          );
      },
    );

    if (vLignes > 0) {
      final Paint ligne = Paint()
        ..color = AppColors.anthracite.withValues(alpha: 0.28)
        ..strokeWidth = 3.2 * u
        ..strokeCap = StrokeCap.round;
      const List<(double, double)> lignes = <(double, double)>[
        (34, 30),
        (43, 36),
        (52, 22),
      ];
      for (int i = 0; i < lignes.length; i++) {
        final (double y, double largeur) = lignes[i];
        final double t = _phase(vLignes, i * 0.2, i * 0.2 + 0.6);
        if (t <= 0) continue;
        canvas.drawLine(
          Offset(30 * u, y * u),
          Offset((30 + largeur * t) * u, y * u),
          ligne,
        );
      }
    }

    // Pastille de validation : la pièce est acceptée.
    if (vPastille > 0) {
      final Offset pastille = Offset(72 * u, 72 * u);
      canvas.drawCircle(
        pastille,
        16 * u * vPastille,
        Paint()..color = AppColors.vert,
      );

      if (vCoche > 0) {
        final Path coche = Path()
          ..moveTo(pastille.dx - 7 * u, pastille.dy)
          ..lineTo(pastille.dx - 1.5 * u, pastille.dy + 5.5 * u)
          ..lineTo(pastille.dx + 7.5 * u, pastille.dy - 5.5 * u);
        canvas.drawPath(
          _traceProgressif(coche, vCoche),
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.6 * u
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round,
        );
      }
    }
  }

  void _feuille(
    Canvas canvas,
    double u, {
    required Offset ancrage,
    required double angle,
    required Offset decalage,
    required Color couleur,
  }) {
    if (couleur.a <= 0) return;
    canvas
      ..save()
      ..translate(ancrage.dx + decalage.dx, ancrage.dy + decalage.dy)
      ..rotate(angle)
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, 52 * u, 62 * u),
          Radius.circular(6 * u),
        ),
        Paint()..color = couleur,
      )
      ..restore();
  }

  @override
  bool shouldRepaint(covariant _PeintrePieces ancien) => ancien.p != p;
}

// ---------------------------------------------------------------------------
// 3 — Les quatre étapes
// ---------------------------------------------------------------------------

CustomPainter _etapes(double progression) => _PeintreEtapes(progression);

class _PeintreEtapes extends CustomPainter {
  const _PeintreEtapes(this.p);

  final double p;

  /// Deux étapes franchies, la troisième en cours, la quatrième à venir.
  static const int _franchies = 2;
  static const int _enCours = 2; // index de l'étape courante
  static const int _total = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final double u = size.width / 100;
    final double y = 44 * u;
    final double xDebut = 14 * u;
    final double xFin = 86 * u;
    final double pas = (xFin - xDebut) / (_total - 1);

    final double vFil = _phase(p, 0.05, 0.55, Curves.easeInOut);

    // Le fil qui relie les étapes, tracé de gauche à droite.
    canvas
      ..drawLine(
        Offset(xDebut, y),
        Offset(xFin, y),
        Paint()
          ..color = AppColors.anthracite.withValues(alpha: 0.12)
          ..strokeWidth = 3 * u
          ..strokeCap = StrokeCap.round,
      )
      ..drawLine(
        Offset(xDebut, y),
        Offset(xDebut + (xFin - xDebut) * vFil, y),
        Paint()
          ..color = AppColors.vert
          ..strokeWidth = 3 * u
          ..strokeCap = StrokeCap.round,
      );

    for (int i = 0; i < _total; i++) {
      // Chaque étape apparaît quand le fil l'atteint.
      final double vNoeud = _phase(p, 0.12 + i * 0.16, 0.34 + i * 0.16,
          Curves.easeOutBack);
      if (vNoeud <= 0) continue;

      final Offset centre = Offset(xDebut + pas * i, y);
      final double r = 11 * u * vNoeud;

      if (i < _franchies) {
        // Franchie : pastille pleine et coche.
        canvas.drawCircle(centre, r, Paint()..color = AppColors.vert);
        final double vCoche = _phase(p, 0.30 + i * 0.16, 0.48 + i * 0.16);
        if (vCoche > 0) {
          final Path coche = Path()
            ..moveTo(centre.dx - 4.6 * u, centre.dy + 0.2 * u)
            ..lineTo(centre.dx - 1.2 * u, centre.dy + 3.6 * u)
            ..lineTo(centre.dx + 5 * u, centre.dy - 3.4 * u);
          canvas.drawPath(
            _traceProgressif(coche, vCoche),
            Paint()
              ..color = Colors.white
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.6 * u
              ..strokeCap = StrokeCap.round
              ..strokeJoin = StrokeJoin.round,
          );
        }
      } else if (i == _enCours) {
        // En cours : halo jaune, anneau vert, cœur plein. Le jaune ne sert
        // qu'ici — c'est l'accent de l'étape courante, jamais une action.
        canvas
          ..drawCircle(
            centre,
            r * 1.75,
            Paint()..color = AppColors.jaune.withValues(alpha: 0.35 * vNoeud),
          )
          ..drawCircle(centre, r, Paint()..color = Colors.white)
          ..drawCircle(
            centre,
            r,
            Paint()
              ..color = AppColors.vert
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3 * u,
          )
          ..drawCircle(centre, r * 0.42, Paint()..color = AppColors.vert);
      } else {
        // À venir : simple contour.
        canvas
          ..drawCircle(centre, r, Paint()..color = Colors.white)
          ..drawCircle(
            centre,
            r,
            Paint()
              ..color = AppColors.anthracite.withValues(alpha: 0.2)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.4 * u,
          );
      }

      // Étiquette sous l'étape : deux traits qui figurent son intitulé.
      final double opacite = i <= _enCours ? 0.42 : 0.18;
      final Paint trait = Paint()
        ..color = AppColors.anthracite.withValues(alpha: opacite * vNoeud)
        ..strokeWidth = 2.6 * u
        ..strokeCap = StrokeCap.round;
      for (final (double dy, double demiLargeur) in <(double, double)>[
        (20, 7),
        (27, 4.5),
      ]) {
        canvas.drawLine(
          Offset(centre.dx - demiLargeur * u, centre.dy + dy * u),
          Offset(centre.dx + demiLargeur * u, centre.dy + dy * u),
          trait,
        );
      }
    }

    // Numéro de l'étape courante, en surplomb.
    final double vNumero = _phase(p, 0.66, 0.9, Curves.easeOutBack);
    if (vNumero > 0) {
      final Offset ancre = Offset(xDebut + pas * _enCours, y - 26 * u);
      canvas
        ..save()
        ..translate(ancre.dx, ancre.dy)
        ..scale(vNumero)
        ..translate(-ancre.dx, -ancre.dy)
        ..drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: ancre, width: 26 * u, height: 17 * u),
            const Radius.circular(Rayon.pilule),
          ),
          Paint()..color = AppColors.vert,
        );
      _texte(canvas, '3/4', ancre, 8.5 * u, Colors.white);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _PeintreEtapes ancien) => ancien.p != p;
}
