import 'dart:ui' show Display, FlutterView;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/storage/key_value_store.dart';

Future<void> main() async {
  final WidgetsBinding binding = WidgetsFlutterBinding.ensureInitialized();

  // Décidé dès que possible pour éviter une rotation parasite au lancement…
  final List<DeviceOrientation>? orientations = _orientationsAutorisees();
  if (orientations != null) {
    await SystemChrome.setPreferredOrientations(orientations);
  }
  // … et confirmé après la première image, quand les dimensions sont sûres.
  // Avant, en release, l'écran pouvait encore mesurer 0 × 0 : l'app se
  // croyait sur un téléphone, se verrouillait en portrait, et Android
  // l'affichait en bandeau au milieu d'une tablette couchée.
  binding.addPostFrameCallback((_) {
    SystemChrome.setPreferredOrientations(
      _orientationsAutorisees() ?? DeviceOrientation.values,
    );
  });
  await initializeDateFormatting('fr_FR');

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const PgdeApp(),
    ),
  );
}

/// Portrait seul sur téléphone (§8.1), toutes orientations sur tablette.
///
/// Un téléphone couché n'offre plus que 360 px de haut : le clavier y
/// mangerait le formulaire. Une tablette couchée garde au moins 600 px dans
/// chaque sens, et c'est souvent ainsi qu'on la pose sur un bureau.
///
/// Le critère est le **plus petit côté de l'écran physique** (`display`),
/// indépendant de l'orientation au lancement et de la fenêtre de l'app — que
/// Android peut avoir réduite. 600 px logiques : seuil tablette de Material.
///
/// `null` tant que l'écran n'est pas encore mesuré.
List<DeviceOrientation>? _orientationsAutorisees() {
  final FlutterView vue =
      WidgetsBinding.instance.platformDispatcher.views.first;
  final Display ecran = vue.display;
  final double plusPetitCote = ecran.size.isEmpty
      ? vue.physicalSize.shortestSide / vue.devicePixelRatio
      : ecran.size.shortestSide / ecran.devicePixelRatio;
  if (plusPetitCote <= 0) return null;
  return plusPetitCote >= 600
      ? DeviceOrientation.values
      : const <DeviceOrientation>[DeviceOrientation.portraitUp];
}
