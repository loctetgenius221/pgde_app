import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/key_value_store.dart';

/// Mémorise si l'utilisateur a déjà vu l'onboarding.
///
/// Lecture **synchrone** : le routeur doit trancher au premier rendu, sans
/// passer par un état de chargement qui ferait apparaître l'écran de connexion
/// une fraction de seconde avant de basculer sur l'onboarding.
class OnboardingController extends Notifier<bool> {
  static const String _cle = 'onboarding_vu';

  @override
  bool build() => ref.watch(keyValueStoreProvider).readBool(_cle);

  Future<void> marquerCommeVu() async {
    await ref.read(keyValueStoreProvider).writeBool(_cle, value: true);
    state = true;
  }
}

final onboardingVuProvider = NotifierProvider<OnboardingController, bool>(
  OnboardingController.new,
);
