import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/push/fcm_service.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class ManasetyApp extends ConsumerWidget {
  const ManasetyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    // Sprint 10 Phase 3 — deep-link tapped push notifications through the router
    FcmService.bindRouter(router);
    return MaterialApp.router(
      title: 'منصتي للمعلم',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }
}
