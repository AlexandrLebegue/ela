import 'dart:math' as math;
import 'package:ela/app.dart';
import 'package:ela/core/theme.dart';
import 'package:ela/data/fake/fake_book_lookup_service.dart';
import 'package:ela/data/models/book.dart';
import 'package:ela/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'support/fonts.dart';

class _FailingLookup extends FakeBookLookupService {
  @override
  Future<Book?> lookupByIsbn(String isbn) async => throw StateError('offline');
}

Future<void> settle(WidgetTester t) async {
  for (var i = 0; i < 16; i++) {
    await t.pump(const Duration(milliseconds: 250));
  }
}

Future<ProviderContainer> routed(
  WidgetTester t,
  String route, {
  bool failLookup = false,
}) async {
  t.view.devicePixelRatio = 2.625;
  t.view.physicalSize = const Size(412, 915) * 2.625;
  addTearDown(t.view.resetDevicePixelRatio);
  addTearDown(t.view.resetPhysicalSize);
  SharedPreferences.setMockInitialValues({'ela.onboarded': true});
  final prefs = await SharedPreferences.getInstance();
  final c = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      if (failLookup)
        bookLookupServiceProvider.overrideWithValue(_FailingLookup()),
    ],
  );
  addTearDown(c.dispose);
  c.read(routerProvider).go(route);
  await t.pumpWidget(
    UncontrolledProviderScope(container: c, child: const ElaApp()),
  );
  await settle(t);
  return c;
}

Future<void> press(WidgetTester t, String text) async {
  final f = find.text(text).last;
  await t.ensureVisible(f);
  await t.pumpAndSettle();
  await t.tap(f);
  await settle(t);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadAppFonts);
  test('Toutes les paires de texte sémantiques atteignent AA', () {
    for (final theme in [ElaTheme.light, ElaTheme.dark]) {
      final c = theme.colorScheme;
      for (final pair in [
        (c.onSurface, c.surface),
        (c.onSurfaceVariant, c.surface),
        (c.primary, c.surface),
        (c.onPrimary, c.primary),
        (c.onSecondary, c.secondary),
        (c.onPrimaryContainer, c.primaryContainer),
        (c.onSecondaryContainer, c.secondaryContainer),
        (c.error, c.surface),
      ]) {
        final a = pair.$1.computeLuminance(), b = pair.$2.computeLuminance();
        expect(
          (math.max(a, b) + .05) / (math.min(a, b) + .05),
          greaterThanOrEqualTo(4.5),
          reason: '${theme.brightness} $pair',
        );
      }
    }
  });
  testWidgets(
    'Retour fiche conserve la requête de recherche et ses résultats',
    (t) async {
      final c = await routed(t, '/recherche');
      await t.enterText(find.byType(TextField), 'Camus');
      await settle(t);
      await press(t, 'L’Étranger');
      expect(c.read(routerProvider).canPop(), isTrue);
      await t.tap(find.byTooltip('Retour').last);
      await settle(t);
      expect(find.text('Camus'), findsOneWidget);
      expect(find.text('L’Étranger'), findsOneWidget);
    },
  );
  testWidgets('Entrée directe dans une fiche permet de revenir aux tendances', (
    t,
  ) async {
    final c = await routed(t, '/livre/9782070667918');
    await t.tap(find.byTooltip('Retour'));
    await settle(t);
    expect(
      c.read(routerProvider).routeInformationProvider.value.uri.path,
      '/tendance',
    );
  });
  testWidgets('Partager copie réellement une référence au presse-papier', (
    t,
  ) async {
    String? copied;
    t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(
      () => t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await routed(t, '/livre/9782070667918');
    await t.tap(find.byTooltip('Partager'));
    await settle(t);
    expect(copied, contains('9782070667918'));
    expect(copied, contains('Le Petit Prince'));
  });
  testWidgets('Une erreur ISBN permet immédiatement de réessayer', (t) async {
    await routed(t, '/scanner', failLookup: true);
    await t.enterText(find.byType(TextField), '9782070667918');
    await press(t, 'Chercher');
    expect(
      find.textContaining('La recherche a été interrompue'),
      findsOneWidget,
    );
    final button = t.widget<FilledButton>(
      find
          .ancestor(
            of: find.text('Chercher'),
            matching: find.byWidgetPredicate((w) => w is FilledButton),
          )
          .first,
    );
    expect(button.onPressed, isNotNull);
  });
  testWidgets('Le thème suit le système puis mémorise le choix du lecteur', (
    t,
  ) async {
    t.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(t.platformDispatcher.clearPlatformBrightnessTestValue);
    final c = await routed(t, '/tendance');
    await t.tap(find.byTooltip('Lire de jour'));
    await settle(t);
    expect(c.read(themeModeProvider), ThemeMode.light);
    expect(
      c.read(sharedPreferencesProvider).getString('ela.themeMode'),
      'light',
    );
  });
  testWidgets(
    'Une feuille avis reste accessible avec clavier et texte agrandi',
    (t) async {
      await routed(t, '/livre/9782070667918');
      await press(t, 'La Communauté');
      await press(t, 'Écrire un avis');
      t.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      t.view.physicalSize = const Size(360, 640) * 2.625;
      t.view.viewInsets = FakeViewPadding(bottom: 260 * 2.625);
      addTearDown(t.view.resetViewInsets);
      await t.pump();
      await press(t, 'Créer mon compte');
      expect(find.text('Votre espace'), findsOneWidget);
    },
  );
  testWidgets('Connexion puis publication : profil réactif et avis ajouté', (
    t,
  ) async {
    final c = await routed(t, '/compte');
    final google = find.text('Continuer avec Google');
    await t.scrollUntilVisible(
      google,
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await t.pumpAndSettle();
    await t.tap(google);
    await settle(t);
    c.read(routerProvider).go('/livre/9782070667918');
    await settle(t);
    await press(t, 'La Communauté');
    await press(t, 'Écrire un avis');
    expect(find.text('Votre avis mérite un nom'), findsNothing);
    await t.enterText(
      find.widgetWithText(TextField, 'Un titre pour votre avis'),
      'Une belle lecture',
    );
    await t.enterText(
      find.widgetWithText(TextField, 'Ce livre vous a fait quoi ?'),
      'Un avis paisible qui donne envie de relire ce livre.',
    );
    await press(t, 'Publier');
    expect(c.read(sharedPreferencesProvider).getInt('ela.stats.reviews'), 1);
    expect(find.text('« Une belle lecture »'), findsOneWidget);
  });
}
