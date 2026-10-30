import '../models/book.dart';
import '../services/trend_service.dart';
import 'demo_books.dart';
import 'fake_delay.dart';

class FakeTrendService implements TrendService {
  static const List<String> _categories = [
    'Tous',
    'Classiques',
    'Contemporains',
    'Thrillers',
    'Fantasy',
  ];

  @override
  Future<List<String>> categories() async {
    await fakeDelay(min: const Duration(milliseconds: 200),
        max: const Duration(milliseconds: 600));
    return _categories;
  }

  @override
  Future<List<Book>> trending({String? category}) async {
    await fakeDelay(min: const Duration(milliseconds: 350),
        max: const Duration(milliseconds: 1200));
    final list = category == null || category == 'Tous'
        ? DemoData.books
        : DemoData.books.where((b) => b.genre == category).toList();
    // Classe par popularité communautaire décroissante.
    return list.toList()..sort((a, b) => b.readersCount.compareTo(a.readersCount));
  }
}
