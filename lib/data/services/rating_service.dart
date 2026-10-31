import '../models/rating.dart';

/// Firebase : books/{isbn}/ratings/{uid}, agrégats recalculés côté serveur.
abstract interface class RatingService {
  List<BookRating> currentRatings();
  Stream<List<BookRating>> watchRatings();
  Future<void> setRating(String isbn, String userId, double value);
  Future<void> deleteRating(String isbn, String userId);
}
