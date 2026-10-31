import 'package:ela/app.dart';
import 'package:ela/data/fake/fake_market_service.dart';
import 'package:ela/data/models/market.dart';
import 'package:ela/features/market/market_screen.dart';
import 'package:ela/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> advance(WidgetTester t) async {
  for (var i = 0; i < 24; i++) {
    await t.pump(const Duration(milliseconds: 150));
  }
}

Future<ProviderContainer> mount(
  WidgetTester t,
  String route, {
  Map<String, Object> seed = const {},
}) async {
  t.view.physicalSize = const Size(412, 915);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.resetPhysicalSize);
  addTearDown(t.view.resetDevicePixelRatio);
  SharedPreferences.setMockInitialValues({'ela.onboarded': true, ...seed});
  final c = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(
        await SharedPreferences.getInstance(),
      ),
    ],
  );
  addTearDown(() async {
    await t.pumpWidget(const SizedBox.shrink());
    await advance(t);
    c.dispose();
  });
  c.read(routerProvider).go(route);
  await t.pumpWidget(
    UncontrolledProviderScope(container: c, child: const ElaApp()),
  );
  await advance(t);
  return c;
}

void main() {
  test(
    'Offres : huit enseignes, port inclus dans le tri, état en premier si demandé',
    () async {
      SharedPreferences.setMockInitialValues({});
      final service = FakeMarketService(await SharedPreferences.getInstance());
      final offers = await service.offers('9782070667918');
      expect(offers.length, 8);
      expect(offers.where((o) => o.isNew).length, 3);
      final cheapest = sortedOffers(offers, OfferSort.totalPrice).first;
      expect(cheapest.merchant, 'Leboncoin');
      // Vinted a un prix de livre plus bas, mais son port change le classement.
      expect(
        cheapest.price,
        greaterThan(offers.firstWhere((o) => o.merchant == 'Vinted').price),
      );
      final condition = sortedOffers(offers, OfferSort.condition);
      expect(condition.first.condition, BookCondition.newBook);
      expect(condition.first.merchant, 'Place des Libraires');
      expect(await service.offers('unknown'), isEmpty);
    },
  );
  test('Annonce persistée, contact simulé et validation du prix', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final service = FakeMarketService(prefs);
    ReaderListing listing(double price) => ReaderListing(
      id: 'mine',
      isbn: '9782070667918',
      sellerId: 'alice',
      seller: 'Alice',
      price: price,
      condition: BookCondition.likeNew,
      city: 'Paris',
      createdAt: DateTime(2026),
      photoUrl: 'https://example.org/book.jpg',
    );
    await expectLater(service.publish(listing(-1)), throwsArgumentError);
    await service.publish(listing(4.5));
    final stored = (await FakeMarketService(prefs).watchListings().first).first;
    expect(stored.price, 4.5);
    expect(stored.photoUrl, 'https://example.org/book.jpg');
    await service.contact('mine');
    expect(service.contacted, contains('mine'));
    await expectLater(service.contact('unknown'), throwsStateError);
  });
  testWidgets('Comparateur depuis la fiche, filtrage, lien affilié et retour', (
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
    final c = await mount(t, '/livre/9782070667918');
    final open = find.text('Comparer dans le Marché');
    await t.ensureVisible(open);
    await t.pump();
    await t.tap(open);
    await advance(t);
    expect(find.byType(OfferComparison), findsOneWidget);
    expect(
      t.widget<OfferComparison>(find.byType(OfferComparison)).isbn,
      '9782070667918',
    );
    await t.tap(find.text('Neuf'));
    await advance(t);
    expect(find.text('Leboncoin'), findsNothing);
    expect(find.text('Place des Libraires'), findsOneWidget);
    final link = find.text('Voir l’offre affiliée').first;
    await t.ensureVisible(link);
    await t.pump();
    await t.tap(link);
    await advance(t);
    expect(find.textContaining('merchant=Place'), findsOneWidget);
    await t.tap(find.text('Copier le lien'));
    await advance(t);
    expect(copied, contains('isbn=9782070667918'));
    expect(copied, contains('merchant=Place'));
    await t.tap(find.byTooltip('Retour au Marché'));
    await advance(t);
    expect(
      c.read(routerProvider).routeInformationProvider.value.uri.path,
      '/livre/9782070667918',
    );
  });
  testWidgets(
    'Vendre depuis la bibliothèque, annonce, contact et Radar intégré',
    (t) async {
      final c = await mount(
        t,
        '/bibliotheque',
        seed: {
          'ela.library':
              '[{"isbn":"9782070667918","section":"toRead","addedAt":"2026-10-20T10:00:00.000"}]',
        },
      );
      await t.tap(find.text('Vendre'));
      await advance(t);
      await t.enterText(
        find.widgetWithText(TextFormField, 'Prix en euros'),
        '4,50',
      );
      await t.enterText(find.widgetWithText(TextFormField, 'Ville'), 'Paris');
      await t.ensureVisible(find.text('Publier l’annonce'));
      await t.pump();
      await t.tap(find.text('Publier l’annonce'));
      await advance(t);
      final listing = (await t.runAsync(
        () => c.read(marketServiceProvider).watchListings().first,
      ))!.first;
      expect(listing.price, 4.5);
      c.read(routerProvider).go('/annonce/${listing.id}');
      await advance(t);
      await t.ensureVisible(find.text('Contacter'));
      await t.pump();
      await t.tap(find.text('Contacter'));
      await advance(t);
      expect(find.text('Demande simulée'), findsOneWidget);
      c.read(routerProvider).go('/radar');
      await advance(t);
      expect(
        c.read(routerProvider).routeInformationProvider.value.uri.path,
        '/marche',
      );
      expect(find.text('Radar · Premium'), findsOneWidget);
      expect(find.textContaining('L’essentiel du Radar'), findsOneWidget);
    },
  );
  testWidgets('Accueil : recherche et filtre de ville des annonces proches', (
    t,
  ) async {
    await mount(t, '/marche');
    await t.enterText(find.byType(TextField), 'camus');
    await advance(t);
    expect(find.text('L’Étranger'), findsWidgets);
    expect(find.text('Les Misérables'), findsNothing);
    final city = find.byType(DropdownButtonFormField<String>);
    await t.ensureVisible(city);
    await t.pump();
    await t.tap(city);
    await advance(t);
    await t.tap(find.text('Paris').last);
    await advance(t);
    expect(find.text('Aucune annonce ici pour le moment'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}
