import 'package:ela/data/models/rating.dart';
import 'package:ela/data/models/review.dart';
import 'package:ela/data/fake/fake_rating_service.dart';
import 'package:ela/data/fake/fake_review_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('Demi-étoiles, bornes, conversion de source et arrondi', () {
    for (var i = 1; i <= 10; i++) {
      expect(BookRating.isValid(i / 2), isTrue);
    }
    for (final v in [0.0, 5.5, 3.7, double.nan, double.infinity]) {
      expect(BookRating.isValid(v), isFalse);
    }
    expect(BookRating.halfStar(3.74), 3.5);
    expect(BookRating.halfStar(3.75), 4);
    expect(BookRating.fromScale(17, 20), 4.25);
    expect(BookRating.fromScale(null, 10), isNull);
    expect(BookRating.fromScale(11, 10), isNull);
    final summary = RatingSummary([
      for (final v in [4.0, 4.5, 4.5])
        BookRating(isbn: 'a', userId: '$v', value: v),
    ]);
    expect(summary.label, '4,3');
    expect(summary.count, 3);
    expect(summary.histogram[5], 2);
    expect(summary.histogram[4], 1);
    expect(RatingSummary([]).average, 0);
  });
  test(
    'Une note par utilisateur et livre, modification, suppression et persistance',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final service = FakeRatingService(prefs);
      final snapshots = <List<BookRating>>[];
      final sub = service.watchRatings().listen(snapshots.add);
      await service.setRating('isbn', 'alice', 3.5);
      await service.setRating('isbn', 'bob', 5);
      await service.setRating('isbn', 'alice', 4);
      expect(
        RatingSummary(
          service.currentRatings().where((r) => r.isbn == 'isbn'),
        ).average,
        4.5,
      );
      expect(
        FakeRatingService(
          prefs,
        ).currentRatings().where((r) => r.isbn == 'isbn').length,
        2,
      );
      await expectLater(
        service.setRating('isbn', 'alice', 3.7),
        throwsArgumentError,
      );
      await service.deleteRating('isbn', 'alice');
      expect(
        service.currentRatings().where((r) => r.isbn == 'isbn').single.userId,
        'bob',
      );
      await Future<void>.delayed(Duration.zero);
      expect(snapshots.last.where((r) => r.isbn == 'isbn').length, 1);
      await sub.cancel();
    },
  );
  test(
    'Avis : note obligatoire, remplacement par auteur, suppression persistée',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final service = FakeReviewService(prefs);
      Review review(double? value) => Review(
        id: 'mine',
        isbn: 'isbn',
        source: ReviewSource.community,
        author: 'Alice',
        userId: 'alice',
        title: '',
        text: '',
        rating: value,
        publishedAt: DateTime(2026),
      );
      await expectLater(
        service.addCommunityReview(review(null)),
        throwsArgumentError,
      );
      await service.addCommunityReview(review(3.5));
      await service.addCommunityReview(review(4.5));
      expect(
        (await FakeReviewService(prefs).communityReviews('isbn')).single.rating,
        4.5,
      );
      await service.deleteCommunityReview('isbn', 'alice');
      expect(await FakeReviewService(prefs).communityReviews('isbn'), isEmpty);
    },
  );
}
