import 'dart:convert';
import 'dart:io';

import 'flags.dart';

/// Client de l'API publique Google Books (sans clé).
/// Utilisé par la recherche ISBN ; toute défaillance (hors-ligne, timeout,
/// introuvable) renvoie `null` et le catalogue local prend le relais.
class GoogleBooksClient {
  GoogleBooksClient._();

  static const String _base = 'https://www.googleapis.com/books/v1/volumes';
  static const Duration _timeout = Duration(seconds: 5);

  /// Retourne le `volumeInfo` du livre, ou `null`.
  static Future<Map<String, dynamic>?> fetchByIsbn(String isbn) async {
    // Jamais de réseau dans les tests : le catalogue local répond seul.
    if (isRunningUnderFlutterTest) return null;
    final clean = isbn.replaceAll(RegExp(r'[^0-9Xx]'), '');
    if (clean.length != 13) return null;
    HttpClient client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 4);
    try {
      final req = await client
          .getUrl(Uri.parse('$_base?q=isbn:$clean'))
          .timeout(const Duration(seconds: 4));
      final res = await req.close().timeout(_timeout);
      if (res.statusCode != 200) {
        await res.drain();
        return null;
      }
      final body = await res
          .transform(const Utf8Decoder())
          .join()
          .timeout(_timeout);
      final json = jsonDecode(body) as Map<String, dynamic>;
      final items = json['items'] as List?;
      if (items == null || items.isEmpty) return null;
      final vol = items.first;
      if (vol is! Map) return null;
      final info = vol['volumeInfo'];
      if (info is! Map) return null;
      final result = Map<String, dynamic>.from(info);
      result['isbn'] = clean;
      return result;
    } catch (_) {
      return null;
    } finally {
      client.close();
    }
  }
}
