import '../models/curation_result.dart';
import '../services/curation_service.dart';
import 'demo_books.dart';

class FakeCurationService implements CurationService {
  @override
  Future<CurationResult> curate(String isbn) async {
    final book = DemoData.byIsbnLookup(isbn);
    if (book == null) {
      throw StateError('Livre inconnu de la curation : $isbn');
    }
    return DemoData.curate(book);
  }
}
