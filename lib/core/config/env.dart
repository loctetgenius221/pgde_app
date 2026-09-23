/// Configuration d'exécution, injectée au build via `--dart-define`.
///
/// Aucune machinerie de « flavors » : deux constantes suffisent tant que le
/// projet n'a qu'un backend à la fois.
///
/// ```
/// flutter run --dart-define=API_BASE_URL=http://192.168.1.12:8000/api/v1 \
///             --dart-define=USE_MOCKS=false
/// ```
abstract final class Env {
  /// Racine de l'API. Voir §8.4 du cadrage :
  /// - émulateur Android : `http://10.0.2.2:8000/api/v1`
  /// - simulateur iOS    : `http://localhost:8000/api/v1`
  /// - appareil physique : `http://<IP LAN>:8000/api/v1`
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api/v1',
  );

  /// Le backend n'expose aucune API consommable aujourd'hui (bloqueurs B1/B2
  /// du cadrage : `routes/api.php` non chargé, Sanctum absent). L'app tourne
  /// donc par défaut sur des implémentations en mémoire.
  ///
  /// Le jour où `/api/v1` existe : `--dart-define=USE_MOCKS=false`, sans
  /// modifier une seule ligne d'écran.
  static const bool useMocks = bool.fromEnvironment(
    'USE_MOCKS',
    defaultValue: true,
  );

  /// Racine du serveur, déduite de [apiBaseUrl] en retirant le suffixe d'API.
  ///
  /// Sert à reconstruire l'adresse d'une pièce jointe quand la réponse ne
  /// donne qu'un chemin relatif. L'API est censée absolutiser les URLs (§7.6),
  /// mais afficher une image vide parce qu'elle a oublié serait un mauvais
  /// échange.
  static String get racineFichiers =>
      apiBaseUrl.replaceFirst(RegExp(r'/api/v\d+/?$'), '');
}
