import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io' show Platform;
import '../models/journal_entry.dart';

import 'package:sqflite_common_ffi/sqflite_ffi.dart' as sqflite_ffi;

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static bool _initialized = false;
  static DatabaseFactory? _databaseFactory;

  DatabaseHelper._init();

  static Future<void> initializeDatabaseFactory() async {
    if (!_initialized) {
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        sqflite_ffi.sqfliteFfiInit();
        _databaseFactory = sqflite_ffi.databaseFactoryFfi;
      } else {
        _databaseFactory = databaseFactory;
      }
      _initialized = true;
    }
  }

  Future<Database> get database async {
    if (_database != null) return _database!;

    await initializeDatabaseFactory();

    _database = await _initDB('journal.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    String dbPath;

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final appDocDir = await getApplicationDocumentsDirectory();
      dbPath = appDocDir.path;
    } else {
      dbPath = await getDatabasesPath();
    }

    final path = join(dbPath, filePath);

    final factory = _databaseFactory ?? databaseFactory;

    return await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 2,
        onCreate: _createDB,
        onUpgrade: _upgradeDB,
      ),
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE journal_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        mood TEXT NOT NULL,
        moodValue INTEGER NOT NULL,
        entryDate TEXT NOT NULL,
        locationName TEXT,
        latitude REAL,
        longitude REAL,
        tags TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_entry_date ON journal_entries(entryDate)
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('DROP TABLE IF EXISTS tasks');
      await _createDB(db, newVersion);
    }
  }

  Future<int> insertEntry(JournalEntry entry) async {
    final db = await database;
    return await db.insert('journal_entries', entry.toMap());
  }

  Future<List<JournalEntry>> getAllEntries() async {
    final db = await database;
    final result = await db.query(
      'journal_entries',
      orderBy: 'entryDate DESC',
    );
    return result.map((map) => JournalEntry.fromMap(map)).toList();
  }

  Future<JournalEntry?> getEntryById(int id) async {
    final db = await database;
    final result = await db.query(
      'journal_entries',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isNotEmpty) {
      return JournalEntry.fromMap(result.first);
    }
    return null;
  }

  Future<List<JournalEntry>> getEntriesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await database;
    final result = await db.query(
      'journal_entries',
      where: 'entryDate >= ? AND entryDate <= ?',
      whereArgs: [
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      ],
      orderBy: 'entryDate DESC',
    );
    return result.map((map) => JournalEntry.fromMap(map)).toList();
  }

  Future<List<JournalEntry>> getEntriesForDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return getEntriesByDateRange(startOfDay, endOfDay);
  }

  Future<int> updateEntry(JournalEntry entry) async {
    final db = await database;
    return await db.update(
      'journal_entries',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<int> deleteEntry(int id) async {
    final db = await database;
    return await db.delete(
      'journal_entries',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<JournalEntry>> getEntriesByMood(Mood mood) async {
    final db = await database;
    final result = await db.query(
      'journal_entries',
      where: 'moodValue = ?',
      whereArgs: [mood.value],
      orderBy: 'entryDate DESC',
    );
    return result.map((map) => JournalEntry.fromMap(map)).toList();
  }

  Future<Map<Mood, int>> getMoodStatistics(
      DateTime startDate, DateTime endDate) async {
    final db = await database;
    final result = await db.query(
      'journal_entries',
      columns: ['moodValue'],
      where: 'entryDate >= ? AND entryDate <= ?',
      whereArgs: [
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      ],
    );

    final Map<Mood, int> stats = {};
    for (final mood in Mood.values) {
      stats[mood] = 0;
    }

    for (final row in result) {
      final mood = Mood.fromValue(row['moodValue'] as int);
      stats[mood] = (stats[mood] ?? 0) + 1;
    }

    return stats;
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
