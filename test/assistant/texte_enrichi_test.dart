import 'package:flutter_test/flutter_test.dart';
import 'package:pgde_app/features/assistant/domain/texte_enrichi.dart';

const StyleFragment _n = StyleFragment.normal;
const StyleFragment _g = StyleFragment.gras;
const StyleFragment _i = StyleFragment.italique;

void main() {
  group('Markdown réduit d’Amath', () {
    test('un texte sans balise reste un seul fragment normal', () {
      expect(analyserTexteEnrichi('Bonjour Awa'), const [
        Fragment('Bonjour Awa'),
      ]);
    });

    test('un texte vide ne produit aucun fragment', () {
      expect(analyserTexteEnrichi(''), isEmpty);
    });

    test('**gras** au milieu d’une phrase', () {
      expect(analyserTexteEnrichi('Je suis **Amath**, votre assistant'), const [
        Fragment('Je suis '),
        Fragment('Amath', _g),
        Fragment(', votre assistant'),
      ]);
    });

    test('plusieurs gras sur une ligne, sans gourmandise', () {
      // Un motif gourmand avalerait « Amath**, du **Ministère » d'un bloc.
      expect(analyserTexteEnrichi('**Amath**, du **Ministère**'), const [
        Fragment('Amath', _g),
        Fragment(', du '),
        Fragment('Ministère', _g),
      ]);
    });

    test('*italique*', () {
      expect(analyserTexteEnrichi('mode *démonstration* actif'), const [
        Fragment('mode '),
        Fragment('démonstration', _i),
        Fragment(' actif'),
      ]);
    });

    test('une puce « * » ou une multiplication ne sont pas de l’italique', () {
      expect(analyserTexteEnrichi('* premier point'), const [
        Fragment('* premier point'),
      ]);
      expect(analyserTexteEnrichi('2 * 3 * 4'), const [Fragment('2 * 3 * 4')]);
    });

    test('les puces « • » et « - » restent telles quelles', () {
      const String texte = '• E-Carrière\n- **Matricule :** 123456A';
      expect(analyserTexteEnrichi(texte), const [
        Fragment('• E-Carrière\n- '),
        Fragment('Matricule :', _g),
        Fragment(' 123456A'),
      ]);
    });

    test('les retours à la ligne sont conservés', () {
      final String texte = analyserTexteEnrichi(
        'Ligne 1\nLigne 2\n\nLigne 4',
      ).map((f) => f.texte).join();
      expect(texte, 'Ligne 1\nLigne 2\n\nLigne 4');
    });

    test('un gras ne déborde pas sur la ligne suivante', () {
      // Le gras peut contenir n'importe quoi, sauf franchir un saut de ligne
      // qui le laisserait ouvert : `.` n'avale pas `\n`.
      expect(analyserTexteEnrichi('**ouvert\nfermé**'), const [
        Fragment('**ouvert\nfermé**'),
      ]);
    });

    test('un lien https devient cliquable, avec son libellé seul', () {
      final List<Fragment> f = analyserTexteEnrichi(
        'Connectez-vous [ici](https://emploi.fonctionpublique.sn/login).',
      );
      expect(f, [
        const Fragment('Connectez-vous '),
        Fragment(
          'ici',
          StyleFragment.lien,
          Uri.parse('https://emploi.fonctionpublique.sn/login'),
        ),
        const Fragment('.'),
      ]);
    });

    test('un lien http est accepté aussi', () {
      final Fragment lien = analyserTexteEnrichi(
        '[test](http://10.128.12.71:8080/x)',
      ).single;
      expect(lien.style, StyleFragment.lien);
      expect(lien.url, Uri.parse('http://10.128.12.71:8080/x'));
    });

    for (final String dangereux in <String>[
      'javascript:void0',
      'tel:+221330000000',
      'file:///etc/passwd',
      'intent://scan#Intent;end',
      '/chemin/relatif',
      'https:sans-hote',
    ]) {
      test('un lien « $dangereux » n’est pas cliquable', () {
        final List<Fragment> f = analyserTexteEnrichi(
          'Voir [cette page]($dangereux)',
        );
        expect(f, const [Fragment('Voir cette page')]);
        expect(f.every((x) => x.url == null), isTrue);
      });
    }

    test('le HTML n’est jamais interprété', () {
      const String html = '<b>gras</b> <a href="https://x.sn">lien</a>';
      expect(analyserTexteEnrichi(html), const [Fragment(html)]);
    });

    test('un astérisque orphelin reste visible', () {
      expect(analyserTexteEnrichi('**pas fermé'), const [
        Fragment('**pas fermé'),
      ]);
    });

    test('le texte réel de la salutation se découpe correctement', () {
      const String salutation =
          'Dalal ak Jàmm !\nJe suis **Amath**, votre assistant virtuel du '
          '**Ministère de la Fonction publique, du Travail et de la Réforme '
          'du Service public**.\nJe suis ravi de vous accueillir !';
      final List<Fragment> f = analyserTexteEnrichi(salutation);
      expect(f.where((x) => x.style == _g).map((x) => x.texte), [
        'Amath',
        'Ministère de la Fonction publique, du Travail et de la Réforme du '
            'Service public',
      ]);
      expect(f.map((x) => x.texte).join(), isNot(contains('*')));
      expect(f.first, const Fragment('Dalal ak Jàmm !\nJe suis ', _n));
    });
  });
}
