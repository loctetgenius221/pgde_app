import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_dimens.dart';
import '../../../core/ui/form_submission.dart';
import '../../../core/ui/icone.dart';
import '../../../core/ui/responsive.dart';
import '../application/auth_controller.dart';

/// Changement de mot de passe d'un compte connecté (§7.2).
class MotDePassePage extends ConsumerStatefulWidget {
  const MotDePassePage({super.key});

  @override
  ConsumerState<MotDePassePage> createState() => _MotDePassePageState();
}

class _MotDePassePageState extends ConsumerState<MotDePassePage>
    with FormSubmission {
  final _formKey = GlobalKey<FormState>();
  final _actuel = TextEditingController();
  final _nouveau = TextEditingController();
  final _confirmation = TextEditingController();

  @override
  void dispose() {
    for (final c in <TextEditingController>[_actuel, _nouveau, _confirmation]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _changer() async {
    if (!_formKey.currentState!.validate()) return;

    final bool succes = await soumettre(
      () => ref
          .read(authControllerProvider.notifier)
          .changerMotDePasse(actuel: _actuel.text, nouveau: _nouveau.text),
    );
    if (!succes || !mounted) return;

    Navigator.of(context).pop();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Mot de passe modifié.')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Mot de passe')),
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
                    'Changer votre mot de passe',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: Espace.xl),

                  BandeauErreur(erreurGlobale),

                  TextFormField(
                    controller: _actuel,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Mot de passe actuel',
                      prefixIcon: const PrefixeChamp(Icones.motDePasse),
                      errorText: erreurDuChamp('current_password'),
                    ),
                    validator: (v) => (v == null || v.isEmpty)
                        ? 'Saisissez votre mot de passe actuel'
                        : null,
                  ),
                  const SizedBox(height: Espace.sm),
                  TextFormField(
                    controller: _nouveau,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Nouveau mot de passe',
                      helperText: '8 caractères minimum',
                      prefixIcon: const PrefixeChamp(Icones.motDePasse),
                      errorText: erreurDuChamp('new_password'),
                    ),
                    validator: (v) => (v == null || v.length < 8)
                        ? 'Au moins 8 caractères'
                        : null,
                  ),
                  const SizedBox(height: Espace.sm),
                  TextFormField(
                    controller: _confirmation,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirmez le nouveau mot de passe',
                      prefixIcon: PrefixeChamp(Icones.motDePasseConfirmation),
                    ),
                    validator: (v) => v == _nouveau.text
                        ? null
                        : 'Les deux mots de passe ne correspondent pas',
                  ),
                  const SizedBox(height: Espace.xl),

                  FilledButton(
                    onPressed: envoiEnCours ? null : _changer,
                    child: envoiEnCours
                        ? const IndicateurBouton()
                        : const Text('Modifier'),
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
