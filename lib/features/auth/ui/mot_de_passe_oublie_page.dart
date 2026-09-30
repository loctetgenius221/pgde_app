import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_dimens.dart';
import '../../../core/ui/form_submission.dart';
import '../../../core/ui/icone.dart';
import '../../../core/ui/responsive.dart';
import '../application/auth_controller.dart';

/// Mot de passe oublié — contrat §3.5.
///
/// Un seul champ, un seul appel. La v1 envoie un lien par email et n'expose
/// **aucune route pour consommer le jeton reçu** : la suite se passe hors de
/// l'app. Proposer ici une saisie de code laisserait croire le contraire, et
/// l'écran finirait sur une erreur au moment le plus mal choisi.
class MotDePasseOubliePage extends ConsumerStatefulWidget {
  const MotDePasseOubliePage({super.key});

  @override
  ConsumerState<MotDePasseOubliePage> createState() =>
      _MotDePasseOubliePageState();
}

class _MotDePasseOubliePageState extends ConsumerState<MotDePasseOubliePage>
    with FormSubmission {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();

  bool _envoye = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _demander() async {
    if (!_formKey.currentState!.validate()) return;

    final bool succes = await soumettre(
      () => ref
          .read(authControllerProvider.notifier)
          .demanderReinitialisation(email: _email.text.trim()),
    );
    if (!succes || !mounted) return;
    setState(() => _envoye = true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Mot de passe oublié')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: Espace.xxl),
          child: ConteneurPage(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    _envoye ? 'Vérifiez vos emails' : 'Retrouver son accès',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: Espace.xs),
                  Text(
                    _envoye
                        // Formulation volontairement prudente : confirmer
                        // qu'un compte existe renseignerait un attaquant.
                        ? 'Si un compte correspond à cette adresse, un lien '
                              'de réinitialisation vient d’être envoyé.'
                        : 'Saisissez l’adresse email de votre compte.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: Espace.xl),

                  BandeauErreur(erreurGlobale),

                  if (!_envoye) ...<Widget>[
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      decoration: InputDecoration(
                        labelText: 'Adresse email',
                        prefixIcon: const PrefixeChamp(Icones.email),
                        errorText: erreurDuChamp('email'),
                      ),
                      validator: (v) {
                        final String valeur = v?.trim() ?? '';
                        if (valeur.isEmpty) return 'Saisissez votre email';
                        if (!valeur.contains('@')) {
                          return 'Adresse email invalide';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: Espace.xl),
                    FilledButton(
                      onPressed: envoiEnCours ? null : _demander,
                      child: envoiEnCours
                          ? const IndicateurBouton()
                          : const Text('Envoyer le lien'),
                    ),
                  ] else
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Revenir à la connexion'),
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
