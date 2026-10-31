import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/rating.dart';
import '../services/rating_service.dart';
import 'demo_books.dart';
import 'fake_delay.dart';

class FakeRatingService implements RatingService {
  FakeRatingService(this.prefs) {
    for (final book in DemoData.books) {
      final seed = stableHash(book.isbn);
      for (var i = 0; i < 210 + seed % 380; i++) {
        final roll = (seed + i * 37) % 100;
        final value = roll < 4
            ? 1.5
            : roll < 12
            ? 2.5
            : roll < 30 + seed % 17
            ? 3.5
            : roll < 65 + seed % 13
            ? 4.5
            : 5.0;
        _demo.add(BookRating(isbn: book.isbn, userId: 'demo-$i', value: value));
      }
    }
    try {
      final rows = jsonDecode(prefs.getString(_key) ?? '[]') as List;
      for (final row in rows) {
        final value = (row['value'] as num).toDouble();
        if (BookRating.isValid(value)) {
          _own.add(
            BookRating(
              isbn: row['isbn'] as String,
              userId: row['userId'] as String,
              value: value,
            ),
          );
        }
      }
    } catch (_) {
      _own.clear();
    }
  }
  final SharedPreferences prefs;
  static const _key = 'ela.ratings';
  final _demo = <BookRating>[];
  final _own = <BookRating>[];
  final _changes = StreamController<List<BookRating>>.broadcast();
  @override
  List<BookRating> currentRatings() => List.unmodifiable([..._demo, ..._own]);
  @override
  Stream<List<BookRating>> watchRatings() => Stream.multi((sink) {
    sink.add(currentRatings());
    final sub = _changes.stream.listen(sink.add);
    sink.onCancel = sub.cancel;
  });
  Future<void> _persist() async {
    await prefs.setString(
      _key,
      jsonEncode(
        _own
            .map((r) => {'isbn': r.isbn, 'userId': r.userId, 'value': r.value})
            .toList(),
      ),
    );
    _changes.add(currentRatings());
  }

  @override
  Future<void> setRating(String isbn, String userId, double value) async {
    if (!BookRating.isValid(value)) {
      throw ArgumentError.value(value, 'value', 'Demi-étoiles de 0,5 à 5');
    }
    _own.removeWhere((r) => r.isbn == isbn && r.userId == userId);
    _own.add(BookRating(isbn: isbn, userId: userId, value: value));
    await _persist();
  }

  @override
  Future<void> deleteRating(String isbn, String userId) async {
    _own.removeWhere((r) => r.isbn == isbn && r.userId == userId);
    await _persist();
  }
}
