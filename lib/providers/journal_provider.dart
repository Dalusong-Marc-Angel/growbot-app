import 'package:flutter/foundation.dart';
import '../model/journal_entry.dart';
import '../services/journal_service.dart';

class JournalProvider extends ChangeNotifier {
  final JournalService _service = JournalService();
  
  List<JournalEntry> _entries = [];
  String _searchQuery = '';
  bool _showOnlyFavorites = false; // Added favorite filter state
  bool _isLoading = false;

  bool get showOnlyFavorites => _showOnlyFavorites;

  List<JournalEntry> get entries {
    List<JournalEntry> filtered = _entries;

    // Apply favorite filter if active
    if (_showOnlyFavorites) {
      filtered = filtered.where((e) => e.isFavorite).toList();
    }

    // Apply search query filter if active
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((entry) {
        return entry.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               entry.content.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    return filtered;
  }

  bool get isLoading => _isLoading;

  void toggleFavoritesFilter() {
    _showOnlyFavorites = !_showOnlyFavorites;
    notifyListeners();
  }

  Future<void> loadEntries(bool isGuest, String? userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _entries = await _service.getEntries(isGuest, userId);
    } catch (e) {
      debugPrint("Error loading entries: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> addEntry({
    required String title,
    required String content,
    DateTime? customDate,
    required bool isGuest,
    required String? userId,
  }) async {
    final now = DateTime.now();
    final newEntry = JournalEntry(
      id: now.millisecondsSinceEpoch.toString(),
      title: title.trim().isEmpty ? "${now.month}/${now.day}/${now.year}" : title,
      content: content,
      date: customDate ?? now,
    );

    await _service.saveEntry(newEntry, isGuest, userId);
    _entries.insert(0, newEntry);
    notifyListeners();
  }

  Future<void> updateEntry(JournalEntry entry, bool isGuest, String? userId) async {
    await _service.updateEntry(entry, isGuest, userId);
    final index = _entries.indexWhere((e) => e.id == entry.id);
    if (index != -1) {
      _entries[index] = entry;
      notifyListeners();
    }
  }

  Future<void> toggleFavorite(JournalEntry entry, bool isGuest, String? userId) async {
    final updated = entry.copyWith(isFavorite: !entry.isFavorite);
    await updateEntry(updated, isGuest, userId);
  }

  Future<void> deleteEntry(String id, bool isGuest, String? userId) async {
    await _service.deleteEntry(id, isGuest, userId);
    _entries.removeWhere((e) => e.id == id);
    notifyListeners();
  }
}