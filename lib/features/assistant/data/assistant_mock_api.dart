import '../domain/message.dart';
import 'assistant_api.dart';

/// Amath simulé, pour le mode démonstration hors ligne.
///
/// Il reproduit la **forme** des échanges du contrat — salutation, menus à
/// boutons, saisie libre de la CNI, liens — sans en reproduire le contenu :
/// côté application, aucun menu n'est codé en dur, c'est le serveur qui
/// décide.
class MockAssistantApi implements AssistantApi {
  @override
  Future<TourChatbot> envoyer({
    required String message,
    String? sessionId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return TourChatbot(
      sessionId: sessionId ?? '00000000-0000-4000-8000-000000000000',
      messages: <Message>[_repondre(message.trim())],
    );
  }

  static Message _repondre(String message) {
    final BoutonChat lu = BoutonChat(titre: '', payload: message);
    return switch (message.startsWith('/') ? lu.intention : null) {
      'greet' => _amath(
        'Dalal ak Jàmm !\nJe suis **Amath**, votre assistant virtuel du '
        '**Ministère de la Fonction publique**.\nPour mieux vous '
        'accompagner, pourriez-vous me communiquer votre nom ?',
      ),
      'go_back_greet_with_name' => _menuPrincipal('Que souhaitez-vous faire ?'),
      'choose_platform' => _amath(
        'Bienvenue sur **${lu.parametre('platform')}** !\n'
        'Avez-vous déjà un compte ?',
        const <BoutonChat>[
          BoutonChat(titre: 'Oui', payload: '/confirm_has_account'),
          BoutonChat(titre: 'Non', payload: '/deny_has_account'),
          _menu,
        ],
      ),
      'confirm_has_account' => _amath(
        'Veuillez renseigner votre numéro de carte nationale d’identité '
        '(**CNI**).\n**À retenir** : il comporte exactement 13 chiffres.',
      ),
      'deny_has_account' => _amath(
        'Créez votre compte sur le site : '
        '[emploi.fonctionpublique.sn](https://emploi.fonctionpublique.sn).',
        const <BoutonChat>[_menu, _support],
      ),
      'ask_support' => _amath(
        '*Mode démonstration* : les contacts du support s’affichent ici.',
        const <BoutonChat>[_menu],
      ),
      String() => _amath(
        'Cette action n’est pas disponible en démonstration.',
        const <BoutonChat>[_menu],
      ),
      null when RegExp(r'^\d{13}$').hasMatch(message) => _amath(
        '**Compte vérifié.** Que souhaitez-vous faire ?',
        const <BoutonChat>[_menu, _support],
      ),
      null when RegExp(r'^\d+$').hasMatch(message) => _amath(
        'Votre numéro de CNI doit comporter exactement 13 chiffres.',
      ),
      null => _menuPrincipal(
        'Bienvenue, $message !\n**Que souhaitez-vous faire aujourd’hui ?**',
      ),
    };
  }

  static Message _menuPrincipal(String texte) =>
      _amath(texte, const <BoutonChat>[
        BoutonChat(
          titre: 'E-Carrière',
          payload: '/choose_platform{"platform": "E-Carrière"}',
        ),
        BoutonChat(
          titre: 'Demande d’emploi (PGDE)',
          payload: '/choose_platform{"platform": "PGDE"}',
        ),
        BoutonChat(
          titre: 'Attestation de non appartenance',
          payload: '/choose_platform{"platform": "Attestation"}',
        ),
      ]);

  static Message _amath(
    String texte, [
    List<BoutonChat> boutons = const <BoutonChat>[],
  ]) => Message(locuteur: Locuteur.assistant, texte: texte, boutons: boutons);

  static const BoutonChat _menu = BoutonChat(
    titre: 'Menu principal',
    payload: '/go_back_greet_with_name',
  );
  static const BoutonChat _support = BoutonChat(
    titre: 'Support',
    payload: '/ask_support',
  );
}
