import 'package:flutter/foundation.dart';
import '../models/journal_entry.dart';
import '../database/database_helper.dart';
import '../services/notification_service.dart';
import '../services/analytics_service.dart';

class JournalProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<JournalEntry> _entries = [];
  bool _isLoading = false;

  List<JournalEntry> get entries => _entries;
  bool get isLoading => _isLoading;

  List<JournalEntry> get todayEntries {
    final today = DateTime.now();
    return _entries.where((entry) {
      return entry.entryDate.year == today.year &&
          entry.entryDate.month == today.month &&
          entry.entryDate.day == today.day;
    }).toList();
  }

  List<JournalEntry> get weekEntries {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    weekStart.copyWith(hour: 0, minute: 0, second: 0, millisecond: 0);
    return _entries
        .where((entry) => entry.entryDate.isAfter(weekStart))
        .toList();
  }

  double get averageMoodThisWeek {
    if (weekEntries.isEmpty) return 2.0;
    final sum = weekEntries.fold<double>(
      0.0,
      (sum, entry) => sum + entry.mood.value,
    );
    return sum / weekEntries.length;
  }

  Future<void> loadEntries() async {
    _isLoading = true;
    notifyListeners();

    try {
      _entries = await _dbHelper.getAllEntries();
    } catch (e) {
      debugPrint('Error loading entries: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addEntry(JournalEntry entry) async {
    try {
      final now = DateTime.now();
      final newEntry = entry.copyWith(
        createdAt: now,
        updatedAt: now,
      );

      final id = await _dbHelper.insertEntry(newEntry);
      final insertedEntry = newEntry.copyWith(id: id);

      _entries.insert(0, insertedEntry);
      notifyListeners();

      await NotificationService.instance.scheduleDailyReminder();

      await AnalyticsService.instance.logJournalEntryCreated(
        mood: insertedEntry.mood,
        hasLocation: insertedEntry.locationName != null,
      );
    } catch (e) {
      debugPrint('Error adding entry: $e');
      rethrow;
    }
  }

  Future<void> updateEntry(JournalEntry entry) async {
    try {
      final updatedEntry = entry.copyWith(updatedAt: DateTime.now());
      await _dbHelper.updateEntry(updatedEntry);

      final index = _entries.indexWhere((e) => e.id == entry.id);
      if (index != -1) {
        _entries[index] = updatedEntry;
        notifyListeners();
      }

      await AnalyticsService.instance.logJournalEntryUpdated();
    } catch (e) {
      debugPrint('Error updating entry: $e');
      rethrow;
    }
  }

  Future<void> deleteEntry(int id) async {
    try {
      await _dbHelper.deleteEntry(id);
      _entries.removeWhere((entry) => entry.id == id);
      notifyListeners();

      await AnalyticsService.instance.logJournalEntryDeleted();
    } catch (e) {
      debugPrint('Error deleting entry: $e');
      rethrow;
    }
  }

  JournalEntry? getEntryById(int id) {
    try {
      return _entries.firstWhere((entry) => entry.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<Map<Mood, int>> getMoodStatistics(
    DateTime startDate,
    DateTime endDate,
  ) async {
    return await _dbHelper.getMoodStatistics(startDate, endDate);
  }
}
