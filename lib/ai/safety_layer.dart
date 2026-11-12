// =============================================================
//  Safety Layer — Crisis & Risk Detection
//
//  Provides an additional safety net beyond the diagnostic
//  engine's built-in crisis detection. This layer:
//    - Pre-screens every user message for crisis signals
//    - Detects escalation patterns across the conversation
//    - Ensures appropriate responses for high-risk content
//    - Never presents the chatbot as a medical authority
// =============================================================

import 'diagnostic_service.dart';

/// Risk level assessment for a user message.
enum RiskLevel {
  none,
  low,
  moderate,
  high,
  crisis,
}

/// Result of a safety screening.
class SafetyScreenResult {
  final RiskLevel riskLevel;
  final bool isCrisis;
  final bool shouldRecommendProfessional;
  final String? overrideResponse;

  const SafetyScreenResult({
    required this.riskLevel,
    required this.isCrisis,
    required this.shouldRecommendProfessional,
    this.overrideResponse,
  });
}

class SafetyLayer {
  final MentalHealthDiagnosticService _diagnosticService;

  SafetyLayer(this._diagnosticService);

  // Additional self-harm / danger keywords beyond the diagnostic engine
  static final List<RegExp> _additionalCrisisPatterns = [
    RegExp(r'\b(give up|giving up) on (life|everything|living)\b'),
    RegExp(r'\b(no point|no purpose|nothing matters|why bother)\b'),
    RegExp(r'\b(nobody (would |will )?care|no one (would |will )?notice)\b'),
    RegExp(r'\b(plan|planning|planned) to (die|end|kill|hurt)\b'),
    RegExp(r'\b(goodbye|farewell|last message|final message)\b'),
    RegExp(r'\b(pills|razor|rope|gun|bridge|jump|hang)\b'),
    RegExp(r'\b(writing a (note|letter) to|say goodbye to)\b'),
  ];

  // Patterns suggesting escalation from previous messages
  static final List<RegExp> _escalationPatterns = [
    RegExp(r'\b(getting worse|feels? worse|worse than before)\b'),
    RegExp(r'\b(cannot take it|cannot handle|had enough)\b'),
    RegExp(r'\b(breaking point|at my limit|reached my limit)\b'),
    RegExp(r'\b(nothing (is )?help(ing|s)|nothing works)\b'),
  ];

  // Patterns that should never trigger a pathological response
  static final List<RegExp> _safeContextPatterns = [
    RegExp(r'\b(just kidding|joke|joking|lol|haha)\b'),
    RegExp(r'\b(movie|film|song|book|game|show|series)\b'),
    RegExp(r'\b(character|story|fiction|plot)\b'),
  ];

  /// Screen a user message for safety concerns.
  /// This runs BEFORE the full diagnostic engine for fast crisis interception.
  SafetyScreenResult screenMessage(String rawText, {int messageCount = 0}) {
    final text = cleanText(rawText);

    // Check for safe/fictional context first
    final isSafeContext = _safeContextPatterns.any((p) => p.hasMatch(text));
    if (isSafeContext) {
      return const SafetyScreenResult(
        riskLevel: RiskLevel.none,
        isCrisis: false,
        shouldRecommendProfessional: false,
      );
    }

    // Check for crisis using diagnostic service's built-in detector
    if (_diagnosticService.isReady && _diagnosticService.isCrisisText(rawText)) {
      return SafetyScreenResult(
        riskLevel: RiskLevel.crisis,
        isCrisis: true,
        shouldRecommendProfessional: true,
        overrideResponse: _crisisResponseText(),
      );
    }

    // Check additional crisis patterns
    final hasAdditionalCrisis =
        _additionalCrisisPatterns.any((p) => p.hasMatch(text));
    if (hasAdditionalCrisis) {
      return SafetyScreenResult(
        riskLevel: RiskLevel.crisis,
        isCrisis: true,
        shouldRecommendProfessional: true,
        overrideResponse: _crisisResponseText(),
      );
    }

    // Check for escalation patterns
    final hasEscalation = _escalationPatterns.any((p) => p.hasMatch(text));
    if (hasEscalation) {
      return const SafetyScreenResult(
        riskLevel: RiskLevel.high,
        isCrisis: false,
        shouldRecommendProfessional: true,
      );
    }

    // Default: no immediate safety concern
    return const SafetyScreenResult(
      riskLevel: RiskLevel.none,
      isCrisis: false,
      shouldRecommendProfessional: false,
    );
  }

  /// Evaluate cumulative risk across the conversation session.
  RiskLevel evaluateSessionRisk(List<DiagnosticResult> sessionDiagnoses) {
    if (sessionDiagnoses.isEmpty) return RiskLevel.none;

    // Any crisis in the session → crisis level
    if (sessionDiagnoses.any((d) => d.isCrisis)) return RiskLevel.crisis;

    // Count high-distress diagnoses
    int highDistressCount = 0;
    for (final d in sessionDiagnoses) {
      if (d.confidence > 0.75 &&
          (d.dominantEmotion == 'depression' ||
              d.dominantEmotion == 'anxiety')) {
        highDistressCount++;
      }
    }

    if (highDistressCount >= 3) return RiskLevel.high;
    if (highDistressCount >= 2) return RiskLevel.moderate;
    if (highDistressCount >= 1) return RiskLevel.low;

    return RiskLevel.none;
  }

  String _crisisResponseText() {
    return "I hear you, and I want you to know that what you're feeling right now matters. "
        "You don't have to go through this alone.\n\n"
        "Please reach out for immediate support:\n"
        "- KSA Ministry of Health: 920033360\n"
        "- Find a helpline near you: findahelpline.com\n"
        "- Crisis Text Line: Text HOME to 741741\n\n"
        "A trained counselor can provide the support you need right now. "
        "I'm here to listen, but please consider contacting one of these services.";
  }
}
