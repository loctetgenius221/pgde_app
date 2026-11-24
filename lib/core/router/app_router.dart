import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/assistant/ui/assistant_page.dart';
import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/ui/connexion_page.dart';
import '../../features/auth/ui/inscription_page.dart';
import '../../features/auth/ui/mot_de_passe_oublie_page.dart';
import '../../features/auth/ui/verification_email_page.dart';
import '../../features/demande/domain/wizard.dart';
import '../../features/demande/ui/accueil_page.dart';
import '../../features/demande/ui/resume_page.dart';
import '../../features/demande/ui/wizard_page.dart';
import '../../features/onboarding/application/onboarding_controller.dart';
import '../../features/onboarding/ui/onboarding_page.dart';
import '../../features/splash/ui/splash_page.dart';
import '../theme/app_dimens.dart';

abstract final class Routes {
  static const String demarrage = '/demarrage';
  static const String onboarding = '/onboarding';
  static const String connexion = '/connexion';
  static const String inscription = '/inscription';
  static const String motDePasseOublie = '/mot-de-passe-oublie';
  static const String verificationEmail = '/verification-email';
  static const String accueil = '/';
  static const String wizard = '/demande';
  static const String resume = '/dossier';
  static const String assistant = '/assistant';

  /// Ouvre le wizard directement sur une étape.
  static String wizardEtape(EtapeWizard etape) =>
      '$wizard?etape=${etape.numero}';
}

const Set<String> _routesPubliques = <String>{
  Routes.connexion,
  Routes.inscription,
  Routes.motDePasseOublie,
  Routes.verificationEmail,
};

final routerProvider = Provider<GoRouter>((ref) {
  // `GoRouter` n'écoute pas Riverpod : on lui expose un `Listenable` que l'on
  // pulse à chaque changement susceptible de modifier la destination.
  final rafraichir = ValueNotifier<int>(0);
  void pulser() => rafraichir.value++;
  ref
    ..listen(authControllerProvider, (_, _) => pulser())
    ..listen(splashTermineProvider, (_, _) => pulser())
    ..listen(onboardingVuProvider, (_, _) => pulser())
    ..onDispose(rafraichir.dispose);

  return GoRouter(
    initialLocation: Routes.demarrage,
    refreshListenable: rafraichir,
    redirect: (context, state) {
      final session = ref.read(authControllerProvider);
      final chemin = state.matchedLocation;

      // 1. On reste sur le splash tant que la session est indéterminée **ou**
      //    que l'animation d'ouverture n'est pas allée à son terme.
      if (!session.hasValue || !ref.read(splashTermineProvider)) {
        return chemin == Routes.demarrage ? null : Routes.demarrage;
      }

      final utilisateur = session.value;

      // 2. Premier lancement : l'onboarding passe avant la connexion. Il ne
      //    concerne pas un utilisateur déjà authentifié.
      if (utilisateur == null && !ref.read(onboardingVuProvider)) {
        return chemin == Routes.onboarding ? null : Routes.onboarding;
      }

      if (utilisateur == null) {
        return _routesPubliques.contains(chemin) ? null : Routes.connexion;
      }

      // 3. `enabled = 0` : la connexion aboutit quand même côté serveur
      //    (BUG-02). C'est ici qu'on bloque l'accès au dossier (§3.3).
      if (!utilisateur.enabled) {
        return chemin == Routes.verificationEmail
            ? null
            : Routes.verificationEmail;
      }

      return (chemin == Routes.demarrage ||
              chemin == Routes.onboarding ||
              chemin == Routes.verificationEmail ||
              _routesPubliques.contains(chemin))
          ? Routes.accueil
          : null;
    },
    routes: <RouteBase>[
      // Fondu enchaîné sur la séquence d'ouverture : une transition de pile
      // ferait passer le splash pour un écran dont on revient.
      _fondu(Routes.demarrage, const SplashPage()),
      _fondu(Routes.onboarding, const OnboardingPage()),
      GoRoute(
        path: Routes.connexion,
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          transitionDuration: Duree.moyenne,
          child: ConnexionPage(
            identifiantInitial:
                state.uri.queryParameters['login'] ??
                state.uri.queryParameters['email'],
          ),
          transitionsBuilder: (_, animation, _, enfant) =>
              FadeTransition(opacity: animation, child: enfant),
        ),
      ),
      GoRoute(
        path: Routes.inscription,
        builder: (_, _) => const InscriptionPage(),
      ),
      GoRoute(
        path: Routes.motDePasseOublie,
        builder: (_, _) => const MotDePasseOubliePage(),
      ),
      GoRoute(
        path: Routes.verificationEmail,
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          transitionDuration: Duree.moyenne,
          child: VerificationEmailPage(
            email: state.uri.queryParameters['email'],
          ),
          transitionsBuilder: (_, animation, _, enfant) =>
              FadeTransition(opacity: animation, child: enfant),
        ),
      ),
      _fondu(Routes.accueil, const AccueilPage()),
      GoRoute(path: Routes.resume, builder: (_, _) => const ResumePage()),
      // Pas de fondu ici : l'avatar traverse la navigation par `Hero`, et un
      // fondu superposé brouillerait la continuité qu'il établit.
      GoRoute(path: Routes.assistant, builder: (_, _) => const AssistantPage()),
      GoRoute(
        path: Routes.wizard,
        builder: (_, state) => WizardPage(
          etapeInitiale: _etapeDemandee(state.uri.queryParameters['etape']),
        ),
      ),
    ],
  );
});

/// `?etape=3` ouvre le wizard sur la troisième étape ; toute autre valeur
/// retombe sur la première plutôt que de faire échouer la navigation.
EtapeWizard _etapeDemandee(String? brut) {
  final int? numero = int.tryParse(brut ?? '');
  return EtapeWizard.values.firstWhere(
    (e) => e.numero == numero,
    orElse: () => EtapeWizard.identite,
  );
}

GoRoute _fondu(String chemin, Widget page) => GoRoute(
  path: chemin,
  pageBuilder: (context, state) => CustomTransitionPage<void>(
    key: state.pageKey,
    transitionDuration: Duree.moyenne,
    child: page,
    transitionsBuilder: (_, animation, _, enfant) =>
        FadeTransition(opacity: animation, child: enfant),
  ),
);
