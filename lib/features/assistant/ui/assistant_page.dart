import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_dimens.dart';
import '../../../core/ui/icone.dart';
import '../../../core/ui/responsive.dart';
import '../application/conversation_controller.dart';
import '../domain/message.dart';
import 'entree_assistant.dart';
import 'ndimbal.dart';

/// Étiquette de la transition partagée entre l'accueil et cet écran.
///
/// Le même avatar traverse la navigation : le candidat suit du regard
/// l'élément sur lequel il vient d'appuyer, au lieu de subir un écran qui se
/// substitue à un autre.
const String heroNdimbal = 'ndimbal-avatar';

/// Conversation avec Ndimbal.
class AssistantPage extends ConsumerStatefulWidget {
  const AssistantPage({super.key});

  @override
  ConsumerState<AssistantPage> createState() => _AssistantPageState();
}

class _AssistantPageState extends ConsumerState<AssistantPage> {
  final TextEditingController _saisie = TextEditingController();
  final ScrollController _defilement = ScrollController();

  /// Vrai le temps de la salutation d'ouverture (§F, « GREETING »).
  ///
  /// On salue **à l'arrivée** plutôt qu'avant de naviguer : retarder l'écran
  /// de huit dixièmes de seconde pour jouer une animation rendrait l'appui
  /// mou. Ici le geste répond tout de suite, et la politesse se fait pendant
  /// que l'écran s'installe.
  bool _salue = true;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 1900), () {
      if (mounted) setState(() => _salue = false);
    });
    _saisie.addListener(() => setState(() {}));
  }

  /// La pose du personnage — distincte de l'état de la conversation : il
  /// salue à l'arrivée, puis garde le sourire tant qu'on lui parle. Sur
  /// l'accueil, il reste en veille, bouche droite.
  PoseNdimbal get _pose => _salue ? PoseNdimbal.salut : PoseNdimbal.sourire;

  @override
  void dispose() {
    _saisie.dispose();
    _defilement.dispose();
    super.dispose();
  }

  void _envoyer([String? suggestion, String? payload]) {
    final String texte = suggestion ?? _saisie.text;
    if (texte.trim().isEmpty) return;
    _saisie.clear();
    ref.read(conversationProvider.notifier).envoyer(texte, payload: payload);
    _versLeBas();
  }

  /// Suit la réponse qui s'écrit.
  ///
  /// Après la frame : la bulle n'a pas encore sa hauteur définitive au moment
  /// où l'état change, et on défilerait vers une position périmée.
  void _versLeBas() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_defilement.hasClients) return;
      _defilement.animateTo(
        _defilement.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final Conversation conversation = ref.watch(conversationProvider);
    ref.listen(conversationProvider, (_, _) => _versLeBas());

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: <Widget>[
            // Le visage seul : à cette taille, le personnage entier ne
            // serait qu'une tache.
            const PastilleNdimbal(taille: 36, anime: true),
            const SizedBox(width: Espace.sm),
            Expanded(child: _Entete(etat: conversation.etat)),
          ],
        ),
        actions: <Widget>[
          if (!conversation.vierge)
            IconButton(
              tooltip: 'Nouvelle conversation',
              onPressed: () =>
                  ref.read(conversationProvider.notifier).reinitialiser(),
              icon: const Icone(Icones.nouvelleConversation),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: conversation.vierge
                  ? _Accueil(pose: _pose, onSuggestion: _envoyer)
                  : _Fil(
                      conversation: conversation,
                      controleur: _defilement,
                      onBouton: (bouton) =>
                          _envoyer(bouton.titre, bouton.payload),
                    ),
            ),
            if (conversation.erreur case final String erreur)
              _BandeauErreur(erreur),
            _BarreSaisie(
              controleur: _saisie,
              actif: !conversation.etat.occupe,
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
        Text('Ndimbal', style: theme.textTheme.titleMedium),
        // L'état est **écrit**, pas seulement animé : une animation seule
        // n'est lisible ni par un lecteur d'écran ni par quelqu'un qui a
        // désactivé les animations.
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: Text(
            switch (etat) {
              EtatAssistant.repos => 'Assistant de la plateforme',
              EtatAssistant.reflexion => 'Réfléchit…',
            },
            key: ValueKey<EtatAssistant>(etat),
            style: theme.textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

/// Premier écran : l'avatar en grand, et de quoi démarrer sans réfléchir.
class _Accueil extends StatelessWidget {
  const _Accueil({required this.pose, required this.onSuggestion});

  final PoseNdimbal pose;
  final ValueChanged<String> onSuggestion;

  static const List<String> _suggestions = <String>[
    'Quelles pièces dois-je fournir ?',
    'Comment remplir mes formations ?',
    'Où en est mon dossier ?',
    'Je n’ai pas de diplôme, que faire ?',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: ConteneurPage(
        child: Column(
          children: <Widget>[
            const SizedBox(height: Espace.lg),
            Hero(
              tag: heroNdimbal,
              // `FittedBox` : le vol interpole un rectangle, de la taille
              // qu'occupait le personnage dans le coin de l'accueil à
              // celle-ci. Sans lui, il garderait sa taille d'arrivée pendant
              // tout le trajet et sauterait au départ.
              flightShuttleBuilder: (_, _, _, _, _) => FittedBox(
                fit: BoxFit.contain,
                child: Ndimbal(pose: pose, taille: 150),
              ),
              child: Ndimbal(
                taille: context.selonFormat<double>(
                  telephone: 132,
                  tablette: 150,
                ),
                pose: pose,
              ),
            ),
            const SizedBox(height: Espace.md),
            Text(
              'Comment puis-je vous aider ?',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: Espace.xs),
            Text(
              'Je réponds sur votre dossier de demande d’emploi.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: Espace.xl),

            // Des questions toutes faites plutôt qu'un champ vide : c'est ce
            // qui lève la « page blanche », le premier obstacle de tout
            // assistant conversationnel.
            for (final String suggestion in _suggestions)
              Padding(
                padding: const EdgeInsets.only(bottom: Espace.xs),
                child: _Suggestion(
                  texte: suggestion,
                  onTap: () => onSuggestion(suggestion),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Suggestion extends StatelessWidget {
  const _Suggestion({required this.texte, required this.onTap});

  final String texte;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(Rayon.pilule),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Rayon.pilule),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Rayon.pilule),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Espace.md,
              vertical: Espace.sm,
            ),
            child: Row(
              children: <Widget>[
                Expanded(child: Text(texte, style: theme.textTheme.bodyMedium)),
                Icone(
                  Icones.suivant,
                  taille: 18,
                  couleur: theme.colorScheme.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Le fil de l'échange.
class _Fil extends StatelessWidget {
  const _Fil({
    required this.conversation,
    required this.controleur,
    required this.onBouton,
  });

  final Conversation conversation;
  final ScrollController controleur;
  final ValueChanged<BoutonChat> onBouton;

  @override
  Widget build(BuildContext context) {
    final bool attend = conversation.etat == EtatAssistant.reflexion;

    return ListView.builder(
      controller: controleur,
      padding: const EdgeInsets.symmetric(vertical: Espace.md),
      itemCount: conversation.messages.length + (attend ? 1 : 0),
      itemBuilder: (context, i) {
        if (i == conversation.messages.length) return const _Frappe();
        return _Bulle(message: conversation.messages[i], onBouton: onBouton);
      },
    );
  }
}

class _Bulle extends StatelessWidget {
  const _Bulle({required this.message, required this.onBouton});

  final Message message;
  final ValueChanged<BoutonChat> onBouton;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool deNdimbal = message.vientDeNdimbal;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Espace.md,
        Espace.xxs,
        Espace.md,
        Espace.xxs,
      ),
      child: Row(
        mainAxisAlignment: deNdimbal
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          if (deNdimbal) ...<Widget>[
            const PastilleNdimbal(),
            const SizedBox(width: Espace.xs),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: deNdimbal
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
                    decoration: BoxDecoration(
                      color: deNdimbal
                          ? theme.colorScheme.surfaceContainerHighest
                          : theme.colorScheme.primary,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(Rayon.lg),
                        topRight: const Radius.circular(Rayon.lg),
                        bottomLeft: Radius.circular(
                          deNdimbal ? Rayon.sm : Rayon.lg,
                        ),
                        bottomRight: Radius.circular(
                          deNdimbal ? Rayon.lg : Rayon.sm,
                        ),
                      ),
                    ),
                    child: Text(
                      message.texte,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: deNdimbal
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.onPrimary,
                        height: 1.4,
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
                          ActionChip(
                            label: Text(bouton.titre),
                            onPressed: () => onBouton(bouton),
                          ),
                      ],
                    ),
                  ),
              ],
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(Espace.md, Espace.xxs, 0, Espace.xxs),
      child: Row(
        children: <Widget>[
          const PastilleNdimbal(anime: true),
          const SizedBox(width: Espace.xs),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Espace.md,
              vertical: Espace.sm + 2,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(Rayon.lg),
                topRight: Radius.circular(Rayon.lg),
                bottomLeft: Radius.circular(Rayon.sm),
                bottomRight: Radius.circular(Rayon.lg),
              ),
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
        ],
      ),
    );
  }

  double _intensite(int index) {
    final double phase = (_controleur.value - index / 3) % 1;
    return phase < 0.5 ? (1 - (phase * 4 - 1).abs()).clamp(0, 1) : 0;
  }
}

class _BandeauErreur extends StatelessWidget {
  const _BandeauErreur(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(Espace.md, 0, Espace.md, Espace.xs),
      padding: const EdgeInsets.all(Espace.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(Rayon.md),
      ),
      child: Row(
        children: <Widget>[
          Icone(
            Icones.alerte,
            taille: 18,
            couleur: theme.colorScheme.onErrorContainer,
          ),
          const SizedBox(width: Espace.xs),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BarreSaisie extends StatelessWidget {
  const _BarreSaisie({
    required this.controleur,
    required this.actif,
    required this.onEnvoyer,
  });

  final TextEditingController controleur;
  final bool actif;
  final VoidCallback onEnvoyer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onEnvoyer(),
                decoration: const InputDecoration(
                  hintText: 'Posez votre question…',
                ),
              ),
            ),
            const SizedBox(width: Espace.xs),
            // Le bouton se désactive pendant la réponse : deux flux
            // concurrents entrelaceraient leurs mots dans la même bulle.
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
