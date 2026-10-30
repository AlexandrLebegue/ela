import 'package:ela/app.dart';
import 'package:ela/providers.dart';
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

  Future<void> pumpApp(WidgetTester tester) {
    return SharedPreferences.getInstance().then((prefs) {
      return tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: const ElaApp(),
        ),
      );
    });
  }

  /// Fait avancer l'horloge factice assez pour déclencher tous les
  /// délais simulés du backend fake (≤ 1,5 s) puis stabilise.
  Future<void> settleAll(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
    await tester.pumpAndSettle();
  }

  testWidgets('Le socle lance l’app avec la barre de 4 entrées',
      (tester) async {
    await pumpApp(tester);
    await settleAll(tester);

    // « Tendance » 2 fois (titre d'écran + libellé de la barre du bas).
    // Les autres branches du shell ne sont pas encore construites : 1 fois.
    expect(find.text('Tendance'), findsNWidgets(2));
    expect(find.text('Scanner'), findsOneWidget);
    expect(find.text('Bibliothèque'), findsOneWidget);
    expect(find.text('Recherche'), findsOneWidget);
  });

  testWidgets('On navigue entre les onglets Scanner et Recherche',
      (tester) async {
    await pumpApp(tester);
    await settleAll(tester);

    await tester.tap(find.text('Scanner').last);
    await tester.pumpAndSettle();
    // La branche Scanner est construite (secours saisie manuelle visible).
    expect(find.text('Ou saisissez un ISBN'), findsOneWidget);

    await tester.tap(find.text('Recherche').last);
    await settleAll(tester);
    expect(find.textContaining('Cherchez parmi les'), findsOneWidget);
  });
}
