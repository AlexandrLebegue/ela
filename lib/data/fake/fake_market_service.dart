import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/market.dart';
import '../services/market_service.dart';
import 'demo_books.dart';
import 'fake_delay.dart';

class FakeMarketService implements MarketService {
  FakeMarketService(this.prefs) {
    _listings = [
      for (var i = 0; i < 9; i++)
        ReaderListing(
          id: 'demo-$i',
          isbn: DemoData.books[i].isbn,
          sellerId: 'reader-$i',
          seller: ['Camille', 'Sarah', 'Louis'][i % 3],
          price: 2.5 + i * .5,
          condition: BookCondition.values[1 + i % 4],
          city: ['Paris', 'Lyon', 'Bordeaux'][i % 3],
          createdAt: DateTime(
            2026,
            10,
            30,
            18,
          ).subtract(Duration(hours: i * 3)),
        ),
    ];
    try {
      _listings.insertAll(
        0,
        (jsonDecode(prefs.getString(_key) ?? '[]') as List).map(
          (e) => ReaderListing.fromJson(e as Map<String, dynamic>),
        ),
      );
    } catch (_) {
      /* Une préférence invalide ne bloque pas les annonces démo. */
    }
  }
  final SharedPreferences prefs;
  static const _key = 'ela.listings';
  late final List<ReaderListing> _listings;
  final _changes = StreamController<List<ReaderListing>>.broadcast();
  final Set<String> contacted = {};
  @override
  Stream<List<ReaderListing>> watchListings() => Stream.multi((sink) {
    sink.add(List.unmodifiable(_listings));
    final sub = _changes.stream.listen(sink.add);
    sink.onCancel = sub.cancel;
  });
  @override
  Future<List<BookOffer>> offers(String isbn) async {
    await fakeDelay();
    final book = DemoData.byIsbnLookup(isbn);
    if (book == null) return [];
    final price = book.priceEur ?? 12;
    final used = book.usedPriceEur ?? 3.5;
    return [
      BookOffer(
        isbn: isbn,
        merchant: 'Fnac',
        price: price,
        shipping: 3,
        condition: BookCondition.newBook,
      ),
      BookOffer(
        isbn: isbn,
        merchant: 'Amazon',
        price: price,
        shipping: 3,
        condition: BookCondition.newBook,
      ),
      BookOffer(
        isbn: isbn,
        merchant: 'Place des Libraires',
        price: price,
        shipping: 0,
        condition: BookCondition.newBook,
      ),
      BookOffer(
        isbn: isbn,
        merchant: 'Rakuten',
        price: used + .9,
        shipping: 2.9,
        condition: BookCondition.likeNew,
      ),
      BookOffer(
        isbn: isbn,
        merchant: 'Momox',
        price: used + 1.5,
        shipping: 1.9,
        condition: BookCondition.veryGood,
      ),
      BookOffer(
        isbn: isbn,
        merchant: 'Recyclivre',
        price: used + 2,
        shipping: 0,
        condition: BookCondition.good,
      ),
      BookOffer(
        isbn: isbn,
        merchant: 'Vinted',
        price: used,
        shipping: 3.2,
        condition: BookCondition.fair,
      ),
      BookOffer(
        isbn: isbn,
        merchant: 'Leboncoin',
        price: used + 1,
        shipping: 0,
        condition: BookCondition.veryGood,
      ),
    ];
  }

  @override
  Future<ReaderListing> publish(ReaderListing listing) async {
    if (!listing.price.isFinite ||
        listing.price <= 0 ||
        listing.price > 1000 ||
        listing.city.trim().isEmpty ||
        listing.isbn.isEmpty) {
      throw ArgumentError('Prix et ville requis');
    }
    _listings.insert(0, listing);
    await prefs.setString(
      _key,
      jsonEncode(
        _listings
            .where((e) => !e.id.startsWith('demo-'))
            .map((e) => e.toJson())
            .toList(),
      ),
    );
    _changes.add(List.unmodifiable(_listings));
    return listing;
  }

  @override
  Future<void> contact(String listingId) async {
    if (!_listings.any((e) => e.id == listingId)) {
      throw StateError('Annonce introuvable');
    }
    contacted.add(listingId);
  }
}
