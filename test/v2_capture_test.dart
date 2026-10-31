import 'dart:io';
import 'dart:ui' as ui;
import 'package:ela/app.dart';
import 'package:ela/features/scanner/scanner_screen.dart';
import 'package:ela/features/ratings/rating_widgets.dart';
import 'package:ela/core/widgets/rating_stars.dart';
import 'package:ela/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'support/fonts.dart';

const _output = String.fromEnvironment('V2_CAPTURE_DIR');
const _compact = bool.fromEnvironment('COMPACT');
const _isbn = '9782070667918';
Future<void> advance(WidgetTester t) async {
  for (var i = 0; i < 24; i++) {
    await t.pump(const Duration(milliseconds: 150));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadAppFonts);
  for (final dark in [false, true]) {
    for (final scene in [
      'fiche-notation',
      'widget-notation',
      'tendance-etoiles',
      'scanner-apres',
      'scanner-manuel',
      'marche-accueil',
      'marche-comparateur',
      'marche-annonce',
      'marche-radar',
    ]) {
      testWidgets('v2 $scene ${dark ? 'nuit' : 'jour'}', (t) async {
        t.view.physicalSize = _compact
            ? const Size(360, 640)
            : const Size(412, 915);
        t.view.devicePixelRatio = 1;
        t.platformDispatcher.textScaleFactorTestValue = _compact ? 1.3 : 1;
        t.platformDispatcher.accessibilityFeaturesTestValue =
            FakeAccessibilityFeatures(disableAnimations: true);
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
        addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
        SharedPreferences.setMockInitialValues({
          'ela.onboarded': true,
          'ela.themeMode': dark ? 'dark' : 'light',
        });
        final c = ProviderContainer(
          overrides: [
            if (scene == 'scanner-apres')
              scannerAvailabilityProvider.overrideWithValue(
                ScannerAvailability.preview,
              ),
            sharedPreferencesProvider.overrideWithValue(
              await SharedPreferences.getInstance(),
            ),
          ],
        );
        final key = GlobalKey();
        c
            .read(routerProvider)
            .go(
              scene == 'marche-accueil'
                  ? '/marche'
                  : scene == 'marche-comparateur'
                  ? '/marche?isbn=$_isbn'
                  : scene == 'marche-annonce'
                  ? '/annonce/demo-0'
                  : scene == 'marche-radar'
                  ? '/marche?vue=radar'
                  : scene == 'tendance-etoiles'
                  ? '/tendance'
                  : scene.startsWith('scanner')
                  ? '/scanner'
                  : '/livre/$_isbn',
            );
        await t.pumpWidget(
          UncontrolledProviderScope(
            container: c,
            child: RepaintBoundary(key: key, child: const ElaApp()),
          ),
        );
        await advance(t);
        if (scene == 'fiche-notation' && _compact) {
          await t.ensureVisible(find.byType(RatingSummaryCard));
          await advance(t);
        }
        if (scene == 'widget-notation') {
          final context = t.element(find.byType(RatingSummaryCard));
          showRatingSheet(context, _isbn);
          await advance(t);
          final stars = find.byWidgetPredicate(
            (w) => w is RatingStars && w.onChanged != null,
          );
          await t.tapAt(t.getTopLeft(stars) + const Offset(194, 28));
          await advance(t);
          expect(find.text('4,5 / 5'), findsOneWidget);
        }
        expect(t.takeException(), isNull);
        if (!_compact && scene == 'widget-notation') {
          await expectLater(
            find.byKey(key),
            matchesGoldenFile('goldens/notation-${dark ? 'nuit' : 'jour'}.png'),
          );
        }
        if (_output.isNotEmpty) {
          final render =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final img = await t.runAsync(() => render.toImage(pixelRatio: 2));
          final bytes = await t.runAsync(
            () => img!.toByteData(format: ui.ImageByteFormat.png),
          );
          img!.dispose();
          await t.runAsync(() async {
            final file = File(
              '$_output/${_compact ? 'compact-' : ''}$scene-${dark ? 'nuit' : 'jour'}.png',
            );
            await file.parent.create(recursive: true);
            await file.writeAsBytes(bytes!.buffer.asUint8List());
          });
        }
        if (scene == 'widget-notation') {
          await t.tap(find.text('Enregistrer'));
          await advance(t);
          expect(c.read(personalRatingProvider(_isbn)), 4.5);
          final context = t.element(find.byType(RatingSummaryCard));
          showRatingSheet(context, _isbn);
          await advance(t);
          await t.tap(find.text('Supprimer ma note'));
          await advance(t);
          expect(c.read(personalRatingProvider(_isbn)), isNull);
        }
        await t.pumpWidget(const SizedBox.shrink());
        await advance(t);
        c.dispose();
      });
    }
  }
}
