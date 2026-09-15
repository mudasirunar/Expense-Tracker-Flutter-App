import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart' as sql;
import '../models/expense.dart';

/// Service responsible for local persistence of expense records.
///
/// Uses native SQLite via [sqflite] on Android & iOS.
/// Seamlessly falls back to persistent [SharedPreferences] JSON storage on Web.
class DatabaseService {
  static const String dbName = 'expense_tracker.db';
  static const int dbVersion = 1;
  static const String tableName = 'expenses';
  static const String _webPrefKey = 'persistent_web_expenses';

  sql.Database? _mobileDb;
  SharedPreferences? _prefs;
  bool _isInitialized = false;

  /// Whether the database service is already initialized.
  bool get isInitialized => _isInitialized;

  /// Initializes the local database storage.
  Future<void> init({sql.Database? testDb, SharedPreferences? testPrefs}) async {
    if (_isInitialized) return;

    if (testDb != null) {
      _mobileDb = testDb;
      _isInitialized = true;
      return;
    }

    if (kIsWeb) {
      _prefs = testPrefs ?? await SharedPreferences.getInstance();
      _isInitialized = true;
      return;
    }

    // Native mobile SQLite setup
    try {
      final dbPath = await sql.getDatabasesPath();
      final path = p.join(dbPath, dbName);

      _mobileDb = await sql.openDatabase(
        path,
        version: dbVersion,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE $tableName (
              id TEXT PRIMARY KEY,
              title TEXT NOT NULL,
              amount_paisa INTEGER NOT NULL,
              category TEXT NOT NULL,
              date TEXT NOT NULL,
              notes TEXT,
              created_at TEXT NOT NULL
            )
          ''');
        },
      );
      _isInitialized = true;
    } catch (e) {
      // Fallback to SharedPreferences if native SQLite fails to load
      debugPrint('SQLite initialization fallback to SharedPreferences: $e');
      _prefs = testPrefs ?? await SharedPreferences.getInstance();
      _isInitialized = true;
    }
  }

  /// Inserts a new [expense] record.
  Future<void> insertExpense(Expense expense) async {
    _ensureInitialized();

    if (_mobileDb != null) {
      await _mobileDb!.insert(
        tableName,
        expense.toMap(),
        conflictAlgorithm: sql.ConflictAlgorithm.replace,
      );
    } else {
      final list = await getAllExpenses();
      list.removeWhere((e) => e.id == expense.id);
      list.add(expense);
      await _saveWebExpenses(list);
    }
  }

  /// Updates an existing [expense] record.
  Future<void> updateExpense(Expense expense) async {
    _ensureInitialized();

    if (_mobileDb != null) {
      await _mobileDb!.update(
        tableName,
        expense.toMap(),
        where: 'id = ?',
        whereArgs: [expense.id],
      );
    } else {
      final list = await getAllExpenses();
      final index = list.indexWhere((e) => e.id == expense.id);
      if (index != -1) {
        list[index] = expense;
        await _saveWebExpenses(list);
      }
    }
  }

  /// Deletes an expense by its [id].
  Future<void> deleteExpense(String id) async {
    _ensureInitialized();

    if (_mobileDb != null) {
      await _mobileDb!.delete(
        tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
    } else {
      final list = await getAllExpenses();
      list.removeWhere((e) => e.id == id);
      await _saveWebExpenses(list);
    }
  }

  /// Retrieves all expenses sorted chronologically (newest first).
  Future<List<Expense>> getAllExpenses() async {
    _ensureInitialized();

    if (_mobileDb != null) {
      final maps = await _mobileDb!.query(
        tableName,
        orderBy: 'date DESC, created_at DESC',
      );
      return maps.map((map) => Expense.fromMap(map)).toList();
    } else {
      final jsonString = _prefs?.getString(_webPrefKey);
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      try {
        final List<dynamic> decoded = json.decode(jsonString) as List<dynamic>;
        final list = decoded
            .map((item) => Expense.fromMap(item as Map<String, dynamic>))
            .toList();
        list.sort((a, b) {
          final cmp = b.date.compareTo(a.date);
          return cmp != 0 ? cmp : b.createdAt.compareTo(a.createdAt);
        });
        return list;
      } catch (e) {
        debugPrint('Error decoding web expenses: $e');
        return [];
      }
    }
  }

  /// Clears all expense records (useful for testing or reset).
  Future<void> clearAll() async {
    _ensureInitialized();

    if (_mobileDb != null) {
      await _mobileDb!.delete(tableName);
    } else {
      await _prefs?.remove(_webPrefKey);
    }
  }

  /// Closes database connection.
  Future<void> close() async {
    if (_mobileDb != null) {
      await _mobileDb!.close();
      _mobileDb = null;
    }
    _isInitialized = false;
  }

  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError('DatabaseService has not been initialized. Call init() first.');
    }
  }

  Future<void> _saveWebExpenses(List<Expense> expenses) async {
    final rawList = expenses.map((e) => e.toMap()).toList();
    await _prefs?.setString(_webPrefKey, json.encode(rawList));
  }
}
