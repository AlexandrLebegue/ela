import 'review.dart';

class CurationResult {
  const CurationResult({
    required this.isbn,
    required this.summary,
    required this.press,
    required this.web,
    required this.curatedAt,
  });

  final String isbn;
  final String summary;
  final List<Review> press;
  final List<Review> web;
  final DateTime curatedAt;

  factory CurationResult.fromJson(Map<String, dynamic> json) => CurationResult(
        isbn: json['isbn'] as String,
        summary: json['summary'] as String,
        press: (json['press'] as List)
            .map((e) => Review.fromJson(e as Map<String, dynamic>))
            .toList(),
        web: (json['web'] as List)
            .map((e) => Review.fromJson(e as Map<String, dynamic>))
            .toList(),
        curatedAt: DateTime.parse(json['curatedAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'isbn': isbn,
        'summary': summary,
        'press': press.map((e) => e.toJson()).toList(),
        'web': web.map((e) => e.toJson()).toList(),
        'curatedAt': curatedAt.toIso8601String(),
      };
}
