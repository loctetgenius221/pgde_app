import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
///
/// §3.4 propose deux voies pour l'activation : le lien signé du web via deep
/// link, ou un **code à six chiffres**. La seconde est retenue : elle ne
/// dépend ni d'App Links, ni d'Universal Links, ni de la capacité du
/// navigateur à rendre la main à l'application.
class VerificationEmailPage extends ConsumerStatefulWidget {
  const VerificationEmailPage({super.key});

  @override
  ConsumerState<VerificationEmailPage> createState() =>
      _VerificationEmailPageState();
}

class _VerificationEmailPageState extends ConsumerState<VerificationEmailPage>
    with FormSubmission {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _annoncer(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _valider() async {
    final String code = _code.text.trim();
    if (code.length < 6) {
      _annoncer('Saisissez les six chiffres du code.');
      return;
    }
    // Le routeur bascule seul vers l'accueil dès que `enabled` passe à vrai.
    await soumettre(
      () => ref.read(authControllerProvider.notifier).verifierAvecCode(code),
    );
  }

  Future<void> _renvoyer() async {
    final bool succes = await soumettre(
      () => ref
          .read(authControllerProvider.notifier)
          .renvoyerEmailDeVerification(),
    );
    if (!succes || !mounted) return;
    _annoncer(
      Env.useMocks
          ? 'Code envoyé. En démonstration : 123456.'
          : 'Nouveau code envoyé.',
    );
  }

  /// Le lien signé du web reste utilisable : si le candidat l'a suivi dans son
  /// navigateur, cette action relit simplement son profil.
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
                    'Code envoyé à ${utilisateur?.email ?? 'votre adresse'}.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: Espace.xl),

                  BandeauErreur(erreurGlobale),

                  TextField(
                    controller: _code,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      letterSpacing: 8,
                    ),
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    decoration: InputDecoration(
                      hintText: '••••••',
                      helperText: Env.useMocks
                          ? 'Code de démonstration : 123456'
                          : null,
                      errorText: erreurDuChamp('code'),
                    ),
                    onSubmitted: (_) => _valider(),
                  ),
                  const SizedBox(height: Espace.lg),

                  FilledButton(
                    onPressed: envoiEnCours ? null : _valider,
                    child: envoiEnCours
                        ? const IndicateurBouton()
                        : const Text('Activer mon compte'),
                  ),
                  const SizedBox(height: Espace.sm),
                  OutlinedButton(
                    onPressed: envoiEnCours ? null : _renvoyer,
                    child: const Text('Renvoyer le code'),
                  ),
                  const SizedBox(height: Espace.xs),
                  TextButton(
                    onPressed: envoiEnCours ? null : _actualiser,
                    child: const Text('J’ai utilisé le lien reçu'),
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
