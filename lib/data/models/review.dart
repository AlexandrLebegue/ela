enum ReviewSource { press, web, community }

class Review {
  const Review({
    required this.id,
    required this.isbn,
    required this.source,
    required this.author,
    required this.title,
    required this.text,
    required this.publishedAt,
    this.outlet,
    this.url,
    this.language = 'fr',
    this.likes = 0,
  });

  final String id;
  final String isbn;
  final ReviewSource source;
  final String author;
  final String? outlet;
  final String title;
  final String text;
  final String? url;
  final String language;
  final DateTime publishedAt;
  final int likes;

  factory Review.fromJson(Map<String, dynamic> json) => Review(
        id: json['id'] as String,
        isbn: json['isbn'] as String,
        source: ReviewSource.values.firstWhere((s) => s.name == json['source']),
        author: json['author'] as String,
        outlet: json['outlet'] as String?,
        title: json['title'] as String,
        text: json['text'] as String,
        url: json['url'] as String?,
        language: json['language'] as String? ?? 'fr',
        publishedAt: DateTime.parse(json['publishedAt'] as String),
        likes: json['likes'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'isbn': isbn,
        'source': source.name,
        'author': author,
        'outlet': outlet,
        'title': title,
        'text': text,
        'url': url,
        'language': language,
        'publishedAt': publishedAt.toIso8601String(),
        'likes': likes,
      };

  @override
  String toString() => 'Review($id, $source)';

  @override
  bool operator ==(Object other) => other is Review && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
