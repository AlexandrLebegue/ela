// Capture réelle, hors réseau, avec polices OFL et icônes du SDK.
// CAPTURE_DIR active l'écriture ; AUDIT_BEFORE permet de relever les défauts
// de la référence sans les masquer dans les validations après refonte.
import 'dart:convert';
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
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const premium = {
  'ela.entitlement':
      '{"tier":"premium","aiTokens":3,"monthlyTokenLimit":3,"premiumSince":"2026-10-01T00:00:00.000"}',
};
const shelf = {
  'ela.library':
      '[{"isbn":"9782070667918","section":"history","addedAt":"2026-10-20T10:00:00.000"},{"isbn":"9782070413438","section":"toread","addedAt":"2026-10-28T09:00:00.000"}]',
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
  });
  final String name;
  final String? route;
  final Widget? home;
  final Map<String, Object> seed;
  final Future<void> Function(WidgetTester)? action;
  final bool loading;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    for (final family in [
      'Lora',
      'NunitoSans',
      'CormorantGaramond',
      'Literata',
    ]) {
      final loader = FontLoader(family);
      loader.addFont(rootBundle.load('assets/fonts/$family.ttf'));
      loader.addFont(rootBundle.load('assets/fonts/$family-Italic.ttf'));
      await loader.load();
    }
    final sdk =
        Platform.environment['FLUTTER_ROOT'] ??
        '${Platform.environment['HOME']}/flutter';
    final icons = FontLoader('MaterialIcons')
      ..addFont(
        Future.value(
          ByteData.sublistView(
            await File(
              '$sdk/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
            ).readAsBytes(),
          ),
        ),
      );
    await icons.load();
  });
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
            overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          );
          addTearDown(container.dispose);
          container
              .read(themeModeProvider.notifier)
              .set(dark ? ThemeMode.dark : ThemeMode.light);
          if (scene.route != null) {
            container.read(routerProvider).go(scene.route!);
          }
          final boundary = GlobalKey();
          await t.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: RepaintBoundary(
                key: boundary,
                child: MediaQuery(
                  data: MediaQueryData(
                    textScaler: TextScaler.linear(compact ? 1.3 : 1),
                  ),
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
