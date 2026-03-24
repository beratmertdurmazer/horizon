import 'package:horizon_protocol/models/game_models.dart';

class PersonaMR {
  static final PersonaMR _instance = PersonaMR._internal();
  factory PersonaMR() => _instance;
  PersonaMR._internal();

  Candidate? currentCandidate;
  List<Decision> decisions = [];

  void initSession(String name, String email) {
    currentCandidate = Candidate(
      id: "BC_${DateTime.now().millisecondsSinceEpoch}",
      name: name,
      email: email,
      scores: {},
      behavioralFlags: [],
      createdAt: DateTime.now(),
    );
    decisions.clear();
  }

  String? _chosenPartner;
  void setPartner(String name) => _chosenPartner = name;
  String? getPartner() => _chosenPartner;

  void logDecision({
    required String moduleId,
    required String chapterId,
    required String choiceId,
    required int durationMs,
    List<String> triggers = const [],
  }) {
    if (currentCandidate == null) return;

    final decision = Decision(
      id: "D_${DateTime.now().millisecondsSinceEpoch}",
      candidateId: currentCandidate!.id,
      moduleId: moduleId,
      chapterId: chapterId,
      choiceId: choiceId,
      durationMs: durationMs,
      triggers: triggers,
      timestamp: DateTime.now(),
    );
    decisions.add(decision);
    
    // Geçici olarak konsola yazalım (debug)
    print("PERSONA_MR LOG: ${decision.chapterId} -> ${decision.choiceId} (${durationMs}ms)");
  }

  // Puan hesaplama ve Flag mapping ileride buraya eklenecek
}
