import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_dimens.dart';
import '../../../core/ui/bouton_dictee.dart';
import '../../../core/ui/icone.dart';
import '../../../core/ui/responsive.dart';
import '../application/conversation_controller.dart';
import '../domain/message.dart';
import 'entree_assistant.dart';
import 'icone_bouton_chat.dart';
import 'ndimbal.dart';
import 'texte_chatbot.dart';

/// Étiquette de la transition partagée entre l'accueil et cet écran.
///
/// Le même avatar traverse la navigation : le candidat suit du regard
/// l'élément sur lequel il vient d'appuyer, au lieu de subir un écran qui se
/// substitue à un autre.
const String heroNdimbal = 'ndimbal-avatar';

/// Conversation avec Amath, l'assistant virtuel du ministère.
///
/// L'écran ne connaît aucun parcours : il affiche les bulles et les boutons
/// que renvoie le chatbot (contrat chatbot §1).
class AssistantPage extends ConsumerStatefulWidget {
  const AssistantPage({super.key});

  @override
  ConsumerState<AssistantPage> createState() => _AssistantPageState();
}

class _AssistantPageState extends ConsumerState<AssistantPage> {
  final TextEditingController _saisie = TextEditingController();
  final ScrollController _defilement = ScrollController();

  /// Vrai le temps de la salutation d'ouverture : le personnage salue à
  /// l'arrivée, pendant que la première réponse se prépare.
  bool _salue = true;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 1900), () {
      if (mounted) setState(() => _salue = false);
    });
    // Après la première frame : on ne modifie pas un fournisseur pendant
    // la construction du widget qui l'écoute.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(conversationProvider.notifier).ouvrir();
      _versLeBas(anime: false);
    });
  }

  @override
  void dispose() {
    _saisie.dispose();
    _defilement.dispose();
    super.dispose();
  }

  void _envoyer() {
    final String texte = _saisie.text;
    if (texte.trim().isEmpty) return;
    _saisie.clear();
    ref.read(conversationProvider.notifier).envoyer(texte);
  }

  /// Suit la réponse qui arrive.
  ///
  /// Après la frame : la bulle n'a pas encore sa hauteur définitive au moment
  /// où l'état change, et on défilerait vers une position périmée.
  void _versLeBas({bool anime = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_defilement.hasClients) return;
      final double fin = _defilement.position.maxScrollExtent;
      if (anime) {
        _defilement.animateTo(
          fin,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      } else {
        _defilement.jumpTo(fin);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final Conversation conversation = ref.watch(conversationProvider);
    final ConversationController controleur = ref.read(
      conversationProvider.notifier,
    );
    ref.listen(conversationProvider, (_, _) => _versLeBas());

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: <Widget>[
            const PastilleNdimbal(taille: 36, anime: true),
            const SizedBox(width: Espace.sm),
            Expanded(child: _Entete(etat: conversation.etat)),
          ],
        ),
        actions: <Widget>[
          // Toujours actif, même pendant un envoi : c'est l'issue de secours
          // quand la conversation ne correspond plus à ce qu'attend Amath.
          IconButton(
            tooltip: 'Nouvelle conversation',
            onPressed: () {
              _saisie.clear();
              controleur.nouvelleConversation();
            },
            icon: const Icone(Icones.reessayer),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: _Fil(
                conversation: conversation,
                pose: _salue ? PoseNdimbal.salut : PoseNdimbal.sourire,
                controleur: _defilement,
                onBouton: controleur.choisir,
                onReessayer: controleur.reessayer,
              ),
            ),
            _BarreSaisie(
              controleur: _saisie,
              conversation: conversation,
              onEnvoyer: _envoyer,
            ),
          ],
        ),
      ),
    );
  }
}

/// Nom et état, sous le titre.
class _Entete extends StatelessWidget {
  const _Entete({required this.etat});

  final EtatAssistant etat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text('Amath', style: theme.textTheme.titleMedium),
        // L'état est **écrit**, pas seulement animé : une animation seule
        // n'est lisible ni par un lecteur d'écran ni par quelqu'un qui a
        // désactivé les animations.
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: Text(
            switch (etat) {
              EtatAssistant.repos => 'Assistant virtuel',
              EtatAssistant.reflexion => 'Amath écrit…',
            },
            key: ValueKey<EtatAssistant>(etat),
            style: theme.textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

/// Le fil : présentation d'Amath, bulles, indicateur de frappe, erreur.
class _Fil extends StatelessWidget {
  const _Fil({
    required this.conversation,
    required this.pose,
    required this.controleur,
    required this.onBouton,
    required this.onReessayer,
  });

  final Conversation conversation;
  final PoseNdimbal pose;
  final ScrollController controleur;
  final ValueChanged<BoutonChat> onBouton;
  final VoidCallback onReessayer;

  @override
  Widget build(BuildContext context) {
    final List<Message> messages = conversation.messages;
    final ErreurChat? erreur = conversation.erreur;

    return ListView(
      controller: controleur,
      padding: const EdgeInsets.only(bottom: Espace.md),
      children: <Widget>[
        _Presentation(pose: pose),
        for (int i = 0; i < messages.length; i++)
          _Bulle(
            message: messages[i],
            boutonsActifs: conversation.boutonsActifs(i),
            onBouton: onBouton,
          ),
        if (conversation.etat.occupe) const _Frappe(),
        if (erreur != null && !conversation.etat.occupe)
          _BulleErreur(erreur: erreur, onReessayer: onReessayer),
      ],
    );
  }
}

/// Le personnage en tête du fil — point d'arrivée de la transition depuis
/// l'accueil.
class _Presentation extends StatelessWidget {
  const _Presentation({required this.pose});

  final PoseNdimbal pose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final double taille = context.selonFormat<double>(
      telephone: 96,
      tablette: 120,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Espace.md,
        Espace.lg,
        Espace.md,
        Espace.md,
      ),
      child: Column(
        children: <Widget>[
          Hero(
            tag: heroNdimbal,
            // `FittedBox` : le vol interpole un rectangle, de la taille
            // qu'occupait le personnage dans le coin de l'accueil à celle-ci.
            flightShuttleBuilder: (_, _, _, _, _) => FittedBox(
              fit: BoxFit.contain,
              child: Ndimbal(pose: pose, taille: taille),
            ),
            child: Ndimbal(taille: taille, pose: pose),
          ),
          const SizedBox(height: Espace.sm),
          Text('Amath', style: theme.textTheme.titleMedium),
          Text(
            'Assistant virtuel du ministère de la Fonction publique',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// Alignement et pastille d'une bulle, selon qui parle.
class _Ligne extends StatelessWidget {
  const _Ligne({required this.deLAssistant, required this.child});

  final bool deLAssistant;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      Espace.md,
      Espace.xxs,
      Espace.md,
      Espace.xxs,
    ),
    child: Row(
      mainAxisAlignment: deLAssistant
          ? MainAxisAlignment.start
          : MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        if (deLAssistant) ...<Widget>[
          const PastilleNdimbal(),
          const SizedBox(width: Espace.xs),
        ],
        Flexible(child: child),
      ],
    ),
  );
}

/// Forme d'une bulle : coin pointu du côté de celui qui parle.
BoxDecoration _forme(Color couleur, {required bool deLAssistant}) =>
    BoxDecoration(
      color: couleur,
      borderRadius: BorderRadius.only(
        topLeft: const Radius.circular(Rayon.lg),
        topRight: const Radius.circular(Rayon.lg),
        bottomLeft: Radius.circular(deLAssistant ? Rayon.sm : Rayon.lg),
        bottomRight: Radius.circular(deLAssistant ? Rayon.lg : Rayon.sm),
      ),
    );

class _Bulle extends StatelessWidget {
  const _Bulle({
    required this.message,
    required this.boutonsActifs,
    required this.onBouton,
  });

  final Message message;
  final bool boutonsActifs;
  final ValueChanged<BoutonChat> onBouton;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool deLAssistant = message.vientDeLAssistant;
    final TextStyle? style = theme.textTheme.bodyLarge?.copyWith(
      color: deLAssistant
          ? theme.colorScheme.onSurface
          : theme.colorScheme.onPrimary,
      height: 1.4,
    );

    return _Ligne(
      deLAssistant: deLAssistant,
      child: Column(
        crossAxisAlignment: deLAssistant
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.end,
        children: <Widget>[
          if (message.texte.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxWidth: 520),
              padding: const EdgeInsets.symmetric(
                horizontal: Espace.md,
                vertical: Espace.sm,
              ),
              decoration: _forme(
                deLAssistant
                    ? theme.colorScheme.surfaceContainerHighest
                    : theme.colorScheme.primary,
                deLAssistant: deLAssistant,
              ),
              // Le candidat s'affiche en texte brut : ce qu'il tape n'est
              // jamais interprété.
              child: deLAssistant
                  ? TexteChatbot(message.texte, style: style)
                  : Text(message.texte, style: style),
            ),
          if (message.imageUrl case final String url)
            Padding(
              padding: const EdgeInsets.only(top: Espace.xxs),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(Rayon.lg),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 280),
                  child: CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.cover,
                    errorWidget: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          if (message.boutons.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: Espace.xs),
              child: Wrap(
                spacing: Espace.xs,
                runSpacing: Espace.xs,
                children: <Widget>[
                  for (final BoutonChat bouton in message.boutons)
                    _BoutonAmath(
                      bouton: bouton,
                      onPressed: boutonsActifs ? () => onBouton(bouton) : null,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _BoutonAmath extends StatelessWidget {
  const _BoutonAmath({required this.bouton, required this.onPressed});

  final BoutonChat bouton;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final DonneesIcone? icone = iconeDuBouton(bouton);
    final Widget libelle = Text(bouton.titre);
    final ButtonStyle style = OutlinedButton.styleFrom(
      minimumSize: const Size(0, 40),
      padding: const EdgeInsets.symmetric(horizontal: Espace.md),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Rayon.pilule),
      ),
      visualDensity: VisualDensity.compact,
    );

    return icone == null
        ? OutlinedButton(onPressed: onPressed, style: style, child: libelle)
        : OutlinedButton.icon(
            onPressed: onPressed,
            style: style,
            icon: Icone(icone, taille: 16),
            label: libelle,
          );
  }
}

/// Échec d'un envoi : la bulle du candidat reste affichée au-dessus.
class _BulleErreur extends StatelessWidget {
  const _BulleErreur({required this.erreur, required this.onReessayer});

  final ErreurChat erreur;
  final VoidCallback onReessayer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _Ligne(
      deLAssistant: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            constraints: const BoxConstraints(maxWidth: 520),
            padding: const EdgeInsets.symmetric(
              horizontal: Espace.md,
              vertical: Espace.sm,
            ),
            decoration: _forme(
              theme.colorScheme.errorContainer,
              deLAssistant: true,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icone(
                  Icones.alerte,
                  taille: 18,
                  couleur: theme.colorScheme.onErrorContainer,
                ),
                const SizedBox(width: Espace.xs),
                Flexible(
                  child: Text(
                    erreur.texte,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (erreur.aRenvoyer != null)
            Padding(
              padding: const EdgeInsets.only(top: Espace.xs),
              child: OutlinedButton.icon(
                onPressed: erreur.enAttente ? null : onReessayer,
                icon: const Icone(Icones.reessayer, taille: 16),
                label: const Text('Réessayer'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Rayon.pilule),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Trois points qui respirent, le temps que la réponse arrive.
class _Frappe extends StatefulWidget {
  const _Frappe();

  @override
  State<_Frappe> createState() => _FrappeState();
}

class _FrappeState extends State<_Frappe> with SingleTickerProviderStateMixin {
  late final AnimationController _controleur = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _controleur.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: 'Amath écrit…',
      child: _Ligne(
        deLAssistant: true,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Espace.md,
            vertical: Espace.sm + 2,
          ),
          decoration: _forme(
            theme.colorScheme.surfaceContainerHighest,
            deLAssistant: true,
          ),
          child: AnimatedBuilder(
            animation: _controleur,
            builder: (context, _) => Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                for (int i = 0; i < 3; i++)
                  Padding(
                    padding: EdgeInsets.only(right: i == 2 ? 0 : 5),
                    child: Opacity(
                      // Décalage d'un tiers de cycle par point : l'onde
                      // court de gauche à droite.
                      opacity: 0.3 + 0.7 * _intensite(i),
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  double _intensite(int index) {
    final double phase = (_controleur.value - index / 3) % 1;
    return phase < 0.5 ? (1 - (phase * 4 - 1).abs()).clamp(0, 1) : 0;
  }
}

class _BarreSaisie extends StatelessWidget {
  const _BarreSaisie({
    required this.controleur,
    required this.conversation,
    required this.onEnvoyer,
  });

  final TextEditingController controleur;
  final Conversation conversation;
  final VoidCallback onEnvoyer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool actif = !conversation.saisieBloquee;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        Espace.md,
        Espace.xs,
        Espace.md,
        Espace.md,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: ConteneurPage(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: controleur,
                enabled: actif,
                minLines: 1,
                maxLines: 4,
                maxLength: ConversationController.longueurMax,
                // Le plafond est appliqué sans compteur : il n'est atteint
                // qu'exceptionnellement et encombrerait chaque saisie.
                buildCounter:
                    (
                      _, {
                      required currentLength,
                      required isFocused,
                      maxLength,
                    }) => null,
                // Clavier numérique proposé pour une CNI, jamais imposé par
                // une validation : c'est Amath qui vérifie le format.
                keyboardType: conversation.attendUneCni
                    ? TextInputType.number
                    : TextInputType.text,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onEnvoyer(),
                decoration: InputDecoration(
                  hintText: conversation.etat.occupe
                      ? 'Amath écrit…'
                      : actif
                      ? 'Écrivez votre message…'
                      : 'Utilisez les boutons ci-dessus…',
                  // Dicter sa réponse : le geste naturel face à un
                  // assistant. Absent quand la saisie est fermée.
                  suffixIcon: actif
                      ? BoutonDictee(
                          texteActuel: () => controleur.text,
                          onTexte: (texte) =>
                              controleur.value = TextEditingValue(
                                text: texte,
                                selection: TextSelection.collapsed(
                                  offset: texte.length,
                                ),
                              ),
                          longueurMax: ConversationController.longueurMax,
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(width: Espace.xs),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controleur,
              builder: (context, valeur, _) {
                final bool pret = actif && valeur.text.trim().isNotEmpty;
                return IconButton.filled(
                  onPressed: pret ? onEnvoyer : null,
                  tooltip: 'Envoyer',
                  iconSize: 22,
                  style: IconButton.styleFrom(
                    minimumSize: const Size.square(50),
                  ),
                  icon: const Icone(Icones.envoyer, taille: 22),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
