import '../../core/format.dart';
import '../../core/google_books_client.dart';
import '../models/book.dart';
import '../services/book_lookup_service.dart';
import 'demo_books.dart';
import 'fake_delay.dart';

class FakeBookLookupService implements BookLookupService {
  @override
  Future<Book?> lookupByIsbn(String isbn) async {
    // Catalogue local d'abord : instantané, cohérent avec la curation démo.
    final local = DemoData.byIsbnLookup(isbn);
    if (local != null) {
      await fakeDelay(min: const Duration(milliseconds: 250));
      return local;
    }
    // Sinon, l'API publique Google Books (autorisée par le cahier des
    // charges) ; hors-ligne → null → « livre introuvable ».
    await fakeDelay(min: const Duration(milliseconds: 400));
    final vol = await GoogleBooksClient.fetchByIsbn(isbn);
    if (vol == null) return null;
    await fakeDelay(min: const Duration(milliseconds: 200));
    return _bookFromVolume(vol);
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

  static Book _bookFromVolume(Map<String, dynamic> vol) {
    final title = vol['title'] as String? ?? 'Livre inconnu';
    final authors = vol['authors'] as List?;
    final author = (authors != null && authors.isNotEmpty)
        ? authors.map((a) => a.toString()).join(', ')
        : 'Auteur inconnu';
    final links = vol['imageLinks'] as Map?;
    final cover = links?['mediumImage'] as String? ??
        links?['thumbnail'] as String?;
    final published = vol['publishedDate'] as String?;
    final year = (published != null && published.length >= 4)
        ? int.tryParse(published.substring(0, 4)) ?? 1900
        : 1900;
    final categories = vol['categories'] as List?;
    final category = (categories != null && categories.isNotEmpty)
        ? categories.first.toString()
        : null;
    return Book(
      isbn: vol['isbn'] as String? ?? '',
      title: title,
      author: author,
      coverUrl: cover?.replaceFirst(RegExp(r'^http://'), 'https://'),
      description: vol['description'] as String?,
      genre: _genreFromCategory(category),
      year: year,
      badge: PopularityBadge.trending,
      readersCount: 0,
    );
  }

  static String _genreFromCategory(String? category) {
    if (category == null) return 'Autre';
    switch (category.toLowerCase()) {
      case 'fiction':
        return 'Contemporains';
      case 'young adult fiction':
      case 'fantasy fiction':
        return 'Fantasy';
      case 'mystery fiction':
      case 'crime fiction':
      case 'thrillers':
        return 'Thrillers';
      case 'classics':
      case 'literary fiction':
        return 'Classiques';
      default:
        return category;
    }
  }
}
