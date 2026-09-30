import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/ui/form_submission.dart';
import '../../../core/ui/icone.dart';
import '../../../core/ui/responsive.dart';
import '../application/auth_controller.dart';

class ConnexionPage extends ConsumerStatefulWidget {
  const ConnexionPage({super.key});

  @override
  ConsumerState<ConnexionPage> createState() => _ConnexionPageState();
}

class _ConnexionPageState extends ConsumerState<ConnexionPage>
    with FormSubmission {
  final _formKey = GlobalKey<FormState>();
  final _identifiant = TextEditingController();
  final _password = TextEditingController();
  bool _motDePasseVisible = false;

  @override
  void dispose() {
    _identifiant.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _connecter() async {
    if (!_formKey.currentState!.validate()) return;
    // La redirection vers l'accueil est pilotée par le routeur, qui observe
    // l'état de session : rien à naviguer ici.
    await soumettre(
      () => ref
          .read(authControllerProvider.notifier)
          .connexion(
            identifiant: _identifiant.text.trim(),
            password: _password.text,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: Espace.xl),
            child: ConteneurPage(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    // Le logo coiffe l'écran, centré et posé sur une pastille
                    // claire : c'est le premier repère institutionnel que voit
                    // le candidat. À gauche et en petit, il passait pour une
                    // vignette décorative.
                    Center(
                      child: Image.asset(
                        'assets/logo_fp.png',
                        width: context.selonFormat<double>(
                          telephone: 72,
                          tablette: 88,
                        ),
                      ),
                    ),
                    const SizedBox(height: Espace.lg),

                    Text(
                      'Votre espace candidat',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: Espace.xl),

                    BandeauErreur(erreurGlobale),

                    TextFormField(
                      controller: _identifiant,
                      // §3.2 : le serveur accepte l'email **ou** le nom
                      // d'utilisateur sur le même champ. Imposer l'un des
                      // deux ferait échouer la moitié des candidats sur une
                      // règle qui n'existe pas.
                      decoration: InputDecoration(
                        labelText: 'Email ou nom d’utilisateur',
                        prefixIcon: const PrefixeChamp(Icones.identifiant),
                        errorText: erreurDuChamp('login'),
                      ),
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      autofillHints: const <String>[AutofillHints.username],
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Saisissez votre identifiant'
                          : null,
                    ),
                    const SizedBox(height: Espace.sm),

                    TextFormField(
                      controller: _password,
                      obscureText: !_motDePasseVisible,
                      decoration: InputDecoration(
                        labelText: 'Mot de passe',
                        prefixIcon: const PrefixeChamp(Icones.motDePasse),
                        errorText: erreurDuChamp('password'),
                        suffixIcon: Padding(
                          padding: const EdgeInsets.only(right: Espace.xs),
                          child: IconButton(
                            tooltip: _motDePasseVisible
                                ? 'Masquer'
                                : 'Afficher',
                            icon: Icone(
                              _motDePasseVisible
                                  ? Icones.masquer
                                  : Icones.afficher,
                              taille: StyleIcone.suffixe,
                              epaisseur: StyleIcone.traitChamp,
                              couleur: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: StyleIcone.opaciteChamp),
                            ),
                            onPressed: () => setState(
                              () => _motDePasseVisible = !_motDePasseVisible,
                            ),
                          ),
                        ),
                      ),
                      autofillHints: const <String>[AutofillHints.password],
                      onFieldSubmitted: (_) => _connecter(),
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Saisissez votre mot de passe'
                          : null,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: envoiEnCours
                            ? null
                            : () => context.push(Routes.motDePasseOublie),
                        child: const Text('Mot de passe oublié ?'),
                      ),
                    ),
                    const SizedBox(height: Espace.xs),

                    FilledButton(
                      onPressed: envoiEnCours ? null : _connecter,
                      child: envoiEnCours
                          ? const IndicateurBouton()
                          : const Text('Se connecter'),
                    ),
                    const SizedBox(height: Espace.md),

                    // `Wrap` et non `Row` : aux grandes tailles de police
                    // d'accessibilité, les deux libellés passent à la ligne au
                    // lieu de déborder.
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: <Widget>[
                        Text(
                          'Pas encore de compte ?',
                          style: theme.textTheme.bodyMedium,
                        ),
                        TextButton(
                          onPressed: envoiEnCours
                              ? null
                              : () => context.push(Routes.inscription),
                          child: const Text('Créer un compte'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
