import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/statistics.dart';

class StatisticsService {
  static final StatisticsService _instance = StatisticsService._internal();
  factory StatisticsService() => _instance;
  StatisticsService._internal();

  Database? _database;
  static const String _tableName = 'statistics';
  static const int _statsId = 1; // Используем фиксированный ID = 1

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'statistics.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            id INTEGER PRIMARY KEY,
            speech_to_text_sent_bytes INTEGER NOT NULL DEFAULT 0,
            speech_to_text_received_bytes INTEGER NOT NULL DEFAULT 0,
            openai_sent_bytes INTEGER NOT NULL DEFAULT 0,
            openai_received_bytes INTEGER NOT NULL DEFAULT 0,
            questions_detected INTEGER NOT NULL DEFAULT 0,
            sentences_recognized INTEGER NOT NULL DEFAULT 0,
            last_updated INTEGER NOT NULL
          )
        ''');
        // Вставляем начальную запись
        await db.insert(_tableName, Statistics.empty().toMap());
      },
    );
  }

  Future<Statistics> getStatistics() async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [_statsId],
    );

    if (maps.isEmpty) {
      // Если записи нет, создаем её
      final empty = Statistics.empty();
      await db.insert(_tableName, empty.toMap());
      return empty;
    }

    return Statistics.fromMap(maps.first);
  }

  Future<void> updateStatistics(Statistics stats) async {
    final db = await database;
    await db.update(
      _tableName,
      stats.copyWith(id: _statsId, lastUpdated: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [_statsId],
    );
  }

  Future<void> addSpeechToTextSent(int bytes) async {
    final stats = await getStatistics();
    await updateStatistics(
      stats.copyWith(
        speechToTextSentBytes: stats.speechToTextSentBytes + bytes,
      ),
    );
  }

  Future<void> addSpeechToTextReceived(int bytes) async {
    final stats = await getStatistics();
    await updateStatistics(
      stats.copyWith(
        speechToTextReceivedBytes: stats.speechToTextReceivedBytes + bytes,
      ),
    );
  }

  Future<void> addOpenAiSent(int bytes) async {
    final stats = await getStatistics();
    await updateStatistics(
      stats.copyWith(
        openAiSentBytes: stats.openAiSentBytes + bytes,
      ),
    );
  }

  Future<void> addOpenAiReceived(int bytes) async {
    final stats = await getStatistics();
    await updateStatistics(
      stats.copyWith(
        openAiReceivedBytes: stats.openAiReceivedBytes + bytes,
      ),
    );
  }

  Future<void> incrementQuestionsDetected() async {
    final stats = await getStatistics();
    await updateStatistics(
      stats.copyWith(
        questionsDetected: stats.questionsDetected + 1,
      ),
    );
  }

  Future<void> incrementSentencesRecognized() async {
    final stats = await getStatistics();
    await updateStatistics(
      stats.copyWith(
        sentencesRecognized: stats.sentencesRecognized + 1,
      ),
    );
  }

  Future<void> resetStatistics() async {
    final db = await database;
    await db.update(
      _tableName,
      Statistics.empty().toMap(),
      where: 'id = ?',
      whereArgs: [_statsId],
    );
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}

