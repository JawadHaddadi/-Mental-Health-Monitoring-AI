// =============================================================
//  Conversation Engine — Dialogue State Management
//
//  Design philosophy:
//    - Flexible flow, not rigid pipeline
//    - Let the user lead the conversation
//    - Advance stages naturally based on what the user shares
//    - Don't rush to analysis or coping — let exploration happen
//
//  Stages are guidelines, not rails:
//    greeting → moodCheckIn → exploration → analysis →
//    follow_up → reflection → coping → closing
//
//  The engine can skip stages or revisit them based on
//  what the user needs. This is closer to how a real
//  therapist conducts a session.
// =============================================================

import 'diagnostic_service.dart';

/// Conversation stages ordered by progression.
enum ConversationStage {
  greeting,
  moodCheckIn,
  emotionalExploration,
  aiAnalysisTrigger,
  followUpClarification,
  supportiveReflection,
  copingSuggestions,
  conversationClosing,
}

/// Tracks the full context of a single conversation session.
class ConversationContext {
  ConversationStage currentStage;
  int messageCount;
  int userMessageCount;
  DiagnosticResult? lastDiagnosis;
  List<DiagnosticResult> sessionDiagnoses;
  String? dominantEmotion;
  bool crisisDetected;
  bool userExpressedDistress;
  bool copingSuggested;
  DateTime sessionStart;
  String? assessmentType;
  int? assessmentScore;
  String? severityLevel;

  /// Tracks the most recent topics the user has discussed (max 5).
  List<String> recentTopics;

  /// Counts messages that signal improvement or positivity after distress.
  int positiveMessageCount;

  /// Tracks the user's preferred coping style (e.g. breathing, journaling).
  String? userPreferredCopingStyle;

  ConversationContext({
    this.currentStage = ConversationStage.greeting,
    this.messageCount = 0,
    this.userMessageCount = 0,
    this.lastDiagnosis,
    List<DiagnosticResult>? sessionDiagnoses,
    this.dominantEmotion,
    this.crisisDetected = false,
    this.userExpressedDistress = false,
    this.copingSuggested = false,
    DateTime? sessionStart,
    this.assessmentType,
    this.assessmentScore,
    this.severityLevel,
    List<String>? recentTopics,
    this.positiveMessageCount = 0,
    this.userPreferredCopingStyle,
  })  : sessionDiagnoses = sessionDiagnoses ?? [],
        recentTopics = recentTopics ?? [],
        sessionStart = sessionStart ?? DateTime.now();

  /// Whether the conversation was launched from an assessment result.
  bool get isAssessmentContext => assessmentType != null;

  /// Keywords mapped to detectable topics.
  static const Map<String, List<String>> _topicKeywords = {
    'work': ['work', 'job', 'boss', 'coworker', 'office', 'career', 'promotion'],
    'family': ['family', 'parent', 'parents', 'mother', 'father', 'mom', 'dad', 'sibling', 'brother', 'sister', 'son', 'daughter'],
    'relationship': ['relationship', 'partner', 'boyfriend', 'girlfriend', 'husband', 'wife', 'dating', 'breakup', 'divorce', 'ex'],
    'school': ['school', 'college', 'university', 'class', 'exam', 'grade', 'study', 'homework', 'professor', 'teacher', 'student'],
    'health': ['health', 'sick', 'illness', 'doctor', 'hospital', 'medication', 'medicine', 'diagnosis', 'disease', 'chronic'],
    'sleep': ['sleep', 'insomnia', 'nightmare', 'awake', 'tired', 'exhausted', 'rest', 'nap'],
    'friends': ['friend', 'friends', 'friendship', 'buddy', 'mate', 'social', 'loneliness', 'lonely', 'isolated'],
    'money': ['money', 'financial', 'finance', 'debt', 'rent', 'bills', 'salary', 'income', 'broke', 'afford'],
  };

  /// Extracts topics from the user's message using keyword matching.
  /// Keeps only the 5 most recent topics.
  void extractTopics(String userMessage) {
    final lower = userMessage.toLowerCase();
    for (final entry in _topicKeywords.entries) {
      if (entry.value.any((keyword) => RegExp('\\b$keyword\\b').hasMatch(lower))) {
        // Remove if already present so it moves to the end (most recent)
        recentTopics.remove(entry.key);
        recentTopics.add(entry.key);
      }
    }
    // Keep only the last 5 topics
    if (recentTopics.length > 5) {
      recentTopics = recentTopics.sublist(recentTopics.length - 5);
    }

    // Detect preferred coping style from user message
    if (lower.contains('breathing') || lower.contains('breathe') || lower.contains('breath')) {
      userPreferredCopingStyle = 'breathing';
    } else if (lower.contains('journal') || lower.contains('writing') || lower.contains('write')) {
      userPreferredCopingStyle = 'journaling';
    } else if (lower.contains('meditat') || lower.contains('mindful')) {
      userPreferredCopingStyle = 'meditation';
    } else if (lower.contains('exercise') || lower.contains('walk') || lower.contains('running') || lower.contains('workout')) {
      userPreferredCopingStyle = 'exercise';
    } else if (lower.contains('music') || lower.contains('listen')) {
      userPreferredCopingStyle = 'music';
    }
  }

  /// Returns true if the user is showing improvement —
  /// at least 2 positive messages after distress was detected.
  bool isUserImproving() {
    return userExpressedDistress && positiveMessageCount > 1;
  }
}

/// Determines conversation flow and transitions between stages.
class ConversationEngine {
  ConversationContext context;

  ConversationEngine({ConversationContext? initialContext})
      : context = initialContext ?? ConversationContext();

  /// Factory for creating an assessment-triggered conversation.
  factory ConversationEngine.fromAssessment({
    required String assessmentType,
    required int score,
    required String severityLevel,
  }) {
    return ConversationEngine(
      initialContext: ConversationContext(
        currentStage: ConversationStage.emotionalExploration,
        assessmentType: assessmentType,
        assessmentScore: score,
        severityLevel: severityLevel,
      ),
    );
  }

  /// Determines whether the current user message should trigger AI analysis.
  bool shouldRunAnalysis(String userMessage) {
    // Always run analysis after the initial greeting exchange
    if (context.userMessageCount >= 1) return true;
    // Run analysis if message is substantive (>3 words)
    if (userMessage.trim().split(RegExp(r'\s+')).length > 3) return true;
    return false;
  }

  /// Update conversation state after receiving a diagnosis.
  void updateWithDiagnosis(DiagnosticResult result) {
    context.lastDiagnosis = result;
    context.sessionDiagnoses.add(result);

    if (result.isCrisis) {
      context.crisisDetected = true;
      context.currentStage = ConversationStage.supportiveReflection;
      return;
    }

    final emotion = result.dominantEmotion;
    context.dominantEmotion = emotion;

    if (emotion != 'positive' && emotion != 'neutral') {
      context.userExpressedDistress = true;
    }

    // Advance conversation stage based on context
    _advanceStage();
  }

  /// Record that a user message was received.
  void recordUserMessage() {
    context.messageCount++;
    context.userMessageCount++;
  }

  /// Record that a bot message was sent.
  void recordBotMessage() {
    context.messageCount++;
  }

  void _advanceStage() {
    switch (context.currentStage) {
      case ConversationStage.greeting:
        context.currentStage = ConversationStage.moodCheckIn;
        break;

      case ConversationStage.moodCheckIn:
        // Go to exploration — let the user share more before analysis
        context.currentStage = ConversationStage.emotionalExploration;
        break;

      case ConversationStage.emotionalExploration:
        // After 2+ user messages of exploration, move to follow-up
        // This prevents getting stuck in exploration for too long
        if (context.userMessageCount >= 2) {
          context.currentStage = ConversationStage.followUpClarification;
        }
        // Otherwise stay in exploration — don't rush
        break;

      case ConversationStage.aiAnalysisTrigger:
        context.currentStage = ConversationStage.followUpClarification;
        break;

      case ConversationStage.followUpClarification:
        context.currentStage = ConversationStage.supportiveReflection;
        break;

      case ConversationStage.supportiveReflection:
        if (!context.copingSuggested) {
          context.currentStage = ConversationStage.copingSuggestions;
        }
        break;

      case ConversationStage.copingSuggestions:
        context.copingSuggested = true;
        context.currentStage = ConversationStage.conversationClosing;
        break;

      case ConversationStage.conversationClosing:
        // If user continues talking, cycle back
        context.currentStage = ConversationStage.followUpClarification;
        break;
    }
  }

  /// Get the current stage for response selection.
  ConversationStage get stage => context.currentStage;
}
