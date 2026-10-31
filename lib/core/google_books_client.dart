import 'dart:convert';
import 'package:http/http.dart' as http;
import 'flags.dart';

/// API publique sans clé ; même chemin Android et navigateur, délai borné.
class GoogleBooksClient {
  GoogleBooksClient._();
  static Future<Map<String, dynamic>?> fetchByIsbn(String isbn) async {
    if (isRunningUnderFlutterTest) return null;
    final clean = isbn.replaceAll(RegExp(r'[^0-9Xx]'), '');
    if (clean.length != 13) return null;
    final client = http.Client();
    try {
      final response = await client
          .get(
            Uri.https('www.googleapis.com', '/books/v1/volumes', {
              'q': 'isbn:$clean',
            }),
          )
          .timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) return null;
      final data =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final items = data['items'] as List?;
      if (items == null || items.isEmpty || items.first is! Map) return null;
      final info = (items.first as Map)['volumeInfo'];
      if (info is! Map) return null;
      return Map<String, dynamic>.from(info)..['isbn'] = clean;
    } catch (_) {
      return null;
    } finally {
      client.close();
    }
  }
}
