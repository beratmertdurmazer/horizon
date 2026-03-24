import 'package:horizon_protocol/models/game_models.dart';
import 'package:horizon_protocol/services/persona_mr.dart';

class AssessmentEngine {
  final PersonaMR _persona = PersonaMR();

  Map<String, double> calculateScores() {
    return {
      'cognitive_focus': _calculateCognitiveFocus(),
      'strategic_prioritization': _calculateStrategicPrioritization(),
      'stress_resilience': _calculateStressResilience(),
      'leadership_impact': _calculateLeadershipImpact(),
    };
  }

  List<String> generateFlags() {
    List<String> flags = [];
    final decisions = _persona.decisions;

    // Ch 7: Analytical Solver
    if (decisions.any((d) => d.chapterId == 'chapter7' && d.choiceId == 'success')) {
      flags.add('high_analytical_depth');
    }

    // Ch 5: Risk Averse (PIN entry instead of bypass)
    if (decisions.any((d) => d.chapterId == 'chapter5' && d.choiceId == 'pin_success')) {
      flags.add('risk_averse');
    }

    // Ch 12: Coaching Mindset (Pardon instead of punish)
    if (decisions.any((d) => d.chapterId == 'chapter12' && d.choiceId == 'pardon')) {
      flags.add('coaching_mindset');
    }

    // Ch 13: Micromanagement (Going yourself instead of delegating)
    if (decisions.any((d) => d.chapterId == 'chapter13' && d.choiceId == 'self_entry')) {
      flags.add('micromanagement_tendency');
    }

    return flags;
  }

  double _calculateCognitiveFocus() {
    double score = 70; // Base score
    final metrics = _persona.chapterMetrics;
    
    // Chapter 3: Focus Efficiency
    final ch3Metric = metrics.firstWhere((m) => m.chapterId == 'chapter3', orElse: () => ChapterMetric(id: '', candidateId: '', chapterId: '', totalTimeMs: 0, timestamp: DateTime.now()));
    if (ch3Metric.totalTimeMs > 0) {
      final hits = ch3Metric.additionalData?['hits'] ?? 0;
      final fastHits = ch3Metric.additionalData?['fast_hits'] ?? 0;
      score += (fastHits / (hits > 0 ? hits : 1)) * 20;
    }

    // Chapter 5: Speed
    final ch5Decision = _persona.decisions.firstWhere((d) => d.chapterId == 'chapter5', orElse: () => Decision(id: '', candidateId: '', moduleId: '', chapterId: '', choiceId: '', durationMs: 0, triggers: [], timestamp: DateTime.now()));
    if (ch5Decision.durationMs > 0) {
      if (ch5Decision.durationMs < 40000) score += 10;
      else if (ch5Decision.durationMs > 70000) score -= 10;
    }

    return score.clamp(0, 100);
  }

  double _calculateStrategicPrioritization() {
    double score = 50;
    final decisions = _persona.decisions;

    // Ch 2 & 4 Alignment
    for (var d in decisions) {
      if (d.chapterId == 'chapter2' || d.chapterId == 'chapter4') {
        if (d.choiceId.contains('reactor') || d.choiceId.contains('lab')) score += 15; // System/Corporate oriented
        if (d.choiceId.contains('quarters')) score += 5; // Employee oriented
      }
    }

    return score.clamp(0, 100);
  }

  double _calculateStressResilience() {
    double score = 60;
    final decisions = _persona.decisions;

    // Chapter 6/8: Panic Index (Errors relative to duration)
    final ch6 = decisions.firstWhere((d) => d.chapterId == 'chapter6', orElse: () => Decision(id: '', candidateId: '', moduleId: '', chapterId: '', choiceId: '', durationMs: 0, triggers: [], timestamp: DateTime.now()));
    if (ch6.triggers.contains('panic_clicks')) score -= 15;

    // Chapter 7: Analytical problem solving
    if (decisions.any((d) => d.chapterId == 'chapter7' && d.choiceId == 'success')) {
      score += 20;
    } else if (decisions.any((d) => d.chapterId == 'chapter7' && d.choiceId == 'random_fail')) {
      score -= 10;
    }

    // Chapter 9: Locus of Control
    final ch9 = decisions.firstWhere((d) => d.chapterId == 'chapter9', orElse: () => Decision(id: '', candidateId: '', moduleId: '', chapterId: '', choiceId: '', durationMs: 0, triggers: [], timestamp: DateTime.now()));
    if (ch9.choiceId == 'internal') score += 10; // Self-critical
    if (ch9.choiceId == 'external') score -= 5; // Blaming system

    return score.clamp(0, 100);
  }

  double _calculateLeadershipImpact() {
    double score = 50;
    final decisions = _persona.decisions;

    // Ch 13: Delegation
    if (decisions.any((d) => d.chapterId == 'chapter13' && d.choiceId == 'delegate')) score += 25;
    if (decisions.any((d) => d.chapterId == 'chapter13' && d.choiceId == 'self_entry')) score += 5;

    // Ch 12: Psychological Safety
    if (decisions.any((d) => d.chapterId == 'chapter12' && d.choiceId == 'pardon')) score += 20;
    if (decisions.any((d) => d.chapterId == 'chapter12' && d.choiceId == 'punish')) score -= 10;

    return score.clamp(0, 100);
  }

  String getLeadershipArchetype(double leadershipScore, double strategicScore) {
    if (leadershipScore > 80 && strategicScore > 70) return "Collaborative Leader";
    if (leadershipScore > 80 && strategicScore < 50) return "Servant Leader";
    if (leadershipScore < 50 && strategicScore > 70) return "Authoritarian";
    return "Balanced Manager";
  }
}
