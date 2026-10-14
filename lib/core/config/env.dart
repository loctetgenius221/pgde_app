abstract final class Env {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://emploi.fonctionpublique.sn/api/v1',
  );

  /// Bascule entre le faux backend en mémoire et la vraie API déployée (ADR-001).
  /// Passer `--dart-define=USE_MOCKS=true` pour forcer le mode démonstration hors ligne.
  static const bool useMocks = bool.fromEnvironment(
    'USE_MOCKS',
    defaultValue: false,
  );

  /// Sert à reconstruire l'adresse d'une pièce jointe quand la réponse ne
  /// donne qu'un chemin relatif. L'API est censée absolutiser les URLs,
  /// mais afficher une image vide parce qu'elle a oublié serait un mauvais
  /// échange.
  static String get racineFichiers =>
      apiBaseUrl.replaceFirst(RegExp(r'/api/v\d+/?$'), '');
}
