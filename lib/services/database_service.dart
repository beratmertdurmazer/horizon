import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:horizon_protocol/models/game_models.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'horizon_protocol.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE candidates(
            id TEXT PRIMARY KEY,
            name TEXT,
            position TEXT,
            scores TEXT,
            behavioralFlags TEXT,
            createdAt TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE decisions(
            id TEXT PRIMARY KEY,
            candidateId TEXT,
            moduleId TEXT,
            chapterId TEXT,
            choiceId TEXT,
            durationMs INTEGER,
            triggers TEXT,
            timestamp TEXT,
            FOREIGN KEY(candidateId) REFERENCES candidates(id)
          )
        ''');

        await db.execute('''
          CREATE TABLE chapter_metrics(
            id TEXT PRIMARY KEY,
            candidateId TEXT,
            chapterId TEXT,
            totalTimeMs INTEGER,
            additionalData TEXT,
            timestamp TEXT,
            FOREIGN KEY(candidateId) REFERENCES candidates(id)
          )
        ''');
      },
    );
  }

  // Candidate Operations
  Future<void> insertCandidate(Candidate candidate) async {
    final db = await database;
    await db.insert(
      'candidates',
      {
        ...candidate.toMap(),
        'scores': jsonEncode(candidate.scores),
        'behavioralFlags': jsonEncode(candidate.behavioralFlags),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateCandidateScores(String id, Map<String, double> scores, List<String> flags) async {
    final db = await database;
    await db.update(
      'candidates',
      {
        'scores': jsonEncode(scores),
        'behavioralFlags': jsonEncode(flags),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Decision Operations
  Future<void> insertDecision(Decision decision) async {
    final db = await database;
    await db.insert(
      'decisions',
      {
        ...decision.toMap(),
        'triggers': jsonEncode(decision.triggers),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Chapter Metric Operations
  Future<void> insertChapterMetric(ChapterMetric metric) async {
    final db = await database;
    await db.insert(
      'chapter_metrics',
      {
        ...metric.toMap(),
        'additionalData': jsonEncode(metric.additionalData),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Query Operations
  Future<List<Decision>> getDecisionsForCandidate(String candidateId) async {
    final db = await database;
    final maps = await db.query(
      'decisions',
      where: 'candidateId = ?',
      whereArgs: [candidateId],
    );
    return List.generate(maps.length, (i) {
      return Decision(
        id: maps[i]['id'] as String,
        candidateId: maps[i]['candidateId'] as String,
        moduleId: maps[i]['moduleId'] as String,
        chapterId: maps[i]['chapterId'] as String,
        choiceId: maps[i]['choiceId'] as String,
        durationMs: maps[i]['durationMs'] as int,
        triggers: List<String>.from(jsonDecode(maps[i]['triggers'] as String)),
        timestamp: DateTime.parse(maps[i]['timestamp'] as String),
      );
    });
  }

  Future<List<ChapterMetric>> getMetricsForCandidate(String candidateId) async {
    final db = await database;
    final maps = await db.query(
      'chapter_metrics',
      where: 'candidateId = ?',
      whereArgs: [candidateId],
    );
    return List.generate(maps.length, (i) {
      return ChapterMetric(
        id: maps[i]['id'] as String,
        candidateId: maps[i]['candidateId'] as String,
        chapterId: maps[i]['chapterId'] as String,
        totalTimeMs: maps[i]['totalTimeMs'] as int,
        additionalData: jsonDecode(maps[i]['additionalData'] as String),
        timestamp: DateTime.parse(maps[i]['timestamp'] as String),
      );
    });
  }

  Future<List<Candidate>> getAllCandidates() async {
    final db = await database;
    final maps = await db.query('candidates', orderBy: 'createdAt DESC');
    return List.generate(maps.length, (i) {
      return Candidate(
        id: maps[i]['id'] as String,
        name: maps[i]['name'] as String,
        position: maps[i]['position'] as String,
        scores: Map<String, double>.from(jsonDecode(maps[i]['scores'] as String)),
        behavioralFlags: List<String>.from(jsonDecode(maps[i]['behavioralFlags'] as String)),
        createdAt: DateTime.parse(maps[i]['createdAt'] as String),
      );
    });
  }
}
