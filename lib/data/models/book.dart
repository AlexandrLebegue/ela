import 'dart:convert';

enum PopularityBadge {
  phenomenon('🔥', 'Phénomène'),
  trending('📈', 'Tendance'),
  hiddenGem('💎', 'Pépite cachée'),
  timelessClassic('🏺', 'Classique intemporel');

  const PopularityBadge(this.emoji, this.label);

  final String emoji;
  final String label;

  String get labelWithEmoji => '$emoji $label';
}

class Book {
  const Book({
    required this.isbn,
    required this.title,
    required this.author,
    required this.genre,
    required this.year,
    required this.badge,
    required this.readersCount,
    this.coverUrl,
    this.description,
    this.publisher,
    this.priceEur,
    this.usedPriceEur,
  });

  final String isbn;
  final String title;
  final String author;
  final String? coverUrl;
  final String? description;
  final String genre;
  final int year;
  final String? publisher;
  final PopularityBadge badge;
  final int readersCount;
  final double? priceEur;
  final double? usedPriceEur;

  factory Book.fromJson(Map<String, dynamic> json) => Book(
        isbn: json['isbn'] as String,
        title: json['title'] as String,
        author: json['author'] as String,
        coverUrl: json['coverUrl'] as String?,
        description: json['description'] as String?,
        genre: json['genre'] as String,
        year: json['year'] as int,
        publisher: json['publisher'] as String?,
        badge: PopularityBadge.values.firstWhere(
          (b) => b.name == json['badge'],
          orElse: () => PopularityBadge.trending,
        ),
        readersCount: json['readersCount'] as int,
        priceEur: (json['priceEur'] as num?)?.toDouble(),
        usedPriceEur: (json['usedPriceEur'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'isbn': isbn,
        'title': title,
        'author': author,
        'coverUrl': coverUrl,
        'description': description,
        'genre': genre,
        'year': year,
        'publisher': publisher,
        'badge': badge.name,
        'readersCount': readersCount,
        'priceEur': priceEur,
        'usedPriceEur': usedPriceEur,
      };

  String get badgeLabel => badge.labelWithEmoji;

  String get titleAuthor => '$title — $author';

  @override
  String toString() => 'Book($isbn, $title)';

  @override
  bool operator ==(Object other) =>
      other is Book && other.isbn == isbn && other.title == title;

  @override
  int get hashCode => Object.hash(isbn, title);
}

String bookToJsonString(Book book) => jsonEncode(book.toJson());

Book bookFromJsonString(String raw) =>
    Book.fromJson(jsonDecode(raw) as Map<String, dynamic>);
