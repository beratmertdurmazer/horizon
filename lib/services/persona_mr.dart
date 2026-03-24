import 'package:horizon_protocol/models/game_models.dart';
import 'package:horizon_protocol/services/database_service.dart';
import 'package:horizon_protocol/services/assessment_engine.dart';

class PersonaMR {
  static final PersonaMR _instance = PersonaMR._internal();
  factory PersonaMR() => _instance;
  PersonaMR._internal();
  
  final DatabaseService _dbService = DatabaseService();

  Candidate? currentCandidate;
  List<Decision> decisions = [];
  final List<ChapterMetric> _chapterMetrics = [];

  Future<void> initSession(String name, String position) async {
    currentCandidate = Candidate(
      id: "BC_${DateTime.now().millisecondsSinceEpoch}",
      name: name,
      position: position,
      scores: {},
      behavioralFlags: [],
      createdAt: DateTime.now(),
    );
    decisions.clear();
    _chapterMetrics.clear();

    await _dbService.insertCandidate(currentCandidate!);
    print("PersonaMR: Session initialized for ${currentCandidate!.name}");
  }

  Future<void> finalizeCandidateSession() async {
    if (currentCandidate == null) return;
    
    final engine = AssessmentEngine();
    final finalScores = engine.calculateScores();
    final finalFlags = engine.generateFlags();

    await _dbService.updateCandidateScores(currentCandidate!.id, finalScores, finalFlags);
    
    print("PersonaMR: Session finalized for ${currentCandidate!.name}");
  }
 

  String? _chosenPartner;
  void setPartner(String name) => _chosenPartner = name;
  String? getPartner() => _chosenPartner;

  Future<void> logChapterMetrics({
    required String chapterId,
    required int totalTimeMs,
    Map<String, dynamic>? additionalData,
  }) async {
    if (currentCandidate == null) return;

    final metric = ChapterMetric(
      id: "M_${DateTime.now().millisecondsSinceEpoch}_$chapterId",
      candidateId: currentCandidate!.id,
      chapterId: chapterId,
      totalTimeMs: totalTimeMs,
      additionalData: additionalData,
      timestamp: DateTime.now(),
    );

    _chapterMetrics.add(metric);
    await _dbService.insertChapterMetric(metric);
    print("PersonaMR DB Metric: $chapterId -> ${totalTimeMs}ms kaydedildi.");
  }

  Future<void> logDecision({
    required String moduleId,
    required String chapterId,
    required String choiceId,
    required int durationMs,
    List<String> triggers = const [],
  }) async {
    if (currentCandidate == null) return;

    final decision = Decision(
      id: "D_${DateTime.now().millisecondsSinceEpoch}_$chapterId",
      candidateId: currentCandidate!.id,
      moduleId: moduleId,
      chapterId: chapterId,
      choiceId: choiceId,
      durationMs: durationMs,
      triggers: triggers,
      timestamp: DateTime.now(),
    );
    
    decisions.add(decision);
    await _dbService.insertDecision(decision);
    print("PersonaMR DB Decision: ${decision.chapterId} -> ${decision.choiceId} kaydedildi.");
  }
  
  // Getters for Assessment Engine
  List<ChapterMetric> get chapterMetrics => _chapterMetrics;
}
