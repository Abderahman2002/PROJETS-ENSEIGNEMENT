import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/router.dart';
import 'providers/auth_provider.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';

class RafiqAlMuallimApp extends StatefulWidget {
  const RafiqAlMuallimApp({super.key});

  @override
  State<RafiqAlMuallimApp> createState() => _RafiqAlMuallimAppState();
}

class _RafiqAlMuallimAppState extends State<RafiqAlMuallimApp> {
  // Created once: recreating the GoRouter on every AuthProvider change would
  // tear down the whole route tree (deactivating widgets like SplashScreen
  // mid-flight and crashing on their pending callbacks). Auth-state-driven
  // navigation happens inside the route builders/callbacks in router.dart,
  // which read the same long-lived AuthProvider instance.
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = buildRouter(context.read<AuthProvider>());
  }

  @override
  Widget build(BuildContext context) {
    final colorThemeId = context.select<AuthProvider, String>((a) => a.colorTheme);
    final colorTheme = AppColorTheme.fromId(colorThemeId);

    return MaterialApp.router(
      title: 'رفيق المعلم الموريتاني',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(colorTheme),
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child!,
      ),
      routerConfig: _router,
    );
  }
}
