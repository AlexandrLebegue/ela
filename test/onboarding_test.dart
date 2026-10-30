import 'package:ela/app.dart';
import 'package:ela/features/onboarding/onboarding_screen.dart';
import 'package:ela/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // Pas de réseau dans les tests.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  /// Avance l'horloge factice au-delà de tous les délais fake (≤ 1,5 s)
  /// puis stabilise — sans ça, des timers restent en attente à la fin.
  Future<void> settleAll(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
    await tester.pumpAndSettle();
  }

  Future<ProviderContainer> pumpApp(
    WidgetTester tester, {
    Map<String, Object> seed = const {},
  }) {
    SharedPreferences.setMockInitialValues(seed);
    return SharedPreferences.getInstance().then((prefs) async {
      await tester.pumpWidget(
        ProviderScope(
          key: const ValueKey('scope'),
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: const ElaApp(),
        ),
      );
      await settleAll(tester);
      return ProviderScope.containerOf(tester.element(find.byType(ElaApp)));
    });
  }

  testWidgets('Premier lancement : 3 écrans, « Commencer à lire » → shell',
      (tester) async {
    await pumpApp(tester);

    // Page 1.
    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.text('Bienvenue chez Ela'), findsOneWidget);
    expect(find.text('Suivant'), findsOneWidget);
    expect(find.text('Commencer à lire'), findsNothing);

    // Page 2.
    await tester.tap(find.text('Suivant'));
    await settleAll(tester);
    expect(find.text('20 avis, 1 verdict'), findsOneWidget);

    // Retour → page 1.
    await tester.tap(find.text('Retour'));
    await settleAll(tester);
    expect(find.text('Bienvenue chez Ela'), findsOneWidget);

    // Pages 2 → 3, puis shell.
    await tester.tap(find.text('Suivant'));
    await settleAll(tester);
    await tester.tap(find.text('Suivant'));
    await settleAll(tester);
    expect(find.text('Votre bibliothèque, partout'), findsOneWidget);
    expect(find.text('Commencer à lire'), findsOneWidget);

    await tester.tap(find.text('Commencer à lire'));
    await settleAll(tester);
    expect(find.byType(OnboardingScreen), findsNothing);
    // Le shell 4 entrées est de retour.
    expect(find.text('Tendance'), findsWidgets);
    expect(find.text('Scanner'), findsWidgets);
  });

  testWidgets('« Passer » saute l’onboarding au premier lancement',
      (tester) async {
    final scope = await pumpApp(tester);
    expect(find.text('Passer'), findsOneWidget);

    await tester.tap(find.text('Passer'));
    await settleAll(tester);

    expect(find.byType(OnboardingScreen), findsNothing);
    expect(find.text('Tendance'), findsWidgets);
    // Mémorisé : la prochaine session passera directement au shell.
    expect(
        scope.read(sharedPreferencesProvider).getBool('ela.onboarded'), true);
  });

  testWidgets('Deuxième lancement : shell direct (onboarding déjà vu)',
      (tester) async {
    await pumpApp(tester, seed: {'ela.onboarded': true});

    expect(find.byType(OnboardingScreen), findsNothing);
    expect(find.text('Tendance'), findsWidgets);
  });
}
