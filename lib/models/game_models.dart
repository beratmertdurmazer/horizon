class Candidate {
  final String id;
  final String name;
  final String email;
  final Map<String, double> scores; // {"cognitive_agility": 85, etc.}
  final List<String> behavioralFlags;
  final DateTime createdAt;

  Candidate({
    required this.id,
    required this.name,
    required this.email,
    required this.scores,
    required this.behavioralFlags,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class Decision {
  final String id;
  final String candidateId;
  final String moduleId;
  final String chapterId;
  final String choiceId;
  final int durationMs;
  final List<String> triggers; // Örneğin ["slow_decision", "risk_averse"]
  final DateTime timestamp;

  Decision({
    required this.id,
    required this.candidateId,
    required this.moduleId,
    required this.chapterId,
    required this.choiceId,
    required this.durationMs,
    required this.triggers,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'candidateId': candidateId,
      'moduleId': moduleId,
      'chapterId': chapterId,
      'choiceId': choiceId,
      'durationMs': durationMs,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
