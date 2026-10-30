import 'package:ela/app.dart';
import 'package:ela/data/models/library_entry.dart';
import 'package:ela/features/library/fly_to_library.dart';
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
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Future<ProviderContainer> pumpApp(WidgetTester tester) {
    return SharedPreferences.getInstance().then((prefs) async {
      await tester.pumpWidget(
        ProviderScope(
          key: const ValueKey('scope'),
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: const ElaApp(),
        ),
      );
      // Contexte d'un descendant du scope pour remonter au conteneur.
      return ProviderScope.containerOf(tester.element(find.byType(ElaApp)));
    });
  }

  Future<void> settleAll(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
    await tester.pumpAndSettle();
  }

  testWidgets('La Bibliothèque liste Historique (passif) et PAL (active) '
      'triés chronologiquement', (tester) async {
    // Persistance pré-chargee avec des horodatages explicites : le tri
    // chronologique est alors déterministe (le fake utilise DateTime.now()).
    SharedPreferences.setMockInitialValues({
      'ela.library': '[{"isbn":"9782070667918","section":"history",'
          '"addedAt":"2026-10-20T10:00:00.000"},'
          '{"isbn":"9782070409236","section":"history",'
          '"addedAt":"2026-10-28T09:00:00.000"},'
          '{"isbn":"9782070413438","section":"toRead",'
          '"addedAt":"2026-10-25T08:00:00.000"}]',
    });
    await pumpApp(tester);
    await settleAll(tester);

    await tester.tap(find.text('Bibliothèque').last);
    await settleAll(tester);

    expect(find.text('Ma Bibliothèque'), findsOneWidget);
    expect(find.text('Historique'), findsOneWidget);
    expect(find.text('Pile à Lire'), findsOneWidget);
    expect(find.text('Passif'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);

    // Historique : le plus récent d'abord.
    expect(find.text('Les Misérables'), findsOneWidget);
    expect(find.text('Le Petit Prince'), findsOneWidget);
    expect(find.text('L’Étranger'), findsOneWidget);

    // L’ordre vertical : Les Misérables (historique récent) au-dessus de
    // Le Petit Prince.
    final mis = tester.getTopLeft(find.text('Les Misérables'));
    final prince = tester.getTopLeft(find.text('Le Petit Prince'));
    expect(mis.dy, lessThan(prince.dy));
  });

  testWidgets('Le vol de couverture notifie la réception par la barre',
      (tester) async {
    final container = await pumpApp(tester);
    await settleAll(tester);

    // Ouvrir la fiche puis ajouter à la PAL : la couverture vole.
    container.read(routerProvider).go('/livre/9782070667918');
    await tester.pump();
    await settleAll(tester);

    await tester.tap(find.text('Ajouter à la PAL'));

    // Avancer jusqu'au déclenchement de la « réception ».
    var flyingSeen = false;
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 300));
      final flying = tester
          .widgetList(
            find.byWidgetPredicate((w) =>
                w.runtimeType.toString().contains('_FlyingCover')),
          )
          .isNotEmpty;
      if (flying) flyingSeen = true;
      if (container.read(flyToLibraryProvider).receiving) break;
    }

    // L'animation a bien joué, puis la barre « reçoit ».
    expect(flyingSeen, isTrue);
    expect(container.read(flyToLibraryProvider).receiving, isTrue);

    // La réception s'efforce d'elle-même après ~520 ms.
    await tester.pump(const Duration(milliseconds: 600));
    expect(container.read(flyToLibraryProvider).receiving, isFalse);

    // Et le livre est bien dans la PAL.
    final entries = container.read(libraryEntriesProvider).value;
    expect(
      entries?.any((e) =>
          e.isbn == '9782070667918' && e.section == LibrarySection.toRead),
      isTrue,
    );
  });
}
