import 'package:ela/core/theme.dart';
import 'package:ela/features/book_detail/book_detail_screen.dart';
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

  Future<void> pumpDetail(
    WidgetTester tester, {
    String isbn = '9782070667918',
  }) {
    return SharedPreferences.getInstance().then((prefs) {
      return tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: MaterialApp(
            theme: ElaTheme.light,
            home: BookDetailScreen(isbn: isbn),
          ),
        ),
      );
    });
  }

  /// Viewport téléphone (390×844 @3x) : la fiche est pensée mobile,
  /// le viewport 800×600 par défaut est trop court.
  void phoneView(WidgetTester tester) {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  /// Avance l'horloge bien au-delà des délais fake (≤ 1,6 s) puis stabilise.
  Future<void> settleAll(WidgetTester tester) async {
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
    await tester.pumpAndSettle();
  }

  /// Compte les cartes d'avis (chaque carte porte une clé `review-…`).
  int reviewCards(WidgetTester tester) => tester
      .widgetList<Widget>(
        find.byWidgetPredicate(
          (w) =>
              w.key is ValueKey<String> &&
              (w.key as ValueKey<String>).value.startsWith('review-'),
        ),
      )
      .length;

  testWidgets(
    'La fiche (gratuit) : synthèse recoupée, 1 avis presse visible, 4 floutés + carte jeton',
    (tester) async {
      phoneView(tester);
      await pumpDetail(tester);
      await settleAll(tester);

      expect(find.text('Le Petit Prince'), findsWidgets);
      expect(find.textContaining('Classique intemporel'), findsOneWidget);
      expect(find.textContaining("14 900 lecteurs d’Ela"), findsOneWidget);
      expect(find.text('Synthèse Ela'), findsOneWidget);
      expect(find.text('La presse en a parlé'), findsOneWidget);
      // Freemium : 1 avis presse réel, 4 floutés, carte de déblocage.
      expect(reviewCards(tester), 1);
      expect(find.text('Avis Premium'), findsNWidgets(4));
      expect(find.text('Débloquer la fiche complète'), findsOneWidget);
      expect(find.textContaining('jetons IA ce mois-ci'), findsOneWidget);
    },
  );

  testWidgets('L’onglet « Le Web » (gratuit) : 2 avis visibles, 13 floutés', (
    tester,
  ) async {
    phoneView(tester);
    await pumpDetail(tester);
    await settleAll(tester);

    await tester.ensureVisible(find.text('Le Web'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Le Web'));
    await settleAll(tester);

    expect(find.textContaining('15 avis du web'), findsOneWidget);
    expect(reviewCards(tester), 2);
    expect(find.text('Avis Premium'), findsNWidgets(13));
  });

  testWidgets(
    'L’onglet « La Communauté » liste les avis et permet de signaler',
    (tester) async {
      phoneView(tester);
      await pumpDetail(tester);
      await settleAll(tester);

      await tester.ensureVisible(find.text('La Communauté'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('La Communauté'));
      await settleAll(tester);

      expect(find.text('La communauté d’Ela'), findsOneWidget);
      expect(find.text('Écrire un avis'), findsOneWidget);
      expect(reviewCards(tester), 24);

      final flag = find.byIcon(Icons.flag_outlined).first;
      await tester.ensureVisible(flag);
      await tester.pumpAndSettle();
      await tester.tap(flag);
      await settleAll(tester);

      expect(find.textContaining('Signalement bien reçu'), findsOneWidget);
    },
  );

  testWidgets('Ajouter à la PAL puis retirer', (tester) async {
    phoneView(tester);
    await pumpDetail(tester);
    await settleAll(tester);

    await tester.ensureVisible(find.text('Ajouter à la PAL'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ajouter à la PAL'));
    await settleAll(tester);

    expect(find.text('Dans votre PAL'), findsOneWidget);
    expect(find.textContaining('Ajouté à votre Pile à Lire'), findsOneWidget);

    await tester.ensureVisible(find.text('Dans votre PAL'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dans votre PAL'));
    await settleAll(tester);

    expect(find.text('Ajouter à la PAL'), findsOneWidget);
    expect(find.textContaining('Retiré de votre Pile à Lire'), findsOneWidget);
  });

  testWidgets('Publier un avis sans compte : invite lazy registration', (
    tester,
  ) async {
    phoneView(tester);
    await pumpDetail(tester);
    await settleAll(tester);

    await tester.ensureVisible(find.text('La Communauté'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('La Communauté'));
    await settleAll(tester);
    await tester.ensureVisible(find.text('Écrire un avis'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Écrire un avis'));
    await settleAll(tester);

    expect(find.textContaining('Votre avis mérite un nom'), findsOneWidget);
    await tester.tap(find.text('Créer mon compte'));
    await settleAll(tester);

    // La feuille se ferme et cède la place à l'écran de compte
    // (navigation réelle testée dans account_test, app complète).
    expect(find.textContaining('Votre avis mérite un nom'), findsNothing);
  });
}
