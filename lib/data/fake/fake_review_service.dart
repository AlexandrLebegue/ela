import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/rating.dart';
import '../models/review.dart';
import '../services/review_service.dart';
import 'demo_books.dart';
import 'fake_delay.dart';

class FakeReviewService implements ReviewService {
  FakeReviewService([this.prefs]);
  final SharedPreferences? prefs;
  List<Review> _locals() {
    try {
      return (jsonDecode(prefs?.getString('ela.reviews') ?? '[]') as List)
          .map((r) => Review.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _save(List<Review> reviews) async {
    await prefs?.setString(
      'ela.reviews',
      jsonEncode(reviews.map((r) => r.toJson()).toList()),
    );
  }

  @override
  Future<void> deleteCommunityReview(String isbn, String userId) async {
    final list = await communityReviews(isbn);
    list.removeWhere((r) => r.userId == userId);
    await _save(
      _locals()..removeWhere((r) => r.isbn == isbn && r.userId == userId),
    );
  }

  final Map<String, List<Review>> _byIsbn = {};
  final Set<String> _reported = {};

  @override
  Future<List<Review>> communityReviews(String isbn) async {
    await fakeDelay();
    return _byIsbn.putIfAbsent(isbn, () {
      final book = DemoData.byIsbnLookup(isbn);
      return [
        ..._locals().where((r) => r.isbn == isbn),
        if (book != null) ...DemoData.communityFor(book),
      ];
    });
  }

  @override
  Future<Review> addCommunityReview(Review review) async {
    await fakeDelay(min: const Duration(milliseconds: 300));
    if (review.rating == null || !BookRating.isValid(review.rating!)) {
      throw ArgumentError('Une note est obligatoire');
    }
    final list = await communityReviews(review.isbn);
    list.removeWhere((r) => r.userId != null && r.userId == review.userId);
    final local = _locals()
      ..removeWhere((r) => r.isbn == review.isbn && r.userId == review.userId);
    await _save([...local, review]);
    list.insert(0, review);
    return review;
  }

  @override
  Future<void> reportReview(String reviewId) async {
    await fakeDelay(
      min: const Duration(milliseconds: 200),
      max: const Duration(milliseconds: 500),
    );
    _reported.add(reviewId);
  }

  bool isReported(String reviewId) => _reported.contains(reviewId);
}
