import '../../core/format.dart';
import '../models/book.dart';
import '../services/book_lookup_service.dart';
import 'demo_books.dart';
import 'fake_delay.dart';

class FakeBookLookupService implements BookLookupService {
  @override
  Future<Book?> lookupByIsbn(String isbn) async {
    await fakeDelay();
    return DemoData.byIsbnLookup(isbn);
  }

  @override
  Future<List<Book>> search(String query) async {
    await fakeDelay(min: const Duration(milliseconds: 250),
        max: const Duration(milliseconds: 900));
    final q = normalizeQuery(query);
    if (q.isEmpty) return const [];
    final words = q.split(RegExp(r'\s+'));
    return DemoData.books.where((b) {
      final haystack = normalizeQuery(
        '${b.title} ${b.author} ${b.isbn}',
      );
      return words.every((w) => haystack.contains(w));
    }).toList();
  }
}
