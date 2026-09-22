import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class PgdeApp extends ConsumerWidget {
  const PgdeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
    title: "Demandes d'emploi",
    debugShowCheckedModeBanner: false,
    routerConfig: ref.watch(routerProvider),
    theme: AppTheme.light(),
    darkTheme: AppTheme.dark(),
    // Application monolingue (§8.1) : pas de fichiers ARB, les libellés sont
    // écrits en français dans les écrans.
    locale: const Locale('fr', 'FR'),
    supportedLocales: const <Locale>[Locale('fr', 'FR')],
    localizationsDelegates: const <LocalizationsDelegate<Object>>[
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
  );
}
