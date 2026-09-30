import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/message.dart';
import 'assistant_mock_api.dart';

/// L'assistant conversationnel du dossier candidat.
///
/// La réponse arrive en **flux**, morceau par morceau. C'est la forme que
/// prennent les API de génération de texte, et c'est aussi la seule qui
/// permette d'afficher les premiers mots tout de suite : sur un réseau
/// sénégalais, attendre la réponse entière avant d'afficher quoi que ce soit
/// donnerait un écran figé pendant plusieurs secondes.
///
/// L'interface est écrite pour ce flux dès maintenant, alors même que le
/// backend n'existe pas : la poser plus tard obligerait à réécrire l'écran.
abstract interface class AssistantApi {
  /// Réponse à [question], en tenant compte de l'[historique].
  ///
  /// Chaque événement du flux est un **fragment à concaténer**, jamais la
  /// réponse complète : c'est ce que rend un serveur qui diffuse.
  Stream<String> repondre({
    required String question,
    required List<Message> historique,
  });
}

/// Point de bascule unique entre le faux assistant et le vrai.
///
/// Aucune implémentation HTTP pour l'instant : le contrat d'interface v1
/// n'expose pas d'endpoint d'assistant. Le jour où il en exposera un, seule
/// cette ligne change.
final assistantApiProvider = Provider<AssistantApi>(
  (ref) => MockAssistantApi(),
);
