import '../models/book.dart';

/// Tendances : listes par catégorie, badges de popularité.
abstract interface class TrendService {
  Future<List<String>> categories();

  Future<List<Book>> trending({String? category});
}
