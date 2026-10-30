import '../models/review.dart';
import '../services/review_service.dart';
import 'demo_books.dart';
import 'fake_delay.dart';

class FakeReviewService implements ReviewService {
  final Map<String, List<Review>> _byIsbn = {};
  final Set<String> _reported = {};

  @override
  Future<List<Review>> communityReviews(String isbn) async {
    await fakeDelay();
    return _byIsbn.putIfAbsent(isbn, () {
      final book = DemoData.byIsbnLookup(isbn);
      return book == null ? <Review>[] : DemoData.communityFor(book);
    });
  }

  @override
  Future<Review> addCommunityReview(Review review) async {
    await fakeDelay(min: const Duration(milliseconds: 300));
    final list = _byIsbn.putIfAbsent(review.isbn, () => <Review>[]);
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
