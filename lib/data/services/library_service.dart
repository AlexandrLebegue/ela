import '../models/library_entry.dart';

/// Bibliothèque locale : Historique (passif) + Pile à Lire (active).
/// Fonctionne sans compte (persistance locale).
abstract interface class LibraryService {
  Stream<List<LibraryEntry>> watchEntries();

  Future<void> addHistory(String isbn);

  Future<void> addToRead(String isbn);

  Future<void> removeEntry(String isbn, LibrarySection section);
}
