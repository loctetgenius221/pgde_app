import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../data/assistant_api.dart';
import '../data/historique_store.dart';
import '../domain/message.dart';

/// Échec d'un envoi, affiché en bulle à la fin du fil (contrat chatbot §7).
@immutable
class ErreurChat {
  const ErreurChat(this.texte, {this.aRenvoyer, this.enAttente = false});

  final String texte;

  /// Message que « Réessayer » renvoie **tel quel** ; `null` : rien à
  /// renvoyer, le bouton n'est pas proposé.
  final String? aRenvoyer;

  /// Vrai tant que le délai `Retry-After` d'un `429` court.
  final bool enAttente;

  @override
  bool operator ==(Object other) =>
      other is ErreurChat &&
      other.texte == texte &&
      other.aRenvoyer == aRenvoyer &&
      other.enAttente == enAttente;

  @override
  int get hashCode => Object.hash(texte, aRenvoyer, enAttente);
}

@immutable
class Conversation {
  const Conversation({
    this.messages = const <Message>[],
    this.etat = EtatAssistant.repos,
    this.sessionId,
    this.erreur,
  });

  final List<Message> messages;
  final EtatAssistant etat;
  final String? sessionId;
  final ErreurChat? erreur;

  bool get vierge => messages.isEmpty;

  Message? get dernierDeLAssistant {
    for (final Message m in messages.reversed) {
      if (m.vientDeLAssistant) return m;
    }
    return null;
  }

  /// Saisie libre fermée pendant un envoi, et tant que le dernier message
  /// d'Amath propose des boutons : il attend un choix, pas un texte (§5).
  bool get saisieBloquee =>
      etat.occupe || (dernierDeLAssistant?.boutons.isNotEmpty ?? false);

  /// Seuls les boutons du **dernier** message répondent : un vieux menu ne
  /// doit pas relancer une étape passée.
  bool boutonsActifs(int index) => !etat.occupe && index == messages.length - 1;

  /// Amath demande une CNI : un clavier numérique est proposé (§6).
  bool get attendUneCni =>
      RegExp(r'\bCNI\b').hasMatch(dernierDeLAssistant?.texte ?? '');

  Conversation copyWith({
    List<Message>? messages,
    EtatAssistant? etat,
    ErreurChat? erreur,
    bool effacerErreur = false,
  }) => Conversation(
    messages: messages ?? this.messages,
    etat: etat ?? this.etat,
    sessionId: sessionId,
    erreur: effacerErreur ? null : (erreur ?? this.erreur),
  );
}

/// Boucle de conversation avec Amath (contrat chatbot §3).
///
/// L'application n'invente aucun menu : elle affiche ce que le chatbot
/// renvoie et lui retourne le choix du candidat.
class ConversationController extends Notifier<Conversation> {
  /// Message d'ouverture, jamais affiché.
  static const String salutation = '/greet';
  static const int longueurMax = 1000;

  static const String indisponible = 'Amath est momentanément indisponible.';
  static const String tropDeMessages =
      'Trop de messages, patientez quelques secondes.';

  /// Incrémenté quand la conversation change de main (compte, ↻) : une
  /// réponse arrivée après coup appartient à l'ancienne et est ignorée.
  int _generation = 0;
  Timer? _reprise;

  @override
  Conversation build() {
    _generation++;
    _reprise?.cancel();
    ref.onDispose(() => _reprise?.cancel());
    // Le magasin suit le compte connecté : un changement de compte repart
    // de l'historique du nouveau candidat, jamais de celui du précédent.
    final Historique? historique = ref.watch(historiqueStoreProvider).lire();
    return historique == null
        ? const Conversation()
        : Conversation(
            messages: historique.messages,
            sessionId: historique.sessionId,
          );
  }

  /// À l'ouverture de l'écran : salue si rien n'est encore affiché.
  Future<void> ouvrir() async {
    if (state.vierge && !state.etat.occupe) await _transmettre(salutation);
  }

  /// Texte saisi par le candidat.
  Future<void> envoyer(String texte) async {
    final String message = texte.trim();
    if (message.isEmpty || state.saisieBloquee) return;
    if (message.length > longueurMax) {
      // Le serveur répondrait 422 : inutile de le solliciter.
      state = state.copyWith(
        erreur: const ErreurChat(
          'Ce message dépasse 1 000 caractères. Raccourcissez-le.',
        ),
      );
      return;
    }
    _ajouterCandidat(message);
    await _transmettre(message);
  }

  /// Bouton d'Amath : le titre s'affiche, le payload part sans retouche.
  Future<void> choisir(BoutonChat bouton) async {
    if (state.vierge ||
        !state.boutonsActifs(state.messages.length - 1) ||
        !state.messages.last.boutons.contains(bouton)) {
      return;
    }
    _ajouterCandidat(bouton.titre);
    await _transmettre(bouton.payload);
  }

  /// Renvoie le message qui a échoué, sans répéter la bulle du candidat.
  Future<void> reessayer() async {
    final String? message = state.erreur?.aRenvoyer;
    if (message == null || state.erreur!.enAttente || state.etat.occupe) {
      return;
    }
    await _transmettre(message);
  }

  /// Bouton ↻ : historique et session effacés, puis nouvelle salutation.
  Future<void> nouvelleConversation() async {
    _generation++;
    _reprise?.cancel();
    state = const Conversation();
    await ref.read(historiqueStoreProvider).purger();
    await _transmettre(salutation);
  }

  void _ajouterCandidat(String texte) => _publier(
    state.copyWith(
      messages: <Message>[
        ...state.messages,
        Message(locuteur: Locuteur.candidat, texte: texte),
      ],
      effacerErreur: true,
    ),
  );

  Future<void> _transmettre(String message) async {
    final int generation = _generation;
    final AssistantApi api = ref.read(assistantApiProvider);
    // Le magasin identifie le compte. Une réponse qui arrive après un
    // changement de compte ne doit ni s'afficher chez le suivant, ni
    // s'écrire dans **son** historique : le contrôleur n'est reconstruit
    // qu'à sa prochaine lecture, le compteur de génération ne suffit pas.
    final HistoriqueStore store = ref.read(historiqueStoreProvider);
    bool perimee() =>
        !ref.mounted ||
        generation != _generation ||
        !identical(store, ref.read(historiqueStoreProvider));

    state = state.copyWith(etat: EtatAssistant.reflexion, effacerErreur: true);
    try {
      final TourChatbot tour = await api.envoyer(
        message: message,
        sessionId: state.sessionId,
      );
      if (perimee()) return;
      _publier(
        Conversation(
          messages: <Message>[...state.messages, ...tour.messages],
          sessionId: tour.sessionId.isEmpty ? state.sessionId : tour.sessionId,
        ),
      );
    } on Object catch (e) {
      if (perimee()) return;
      state = state.copyWith(
        etat: EtatAssistant.repos,
        erreur: _erreurPour(e, message),
      );
    }
  }

  /// Affiche [conversation] et la garde sur l'appareil (§8).
  void _publier(Conversation conversation) {
    state = conversation;
    unawaited(
      ref
          .read(historiqueStoreProvider)
          .ecrire(
            Historique(
              sessionId: conversation.sessionId,
              messages: conversation.messages,
            ),
          ),
    );
  }

  ErreurChat _erreurPour(Object erreur, String message) {
    if (erreur is ApiException) {
      // Le texte du serveur dit déjà combien de temps attendre.
      if (erreur.isTooManyCniAttempts) return ErreurChat(erreur.message);
      if (erreur.statusCode == 429) {
        _programmerReprise(erreur.retryAfter);
        return ErreurChat(tropDeMessages, aRenvoyer: message, enAttente: true);
      }
      // Erreur de l'application, pas du réseau : la renvoyer échouerait
      // de la même façon.
      if (erreur.isValidation) {
        return const ErreurChat(
          'Ce message n’a pas pu être envoyé : il est vide ou trop long.',
        );
      }
    }
    return ErreurChat(indisponible, aRenvoyer: message);
  }

  void _programmerReprise(Duration? delai) {
    _reprise?.cancel();
    _reprise = Timer(delai ?? const Duration(seconds: 5), () {
      final ErreurChat? erreur = state.erreur;
      if (erreur == null || !erreur.enAttente) return;
      state = state.copyWith(
        erreur: ErreurChat(erreur.texte, aRenvoyer: erreur.aRenvoyer),
      );
    });
  }
}

final conversationProvider =
    NotifierProvider<ConversationController, Conversation>(
      ConversationController.new,
    );
