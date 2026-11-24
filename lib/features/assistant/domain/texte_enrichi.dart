import 'package:flutter/foundation.dart';

/// Style d'un morceau de texte du chatbot.
enum StyleFragment { normal, gras, italique, lien }

@immutable
class Fragment {
  const Fragment(this.texte, [this.style = StyleFragment.normal, this.url]);

  final String texte;
  final StyleFragment style;

  /// Renseignée pour un [StyleFragment.lien] seulement, toujours en http(s).
  final Uri? url;

  @override
  bool operator ==(Object other) =>
      other is Fragment &&
      other.texte == texte &&
      other.style == style &&
      other.url == url;

  @override
  int get hashCode => Object.hash(texte, style, url);

  @override
  String toString() => '${style.name}(${url ?? ''}): $texte';
}

/// Découpe le Markdown **réduit** du chatbot (contrat §4).
///
/// Seuls `**gras**`, `*italique*` et `[libellé](https://…)` sont reconnus.
/// Tout le reste — HTML compris — reste du texte brut : rien de ce que
/// renvoie le serveur ne peut injecter de mise en forme imprévue. Un lien
/// qui n'est pas en http(s) n'est pas cliquable : seul son libellé s'affiche.
List<Fragment> analyserTexteEnrichi(String texte) {
  final List<Fragment> fragments = <Fragment>[];
  int curseur = 0;

  void ajouter(Fragment f) {
    if (f.texte.isEmpty) return;
    // Deux morceaux normaux qui se suivent n'en font qu'un.
    if (f.style == StyleFragment.normal &&
        fragments.isNotEmpty &&
        fragments.last.style == StyleFragment.normal) {
      fragments.last = Fragment(fragments.last.texte + f.texte);
    } else {
      fragments.add(f);
    }
  }

  for (final RegExpMatch m in _balises.allMatches(texte)) {
    ajouter(Fragment(texte.substring(curseur, m.start)));
    if (m.group(1) case final String gras) {
      ajouter(Fragment(gras, StyleFragment.gras));
    } else if (m.group(2) case final String libelle) {
      final Uri? url = _urlWeb(m.group(3)!);
      ajouter(
        url == null
            ? Fragment(libelle)
            : Fragment(libelle, StyleFragment.lien, url),
      );
    } else {
      ajouter(Fragment(m.group(4)!, StyleFragment.italique));
    }
    curseur = m.end;
  }
  ajouter(Fragment(texte.substring(curseur)));
  return fragments;
}

/// Dans l'ordre : gras, lien, italique. L'italique exige un caractère non
/// blanc juste après l'étoile ouvrante et juste avant la fermante : une
/// puce « * » ou une multiplication « 2 * 3 » ne sont pas de l'italique.
final RegExp _balises = RegExp(
  r'\*\*(.+?)\*\*'
  r'|\[([^\]\n]+)\]\(([^)\s]+)\)'
  r'|\*(?![\s*])([^*\n]+?)(?<!\s)\*',
);

Uri? _urlWeb(String brut) {
  final Uri? url = Uri.tryParse(brut);
  if (url == null || !url.hasAuthority) return null;
  return url.scheme == 'https' || url.scheme == 'http' ? url : null;
}
