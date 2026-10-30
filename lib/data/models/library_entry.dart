import 'dart:convert';

enum LibrarySection { history, toRead }

class LibraryEntry {
  const LibraryEntry({
    required this.isbn,
    required this.section,
    required this.addedAt,
  });

  final String isbn;
  final LibrarySection section;
  final DateTime addedAt;

  LibraryEntry copyWith({LibrarySection? section, DateTime? addedAt}) =>
      LibraryEntry(
        isbn: isbn,
        section: section ?? this.section,
        addedAt: addedAt ?? this.addedAt,
      );

  factory LibraryEntry.fromMap(Map<String, dynamic> map) => LibraryEntry(
        isbn: map['isbn'] as String,
        section: LibrarySection.values
            .firstWhere((s) => s.name == map['section'], orElse: () => LibrarySection.history),
        addedAt: DateTime.parse(map['addedAt'] as String),
      );

  Map<String, dynamic> toMap() => {
        'isbn': isbn,
        'section': section.name,
        'addedAt': addedAt.toIso8601String(),
      };

  @override
  String toString() => 'LibraryEntry($isbn, $section)';

  @override
  bool operator ==(Object other) =>
      other is LibraryEntry &&
      other.isbn == isbn &&
      other.section == section;

  @override
  int get hashCode => Object.hash(isbn, section);
}

String libraryEntriesToJson(List<LibraryEntry> entries) =>
    jsonEncode(entries.map((e) => e.toMap()).toList());

List<LibraryEntry> libraryEntriesFromJson(String raw) =>
    (jsonDecode(raw) as List)
        .map((e) => LibraryEntry.fromMap(e as Map<String, dynamic>))
        .toList();
