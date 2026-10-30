import '../models/book.dart';

/// Recherche de livres : par ISBN (API publique autorisée) et par texte.
abstract interface class BookLookupService {
  /// Retourne le livre correspondant à l'ISBN, ou `null` si introuvable.
  Future<Book?> lookupByIsbn(String isbn);

  /// Recherche libre (titre / auteur / ISBN).
  Future<List<Book>> search(String query);
}
