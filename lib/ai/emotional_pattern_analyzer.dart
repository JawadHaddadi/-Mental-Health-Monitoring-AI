// =============================================================
//  Emotional Pattern Analyzer
//
//  Analyzes sequences of detected emotions to compute
//  mental health indicators based on emotional patterns.
//
//  IMPORTANT: These are pattern-based INDICATORS, NOT diagnoses.
//  The system does NOT provide medical diagnoses.
//
//  Process:
//    1. Map emotions to numerical values
//    2. Extract features (avg, variance, ratios, swings)
//    3. Apply rule-based scoring for 5 indicators
//    4. Return normalized percentages (0-100%)
//
//  Indicator categories (matching ONNX model labels):
//    0 = Stress
//    1 = Depression
//    2 = Bipolar Disorder
//    3 = Personality Disorder
//    4 = Anxiety
// =============================================================

import 'dart:math';
import '../models/nlp_result.dart';

/// Result of the emotional pattern analysis.
class PatternAnalysisResult {
  final double stressIndicator;      // 0.0 – 1.0
  final double depressionIndicator;  // 0.0 – 1.0
  final double bipolarIndicator;     // 0.0 – 1.0
  final double personalityIndicator; // 0.0 – 1.0
  final double anxietyIndicator;     // 0.0 – 1.0

  // Raw features for optional display
  final double averageMood;
  final double moodVariance;
  final double negativeRatio;
  final int moodSwings;
  final int totalEntries;

  const PatternAnalysisResult({
    required this.stressIndicator,
    required this.depressionIndicator,
    required this.bipolarIndicator,
    required this.personalityIndicator,
    required this.anxietyIndicator,
    required this.averageMood,
    required this.moodVariance,
    required this.negativeRatio,
    required this.moodSwings,
    required this.totalEntries,
  });

  /// The highest-scoring indicator label.
  String get dominantIndicator {
    final scores = {
      'Stress': stressIndicator,
      'Depression': depressionIndicator,
      'Bipolar': bipolarIndicator,
      'Personality': personalityIndicator,
      'Anxiety': anxietyIndicator,
    };
    final sorted = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }

  /// Returns all indicators as a sorted list (highest first).
  List<MapEntry<String, double>> get sortedIndicators {
    final scores = {
      'Stress': stressIndicator,
      'Depression': depressionIndicator,
      'Bipolar': bipolarIndicator,
      'Personality': personalityIndicator,
      'Anxiety': anxietyIndicator,
    };
    return scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
  }
}

class EmotionalPatternAnalyzer {
  // ── Step 1: Emotion → Numeric Value ──────────────────────
  // Joy = +2, Neutral = 0, Anxiety = -1, Sadness = -2
  static double _emotionToNumeric(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'joy':
        return 2.0;
      case 'neutral':
        return 0.0;
      case 'anxiety':
        return -1.0;
      case 'sadness':
        return -2.0;
      default:
        return 0.0;
    }
  }

  /// Analyze a list of NLPResult emotions and return indicators.
  /// Requires at least 3 entries to produce meaningful results.
  static PatternAnalysisResult? analyze(List<NLPResult> emotions) {
    if (emotions.length < 3) return null;

    final total = emotions.length;

    // ── Step 1: Convert to numeric values ─────────────────
    final values = emotions.map((e) => _emotionToNumeric(e.emotion)).toList();

    // ── Step 2: Extract features ──────────────────────────

    // 2a. Average Mood
    final avgMood = values.reduce((a, b) => a + b) / total;

    // 2b. Mood Variance
    final meanSquaredDiff = values
        .map((v) => (v - avgMood) * (v - avgMood))
        .reduce((a, b) => a + b) / total;
    final variance = meanSquaredDiff; // population variance

    // 2c. Emotion Ratios
    final counts = <String, int>{};
    for (final e in emotions) {
      final key = e.emotion.toLowerCase();
      counts[key] = (counts[key] ?? 0) + 1;
    }

    final joyRatio = (counts['joy'] ?? 0) / total;
    final neutralRatio = (counts['neutral'] ?? 0) / total;
    final anxietyRatio = (counts['anxiety'] ?? 0) / total;
    final sadnessRatio = (counts['sadness'] ?? 0) / total;
    final negativeRatio = anxietyRatio + sadnessRatio;

    // 2d. Mood Swings (count of direction changes > 1 unit)
    int swings = 0;
    for (int i = 1; i < values.length; i++) {
      final diff = (values[i] - values[i - 1]).abs();
      if (diff >= 2.0) {
        swings++;
      }
    }

    // 2e. Check for extreme range (max - min)
    final maxMood = values.reduce(max);
    final minMood = values.reduce(min);
    final moodRange = maxMood - minMood;

    // ── Step 3: Compute indicator scores ──────────────────
    // Each indicator gets a score 0.0 – 1.0 based on rules.
    // Multiple signals contribute additively, then clamped.

    // --- STRESS (0) ---
    // High anxiety + many neutrals + low variance
    double stressScore = 0.0;
    if (anxietyRatio > 0.4 && variance < 1.5) stressScore += 0.35;
    if (anxietyRatio > 0.3 && neutralRatio > 0.2) stressScore += 0.25;
    if (avgMood < 0 && avgMood > -1.5) stressScore += 0.20;
    if (negativeRatio > 0.5 && variance < 2.0) stressScore += 0.20;
    stressScore = stressScore.clamp(0.0, 1.0);

    // --- DEPRESSION (1) ---
    // High sadness + very low joy + low average mood
    double depressionScore = 0.0;
    if (sadnessRatio > 0.5 && avgMood < -1.0) depressionScore += 0.40;
    if (sadnessRatio > 0.3 && joyRatio < 0.1) depressionScore += 0.30;
    if (avgMood < -1.5) depressionScore += 0.20;
    if (sadnessRatio > 0.4 && neutralRatio < 0.2) depressionScore += 0.15;
    // Low variance with low mood = persistent sadness
    if (variance < 1.0 && avgMood < -1.0) depressionScore += 0.15;
    depressionScore = depressionScore.clamp(0.0, 1.0);

    // --- BIPOLAR (2) ---
    // Very large emotional fluctuations between extremes
    double bipolarScore = 0.0;
    if (variance > 2.0 && moodRange >= 3.0) bipolarScore += 0.40;
    if (swings >= 2 && moodRange >= 3.0) bipolarScore += 0.30;
    if (joyRatio > 0.15 && sadnessRatio > 0.15 && variance > 1.5) {
      bipolarScore += 0.25;
    }
    // Rapid cycling: high swing count relative to entries
    final swingRatio = total > 3 ? swings / (total - 1) : 0.0;
    if (swingRatio > 0.3 && moodRange >= 3.0) bipolarScore += 0.20;
    bipolarScore = bipolarScore.clamp(0.0, 1.0);

    // --- PERSONALITY DISORDER (3) ---
    // Frequent emotional swings + high reactivity + anxiety
    double personalityScore = 0.0;
    if (swings >= 2 && anxietyRatio > 0.25) personalityScore += 0.35;
    if (swingRatio > 0.25 && negativeRatio > 0.5) personalityScore += 0.25;
    if (variance > 1.5 && anxietyRatio > 0.3) personalityScore += 0.20;
    // Emotional instability without extreme highs (distinguishes from bipolar)
    if (swings >= 2 && joyRatio < 0.2 && variance > 1.0) {
      personalityScore += 0.20;
    }
    personalityScore = personalityScore.clamp(0.0, 1.0);

    // --- ANXIETY (4) ---
    // High anxiety + moderate sadness + low joy
    double anxietyScore = 0.0;
    if (anxietyRatio > 0.5) anxietyScore += 0.40;
    if (anxietyRatio > 0.3 && sadnessRatio < 0.4) anxietyScore += 0.25;
    if (anxietyRatio > 0.4 && joyRatio < 0.15) anxietyScore += 0.20;
    if (avgMood < -0.5 && anxietyRatio > 0.3) anxietyScore += 0.15;
    anxietyScore = anxietyScore.clamp(0.0, 1.0);

    return PatternAnalysisResult(
      stressIndicator: stressScore,
      depressionIndicator: depressionScore,
      bipolarIndicator: bipolarScore,
      personalityIndicator: personalityScore,
      anxietyIndicator: anxietyScore,
      averageMood: avgMood,
      moodVariance: variance,
      negativeRatio: negativeRatio,
      moodSwings: swings,
      totalEntries: total,
    );
  }
}
