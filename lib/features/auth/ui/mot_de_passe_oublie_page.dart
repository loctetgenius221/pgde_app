import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/ui/form_submission.dart';
import '../../../core/ui/icone.dart';
import '../../../core/ui/responsive.dart';
import '../application/auth_controller.dart';

/// Réinitialisation du mot de passe (§7.2).
///
/// Deux temps dans un seul écran : on demande le code, puis on le saisit avec
/// le nouveau mot de passe. Séparer en deux pages obligerait à ressaisir
/// l'email, ou à le transporter dans la navigation pour rien.
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
  final _numberid = TextEditingController();
  final _code = TextEditingController();
  final _nouveau = TextEditingController();

  bool _codeEnvoye = false;

  @override
  void dispose() {
    for (final c in <TextEditingController>[
      _email,
      _numberid,
      _code,
      _nouveau,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _demanderLeCode() async {
    if (!_formKey.currentState!.validate()) return;

    final bool succes = await soumettre(
      () => ref
          .read(authControllerProvider.notifier)
          .demanderReinitialisation(
            email: _email.text.trim(),
            numberid: _numberid.text.trim(),
          ),
    );
    if (!succes || !mounted) return;
    setState(() => _codeEnvoye = true);
  }

  Future<void> _reinitialiser() async {
    if (!_formKey.currentState!.validate()) return;

    final bool succes = await soumettre(
      () => ref
          .read(authControllerProvider.notifier)
          .reinitialiser(
            jeton: _code.text.trim(),
            email: _email.text.trim(),
            motDePasse: _nouveau.text,
          ),
    );
    if (!succes || !mounted) return;

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Mot de passe réinitialisé. Connectez-vous avec le nouveau.',
        ),
      ),
    );
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
                    _codeEnvoye ? 'Saisissez le code' : 'Retrouver son accès',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: Espace.xs),
                  Text(
                    _codeEnvoye
                        ? 'Si les informations correspondent à un compte, un '
                              'code vous a été envoyé par email.'
                        : 'Indiquez votre email et le numéro de pièce donné à '
                              'l’inscription. Les deux sont nécessaires : '
                              'l’email seul n’identifie pas un compte ici.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: Espace.xl),

                  BandeauErreur(erreurGlobale),

                  TextFormField(
                    controller: _email,
                    enabled: !_codeEnvoye,
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
                      if (!valeur.contains('@')) return 'Adresse email invalide';
                      return null;
                    },
                  ),
                  const SizedBox(height: Espace.sm),
                  TextFormField(
                    controller: _numberid,
                    enabled: !_codeEnvoye,
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: InputDecoration(
                      labelText: 'Numéro de CNI ou de passeport',
                      prefixIcon: const PrefixeChamp(Icones.piece),
                      errorText: erreurDuChamp('numberid'),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Saisissez votre numéro de pièce'
                        : null,
                  ),

                  if (_codeEnvoye) ...<Widget>[
                    const SizedBox(height: Espace.sm),
                    TextFormField(
                      controller: _code,
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Code reçu par email',
                        helperText: Env.useMocks
                            ? 'Code de démonstration : 123456'
                            : 'Six chiffres',
                        prefixIcon: const PrefixeChamp(Icones.emailAttente),
                        errorText: erreurDuChamp('token'),
                      ),
                      validator: (v) => (v == null || v.trim().length < 6)
                          ? 'Le code comporte six chiffres'
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
                        errorText: erreurDuChamp('password'),
                      ),
                      validator: (v) => (v == null || v.length < 8)
                          ? 'Au moins 8 caractères'
                          : null,
                    ),
                  ],

                  const SizedBox(height: Espace.xl),
                  FilledButton(
                    onPressed: envoiEnCours
                        ? null
                        : (_codeEnvoye ? _reinitialiser : _demanderLeCode),
                    child: envoiEnCours
                        ? const IndicateurBouton()
                        : Text(
                            _codeEnvoye
                                ? 'Réinitialiser'
                                : 'Recevoir un code',
                          ),
                  ),
                  if (_codeEnvoye)
                    TextButton(
                      onPressed: envoiEnCours
                          ? null
                          : () => setState(() => _codeEnvoye = false),
                      child: const Text('Corriger mes informations'),
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
