// =============================================================
//  Chat Service — Orchestrates the Full AI Pipeline
//
//  Design philosophy (inspired by Wysa, Woebot, Replika):
//    - Be warm and natural, like a supportive friend
//    - Don't force clinical labels into conversation
//    - Handle off-topic messages gracefully
//    - Match the user's emotional energy
//    - Use AI diagnosis to GUIDE response selection silently
//      (the user never sees "Anxiety detected" — they just get
//       an empathetic, contextually appropriate response)
//
//  Pipeline:
//    User message
//    → Off-topic filter (is this about feelings/wellness?)
//    → Safety Layer pre-screen (crisis detection)
//    → ONNX model inference (emotion classification)
//    → Conversation context update (memory across messages)
//    → Response selection (stage + emotion + context)
//    → Response displayed in Flutter chat UI
//
//  The ONNX model's role:
//    - Classifies text into 5 categories (Stress, Depression,
//      Bipolar, Anxiety, Personality Disorder)
//    - Output drives: response tone, coping suggestions type,
//      mood tracker data, session risk assessment
//    - Runs silently — user sees warm responses, not labels
//
//  All processing runs locally on the device.
// =============================================================

import 'package:flutter/foundation.dart';
import '../ai/diagnostic_service.dart';
import '../ai/conversation_engine.dart';
import '../ai/response_library.dart';
import '../ai/safety_layer.dart';

/// Represents a single chat message.
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final DiagnosticResult? diagnosis;

  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
    this.diagnosis,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// The main chat service that wires together all AI components.
class ChatService {
  final MentalHealthDiagnosticService _diagnosticService;
  late final SafetyLayer _safetyLayer;
  late ConversationEngine _conversationEngine;

  bool _isInitialized = false;
  bool _isProcessing = false;

  bool get isInitialized => _isInitialized;
  bool get isProcessing => _isProcessing;
  ConversationContext get context => _conversationEngine.context;

  ChatService({
    MentalHealthDiagnosticService? diagnosticService,
  }) : _diagnosticService = diagnosticService ?? MentalHealthDiagnosticService() {
    _safetyLayer = SafetyLayer(_diagnosticService);
    _conversationEngine = ConversationEngine();
  }

  /// Create a chat service pre-loaded with assessment context.
  factory ChatService.fromAssessment({
    required String assessmentType,
    required int score,
    required String severityLevel,
    MentalHealthDiagnosticService? diagnosticService,
  }) {
    final service = ChatService(diagnosticService: diagnosticService);
    service._conversationEngine = ConversationEngine.fromAssessment(
      assessmentType: assessmentType,
      score: score,
      severityLevel: severityLevel,
    );
    return service;
  }

  /// Initialize the ONNX model and tokenizer. Call once at startup.
  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      await _diagnosticService.initialize();
      _isInitialized = true;
    } catch (e) {
      debugPrint('ChatService initialization error: $e');
      _isInitialized = true; // Still work with fallback responses
    }
  }

  /// Get the initial greeting message.
  ChatMessage getGreeting() {
    String greeting;
    if (_conversationEngine.context.isAssessmentContext) {
      greeting = ResponseLibrary.greetingFromAssessment(
        _conversationEngine.context.assessmentType!,
        _conversationEngine.context.assessmentScore!,
        _conversationEngine.context.severityLevel!,
      );
    } else {
      greeting = ResponseLibrary.greeting();
    }
    _conversationEngine.recordBotMessage();
    return ChatMessage(text: greeting, isUser: false);
  }

  // ─────────────────────────────────────────────
  // OFF-TOPIC DETECTION
  // ─────────────────────────────────────────────
  // Detects messages that have nothing to do with feelings,
  // mental health, or personal experiences.
  // These should get a gentle redirect, NOT therapy responses.
  // ─────────────────────────────────────────────
  static final List<RegExp> _mentalHealthSignals = [
    // Feelings & emotions
    RegExp(r'\b(feel|feeling|felt|sad|happy|angry|anxious|worried|scared|afraid|nervous|depressed|stressed|overwhelmed|lonely|empty|hopeless|tired|exhausted|hurt|pain|suffering|numb|frustrated|confused|lost|broken|crying|cry|panic|terrified|grief|grieving|mourning)\b', caseSensitive: false),
    // Mental health topics
    RegExp(r'\b(anxiety|depression|stress|therapy|therapist|counselor|mental health|sleep|insomnia|nightmare|trauma|abuse|relationship|family|friend|breakup|divorce|death|loss|work|job|school|exam|pressure|burden|self.harm|suicide|medication|mood|energy|motivation|appetite)\b', caseSensitive: false),
    // Personal experience language
    RegExp(r'\b(i am|i feel|i have been|i cannot|i do not|i think|i need|i want|my life|my mind|my heart|it hurts|no one|nobody|everyone|everything|nothing)\b', caseSensitive: false),
    // Help seeking
    RegExp(r'\b(help|advice|suggest|recommend|cope|deal with|handle|manage|how (can|do|should) i|what (should|can) i)\b', caseSensitive: false),
    // Greetings & simple responses (these are fine, not off-topic)
    RegExp(r'^(hi|hello|hey|good morning|good evening|good night|thanks|thank you|yes|no|ok|okay|fine|good|great|bye|goodbye)\b', caseSensitive: false),
  ];

  bool _isOffTopic(String text) {
    final cleaned = text.toLowerCase().trim();

    // Very short messages (1-3 words) are never off-topic — they're just brief
    if (cleaned.split(RegExp(r'\s+')).length <= 3) return false;

    // Check if any mental health signal is present
    return !_mentalHealthSignals.any((p) => p.hasMatch(cleaned));
  }

  // ─────────────────────────────────────────────
  // HELP-SEEKING DETECTION
  // ─────────────────────────────────────────────
  static final List<RegExp> _helpSeekingPatterns = [
    RegExp(r'\b(what (should|can|do) i do)\b', caseSensitive: false),
    RegExp(r'\b(how (can|do|should) i)\b', caseSensitive: false),
    RegExp(r'\b(any (advice|suggestions?|tips?|help))\b', caseSensitive: false),
    RegExp(r'\b(help me|i need help|need advice)\b', caseSensitive: false),
    RegExp(r'\b(what (to|can i) do (about|for|to))\b', caseSensitive: false),
    RegExp(r'\b(how to (cope|deal|handle|manage|feel better|ease|calm|relax))\b', caseSensitive: false),
    RegExp(r'\b(suggest|recommend|give me tips)\b', caseSensitive: false),
    RegExp(r'\b(take care of my (mental|emotional) health)\b', caseSensitive: false),
    RegExp(r'\b(ease my mind|calm (down|myself))\b', caseSensitive: false),
  ];

  bool _isHelpSeekingMessage(String text) {
    final cleaned = text.toLowerCase().trim();
    return _helpSeekingPatterns.any((p) => p.hasMatch(cleaned));
  }

  // ─────────────────────────────────────────────
  // INFORMATIONAL QUESTION DETECTION
  // ─────────────────────────────────────────────
  static final List<RegExp> _informationalPatterns = [
    RegExp(r'\b(what (is|are|does)|define|meaning of)\b.*\??\s*$', caseSensitive: false),
    RegExp(r'\b(mental health (includes?|means?|is))\b', caseSensitive: false),
    RegExp(r'\b(what (includes?|involves?|consists?))\b', caseSensitive: false),
    RegExp(r'\b(tell me about|explain|describe)\b', caseSensitive: false),
  ];

  bool _isInformationalQuestion(String text) {
    final cleaned = text.toLowerCase().trim();
    return _informationalPatterns.any((p) => p.hasMatch(cleaned));
  }

  // ─────────────────────────────────────────────
  // MAIN MESSAGE PROCESSING PIPELINE
  // ─────────────────────────────────────────────
  Future<ChatMessage> processMessage(String userText) async {
    _isProcessing = true;
    _conversationEngine.recordUserMessage();

    try {
      // ── STEP 0: Off-topic filter ──────────────────────────
      // If the message has nothing to do with mental health or
      // feelings, gently redirect instead of treating it as therapy.
      if (_isOffTopic(userText)) {
        _conversationEngine.recordBotMessage();
        _isProcessing = false;
        return ChatMessage(
          text: ResponseLibrary.offTopicResponse(),
          isUser: false,
        );
      }

      // ── STEP 1: Safety pre-screen (fast crisis check) ─────
      final safetyResult = _safetyLayer.screenMessage(
        userText,
        messageCount: _conversationEngine.context.userMessageCount,
      );

      if (safetyResult.isCrisis) {
        _conversationEngine.context.crisisDetected = true;
        _conversationEngine.recordBotMessage();
        _isProcessing = false;
        return ChatMessage(
          text: safetyResult.overrideResponse ??
              ResponseLibrary.crisisResponse(),
          isUser: false,
        );
      }

      // ── STEP 2: Detect intent ─────────────────────────────
      final isHelpSeeking = _isHelpSeekingMessage(userText);
      final isInformational = _isInformationalQuestion(userText);

      // ── STEP 3: Run AI analysis ───────────────────────────
      DiagnosticResult? diagnosis;
      String emotion = _conversationEngine.context.dominantEmotion ?? 'neutral';
      final conversationEmotion = _conversationEngine.context.dominantEmotion;
      final hadDistress = _conversationEngine.context.userExpressedDistress;

      if (_diagnosticService.isReady &&
          _conversationEngine.shouldRunAnalysis(userText)) {
        diagnosis = await _diagnosticService.diagnose(userText);

        if (diagnosis.label == 'Invalid Input') {
          // Use conversation context for a natural response
          if (hadDistress && conversationEmotion != null) {
            emotion = conversationEmotion;
          }
          _conversationEngine.context.currentStage =
              _nextStageForSimpleInput(_conversationEngine.stage);
          // Don't return early — let the normal flow handle it
        } else if (diagnosis.label == 'Contextual') {
          // Short contextual words (ok, yes, no) — use conversation memory
          emotion = (hadDistress && conversationEmotion != null)
              ? conversationEmotion
              : 'neutral';
          _conversationEngine.context.currentStage =
              _nextStageForSimpleInput(_conversationEngine.stage);
        } else {
          // Real diagnosis — update conversation state
          _conversationEngine.updateWithDiagnosis(diagnosis);
          emotion = diagnosis.dominantEmotion;

          // Track positive messages for improvement detection
          if (emotion == 'positive' || emotion == 'neutral') {
            _conversationEngine.context.positiveMessageCount++;
          }

          // ── CONVERSATION MEMORY ──────────────────────────
          // If conversation has established distress but current
          // message is classified as positive/neutral with low
          // confidence, keep the distress context.
          // This prevents: user in grief conversation says
          // "my cats were part of my family" → classified positive
          // → bot responds happily. Instead, we maintain empathy.
          if ((emotion == 'positive' || emotion == 'neutral') &&
              hadDistress &&
              conversationEmotion != null &&
              conversationEmotion != 'positive' &&
              conversationEmotion != 'neutral') {
            if (diagnosis.confidence < 0.90) {
              emotion = conversationEmotion;
              _conversationEngine.context.dominantEmotion = conversationEmotion;
            }
          }
        }

        // Check if model flagged crisis (safety layer might have missed)
        if (diagnosis != null && diagnosis.isCrisis) {
          _conversationEngine.context.crisisDetected = true;
          _conversationEngine.recordBotMessage();
          _isProcessing = false;
          return ChatMessage(
            text: ResponseLibrary.crisisResponse(),
            isUser: false,
            diagnosis: diagnosis,
          );
        }
      } else {
        // Not running analysis — just advance the conversation
        _conversationEngine.context.currentStage =
            _nextStageForSimpleInput(_conversationEngine.stage);
      }

      // Always extract topics from user message (even when analysis didn't run)
      // This ensures topic-aware responses work regardless of analysis state
      _conversationEngine.context.extractTopics(userText);

      // ── STEP 4: Handle special intents ────────────────────

      // Help-seeking → jump to coping suggestions
      if (isHelpSeeking) {
        _conversationEngine.context.currentStage =
            ConversationStage.copingSuggestions;
      }

      // Informational question → provide info directly
      if (isInformational) {
        _conversationEngine.recordBotMessage();
        _isProcessing = false;
        return ChatMessage(
          text: ResponseLibrary.informationalResponse(),
          isUser: false,
          diagnosis: diagnosis,
        );
      }

      // ── STEP 5: Handle positive messages naturally ────────
      // If user says something genuinely positive and there's
      // NO distress history, respond positively — don't ask
      // about anxiety or depression!
      if (emotion == 'positive' && !hadDistress) {
        final stage = _conversationEngine.stage;
        if (stage != ConversationStage.greeting) {
          _conversationEngine.recordBotMessage();
          _isProcessing = false;
          return ChatMessage(
            text: ResponseLibrary.positiveContinuation(),
            isUser: false,
            diagnosis: diagnosis,
          );
        }
      }

      // ── STEP 6: Session risk check ────────────────────────
      final sessionRisk = _safetyLayer.evaluateSessionRisk(
        _conversationEngine.context.sessionDiagnoses,
      );
      final shouldNudgeProfessional =
          safetyResult.shouldRecommendProfessional ||
              sessionRisk == RiskLevel.high ||
              sessionRisk == RiskLevel.moderate;

      // ── STEP 7: Select response from library ──────────────

      // Use contextual follow-up when we have detected topics
      final currentStage = _conversationEngine.stage;
      final recentTopics = _conversationEngine.context.recentTopics;
      final preferredStyle = _conversationEngine.context.userPreferredCopingStyle;

      String response;

      // Topic-aware responses: use contextual follow-up whenever we have
      // topics and we're in a stage that benefits from topic specificity
      // (not just followUpClarification — also emotionalExploration, moodCheckIn)
      if (recentTopics.isNotEmpty &&
          (currentStage == ConversationStage.followUpClarification ||
           currentStage == ConversationStage.emotionalExploration ||
           currentStage == ConversationStage.aiAnalysisTrigger)) {
        // Use topic-aware follow-up for the most recent topic
        response = ResponseLibrary.contextualFollowUp(
          recentTopics.last,
          emotion,
        );
      } else if (currentStage == ConversationStage.copingSuggestions &&
          preferredStyle != null) {
        // Use personalized coping when user has a preferred style
        response = ResponseLibrary.personalizedCoping(emotion, preferredStyle);
      } else {
        response = ResponseLibrary.selectResponse(
          stage: currentStage,
          emotion: emotion,
          isChronic: diagnosis?.isChronic ?? false,
          isCrisis: false,
          crisisWasDetected: _conversationEngine.context.crisisDetected,
          hadDistress: _conversationEngine.context.userExpressedDistress,
          userMessage: userText,
        );
      }

      // Append professional help nudge (sparingly — every 4th message)
      if (shouldNudgeProfessional &&
          _conversationEngine.context.userMessageCount % 4 == 0 &&
          !_conversationEngine.context.crisisDetected) {
        response += '\n\n${ResponseLibrary.professionalHelpNudge()}';
      }

      _conversationEngine.recordBotMessage();
      _isProcessing = false;

      return ChatMessage(
        text: response,
        isUser: false,
        diagnosis: diagnosis,
      );
    } catch (e) {
      debugPrint('ChatService processMessage error: $e');
      _isProcessing = false;
      _conversationEngine.recordBotMessage();
      return ChatMessage(
        text: "I'm here to listen. Could you tell me more about how you're feeling?",
        isUser: false,
      );
    }
  }

  /// Simple stage progression for messages that don't trigger analysis.
  /// Ensures the conversation never gets permanently stuck at any stage.
  ConversationStage _nextStageForSimpleInput(ConversationStage current) {
    switch (current) {
      case ConversationStage.greeting:
        return ConversationStage.moodCheckIn;
      case ConversationStage.moodCheckIn:
        return ConversationStage.emotionalExploration;
      case ConversationStage.emotionalExploration:
        return ConversationStage.followUpClarification;
      case ConversationStage.aiAnalysisTrigger:
        return ConversationStage.followUpClarification;
      case ConversationStage.followUpClarification:
        return ConversationStage.supportiveReflection;
      case ConversationStage.supportiveReflection:
        return ConversationStage.copingSuggestions;
      case ConversationStage.copingSuggestions:
        return ConversationStage.conversationClosing;
      case ConversationStage.conversationClosing:
        return ConversationStage.followUpClarification;
    }
  }

  /// Dispose the diagnostic service when done.
  void dispose() {
    if (_diagnosticService.isReady) {
      _diagnosticService.dispose();
    }
  }
}
