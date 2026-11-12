import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/auth_provider.dart';
import '../database/db_helper.dart';
import '../models/nlp_result.dart';
import '../ai/emotional_pattern_analyzer.dart';

enum MoodSource { journal, chat }

class MoodTrackerScreen extends StatefulWidget {
  const MoodTrackerScreen({Key? key}) : super(key: key);

  @override
  State<MoodTrackerScreen> createState() => _MoodTrackerScreenState();
}

class _MoodTrackerScreenState extends State<MoodTrackerScreen> {
  List<NLPResult> _journalEmotions = [];
  List<NLPResult> _chatEmotions = [];
  bool _isLoading = true;
  MoodSource _selectedSource = MoodSource.journal;

  List<NLPResult> get _emotions =>
      _selectedSource == MoodSource.journal ? _journalEmotions : _chatEmotions;

  @override
  void initState() {
    super.initState();
    _loadAllEmotions();
  }

  Future<void> _loadAllEmotions() async {
    try {
      final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
      if (user != null) {
        final journalResults = await DatabaseHelper.instance.getUserEmotions(user.userID!);
        final chatResults = await DatabaseHelper.instance.getUserChatEmotions(user.userID!);
        setState(() {
          _journalEmotions = journalResults;
          _chatEmotions = chatResults;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  int _emotionToVal(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'joy': return 3;
      case 'neutral': return 2;
      case 'anxiety': return 1;
      case 'sadness': return 0;
      default: return 2;
    }
  }

  String _valToEmotion(double val) {
    switch (val.round()) {
      case 3: return 'Joy';
      case 2: return 'Neutral';
      case 1: return 'Anxiety';
      case 0: return 'Sadness';
      default: return '';
    }
  }

  Color _emotionColor(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'joy': return const Color(0xFF4CAF50);
      case 'neutral': return const Color(0xFF42A5F5);
      case 'anxiety': return const Color(0xFFFF9800);
      case 'sadness': return const Color(0xFF78909C);
      default: return const Color(0xFF42A5F5);
    }
  }

  IconData _emotionIcon(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'joy': return Icons.sentiment_very_satisfied;
      case 'neutral': return Icons.sentiment_neutral;
      case 'anxiety': return Icons.sentiment_dissatisfied;
      case 'sadness': return Icons.sentiment_very_dissatisfied;
      default: return Icons.sentiment_neutral;
    }
  }

  // ── Emotion Trend Analysis ─────────────────────────────────
  Map<String, dynamic> _analyzeEmotionTrends(List<NLPResult> emotions) {
    if (emotions.length < 2) return {};

    final counts = <String, int>{};
    for (final e in emotions) {
      counts[e.emotion] = (counts[e.emotion] ?? 0) + 1;
    }

    final sorted = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final dominant = sorted.first;
    final dominantPercent = (dominant.value / emotions.length * 100).round();

    String? streakEmotion;
    int maxStreak = 0;
    int currentStreak = 1;
    for (int i = 1; i < emotions.length; i++) {
      if (emotions[i].emotion == emotions[i - 1].emotion) {
        currentStreak++;
        if (currentStreak > maxStreak) {
          maxStreak = currentStreak;
          streakEmotion = emotions[i].emotion;
        }
      } else {
        currentStreak = 1;
      }
    }

    String? trendDirection;
    if (emotions.length >= 6) {
      final recentAvg = emotions.sublist(emotions.length - 3)
          .map((e) => _emotionToVal(e.emotion))
          .reduce((a, b) => a + b) / 3.0;
      final olderAvg = emotions.sublist(emotions.length - 6, emotions.length - 3)
          .map((e) => _emotionToVal(e.emotion))
          .reduce((a, b) => a + b) / 3.0;
      if (recentAvg > olderAvg + 0.3) {
        trendDirection = 'improving';
      } else if (recentAvg < olderAvg - 0.3) {
        trendDirection = 'declining';
      } else {
        trendDirection = 'stable';
      }
    }

    return {
      'dominant': dominant.key,
      'dominantCount': dominant.value,
      'dominantPercent': dominantPercent,
      'total': emotions.length,
      'streakEmotion': maxStreak >= 3 ? streakEmotion : null,
      'streakLength': maxStreak >= 3 ? maxStreak : 0,
      'trendDirection': trendDirection,
      'counts': counts,
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final trends = _analyzeEmotionTrends(_emotions);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mood Tracker'),
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Source Toggle ──────────────────────
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildToggleButton(
                              label: 'Journal',
                              icon: Icons.auto_stories,
                              isActive: _selectedSource == MoodSource.journal,
                              count: _journalEmotions.length,
                              onTap: () => setState(() => _selectedSource = MoodSource.journal),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: _buildToggleButton(
                              label: 'Chat',
                              icon: Icons.psychology_alt,
                              isActive: _selectedSource == MoodSource.chat,
                              count: _chatEmotions.length,
                              onTap: () => setState(() => _selectedSource = MoodSource.chat),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Chart Section ─────────────────────
                    Text(
                      _selectedSource == MoodSource.journal
                          ? 'Journal Emotional Trend'
                          : 'Chat Emotional Trend',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    if (_emotions.isEmpty)
                      _buildEmptyState(isDark)
                    else
                      SizedBox(
                        height: 250,
                        child: LineChart(
                          LineChartData(
                            gridData: FlGridData(show: false),
                            titlesData: FlTitlesData(
                              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: 1.0,
                                  getTitlesWidget: (value, meta) {
                                    if (value != value.roundToDouble()) {
                                      return const SizedBox.shrink();
                                    }
                                    final label = _valToEmotion(value);
                                    if (label.isEmpty) return const SizedBox.shrink();
                                    return SizedBox(
                                      width: 60,
                                      child: Text(
                                        label,
                                        style: const TextStyle(fontSize: 11),
                                        textAlign: TextAlign.right,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  },
                                  reservedSize: 64,
                                ),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            minX: 0,
                            maxX: (_emotions.length - 1).toDouble().clamp(1, double.infinity),
                            minY: 0,
                            maxY: 3,
                            lineBarsData: [
                              LineChartBarData(
                                spots: _emotions.asMap().entries.map((e) {
                                  return FlSpot(e.key.toDouble(), _emotionToVal(e.value.emotion).toDouble());
                                }).toList(),
                                isCurved: true,
                                color: _selectedSource == MoodSource.journal
                                    ? Theme.of(context).primaryColor
                                    : const Color(0xFFFF7043),
                                barWidth: 3,
                                dotData: FlDotData(show: true),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: (_selectedSource == MoodSource.journal
                                      ? Theme.of(context).primaryColor
                                      : const Color(0xFFFF7043))
                                      .withOpacity(0.15),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // ── Emotion Insights Section ──────────
                    if (trends.isNotEmpty) ...[
                      const SizedBox(height: 28),
                      const Text('Insights', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      _buildInsightCard(trends, isDark),
                    ],

                    // ── Mental Health Indicators Section ──
                    if (_emotions.length >= 3) ...[
                      const SizedBox(height: 28),
                      _buildIndicatorsSection(isDark),
                    ],

                    // ── History Section ───────────────────
                    const SizedBox(height: 28),
                    const Text('History', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    if (_emotions.isEmpty)
                      Text('No mood data available.', style: TextStyle(color: Colors.grey.shade500))
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _emotions.length,
                        itemBuilder: (context, index) {
                          final emo = _emotions.reversed.toList()[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _emotionColor(emo.emotion).withOpacity(0.15),
                                child: Icon(_emotionIcon(emo.emotion), color: _emotionColor(emo.emotion)),
                              ),
                              title: Text(
                                emo.emotion,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                'Confidence: ${(emo.confidence * 100).toStringAsFixed(1)}%',
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Icon(
                                _selectedSource == MoodSource.journal ? Icons.auto_stories : Icons.psychology_alt,
                                size: 16,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildToggleButton({
    required String label,
    required IconData icon,
    required bool isActive,
    required int count,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? (isDark ? Colors.white.withOpacity(0.12) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isActive && !isDark
              ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4, offset: const Offset(0, 1))]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey.shade500,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive
                    ? (isDark ? Colors.white : Colors.grey.shade800)
                    : Colors.grey.shade500,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isActive
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.15)
                      : Colors.grey.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isActive
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey.shade500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    final isChat = _selectedSource == MoodSource.chat;
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.show_chart, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'Not enough data yet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 4),
            Text(
              isChat
                  ? 'Chat with the AI to see emotions detected here'
                  : 'Write journal entries to see your mood chart',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightCard(Map<String, dynamic> trends, bool isDark) {
    final dominant = trends['dominant'] as String;
    final dominantPercent = trends['dominantPercent'] as int;
    final total = trends['total'] as int;
    final streakEmotion = trends['streakEmotion'] as String?;
    final streakLength = trends['streakLength'] as int;
    final trendDirection = trends['trendDirection'] as String?;
    final counts = trends['counts'] as Map<String, int>;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _emotionColor(dominant).withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_emotionIcon(dominant), color: _emotionColor(dominant), size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Most frequent: $dominant',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _emotionColor(dominant)),
                    ),
                    Text(
                      'Appeared $dominantPercent% of the time ($total entries)',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Row(
              children: counts.entries.map((entry) {
                final ratio = entry.value / total;
                return Expanded(
                  flex: (ratio * 100).round().clamp(1, 100),
                  child: Container(height: 6, color: _emotionColor(entry.key)),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: counts.entries.map((entry) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: _emotionColor(entry.key)),
                  ),
                  const SizedBox(width: 4),
                  Text('${entry.key} ${entry.value}', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                ],
              );
            }).toList(),
          ),

          if (streakEmotion != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _emotionColor(streakEmotion).withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.repeat, size: 16, color: _emotionColor(streakEmotion)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pattern detected: $streakEmotion appeared $streakLength times consecutively. '
                      'This may indicate a persistent emotional state worth monitoring.',
                      style: TextStyle(fontSize: 12, color: _emotionColor(streakEmotion)),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (trendDirection != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  trendDirection == 'improving' ? Icons.trending_up
                      : trendDirection == 'declining' ? Icons.trending_down
                      : Icons.trending_flat,
                  size: 18,
                  color: trendDirection == 'improving' ? Colors.green
                      : trendDirection == 'declining' ? Colors.orange
                      : Colors.blue,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    trendDirection == 'improving' ? 'Your mood has been improving recently'
                        : trendDirection == 'declining' ? 'Your mood has been declining — take care of yourself'
                        : 'Your mood has been relatively stable',
                    style: TextStyle(
                      fontSize: 13,
                      color: trendDirection == 'improving' ? Colors.green
                          : trendDirection == 'declining' ? Colors.orange
                          : Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  MENTAL HEALTH INDICATORS
  // ══════════════════════════════════════════════════════════════

  Widget _buildIndicatorsSection(bool isDark) {
    final analysis = EmotionalPatternAnalyzer.analyze(_emotions);
    if (analysis == null) return const SizedBox.shrink();

    final indicators = analysis.sortedIndicators;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Mental Health Indicators',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Tooltip(
              message: 'Based on emotional patterns, not medical diagnosis',
              child: Icon(Icons.info_outline, size: 18, color: Colors.grey.shade400),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Indicator cards
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200,
            ),
          ),
          child: Column(
            children: [
              // Indicator bars
              ...indicators.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _buildIndicatorBar(
                  label: entry.key,
                  value: entry.value,
                  color: _indicatorColor(entry.key),
                  icon: _indicatorIcon(entry.key),
                  isDark: isDark,
                ),
              )),

              // Features summary
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.03) : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildFeatureChip(
                      'Avg Mood',
                      analysis.averageMood.toStringAsFixed(1),
                      analysis.averageMood >= 0 ? Colors.green : Colors.orange,
                    ),
                    _buildFeatureChip(
                      'Variance',
                      analysis.moodVariance.toStringAsFixed(1),
                      analysis.moodVariance > 2 ? Colors.red : Colors.blue,
                    ),
                    _buildFeatureChip(
                      'Neg. Ratio',
                      '${(analysis.negativeRatio * 100).round()}%',
                      analysis.negativeRatio > 0.5 ? Colors.red : Colors.green,
                    ),
                    _buildFeatureChip(
                      'Swings',
                      '${analysis.moodSwings}',
                      analysis.moodSwings > 2 ? Colors.orange : Colors.blue,
                    ),
                  ],
                ),
              ),

              // Disclaimer
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 16, color: Colors.amber.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'These indicators are based on emotional patterns in your conversations and journal entries. '
                        'They are not medical diagnoses. Please consult a mental health professional for proper evaluation.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.amber.shade800,
                          fontStyle: FontStyle.italic,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIndicatorBar({
    required String label,
    required double value,
    required Color color,
    required IconData icon,
    required bool isDark,
  }) {
    final percentage = (value * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$label Indicator',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.grey.shade800,
                ),
              ),
            ),
            Text(
              '$percentage%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value,
            backgroundColor: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade100,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureChip(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
        ),
      ],
    );
  }

  Color _indicatorColor(String indicator) {
    switch (indicator) {
      case 'Stress': return const Color(0xFFFF7043);
      case 'Depression': return const Color(0xFF78909C);
      case 'Bipolar': return const Color(0xFFAB47BC);
      case 'Personality': return const Color(0xFFEC407A);
      case 'Anxiety': return const Color(0xFFFFA726);
      default: return const Color(0xFF42A5F5);
    }
  }

  IconData _indicatorIcon(String indicator) {
    switch (indicator) {
      case 'Stress': return Icons.local_fire_department;
      case 'Depression': return Icons.cloud;
      case 'Bipolar': return Icons.swap_vert;
      case 'Personality': return Icons.psychology;
      case 'Anxiety': return Icons.bolt;
      default: return Icons.monitor_heart;
    }
  }
}
