import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme.dart';
import 'providers.dart';

class ElaApp extends ConsumerWidget {
  const ElaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
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
