import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_dimens.dart';
import '../../../core/ui/form_submission.dart';
import '../../../core/ui/icone.dart';
import '../../../core/ui/responsive.dart';
import '../application/auth_controller.dart';

/// Création de compte — règles exactes de `AuthController::register` (§3.2).
///
/// Le compte naît désactivé : aucun jeton n'est émis, l'utilisateur est
/// renvoyé vers la connexion, puis vers l'écran de vérification.
///
/// Les huit champs sont regroupés en trois sections. Une colonne de huit
/// champs d'affilée fait décrocher : le découpage donne un rythme et des
/// points de repère.
class InscriptionPage extends ConsumerStatefulWidget {
  const InscriptionPage({super.key});

  @override
  ConsumerState<InscriptionPage> createState() => _InscriptionPageState();
}

class _InscriptionPageState extends ConsumerState<InscriptionPage>
    with FormSubmission {
  final _formKey = GlobalKey<FormState>();
  final _prenom = TextEditingController();
  final _nom = TextEditingController();
  final _username = TextEditingController();
  final _numberid = TextEditingController();
  final _email = TextEditingController();
  final _emailConfirmation = TextEditingController();
  final _password = TextEditingController();
  final _passwordConfirmation = TextEditingController();

  @override
  void dispose() {
    for (final c in <TextEditingController>[
      _prenom,
      _nom,
      _username,
      _numberid,
      _email,
      _emailConfirmation,
      _password,
      _passwordConfirmation,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _inscrire() async {
    if (!_formKey.currentState!.validate()) return;

    final succes = await soumettre(
      () => ref
          .read(authControllerProvider.notifier)
          .inscription(
            firstname: _prenom.text.trim(),
            lastname: _nom.text.trim(),
            username: _username.text.trim(),
            numberid: _numberid.text.trim(),
            email: _email.text.trim(),
            password: _password.text,
          ),
    );
    if (!succes || !mounted) return;

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        duration: Duration(seconds: 6),
        content: Text(
          'Compte créé. Un email de vérification vous a été envoyé : '
          'activez-le avant de déposer votre demande.',
        ),
      ),
    );
  }

  String? _obligatoire(String? v, String libelle) =>
      (v == null || v.trim().isEmpty) ? 'Saisissez votre $libelle' : null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: Espace.xxl),
          child: ConteneurPage(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text('Créer un compte', style: theme.textTheme.displaySmall),
                  const SizedBox(height: Espace.xs),
                  Text(
                    'Quelques informations suffisent. Votre dossier se '
                    'remplira ensuite, étape par étape.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: Espace.xl),

                  BandeauErreur(erreurGlobale),

                  const _Section('Votre identité'),
                  TextFormField(
                    controller: _prenom,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Prénom',
                      prefixIcon: const PrefixeChamp(Icones.prenom),
                      errorText: erreurDuChamp('firstname'),
                    ),
                    validator: (v) => _obligatoire(v, 'prénom'),
                  ),
                  const SizedBox(height: Espace.sm),
                  TextFormField(
                    controller: _nom,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Nom',
                      prefixIcon: const PrefixeChamp(Icones.nom),
                      errorText: erreurDuChamp('lastname'),
                    ),
                    validator: (v) => _obligatoire(v, 'nom'),
                  ),
                  const SizedBox(height: Espace.sm),
                  TextFormField(
                    controller: _numberid,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: InputDecoration(
                      labelText: 'Numéro de CNI ou de passeport',
                      prefixIcon: const PrefixeChamp(Icones.piece),
                      errorText: erreurDuChamp('numberid'),
                    ),
                    validator: (v) => _obligatoire(v, 'numéro de CNI'),
                  ),

                  const _Section('Vos identifiants'),
                  TextFormField(
                    controller: _username,
                    autocorrect: false,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: "Nom d'utilisateur",
                      helperText: 'C’est avec lui que vous vous connecterez',
                      prefixIcon: const PrefixeChamp(Icones.identifiant),
                      errorText: erreurDuChamp('username'),
                    ),
                    validator: (v) => _obligatoire(v, "nom d'utilisateur"),
                  ),
                  const SizedBox(height: Espace.sm),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Adresse email',
                      prefixIcon: const PrefixeChamp(Icones.email),
                      errorText: erreurDuChamp('email'),
                    ),
                    validator: (v) {
                      final valeur = v?.trim() ?? '';
                      if (valeur.isEmpty) return 'Saisissez votre email';
                      if (!valeur.contains('@') || !valeur.contains('.')) {
                        return 'Adresse email invalide';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: Espace.sm),
                  // Le serveur impose la règle `confirmed` sur l'email (§3.2) :
                  // la double saisie fait partie du contrat, et protège une
                  // activation de compte qui ne passe que par là.
                  TextFormField(
                    controller: _emailConfirmation,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: "Confirmez l'adresse email",
                      prefixIcon: PrefixeChamp(Icones.emailConfirmation),
                    ),
                    validator: (v) => v?.trim() == _email.text.trim()
                        ? null
                        : 'Les deux adresses ne correspondent pas',
                  ),

                  const _Section('Votre mot de passe'),
                  TextFormField(
                    controller: _password,
                    obscureText: true,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Mot de passe',
                      helperText: '8 caractères minimum',
                      prefixIcon: const PrefixeChamp(Icones.motDePasse),
                      errorText: erreurDuChamp('password'),
                    ),
                    validator: (v) => (v == null || v.length < 8)
                        ? 'Au moins 8 caractères'
                        : null,
                  ),
                  const SizedBox(height: Espace.sm),
                  TextFormField(
                    controller: _passwordConfirmation,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirmez le mot de passe',
                      prefixIcon: PrefixeChamp(Icones.motDePasseConfirmation),
                    ),
                    validator: (v) => v == _password.text
                        ? null
                        : 'Les deux mots de passe ne correspondent pas',
                  ),
                  const SizedBox(height: Espace.xl),

                  FilledButton(
                    onPressed: envoiEnCours ? null : _inscrire,
                    child: envoiEnCours
                        ? const IndicateurBouton()
                        : const Text('Créer mon compte'),
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

/// Intertitre de groupe de champs.
class _Section extends StatelessWidget {
  const _Section(this.titre);

  final String titre;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: Espace.lg, bottom: Espace.sm),
    child: Text(titre, style: Theme.of(context).textTheme.titleMedium),
  );
}
