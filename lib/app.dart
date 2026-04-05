import 'package:flutter/material.dart';
import 'package:freecal/core/router/app_router.dart';
import 'package:freecal/core/theme/app_theme.dart';

/// Root widget for the FreeCal application.
class FreecalApp extends StatelessWidget {
  const FreecalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'FreeCal',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
