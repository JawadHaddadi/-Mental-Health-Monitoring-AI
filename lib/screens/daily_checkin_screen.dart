import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../database/db_helper.dart';

class DailyCheckInScreen extends StatefulWidget {
  const DailyCheckInScreen({Key? key}) : super(key: key);

  @override
  State<DailyCheckInScreen> createState() => _DailyCheckInScreenState();
}

class _DailyCheckInScreenState extends State<DailyCheckInScreen>
    with TickerProviderStateMixin {
  // ── Mood options ──────────────────────────────────────────────
  static const List<Map<String, String>> _moods = [
    {'emoji': '\u{1F60A}', 'label': 'Great'},
    {'emoji': '\u{1F642}', 'label': 'Good'},
    {'emoji': '\u{1F610}', 'label': 'Okay'},
    {'emoji': '\u{1F614}', 'label': 'Sad'},
    {'emoji': '\u{1F630}', 'label': 'Anxious'},
    {'emoji': '\u{1F624}', 'label': 'Stressed'},
  ];

  // ── Motivational quotes ──────────────────────────────────────
  static const List<String> _quotes = [
    'Every day is a fresh start. Take a deep breath and begin again.',
    'You are stronger than you think and braver than you believe.',
    'Small steps every day lead to big changes over time.',
    'It is okay to not be okay. What matters is that you show up.',
    'Your mental health is a priority. Your happiness is essential.',
    'Progress, not perfection, is what we should be asking of ourselves.',
    'Be gentle with yourself. You are doing the best you can.',
    'Healing is not linear, but every step counts.',
    'You deserve the same compassion you give to others.',
    'Take it one moment at a time. You have got this.',
    'The sun will rise, and we will try again.',
    'Courage does not always roar. Sometimes it is the quiet voice at the end of the day saying: I will try again tomorrow.',
    'Feelings are visitors. Let them come and go.',
    'Rest if you must, but do not quit.',
    'You are not your thoughts. You are the observer of your thoughts.',
  ];

  // ── State ────────────────────────────────────────────────────
  String? _todayMood;
  Map<String, dynamic> _streakData = {'currentStreak': 0, 'longestStreak': 0};
  List<Map<String, dynamic>> _weeklyCheckIns = [];
  int _exerciseCount = 0;
  bool _isLoading = true;
  bool _justCheckedIn = false;
  String _dailyQuote = '';

  late AnimationController _checkInAnimController;
  late Animation<double> _checkInScaleAnim;
  late AnimationController _streakAnimController;
  late Animation<double> _streakCountAnim;

  int? get _userID =>
      Provider.of<AuthProvider>(context, listen: false).currentUser?.userID;

  @override
  void initState() {
    super.initState();

    // Pick a random quote seeded by today's date for consistency within the day
    final today = DateTime.now();
    final seed = today.year * 10000 + today.month * 100 + today.day;
    _dailyQuote = _quotes[seed % _quotes.length];

    _checkInAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _checkInScaleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _checkInAnimController, curve: Curves.elasticOut),
    );

    _streakAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _streakCountAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _streakAnimController, curve: Curves.easeOutCubic),
    );

    _loadData();
  }

  @override
  void dispose() {
    _checkInAnimController.dispose();
    _streakAnimController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final uid = _userID;
    if (uid == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final todayMood = await DatabaseHelper.instance.getTodayCheckIn(uid);
      final streak = await DatabaseHelper.instance.getUserStreak(uid);
      final weekly = await DatabaseHelper.instance.getWeeklyCheckIns(uid);
      final exercises = await DatabaseHelper.instance.getExerciseCount(uid);

      if (!mounted) return;
      setState(() {
        _todayMood = todayMood;
        _streakData = streak;
        _weeklyCheckIns = weekly;
        _exerciseCount = exercises;
        _isLoading = false;
      });
      _streakAnimController.forward();
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onMoodSelected(String mood) async {
    final uid = _userID;
    if (uid == null) return;

    await DatabaseHelper.instance.createDailyCheckIn(uid, mood);
    await DatabaseHelper.instance.updateStreak(uid);

    final streak = await DatabaseHelper.instance.getUserStreak(uid);
    final weekly = await DatabaseHelper.instance.getWeeklyCheckIns(uid);

    if (!mounted) return;
    setState(() {
      _todayMood = mood;
      _streakData = streak;
      _weeklyCheckIns = weekly;
      _justCheckedIn = true;
    });

    _checkInAnimController.forward(from: 0.0);
    _streakAnimController.forward(from: 0.0);
  }

  // ── Helpers ──────────────────────────────────────────────────
  String _emojiForMood(String mood) {
    for (final m in _moods) {
      if (m['label'] == mood) return m['emoji']!;
    }
    return '\u{1F642}';
  }

  String _streakMessage(int streak) {
    if (streak >= 30) return 'Incredible dedication!';
    if (streak >= 14) return 'Two weeks strong!';
    if (streak >= 7) return 'Amazing week!';
    if (streak >= 3) return 'Keep going!';
    if (streak >= 1) return 'Great start!';
    return 'Start your streak today!';
  }

  Color _moodColor(String mood) {
    switch (mood) {
      case 'Great':
        return const Color(0xFF4CAF50);
      case 'Good':
        return const Color(0xFF66BB6A);
      case 'Okay':
        return const Color(0xFF42A5F5);
      case 'Sad':
        return const Color(0xFF78909C);
      case 'Anxious':
        return const Color(0xFFFFA726);
      case 'Stressed':
        return const Color(0xFFEF5350);
      default:
        return const Color(0xFF42A5F5);
    }
  }

  // ══════════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        title: const Text(
          'Daily Check-In',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStreakCard(isDark),
                    const SizedBox(height: 24),
                    _buildMoodSection(isDark),
                    const SizedBox(height: 24),
                    _buildWeeklyCalendar(isDark),
                    const SizedBox(height: 24),
                    _buildAchievements(isDark),
                    const SizedBox(height: 24),
                    _buildQuoteCard(isDark),
                  ],
                ),
              ),
            ),
    );
  }

  // ── Streak Card ──────────────────────────────────────────────
  Widget _buildStreakCard(bool isDark) {
    final current = _streakData['currentStreak'] as int? ?? 0;
    final longest = _streakData['longestStreak'] as int? ?? 0;

    return AnimatedBuilder(
      animation: _streakCountAnim,
      builder: (context, child) {
        final animatedCurrent =
            (current * _streakCountAnim.value).round();
        final animatedLongest =
            (longest * _streakCountAnim.value).round();

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
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '\u{1F525}',
                    style: TextStyle(fontSize: 36),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '$animatedCurrent',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'day${current == 1 ? '' : 's'}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'streak',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _streakMessage(current),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.95),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Longest streak: $animatedLongest day${longest == 1 ? '' : 's'}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Mood Selection / Already Checked In ──────────────────────
  Widget _buildMoodSection(bool isDark) {
    if (_todayMood != null) {
      return _buildAlreadyCheckedIn(isDark);
    }
    return _buildMoodSelector(isDark);
  }

  Widget _buildMoodSelector(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How are you feeling today?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Tap a mood to check in for today',
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.15,
          ),
          itemCount: _moods.length,
          itemBuilder: (context, index) {
            final mood = _moods[index];
            return _buildMoodTile(mood, isDark);
          },
        ),
      ],
    );
  }

  Widget _buildMoodTile(Map<String, String> mood, bool isDark) {
    final color = _moodColor(mood['label']!);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onMoodSelected(mood['label']!),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withOpacity(0.25),
              width: 1.5,
            ),
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                mood['emoji']!,
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(height: 6),
              Text(
                mood['label']!,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlreadyCheckedIn(bool isDark) {
    final emoji = _emojiForMood(_todayMood!);
    final color = _moodColor(_todayMood!);

    return Column(
      children: [
        if (_justCheckedIn)
          ScaleTransition(
            scale: _checkInScaleAnim,
            child: _buildCheckedInCard(isDark, emoji, color),
          )
        else
          _buildCheckedInCard(isDark, emoji, color),
      ],
    );
  }

  Widget _buildCheckedInCard(bool isDark, String emoji, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: color.withOpacity(0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.12),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 36)),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                'You\'ve already checked in today!',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'You\'re feeling $_todayMood',
            style: TextStyle(
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _dailyQuote,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Weekly Mood Calendar ─────────────────────────────────────
  Widget _buildWeeklyCalendar(bool isDark) {
    final now = DateTime.now();
    final weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    // Build a map from date string (yyyy-MM-dd) to mood
    final moodMap = <String, String>{};
    for (final entry in _weeklyCheckIns) {
      final date = entry['date'] as String?;
      final mood = entry['mood'] as String?;
      if (date != null && mood != null) {
        moodMap[date] = mood;
      }
    }

    // Generate the 7 days of the current week (Monday to Sunday)
    final mondayOffset = now.weekday - 1;
    final monday = now.subtract(Duration(days: mondayOffset));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'This Week',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
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
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (i) {
              final day = monday.add(Duration(days: i));
              final dateStr =
                  '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
              final mood = moodMap[dateStr];
              final isToday = day.year == now.year &&
                  day.month == now.month &&
                  day.day == now.day;
              final isFuture = day.isAfter(now);

              return Column(
                children: [
                  Text(
                    weekDays[i],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isToday
                          ? Theme.of(context).colorScheme.primary
                          : (isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: mood != null
                          ? _moodColor(mood).withOpacity(0.15)
                          : (isToday
                              ? Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.1)
                              : (isDark
                                  ? Colors.white.withOpacity(0.05)
                                  : Colors.grey.shade100)),
                      border: isToday
                          ? Border.all(
                              color: Theme.of(context).colorScheme.primary,
                              width: 2,
                            )
                          : null,
                    ),
                    child: Center(
                      child: mood != null
                          ? Text(
                              _emojiForMood(mood),
                              style: const TextStyle(fontSize: 18),
                            )
                          : isFuture
                              ? const SizedBox.shrink()
                              : Icon(
                                  Icons.remove,
                                  size: 14,
                                  color: isDark
                                      ? Colors.grey.shade600
                                      : Colors.grey.shade400,
                                ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${day.day}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isToday ? FontWeight.w700 : FontWeight.normal,
                      color: isToday
                          ? Theme.of(context).colorScheme.primary
                          : (isDark
                              ? Colors.grey.shade500
                              : Colors.grey.shade500),
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  // ── Achievements / Badges ────────────────────────────────────
  Widget _buildAchievements(bool isDark) {
    final current = _streakData['currentStreak'] as int? ?? 0;
    final longest = _streakData['longestStreak'] as int? ?? 0;
    final bestStreak = max(current, longest);

    final badges = <Map<String, dynamic>>[
      {
        'title': 'First Step',
        'description': 'Complete your first check-in',
        'icon': Icons.flag,
        'color': const Color(0xFF4CAF50),
        'unlocked': bestStreak >= 1 || _todayMood != null,
      },
      {
        'title': 'Week Warrior',
        'description': '7 day streak',
        'icon': Icons.local_fire_department,
        'color': const Color(0xFFFF7043),
        'unlocked': bestStreak >= 7,
      },
      {
        'title': 'Month Master',
        'description': '30 day streak',
        'icon': Icons.emoji_events,
        'color': const Color(0xFFFFD600),
        'unlocked': bestStreak >= 30,
      },
      {
        'title': 'Mindful Explorer',
        'description': 'Complete 5 exercises',
        'icon': Icons.self_improvement,
        'color': const Color(0xFF7E57C2),
        'unlocked': _exerciseCount >= 5,
      },
      {
        'title': 'Journal Keeper',
        'description': '10 journal entries',
        'icon': Icons.auto_stories,
        'color': const Color(0xFF42A5F5),
        'unlocked': false, // hardcoded threshold — no method available yet
      },
    ];

    final unlockedCount = badges.where((b) => b['unlocked'] == true).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Achievements',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.grey.shade800,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$unlockedCount/${badges.length}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
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
            children: badges
                .map((badge) => _buildBadgeRow(badge, isDark))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildBadgeRow(Map<String, dynamic> badge, bool isDark) {
    final unlocked = badge['unlocked'] as bool;
    final color = badge['color'] as Color;
    final displayColor = unlocked ? color : Colors.grey.shade400;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: unlocked
                  ? color.withOpacity(0.15)
                  : (isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.grey.shade100),
            ),
            child: Icon(
              badge['icon'] as IconData,
              color: displayColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  badge['title'] as String,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: unlocked
                        ? (isDark ? Colors.white : Colors.grey.shade800)
                        : Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  badge['description'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          if (unlocked)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Unlocked',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            )
          else
            Icon(Icons.lock_outline, size: 18, color: Colors.grey.shade400),
        ],
      ),
    );
  }

  // ── Motivational Quote Card ──────────────────────────────────
  Widget _buildQuoteCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1B5E20), const Color(0xFF2E7D32)]
              : [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.format_quote,
            size: 28,
            color: isDark ? Colors.green.shade200 : Colors.green.shade700,
          ),
          const SizedBox(height: 10),
          Text(
            _dailyQuote,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.green.shade100 : Colors.green.shade800,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Daily Wellness Thought',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.green.shade300 : Colors.green.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
