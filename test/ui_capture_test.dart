// Capture réelle, hors réseau, avec polices OFL et icônes du SDK.
// CAPTURE_DIR active l'écriture ; AUDIT_BEFORE permet de relever les défauts
// de la référence sans les masquer dans les validations après refonte.
import 'dart:convert';
import 'dart:async';
import 'package:ela/data/models/book.dart';
import 'package:ela/data/models/curation_result.dart';
import 'package:ela/data/models/entitlement.dart';
import 'package:ela/data/models/library_entry.dart';
import 'package:ela/features/search/search_screen.dart';
import 'package:ela/features/scanner/scanner_screen.dart';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:ela/app.dart';
import 'package:ela/core/theme.dart';
import 'package:ela/features/book_detail/book_detail_screen.dart';
import 'package:ela/features/onboarding/onboarding_screen.dart';
import 'package:ela/features/splash/splash_screen.dart';
import 'package:ela/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'support/fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const premium = {
  'ela.entitlement':
      '{"tier":"premium","aiTokens":3,"monthlyTokenLimit":3,"premiumSince":"2026-10-01T00:00:00.000"}',
};
const shelf = {
  'ela.library':
      '[{"isbn":"9782070667918","section":"history","addedAt":"2026-10-20T10:00:00.000"},{"isbn":"9782070413438","section":"toRead","addedAt":"2026-10-28T09:00:00.000"}]',
};
const member = {
  'ela.profile':
      '{"id":"user-9","email":"claude@ela.app","displayName":"Claude","isAnonymous":false}',
};
const captureDir = String.fromEnvironment('CAPTURE_DIR');
const auditBefore = bool.fromEnvironment('AUDIT_BEFORE');
const compact = bool.fromEnvironment('COMPACT');

Future<void> advance(WidgetTester t) async {
  for (var i = 0; i < 16; i++) {
    await t.pump(const Duration(milliseconds: 250));
  }
}

Future<void> tapLabel(WidgetTester t, String label) async {
  final f = find.text(label).last;
  await t.ensureVisible(f);
  await t.pump(const Duration(milliseconds: 400));
  await t.tap(f);
  await advance(t);
}

class Scene {
  const Scene(
    this.name, {
    this.route,
    this.home,
    this.seed = const {},
    this.action,
    this.loading = false,
    this.state,
  });
  final String? state;
  final String name;
  final String? route;
  final Widget? home;
  final Map<String, Object> seed;
  final Future<void> Function(WidgetTester)? action;
  final bool loading;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadAppFonts);
  final scenes = [
    const Scene('01-splash', home: SplashScreen()),
    const Scene('02-onboarding-1', home: OnboardingScreen()),
    Scene(
      '03-onboarding-2',
      home: const OnboardingScreen(),
      action: (t) => tapLabel(t, 'Suivant'),
    ),
    Scene(
      '04-onboarding-3',
      home: const OnboardingScreen(),
      action: (t) async {
        await tapLabel(t, 'Suivant');
        await tapLabel(t, 'Suivant');
      },
    ),
    const Scene('05-tendance', route: '/tendance'),
    const Scene('06-tendance-chargement', route: '/tendance', loading: true),
    Scene(
      '07-tendance-classiques',
      route: '/tendance',
      action: (t) => tapLabel(t, 'Classiques'),
    ),
    const Scene('08-recherche', route: '/recherche'),
    Scene(
      '09-recherche-resultats',
      route: '/recherche',
      action: (t) async {
        await t.enterText(find.byType(TextField), 'Camus');
        await advance(t);
      },
    ),
    Scene(
      '10-recherche-vide',
      route: '/recherche',
      action: (t) async {
        await t.enterText(find.byType(TextField), 'zzintrouvable');
        await advance(t);
      },
    ),
    const Scene('11-scanner', route: '/scanner'),
    Scene(
      '12-scanner-inconnu',
      route: '/scanner',
      action: (t) async {
        await t.enterText(find.byType(TextField), '0000000000000');
        await tapLabel(t, 'Chercher');
      },
    ),
    const Scene('13-fiche-presse', route: '/livre/9782070667918'),
    Scene(
      '14-fiche-synthese',
      route: '/livre/9782070667918',
      action: (t) async {
        await t.drag(
          find.byType(SingleChildScrollView).first,
          const Offset(0, -430),
        );
        await advance(t);
      },
    ),
    Scene(
      '15-fiche-web',
      route: '/livre/9782070667918',
      action: (t) async {
        await tapLabel(t, 'Le Web');
        await t.drag(
          find.byType(SingleChildScrollView).first,
          const Offset(0, -430),
        );
        await advance(t);
      },
    ),
    Scene(
      '16-fiche-communaute',
      route: '/livre/9782070667918',
      action: (t) async {
        await tapLabel(t, 'La Communauté');
        await t.drag(
          find.byType(SingleChildScrollView).first,
          const Offset(0, -430),
        );
        await advance(t);
      },
    ),
    Scene(
      '17-avis-invite',
      route: '/livre/9782070667918',
      action: (t) async {
        await tapLabel(t, 'La Communauté');
        await tapLabel(t, 'Écrire un avis');
      },
    ),
    Scene(
      '18-avis-formulaire',
      route: '/livre/9782070667918',
      seed: member,
      action: (t) async {
        await tapLabel(t, 'La Communauté');
        await tapLabel(t, 'Écrire un avis');
      },
    ),
    const Scene(
      '19-fiche-premium',
      route: '/livre/9782070667918',
      seed: premium,
    ),
    Scene(
      '20-fiche-web-premium',
      route: '/livre/9782070667918',
      seed: premium,
      action: (t) async {
        await tapLabel(t, 'Le Web');
        await t.drag(
          find.byType(SingleChildScrollView).first,
          const Offset(0, -430),
        );
        await advance(t);
      },
    ),
    const Scene(
      '21-fiche-introuvable',
      home: BookDetailScreen(isbn: '0000000000000'),
    ),
    const Scene('22-bibliotheque-vide', route: '/bibliotheque'),
    const Scene('23-bibliotheque', route: '/bibliotheque', seed: shelf),
    const Scene('24-compte', route: '/compte'),
    Scene(
      '25-compte-validation',
      route: '/compte',
      action: (t) => tapLabel(t, 'Continuer avec mon e-mail'),
    ),
    const Scene('26-compte-membre', route: '/compte', seed: member),
    Scene(
      '27-bilan',
      route: '/compte',
      seed: {...member, ...premium, ...shelf},
      action: (t) async {
        await t.drag(find.byType(Scrollable).first, const Offset(0, -300));
        await advance(t);
      },
    ),
    Scene(
      '28-export-csv',
      route: '/compte',
      seed: {...member, ...premium, ...shelf},
      action: (t) => tapLabel(t, 'Exporter en CSV'),
    ),
    const Scene('29-premium', route: '/premium'),
    Scene(
      '30-premium-abonnement',
      route: '/premium',
      action: (t) async {
        await t.drag(find.byType(Scrollable).first, const Offset(0, -600));
        await advance(t);
      },
    ),
    const Scene('31-premium-actif', route: '/premium', seed: premium),
    const Scene('32-radar', route: '/radar'),
    const Scene('33-radar-premium', route: '/radar', seed: premium),
    const Scene('34-match-vide', route: '/match'),
    const Scene('35-match', route: '/match', seed: shelf),
    const Scene(
      '36-match-premium',
      route: '/match',
      seed: {...shelf, ...premium},
    ),
    Scene(
      '37-bibliotheque-etagere',
      route: '/bibliotheque',
      seed: shelf,
      action: (t) => tapLabel(t, 'Étagère'),
    ),
    const Scene('38-tendance-erreur', route: '/tendance', state: 'trend-error'),
    const Scene('39-tendance-vide', route: '/tendance', state: 'trend-empty'),
    Scene(
      '40-recherche-chargement',
      route: '/recherche',
      state: 'search-loading',
      action: (t) async {
        await t.enterText(find.byType(TextField), 'Camus');
        await advance(t);
      },
    ),
    Scene(
      '41-recherche-erreur',
      route: '/recherche',
      state: 'search-error',
      action: (t) async {
        await t.enterText(find.byType(TextField), 'Camus');
        await advance(t);
      },
    ),
    const Scene(
      '42-fiche-chargement',
      home: BookDetailScreen(isbn: '0000000000000'),
      state: 'book-loading',
    ),
    Scene(
      '43-fiche-erreur',
      route: '/livre/9782070667918',
      state: 'curation-error',
      action: (t) async {
        await t.drag(
          find.byType(SingleChildScrollView).first,
          const Offset(0, -430),
        );
        await advance(t);
      },
    ),
    Scene(
      '44-communaute-erreur',
      route: '/livre/9782070667918',
      state: 'community-error',
      action: (t) async {
        await tapLabel(t, 'La Communauté');
        await t.drag(
          find.byType(SingleChildScrollView).first,
          const Offset(0, -430),
        );
        await advance(t);
      },
    ),
    Scene(
      '45-communaute-vide',
      route: '/livre/9782070667918',
      state: 'community-empty',
      action: (t) async {
        await tapLabel(t, 'La Communauté');
        await t.drag(
          find.byType(SingleChildScrollView).first,
          const Offset(0, -430),
        );
        await advance(t);
      },
    ),
    const Scene(
      '46-premium-chargement',
      route: '/premium',
      state: 'entitlement-loading',
    ),
    const Scene(
      '47-premium-erreur',
      route: '/premium',
      state: 'entitlement-error',
    ),
    const Scene('48-scanner-refuse', route: '/scanner', state: 'camera-denied'),
    Scene(
      '49-fiche-curation',
      route: '/livre/9782070667918',
      state: 'curation-loading',
      action: (t) async {
        await t.drag(
          find.byType(SingleChildScrollView).first,
          const Offset(0, -430),
        );
        await advance(t);
      },
    ),
    Scene(
      '50-fiche-sans-jeton',
      route: '/livre/9782070667918',
      seed: {
        'ela.entitlement': '{"tier":"free","aiTokens":0,"monthlyTokenLimit":3}',
        'ela.aiTokenMonth': '${DateTime.now().year}-${DateTime.now().month}',
      },
      action: (t) async {
        await t.drag(
          find.byType(SingleChildScrollView).first,
          const Offset(0, -1500),
        );
        await advance(t);
      },
    ),
    const Scene('51-fiche-en-pal', route: '/livre/9782070413438', seed: shelf),
    Scene(
      '52-fiche-debloquee',
      route: '/livre/9782070667918',
      state: 'unlocked',
      action: (t) async {
        await t.drag(
          find.byType(SingleChildScrollView).first,
          const Offset(0, -430),
        );
        await advance(t);
      },
    ),
    Scene(
      '53-compte-connexion',
      route: '/compte',
      action: (t) async {
        final f = find.text('Continuer avec Google');
        await t.scrollUntilVisible(
          f,
          100,
          scrollable: find.byType(Scrollable).first,
        );
        await t.pump();
        await t.tap(f);
        await t.pump(const Duration(milliseconds: 100));
      },
    ),
    const Scene(
      '54-bibliotheque-erreur',
      route: '/bibliotheque',
      state: 'library-error',
    ),
    const Scene(
      '55-radar-chargement',
      route: '/radar',
      state: 'entitlement-loading',
    ),
    const Scene('56-radar-erreur', route: '/radar', state: 'entitlement-error'),
    const Scene(
      '57-match-chargement',
      route: '/match',
      state: 'entitlement-loading',
    ),
    const Scene('58-match-erreur', route: '/match', state: 'library-error'),
    const Scene(
      '59-compte-chargement',
      route: '/compte',
      state: 'entitlement-loading',
      seed: member,
    ),
    const Scene(
      '60-compte-erreur',
      route: '/compte',
      state: 'entitlement-error',
      seed: member,
    ),
  ];
  for (final dark in [false, true]) {
    for (final scene in scenes) {
      testWidgets(
        '${scene.name} ${dark ? 'nuit' : 'jour'}${compact ? ' compact 1.3' : ''}',
        (t) async {
          final issues = <String>[];
          final old = FlutterError.onError;
          if (auditBefore) {
            FlutterError.onError = (d) => issues.add(d.toString());
          }
          addTearDown(() => FlutterError.onError = old);
          t.platformDispatcher.textScaleFactorTestValue = compact ? 1.3 : 1;
          addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
          t.view.devicePixelRatio = 2.625;
          t.view.physicalSize =
              (compact ? const Size(360, 640) : const Size(412, 915)) * 2.625;
          addTearDown(t.view.resetPhysicalSize);
          addTearDown(t.view.resetDevicePixelRatio);
          SharedPreferences.setMockInitialValues({
            'ela.onboarded': true,
            ...scene.seed,
          });
          final prefs = await SharedPreferences.getInstance();
          final container = ProviderContainer(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              if (scene.state == 'trend-error')
                trendingProvider('Tous').overrideWith(
                  (ref) => Future.error(
                    StateError('Capture: tendance indisponible'),
                  ),
                ),
              if (scene.state == 'trend-empty')
                trendingProvider(
                  'Tous',
                ).overrideWith((ref) => Future.value(<Book>[])),
              if (scene.state == 'search-error')
                searchResultsProvider('Camus').overrideWith(
                  (ref) => Future.error(
                    StateError('Capture: recherche indisponible'),
                  ),
                ),
              if (scene.state == 'search-loading')
                searchResultsProvider(
                  'Camus',
                ).overrideWith((ref) => Completer<List<Book>>().future),
              if (scene.state == 'book-loading')
                bookByIsbnProvider(
                  '0000000000000',
                ).overrideWith((ref) => Completer<Book?>().future),
              if (scene.state == 'curation-error')
                curationProvider('9782070667918').overrideWith(
                  (ref) => Future.error(
                    StateError('Capture: curation indisponible'),
                  ),
                ),
              if (scene.state == 'curation-loading')
                curationProvider(
                  '9782070667918',
                ).overrideWith((ref) => Completer<CurationResult>().future),
              if (scene.state == 'community-error')
                communityReviewsProvider('9782070667918').overrideWith(
                  (ref) =>
                      Future.error(StateError('Capture: avis indisponibles')),
                ),
              if (scene.state == 'community-empty')
                communityReviewsProvider(
                  '9782070667918',
                ).overrideWith((ref) => Future.value([])),
              if (scene.state == 'entitlement-loading')
                entitlementStreamProvider.overrideWith(
                  (ref) => const Stream<Entitlement>.empty(),
                ),
              if (scene.state == 'entitlement-error')
                entitlementStreamProvider.overrideWith(
                  (ref) => Stream<Entitlement>.error(
                    StateError('Capture: abonnement indisponible'),
                  ),
                ),
              if (scene.state == 'library-error')
                libraryEntriesProvider.overrideWith(
                  (ref) => Stream<List<LibraryEntry>>.error(
                    StateError('Capture: bibliothèque indisponible'),
                  ),
                ),
              if (scene.state == 'camera-denied')
                scannerAvailabilityProvider.overrideWithValue(
                  ScannerAvailability.denied,
                ),
            ],
          );
          addTearDown(container.dispose);
          container
              .read(themeModeProvider.notifier)
              .set(dark ? ThemeMode.dark : ThemeMode.light);
          if (scene.route != null) {
            container.read(routerProvider).go(scene.route!);
          }
          if (scene.state == 'unlocked') {
            container
                .read(unlockedBooksProvider.notifier)
                .unlock('9782070667918');
          }
          final boundary = GlobalKey();
          await t.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: RepaintBoundary(
                key: boundary,
                child: MediaQuery(
                  data: MediaQueryData.fromView(
                    t.view,
                  ).copyWith(textScaler: TextScaler.linear(compact ? 1.3 : 1)),
                  child: scene.home == null
                      ? const ElaApp()
                      : MaterialApp(
                          debugShowCheckedModeBanner: false,
                          theme: dark ? ElaTheme.dark : ElaTheme.light,
                          home: scene.home!,
                        ),
                ),
              ),
            ),
          );
          if (!scene.loading) await advance(t);
          await scene.action?.call(t);
          await t.pump();
          final context = t.element(find.byType(Scaffold).first);
          expect(
            MediaQuery.sizeOf(context),
            compact ? const Size(360, 640) : const Size(412, 915),
          );
          expect(MediaQuery.textScalerOf(context).scale(10), compact ? 13 : 10);
          if (captureDir.isNotEmpty) {
            final render =
                boundary.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary;
            final img = await t.runAsync(
              () => render.toImage(pixelRatio: 2.625),
            );
            final bytes = (await t.runAsync(
              () => img!.toByteData(format: ui.ImageByteFormat.png),
            ))!;
            img!.dispose();
            await t.runAsync(() async {
              final dir = Directory('$captureDir/${dark ? 'nuit' : 'jour'}')
                ..createSync(recursive: true);
              File(
                '${dir.path}/${scene.name}.png',
              ).writeAsBytesSync(bytes.buffer.asUint8List());
              if (issues.isNotEmpty) {
                File(
                  '${dir.path}/${scene.name}-issues.txt',
                ).writeAsStringSync(issues.join('\n\n'));
              }
            });
          }
          await t.pumpWidget(const SizedBox.shrink());
          await advance(t);
        },
      );
    }
  }
  test('Capture configuration is documented', () {
    expect(jsonDecode(premium.values.first)['tier'], 'premium');
  });
}
