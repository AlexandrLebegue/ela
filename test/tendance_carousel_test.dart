import 'dart:io';
import 'dart:typed_data';
import 'package:ela/core/widgets/cover_palette.dart';
import 'dart:ui' as ui;

import 'package:ela/app.dart';
import 'package:ela/core/widgets/book_cover.dart';
import 'package:ela/data/fake/demo_books.dart';
import 'package:ela/data/models/book.dart';
import 'package:ela/data/models/library_entry.dart';
import 'package:ela/features/book_detail/book_detail_screen.dart';
import 'package:ela/features/trending/featured_carousel.dart';
import 'package:ela/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'support/fonts.dart';

const _capture = String.fromEnvironment('TENDANCE_CAPTURE_DIR');
final _boundary = GlobalKey();
final _pages = find.byKey(const ValueKey('featured-pages'));
final _catalogue = DemoData.books.toList()
  ..sort((a, b) => b.readersCount.compareTo(a.readersCount));
PageController _controller(WidgetTester t) =>
    t.widget<PageView>(_pages).controller!;

Future<void> _advance(WidgetTester t, [int milliseconds = 1000]) async {
  for (var i = 0; i < milliseconds; i += 100) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

Future<ProviderContainer> _mount(
  WidgetTester t, {
  bool dark = false,
  bool compact = false,
  bool reduced = false,
  List<Book>? books,
}) async {
  t.view.devicePixelRatio = 1;
  t.view.physicalSize = compact ? const Size(360, 640) : const Size(412, 915);
  t.platformDispatcher.textScaleFactorTestValue = compact ? 1.3 : 1;
  t.platformDispatcher.accessibilityFeaturesTestValue =
      FakeAccessibilityFeatures(disableAnimations: reduced);
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
      sharedPreferencesProvider.overrideWithValue(
        await SharedPreferences.getInstance(),
      ),
      trendingProvider('Tous').overrideWith((ref) async => books ?? _catalogue),
    ],
  );
  addTearDown(() async {
    await t.pumpWidget(const SizedBox.shrink());
    await _advance(t);
    c.dispose();
  });
  await t.pumpWidget(
    UncontrolledProviderScope(
      container: c,
      child: RepaintBoundary(key: _boundary, child: const ElaApp()),
    ),
  );
  await _advance(t);
  return c;
}

Future<void> _captureFrame(WidgetTester t, String name) async {
  if (_capture.isEmpty) return;
  final render =
      _boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = await t.runAsync(() => render.toImage(pixelRatio: 2.625));
  final bytes = await t.runAsync(
    () => image!.toByteData(format: ui.ImageByteFormat.png),
  );
  image!.dispose();
  await t.runAsync(() async {
    final file = File('$_capture/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadAppFonts);
  test(
    'Palette : dominante réelle, marges blanches et transparence ignorées',
    () {
      final bytes = Uint8List.fromList([
        255,
        255,
        255,
        255,
        112,
        59,
        67,
        255,
        113,
        60,
        68,
        255,
        10,
        120,
        30,
        255,
        10,
        120,
        30,
        0,
      ]);
      expect(dominantCoverColor(bytes), const Color.fromARGB(255, 112, 59, 67));
      expect(
        dominantCoverColor(Uint8List.fromList([255, 255, 255, 255])),
        isNull,
      );
    },
  );

  for (final dark in [false, true]) {
    final theme = dark ? 'nuit' : 'jour';
    testWidgets('Tendance $theme : goldens, quatre positions et rayons', (
      t,
    ) async {
      await _mount(t, dark: dark, reduced: true);
      for (var i = 0; i < 4; i++) {
        if (i > 0) {
          await t.drag(_pages, const Offset(-280, 0));
          await _advance(t);
        }
        expect(_controller(t).page, closeTo(i + 1, .001));
        expect(find.text(_catalogue[i].title), findsWidgets);
        await _captureFrame(t, 'apres/$theme/0${i + 1}-hero');
        if (i == 0 || i == 2) {
          await expectLater(
            find.byKey(_boundary),
            matchesGoldenFile('goldens/tendance-$theme-$i.png'),
          );
        }
      }
      await t.scrollUntilVisible(
        find.text('En hausse cette semaine'),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await _advance(t);
      await _captureFrame(t, 'apres/$theme/05-rayons');
      final top = find.byKey(const PageStorageKey('shelf-top'));
      await t.drag(top, const Offset(-1500, 0));
      await _advance(t);
      await t.drag(top, const Offset(-1500, 0));
      await _advance(t);
      expect(find.text('10'), findsOneWidget);
      await t.scrollUntilVisible(
        find.text('Une soirée, un livre'),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Classiques qu’on relit'), findsOneWidget);
      expect(t.takeException(), isNull);
    });

    testWidgets('Tendance $theme : 360 × 640, texte 1,3 et accès aux rayons', (
      t,
    ) async {
      await _mount(t, dark: dark, compact: true, reduced: true);
      for (var i = 0; i < 5; i++) {
        await t.drag(_pages, const Offset(-250, 0));
        await _advance(t);
        expect(t.takeException(), isNull);
      }
      await t.scrollUntilVisible(
        find.text('Une soirée, un livre'),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await _advance(t);
      await _captureFrame(t, 'compact-$theme');
      expect(t.takeException(), isNull);
    });
  }

  testWidgets('Défilement lent, pause au toucher, reprise après inactivité', (
    t,
  ) async {
    await _mount(t);
    await _advance(t, 7500);
    expect(_controller(t).page, closeTo(2, .001));
    final gesture = await t.startGesture(
      t.getCenter(_pages) + const Offset(20, 0),
    );
    final page = _controller(t).page!;
    await _advance(t, 16000);
    expect(_controller(t).page, page);
    await gesture.moveBy(const Offset(20, 0));
    await gesture.up();
    await _advance(t, 10000);
    expect(_controller(t).page, page);
    await _advance(t, 4000);
    expect(_controller(t).page, isNot(page));
  });

  testWidgets(
    'Réduction des animations : stable et navigation manuelle possible',
    (t) async {
      await _mount(t, reduced: true);
      await _advance(t, 30000);
      expect(_controller(t).page, 1);
      expect(find.byTooltip('Mettre le carrousel en pause'), findsNothing);
      await t.drag(_pages, const Offset(-280, 0));
      await _advance(t);
      expect(_controller(t).page, 2);
    },
  );

  testWidgets(
    'Pause explicite et suspension en arrière-plan ou dans un autre onglet',
    (t) async {
      await _mount(t);
      await t.tap(find.byTooltip('Mettre le carrousel en pause'));
      await _advance(t, 18000);
      expect(_controller(t).page, 1);
      await t.tap(find.byTooltip('Reprendre le carrousel'));
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await _advance(t, 18000);
      expect(_controller(t).page, 1);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await t.tap(find.text('Recherche').last);
      await _advance(t, 18000);
      await t.tap(find.text('Tendance').last);
      await _advance(t);
      expect(_controller(t).page, 1);
    },
  );

  testWidgets('L’ajout rapide persiste le bon ISBN sans doublon', (t) async {
    final c = await _mount(t, reduced: true);
    await t.tap(find.byKey(const ValueKey('quick-add-pal')));
    await _advance(t);
    final entries = c.read(libraryEntriesProvider).value!;
    expect(
      entries.where((e) => e.section == LibrarySection.toRead).single.isbn,
      _catalogue.first.isbn,
    );
    expect(find.text('Dans votre Pile à lire'), findsOneWidget);
    expect(
      t
          .widget<FilledButton>(find.byKey(const ValueKey('quick-add-pal')))
          .onPressed,
      isNull,
    );
    expect(
      c.read(sharedPreferencesProvider).getString('ela.library'),
      contains(_catalogue.first.isbn),
    );
  });

  testWidgets(
    'La couverture vole vers la fiche et le retour conserve la position',
    (t) async {
      await _mount(t);
      await t.drag(_pages, const Offset(-280, 0));
      await _advance(t);
      final book = _catalogue[1];
      final source = find.byWidgetPredicate(
        (w) => w is Hero && w.tag == trendingHeroTag('hero', book),
      );
      expect(source, findsOneWidget);
      await t.tapAt(t.getCenter(_pages));
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));
      // Le shuttle d'un Hero est un BookCover dans un Positioned/IgnorePointer
      // de l'Overlay, en dehors des deux routes (la fiche fait 110 dp).
      final flight = find.byWidgetPredicate(
        (w) => w is BookCover && w.book.isbn == book.isbn,
      );
      expect(flight, findsOneWidget);
      expect(
        find.ancestor(of: flight, matching: find.byType(Hero)),
        findsNothing,
      );
      expect(find.byType(BookDetailScreen), findsOneWidget);
      expect(
        t.widget<BookDetailScreen>(find.byType(BookDetailScreen)).heroTag,
        trendingHeroTag('hero', book),
      );
      expect(
        find.ancestor(of: flight.last, matching: find.byType(IgnorePointer)),
        findsWidgets,
      );
      await _advance(t, 18000);
      await t.tap(find.byTooltip('Retour'));
      await _advance(t);
      expect(_controller(t).page, 2);
      expect(t.takeException(), isNull);
    },
  );

  testWidgets(
    'Un seul livre : aucune boucle ni timer, sémantique et cible de 48 dp',
    (t) async {
      final semantics = t.ensureSemantics();
      try {
        await _mount(t, books: [_catalogue.first]);
        await _advance(t, 20000);
        expect(_controller(t).page, 0);
        await t.ensureVisible(find.byKey(const ValueKey('featured-dot-0')));
        await t.pump();
        expect(
          find.bySemanticsLabel('Livre 1 sur 1 : Le Petit Prince'),
          findsOneWidget,
        );
        final dot = find.bySemanticsLabel('Livre 1 sur 1 : Le Petit Prince');
        expect(t.getSize(dot).height, greaterThanOrEqualTo(48));
        expect(
          t.getSemantics(dot).getSemanticsData().hasAction(SemanticsAction.tap),
          isTrue,
        );
        expect(t.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    },
  );
}
