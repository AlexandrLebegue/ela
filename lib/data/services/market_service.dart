import '../models/market.dart';

/// Offres externes et annonces lecteurs ; substituable par un backend.
abstract interface class MarketService {
  Future<List<BookOffer>> offers(String isbn);
  Stream<List<ReaderListing>> watchListings();
  Future<ReaderListing> publish(ReaderListing listing);
  Future<void> contact(String listingId);
}
