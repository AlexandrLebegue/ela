import 'package:ela/features/scanner/scanner_screen.dart';
import 'package:ela/app.dart';
import 'package:ela/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Le scan ne retient que les ISBN EAN-13 et vérifie la clé', () {
    expect(isBookBarcode('9782070667918'), isTrue);
    expect(isBookBarcode('9782070667919'), isFalse);
    expect(isBookBarcode('4006381333931'), isFalse);
    expect(isBookBarcode('978207066791'), isFalse);
    expect(isBookBarcode('https://ela.app/livre'), isFalse);
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({'ela.onboarded': true});
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

  Future<void> settleAll(WidgetTester tester) async {
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
    await tester.pumpAndSettle();
  }

  testWidgets('Le scanner se dégrade proprement sans caméra', (tester) async {
    await pumpApp(tester);
    await settleAll(tester);

    await tester.tap(find.text('Scanner').last);
    await settleAll(tester);

    // En environnement de test, la caméra n'existe pas : la carte
    // « Caméra indisponible » s'affiche, avec le secours saisie manuelle.
    expect(find.textContaining('Caméra indisponible'), findsOneWidget);
    expect(find.text('Ou saisissez un ISBN'), findsOneWidget);
    await tester.tapAt(const Offset(12, 12));
    await settleAll(tester);
    expect(find.byType(TextField), findsNothing);
    await tester.tap(find.text('Saisir un ISBN'));
    await settleAll(tester);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('La saisie manuelle d’ISBN ouvre la fiche du livre', (
    tester,
  ) async {
    await pumpApp(tester);
    await settleAll(tester);

    await tester.tap(find.text('Scanner').last);
    await settleAll(tester);

    final isbnField = find.widgetWithText(TextField, '978…');
    await tester.enterText(isbnField, '9782070667918');
    await tester.pump();
    await tester.ensureVisible(find.text('Chercher').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chercher').last);
    await settleAll(tester);

    // La fiche « Le Petit Prince » s'est ouverte (hors shell).
    expect(find.textContaining('Le Petit Prince'), findsWidgets);
  });

  testWidgets('Un ISBN inconnu renvoie un avertissement', (tester) async {
    await pumpApp(tester);
    await settleAll(tester);

    await tester.tap(find.text('Scanner').last);
    await settleAll(tester);

    await tester.enterText(
      find.widgetWithText(TextField, '978…'),
      '9999999999999',
    );
    await tester.pump();
    await tester.ensureVisible(find.text('Chercher').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chercher').last);
    await settleAll(tester);

    expect(find.textContaining('Livre introuvable'), findsOneWidget);
  });
}
