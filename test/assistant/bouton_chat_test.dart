import 'package:flutter_test/flutter_test.dart';
import 'package:pgde_app/core/ui/icone.dart';
import 'package:pgde_app/features/assistant/domain/message.dart';
import 'package:pgde_app/features/assistant/ui/icone_bouton_chat.dart';

BoutonChat _b(String payload, [String titre = 'Libellé']) =>
    BoutonChat(titre: titre, payload: payload);

void main() {
  group('Intention d’un bouton', () {
    test('le texte entre « / » et « { »', () {
      expect(
        _b('/choose_platform{"platform": "PGDE"}').intention,
        'choose_platform',
      );
    });

    test('sans paramètre, tout le payload après « / »', () {
      expect(_b('/voir_actes').intention, 'voir_actes');
    });

    test('sans barre initiale', () {
      expect(_b('ask_support').intention, 'ask_support');
    });

    test('paramètre lu dans le JSON, accents compris', () {
      expect(
        _b('/choose_platform{"platform": "E-Carrière"}').parametre('platform'),
        'E-Carrière',
      );
    });

    test('paramètre absent ou JSON illisible : null, sans erreur', () {
      expect(_b('/voir_actes').parametre('platform'), isNull);
      expect(_b('/choose_platform{"autre": 1}').parametre('platform'), isNull);
      expect(_b('/choose_platform{cassé').parametre('platform'), isNull);
      expect(_b('/choose_platform[]{').parametre('platform'), isNull);
    });
  });

  group('Icône d’un bouton (contrat §5)', () {
    final Map<String, DonneesIcone> attendu = <String, DonneesIcone>{
      '/go_back_greet_with_name': Icones.maison,
      '/go_back_ecarriere': Icones.retour,
      '/go_back_pgde': Icones.retour,
      '/retour_menu_utilisateur': Icones.retour,
      '/ask_support': Icones.telephone,
      '/start_account_verification': Icones.reessayer,
      '/confirm_has_account': Icones.valide,
      '/confirm_has_access': Icones.valide,
      '/confirm_password_reset': Icones.valide,
      '/confirm_reset_ecarriere': Icones.valide,
      '/deny_has_account': Icones.croix,
      '/deny_has_access': Icones.croix,
      '/deny_password_reset': Icones.croix,
      '/cancel_reset_ecarriere': Icones.croix,
      '/ask_account_creation': Icones.ajoutCompte,
      '/ask_attestation_account': Icones.ajoutCompte,
      '/ask_login': Icones.connexion,
      '/ask_password_reset': Icones.cle,
      '/reset_password_ecarriere': Icones.cle,
      '/voir_actes': Icones.document,
      '/ask_attestation_request': Icones.document,
      '/voir_projets': Icones.graphique,
      '/ask_attestation_info': Icones.info,
      '/ask_attestation_status': Icones.horloge,
      '/choose_platform{"platform": "E-Carrière"}': Icones.poste,
      '/choose_platform{"platform": "PGDE"}': Icones.identifiant,
      '/choose_platform{"platform": "Attestation"}': Icones.document,
    };

    attendu.forEach((payload, icone) {
      test(payload, () => expect(iconeDuBouton(_b(payload)), icone));
    });

    test('l’icône suit le payload, jamais le libellé', () {
      // Libellé trompeur : c'est l'intention qui décide.
      expect(
        iconeDuBouton(_b('/ask_support', 'Menu principal')),
        Icones.telephone,
      );
      expect(iconeDuBouton(_b('/inconnue', 'Support')), isNull);
    });

    test('intention ou plateforme inconnue : pas d’icône, pas d’erreur', () {
      expect(iconeDuBouton(_b('/nouvelle_intention_2027')), isNull);
      expect(
        iconeDuBouton(_b('/choose_platform{"platform": "Autre"}')),
        isNull,
      );
      expect(iconeDuBouton(_b('/choose_platform')), isNull);
      expect(iconeDuBouton(_b('')), isNull);
    });
  });

  group('Sérialisation de l’historique', () {
    test('un message et ses boutons survivent à l’aller-retour JSON', () {
      const Message m = Message(
        locuteur: Locuteur.assistant,
        texte: '**Oui** ?',
        imageUrl: 'https://exemple.sn/a.png',
        boutons: <BoutonChat>[
          BoutonChat(titre: 'Oui', payload: '/confirm_has_account'),
          BoutonChat(
            titre: 'PGDE',
            payload: '/choose_platform{"platform": "PGDE"}',
          ),
        ],
      );
      expect(Message.fromJson(m.toJson()), m);
    });

    test('une bulle du candidat garde son locuteur', () {
      const Message m = Message(locuteur: Locuteur.candidat, texte: 'Awa');
      expect(Message.fromJson(m.toJson()), m);
    });

    test('champs absents : valeurs neutres', () {
      final Message m = Message.fromJson(const <String, dynamic>{});
      expect(m.vientDeLAssistant, isTrue);
      expect(m.texte, '');
      expect(m.boutons, isEmpty);
      expect(m.imageUrl, isNull);
    });
  });
}
