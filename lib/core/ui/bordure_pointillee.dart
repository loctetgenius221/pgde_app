import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import '../theme/app_dimens.dart';

/// Zone cliquable au contour pointillé — « Ajouter un autre diplôme »,
/// « Joindre le diplôme ».
///
/// Le pointillé est la convention du web pour ce qui **n'existe pas encore** :
/// une place à remplir, par opposition aux cartes pleines déjà saisies.
class ZonePointillee extends StatelessWidget {
  const ZonePointillee({
    required this.child,
    required this.onTap,
    this.padding = const EdgeInsets.all(Espace.md),
    this.rayon = Rayon.champ,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double rayon;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final BorderRadius arrondi = BorderRadius.circular(rayon);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: arrondi,
        child: CustomPaint(
          painter: _PeintreContour(
            couleur: scheme.onSurfaceVariant.withValues(alpha: 0.35),
            rayon: rayon,
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class _PeintreContour extends CustomPainter {
  const _PeintreContour({required this.couleur, required this.rayon});

  final Color couleur;
  final double rayon;

  static const double _tiret = 5;
  static const double _espace = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint pinceau = Paint()
      ..color = couleur
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    // Tracé à mi-épaisseur du bord, pour que le trait ne soit pas rogné.
    final Path contour = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(0.6),
          Radius.circular(rayon),
        ),
      );
    for (final PathMetric mesure in contour.computeMetrics()) {
      for (double d = 0; d < mesure.length; d += _tiret + _espace) {
        canvas.drawPath(mesure.extractPath(d, d + _tiret), pinceau);
      }
    }
  }

  @override
  bool shouldRepaint(_PeintreContour ancien) =>
      ancien.couleur != couleur || ancien.rayon != rayon;
}
