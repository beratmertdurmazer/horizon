import 'dart:convert';
import 'dart:math';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:horizon_protocol/models/game_models.dart';
import 'package:web/web.dart' as web;

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  
  final _random = Random();

  Database? _db;

  // Web Fallback Storage
  static List<Candidate> _webCandidates = [];
  static List<Decision> _webDecisions = [];
  static List<ChapterMetric> _webMetrics = [];

  DatabaseService._internal() {
    if (kIsWeb) {
      _loadFromWebStorage();
    }
  }

  void _saveToWebStorage() {
    try {
      final candidatesJson = jsonEncode(_webCandidates.map((c) => {
        'id': c.id,
        'name': c.name,
        'position': c.position,
        'scores': c.scores,
        'behavioralFlags': c.behavioralFlags,
        'createdAt': c.createdAt.toIso8601String(),
      }).toList());
      web.window.localStorage.setItem('horizon_candidates', candidatesJson);

      final decisionsJson = jsonEncode(_webDecisions.map((d) => d.toMap()..['triggers'] = jsonEncode(d.triggers)).toList());
      web.window.localStorage.setItem('horizon_decisions', decisionsJson);

      final metricsJson = jsonEncode(_webMetrics.map((m) => m.toMap()..['additionalData'] = jsonEncode(m.additionalData)).toList());
      web.window.localStorage.setItem('horizon_metrics', metricsJson);
    } catch (e) {
      debugPrint("WebStorage Error: $e");
    }
  }

  void _loadFromWebStorage() {
    try {
      final data = web.window.localStorage.getItem('horizon_candidates');
      if (data != null) {
        final List<dynamic> list = jsonDecode(data);
        _webCandidates = list.map((m) => Candidate(
          id: m['id'],
          name: m['name'],
          position: m['position'],
          scores: Map<String, double>.from(m['scores']),
          behavioralFlags: List<String>.from(m['behavioralFlags']),
          createdAt: DateTime.parse(m['createdAt']),
        )).toList();
      }

      final decisionsData = web.window.localStorage.getItem('horizon_decisions');
      if (decisionsData != null) {
        final List<dynamic> list = jsonDecode(decisionsData);
        _webDecisions = list.map((m) => Decision(
          id: m['id'],
          candidateId: m['candidateId'],
          moduleId: m['moduleId'],
          chapterId: m['chapterId'],
          choiceId: m['choiceId'],
          durationMs: m['durationMs'],
          triggers: List<String>.from(jsonDecode(m['triggers'])),
          timestamp: DateTime.parse(m['timestamp']),
        )).toList();
      }

      final metricsData = web.window.localStorage.getItem('horizon_metrics');
      if (metricsData != null) {
        final List<dynamic> list = jsonDecode(metricsData);
        _webMetrics = list.map((m) => ChapterMetric(
          id: m['id'],
          candidateId: m['candidateId'],
          chapterId: m['chapterId'],
          totalTimeMs: m['totalTimeMs'],
          additionalData: jsonDecode(m['additionalData']),
          timestamp: DateTime.parse(m['timestamp']),
        )).toList();
      }
    } catch (e) {
      debugPrint("WebStorage Load Error: $e");
    }
  }
  Future<Database?> get database async {
    if (kIsWeb) return null;
    _db ??= await _initDb();
    return _db;
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
    if (kIsWeb) {
      _webCandidates.removeWhere((c) => c.id == candidate.id);
      _webCandidates.insert(0, candidate);
      _saveToWebStorage();
      return;
    }
    final db = await database;
    await db!.insert(
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
    if (kIsWeb) {
      final index = _webCandidates.indexWhere((c) => c.id == id);
      if (index != -1) {
        final old = _webCandidates[index];
        _webCandidates[index] = Candidate(
          id: old.id,
          name: old.name,
          position: old.position,
          scores: scores,
          behavioralFlags: flags,
          createdAt: old.createdAt,
        );
      }
      _saveToWebStorage();
      return;
    }
    final db = await database;
    await db!.update(
      'candidates',
      {
        'scores': jsonEncode(scores),
        'behavioralFlags': jsonEncode(flags),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteCandidate(String id) async {
    if (kIsWeb) {
      _webCandidates.removeWhere((c) => c.id == id);
      _webDecisions.removeWhere((d) => d.candidateId == id);
      _webMetrics.removeWhere((m) => m.candidateId == id);
      _saveToWebStorage();
      return;
    }
    final db = await database;
    await db!.delete('chapter_metrics', where: 'candidateId = ?', whereArgs: [id]);
    await db.delete('decisions', where: 'candidateId = ?', whereArgs: [id]);
    await db.delete('candidates', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearDatabase() async {
    if (kIsWeb) {
      _webCandidates.clear();
      _webDecisions.clear();
      _webMetrics.clear();
      _saveToWebStorage();
      return;
    }
    final db = await database;
    await db!.delete('chapter_metrics');
    await db.delete('decisions');
    await db.delete('candidates');
  }

  // Decision Operations
  Future<void> insertDecision(Decision decision) async {
    if (kIsWeb) {
      _webDecisions.add(decision);
      _saveToWebStorage();
      return;
    }
    final db = await database;
    await db!.insert(
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
    if (kIsWeb) {
      _webMetrics.add(metric);
      _saveToWebStorage();
      return;
    }
    final db = await database;
    await db!.insert(
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
    if (kIsWeb) return _webDecisions.where((d) => d.candidateId == candidateId).toList();
    final db = await database;
    final maps = await db!.query(
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
    if (kIsWeb) return _webMetrics.where((m) => m.candidateId == candidateId).toList();
    final db = await database;
    final maps = await db!.query(
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
    if (kIsWeb) return _webCandidates;
    final db = await database;
    final maps = await db!.query('candidates', orderBy: 'createdAt DESC');
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

  Future<void> seedMockData() async {
    // 1. İŞBİRLİKÇİ PROFİL (ELARA'S ALLY)
    final mock1 = Candidate(
      id: "DEMO-001",
      name: "Örnek Aday (İşbirlikçi)",
      position: "Senior Project Manager",
      scores: {}, 
      behavioralFlags: [],
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    );
    await insertCandidate(mock1);
    await _seedCandidateData(mock1, isCollaborative: true);

    // 2. OTORİTER / RİSKLİ PROFİL (THE ENFORCER)
    final mock2 = Candidate(
      id: "DEMO-002",
      name: "Aday 002 (Otoriter)",
      position: "Operations lead",
      scores: {},
      behavioralFlags: [],
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    );
    await insertCandidate(mock2);
    await _seedCandidateData(mock2, isCollaborative: false);

    _saveToWebStorage();
  }

  Future<void> _seedCandidateData(Candidate candidate, {required bool isCollaborative}) async {
    final chapters = [
      "Bölüm 1: Bağlantı", "Bölüm 2: Triage", "Bölüm 3: Parazitler", 
      "Bölüm 4: Kritik Seçim", "Bölüm 5: Erişim", "Bölüm 6: Alarm", 
      "Bölüm 7: Çöküş", "Bölüm 8: Sızıntı", "Bölüm 9: Enkaz",
      "Bölüm 10: Seçim", "Bölüm 11: Tartışma", "Bölüm 12: Hata", "Bölüm 13: Final"
    ];

    for (int i = 0; i < chapters.length; i++) {
      final chId = chapters[i];
      List<Map<String, dynamic>> timeline = [];
      String choiceId = "";
      int durationMs = 3000;
      List<String> triggers = [];
      Map<String, dynamic>? additionalData;

      switch (i + 1) {
        case 1: // Bağlantı
          choiceId = isCollaborative ? "start_analysis" : "skip_analysis";
          durationMs = isCollaborative ? (3000 + _random.nextInt(3000)) : (15000 + _random.nextInt(10000));
          timeline = [{"t": 1000, "a": "STARTED"}, {"t": durationMs, "a": "COMPLETED"}];
          additionalData = {
            'errorCount': isCollaborative ? _random.nextInt(2) : (3 + _random.nextInt(5)),
            'timeToFirstClick': isCollaborative ? (800 + _random.nextInt(1000)) : (15000 + _random.nextInt(15000)),
          };
          break;
        case 2: // Triage
          choiceId = isCollaborative ? "quarters" : "reactor";
          durationMs = 25000 + _random.nextInt(10000);
          final switches = isCollaborative ? (4 + _random.nextInt(4)) : (10 + _random.nextInt(10));
          timeline = [
            {"t": 1000, "a": "STARTED"},
            {"t": 5000, "a": "FOCUS_ORDER", "system": "reactor"},
            {"t": 8000, "a": "FOCUS_ORDER", "system": "oxygen"},
            {"t": 12000, "a": "CHOICE_MADE", "choice": choiceId},
            {"t": durationMs, "a": "COMPLETED"}
          ];
          additionalData = {
            'switch_count': switches,
            'focus_order': ["reactor", "oxygen", "comms"],
            'final_levels': {'reactor': 45, 'oxygen': 65, 'comms': 80},
          };
          break;
        case 3: // Parazitler
          choiceId = "continue";
          durationMs = 30000 + _random.nextInt(15000);
          final flips = isCollaborative ? (5 + _random.nextInt(3)) : (12 + _random.nextInt(5));
          final closeAll = !isCollaborative; 
          timeline = [
            {"t": 1000, "a": "STARTED"},
            {"t": 3000, "a": "POPUP_SPAWNED"},
            {"t": 4500, "a": "TILE_FLIPPED", "id": 1},
            {"t": 6000, "a": "TILE_FLIPPED", "id": 5},
            {"t": 7500, "a": "SUCCESS_MATCH"},
            {"t": 9000, "a": "BOX_CLOSED", "bulk": closeAll},
            {"t": 11000, "a": "POPUP_CLOSED", "reactionTime": 1500},
            {"t": durationMs, "a": "COMPLETED"}
          ];
          additionalData = {
            'missedPopups': isCollaborative ? 0 : 1,
            'symbolMatchErrors': isCollaborative ? 1 : 4,
            'tile_flips': flips,
            'box_closing_strategy': closeAll ? 'Toplu Kapatma' : 'Tekil Yönetim',
          };
          break;
        case 4: // Kritik Karar
          choiceId = isCollaborative ? "ethics_over_authority" : "authority_over_ethics";
          durationMs = 15000 + _random.nextInt(10000);
          timeline = [
            {"t": 1000, "a": "STARTED"},
            {"t": 8000, "a": "CHOICE_MADE", "choice": choiceId},
            {"t": durationMs, "a": "COMPLETED"}
          ];
          additionalData = {'choiceConsistency': isCollaborative ? 100 : 60};
          break;
        case 5: // Erişim
          choiceId = "success";
          durationMs = 45000 + _random.nextInt(20000);
          timeline = [
            {"t": 1000, "a": "STARTED"},
            {"t": 15000, "a": "PIN_ERROR", "input": "1234"},
            {"t": 30000, "a": "PIN_SUCCESS"},
            {"t": durationMs, "a": "COMPLETED"}
          ];
          additionalData = {
            'failedAttempts': _random.nextInt(3),
            'readingTime': 15000 + _random.nextInt(10000),
          };
          break;
        case 6: // Kaos
          choiceId = "muted";
          durationMs = 5000 + _random.nextInt(10000);
          timeline = [
            {"t": 1000, "a": "STARTED"},
            {"t": 2000, "a": "POPUP_SPAWNED"},
            if (!isCollaborative) {"t": 3000, "a": "PANIC_CLICK", "count": 1},
            {"t": 4500, "a": "ALARMS_MUTED"},
            {"t": durationMs, "a": "COMPLETED"}
          ];
          additionalData = {
            'panic_clicks': isCollaborative ? 0 : _random.nextInt(5),
            'mutingSpeed': 1200 + _random.nextInt(3000),
          };
          break;
        case 7: // Binary
          choiceId = "success";
          durationMs = 40000 + _random.nextInt(20000);
          timeline = [
            {"t": 1000, "a": "STARTED"},
            {"t": 15000, "a": "ERROR_CLICK"},
            {"t": 35000, "a": "SUCCESS_MATCH"},
            {"t": durationMs, "a": "COMPLETED"}
          ];
          additionalData = {
            'errorCount': isCollaborative ? 0 : 3,
          };
          break;
        case 8: // Sızıntı
          choiceId = isCollaborative ? "help_others_unprotected" : "mask";
          durationMs = 10000 + _random.nextInt(5000);
          timeline = [
            {"t": 1000, "a": "STARTED"},
            {"t": 6000, "a": "CHOICE_MADE", "choice": choiceId},
            {"t": durationMs, "a": "COMPLETED"}
          ];
          additionalData = {
            'reactionTime': 4000 + _random.nextInt(2000),
          };
          break;
        case 9: // Enkaz
          choiceId = isCollaborative ? "internal" : "external";
          durationMs = 15000 + _random.nextInt(5000);
          timeline = [
            {"t": 1000, "a": "STARTED"},
            {"t": 10000, "a": "REFLECTION_CHOICE", "type": choiceId},
            {"t": durationMs, "a": "COMPLETED"}
          ];
          break;
        case 10: // Partner Seçimi
          choiceId = isCollaborative ? "elara" : "kael";
          durationMs = 12000;
          timeline = [
            {"t": 1000, "a": "STARTED"},
            {"t": 8000, "a": "CHARACTER_SELECTED", "name": choiceId},
            {"t": 12000, "a": "COMPLETED"}
          ];
          break;
        case 11: // Tartışma
          choiceId = isCollaborative ? "collaborative" : "authoritarian";
          durationMs = 25000;
          timeline = [
            {"t": 1000, "a": "STARTED"},
            {"t": 12000, "a": "DIALOGUE_CHOICE", "collaborative": isCollaborative},
            {"t": 25000, "a": "COMPLETED"}
          ];
          additionalData = {
            'negotiationSteps': 3,
            'finalAgreement': isCollaborative ? 1 : 0,
          };
          break;
        case 12: // Müdahale
          choiceId = isCollaborative ? "forgive_and_cooperate" : "punish_food_ration";
          durationMs = 15000;
          timeline = [
            {"t": 1000, "a": "STARTED"},
            {"t": 9000, "a": "HANDLED_MISTAKE", "punitive": !isCollaborative},
            {"t": 15000, "a": "COMPLETED"}
          ];
          additionalData = {
            'forgiveDelay': isCollaborative ? 2000 : 8000,
          };
          break;
        case 13: // Final
          choiceId = isCollaborative ? "delegate_trust" : "self_reliance_control";
          durationMs = 20000;
          timeline = [
            {"t": 1000, "a": "STARTED"},
            {"t": 15000, "a": "FINAL_DECISION", "delegate": isCollaborative},
            {"t": 20000, "a": "COMPLETED"}
          ];
          additionalData = {
            'delegationRatio': isCollaborative ? 0.9 : 0.2,
            'readDuration': 12000,
          };
          break;
      }

      await insertChapterMetric(ChapterMetric(
        id: "M_${candidate.id}_$i",
        candidateId: candidate.id,
        chapterId: chId,
        totalTimeMs: durationMs + 2000,
        additionalData: {
          if (timeline.isNotEmpty) 'timeline': timeline,
          if (additionalData != null) ...additionalData!,
        },
        timestamp: DateTime.now().subtract(Duration(minutes: 60 - i)),
      ));

      await insertDecision(Decision(
        id: "D_${candidate.id}_$i",
        candidateId: candidate.id,
        moduleId: "MOD_DEMO",
        chapterId: chId,
        choiceId: choiceId,
        durationMs: durationMs,
        triggers: triggers,
        timestamp: DateTime.now().subtract(Duration(minutes: 60 - i)),
      ));
    }
  }
}
