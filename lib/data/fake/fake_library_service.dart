import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/library_entry.dart';
import '../services/library_service.dart';
import 'fake_delay.dart';

/// Persistance locale SharedPreferences : l'Historique et la PAL
/// fonctionnent sans compte, même hors-ligne.
class FakeLibraryService implements LibraryService {
  FakeLibraryService(this._prefs) {
    _entries = _load();
  }

  final SharedPreferences _prefs;
  static const _key = 'ela.library';

  late List<LibraryEntry> _entries;
  final StreamController<List<LibraryEntry>> _controller =
      StreamController<List<LibraryEntry>>.broadcast();

  @override
  Stream<List<LibraryEntry>> watchEntries() => Stream.multi((controller) {
        // Instantané initial : un abonnement tardif ne rate pas l'état.
        controller.add(List.unmodifiable(_entries));
        final sub = _controller.stream.listen(controller.add);
        controller.onCancel = sub.cancel;
      });

  List<LibraryEntry> _load() {
    final raw = _prefs.getString(_key);
    if (raw == null) return [];
    try {
      return libraryEntriesFromJson(raw);
    } catch (_) {
      return [];
    }
  }

  void _persist() {
    _prefs.setString(_key, libraryEntriesToJson(_entries));
    _controller.add(List.unmodifiable(_entries));
  }

  bool _has(String isbn, LibrarySection section) =>
      _entries.any((e) => e.isbn == isbn && e.section == section);

  @override
  Future<void> addHistory(String isbn) async {
    await fakeDelay(min: const Duration(milliseconds: 150),
        max: const Duration(milliseconds: 400));
    if (_has(isbn, LibrarySection.history)) return;
    _entries.add(
      LibraryEntry(isbn: isbn, section: LibrarySection.history,
          addedAt: DateTime.now()),
    );
    _entries.sort((a, b) => b.addedAt.compareTo(a.addedAt));
    _persist();
  }

  @override
  Future<void> addToRead(String isbn) async {
    await fakeDelay(min: const Duration(milliseconds: 150),
        max: const Duration(milliseconds: 400));
    if (_has(isbn, LibrarySection.toRead)) return;
    _entries.add(
      LibraryEntry(isbn: isbn, section: LibrarySection.toRead,
          addedAt: DateTime.now()),
    );
    _persist();
  }

  @override
  Future<void> removeEntry(String isbn, LibrarySection section) async {
    await fakeDelay(min: const Duration(milliseconds: 150),
        max: const Duration(milliseconds: 400));
    _entries.removeWhere((e) => e.isbn == isbn && e.section == section);
    _persist();
  }

  List<LibraryEntry> get historyEntries => _entries
      .where((e) => e.section == LibrarySection.history)
      .toList()
    ..sort((a, b) => b.addedAt.compareTo(a.addedAt));

  List<LibraryEntry> get toReadEntries => _entries
      .where((e) => e.section == LibrarySection.toRead)
      .toList()
    ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
}
