import 'package:flutter/material.dart';
import '../main.dart'; // for themeNotifier
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../database/db_helper.dart';
import 'login_screen.dart';
import 'journal_screen.dart';
import 'mood_tracker_screen.dart';
import 'assessment_screen.dart';
import 'chat_screen.dart';
import 'chat_history_screen.dart';
import 'daily_checkin_screen.dart';
import 'weekly_summary_screen.dart';
import 'exercises_screen.dart';
import 'about_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboard();
      case 1:
        return const JournalScreen();
      case 2:
        return const MoodTrackerScreen();
      case 3:
        return const AssessmentScreen();
      case 4:
        return const ChatScreen();
      default:
        return _buildDashboard();
    }
  }

  Widget _buildDashboard() {
    final user = Provider.of<AuthProvider>(context).currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Greeting Card with Streak ──────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1A237E), const Color(0xFF283593)]
                    : [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.primary.withOpacity(0.75)],
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
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.2),
                      ),
                      child: Center(
                        child: Text(
                          (user?.name?.isNotEmpty == true)
                              ? user!.name!.substring(0, 1).toUpperCase()
                              : 'G',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getGreeting(user?.name ?? 'Guest'),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Your space to understand your emotions',
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
                // Streak badge
                if (user?.userID != null)
                  FutureBuilder<Map<String, int>>(
                    future: DatabaseHelper.instance.getUserStreak(user!.userID!),
                    builder: (context, snapshot) {
                      final streak = snapshot.data?['currentStreak'] ?? 0;
                      if (streak <= 0) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🔥', style: TextStyle(fontSize: 16)),
                              const SizedBox(width: 6),
                              Text(
                                '$streak day streak',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Daily Check-In Prompt ─────────────────────
          if (user?.userID != null)
            FutureBuilder<String?>(
              future: DatabaseHelper.instance.getTodayCheckIn(user!.userID!),
              builder: (context, snapshot) {
                final todayMood = snapshot.data;
                return InkWell(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const DailyCheckInScreen()),
                    );
                    // Refresh home screen when returning from check-in
                    if (mounted) setState(() {});
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: todayMood != null
                            ? (isDark
                                ? [const Color(0xFF1B5E20), const Color(0xFF2E7D32)]
                                : [const Color(0xFF66BB6A), const Color(0xFF81C784)])
                            : (isDark
                                ? [const Color(0xFF4A148C), const Color(0xFF6A1B9A)]
                                : [const Color(0xFF7E57C2), const Color(0xFF9575CD)]),
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Text(
                          todayMood != null ? '✅' : '💭',
                          style: const TextStyle(fontSize: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                todayMood != null
                                    ? 'Checked in today: $todayMood'
                                    : 'How are you feeling today?',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                todayMood != null
                                    ? 'Tap to view your streaks & badges'
                                    : 'Tap to do your daily check-in',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.85),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.8)),
                      ],
                    ),
                  ),
                );
              },
            ),

          const SizedBox(height: 24),

          // ── Section: Quick Actions ─────────────────────
          Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildQuickAction(
                  icon: Icons.edit_note,
                  label: 'Journal',
                  color: const Color(0xFF42A5F5),
                  onTap: () => _onItemTapped(1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickAction(
                  icon: Icons.psychology_alt,
                  label: 'AI Chat',
                  color: const Color(0xFFFF7043),
                  onTap: () => _onItemTapped(4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickAction(
                  icon: Icons.self_improvement,
                  label: 'Exercises',
                  color: const Color(0xFF26A69A),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ExercisesScreen()),
                    );
                    if (mounted) setState(() {});
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Section: Features ──────────────────────────
          Text(
            'Features',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 14),
          _buildFeatureRow(
            icon: Icons.auto_stories,
            title: 'Journal Entry',
            subtitle: 'Write your thoughts and track your feelings',
            color: const Color(0xFF42A5F5),
            onTap: () => _onItemTapped(1),
          ),
          const SizedBox(height: 10),
          _buildFeatureRow(
            icon: Icons.insights,
            title: 'Mood Tracker',
            subtitle: 'See your emotional trend over time',
            color: const Color(0xFF7E57C2),
            onTap: () => _onItemTapped(2),
          ),
          const SizedBox(height: 10),
          _buildFeatureRow(
            icon: Icons.quiz_outlined,
            title: 'Mental Assessments',
            subtitle: 'PHQ-9, GAD-7, PSS-10, DASS-21 & WHO-5',
            color: const Color(0xFF66BB6A),
            onTap: () => _onItemTapped(3),
          ),
          const SizedBox(height: 10),
          _buildFeatureRow(
            icon: Icons.psychology_alt,
            title: 'AI Support Chat',
            subtitle: 'Talk to your AI wellness companion',
            color: const Color(0xFFFF7043),
            onTap: () => _onItemTapped(4),
          ),
          const SizedBox(height: 10),
          _buildFeatureRow(
            icon: Icons.self_improvement,
            title: 'Wellness Exercises',
            subtitle: 'CBT, breathing, and grounding techniques',
            color: const Color(0xFF26A69A),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ExercisesScreen()),
              );
              if (mounted) setState(() {});
            },
          ),
          const SizedBox(height: 10),
          _buildFeatureRow(
            icon: Icons.bar_chart_rounded,
            title: 'Weekly Summary',
            subtitle: 'Insights, mood trends, and activity report',
            color: const Color(0xFFEF5350),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WeeklySummaryScreen()),
            ),
          ),
          const SizedBox(height: 10),
          _buildFeatureRow(
            icon: Icons.emoji_events_outlined,
            title: 'Daily Check-In',
            subtitle: 'Track your mood, build streaks, earn badges',
            color: const Color(0xFFFFB300),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DailyCheckInScreen()),
              );
              if (mounted) setState(() {});
            },
          ),
          const SizedBox(height: 10),
          _buildFeatureRow(
            icon: Icons.history,
            title: 'Chat History',
            subtitle: 'Review your past conversations',
            color: const Color(0xFF78909C),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChatHistoryScreen()),
            ),
          ),
          const SizedBox(height: 10),
          _buildFeatureRow(
            icon: Icons.info_outline,
            title: 'About',
            subtitle: 'App info, privacy, and resources',
            color: const Color(0xFF546E7A),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AboutScreen()),
            ),
          ),
        ],
      ),
    );
  }

  String _getGreeting(String name) {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning, $name';
    if (hour < 17) return 'Good Afternoon, $name';
    if (hour < 21) return 'Good Evening, $name';
    return 'Good Night, $name';
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
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
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 20, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.psychology_alt,
              size: 24,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Mental Health App',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              themeNotifier.value == ThemeMode.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
              size: 22,
            ),
            onPressed: () {
              themeNotifier.value =
                  themeNotifier.value == ThemeMode.dark
                      ? ThemeMode.light
                      : ThemeMode.dark;
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, size: 22),
            onPressed: () async {
              await authProvider.logout();
              if (!mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          )
        ],
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        height: 65,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.auto_stories_outlined), selectedIcon: Icon(Icons.auto_stories), label: 'Journal'),
          NavigationDestination(icon: Icon(Icons.insights_outlined), selectedIcon: Icon(Icons.insights), label: 'Mood'),
          NavigationDestination(icon: Icon(Icons.quiz_outlined), selectedIcon: Icon(Icons.quiz), label: 'Tests'),
          NavigationDestination(icon: Icon(Icons.psychology_outlined), selectedIcon: Icon(Icons.psychology), label: 'Chat'),
        ],
      ),
    );
  }
}
