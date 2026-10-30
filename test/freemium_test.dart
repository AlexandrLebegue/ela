import 'package:ela/core/theme.dart';
import 'package:ela/features/account/account_screen.dart';
import 'package:ela/features/book_detail/book_detail_screen.dart';
import 'package:ela/features/premium/matchmaker_screen.dart';
import 'package:ela/features/premium/premium_screen.dart';
import 'package:ela/features/premium/radar_screen.dart';
import 'package:ela/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const premiumSeed = {
    'ela.entitlement':
        '{"tier":"premium","aiTokens":3,"monthlyTokenLimit":3,"premiumSince":"2026-10-01T00:00:00.000"}',
  };
  const librarySeed = {
    'ela.library':
        '[{"isbn":"9782070667918","section":"history","addedAt":"2026-10-20T10:00:00.000"},{"isbn":"9782070413438","section":"toread","addedAt":"2026-10-28T09:00:00.000"}]',
  };

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Future<void> settleAll(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
    await tester.pumpAndSettle();
  }

  Future<void> pump(
    WidgetTester tester,
    Widget home, {
    Map<String, Object>? seed,
  }) {
    SharedPreferences.setMockInitialValues(seed ?? {});
    return       SharedPreferences.getInstance().then((prefs) async {
      // Viewport haut (390×2000) : les ListViews paresseuses construisent
      // alors toute leur hauteur, ce qui rend chaque élément tappable.
      tester.view.physicalSize = const Size(1170, 6000);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: MaterialApp(
            theme: ElaTheme.light,
            home: home,
          ),
        ),
      );
      await settleAll(tester);
    });
  }

  Future<void> pumpUntil(WidgetTester tester, Finder find) async {
    for (var i = 0; i < 12; i++) {
      if (find.evaluate().isNotEmpty) return;
      await tester.pump(const Duration(milliseconds: 400));
    }
    expect(find, findsWidgets);
  }

  int reviewCards(WidgetTester tester) => tester
      .widgetList<Widget>(
        find.byWidgetPredicate(
          (w) =>
              w.key is ValueKey<String> &&
              (w.key as ValueKey<String>).value.startsWith('review-'),
        ),
      )
      .length;

  testWidgets('Gratuit : 1 jeton dépensé débloque la fiche complète',
      (tester) async {
    await pump(tester, const BookDetailScreen(isbn: '9782070667918'));

    expect(find.text('Débloquer — 1 jeton'), findsOneWidget);
    await tester.ensureVisible(find.text('Débloquer — 1 jeton'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Débloquer — 1 jeton'));
    // Pendant le délai simulé le bouton affiche « Déblocage… » : on attend
    // que le délai passe et que la fiche se débloque.
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 400));
      if (find.text('Déblocage…').evaluate().isEmpty) break;
    }
    await tester.pumpAndSettle();

    // Les 5 avis presse sont réels, plus aucun flouté.
    expect(reviewCards(tester), 5);
    expect(find.text('Avis Premium'), findsNothing);
    // Le compteur est passé de 3 à 2 jetons.
    expect(find.textContaining('2 jetons IA ce mois-ci'), findsOneWidget);
    await settleAll(tester);
  });

  testWidgets('Premium : 5 presse + 15 web, avis étrangers traduits',
      (tester) async {
    await pump(
      tester,
      const BookDetailScreen(isbn: '9782070667918'),
      seed: premiumSeed,
    );

    expect(reviewCards(tester), 5);
    expect(find.text('Avis Premium'), findsNothing);
    expect(find.text('Débloquer la fiche complète'), findsNothing);

    await tester.tap(find.text('Le Web'));
    await settleAll(tester);
    expect(reviewCards(tester), 15);
    // 2 avis étrangers (en/es) portent la mention « Traduit par Ela ».
    expect(find.textContaining('Traduit par Ela'), findsNWidgets(2));
  });

  testWidgets('Paywall : abonnement simulé → Premium, puis annulation',
      (tester) async {
    await pump(tester, const PremiumScreen());

    expect(find.text('Passer Premium — 2 €/mois'), findsOneWidget);
    expect(find.text('Radar à économies'), findsOneWidget);
    expect(find.text('MatchMaker'), findsOneWidget);
    expect(find.text('Traduction automatique'), findsOneWidget);

    await tester.tap(find.text('Passer Premium — 2 €/mois'));
    await pumpUntil(tester, find.textContaining('Membre depuis'));
    expect(find.text('Annuler l’abonnement'), findsOneWidget);

    await tester.tap(find.text('Annuler l’abonnement'));
    await pumpUntil(tester, find.text('Passer Premium — 2 €/mois'));
  });

  testWidgets('Radar : teaser gratuit, liste complète en Premium',
      (tester) async {
    // Gratuit : 1 affaire réelle + floutées + invitation.
    await pump(tester, const RadarScreen());
    expect(find.textContaining('L’essentiel du Radar'), findsOneWidget);
    expect(find.text('Avis Premium'), findsNothing);
    expect(find.textContaining('Occasion floutée'), findsWidgets);
    expect(find.text('Voir Premium — 2 €/mois'), findsOneWidget);

    // Premium : 6 affaires, badges de remise, rien de flouté.
    await pump(tester, const RadarScreen(), seed: premiumSeed);
    expect(find.textContaining('Occasion floutée'), findsNothing);
    final badges = find
        .textContaining(RegExp(r'^−\d+ %$'))
        .evaluate()
        .length;
    expect(badges, 6);
  });

  testWidgets('MatchMaker : matches d’après l’étagère, verrou gratuit',
      (tester) async {
    // Étagère vide → état vide.
    await pump(tester, const MatchMakerScreen());
    expect(
        find.textContaining('Votre étagère est vide'), findsOneWidget);

    // Avec 2 livres + Premium : des scores de compatibilité affichés.
    await pump(tester, const MatchMakerScreen(),
        seed: {...premiumSeed, ...librarySeed});
    expect(
        find.textContaining(RegExp(r'^\d+ %$')), findsWidgets);
    expect(find.textContaining('Même genre'), findsWidgets);
    expect(find.textContaining('Match Premium — score masqué'), findsNothing);

    // Gratuit : les matchs au-delà des 2 premiers sont verrouillés.
    await pump(tester, const MatchMakerScreen(),
        seed: librarySeed);
    expect(find.textContaining('Match Premium — score masqué'), findsWidgets);
    expect(find.text('Voir Premium — 2 €/mois'), findsOneWidget);
  });

  testWidgets('Bilan de curiosité (Premium) : stats + export CSV',
      (tester) async {
    // Compte connecté + Premium + 2 livres lus/à lire → bilan sur le compte.
    await pump(
      tester,
      const AccountScreen(),
      seed: {
        'ela.profile':
            '{"id":"user-9","email":"claude@ela.app","displayName":"Claude","isAnonymous":false}',
        ...premiumSeed,
        'ela.library': librarySeed['ela.library'] as String,
        'ela.stats.reviews': 4,
      },
    );

    expect(find.text('Bilan de curiosité'), findsOneWidget);
    expect(find.text('Avis'), findsOneWidget);

    await tester.ensureVisible(find.text('Exporter en CSV'));
    await tester.pump();
    await tester.tap(find.text('Exporter en CSV'));
    await tester.pumpAndSettle();
    expect(find.textContaining('livres_lus;'), findsOneWidget);
    expect(find.textContaining('avis_publies;4'), findsOneWidget);
    await tester.tap(find.text('Copier'));
    await tester.pump();
    expect(
        find.textContaining('CSV copié dans le presse-papier'),
        findsOneWidget);
  });
}
