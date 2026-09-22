import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/ui/form_submission.dart';
import '../../../core/ui/icone.dart';
import '../../../core/ui/responsive.dart';
import '../application/auth_controller.dart';

/// Écran bloquant tant que `enabled = 0` (§3.3, §3.5).
///
/// Le serveur laisse un compte non vérifié se connecter (BUG-02) et
/// `hasVerifiedEmail()` renvoie toujours `false` (bug de cast, §3.5) : c'est
/// donc `enabled` — et lui seul — qui fait foi, côté app.
class VerificationEmailPage extends ConsumerStatefulWidget {
  const VerificationEmailPage({super.key});

  @override
  ConsumerState<VerificationEmailPage> createState() =>
      _VerificationEmailPageState();
}

class _VerificationEmailPageState extends ConsumerState<VerificationEmailPage>
    with FormSubmission {
  Future<void> _renvoyer() async {
    final succes = await soumettre(
      () => ref
          .read(authControllerProvider.notifier)
          .renvoyerEmailDeVerification(),
    );
    if (!succes || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          Env.useMocks
              ? 'Compte activé (raccourci de développement).'
              : 'Un nouvel email de vérification vous a été envoyé.',
        ),
      ),
    );
    await ref.read(authControllerProvider.notifier).rafraichir();
  }

  Future<void> _actualiser() =>
      soumettre(() => ref.read(authControllerProvider.notifier).rafraichir());

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final utilisateur = ref.watch(utilisateurConnecteProvider);

    return Scaffold(
      appBar: AppBar(
        actions: <Widget>[
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
                        taille: 44,
                        couleur: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(height: Espace.lg),
                  Text(
                    'Activez votre compte',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: Espace.sm),
                  Text(
                    'Un email de vérification a été envoyé à '
                    '${utilisateur?.email ?? 'votre adresse'}. '
                    'Ouvrez-le pour activer votre compte, puis revenez ici.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: Espace.xl),

                  BandeauErreur(erreurGlobale),

                  FilledButton(
                    onPressed: envoiEnCours ? null : _actualiser,
                    child: envoiEnCours
                        ? const IndicateurBouton()
                        : const Text('J’ai activé mon compte'),
                  ),
                  const SizedBox(height: Espace.sm),
                  OutlinedButton(
                    onPressed: envoiEnCours ? null : _renvoyer,
                    child: const Text('Renvoyer l’email'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
