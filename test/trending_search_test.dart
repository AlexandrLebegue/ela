import 'package:ela/core/theme.dart';
import 'package:ela/features/search/search_screen.dart';
import 'package:ela/features/trending/trending_screen.dart';
import 'package:ela/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpScreen(WidgetTester tester, Widget screen) {
    return SharedPreferences.getInstance().then((prefs) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: MaterialApp(theme: ElaTheme.light, home: screen),
        ),
      );
    });
  }

  /// Avance l'horloge factice jusqu'à ce que [find] matche (ou timeout).
  Future<void> pumpUntil(
    WidgetTester tester,
    Finder find, {
    int maxTicks = 10,
  }) async {
    for (var i = 0; i < maxTicks; i++) {
      if (find.evaluate().isNotEmpty) return;
      await tester.pump(const Duration(milliseconds: 400));
    }
    expect(find, findsWidgets, reason: 'timeout en attente de $find');
  }

  testWidgets(
    'Tendance : squelettes puis liste en cascade, rangs dorés, changement de catégorie',
    (tester) async {
      await pumpScreen(tester, const TrendingScreen());
      await tester.pump();

      // Squelettes pendant le chargement (pas encore de titre).
      expect(find.text('Le Petit Prince'), findsNothing);

      await pumpUntil(tester, find.text('Le Petit Prince'));
      expect(find.text('Le Petit Prince'), findsOneWidget);
      expect(find.text('N°1'), findsOneWidget);
      expect(find.text('N°2'), findsOneWidget);
      expect(find.text('N°4'), findsOneWidget);

      // Les puces de catégories sont arrivées ; on bascule sur Classiques.
      await pumpUntil(tester, find.text('Classiques'));
      await tester.tap(find.text('Classiques'));

      await pumpUntil(tester, find.text('Les Misérables'));
      expect(find.text('Les Misérables'), findsOneWidget);
      expect(find.text('Verity'), findsNothing);
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'Recherche : résultats par auteur, puis retour au hint au clear',
    (tester) async {
      await pumpScreen(tester, const SearchScreen());
      await tester.pump();

      expect(find.textContaining('Cherchez parmi'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Camus');
      await tester.pump(const Duration(milliseconds: 400)); // debounce

      await pumpUntil(tester, find.text('L’Étranger'));
      expect(find.text('L’Étranger'), findsOneWidget);
      expect(find.textContaining('Albert Camus'), findsOneWidget);

      // Clear → debounce 350 ms puis fondu 300 ms vers le hint.
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();
      expect(find.textContaining('Cherchez parmi'), findsOneWidget);
      expect(find.text('L’Étranger'), findsNothing);
    },
  );

  testWidgets('Recherche : aucun résultat pour une requête inconnue', (
    tester,
  ) async {
    await pumpScreen(tester, const SearchScreen());
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'zzzz');
    await tester.pump(const Duration(milliseconds: 400));

    await pumpUntil(tester, find.textContaining('Aucun résultat'));
    expect(find.textContaining('Aucun résultat pour « zzzz »'), findsOneWidget);
    await tester.pumpAndSettle();
  });
}
