import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../domain/texte_enrichi.dart';

/// Ouvre un lien d'Amath.
typedef OuvrirLien = Future<void> Function(Uri url);

/// Navigateur externe, comme le demande le contrat : une page de connexion
/// ouverte dans l'application ferait douter le candidat de l'adresse.
Future<void> ouvrirDansLeNavigateur(Uri url) async {
  await launchUrl(url, mode: LaunchMode.externalApplication);
}

/// Texte d'une bulle d'Amath, en Markdown réduit (contrat chatbot §4).
///
/// Stateful pour une seule raison : les reconnaisseurs de geste des liens
/// doivent être libérés.
class TexteChatbot extends StatefulWidget {
  const TexteChatbot(
    this.texte, {
    this.style,
    this.ouvrir = ouvrirDansLeNavigateur,
    super.key,
  });

  final String texte;
  final TextStyle? style;
  final OuvrirLien ouvrir;

  @override
  State<TexteChatbot> createState() => _TexteChatbotState();
}

class _TexteChatbotState extends State<TexteChatbot> {
  final List<TapGestureRecognizer> _liens = <TapGestureRecognizer>[];

  void _liberer() {
    for (final TapGestureRecognizer r in _liens) {
      r.dispose();
    }
    _liens.clear();
  }

  TapGestureRecognizer _reconnaisseur(Uri url) {
    final TapGestureRecognizer r = TapGestureRecognizer()
      ..onTap = () => widget.ouvrir(url);
    _liens.add(r);
    return r;
  }

  @override
  void dispose() {
    _liberer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _liberer();
    final Color couleurLien = Theme.of(context).colorScheme.primary;

    return Text.rich(
      TextSpan(
        style: widget.style,
        children: <InlineSpan>[
          for (final Fragment f in analyserTexteEnrichi(widget.texte))
            switch (f.style) {
              StyleFragment.normal => TextSpan(text: f.texte),
              StyleFragment.gras => TextSpan(
                text: f.texte,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              StyleFragment.italique => TextSpan(
                text: f.texte,
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
              StyleFragment.lien => TextSpan(
                text: f.texte,
                style: TextStyle(
                  color: couleurLien,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                  decorationColor: couleurLien,
                ),
                recognizer: _reconnaisseur(f.url!),
              ),
            },
        ],
      ),
    );
  }
}
