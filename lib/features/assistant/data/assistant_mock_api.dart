import '../domain/message.dart';
import 'assistant_api.dart';

/// Réponses locales, pour le mode démonstration hors ligne.
class MockAssistantApi implements AssistantApi {
  @override
  Future<TourChatbot> envoyer({
    required String message,
    String? sessionId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return TourChatbot(
      sessionId: sessionId ?? 'mock-session',
      messages: <Message>[
        Message(locuteur: Locuteur.ndimbal, texte: _choisir(message)),
      ],
    );
  }

  String _choisir(String question) {
    final String q = _sansAccent(question.toLowerCase());
    for (final _Reponse r in _catalogue) {
      if (r.motsCles.any(q.contains)) return r.texte;
    }
    return 'Je ne suis pas sûr de bien comprendre. Je peux vous aider sur '
        'les pièces à fournir, les étapes du dossier, les vœux '
        'd’emploi et le suivi de votre demande. Que souhaitez-vous '
        'savoir ?';
  }

  static String _sansAccent(String texte) {
    const String avec = 'àâäéèêëîïôöùûüç';
    const String sans = 'aaaeeeeiioouuuc';
    final StringBuffer sortie = StringBuffer();
    for (final int unite in texte.runes) {
      final int i = avec.indexOf(String.fromCharCode(unite));
      sortie.write(i == -1 ? String.fromCharCode(unite) : sans[i]);
    }
    return sortie.toString();
  }

  static const List<_Reponse> _catalogue = <_Reponse>[
    _Reponse(
      <String>['bonjour', 'salut', 'bonsoir', 'nanga def', 'coucou'],
      'Bonjour ! Je suis Ndimbal, l’assistant de la plateforme. Je peux '
      'vous guider dans la constitution de votre dossier de demande '
      'd’emploi. Par quoi commençons-nous ?',
    ),
    _Reponse(
      <String>['qui es tu', 'qui est tu', 'ndimbal', 'tu es qui', 'ton nom'],
      'Je m’appelle Ndimbal — « aide », en wolof. Je réponds aux questions '
      'sur votre dossier de demande d’emploi dans la fonction publique. '
      'Je ne traite aucun dossier moi-même : les décisions reviennent au '
      'ministère.',
    ),
    _Reponse(
      <String>['piece', 'document', 'justificatif', 'fournir', 'joindre'],
      'Deux pièces vous sont demandées. Une photo de profil, à l’étape 1 : '
      'JPG, PNG ou WEBP, 4 Mo maximum. Et un justificatif par formation, '
      'à l’étape 2 : PDF, image ou DOCX, 8 Mo maximum. La photo d’un '
      'diplôme est acceptée.',
    ),
    _Reponse(
      <String>['etape', 'commencer', 'demarrer', 'remplir', 'formulaire'],
      'Le dossier tient en quatre étapes : identité et résidence, '
      'formations et documents, expériences professionnelles, puis vœux '
      'd’emploi. Vous pouvez les remplir dans l’ordre que vous voulez et '
      'revenir plus tard : votre saisie est conservée.',
    ),
    _Reponse(
      <String>['voeu', 'emploi souhaite', 'metier', 'poste souhaite'],
      'Vous choisissez deux métiers, à l’étape 4, et ils doivent être '
      'différents. Sélectionnez d’abord un secteur, puis le métier dans '
      'ce secteur. Vous pouvez indiquer pour chacun vos années '
      'd’expérience.',
    ),
    _Reponse(
      <String>['diplome', 'formation', 'etude', 'niveau', 'sans diplome'],
      'Ajoutez une formation par diplôme obtenu, en commençant par le plus '
      'élevé. Si vous n’avez pas de diplôme, choisissez « Sans diplôme » '
      'dans la liste : les champs inutiles disparaissent et aucun '
      'justificatif ne vous est demandé.',
    ),
    _Reponse(
      <String>['experience', 'travaille', 'emploi precedent', 'employeur'],
      'À l’étape 3, répondez d’abord si vous avez déjà travaillé. Si oui, '
      'décrivez chaque expérience : poste, employeur, durée. Une '
      'expérience sans poste ni employeur ni description ne serait pas '
      'enregistrée.',
    ),
    _Reponse(
      <String>['handicap'],
      'La question figure à l’étape 1. Si vous répondez oui, un second champ '
      'apparaît pour préciser le type de handicap. Cette information sert '
      'aux dispositifs d’accompagnement prévus par la loi.',
    ),
    _Reponse(
      <String>['delai', 'combien de temps', 'reponse', 'quand', 'attente'],
      'Le dépôt est possible toute l’année. Les délais d’instruction '
      'dépendent du ministère et ne sont pas fixés dans l’application. '
      'Vous serez informé par email à chaque changement d’état de votre '
      'dossier.',
    ),
    _Reponse(
      <String>['suivi', 'statut', 'ou en est', 'avancement', 'progression'],
      'L’écran d’accueil affiche l’état de chaque étape et le nombre '
      'd’étapes complétées. Tant que votre dossier n’est pas enregistré, '
      'il reste modifiable à tout moment.',
    ),
    _Reponse(
      <String>['mot de passe', 'connexion', 'connecter', 'identifiant'],
      'Vous vous connectez avec votre email **ou** votre nom d’utilisateur, '
      'au choix. Si vous avez oublié votre mot de passe, utilisez le lien '
      '« Mot de passe oublié ? » sur l’écran de connexion : un lien de '
      'réinitialisation vous sera envoyé par email.',
    ),
    _Reponse(
      <String>['modifier', 'corriger', 'erreur', 'changer'],
      'Tant que le dossier n’est pas transmis, tout reste modifiable : '
      'ouvrez l’étape concernée depuis l’accueil et corrigez. Une fois '
      'enregistré, le bouton « Modifier mon dossier » vous y ramène.',
    ),
    _Reponse(<String>[
      'merci',
      'parfait',
      'super',
      'jerejef',
    ], 'Avec plaisir. N’hésitez pas si une autre question se présente.'),
  ];
}

class _Reponse {
  const _Reponse(this.motsCles, this.texte);

  final List<String> motsCles;
  final String texte;
}
