abstract final class Env {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api/v1',
  );

  // Donner mock utiliser car pas encore d'API présent
  static const bool useMocks = bool.fromEnvironment(
    'USE_MOCKS',
    defaultValue: true,
  );

  /// Sert à reconstruire l'adresse d'une pièce jointe quand la réponse ne
  /// donne qu'un chemin relatif. L'API est censée absolutiser les URLs,
  /// mais afficher une image vide parce qu'elle a oublié serait un mauvais
  /// échange.
  static String get racineFichiers =>
      apiBaseUrl.replaceFirst(RegExp(r'/api/v\d+/?$'), '');
}
