import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/formatters.dart';
import 'core/router.dart';
import 'core/strings.dart';
import 'core/theme.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: AppStrings.appTitle,
      locale: appLocale,
      supportedLocales: const [appLocale],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      // Flutter 3.44+ usa edge-to-edge no Android: sem SafeArea o conteúdo
      // (inclusive a parte inferior de listas e formulários) fica sob a barra
      // de navegação do sistema. Aplicar uma vez aqui cobre todas as rotas.
      builder: (context, child) =>
          SafeArea(child: child ?? const SizedBox.shrink()),
      routerConfig: appRouter,
    );
  }
}
