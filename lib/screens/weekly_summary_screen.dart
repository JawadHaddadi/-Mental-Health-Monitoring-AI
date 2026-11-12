import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../database/db_helper.dart';
import '../models/journal_entry.dart';
import '../models/nlp_result.dart';

class WeeklySummaryScreen extends StatefulWidget {
  const WeeklySummaryScreen({Key? key}) : super(key: key);

  @override
  State<WeeklySummaryScreen> createState() => _WeeklySummaryScreenState();
}

class _WeeklySummaryScreenState extends State<WeeklySummaryScreen> {
  late Future<Map<String, dynamic>> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadAllData();
  }

  Future<Map<String, dynamic>> _loadAllData() async {
    final userID =
        Provider.of<AuthProvider>(context, listen: false).currentUser?.userID;
    if (userID == null) return {};

    final db = DatabaseHelper.instance;

    final results = await Future.wait([
      db.getWeeklySummary(userID),
      db.getWeeklyCheckIns(userID),
      db.getUserJournalEntries(userID),
      db.getUserChatEmotions(userID),
    ]);

    final summary = results[0] as Map<String, dynamic>;
    final weeklyCheckIns = results[1] as List<Map<String, dynamic>>;
    final allJournals = results[2] as List<JournalEntry>;
    final chatEmotions = results[3] as List<NLPResult>;

    // Filter journals to this week only
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final weeklyJournals = allJournals.where((j) {
      final d = DateTime.tryParse(j.date);
      return d != null && d.isAfter(weekAgo);
    }).toList();

    return {
      ...summary,
      'weeklyCheckIns': weeklyCheckIns,
      'weeklyJournals': weeklyJournals,
      'chatEmotions': chatEmotions,
    };
  }

  void _refresh() {
    setState(() {
      _dataFuture = _loadAllData();
    });
  }

  // ── Date helpers ──────────────────────────────────────────

  String _formatDateRange() {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    return '${_shortDate(weekAgo)} - ${_shortDate(now)}';
  }

  String _shortDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}';
  }

  String _weekdayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  // ── Emotion helpers ───────────────────────────────────────

  static const Map<String, Color> _emotionColors = {
    'Joy': Color(0xFF66BB6A),
    'Sadness': Color(0xFF42A5F5),
    'Anxiety': Color(0xFFFFCA28),
    'Anger': Color(0xFFEF5350),
    'Fear': Color(0xFFAB47BC),
    'Surprise': Color(0xFFFF7043),
    'Disgust': Color(0xFF8D6E63),
    'Neutral': Color(0xFF78909C),
  };

  static const Map<String, String> _moodEmojis = {
    'Happy': '\u{1F60A}',
    'Sad': '\u{1F622}',
    'Angry': '\u{1F620}',
    'Anxious': '\u{1F630}',
    'Calm': '\u{1F60C}',
    'Tired': '\u{1F634}',
    'Excited': '\u{1F929}',
    'Neutral': '\u{1F610}',
    'Stressed': '\u{1F625}',
    'Grateful': '\u{1F64F}',
  };

  Color _colorForEmotion(String emotion) {
    return _emotionColors[emotion] ?? const Color(0xFF78909C);
  }

  String _emojiForMood(String mood) {
    return _moodEmojis[mood] ?? '\u{1F610}';
  }

  // ── Insight generation ────────────────────────────────────

  List<_Insight> _generateInsights(Map<String, dynamic> data) {
    final insights = <_Insight>[];
    final journalCount = data['journalCount'] as int? ?? 0;
    final chatCount = data['chatCount'] as int? ?? 0;
    final exerciseCount = data['exerciseCount'] as int? ?? 0;
    final checkInCount = data['checkInCount'] as int? ?? 0;
    final emotions =
        data['emotions'] as List<dynamic>? ?? [];
    final weeklyCheckIns =
        data['weeklyCheckIns'] as List<Map<String, dynamic>>? ?? [];
    final weeklyJournals =
        data['weeklyJournals'] as List<JournalEntry>? ?? [];

    // Dominant mood
    if (emotions.isNotEmpty) {
      final topEmotion = emotions.first['emotion'] as String? ?? 'Neutral';
      insights.add(_Insight(
        icon: Icons.psychology,
        color: _colorForEmotion(topEmotion),
        text: 'Your dominant mood this week was $topEmotion.',
      ));
    }

    // Most active day
    if (weeklyCheckIns.length >= 2) {
      final dayCounts = <int, int>{};
      for (final ci in weeklyCheckIns) {
        final d = DateTime.tryParse(ci['date'] as String? ?? '');
        if (d != null) {
          dayCounts[d.weekday] = (dayCounts[d.weekday] ?? 0) + 1;
        }
      }
      if (dayCounts.isNotEmpty) {
        final bestDay = dayCounts.entries
            .reduce((a, b) => a.value >= b.value ? a : b)
            .key;
        insights.add(_Insight(
          icon: Icons.calendar_today,
          color: const Color(0xFF42A5F5),
          text: 'You were most active on ${_weekdayName(bestDay)}.',
        ));
      }
    }

    // Exercises
    if (exerciseCount > 0) {
      insights.add(_Insight(
        icon: Icons.fitness_center,
        color: const Color(0xFF66BB6A),
        text:
            'You completed $exerciseCount exercise${exerciseCount == 1 ? '' : 's'} '
            '-- keep it up!',
      ));
    } else {
      insights.add(_Insight(
        icon: Icons.fitness_center,
        color: const Color(0xFFFF7043),
        text:
            'No exercises this week. Try a quick breathing or grounding exercise.',
      ));
    }

    // Journaling consistency
    if (journalCount >= 5) {
      insights.add(_Insight(
        icon: Icons.auto_stories,
        color: const Color(0xFF7E57C2),
        text:
            'You\'ve been journaling consistently -- this helps build self-awareness.',
      ));
    } else if (journalCount >= 1) {
      insights.add(_Insight(
        icon: Icons.auto_stories,
        color: const Color(0xFF7E57C2),
        text:
            'You wrote $journalCount journal '
            '${journalCount == 1 ? 'entry' : 'entries'} this week. '
            'Try to write a little each day.',
      ));
    }

    // Chat activity
    if (chatCount > 0) {
      insights.add(_Insight(
        icon: Icons.chat_bubble_outline,
        color: const Color(0xFFFF7043),
        text:
            'You sent $chatCount message${chatCount == 1 ? '' : 's'} '
            'to your AI companion this week.',
      ));
    }

    // Low activity nudge
    final totalActivity =
        journalCount + chatCount + exerciseCount + checkInCount;
    if (totalActivity < 3) {
      insights.add(_Insight(
        icon: Icons.lightbulb_outline,
        color: const Color(0xFFFFCA28),
        text:
            'Try to check in daily -- even a quick mood log helps track your well-being.',
      ));
    }

    // Journal-mood correlation
    if (weeklyJournals.isNotEmpty && weeklyCheckIns.isNotEmpty) {
      // Days with journal entries
      final journalDates = <String>{};
      for (final j in weeklyJournals) {
        final d = DateTime.tryParse(j.date);
        if (d != null) journalDates.add(d.toIso8601String().substring(0, 10));
      }

      // Categorize moods on journal days vs non-journal days
      final positiveMoods = {'Happy', 'Calm', 'Excited', 'Grateful'};
      int positiveOnJournalDays = 0;
      int totalOnJournalDays = 0;
      int positiveOnNonJournalDays = 0;
      int totalOnNonJournalDays = 0;

      for (final ci in weeklyCheckIns) {
        final d = DateTime.tryParse(ci['date'] as String? ?? '');
        final mood = ci['mood'] as String? ?? '';
        if (d == null) continue;
        final dateKey = d.toIso8601String().substring(0, 10);
        final isPositive = positiveMoods.contains(mood);
        if (journalDates.contains(dateKey)) {
          totalOnJournalDays++;
          if (isPositive) positiveOnJournalDays++;
        } else {
          totalOnNonJournalDays++;
          if (isPositive) positiveOnNonJournalDays++;
        }
      }

      if (totalOnJournalDays >= 2 && totalOnNonJournalDays >= 1) {
        final rateJournal = positiveOnJournalDays / totalOnJournalDays;
        final rateNon = positiveOnNonJournalDays / totalOnNonJournalDays;
        if (rateJournal > rateNon) {
          insights.add(_Insight(
            icon: Icons.link,
            color: const Color(0xFF26A69A),
            text:
                'Your mood tends to be more positive on days you journal. '
                'Writing seems to help!',
          ));
        } else {
          insights.add(_Insight(
            icon: Icons.link,
            color: const Color(0xFF26A69A),
            text:
                'You journaled on ${journalDates.length} '
                '${journalDates.length == 1 ? 'day' : 'days'} this week. '
                'Keep going to see mood patterns emerge.',
          ));
        }
      } else if (weeklyJournals.isNotEmpty) {
        insights.add(_Insight(
          icon: Icons.link,
          color: const Color(0xFF26A69A),
          text:
              'You journaled on ${journalDates.length} '
              '${journalDates.length == 1 ? 'day' : 'days'} this week. '
              'More entries will help reveal mood-journaling patterns.',
        ));
      }
    }

    return insights;
  }

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        title: const Text(
          'Weekly Summary',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 22),
            tooltip: 'Refresh',
            onPressed: _refresh,
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _dataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline,
                          size: 48,
                          color: isDark ? Colors.white54 : Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'Could not load your weekly data.\nPlease try again.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDark ? Colors.white54 : Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _refresh,
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final data = snapshot.data ?? {};
            if (data.isEmpty) {
              return const Center(child: Text('Please log in to view your summary.'));
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(isDark),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Activity Summary', isDark),
                  const SizedBox(height: 14),
                  _buildActivityGrid(data, isDark),
                  const SizedBox(height: 28),
                  _buildSectionTitle('Mood Distribution', isDark),
                  const SizedBox(height: 14),
                  _buildMoodDistribution(data, isDark),
                  const SizedBox(height: 28),
                  _buildSectionTitle('Mood Trend (Last 7 Days)', isDark),
                  const SizedBox(height: 14),
                  _buildMoodTrend(data, isDark),
                  const SizedBox(height: 28),
                  _buildSectionTitle('Smart Insights', isDark),
                  const SizedBox(height: 14),
                  _buildInsights(data, isDark),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────

  Widget _buildHeader(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1A237E), const Color(0xFF283593)]
              : [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withOpacity(0.75),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.2),
                ),
                child: const Icon(Icons.bar_chart_rounded,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Weekly Report',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _formatDateRange(),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Section title ─────────────────────────────────────────

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: isDark ? Colors.white : Colors.grey.shade800,
      ),
    );
  }

  // ── Activity grid ─────────────────────────────────────────

  Widget _buildActivityGrid(Map<String, dynamic> data, bool isDark) {
    final items = [
      _ActivityItem(
        icon: Icons.auto_stories,
        label: 'Journal Entries',
        count: data['journalCount'] as int? ?? 0,
        color: const Color(0xFF42A5F5),
      ),
      _ActivityItem(
        icon: Icons.chat_bubble_outline,
        label: 'Chat Sessions',
        count: data['chatCount'] as int? ?? 0,
        color: const Color(0xFFFF7043),
      ),
      _ActivityItem(
        icon: Icons.fitness_center,
        label: 'Exercises',
        count: data['exerciseCount'] as int? ?? 0,
        color: const Color(0xFF66BB6A),
      ),
      _ActivityItem(
        icon: Icons.check_circle_outline,
        label: 'Check-ins',
        count: data['checkInCount'] as int? ?? 0,
        color: const Color(0xFF7E57C2),
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.55,
      children: items.map((item) => _buildActivityCard(item, isDark)).toList(),
    );
  }

  Widget _buildActivityCard(_ActivityItem item, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: item.color.withOpacity(0.12),
            ),
            child: Icon(item.icon, color: item.color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            '${item.count}',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Colors.grey.shade800,
            ),
          ),
          Text(
            item.label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // ── Mood distribution ─────────────────────────────────────

  Widget _buildMoodDistribution(Map<String, dynamic> data, bool isDark) {
    final emotions = data['emotions'] as List<dynamic>? ?? [];

    if (emotions.isEmpty) {
      return _buildEmptyCard(
        'No mood data this week. Chat with your AI companion to get started.',
        isDark,
      );
    }

    // Find max count for bar scaling
    int maxCount = 1;
    for (final e in emotions) {
      final c = (e['count'] as int?) ?? 0;
      if (c > maxCount) maxCount = c;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        children: [
          for (int i = 0; i < emotions.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            _buildEmotionBar(
              emotions[i]['emotion'] as String? ?? 'Unknown',
              (emotions[i]['count'] as int?) ?? 0,
              maxCount,
              isDark,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmotionBar(
      String emotion, int count, int maxCount, bool isDark) {
    final color = _colorForEmotion(emotion);
    final fraction = maxCount > 0 ? count / maxCount : 0.0;

    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(
            emotion,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.grey.shade700,
            ),
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  Container(
                    height: 22,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    height: 22,
                    width: constraints.maxWidth * fraction,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color, color.withOpacity(0.7)],
                      ),
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 28,
          child: Text(
            '$count',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white54 : Colors.grey.shade600,
            ),
          ),
        ),
      ],
    );
  }

  // ── Mood trend ────────────────────────────────────────────

  Widget _buildMoodTrend(Map<String, dynamic> data, bool isDark) {
    final checkIns =
        data['weeklyCheckIns'] as List<Map<String, dynamic>>? ?? [];

    if (checkIns.isEmpty) {
      return _buildEmptyCard(
        'No check-ins this week. Tap the mood tracker to log how you feel.',
        isDark,
      );
    }

    // Build a map of date -> mood for the last 7 days
    final now = DateTime.now();
    final days = List.generate(7, (i) {
      return DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: 6 - i));
    });

    final moodByDate = <String, String>{};
    for (final ci in checkIns) {
      final d = DateTime.tryParse(ci['date'] as String? ?? '');
      if (d != null) {
        moodByDate[d.toIso8601String().substring(0, 10)] =
            ci['mood'] as String? ?? '';
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: days.map((day) {
          final key = day.toIso8601String().substring(0, 10);
          final mood = moodByDate[key];
          final hasData = mood != null && mood.isNotEmpty;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: hasData
                      ? (isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.grey.shade50)
                      : (isDark
                          ? Colors.white.withOpacity(0.04)
                          : Colors.grey.shade100),
                  border: hasData
                      ? Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.4),
                          width: 2,
                        )
                      : null,
                ),
                child: Center(
                  child: Text(
                    hasData ? _emojiForMood(mood) : '--',
                    style: TextStyle(
                      fontSize: hasData ? 20 : 12,
                      color: isDark ? Colors.white38 : Colors.grey.shade400,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _weekdayName(day.weekday),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white54 : Colors.grey.shade500,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ── Smart insights ────────────────────────────────────────

  Widget _buildInsights(Map<String, dynamic> data, bool isDark) {
    final insights = _generateInsights(data);

    if (insights.isEmpty) {
      return _buildEmptyCard(
        'Use the app more this week to unlock personalized insights.',
        isDark,
      );
    }

    return Column(
      children: [
        for (int i = 0; i < insights.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _buildInsightCard(insights[i], isDark),
        ],
      ],
    );
  }

  Widget _buildInsightCard(_Insight insight, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: insight.color.withOpacity(0.12),
            ),
            child: Icon(insight.icon, color: insight.color, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              insight.text,
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: isDark ? Colors.white.withOpacity(0.85) : Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty state ───────────────────────────────────────────

  Widget _buildEmptyCard(String message, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 20,
            color: isDark ? Colors.white38 : Colors.grey.shade400,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white38 : Colors.grey.shade500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Data classes ──────────────────────────────────────────────

class _ActivityItem {
  final IconData icon;
  final String label;
  final int count;
  final Color color;

  const _ActivityItem({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
  });
}

class _Insight {
  final IconData icon;
  final Color color;
  final String text;

  const _Insight({
    required this.icon,
    required this.color,
    required this.text,
  });
}
