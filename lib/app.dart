import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/flags.dart';
import 'core/theme.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/splash/splash_screen.dart';
import 'providers.dart';

/// Racine de l'app : splash de marque → (onboarding la 1ʳᵉ fois) → shell.
class ElaApp extends ConsumerStatefulWidget {
  const ElaApp({super.key});

  @override
  ConsumerState<ElaApp> createState() => _ElaAppState();
}

class _ElaAppState extends ConsumerState<ElaApp> {
  // Sous flutter test le splash est omis (pas de ticker permanent,
  // pas d'attente) ; l'onboarding reste testable (flag prefs).
  final bool _skipSplash = isRunningUnderFlutterTest;
  late bool _splashDone = _skipSplash;
  Timer? _splashTimer;

  @override
  void initState() {
    super.initState();
    if (!_skipSplash) {
      _splashTimer = Timer(const Duration(milliseconds: 1100), _markSplashDone);
    }
  }

  void _markSplashDone() {
    if (mounted) setState(() => _splashDone = true);
  }

  @override
  void dispose() {
    _splashTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final themeMode = ref.watch(themeModeProvider);

    if (!_splashDone) {
      return MaterialApp(
        title: 'Ela',
        debugShowCheckedModeBanner: false,
        theme: ElaTheme.light,
        darkTheme: ElaTheme.dark,
        themeMode: themeMode,
        home: const SplashScreen(),
      );
    }

    // L'onboarding n'est montré qu'une fois ; ensuite on passe
    // directement au routeur (shell 4 branches + routes détail).
    if (!ref.watch(onboardedProvider)) {
      return MaterialApp(
        title: 'Ela',
        debugShowCheckedModeBanner: false,
        theme: ElaTheme.light,
        darkTheme: ElaTheme.dark,
        themeMode: themeMode,
        home: const OnboardingScreen(),
      );
    }

    return MaterialApp.router(
      title: 'Ela',
      debugShowCheckedModeBanner: false,
      theme: ElaTheme.light,
      darkTheme: ElaTheme.dark,
      themeMode: themeMode,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
