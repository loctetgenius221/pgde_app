import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Signal émis par la couche réseau lorsque le serveur rejette le jeton (401).
///
/// Inversion de dépendance : `core` n'a pas le droit de connaître `features`.
/// La couche réseau publie un événement, le module d'authentification s'y
/// abonne. La flèche pointe donc de `features/auth` vers `core`, jamais
/// l'inverse.
class SessionExpiry extends ChangeNotifier {
  void signal() => notifyListeners();
}

final sessionExpiryProvider = Provider<SessionExpiry>((ref) {
  final signal = SessionExpiry();
  ref.onDispose(signal.dispose);
  return signal;
});
