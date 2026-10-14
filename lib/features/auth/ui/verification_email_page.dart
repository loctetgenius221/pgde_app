import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/env.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/ui/form_submission.dart';
import '../../../core/ui/icone.dart';
import '../../../core/ui/responsive.dart';
import '../application/auth_controller.dart';
import '../data/auth_mock_api.dart';
import '../domain/utilisateur.dart';

/// Écran d'activation de compte — conforme au contrat d'API mobile §3.2.
///
/// L'API transmet un lien d'activation par e-mail (sans code OTP in-app). L'utilisateur
/// doit ouvrir le lien dans son navigateur / sa messagerie, puis se connecter.
/// La route `POST /auth/resend-verification` permet de renvoyer un nouveau lien.
class VerificationEmailPage extends ConsumerStatefulWidget {
  const VerificationEmailPage({super.key, this.email});

  final String? email;

  @override
  ConsumerState<VerificationEmailPage> createState() =>
      _VerificationEmailPageState();
}

class _VerificationEmailPageState extends ConsumerState<VerificationEmailPage>
    with FormSubmission {
  late final TextEditingController _emailController;
  final _formKey = GlobalKey<FormState>();

  bool _modeEdition = false;
  int _cooldownSecondes = 0;
  Timer? _cooldownTimer;
  bool _dernierEnvoiReussi = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.email ?? '');
    // Si aucune adresse n'a été fournie, on ouvre directement le champ de saisie.
    _modeEdition = (widget.email == null || widget.email!.trim().isEmpty);
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _emailController.dispose();
    super.dispose();
  }

  String _recupererAdresse() {
    final utilisateur = ref.read(utilisateurConnecteProvider);
    final String texteSaisi = _emailController.text.trim();
    if (texteSaisi.isNotEmpty) return texteSaisi;
    return (utilisateur?.email ?? widget.email ?? '').trim();
  }

  void _annoncer(String message, {bool succes = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: succes
              ? Theme.of(context).colorScheme.primary
              : null,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void _demarrerCooldown([int secondes = 60]) {
    _cooldownTimer?.cancel();
    setState(() {
      _cooldownSecondes = secondes;
      _dernierEnvoiReussi = true;
    });
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_cooldownSecondes > 1) {
          _cooldownSecondes--;
        } else {
          _cooldownSecondes = 0;
          timer.cancel();
        }
      });
    });
  }

  Future<void> _renvoyer() async {
    if (_modeEdition && !_formKey.currentState!.validate()) return;

    final String adresse = _recupererAdresse();

    if (adresse.isEmpty) {
      _annoncer('Veuillez renseigner votre adresse e-mail.');
      return;
    }

    if (!adresse.contains('@') || !adresse.contains('.')) {
      _annoncer('Veuillez renseigner une adresse e-mail valide.');
      return;
    }

    final bool succes = await soumettre(
      () => ref
          .read(authControllerProvider.notifier)
          .renvoyerEmailDeVerification(email: adresse),
    );
    if (!succes || !mounted) return;

    _demarrerCooldown(60);
    setState(() => _modeEdition = false);
    _annoncer(
      'Si un compte non activé correspond à cette adresse, un nouveau lien lui a été envoyé.',
      succes: true,
    );
  }

  Future<void> _validerOuSeConnecter() async {
    final utilisateur = ref.read(utilisateurConnecteProvider);

    // Cas particulier : l'utilisateur a déjà une session avec enabled: false.
    // On rafraîchit son profil pour voir s'il a cliqué sur le lien d'activation côté web.
    if (utilisateur != null && !utilisateur.enabled) {
      final bool succes = await soumettre(
        () => ref.read(authControllerProvider.notifier).rafraichir(),
      );
      if (!succes || !mounted) return;

      final Utilisateur? maj = ref.read(utilisateurConnecteProvider);
      if (maj != null && maj.enabled) {
        _annoncer('Compte activé avec succès ! Bienvenue.', succes: true);
        context.go(Routes.accueil);
      } else {
        _annoncer(
          'Votre compte n’est pas encore activé. Cliquez sur le lien reçu par e-mail.',
        );
      }
      return;
    }

    // Cas standard : rediriger vers l'écran de connexion avec l'adresse pré-remplie.
    final String adresse = _recupererAdresse();
    final String chemin = adresse.isNotEmpty
        ? '${Routes.connexion}?login=${Uri.encodeComponent(adresse)}'
        : Routes.connexion;
    context.go(chemin);
  }

  Future<void> _activerEnModeDemo() async {
    final String adresse = _recupererAdresse();
    final bool succes = await soumettre(
      () => ref
          .read(authControllerProvider.notifier)
          .verifierAvecCode(MockAuthApi.codeDeDemonstration, email: adresse),
    );
    if (succes && mounted) {
      _annoncer('Compte activé avec succès en mode démo !', succes: true);
      final session = ref.read(utilisateurConnecteProvider);
      if (session == null || !session.enabled) {
        context.go('${Routes.connexion}?login=${Uri.encodeComponent(adresse)}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final utilisateur = ref.watch(utilisateurConnecteProvider);
    final String adresseAffichee = _recupererAdresse();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activation du compte'),
        actions: <Widget>[
          if (utilisateur != null)
            TextButton.icon(
              icon: const Icone(Icones.deconnexion, taille: 20),
              label: const Text('Déconnexion'),
              onPressed: () =>
                  ref.read(authControllerProvider.notifier).deconnexion(),
            ),
          SizedBox(width: context.margeLaterale - Espace.sm),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: ConteneurPage(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(Espace.lg),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icone(
                        Icones.emailAttente,
                        taille: 48,
                        couleur: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(height: Espace.lg),
                  Text(
                    'Vérifiez vos e-mails',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: Espace.sm),
                  Text(
                    'Un lien de confirmation vous a été envoyé pour activer votre accès candidat.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: Espace.lg),

                  // Carte d'affichage / Édition de l'adresse e-mail
                  if (!_modeEdition && adresseAffichee.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Espace.md,
                        vertical: Espace.sm,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(Rayon.md),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                      child: Row(
                        children: <Widget>[
                          Icone(
                            Icones.email,
                            taille: 20,
                            couleur: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: Espace.sm),
                          Expanded(
                            child: Text(
                              adresseAffichee,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          TextButton(
                            onPressed: () =>
                                setState(() => _modeEdition = true),
                            child: const Text('Modifier'),
                          ),
                        ],
                      ),
                    )
                  else
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          TextFormField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: 'Adresse e-mail du compte',
                              hintText: 'votre.email@example.com',
                              prefixIcon: const PrefixeChamp(Icones.email),
                              errorText: erreurDuChamp('email'),
                              suffixIcon:
                                  (widget.email != null &&
                                      widget.email!.trim().isNotEmpty)
                                  ? TextButton(
                                      onPressed: () =>
                                          setState(() => _modeEdition = false),
                                      child: const Text('Annuler'),
                                    )
                                  : null,
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              final valeur = v?.trim() ?? '';
                              if (valeur.isEmpty) {
                                return 'Saisissez votre email';
                              }
                              if (!valeur.contains('@') ||
                                  !valeur.contains('.')) {
                                return 'Adresse email invalide';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: Espace.md),

                  // Consignes explicatives
                  Container(
                    padding: const EdgeInsets.all(Espace.md),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(
                        alpha: 0.35,
                      ),
                      borderRadius: BorderRadius.circular(Rayon.md),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Icon(
                          Icons.info_outline,
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: Espace.sm),
                        Expanded(
                          child: Text(
                            'Cliquez sur le lien dans votre messagerie pour finaliser l’activation, puis revenez vous connecter.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (_dernierEnvoiReussi) ...<Widget>[
                    const SizedBox(height: Espace.sm),
                    Text(
                      'Pensez à vérifier votre dossier spams / courriers indésirables.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],

                  const SizedBox(height: Espace.lg),

                  BandeauErreur(erreurGlobale),

                  // Action 1 : Se connecter / Rafraîchir
                  FilledButton.icon(
                    icon: (utilisateur != null && !utilisateur.enabled)
                        ? const Icon(Icons.refresh, size: 20)
                        : const Icon(Icons.login, size: 20),
                    label: Text(
                      (utilisateur != null && !utilisateur.enabled)
                          ? 'J’ai activé mon compte — Vérifier'
                          : 'J’ai activé mon compte — Se connecter',
                    ),
                    onPressed: envoiEnCours ? null : _validerOuSeConnecter,
                  ),
                  const SizedBox(height: Espace.sm),

                  const SizedBox(height: Espace.sm),

                  // Action 3 : Renvoyer le lien d'activation avec cooldown anti-spam
                  OutlinedButton.icon(
                    icon: envoiEnCours
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            _cooldownSecondes > 0
                                ? Icons.hourglass_top
                                : Icons.refresh,
                            size: 20,
                          ),
                    label: Text(
                      _cooldownSecondes > 0
                          ? 'Renvoyer le lien ($_cooldownSecondes s)'
                          : 'Renvoyer le lien d’activation',
                    ),
                    onPressed: (envoiEnCours || _cooldownSecondes > 0)
                        ? null
                        : _renvoyer,
                  ),

                  if (Env.useMocks) ...<Widget>[
                    const SizedBox(height: Espace.md),
                    TextButton(
                      onPressed: envoiEnCours ? null : _activerEnModeDemo,
                      child: const Text('Mode démo : activer automatiquement'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
