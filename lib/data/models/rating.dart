/// Une seule note par lecteur et ISBN, sur une échelle de 0,5 à 5.
class BookRating {
  const BookRating({
    required this.isbn,
    required this.userId,
    required this.value,
  });
  final String isbn;
  final String userId;
  final double value;

  static bool isValid(double value) =>
      value.isFinite &&
      value >= .5 &&
      value <= 5 &&
      value * 2 == (value * 2).roundToDouble();
  static double halfStar(double value) => (value.clamp(.5, 5) * 2).round() / 2;
  static double? fromScale(double? value, double scale) =>
      value == null ||
          !value.isFinite ||
          scale <= 0 ||
          !scale.isFinite ||
          value < 0 ||
          value > scale
      ? null
      : value / scale * 5;
}

class RatingSummary {
  RatingSummary(Iterable<BookRating> ratings) {
    for (final rating in ratings) {
      count++;
      _sum += rating.value;
      // Une demi-étoile rejoint la tranche supérieure (4,5 → 5).
      histogram[rating.value.ceil()] =
          (histogram[rating.value.ceil()] ?? 0) + 1;
    }
  }
  int count = 0;
  double _sum = 0;
  final Map<int, int> histogram = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
  double get average => count == 0 ? 0 : _sum / count;
  String get label => average.toStringAsFixed(1).replaceAll('.', ',');
}
